extends Node
## Estado central do jogo: save, Director (batalha), farm offline, ações para a UI e ciclo de vida do app.

signal changed                                  ## algo mudou (a UI atualiza números)
signal toast(text: String, kind: String)
signal offline_started
signal offline_done(report: Dictionary, diary: Array)
signal back_pressed

var d: Dictionary
var dir: Director
var speed := 1
var buy_mode := 1                               ## 1, 10, 100 ou -1 (máximo)
var income_ph := 0.0                            ## ouro/hora farmando (HUD "rende X/h")
var offline_progress := 0.0
var offline_busy := false
var last_report: Dictionary = {}
var last_diary: Array = []
var rng := RandomNumberGenerator.new()
var qa_frozen := false                          ## modo QA: congela o tempo para screenshots determinísticos
var no_save := false                            ## modo QA: nunca grava o save de verdade

var _off: Offline = null
var _save_t := 0.0
var _inc_t := 99.0
var _last_tap := 0.0


func _ready() -> void:
	rng.randomize()
	d = SaveIO.load_or_new()
	apply_settings()
	dir = Director.new(d, rng.randi())
	dir.inter_len = 0.9
	get_tree().set_auto_accept_quit(false)
	speed = clampi(int(d.settings.speed), 1, 3)
	Goals.ensure_daily(d)
	_check_away()


func now() -> float:
	return Time.get_unix_time_from_system()


func _process(delta: float) -> void:
	if qa_frozen:
		return
	if _off != null:
		_off.step(10)
		offline_progress = _off.progress()
		if _off.done:
			_finish_offline()
		return
	dir.tick(minf(delta, 0.1) * speed)
	d.stats.play_s = float(d.stats.play_s) + delta
	_save_t += delta
	if _save_t >= 10.0:
		_save_t = 0.0
		save_now()
	_inc_t += delta
	if _inc_t >= 20.0:
		_inc_t = 0.0
		refresh_income()
		Goals.ensure_daily(d)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			save_now()
		NOTIFICATION_APPLICATION_RESUMED:
			_check_away()
		NOTIFICATION_WM_CLOSE_REQUEST:
			save_now()
			get_tree().quit()
		NOTIFICATION_WM_GO_BACK_REQUEST:
			back_pressed.emit()


func apply_settings() -> void:
	Loc.set_language(String(d.settings.lang))
	NumFmt.scientific = bool(d.settings.sci)
	Engine.max_fps = 30 if bool(d.settings.fps30) else 60
	Sfx.set_volumes(float(d.settings.sfx), float(d.settings.music))
	Sfx.haptics = bool(d.settings.vibration)


func set_setting(key: String, value: Variant) -> void:
	d.settings[key] = value
	apply_settings()
	if key == "auto_advance" or key == "auto_fury":
		dir.refresh()
	changed.emit()


func save_now() -> void:
	if no_save:
		return
	_sanitize()
	SaveIO.save(d)


## Garante que nenhum número do save virou NaN/inf (JSON não aceita).
func _sanitize() -> void:
	for k in ["gold"]:
		var v := float(d.cur[k])
		if is_nan(v) or is_inf(v):
			d.cur[k] = 0.0
	var bp := float(d.stage.blocked_power)
	if is_nan(bp) or is_inf(bp):
		d.stage.blocked_power = 0.0


# ---------------------------------------------------------------- offline

func _check_away() -> void:
	if _off != null:
		return
	var t := now()
	var away := t - float(d.t_last)
	if away < 0.0:
		d.t_last = t                    # relógio voltou: não rende nada
		return
	if away >= 60.0:
		start_offline(away)


func start_offline(away: float) -> void:
	_off = Offline.new(d, away, rng.randi())
	offline_busy = true
	offline_progress = 0.0
	offline_started.emit()


func _finish_offline() -> void:
	var o := _off
	_off = null
	offline_busy = false
	o.commit_into(d)
	last_report = o.report
	var drng := RandomNumberGenerator.new()
	drng.seed = int(now())
	last_diary = Offline.diary(o.report, drng)
	dir.refresh()
	dir.restart_encounter()
	d.t_last = now()
	save_now()
	refresh_income()
	offline_done.emit(o.report, last_diary)
	changed.emit()


func refresh_income() -> void:
	income_ph = Offline.gold_per_hour(d, int(now()) % 1000 + 1) * float(dir.mods.off_eff)


