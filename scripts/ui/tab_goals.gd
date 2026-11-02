class_name TabGoals
extends VBoxContainer
## Aba "Metas": presente diário (7 dias), missões do dia, código de resgate e conquistas.

var _day_cards: Array = []
var _login_btn: Kit.CostButton
var _streak_lbl: Label
var _missions: Array = []
var _ach_rows: Dictionary = {}
var _ach_box: VBoxContainer
var _code_edit: LineEdit
var _code_msg: Label
var _mission_box: VBoxContainer
var _built_day := ""


func _init() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func build() -> void:
	var s := Kit.scroll(12)
	add_child(s[0])
	var v: VBoxContainer = s[1]
	# --- presente diário ---
	v.add_child(Kit.label(Loc.t("goals.login"), 28, Color.WHITE, 6, 700))
	var days := Kit.hbox(6)
	v.add_child(days)
	for i in 7:
		var c := DayCard.new(i + 1)
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		days.add_child(c)
		c.build()
		_day_cards.append(c)
	_streak_lbl = Kit.label("", 20, Pal.TEXT_DIM, 4, 600)
	v.add_child(_streak_lbl)
	_login_btn = Kit.cost_button("ic_gift", "green", 26, Vector2(0, 72))
	_login_btn.pressed.connect(_claim_login)
	v.add_child(_login_btn)
	# --- missões ---
	v.add_child(Kit.label(Loc.t("goals.daily"), 28, Color.WHITE, 6, 700))
	_mission_box = Kit.vbox(8)
	v.add_child(_mission_box)
	v.add_child(Kit.label(Loc.t("goals.refresh"), 18, Pal.TEXT_DIM, 4, 600))
	# --- código ---
	v.add_child(Kit.label(Loc.t("goals.code"), 28, Color.WHITE, 6, 700))
	var cr := Kit.hbox(8)
	v.add_child(cr)
	_code_edit = LineEdit.new()
	_code_edit.placeholder_text = Loc.t("goals.code_hint")
	_code_edit.custom_minimum_size = Vector2(0, 60)
	_code_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_code_edit.add_theme_font_override("font", Kit.font(600))
	_code_edit.add_theme_font_size_override("font_size", 26)
	_code_edit.add_theme_stylebox_override("normal", Kit.box(Color(0, 0, 0, 0.4), 16))
	_code_edit.add_theme_stylebox_override("focus", Kit.box(Color(0, 0, 0, 0.55), 16))
	cr.add_child(_code_edit)
	var rb := Kit.button(Loc.t("goals.redeem"), "blue", 22)
	rb.custom_minimum_size = Vector2(170, 60)
	rb.pressed.connect(_redeem)
	cr.add_child(rb)
	_code_msg = Kit.label("", 20, Pal.GOLD, 4, 600)
	v.add_child(_code_msg)
	# --- conquistas ---
	v.add_child(Kit.label(Loc.t("goals.ach"), 28, Color.WHITE, 6, 700))
	_ach_box = Kit.vbox(8)
	v.add_child(_ach_box)
	for a in Goals.ACH:
		var r := GoalRow.new()
		_ach_box.add_child(r)
		r.build_ach(a)
		_ach_rows[a.id] = r
	_build_missions()
	refresh()


func _build_missions() -> void:
	for c in _mission_box.get_children():
		c.queue_free()
	_missions.clear()
	var i := 0
	for m in G.d.daily.missions:
		var r := GoalRow.new()
		_mission_box.add_child(r)
		r.build_mission(i)
		_missions.append(r)
		i += 1
	_built_day = String(G.d.daily.mission_date)


func _claim_login() -> void:
	var r := G.claim_login()
	if r.is_empty():
		return
	var txt := ""
	if float(r.gold) > 0.0:
		txt += "+" + NumFmt.fmt(float(r.gold))
	if int(r.gems) > 0:
		txt += "  +%d" % int(r.gems)
	G.toast.emit(Loc.t("goals.day", [int(r.day)]) + ": " + txt, "good")
	Sfx.play("fanfare", 1.0)


func _redeem() -> void:
	var r := G.redeem(_code_edit.text)
	match int(r[0]):
		0:
			_code_msg.text = Loc.t("goals.code_ok") + "  +%d" % int(r[1])
			_code_edit.text = ""
			Sfx.play("fanfare", 1.0)
		1:
			_code_msg.text = Loc.t("goals.code_bad")
		2:
			_code_msg.text = Loc.t("goals.code_used")


func refresh() -> void:
	var d := G.d
	if _built_day != String(d.daily.mission_date):
		_build_missions()
	var can := Goals.login_can_claim(d)
	var today_day := Goals.login_day(d)
	var claimed_day := (int(d.daily.streak) - 1) % 7 + 1 if not can else today_day - 1
	for i in _day_cards.size():
		_day_cards[i].refresh(i + 1, can and (i + 1) == today_day, (i + 1) <= claimed_day and (not can or (i + 1) < today_day))
	_streak_lbl.text = Loc.t("goals.streak", [int(d.daily.streak)])
	_login_btn.set_texts(Loc.t("ui.claim") if can else Loc.t("ui.claimed"), "")
	_login_btn.disabled = not can
	for r in _missions:
		r.refresh()
	# conquistas: prontas primeiro, depois em andamento, pegas por último
	var order: Array = []
	for a in Goals.ACH:
		var rank := 1
		if Goals.ach_claimed(d, a):
			rank = 2
		elif Goals.ach_done(d, a):
			rank = 0
		order.append([rank, Goals.ACH.find(a), a.id])
	order.sort()
	for i in order.size():
		var id: String = order[i][2]
		_ach_box.move_child(_ach_rows[id], i)
		_ach_rows[id].refresh()


