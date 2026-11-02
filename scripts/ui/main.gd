class_name Main
extends Control
## Tela principal: HUD, batalha, abas e barra de navegação. Toda a interface é montada aqui em código.

const HUD_H := 150.0
const NAV_H := 112.0
const TAB_ICONS: Array[String] = ["tab_family", "tab_relics", "tab_bless", "tab_goals", "tab_more"]
const TAB_KEYS: Array[String] = ["family", "relics", "bless", "goals", "more"]

var battle: BattleView
var fx: FxLayer
var hud: Control
var world_lbl: Label
var stage_lbl: Label
var power_lbl: Label
var wave_lbl: Label
var income_lbl: Label
var gold_lbl: Label
var gems_lbl: Label
var bless_lbl: Label
var gold_chip: PanelContainer
var bless_chip: PanelContainer
var gear_btn: Button
var speed_btn: Button
var fury_btn: FuryButton
var challenge_btn: Button
var nav: HBoxContainer
var nav_btns: Array = []
var tab_area: PanelContainer
var pages: Array = []
var cur_tab := 0
var popups: Popups
var tutorial: Tutorial
var overlay_off: Control
var _off_bar: ProgressBar
var _off_lbl: Label
var banner_left := 0.0                          ## segundos restantes de um banner na tela (o tutorial some para não cobri-lo)
var _ui_t := 0.0
var _toast: PanelContainer
var _toast_lbl: Label
var _toast_tw: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	G.changed.connect(_on_changed)
	G.toast.connect(show_toast)
	G.offline_done.connect(_on_offline_done)
	G.back_pressed.connect(_on_back)
	resized.connect(_layout)
	# o pai é um Node (não um Control): o tamanho vem do viewport
	get_viewport().size_changed.connect(_fit)
	_fit()
	_refresh_all()


## Sobe a árvore até achar a tela principal.
static func find(from: Node) -> Main:
	var n: Node = from
	while n != null:
		if n is Main:
			return n as Main
		n = n.get_parent()
	return null


## Retângulo (em coordenadas da tela) do botão de comprar/recrutar de um herói, para o tutorial.
func family_button_rect(id: String) -> Rect2:
	var fam := pages[0] as TabFamily
	if fam == null or not fam.has_card(id):
		return Rect2(size.x * 0.5, size.y * 0.7, 10, 10)
	return fam.card_button_rect(id)


func _fit() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size
	if tutorial != null:
		tutorial.size = size
	_layout()


# ---------------------------------------------------------------- construção

