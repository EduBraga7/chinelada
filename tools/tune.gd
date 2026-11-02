extends SceneTree
## Otimizador de balanceamento: ajusta as constantes de Econ para o bot guloso seguir o cronograma alvo.
## Uso: Godot_console --headless --path . -s tools/tune.gd -- [--rounds=3] [--dt=0.2]
## Imprime os melhores valores; copie-os para economy.gd.

# estágio -> segundos alvo (bot guloso, jogo ativo)
const TARGETS := {3: 30.0, 5: 60.0, 10: 150.0, 20: 600.0, 30: 1500.0, 40: 3000.0, 50: 5400.0, 60: 9000.0, 70: 14400.0, 80: 21600.0}
const CAP_SEC := 8.0 * 3600.0

# nome -> [min, max]
const PARAMS := {
	"HP_G": [1.12, 1.45],
	"GOLD_G": [1.08, 1.35],
	"LEVEL_G": [1.04, 1.20],
	"RECRUIT_K": [3.0, 80.0],
	"BOSS_HP": [6.0, 60.0],
	"ATK_G": [1.10, 1.40],
	"LATE_F": [0.03, 1.5],
}

var _done := false
var dt := 0.2


func _init() -> void:
	process_frame.connect(_watchdog)
	var rounds := 3
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--rounds="):
			rounds = int(a.substr(9))
		elif a.begins_with("--dt="):
			dt = float(a.substr(5))
	var cur := {}
	for k in PARAMS:
		cur[k] = _param_get(k)
	var best := _eval(cur)
	print("inicio: loss=%.3f  %s" % [best.loss, _fmt(cur, best)])
	var step := 0.5
	for r in rounds:
		var improved := false
		for k in PARAMS:
			for sgn in [1.0, -1.0]:
				var cand := cur.duplicate()
				var lo: float = PARAMS[k][0]
				var hi: float = PARAMS[k][1]
				# passo multiplicativo sobre o "excesso" acima de 1 (para taxas) ou sobre o valor
				var v: float = cand[k]
				if k.ends_with("_G"):
					v = 1.0 + (v - 1.0) * pow(1.0 + step, sgn)
				else:
					v = v * pow(1.0 + step, sgn)
				cand[k] = clampf(v, lo, hi)
				if is_equal_approx(cand[k], cur[k]):
					continue
				var res := _eval(cand)
				if res.loss < best.loss:
					best = res
					cur = cand
					improved = true
					print("  r%d %s -> %.4f  loss=%.3f" % [r + 1, k, cand[k], res.loss])
		print("rodada %d (passo %.2f): loss=%.3f  %s" % [r + 1, step, best.loss, _fmt(cur, best)])
		if not improved:
			step *= 0.5
		else:
			step *= 0.7
	print("== MELHOR ==")
	print(_fmt(cur, best))
	_done = true
	quit()


func _watchdog() -> void:
	if not _done:
		print("tune terminou sem concluir (erro)")
		quit(2)


func _fmt(cur: Dictionary, res: Dictionary) -> String:
	var parts: Array[String] = []
	for k in cur:
		parts.append("%s=%.4f" % [k, cur[k]])
	var ts: Array[String] = []
	for s in TARGETS:
		ts.append("%d:%s" % [s, NumFmt.duration(res.times.get(s, CAP_SEC))])
	return " ".join(parts) + "   | " + " ".join(ts) + " | fails=%d" % res.fails


func _eval(p: Dictionary) -> Dictionary:
	for k in p:
		_param_set(k, p[k])
	Econ.reset_cache()
	var d := GameData.new_data()
	var dir := Director.new(d, 4242)
	dir.emit = false
	dir.inter_len = 0.8
	var t := 0.0
	var tick_i := 0
	var every := maxi(1, roundi(1.0 / dt))
	var times := {}
	var last_c := 0
	var max_target: int = TARGETS.keys().max()
	while t < CAP_SEC:
		dir.tick(dt)
		t += dt
		tick_i += 1
		if tick_i % every == 0:
			if Actions.auto_buy(d) > 0:
				dir.refresh()
		var c := int(d.stage.cleared)
		if c != last_c:
			if c > last_c:
				for s in TARGETS:
					if c >= s and not times.has(s):
						times[s] = t
			last_c = c
			if c >= max_target:
				break
	var loss := 0.0
	for s in TARGETS:
		var ta: float = times.get(s, CAP_SEC * 2.0)
		loss += pow(log(ta / float(TARGETS[s])), 2.0)
	var fails := int(d.stage.fail)
	# derrotas são desejáveis só em quantidade moderada
	var total_fails := _count_fails(dir)
	loss += 0.02 * maxf(0.0, 4.0 - total_fails) + 0.004 * maxf(0.0, total_fails - 60.0)
	return {"loss": loss, "times": times, "fails": total_fails}


func _count_fails(dir: Director) -> int:
	return dir.fail_total


func _param_get(k: String) -> float:
	match k:
		"HP_G": return Econ.HP_G
		"GOLD_G": return Econ.GOLD_G
		"LEVEL_G": return Econ.LEVEL_G
		"RECRUIT_K": return Econ.RECRUIT_K
		"BOSS_HP": return Econ.BOSS_HP
		"ATK_G": return Econ.ATK_G
		"LATE_F": return Econ.LATE_F
	return 0.0


func _param_set(k: String, v: float) -> void:
	match k:
		"HP_G": Econ.HP_G = v
		"GOLD_G": Econ.GOLD_G = v
		"LEVEL_G": Econ.LEVEL_G = v
		"RECRUIT_K": Econ.RECRUIT_K = v
		"BOSS_HP":
			Econ.BOSS_HP = v
			Econ.ELITE_HP = v * 0.4
		"ATK_G": Econ.ATK_G = v
		"LATE_F": Econ.LATE_F = v