## Carta de um dia do presente
class DayCard extends PanelContainer:
	var day: int
	var icon_rect: TextureRect
	var day_lbl: Label
	var amt_lbl: Label
	var check: TextureRect

	func _init(d: int) -> void:
		day = d

	func build() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		custom_minimum_size = Vector2(0, 118)
		var rw: Array = Goals.LOGIN[day - 1]
		var v := Kit.vbox(0)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(v)
		day_lbl = Kit.label(Loc.t("goals.day", [day]), 17, Pal.TEXT_DIM, 4, 700)
		day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(day_lbl)
		icon_rect = Kit.icon("ic_coin" if rw[0] == "gold" else "ic_gem", 46)
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(icon_rect)
		var txt := ""
		if rw[0] == "gold":
			txt = "%sh" % NumFmt.fmt(float(rw[1]))
		else:
			txt = "+%d" % int(rw[1])
		if day == 7:
			txt += "+"
		amt_lbl = Kit.label(txt, 19, Color.WHITE, 4, 700)
		amt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(amt_lbl)
		check = Kit.icon("ic_check", 30)
		check.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		check.position = Vector2(-4, -4)
		check.visible = false
		add_child(check)

	func refresh(_d: int, is_today: bool, done: bool) -> void:
		var sb := Kit.box(Pal.PANEL if not is_today else Color("#3b5e2c"), 16)
		if is_today:
			sb.set_border_width_all(4)
			sb.border_color = Pal.GOLD
		add_theme_stylebox_override("panel", sb)
		check.visible = done
		modulate = Color(1, 1, 1, 0.55) if done else Color.WHITE


## Linha de missão ou conquista
class GoalRow extends PanelContainer:
	var title: Label
	var sub: Label
	var bar: ProgressBar
	var btn: Kit.CostButton
	var _ach: Dictionary = {}
	var _mi := -1

	func _base() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		add_theme_stylebox_override("panel", Kit.box(Pal.PANEL, 20))
		var m := MarginContainer.new()
		for k in ["left", "right", "top", "bottom"]:
			m.add_theme_constant_override("margin_" + k, 10)
		add_child(m)
		var row := Kit.hbox(10)
		m.add_child(row)
		var col := Kit.vbox(3)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		title = Kit.label("", 22, Color.WHITE, 5, 700)
		title.clip_text = true
		col.add_child(title)
		bar = Kit.bar(Pal.GREEN, Color(0, 0, 0, 0.5), 20)
		col.add_child(bar)
		sub = Kit.label("", 17, Pal.TEXT_DIM, 4, 600)
		col.add_child(sub)
		btn = Kit.cost_button("ic_gem", "green", 20, Vector2(140, 64))
		row.add_child(btn)

	func build_ach(a: Dictionary) -> void:
		_ach = a
		_base()
		btn.pressed.connect(func():
			if G.claim_ach(String(a.id)) > 0:
				Sfx.play("fanfare", 1.0))

	func build_mission(i: int) -> void:
		_mi = i
		_base()
		btn.pressed.connect(func():
			if G.claim_mission(i) > 0:
				Sfx.play("fanfare", 1.0))

	func refresh() -> void:
		var d := G.d
		if _mi >= 0:
			if _mi >= d.daily.missions.size():
				return
			var m: Dictionary = d.daily.missions[_mi]
			var tgt := float(m.target)
			var prog := Goals.mission_progress(d, m)
			title.text = Loc.t("mission." + String(m.kind), [NumFmt.fmt(tgt)])
			bar.value = prog / tgt
			sub.text = "%s / %s" % [NumFmt.fmt(prog), NumFmt.fmt(tgt)]
			_btn_state(bool(m.claimed), prog >= tgt, int(m.gems))
		else:
			var tgt2 := float(_ach.target)
			var prog2 := minf(Goals.progress(d, _ach.kind), tgt2)
			title.text = Loc.t("ach." + String(_ach.id))
			bar.value = prog2 / tgt2
			sub.text = Loc.t("ach." + String(_ach.kind), [NumFmt.fmt(tgt2)])
			_btn_state(Goals.ach_claimed(d, _ach), prog2 >= tgt2, int(_ach.gems))

	func _btn_state(claimed: bool, done: bool, gems: int) -> void:
		if claimed:
			btn.set_texts(Loc.t("ui.claimed"), "")
			btn.disabled = true
			modulate = Color(1, 1, 1, 0.6)
		else:
			modulate = Color.WHITE
			btn.set_texts(Loc.t("ui.claim") if done else "", str(gems))
			btn.disabled = not done
