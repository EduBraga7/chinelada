extends SceneTree
## Joga o jogo sem gráficos com um bot guloso para medir o ritmo (estágio × tempo) e achar bugs.
## Uso: Godot_console --headless --path . -s tools/sim_economy.gd -- --hours=2 [--prestige] [--seed=7] [--dt=0.1]

const MARKS: Array[int] = [2, 3, 4, 5, 6, 8, 10, 12, 15, 20, 25, 30, 40, 50, 60, 70, 80, 100, 120, 150, 200, 300]


func _init() -> void:
	var hours := 1.0
	var prestige_on := false
	var seed_val := 1337
	var dt := 0.1
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--hours="):
			hours = float(a.substr(8))
		elif a == "--prestige":
			prestige_on = true
		elif a.begins_with("--seed="):
			seed_val = int(a.substr(7))
		elif a.begins_with("--dt="):
			dt = float(a.substr(5))
	var d := GameData.new_data()
	var dir := Director.new(d, seed_val)
	dir.emit = false
	dir.inter_len = 0.8
	var t := 0.0
	var tmax := hours * 3600.0
	var tick_i := 0
	var every := maxi(1, roundi(1.0 / dt))
	var last_cleared := 0
	var last_progress_t := 0.0
	var reached := {}
	var ms0 := Time.get_ticks_msec()
	var wipes := 0
	var presti_log: Array[String] = []
	print("== sim_economy: %.1f h, seed %d, dt %.2f, prestigio=%s ==" % [hours, seed_val, dt, str(prestige_on)])
	while t < tmax:
		dir.tick(dt)
		t += dt
		tick_i += 1
		if tick_i % every == 0:
			if Actions.auto_buy(d) > 0:
				dir.refresh()
		var c := int(d.stage.cleared)
		if c != last_cleared:
			if c > last_cleared:
				last_progress_t = t
				if MARKS.has(c) and not reached.has(c):
					reached[c] = t
					print("stage %3d  t=%-9s gold=%-8s power=%-8s  %s" % [c, NumFmt.duration(t), NumFmt.fmt(float(d.cur.gold)), NumFmt.fmt(dir.power), _heroes(d)])
			last_cleared = c
		if prestige_on and t - last_progress_t > 600.0 and Econ.bless_gain(d) >= 1:
			var gain := Actions.prestige(d)
			_spend_bless(d)
			dir.fury_carry = 0.0
			dir.refresh()
			dir.restart_encounter()
			presti_log.append("  prestigio #%d em t=%s: +%d Bencaos (total %s)" % [int(d.prestige.count), NumFmt.duration(t), gain, NumFmt.fmt(float(d.prestige.earned))])
			print(presti_log[-1])
			reached.clear()
			last_cleared = int(d.stage.cleared)
			last_progress_t = t
		if not is_finite(float(d.cur.gold)):
			push_error("ouro virou NaN/inf em t=%f" % t)
			break
	print("-- fim: t=%s  estagio limpo=%d (melhor %d)  kills=%s  boss=%d  fails=%d  ouro=%s" % [
		NumFmt.duration(t), int(d.stage.cleared), int(d.stage.best), NumFmt.fmt(float(d.stats.kills)),
		int(d.stats.bosses), int(d.stage.fail), NumFmt.fmt(float(d.cur.gold))])
	print("-- herois: %s" % _heroes(d))
	print("-- tempo real de CPU: %.1f s" % ((Time.get_ticks_msec() - ms0) / 1000.0))
	quit()


func _heroes(d: Dictionary) -> String:
	var parts: Array[String] = []
	for id in HeroDefs.IDS:
		if d.heroes[id].owned:
			parts.append("%s:%d%s" % [id.substr(0, 3), int(d.heroes[id].lvl), "" if d.party.has(id) else "(b)"])
	return " ".join(parts)


func _spend_bless(d: Dictionary) -> void:
	var order: Array[String] = ["forca", "ouro", "saude", "pressa", "sorte", "furia", "tempo_boss", "off_cap", "auto_furia", "inicio"]
	var guard := 0
	while guard < 200:
		guard += 1
		var bought := false
		for id in order:
			if Actions.buy_bless(d, id):
				bought = true
				break
		if not bought:
			break
