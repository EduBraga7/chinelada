class_name QaTour
extends Node
## Roteiro de verificação visual: monta estados do jogo, tira screenshots em res://qa/ e sai.
## Uso: Godot_console --path . --rendering-driver opengl3 --resolution 540x960 -- --qa=tour

var main: Main
var mode := "tour"
var tag := ""


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://qa"))
	_run()


func _run() -> void:
	await _frames(20)
	match mode:
		"tour":
			await _tour()
		"offline":
			await _offline()
		"boss":
			await _boss()
		"live":
			await _live()
		"stress":
			await _stress()
		"perf":
			await _perf()
		"soak":
			await _soak()
		"vsync":
			await _vsync()
	print("QA concluído: ", mode)
	get_tree().quit()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(n: String) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var p := "res://qa/%s%s.png" % [n, tag]
	img.save_png(p)
	print("shot ", p, " ", img.get_size())


## Avança a simulação quadro a quadro (a UI e os efeitos rodam normalmente).
func _play(seconds: float) -> void:
	var steps := int(seconds * 30.0)
	for i in steps:
		G.dir.tick(1.0 / 30.0)
		await get_tree().process_frame


func _late_state() -> void:
	var d := G.d
	d.stage.cleared = 44
	d.stage.best = 44
	d.prestige.run_best = 44
	var i := 0
	for id in HeroDefs.IDS:
		var h: Dictionary = d.heroes[id]
		h.owned = true
		h.lvl = 50 + i * 9
		i += 1
	d.cur.gold = 4.2e7
	d.cur.gems = 180
	d.cur.bless = 12
	d.prestige.count = 2
	d.prestige.earned = 40.0
	d.relics = {"chinelo_sorte": {"lvl": 4}, "cofrinho": {"lvl": 2}, "chinelo_ouro": {"lvl": 1}}
	d.settings.auto_up = true
	Actions.fix_party(d)
	Actions.auto_team(d)
	G.dir.refresh()
	G.dir.restart_encounter()


func _tour() -> void:
	# 1) jogo novo, primeiros segundos
	await _play(3.0)
	await _shot("01_novo")
	# 2) estado avançado, batalha com efeitos
	_late_state()
	await _play(0.4)
	G.dir.sim.fury = 100.0
	await _play(2.5)
	main.fx.number(Vector2(300, 400), "1.2M", Color("#ffd23f"), 46, true)
	await _shot("02_batalha")
	G.activate_fury()
	await _play(1.2)
	await _shot("03_furia")
	# 3) abas
	for i in range(1, 5):
		main.select_tab(i)
		await _frames(4)
		await _shot("04_aba%d" % i)
	main.select_tab(0)
	await _frames(4)
	await _popups_tour()
	# 4) popups
	main.popups.settings()
	await _frames(20)
	await _shot("05_config")
	main.popups.close_top()
	await _frames(8)
	var rep := {"away": 8.0 * 3600.0, "used_real": 8.0 * 3600.0, "capped": true, "gold": 1.84e9, "kills": 12345.0, "stages": 7, "bosses": 2,
		"gems": 14, "levels": 63, "recruits": 0, "stage_from": 44, "stage_to": 51, "fails": 3, "stuck": false}
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	main.popups.offline(rep, Offline.diary(rep, rng))
	await _frames(70)
	await _shot("06_offline")
	main.popups.close_top()
	await _frames(8)


func _popups_tour() -> void:
	G.d.cur.gems = 900
	G.rng.seed = 11
	var res := G.open_marmitas(10)
	main.popups.marmita_reveal(res)
	await _frames(60)
	await _shot("07_marmita10")
	main.popups.close_top()
	await _frames(8)
	res = G.open_marmitas(1)
	main.popups.marmita_reveal(res)
	await _frames(40)
	await _shot("08_marmita1")
	main.popups.close_top()
	await _frames(8)
	main.popups.bestiary()
	await _frames(20)
	await _shot("09_bestiario")
	main.popups.close_top()
	await _frames(8)
	main.popups.photo()
	await _frames(20)
	await _shot("10_foto")
	main.popups.close_top()
	await _frames(8)
	main.popups.relic_detail("chinelo_ouro")
	await _frames(20)
	await _shot("11_relic")
	main.popups.close_top()
	await _frames(8)
	main.select_tab(2)
	await _frames(4)
	main.popups.confirm(Loc.t("bless.confirm_title"), Loc.t("bless.confirm", [23, 1, 115]), func(): pass, Loc.t("bless.pray"), "purple")
	await _frames(20)
	await _shot("12_confirma")
	main.popups.close_top()
	await _frames(8)
	main.select_tab(0)


