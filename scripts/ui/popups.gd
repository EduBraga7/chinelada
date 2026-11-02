class_name Popups
extends Control
## Janelas modais (com animação): configurações, diário do farm offline, compartilhar, confirmações.

var _stack: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func is_open() -> bool:
	return not _stack.is_empty()


func back() -> void:
	if is_open():
		close_top()


func close_top() -> void:
	if _stack.is_empty():
		return
	var dim: Control = _stack.pop_back()
	var tw := create_tween()
	tw.tween_property(dim, "modulate:a", 0.0, 0.12)
	tw.tween_callback(dim.queue_free)
	Sfx.play("tab", 0.8)


## Abre uma janela. Devolve o painel (para ajustes). `body` entra abaixo do título.
func open(title: String, body: Control, closable: bool = true, width: float = 620.0) -> PanelContainer:
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.01, 0.07, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.add_child(center)
	var panel := Kit.panel(Pal.PANEL, 36, 22, Pal.GOLD, 4)
	panel.custom_minimum_size = Vector2(minf(width, size.x - 40.0), 0)
	center.add_child(panel)
	var v := Kit.vbox(14)
	panel.add_child(v)
	if title != "":
		var t := Kit.label(title, 40, Pal.GOLD, 9, 700)
		t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(t)
	v.add_child(body)
	if closable:
		var cb := Kit.button(Loc.t("ui.close"), "gray", 28)
		cb.pressed.connect(close_top)
		v.add_child(cb)
	_stack.append(dim)
	panel.pivot_offset = Vector2(panel.custom_minimum_size.x * 0.5, 300)
	panel.scale = Vector2(0.8, 0.8)
	dim.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(dim, "modulate:a", 1.0, 0.12)
	tw.parallel().tween_property(panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return panel


func message(title: String, text: String) -> void:
	var l := Kit.label(text, 28, Color.WHITE, 5, 600)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(540, 0)
	open(title, l)


func confirm(title: String, text: String, on_yes: Callable, yes_label: String = "", kind: String = "green") -> void:
	var v := Kit.vbox(16)
	var l := Kit.label(text, 28, Color.WHITE, 5, 600)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(540, 0)
	v.add_child(l)
	var row := Kit.hbox(12)
	v.add_child(row)
	var no := Kit.button(Loc.t("ui.cancel"), "gray", 28)
	no.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	no.pressed.connect(close_top)
	row.add_child(no)
	var yes := Kit.button(yes_label if yes_label != "" else Loc.t("ui.yes"), kind, 28)
	yes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	yes.pressed.connect(func():
		close_top()
		on_yes.call())
	row.add_child(yes)
	open(title, v, false)


# ---------------------------------------------------------------- compartilhar

func share_sheet(text: String) -> void:
	var v := Kit.vbox(12)
	var l := Kit.label(text, 24, Color.WHITE, 4, 600)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(540, 0)
	var box := Kit.panel(Pal.PANEL2, 20, 14)
	box.add_child(l)
	v.add_child(box)
	var row := Kit.hbox(10)
	v.add_child(row)
	var wa := Kit.button(Loc.t("share.whatsapp"), "green", 26)
	wa.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wa.pressed.connect(func():
		Share.whatsapp(text)
		G.d.stats.shares = float(G.d.stats.shares) + 1)
	row.add_child(wa)
	var tg := Kit.button(Loc.t("share.telegram"), "blue", 26)
	tg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tg.pressed.connect(func():
		Share.telegram(text)
		G.d.stats.shares = float(G.d.stats.shares) + 1)
	row.add_child(tg)
	var cp := Kit.button(Loc.t("share.copy"), "orange", 26)
	cp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cp.pressed.connect(func():
		Share.copy(text)
		G.toast.emit(Loc.t("share.copied"), "good"))
	row.add_child(cp)
	open(Loc.t("more.share"), v, true)


# ---------------------------------------------------------------- diário do farm offline

func offline(report: Dictionary, diary: Array) -> void:
	var v := Kit.vbox(12)
	var away := Kit.label(Loc.t("offline.away", [NumFmt.duration(float(report.away))]), 28, Color.WHITE, 6, 600)
	away.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(away)
	if bool(report.capped):
		var cap := Kit.label(Loc.t("offline.cap", [NumFmt.duration(float(report.used_real))]), 22, Pal.TEXT_DIM, 4, 600)
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(cap)
	var grid := Kit.panel(Pal.PANEL2, 24, 14)
	v.add_child(grid)
	var gv := Kit.vbox(8)
	grid.add_child(gv)
	var rows: Array = []
	rows.append(["ic_coin", "offline.gold", "+" + NumFmt.fmt(float(report.gold)), true])
	rows.append(["role_melee", "offline.kills", "+" + NumFmt.fmt(float(report.kills)), false])
	if int(report.stages) > 0:
		rows.append(["ic_arrow_up", "offline.stage", "%d → %d" % [int(report.stage_from), int(report.stage_to)], false])
	if int(report.bosses) > 0:
		rows.append(["ic_skull", "offline.bosses", "+%d" % int(report.bosses), false])
	if int(report.gems) > 0:
		rows.append(["ic_gem", "offline.gems", "+%d" % int(report.gems), false])
	if int(report.levels) > 0:
		rows.append(["ic_star", "offline.levels", "+%d" % int(report.levels), false])
	for r in rows:
		var row := Kit.hbox(12)
		row.add_child(Kit.icon(r[0], 44))
		var name_l := Kit.label(Loc.t(r[1]), 28, Color.WHITE, 5, 600)
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_l)
		var val := Kit.label("", 32, Pal.GOLD, 6, 700)
		row.add_child(val)
		gv.add_child(row)
		# contador animado
		var final_text: String = r[2]
		if bool(r[3]):
			var target := float(report.gold)
			var tw := create_tween()
			tw.tween_method(func(x: float): val.text = "+" + NumFmt.fmt(x), 0.0, target, 1.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
			tw.tween_callback(func(): val.text = final_text)
		else:
			val.text = final_text
	# diário
	var dt := Kit.label(Loc.t("offline.diary"), 26, Color("#9fe9ff"), 5, 700)
	v.add_child(dt)
	var dbox := Kit.panel(Color("#fff6dc"), 20, 14)
	v.add_child(dbox)
	var dv := Kit.vbox(6)
	dbox.add_child(dv)
	for ln in diary:
		var line := Kit.label("• " + Loc.t(String(ln.k), ln.a), 22, Color("#3a2a40"), 0, 600)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(520, 0)
		dv.add_child(line)
	var btns := Kit.hbox(10)
	v.add_child(btns)
	var sh := Kit.button(Loc.t("offline.share"), "blue", 26)
	sh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sh.pressed.connect(func(): share_sheet(Share.diary_text(report)))
	btns.add_child(sh)
	var ok := Kit.button(Loc.t("offline.claim"), "green", 30)
	ok.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ok.custom_minimum_size = Vector2(0, 76)
	ok.pressed.connect(func():
		close_top()
		Sfx.play("fanfare", 1.0))
	btns.add_child(ok)
	open(Loc.t("offline.title"), v, false)
	Sfx.play("fanfare", 1.0)


# ---------------------------------------------------------------- configurações

func settings() -> void:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(560, minf(size.y * 0.62, 760))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := Kit.vbox(12)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	v.add_child(_slider_row(Loc.t("set.sfx"), float(G.d.settings.sfx), func(x: float): G.set_setting("sfx", x)))
	v.add_child(_slider_row(Loc.t("set.music"), float(G.d.settings.music), func(x: float): G.set_setting("music", x)))
	v.add_child(_toggle_row(Loc.t("set.vibration"), bool(G.d.settings.vibration), func(b: bool): G.set_setting("vibration", b)))
	v.add_child(_toggle_row(Loc.t("set.shake"), bool(G.d.settings.shake), func(b: bool): G.set_setting("shake", b)))
	v.add_child(_toggle_row(Loc.t("set.auto_advance"), bool(G.d.settings.auto_advance), func(b: bool): G.set_setting("auto_advance", b)))
	var up_ok := Econ.auto_up_unlocked(G.d)
	v.add_child(_toggle_row(Loc.t("set.auto_up") + ("" if up_ok else "  (" + Loc.t("set.auto_up_locked") + ")"), bool(G.d.settings.auto_up) and up_ok,
		func(b: bool): G.set_setting("auto_up", b and up_ok), not up_ok))
	var fury_ok := bool(G.dir.mods.auto_fury)
	v.add_child(_toggle_row(Loc.t("set.auto_fury") + ("" if fury_ok else "  (" + Loc.t("set.auto_fury_locked") + ")"), bool(G.d.settings.auto_fury) and fury_ok,
		func(b: bool): G.set_setting("auto_fury", b and fury_ok), not fury_ok))
	v.add_child(_toggle_row(Loc.t("set.auto_team"), bool(G.d.settings.auto_team), func(b: bool): G.set_auto_team(b)))
	v.add_child(_toggle_row(Loc.t("set.fps30"), bool(G.d.settings.fps30), func(b: bool): G.set_setting("fps30", b)))
	v.add_child(_toggle_row(Loc.t("set.numbers"), bool(G.d.settings.sci), func(b: bool): G.set_setting("sci", b)))
	# idioma
	var lang := Kit.hbox(8)
	var ll := Kit.label(Loc.t("set.language"), 26, Color.WHITE, 5, 600)
	ll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lang.add_child(ll)
	for opt in [["auto", "set.lang_auto"], ["pt", "set.lang_pt"], ["en", "set.lang_en"]]:
		var code: String = opt[0]
		var b := Kit.button(Loc.t(opt[1]), "green" if String(G.d.settings.lang) == code else "gray", 20)
		b.custom_minimum_size = Vector2(120, 52)
		b.pressed.connect(func():
			G.set_setting("lang", code)
			close_top()
			G.toast.emit(Loc.t("toast.saved"), "good"))
		lang.add_child(b)
	v.add_child(lang)
	var rs := Kit.button(Loc.t("set.reset"), "red", 24)
	rs.pressed.connect(func():
		close_top()
		confirm(Loc.t("set.reset"), Loc.t("set.reset_confirm"), func():
			G.reset_all()
			get_tree().reload_current_scene(), "", "red"))
	v.add_child(rs)
	v.add_child(Kit.label(Loc.t("more.credits"), 20, Pal.TEXT_DIM, 4, 600))
	open(Loc.t("more.settings"), sc, true)


# ---------------------------------------------------------------- relíquias

func relic_detail(id: String) -> void:
	var has: bool = G.d.relics.has(id)
	var r: Dictionary = RelicDefs.DATA[id]
	var col: Color = Pal.RARITY[r.rarity]
	var v := Kit.vbox(10)
	var frame := Kit.panel(Pal.PANEL2, 30, 16, col, 5)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var ic := Kit.icon("rl_" + id, 170)
	ic.modulate = Color.WHITE if has else Color(0.04, 0.02, 0.08, 0.85)
	frame.add_child(ic)
	v.add_child(frame)
	var rl := Kit.label(Loc.t("relic.rarity." + String(r.rarity)), 26, col, 6, 700)
	rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(rl)
	var lvl := int(G.d.relics[id].lvl) if has else 0
	var l1 := Kit.label(Loc.t("relic.lvl", [lvl]) if has else Loc.t("relic.unknown"), 28, Pal.GOLD, 6, 700)
	l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l1)
	if has:
		var cur := Kit.label(Loc.stat_text(String(r.stat), RelicDefs.value(id, lvl)), 26, Color.WHITE, 5, 600)
		cur.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(cur)
		if lvl < RelicDefs.MAX_LEVEL:
			var nx := Kit.label("→ " + Loc.stat_text(String(r.stat), RelicDefs.value(id, lvl + 1)), 22, Color("#9fe9ff"), 5, 600)
			nx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(nx)
	open(Loc.t("relic." + id) if has else Loc.t("relic.unknown"), v, true)