func _build() -> void:
	var bg := ColorRect.new()
	bg.color = Pal.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	# batalha
	battle = BattleView.new()
	add_child(battle)
	# HUD
	hud = Control.new()
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	var hud_bg := ColorRect.new()
	hud_bg.color = Color("#251a3b")
	hud_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(hud_bg)
	world_lbl = Kit.label("", 22, Pal.TEXT_DIM, 4, 600)
	hud.add_child(world_lbl)
	stage_lbl = Kit.label("", 40, Color.WHITE, 8, 700)
	hud.add_child(stage_lbl)
	gear_btn = Kit.button("", "gray", 20)
	gear_btn.custom_minimum_size = Vector2(64, 64)
	gear_btn.pressed.connect(func(): popups.settings())
	hud.add_child(gear_btn)
	var gear_icon := Kit.icon("ic_gear", 40)
	gear_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	gear_icon.offset_left = 8
	gear_icon.offset_top = 6
	gear_icon.offset_right = -8
	gear_icon.offset_bottom = -12
	gear_btn.add_child(gear_icon)
	var chips := Kit.hbox(10)
	chips.name = "chips"
	hud.add_child(chips)
	var gc := _chip("ic_coin")
	gold_chip = gc[0]
	gold_lbl = gc[1]
	chips.add_child(gold_chip)
	var gm := _chip("ic_gem")
	gems_lbl = gm[1]
	chips.add_child(gm[0])
	var bc := _chip("ic_bless")
	bless_chip = bc[0]
	bless_lbl = bc[1]
	chips.add_child(bless_chip)
	power_lbl = Kit.label("", 22, Pal.TEXT_DIM, 4, 600)
	power_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(power_lbl)
	income_lbl = Kit.label("", 20, Color("#9fe9ff"), 4, 600)
	income_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(income_lbl)
	# sobreposições da batalha
	wave_lbl = Kit.label("", 24, Color.WHITE, 6, 700)
	battle.add_child(wave_lbl)
	speed_btn = Kit.button("", "blue", 26)
	speed_btn.custom_minimum_size = Vector2(96, 64)
	speed_btn.pressed.connect(func(): G.cycle_speed())
	battle.add_child(speed_btn)
	fury_btn = FuryButton.new()
	fury_btn.pressed.connect(_on_fury)
	battle.add_child(fury_btn)
	challenge_btn = Kit.button("", "red", 26)
	challenge_btn.custom_minimum_size = Vector2(230, 60)
	challenge_btn.pressed.connect(func(): G.force_retry())
	battle.add_child(challenge_btn)
	# abas
	tab_area = PanelContainer.new()
	var sb := Kit.box(Pal.PANEL2, 30)
	sb.corner_radius_bottom_left = 0
	sb.corner_radius_bottom_right = 0
	sb.set_content_margin_all(12)
	tab_area.add_theme_stylebox_override("panel", sb)
	add_child(tab_area)
	for pc in [TabFamily, TabRelics, TabBless, TabGoals, TabMore]:
		var pg: Control = pc.new()
		pages.append(pg)
		tab_area.add_child(pg)
		pg.call("build")
		pg.visible = false
	# navegação
	nav = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 0)
	add_child(nav)
	for i in 5:
		var nb := NavButton.new()
		nb.setup(TAB_ICONS[i], Loc.t("tab." + TAB_KEYS[i]))
		nb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nb.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var idx := i
		nb.pressed.connect(func(): select_tab(idx))
		nav.add_child(nb)
		nav_btns.append(nb)
	# efeitos por cima de tudo + popups
	fx = FxLayer.new()
	fx.z_index = 60
	add_child(fx)
	battle.fx = fx
	fx.coin_arrived.connect(_on_coin_arrived)
	popups = Popups.new()
	popups.z_index = 100
	add_child(popups)
	# aviso (toast)
	_toast = Kit.panel(Color(0.1, 0.06, 0.18, 0.95), 24, 12, Pal.GOLD, 3)
	_toast_lbl = Kit.label("", 26, Color.WHITE, 5, 700)
	_toast.add_child(_toast_lbl)
	_toast.visible = false
	_toast.z_index = 80
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_toast)
	# contagem offline
	overlay_off = Control.new()
	overlay_off.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_off.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_off.visible = false
	overlay_off.z_index = 120
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.02, 0.1, 0.9)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_off.add_child(dim)
	var oc := VBoxContainer.new()
	oc.set_anchors_preset(Control.PRESET_CENTER)
	oc.custom_minimum_size = Vector2(520, 200)
	oc.position = Vector2(-260, -100)
	oc.add_theme_constant_override("separation", 20)
	overlay_off.add_child(oc)
	_off_lbl = Kit.label("", 36, Color.WHITE, 8, 700)
	_off_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	oc.add_child(_off_lbl)
	_off_bar = Kit.bar(Pal.GREEN, Color(0, 0, 0, 0.5), 30)
	oc.add_child(_off_bar)
	add_child(overlay_off)
	tutorial = Tutorial.new()
	tutorial.main = self
	tutorial.z_index = 70
	add_child(tutorial)
	select_tab(0)


func _chip(icon: String) -> Array:
	var p := Kit.panel(Color(0.1, 0.06, 0.18, 0.85), 30, 6)
	var h := Kit.hbox(8)
	p.add_child(h)
	h.add_child(Kit.icon(icon, 40))
	var l := Kit.label("0", 30, Color.WHITE, 6, 700)
	l.custom_minimum_size = Vector2(70, 0)
	h.add_child(l)
	return [p, l]


# ---------------------------------------------------------------- layout

func _safe() -> Vector2:
	if not OS.has_feature("mobile"):
		return Vector2.ZERO
	var r := DisplayServer.get_display_safe_area()
	var scr := DisplayServer.screen_get_size()
	var vis := get_viewport().get_visible_rect().size
	var sy := vis.y / float(maxi(scr.y, 1))
	return Vector2(maxf(0.0, r.position.y) * sy, maxf(0.0, scr.y - r.end.y) * sy)


