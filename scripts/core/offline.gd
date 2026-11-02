class_name Offline
extends RefCounted
## Motor de farm offline. O Android não deixa o jogo rodar em segundo plano, então, ao voltar,
## calculamos o que a família teria feito: roda a MESMA BattleSim sem gráficos para MEDIR o tempo
## de limpeza e os ganhos de um estágio, extrapola em blocos de tempo, aplica auto-melhorar entre os
## blocos e avança de estágio quando o time aguenta (mesmas regras do Director: poder +15%).
##
## Uso: var o := Offline.new(d, away_seconds); o.run_all()  (ou o.step(8) a cada frame até o.done)
## O save original NÃO é alterado: o resultado fica em `o.s`; use o.commit_into(d) para aplicar.

const CHUNK := 300.0          ## segundos efetivos entre decisões de compra/avanço
const MAX_ITER := 700
const MEASURE_DT := 0.2       ## passo da medição (o jogo usa ~0,017 a 0,05): mais grosso = mais rápido, e o teste confere a diferença
const MEASURE_CAP := 240.0    ## um encontro que passa disso é tratado como derrota
const INTER := 0.8            ## pausa entre encontros (igual ao jogo)

var s: Dictionary                ## cópia do save sendo simulada
var mods: Dictionary = {}
var rng := RandomNumberGenerator.new()
var budget := 0.0                ## segundos efetivos a gastar
var t := 0.0
var iter := 0
var done := false
var report: Dictionary = {}
var _auto_up := false


func _init(data: Dictionary, away_sec: float, seed_val: int = 1, eff_override: float = -1.0) -> void:
	s = data.duplicate(true)
	rng.seed = seed_val
	mods = Econ.mods(s)
	var cap := float(mods.off_cap)
	var used := minf(maxf(away_sec, 0.0), cap)
	var eff := float(mods.off_eff) if eff_override < 0.0 else eff_override
	budget = used * eff
	_auto_up = bool(s.settings.auto_up) and Econ.auto_up_unlocked(s)
	report = {
		"away": away_sec, "used_real": used, "capped": away_sec > cap, "budget": budget,
		"gold": 0.0, "kills": 0.0, "crits": 0.0, "stages": 0, "bosses": 0, "gems": 0, "levels": 0,
		"recruits": 0, "fails": 0, "stage_from": int(s.stage.cleared), "stage_to": int(s.stage.cleared),
		"farm_stage": maxi(1, int(s.stage.cleared)), "stuck": false, "iters": 0,
	}


func run_all() -> void:
	while not done:
		step(1000)


## Processa iterações por até `slice_ms` milissegundos (para não travar o frame).
func step(slice_ms: int = 8) -> void:
	var t0 := Time.get_ticks_usec()
	while not done and (Time.get_ticks_usec() - t0) < slice_ms * 1000:
		_iterate()


## Aplica o resultado no save real (substitui as seções que o motor mexe).
func commit_into(d: Dictionary) -> void:
	for k in ["cur", "stage", "heroes", "party", "stats", "prestige"]:
		d[k] = s[k].duplicate(true)
	d.stats.offline_s = float(d.stats.offline_s) + float(report.used_real)
	Actions.fix_party(d)


func progress() -> float:
	if budget <= 0.0:
		return 1.0
	return clampf(t / budget, 0.0, 1.0)


# ---------------------------------------------------------------- núcleo

func _iterate() -> void:
	iter += 1
	if t >= budget - 0.5 or iter > MAX_ITER:
		_finish()
		return
	var stats := Econ.party_stats(s, mods)
	var power := Econ.team_power(stats)
	var cleared := int(s.stage.cleared)
	var blocked := float(s.stage.blocked_power)
	# 1) tentar avançar (igual ao Director.choose_stage)
	if bool(s.settings.auto_advance) and (blocked <= 0.0 or power >= blocked * 1.15):
		var frontier := cleared + 1
		var m := measure(s, stats, mods, frontier, rng.randi())
		t += float(m.time)
		_credit(m, 1.0)
		if bool(m.win):
			s.stage.cleared = frontier
			s.stage.best = maxi(int(s.stage.best), frontier)
			s.prestige.run_best = maxi(int(s.prestige.run_best), frontier)
			s.stage.blocked_power = 0.0
			s.stats.stages = float(s.stats.stages) + 1
			report.stages = int(report.stages) + 1
			if WorldDefs.is_boss_stage(frontier):
				report.bosses = int(report.bosses) + 1
				s.stats.bosses = float(s.stats.bosses) + 1
				var g := Econ.stage_clear_gems(frontier, mods)
				if g > 0:
					s.cur.gems = int(s.cur.gems) + g
					report.gems = int(report.gems) + g
			_try_recruit_and_buy()
			return
		# Online o ouro da luta perdida já é gasto DURANTE a luta (auto-melhorar a cada 0,5 s), e o poder
		# guardado para o "+15%" é o do fim dela: aqui gastamos primeiro e só depois medimos o poder.
		s.stage.fail = int(s.stage.fail) + 1
		report.fails = int(report.fails) + 1
		_try_recruit_and_buy()
		s.stage.blocked_power = Econ.team_power(Econ.party_stats(s, mods))
		if t >= budget - 0.5:
			return
	# 2) farmar o último estágio limpo
	var fs := maxi(1, int(s.stage.cleared))
	report.farm_stage = fs
	var mf := measure(s, stats, mods, fs, rng.randi())
	if not bool(mf.win):
		# nem o farm aguenta: recua (igual ao Director)
		t += float(mf.time)
		_credit(mf, 1.0)
		s.stage.cleared = maxi(0, fs - 2)
		return
	var remaining := budget - t
	var chunk := minf(clampf(budget / 80.0, Director.RETRY_MIN, CHUNK), remaining)
	if not _auto_up:
		chunk = remaining     # sem compras o poder não muda: consome tudo de uma vez
	var runs := chunk / float(mf.time)
	_credit(mf, runs)
	t += chunk
	if _auto_up:
		_try_recruit_and_buy()
	elif chunk >= remaining:
		report.stuck = bool(report.fails) and int(report.fails) > 0 and int(report.stages) == 0


