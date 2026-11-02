extends SceneTree
## Valida o motor offline contra o jogo online (mesmo estado inicial, auto-melhorar ligado), com várias sementes.
## O ouro total cresce exponencialmente com o estágio, então o critério principal é o ESTÁGIO alcançado
## (média das sementes) e o número de abates; o ouro só precisa estar no mesmo "ponto de grandeza".
## Uso: Godot_console --headless --path . -s tools/test_offline.gd -- [--warm=30] [--hours=1,4,8] [--seeds=4]

var _done := false
var _fails := 0
var _seeds := 4


func _init() -> void:
	process_frame.connect(_watchdog)
	var warm := 30.0
	var hours: Array[float] = [1.0, 4.0, 8.0]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--warm="):
			warm = float(a.substr(7))
		elif a.begins_with("--hours="):
			hours.clear()
			for h in a.substr(8).split(","):
				hours.append(float(h))
		elif a.begins_with("--seeds="):
			_seeds = maxi(1, int(a.substr(8)))
	print("== test_offline: aquecimento %.0f min, %d sementes ==" % [warm, _seeds])
	var base := _warmup(warm)
	print("estado base: estagio limpo %d | herois %s | ouro %s" % [int(base.stage.cleared), _heroes(base), NumFmt.fmt(float(base.cur.gold))])
	_edge_cases(base)
	for h in hours:
		_compare(base, h, true)
	_compare(base, hours[0], false)
	print("== resultado: %s ==" % ("OK" if _fails == 0 else "%d FALHA(S)" % _fails))
	_done = true
	quit(1 if _fails > 0 else 0)


func _watchdog() -> void:
	if not _done:
		print("test_offline terminou sem concluir (erro no script)")
		quit(2)


func _warmup(minutes: float) -> Dictionary:
	var d := GameData.new_data()
	var dir := Director.new(d, 555)
	dir.emit = false
	dir.inter_len = 0.8
	var t := 0.0
	var i := 0
	while t < minutes * 60.0:
		dir.tick(0.1)
		t += 0.1
		i += 1
		if i % 10 == 0 and Actions.auto_buy(d) > 0:
			dir.refresh()
	return d


func _heroes(d: Dictionary) -> String:
	var parts: Array[String] = []
	for id in HeroDefs.IDS:
		if d.heroes[id].owned:
			parts.append("%s:%d" % [id.substr(0, 3), int(d.heroes[id].lvl)])
	return " ".join(parts)


func _expect(cond: bool, msg: String) -> void:
	if cond:
		print("  ok   ", msg)
	else:
		print("  FALHA ", msg)
		_fails += 1


func _edge_cases(base: Dictionary) -> void:
	print("-- casos de borda --")
	var o0 := Offline.new(base, 0.0, 1)
	o0.run_all()
	_expect(is_equal_approx(float(o0.report.gold), 0.0) and int(o0.report.stages) == 0, "away = 0 não rende nada")
	var on := Offline.new(base, -500.0, 1)
	on.run_all()
	_expect(is_equal_approx(float(on.report.gold), 0.0), "away negativo (relógio voltou) não rende nada")
	var oc := Offline.new(base, 100.0 * 3600.0, 1)
	_expect(bool(oc.report.capped) and is_equal_approx(float(oc.report.used_real), 8.0 * 3600.0), "teto de 8 h aplicado (100 h fora)")
	_expect(is_equal_approx(float(oc.report.budget), 8.0 * 3600.0 * 0.8), "eficiência 80% aplicada")
	var before_gold := float(base.cur.gold)
	var o1 := Offline.new(base, 600.0, 1)
	o1.run_all()
	_expect(is_equal_approx(float(base.cur.gold), before_gold), "o save original não é alterado pelo motor")
	var d2 := base.duplicate(true)
	o1.commit_into(d2)
	_expect(float(d2.cur.gold) > before_gold, "commit_into aplica o ouro ganho")
	var long := Offline.new(base, 8.0 * 3600.0, 3, 1.0)
	var ms := Time.get_ticks_msec()
	long.run_all()
	_expect(Time.get_ticks_msec() - ms < 4000, "8 h de ausência calculadas em < 4 s (%d ms; no celular o cálculo é fatiado por quadro)" % (Time.get_ticks_msec() - ms))
	_expect(long.iter <= Offline.MAX_ITER, "limite de iterações respeitado (%d)" % long.iter)