func _layout() -> void:
	var w := size.x
	var h := size.y
	var safe := _safe()
	var hud_h := HUD_H + safe.x
	var bh := w * 500.0 / 720.0
	hud.position = Vector2.ZERO
	hud.size = Vector2(w, hud_h)
	world_lbl.position = Vector2(24, safe.x + 8)
	stage_lbl.position = Vector2(24, safe.x + 32)
	gear_btn.position = Vector2(w - 88, safe.x + 14)
	hud.get_node("chips").position = Vector2(14, safe.x + 88)
	power_lbl.position = Vector2(w - 330, safe.x + 14)
	power_lbl.size = Vector2(230, 30)
	income_lbl.position = Vector2(w - 330, safe.x + 44)
	income_lbl.size = Vector2(230, 28)
	battle.position = Vector2(0, hud_h)
	battle.size = Vector2(w, bh)
	wave_lbl.position = Vector2(18, 58)
	speed_btn.position = Vector2(14, bh - 80)
	fury_btn.position = Vector2(w - 138, bh - 138)
	fury_btn.size = Vector2(124, 124)
	challenge_btn.position = Vector2((w - 230) * 0.5, bh - 76)
	var nav_h := NAV_H + safe.y
	nav.position = Vector2(0, h - nav_h)
	nav.size = Vector2(w, nav_h)
	tab_area.position = Vector2(0, hud_h + bh)
	tab_area.size = Vector2(w, maxf(0.0, h - hud_h - bh - nav_h))
	fx.coin_target = Vector2(110, safe.x + 108)
	_toast.position = Vector2(w * 0.5 - _toast.size.x * 0.5, hud_h + 70)


func select_tab(i: int) -> void:
	cur_tab = i
	for k in pages.size():
		pages[k].visible = k == i
	for k in nav_btns.size():
		nav_btns[k].set_active(k == i)
	Sfx.play("tab", 1.0)
	_refresh_all()


# ---------------------------------------------------------------- atualização

func _on_changed() -> void:
	_refresh_all()


func _refresh_all() -> void:
	_refresh_hud()
	var pg: Control = pages[cur_tab]
	if pg.has_method("refresh"):
		pg.refresh()
	for k in nav_btns.size():
		nav_btns[k].set_badge(_badge(k))


func _badge(i: int) -> bool:
	match i:
		0:
			for id in HeroDefs.IDS:
				var hh: Dictionary = G.d.heroes[id]
				if bool(hh.owned):
					if float(G.d.cur.gold) >= Econ.level_cost(id, int(hh.lvl)) and G.d.party.has(id):
						return true
				elif Econ.hero_available(G.d, id) and float(G.d.cur.gold) >= Econ.recruit_cost(id):
					return true
		1:
			return int(G.d.cur.gems) >= Econ.MARMITA_COST
		2:
			return int(G.d.cur.bless) > 0 or Econ.bless_gain(G.d) > 0
		3:
			return Goals.ach_claimable(G.d) + Goals.missions_claimable(G.d) > 0 or Goals.login_can_claim(G.d)
		4:
			return Goals.fornada_state(G.d).state == "ready"
	return false