func _offline() -> void:
	_late_state()
	G.d.t_last = Time.get_unix_time_from_system() - 9.0 * 3600.0
	G.save_now()
	G.d.t_last = Time.get_unix_time_from_system() - 9.0 * 3600.0
	G.start_offline(9.0 * 3600.0)
	await _frames(2)
	await _shot("10_contando")
	while G.offline_busy:
		await _frames(1)
	await _frames(70)
	await _shot("11_offline_real")


## Tempo real (sem congelar): jogo novo rodando sozinho; mede FPS e custo de CPU.
func _live() -> void:
	var secs := 14.0
	var t0 := Time.get_ticks_msec()
	var shots := [4.0, 13.0]
	var si := 0
	var proc_sum := 0.0
	var proc_max := 0.0
	var n := 0
	while float(Time.get_ticks_msec() - t0) / 1000.0 < secs:
		await get_tree().process_frame
		var pt := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		proc_sum += pt
		proc_max = maxf(proc_max, pt)
		n += 1
		if si < shots.size() and float(Time.get_ticks_msec() - t0) / 1000.0 >= shots[si]:
			await _shot("30_live_%d" % si)
			si += 1
		if n == 120 and int(G.d.cur.gold) > 0:
			G.upgrade_hero("neide")
	print("LIVE: fps=%.0f  process medio=%.2f ms  max=%.2f ms  draw calls=%d  nos=%d  estagio=%d ouro=%s" % [
		Engine.get_frames_per_second(), proc_sum / maxf(n, 1.0), proc_max,
		int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		int(G.d.stage.cleared), NumFmt.fmt(float(G.d.cur.gold))])


## Maratona: ~40 min de jogo simulados com a UI rodando, trocando de aba e abrindo popups; vigia vazamentos.
func _soak() -> void:
	_late_state()
	G.set_speed(1)
	Engine.max_fps = 0                              # use com --disable-vsync
	G.d.settings.auto_up = true
	var dt := 0.05
	var sim_min := 40.0
	var steps := int(sim_min * 60.0 / dt)
	var per_min := int(60.0 / dt)
	var t_wall := Time.get_ticks_msec()
	var stage0 := int(G.d.stage.cleared)
	for i in steps:
		G.dir.tick(dt)
		await get_tree().process_frame
		if i % per_min == per_min - 1:
			var m := (i + 1) / per_min
			main.select_tab(m % 5)
			if m % 5 == 0:
				main.popups.settings()
				await _frames(4)
				main.popups.close_top()
			if m % 7 == 0:
				var rr := G.open_marmitas(1)
				if not rr.is_empty():
					main.popups.marmita_reveal(rr)
					await _frames(30)
					main.popups.close_top()
			if m % 4 == 0:
				G.activate_fury()
			if m % 5 == 0 or m == 1:
				print("min %2d  estagio=%d  ouro=%s  nos=%d  objetos=%d  orfaos=%d  mem=%.0f MB  textura=%.0f MB  parede=%.0fs" % [
					m, int(G.d.stage.cleared), NumFmt.fmt(float(G.d.cur.gold)),
					int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), int(Performance.get_monitor(Performance.OBJECT_COUNT)),
					int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
					Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
					Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
					float(Time.get_ticks_msec() - t_wall) / 1000.0])
	print("soak: estagio %d -> %d em %.0f min simulados" % [stage0, int(G.d.stage.cleared), sim_min])


func _set_proc(n: Node, on: bool) -> void:
	n.set_process(on)
	for c in n.get_children():
		_set_proc(c, on)


## Tempo de quadro (ms) medido de relógio de parede entre dois process_frame.
func _frame_ms(secs: float) -> String:
	var ts: Array[float] = []
	var last := Time.get_ticks_usec()
	var t_end := last + int(secs * 1e6)
	while last < t_end:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		ts.append(float(now - last) / 1000.0)
		last = now
	ts.sort()
	var sum := 0.0
	for t in ts:
		sum += t
	return "quadro medio=%.1f ms  p95=%.1f ms  max=%.1f ms  (%d quadros)" % [sum / maxf(ts.size(), 1.0), ts[int(ts.size() * 0.95)], ts[ts.size() - 1], ts.size()]


## Ritmo de quadros real (com o limitador de FPS do jogo) em cada modo de vsync da janela.
func _vsync() -> void:
	_late_state()
	G.qa_frozen = false
	var names := ["desligado", "ligado", "adaptativo", "mailbox"]
	for fps_cap in [60, 0]:
		Engine.max_fps = fps_cap
		for m in [0, 1, 2, 3]:
			DisplayServer.window_set_vsync_mode(m)
			await _frames(20)
			print("max_fps=%2d  vsync %-10s -> %s" % [fps_cap, names[m], await _frame_ms(3.0)])


