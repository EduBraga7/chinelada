class_name Director
extends RefCounted
## Regente do fluxo de estágios: escolhe o estágio da vez, roda o combate, aplica os ganhos no save
## e decide o que fazer depois (avançar, farmar, tentar de novo). Sem UI: usado pelo jogo e pelos bots.
##
## Regras (iguais online e offline):
##  - auto-avançar ligado: tenta sempre o estágio seguinte ao último limpo ("fronteira");
##  - se perder na fronteira, guarda o poder do time (blocked_power) e farma o último limpo;
##  - só tenta a fronteira de novo quando o poder subir 15% acima do poder da derrota
##    e depois de RETRY_MIN segundos farmando (evita tentativas em sequência sem chance).

const RETRY_MIN := 60.0

var d: Dictionary
var sim: BattleSim = null
var mods: Dictionary = {}
var rng := RandomNumberGenerator.new()
var out: Array = []            ## eventos de alto nível para a UI: encounter, clear, fail
var stage := 1
var frontier := false
var intermission := 0.0
var inter_len := 1.0
var emit := true
var power := 0.0
var stats_party: Array = []
var fury_carry := 0.0
var fail_total := 0            ## derrotas na fronteira desde que o Director foi criado (métrica de teste)
var _auto_t := 0.0
var _retry_t := 0.0            ## segundos farmando desde a última derrota na fronteira


func _init(data: Dictionary, p_seed: int = 0) -> void:
	d = data
	rng.seed = p_seed if p_seed != 0 else randi()
	refresh()


## Recalcula bônus, estatísticas do time e poder (chamar após qualquer mudança no save).
func refresh() -> void:
	mods = Econ.mods(d)
	stats_party = Econ.party_stats(d, mods)
	power = Econ.team_power(stats_party)
	if sim != null:
		sim.mods = mods
		sim.refresh_party(stats_party)


func choose_stage() -> int:
	var cleared := int(d.stage.cleared)
	if bool(d.settings.auto_advance):
		var blocked := float(d.stage.blocked_power)
		if blocked <= 0.0 or (power >= blocked * 1.15 and _retry_t >= RETRY_MIN):
			d.stage.blocked_power = 0.0
			frontier = true
			return cleared + 1
		frontier = false
		return maxi(1, cleared)
	var f := clampi(int(d.stage.farm), 1, cleared + 1)
	d.stage.farm = f
	frontier = f == cleared + 1
	return f


func start_encounter() -> void:
	stage = choose_stage()
	sim = BattleSim.new()
	sim.emit_events = emit
	sim.setup(stats_party, stage, mods, rng.randi())
	sim.fury = fury_carry
	sim.auto_fury = bool(mods.auto_fury) and bool(d.settings.auto_fury)
	if emit:
		out.append({"t": "encounter", "stage": stage, "boss": sim.boss_stage, "frontier": frontier})


## Recomeça o encontro atual (ex.: depois de mexer no time).
func restart_encounter() -> void:
	refresh()
	if sim != null:
		fury_carry = sim.fury
	start_encounter()


## Botão "Desafiar": ignora o bloqueio e tenta a fronteira agora.
func force_retry() -> void:
	d.stage.blocked_power = 0.0
	_retry_t = RETRY_MIN
	restart_encounter()


func tick(dt: float) -> void:
	if sim == null:
		start_encounter()
	if sim.result != BattleSim.Result.RUNNING:
		intermission -= dt
		if intermission <= 0.0:
			start_encounter()
		return
	_retry_t += dt
	var left := dt
	while left > 0.0 and sim.result == BattleSim.Result.RUNNING:
		var s := minf(left, BattleSim.MAX_STEP)
		sim.step(s)
		left -= s
	_apply_loot()
	if sim.result != BattleSim.Result.RUNNING:
		_finish(sim.result)
	elif bool(d.settings.auto_up) and Econ.auto_up_unlocked(d):
		_auto_t += dt
		if _auto_t >= 0.5:
			_auto_t = 0.0
			if Actions.auto_buy(d) > 0:
				refresh()


func _apply_loot() -> void:
	var l := sim.take_loot()
	if float(l.gold) > 0.0:
		d.cur.gold = float(d.cur.gold) + float(l.gold)
		d.stats.gold_total = float(d.stats.gold_total) + float(l.gold)
	d.stats.kills = float(d.stats.kills) + int(l.kills)
	d.stats.crits = float(d.stats.crits) + int(l.crits)


func _finish(res: int) -> void:
	fury_carry = sim.fury
	intermission = inter_len
	d.stats.fury = float(d.stats.fury) + int(sim.summary.fury_used)
	if res == BattleSim.Result.WIN:
		d.stats.stages = float(d.stats.stages) + 1
		var first := stage > int(d.stage.cleared)
		var gems := 0
		if first:
			d.stage.cleared = stage
			d.stage.best = maxi(int(d.stage.best), stage)
			d.prestige.run_best = maxi(int(d.prestige.run_best), stage)
			gems = Econ.stage_clear_gems(stage, mods)
			if gems > 0:
				d.cur.gems = int(d.cur.gems) + gems
			Actions.fix_party(d)       # novas vagas de time ao passar do estágio 19/39
			Actions.auto_team(d)
		if sim.boss_stage:
			d.stats.bosses = float(d.stats.bosses) + 1
		d.stage.fail = 0
		if emit:
			out.append({"t": "clear", "stage": stage, "first": first, "boss": sim.boss_stage, "gems": gems})
		refresh()
	else:
		if frontier:
			d.stage.blocked_power = power
			d.stage.fail = int(d.stage.fail) + 1
			fail_total += 1
			_retry_t = 0.0
		elif stage > 1 and bool(d.settings.auto_advance):
			# até o estágio de farm ficou difícil: recua um
			d.stage.cleared = maxi(0, stage - 2)
		if emit:
			out.append({"t": "fail", "stage": stage, "timeout": res == BattleSim.Result.TIMEOUT})