func _refresh_hud() -> void:
	var d := G.d
	var dir := G.dir
	gold_lbl.text = NumFmt.fmt(float(d.cur.gold))
	gems_lbl.text = NumFmt.fmt(float(d.cur.gems))
	bless_chip.visible = int(d.cur.bless) > 0 or int(d.prestige.count) > 0
	bless_lbl.text = NumFmt.fmt(float(d.cur.bless))
	var stage := dir.stage
	var wid: String = WorldDefs.DATA[WorldDefs.index_of(stage)].id
	var cyc := WorldDefs.cycle_of(stage)
	world_lbl.text = Loc.t("world." + wid) + ((" · " + Loc.t("hud.nightmare", [cyc])) if cyc > 0 else "") \
		+ ("" if dir.frontier else " · " + Loc.t("hud.farming"))
	stage_lbl.text = Loc.t("hud.stage", [stage])
	power_lbl.text = Loc.t("hud.power") + " " + NumFmt.fmt(dir.power)
	income_lbl.text = Loc.t("hud.income", [NumFmt.fmt(G.income_ph)]) if G.income_ph > 0.0 else ""
	var sim := dir.sim
	if sim != null:
		Sfx.play_music("music_boss" if sim.boss_stage else "music_main")
		wave_lbl.text = "" if sim.boss_stage else Loc.t("hud.wave", [maxi(sim.wave, 1), sim.waves_total])
		fury_btn.progress = sim.fury / 100.0
		fury_btn.active = sim.fury_t / maxf(sim.fury_dur, 0.1) if sim.fury_t > 0.0 else 0.0
	speed_btn.text = "x%d" % G.speed
	var blocked := float(d.stage.blocked_power) > 0.0 and bool(d.settings.auto_advance)
	challenge_btn.visible = blocked
	challenge_btn.text = Loc.t("hud.challenge")


func _process(delta: float) -> void:
	_ui_t += delta
	banner_left = maxf(banner_left - delta, 0.0)
	if G.offline_busy:
		overlay_off.visible = true
		_off_lbl.text = Loc.t("offline.counting")
		_off_bar.value = G.offline_progress
	else:
		overlay_off.visible = false
	# eventos de alto nível da batalha
	if not G.dir.out.is_empty():
		for ev in G.dir.out:
			_on_director_event(ev)
		G.dir.out.clear()
	if _ui_t >= 0.15:
		_ui_t = 0.0
		_refresh_all()


func _on_director_event(ev: Dictionary) -> void:
	match String(ev.t):
		"encounter":
			if bool(ev.boss):
				banner(Loc.t("hud.boss_incoming"), Pal.RED)
				Sfx.play("boss_roar", 1.0)
				battle.shake(6.0)
		"clear":
			if bool(ev.boss):
				banner(Loc.t("hud.boss_down"), Pal.GOLD)
				Sfx.play("fanfare", 1.0)
			elif bool(ev.first):
				banner(Loc.t("hud.cleared"), Pal.GREEN, 0.9)
		"fail":
			banner(Loc.t("hud.family_down"), Pal.ORANGE)
			Sfx.play("fail", 1.0)


func _on_fury() -> void:
	if G.activate_fury():
		Sfx.vibrate(30)


func _on_coin_arrived(_n: int) -> void:
	var tw := create_tween()
	gold_chip.pivot_offset = gold_chip.size * 0.5
	tw.tween_property(gold_chip, "scale", Vector2(1.12, 1.12), 0.05)
	tw.tween_property(gold_chip, "scale", Vector2.ONE, 0.09)
	Sfx.play("coin", 1.0 + randf() * 0.2)


func _on_offline_done(report: Dictionary, diary: Array) -> void:
	popups.offline(report, diary)


func _on_back() -> void:
	popups.back()


# ---------------------------------------------------------------- banners e avisos

func banner(text: String, col: Color, life: float = 1.5) -> void:
	banner_left = maxf(banner_left, life + 0.6)
	var l := Kit.label(text, 56, col, 12, 700)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.size = Vector2(battle.size.x, 80)
	l.position = Vector2(0, battle.size.y * 0.22)
	l.pivot_offset = l.size * 0.5
	l.scale = Vector2(0.3, 0.3)
	l.modulate.a = 0.0
	battle.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "scale", Vector2(1.15, 1.15), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 1.0, 0.12)
	tw.tween_property(l, "scale", Vector2.ONE, 0.1)
	tw.tween_interval(life)
	tw.tween_property(l, "modulate:a", 0.0, 0.25)
	tw.tween_callback(l.queue_free)


func show_toast(text: String, kind: String = "info") -> void:
	_toast_lbl.text = text
	_toast_lbl.add_theme_color_override("font_color", Pal.GOLD if kind == "good" else Color.WHITE)
	_toast.reset_size()
	_toast.position = Vector2(size.x * 0.5 - _toast.size.x * 0.5, HUD_H + _safe().x + 70)
	_toast.visible = true
	_toast.modulate.a = 0.0
	if _toast_tw != null:
		_toast_tw.kill()
	_toast_tw = create_tween()
	_toast_tw.tween_property(_toast, "modulate:a", 1.0, 0.15)
	_toast_tw.tween_interval(1.8)
	_toast_tw.tween_property(_toast, "modulate:a", 0.0, 0.3)
	_toast_tw.tween_callback(func(): _toast.visible = false)