func _credit(m: Dictionary, runs: float) -> void:
	var g := float(m.gold) * runs
	s.cur.gold = float(s.cur.gold) + g
	s.stats.gold_total = float(s.stats.gold_total) + g
	s.stats.kills = float(s.stats.kills) + float(m.kills) * runs
	s.stats.crits = float(s.stats.crits) + float(m.crits) * runs
	report.gold = float(report.gold) + g
	report.kills = float(report.kills) + float(m.kills) * runs
	report.crits = float(report.crits) + float(m.crits) * runs


func _try_recruit_and_buy() -> void:
	if not _auto_up:
		return
	for _k in 8:
		var before: Dictionary = {}
		for id in HeroDefs.IDS:
			before[id] = bool(s.heroes[id].owned)
		var n := Actions.auto_buy(s, 40)
		if n <= 0:
			break
		report.levels = int(report.levels) + n
		for id in HeroDefs.IDS:
			if bool(s.heroes[id].owned) and not before[id]:
				report.recruits = int(report.recruits) + 1
				report.levels = int(report.levels) - 1
	mods = Econ.mods(s)


func _finish() -> void:
	done = true
	report.stage_to = int(s.stage.cleared)
	report.iters = iter
	report.stuck = int(report.stages) == 0 and int(report.fails) > 0


# ---------------------------------------------------------------- medição

## Roda um encontro inteiro (sem gráficos) e devolve tempo, ganhos e se o time venceu.
static func measure(d: Dictionary, stats: Array, m: Dictionary, stage: int, seed_val: int) -> Dictionary:
	var sim := BattleSim.new()
	sim.emit_events = false
	sim.setup(stats, stage, m, seed_val)
	sim.auto_fury = bool(m.auto_fury) and bool(d.settings.auto_fury)
	while sim.result == BattleSim.Result.RUNNING and sim.time < MEASURE_CAP:
		sim.step(MEASURE_DT)
	return {
		"win": sim.result == BattleSim.Result.WIN,
		"time": maxf(sim.time, 1.0) + INTER,
		"gold": float(sim.loot.gold),
		"kills": int(sim.loot.kills),
		"crits": int(sim.loot.crits),
	}


## Ouro por hora (bruto, sem eficiência) farmando o último estágio limpo; usado no HUD.
static func gold_per_hour(d: Dictionary, seed_val: int = 7) -> float:
	var m := Econ.mods(d)
	var stats := Econ.party_stats(d, m)
	var fs := maxi(1, int(d.stage.cleared))
	var r := measure(d, stats, m, fs, seed_val)
	if not bool(r.win):
		return 0.0
	return float(r.gold) / float(r.time) * 3600.0


# ---------------------------------------------------------------- diário da família

## Linhas do diário como chaves de tradução + argumentos (a UI traduz com Loc).
static func diary(r: Dictionary, rng: RandomNumberGenerator) -> Array:
	var out: Array = []
	if int(r.stages) > 0:
		out.append({"k": "diary.stages", "a": [int(r.stages), int(r.stage_to)]})
	if int(r.bosses) > 0:
		out.append({"k": "diary.boss", "a": [int(r.bosses)]})
	if int(r.recruits) > 0:
		out.append({"k": "diary.recruit", "a": [int(r.recruits)]})
	if int(r.levels) > 0:
		out.append({"k": "diary.levels", "a": [int(r.levels)]})
	if bool(r.stuck):
		out.append({"k": "diary.stuck", "a": [int(r.stage_to) + 1]})
	if bool(r.capped):
		out.append({"k": "diary.capped", "a": []})
	var pool: Array = []
	for i in range(1, 9):
		pool.append(i)
	for _k in 2:
		var idx := rng.randi() % pool.size()
		out.append({"k": "diary.flavor.%d" % pool[idx], "a": []})
		pool.remove_at(idx)
	return out