func marmita_reveal(results: Array) -> void:
	var v := Kit.vbox(12)
	var best := 0
	for r in results:
		best = maxi(best, RelicDefs.RARITY_ORDER.find(r.rarity))
	if results.size() == 1:
		var r0: Dictionary = results[0]
		var col: Color = Pal.RARITY[r0.rarity]
		var glow := Kit.panel(Color(col.r, col.g, col.b, 0.22), 40, 22, col, 5)
		glow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var ic := Kit.icon("rl_" + String(r0.id), 200)
		glow.add_child(ic)
		v.add_child(glow)
		var nm := Kit.label(Loc.t("relic." + String(r0.id)), 32, col, 7, 700)
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nm)
		var tag := Kit.label(Loc.t("relic.new") if bool(r0.new) else Loc.t("relic.up") + "  " + Loc.t("relic.lvl", [int(r0.lvl)]), 28, Pal.GOLD, 6, 700)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(tag)
		var st := Kit.label(Loc.stat_text(String(RelicDefs.DATA[r0.id].stat), RelicDefs.value(String(r0.id), int(r0.lvl))), 24, Color.WHITE, 5, 600)
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(st)
		glow.pivot_offset = Vector2(120, 120)
		glow.scale = Vector2(0.3, 0.3)
		var tw := create_tween()
		tw.tween_property(glow, "scale", Vector2(1.1, 1.1), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(glow, "scale", Vector2.ONE, 0.1)
	else:
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		v.add_child(grid)
		var i := 0
		for r1 in results:
			var col1: Color = Pal.RARITY[r1.rarity]
			var cell := Kit.panel(Color(col1.r, col1.g, col1.b, 0.18), 18, 6, col1, 4)
			cell.custom_minimum_size = Vector2(102, 128)
			var cv := Kit.vbox(0)
			cell.add_child(cv)
			var ic1 := Kit.icon("rl_" + String(r1.id), 74)
			ic1.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			cv.add_child(ic1)
			var tg := Kit.label(Loc.t("relic.new") if bool(r1.new) else "+1", 17, Pal.GOLD, 4, 700)
			tg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cv.add_child(tg)
			grid.add_child(cell)
			cell.pivot_offset = Vector2(51, 64)
			cell.scale = Vector2.ZERO
			var tw2 := create_tween()
			tw2.tween_interval(0.07 * i)
			tw2.tween_property(cell, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			i += 1
	var ok := Kit.button(Loc.t("ui.continue"), "green", 30)
	ok.custom_minimum_size = Vector2(0, 76)
	ok.pressed.connect(close_top)
	v.add_child(ok)
	open(Loc.t("relic.marmita"), v, false, 640)
	Sfx.play("fanfare" if best >= 2 else "coin", 1.0)


# ---------------------------------------------------------------- bestiário, estatísticas, foto

func bestiary() -> void:
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(580, minf(size.y * 0.6, 740))
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var v := Kit.vbox(10)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(v)
	var best := int(G.d.stage.best)
	for wi in WorldDefs.DATA.size():
		var w: Dictionary = WorldDefs.DATA[wi]
		var seen_world := best >= wi * WorldDefs.STAGES_PER_WORLD + 1 or wi == 0
		v.add_child(Kit.label(Loc.t("world." + String(w.id)) if seen_world else "???", 26, Pal.GOLD, 6, 700))
		var grid := GridContainer.new()
		grid.columns = 5
		grid.add_theme_constant_override("h_separation", 6)
		grid.add_theme_constant_override("v_separation", 6)
		v.add_child(grid)
		var ids: Array = w.regular.duplicate()
		ids.append(w.boss)
		for en in ids:
			var is_boss: bool = en == w.boss
			var seen := seen_world and (not is_boss or best >= (wi + 1) * WorldDefs.STAGES_PER_WORLD)
			var cell := Kit.panel(Pal.PANEL2, 14, 4)
			cell.custom_minimum_size = Vector2(104, 112)
			var cv := Kit.vbox(0)
			cell.add_child(cv)
			var ic := Kit.icon("en_" + String(en), 80)
			ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			ic.modulate = Color.WHITE if seen else Color(0.04, 0.02, 0.08, 0.85)
			cv.add_child(ic)
			var nl := Kit.label(Loc.t("enemy." + String(en)) if seen else "???", 13, Color.WHITE, 3, 600)
			nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			cv.add_child(nl)
			grid.add_child(cell)
	open(Loc.t("more.bestiary"), sc, true, 640)


func stats() -> void:
	var d := G.d
	var v := Kit.vbox(8)
	var rows := [
		["stats.best", str(int(d.stage.best))], ["stats.kills", NumFmt.fmt(float(d.stats.kills))],
		["stats.bosses", NumFmt.fmt(float(d.stats.bosses))], ["stats.stages", NumFmt.fmt(float(d.stats.stages))],
		["stats.gold", NumFmt.fmt(float(d.stats.gold_total))], ["stats.upgrades", NumFmt.fmt(float(d.stats.upgrades))],
		["stats.crits", NumFmt.fmt(float(d.stats.crits))], ["stats.fury", NumFmt.fmt(float(d.stats.fury))],
		["stats.prestige", str(int(d.prestige.count))], ["stats.play", NumFmt.duration(float(d.stats.play_s))],
		["stats.offline", NumFmt.duration(float(d.stats.offline_s))],
	]
	var box := Kit.panel(Pal.PANEL2, 22, 14)
	var bv := Kit.vbox(6)
	box.add_child(bv)
	for r in rows:
		var h := Kit.hbox(8)
		var l := Kit.label(Loc.t(r[0]), 24, Color.WHITE, 5, 600)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(l)
		h.add_child(Kit.label(String(r[1]), 26, Pal.GOLD, 5, 700))
		bv.add_child(h)
	v.add_child(box)
	open(Loc.t("stats.title"), v, true)


func photo() -> void:
	var v := Kit.vbox(12)
	var polaroid := Kit.panel(Color("#fffaf0"), 12, 18)
	var inner := Kit.vbox(10)
	polaroid.add_child(inner)
	var scene := Control.new()
	scene.custom_minimum_size = Vector2(500, 330)
	scene.clip_contents = true
	var wid: String = WorldDefs.DATA[WorldDefs.index_of(maxi(1, int(G.d.stage.cleared)))].id
	var bg := TextureRect.new()
	bg.texture = Art.tex("bg_" + wid)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	scene.add_child(bg)
	var party: Array = G.d.party
	var n := party.size()
	for i in n:
		var t := TextureRect.new()
		t.texture = Art.tex("hero_" + String(party[i]))
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.custom_minimum_size = Vector2(190, 190)
		t.size = Vector2(190, 190)
		var spacing := (500.0 - 190.0) / maxf(float(n - 1), 1.0)
		t.position = Vector2(5.0 + spacing * i if n > 1 else 155.0, 150.0 + (i % 2) * 10.0)
		scene.add_child(t)
	inner.add_child(scene)
	var cap := Kit.label(Loc.t("photo.caption", [int(G.d.stage.best)]), 30, Color("#3a2a40"), 0, 700)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inner.add_child(cap)
	polaroid.pivot_offset = Vector2(280, 250)
	polaroid.rotation = -0.025
	v.add_child(polaroid)
	var hint := Kit.label(Loc.t("photo.hint"), 22, Pal.TEXT_DIM, 4, 600)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)
	var sh := Kit.button(Loc.t("more.share"), "green", 26)
	sh.pressed.connect(func(): share_sheet(Share.progress_text()))
	v.add_child(sh)
	open(Loc.t("photo.title"), v, true)


func _toggle_row(text: String, value: bool, on_change: Callable, disabled: bool = false) -> Control:
	var row := Kit.hbox(10)
	var l := Kit.label(text, 24, Color.WHITE if not disabled else Pal.TEXT_DIM, 5, 600)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(l)
	var b := Kit.button(Loc.t("ui.on") if value else Loc.t("ui.off"), "green" if value else "gray", 22)
	b.custom_minimum_size = Vector2(150, 54)
	b.disabled = disabled
	b.pressed.connect(func():
		var nv := b.text == Loc.t("ui.off")
		b.text = Loc.t("ui.on") if nv else Loc.t("ui.off")
		Kit.style_button(b, "green" if nv else "gray", 22)
		on_change.call(nv))
	row.add_child(b)
	return row


func _slider_row(text: String, value: float, on_change: Callable) -> Control:
	var row := Kit.hbox(12)
	var l := Kit.label(text, 24, Color.WHITE, 5, 600)
	l.custom_minimum_size = Vector2(170, 0)
	row.add_child(l)
	var s := Kit.slider(value, on_change)
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(s)
	return row