# ---------------------------------------------------------------- botão de Fúria

class FuryButton extends Control:
	signal pressed
	var progress := 0.0
	var active := 0.0
	var _t := 0.0
	var _tex: Texture2D

	func _ready() -> void:
		_tex = Art.tex("ic_fury")
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			pressed.emit()
			accept_event()

	func _draw() -> void:
		var c := size * 0.5
		var ready := progress >= 0.999 and active <= 0.0
		var pulse := 1.0 + (0.06 * sin(_t * 9.0) if ready else 0.0)
		var r := 50.0 * pulse
		if ready:
			draw_circle(c, r + 14.0, Color(1.0, 0.6, 0.1, 0.25 + 0.15 * sin(_t * 9.0)))
		draw_circle(c, r + 5.0, Color(0.08, 0.04, 0.12, 0.92))
		draw_circle(c, r - 2.0, Color("#3b2158") if not ready else Color("#7a2a1a"))
		draw_arc(c, r - 6.0, -PI * 0.5, PI * 1.5, 48, Color(1, 1, 1, 0.15), 10.0)
		if active > 0.0:
			draw_arc(c, r - 6.0, -PI * 0.5, -PI * 0.5 + TAU * active, 48, Color("#ff5a64"), 10.0)
		else:
			draw_arc(c, r - 6.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(progress, 0.0, 1.0), 48, Pal.GOLD if ready else Pal.ORANGE, 10.0)
		var s := 56.0 * (1.0 + (0.08 * sin(_t * 12.0) if active > 0.0 else 0.0))
		var tint := Color.WHITE if (ready or active > 0.0) else Color(1, 1, 1, 0.55)
		draw_texture_rect(_tex, Rect2(c.x - s * 0.5, c.y - s * 0.5 - 2.0, s, s), false, tint)
		if ready:
			var f := Kit.font(700)
			var t := Loc.t("hud.fury_ready")
			var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x
			var p := Vector2(c.x - w * 0.5, size.y - 4.0)
			draw_string_outline(f, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 7, Pal.OUTLINE)
			draw_string(f, p, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Pal.GOLD)


# ---------------------------------------------------------------- botão da barra de navegação

class NavButton extends Button:
	var icon_rect: TextureRect
	var lbl: Label
	var badge: Panel
	var _active := false

	func setup(icon_name: String, text: String) -> void:
		toggle_mode = false
		focus_mode = Control.FOCUS_NONE
		var st := Kit.box(Color("#1c1230"), 0)
		var sp := Kit.box(Color("#3b2c5e"), 0)
		add_theme_stylebox_override("normal", st)
		add_theme_stylebox_override("hover", st)
		add_theme_stylebox_override("pressed", sp)
		add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_theme_constant_override("separation", 0)
		add_child(v)
		icon_rect = Kit.icon(icon_name, 54)
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(icon_rect)
		lbl = Kit.label(text, 20, Pal.TEXT_DIM, 4, 700)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lbl)
		badge = Panel.new()
		badge.add_theme_stylebox_override("panel", Kit.box(Pal.RED, 12))
		badge.custom_minimum_size = Vector2(22, 22)
		badge.size = Vector2(22, 22)
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.visible = false
		add_child(badge)

	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED and badge != null:
			badge.position = Vector2(size.x * 0.5 + 16.0, 8.0)

	func set_active(a: bool) -> void:
		_active = a
		var sb := Kit.box(Color("#3b2c5e") if a else Color("#1c1230"), 0)
		if a:
			sb.border_width_top = 6
			sb.border_color = Pal.GOLD
		add_theme_stylebox_override("normal", sb)
		add_theme_stylebox_override("hover", sb)
		lbl.add_theme_color_override("font_color", Color.WHITE if a else Pal.TEXT_DIM)
		icon_rect.modulate = Color.WHITE if a else Color(1, 1, 1, 0.7)

	func set_badge(b: bool) -> void:
		badge.visible = b