func _run_online(base: Dictionary, secs: float, auto_up: bool, seed_val: int) -> Dictionary:
	var d1 := base.duplicate(true)
	d1.settings.auto_up = auto_up
	var dir := Director.new(d1, seed_val)
	dir.emit = false
	dir.inter_len = 0.8
	var g0 := float(d1.stats.gold_total)
	var k0 := float(d1.stats.kills)
	var t := 0.0
	while t < secs:
		dir.tick(0.1)
		t += 0.1
	return {"stage": int(d1.stage.cleared), "gold": float(d1.stats.gold_total) - g0, "kills": float(d1.stats.kills) - k0}


func _run_offline(base: Dictionary, secs: float, auto_up: bool, seed_val: int) -> Dictionary:
	var d2 := base.duplicate(true)
	d2.settings.auto_up = auto_up
	var ms := Time.get_ticks_msec()
	var o := Offline.new(d2, secs, seed_val, 1.0)
	o.run_all()
	return {"stage": int(o.s.stage.cleared), "gold": float(o.s.stats.gold_total) - float(base.stats.gold_total),
		"kills": float(o.s.stats.kills) - float(base.stats.kills), "ms": Time.get_ticks_msec() - ms, "iter": o.iter}


func _mean(a: Array) -> float:
	var s := 0.0
	for v in a:
		s += float(v)
	return s / maxf(a.size(), 1.0)


func _compare(base: Dictionary, hours: float, auto_up: bool) -> void:
	var secs := minf(hours * 3600.0, float(Econ.mods(base).off_cap))
	var s0 := int(base.stage.cleared)
	var on_st: Array = []
	var off_st: Array = []
	var on_k: Array = []
	var off_k: Array = []
	var on_g: Array = []
	var off_g: Array = []
	var max_ms := 0
	for i in _seeds:
		var a := _run_online(base, secs, auto_up, 100 + i)
		var b := _run_offline(base, secs, auto_up, 100 + i)
		on_st.append(a.stage)
		off_st.append(b.stage)
		on_k.append(a.kills)
		off_k.append(b.kills)
		on_g.append(a.gold)
		off_g.append(b.gold)
		max_ms = maxi(max_ms, int(b.ms))
	var mon := _mean(on_st)
	var mof := _mean(off_st)
	var kr := _mean(off_k) / maxf(_mean(on_k), 1.0)
	var gl := log(maxf(_mean(off_g), 1.0)) / log(10.0) - log(maxf(_mean(on_g), 1.0)) / log(10.0)
	print("-- %.0f h, auto-melhorar=%s (estagio inicial %d) --" % [hours, str(auto_up), s0])
	print("  online : estagios %s  media %.1f | abates +%s | ouro +%s" % [str(on_st), mon, NumFmt.fmt(_mean(on_k)), NumFmt.fmt(_mean(on_g))])
	print("  offline: estagios %s  media %.1f | abates +%s | ouro +%s | pior calculo %d ms" % [str(off_st), mof, NumFmt.fmt(_mean(off_k)), NumFmt.fmt(_mean(off_g)), max_ms])
	var gain_on := maxf(mon - float(s0), 1.0)
	var gain_off := mof - float(s0)
	print("  progresso offline/online: %.2f (estagios ganhos) | abates %.2f | ouro: %+.2f ordens de grandeza" % [gain_off / gain_on, kr, gl])
	if auto_up:
		_expect(absf(mof - mon) <= maxf(3.0, 0.10 * mon), "estagio medio dentro de 10%% do online (%.1f vs %.1f)" % [mof, mon])
		_expect(absf(gl) <= 0.7, "ouro no mesmo ponto de grandeza (%+.2f ordens)" % gl)
	else:
		_expect(absf(mof - mon) <= 2.0, "sem auto-melhorar: estagio parecido (%.1f vs %.1f)" % [mof, mon])
		_expect(kr >= 0.55 and kr <= 1.40, "sem auto-melhorar: abates parecidos (%.2f)" % kr)
		_expect(absf(gl) <= 0.2, "sem auto-melhorar: ouro parecido (%+.2f ordens)" % gl)
	_expect(max_ms < 3000, "calculo offline < 3 s (%d ms)" % max_ms)