func _bench(label: String, f: Callable, n: int = 40) -> void:
	var t0 := Time.get_ticks_usec()
	for i in n:
		f.call()
	print("  %-34s %.3f ms" % [label, float(Time.get_ticks_usec() - t0) / 1000.0 / float(n)])


## Descobre quem consome tempo: liga/desliga partes e mede o tempo de quadro.
func _perf() -> void:
	_late_state()
	G.qa_frozen = false
	Engine.max_fps = 0                              # sem limitador: mede o custo real (use --disable-vsync)
	await _frames(30)
	print("-- micro-benchmarks (ms por chamada) --")
	_bench("main._refresh_hud", main._refresh_hud)
	_bench("aba Familia.refresh", main.pages[0].refresh)
	_bench("aba Reliquias.refresh", main.pages[1].refresh)
	_bench("aba Bencaos.refresh", main.pages[2].refresh)
	_bench("aba Metas.refresh", main.pages[3].refresh)
	_bench("aba Mais.refresh", main.pages[4].refresh)
	_bench("badges (5)", func(): for k in 5: main._badge(k))
	_bench("main._refresh_all", main._refresh_all)
	_bench("G.dir.refresh", G.dir.refresh)
	_bench("G.refresh_income", G.refresh_income, 5)
	_bench("Kit.style_button", func(): Kit.style_button(main.pages[0]._auto_btn, "green", 20))
	_bench("Econ.hero_stats x8", func(): for id in HeroDefs.IDS: Econ.hero_stats(G.d, id, G.dir.mods))
	_bench("SaveIO.save (JSON, sem disco)", func(): JSON.stringify(G.d), 10)
	print("-- tempo de quadro --")
	print("tudo ligado       : ", await _frame_ms(3.0))
	G.set_process(false)
	print("sem simulacao (G) : ", await _frame_ms(3.0))
	G.set_process(true)
	_set_proc(main.battle, false)
	print("sem battle_view   : ", await _frame_ms(3.0))
	_set_proc(main.battle, true)
	_set_proc(main.fx, false)
	print("sem fx            : ", await _frame_ms(3.0))
	_set_proc(main.fx, true)
	main.set_process(false)
	print("sem Main._process : ", await _frame_ms(3.0))
	main.set_process(true)
	_set_proc(main, false)
	G.set_process(false)
	print("so render (nada)  : ", await _frame_ms(3.0))
	main.visible = false
	print("main invisivel    : ", await _frame_ms(3.0))
	main.visible = true


## Estresse: time cheio, estágio com enxames, velocidade x3 e muitos efeitos.
func _stress() -> void:
	_late_state()
	G.d.stage.cleared = 94
	G.d.stage.best = 94
	G.d.stage.blocked_power = 0.0
	for id in HeroDefs.IDS:
		G.d.heroes[id].lvl = 30
	G.set_speed(3)
	G.dir.refresh()
	G.dir.restart_encounter()
	G.qa_frozen = false
	Engine.max_fps = 0                              # sem limitador (use --disable-vsync)
	var t0 := Time.get_ticks_msec()
	var ts: Array[float] = []
	var last := Time.get_ticks_usec()
	var units_max := 0
	var calls_max := 0
	var shot_done := false
	while float(Time.get_ticks_msec() - t0) / 1000.0 < 15.0:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		ts.append(float(now - last) / 1000.0)
		last = now
		var sim := G.dir.sim
		if sim != null:
			units_max = maxi(units_max, sim.enemies.size() + sim.heroes.size())
		calls_max = maxi(calls_max, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		if not shot_done and float(Time.get_ticks_msec() - t0) / 1000.0 > 8.0:
			shot_done = true
			await _shot("31_stress")
	ts.sort()
	var sum := 0.0
	for t in ts:
		sum += t
	print("STRESS x3: quadro medio=%.2f ms  p99=%.2f ms  max=%.2f ms  draw calls max=%d  nos=%d  unidades max=%d  estagio=%d" % [
		sum / maxf(ts.size(), 1.0), ts[int(ts.size() * 0.99)], ts[ts.size() - 1], calls_max,
		int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)), units_max, int(G.d.stage.cleared)])


func _boss() -> void:
	_late_state()
	G.d.stage.cleared = 49
	G.d.stage.best = 49
	G.d.stage.blocked_power = 0.0
	G.dir.refresh()
	G.dir.restart_encounter()
	await _play(5.0)
	await _shot("20_boss")