# ---------------------------------------------------------------- ações

func upgrade_hero(id: String) -> int:
	var n := Actions.upgrade(d, id, buy_mode)
	if n > 0:
		dir.refresh()
		changed.emit()
	return n


func recruit_hero(id: String) -> bool:
	if not Actions.recruit(d, id):
		return false
	Actions.auto_team(d)
	dir.refresh()
	dir.restart_encounter()
	toast.emit(Loc.t("hero.joined", [Loc.t("hero.%s.name" % id)]), "good")
	changed.emit()
	return true


func toggle_team(id: String) -> bool:
	d.settings.auto_team = false
	if Actions.toggle_party(d, id):
		dir.refresh()
		dir.restart_encounter()
		changed.emit()
		return true
	return false


func set_auto_team(on: bool) -> void:
	d.settings.auto_team = on
	if on:
		Actions.auto_team(d)
		dir.refresh()
		dir.restart_encounter()
	changed.emit()


func activate_fury() -> bool:
	if dir.sim == null or not dir.sim.activate_fury():
		return false
	changed.emit()
	return true


## "Dedada": devolve o dano causado (0 se não havia alvo ou o toque veio rápido demais).
func tap() -> float:
	var t := float(Time.get_ticks_msec()) / 1000.0
	if dir.sim == null or t - _last_tap < 0.12:
		return 0.0
	var dmg := Econ.tap_damage(dir.stats_party, dir.mods)
	if dir.sim.tap(dmg):
		_last_tap = t
		d.stats.taps = float(d.stats.taps) + 1
		return dmg
	return 0.0


## Papagaio Dourado: devolve a recompensa (ouro ≈ 4 min de renda + chance de Pães de Queijo).
func catch_parrot() -> Dictionary:
	var gold := maxf(income_ph / 3600.0 * 240.0, Econ.stage_income(maxi(1, int(d.stage.cleared))) * 3.0)
	var gems := 0
	if rng.randf() < 0.25:
		gems = rng.randi_range(1, 3)
	d.cur.gold = float(d.cur.gold) + gold
	d.stats.gold_total = float(d.stats.gold_total) + gold
	d.cur.gems = int(d.cur.gems) + gems
	d.stats.parrots = float(d.stats.parrots) + 1
	changed.emit()
	return {"gold": gold, "gems": gems}


func claim_ach(id: String) -> int:
	var g := Goals.claim_ach(d, id)
	if g > 0:
		changed.emit()
	return g


func claim_mission(i: int) -> int:
	var g := Goals.claim_mission(d, i)
	if g > 0:
		changed.emit()
	return g


func claim_login() -> Dictionary:
	var r := Goals.claim_login(d, income_ph, int(d.stage.best))
	if not r.is_empty():
		changed.emit()
	return r


func redeem(code: String) -> Array:
	var r := Goals.redeem(d, code)
	if int(r[0]) == 0:
		changed.emit()
	return r


func fornada_start(kind: String) -> bool:
	var ok := Goals.fornada_start(d, kind)
	if ok:
		save_now()
		changed.emit()
	return ok


func fornada_claim() -> int:
	var g := Goals.fornada_claim(d, dir.mods)
	if g > 0:
		changed.emit()
	return g


func force_retry() -> void:
	dir.force_retry()
	changed.emit()


func open_marmitas(n: int) -> Array:
	var res := Actions.open_marmitas(d, n, rng)
	if not res.is_empty():
		dir.refresh()
		changed.emit()
	return res


func buy_bless(id: String) -> bool:
	if Actions.buy_bless(d, id):
		dir.refresh()
		changed.emit()
		return true
	return false


func prestige() -> int:
	var gain := Actions.prestige(d)
	if gain > 0:
		dir.fury_carry = 0.0
		dir.refresh()
		dir.restart_encounter()
		save_now()
		changed.emit()
	return gain


func set_speed(s: int) -> void:
	speed = clampi(s, 1, 3)
	d.settings.speed = speed
	changed.emit()


func cycle_speed() -> void:
	set_speed(speed % 3 + 1)


func set_buy_mode(m: int) -> void:
	buy_mode = m
	changed.emit()


func reset_all() -> void:
	SaveIO.wipe()
	d = GameData.fix(GameData.new_data())
	dir = Director.new(d, rng.randi())
	dir.inter_len = 0.9
	apply_settings()
	changed.emit()
