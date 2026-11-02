class_name TabFamily
extends VBoxContainer
## Aba "Família": lista de heróis com nível, estatísticas, botão MELHORAR (segure para comprar em
## sequência), recrutar e escalação do time.

const HEAD := Rect2(30, 6, 196, 196)
const HEAD_DOG := Rect2(40, 56, 216, 190)

var _cards: Dictionary = {}
var _mode_btns: Array = []
var _auto_btn: Button
var _auto_styled := false                       ## estilo atual do botão (false = azul/desligado)
var _slots_lbl: Label
var _list: VBoxContainer


func _init() -> void:
	add_theme_constant_override("separation", 8)
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func build() -> void:
	# --- cabeçalho: modo de compra + escalação automática ---
	var head := Kit.hbox(8)
	add_child(head)
	var modes := [[1, "x1"], [10, "x10"], [100, "x100"], [-1, ""]]
	for m in modes:
		var b := Kit.button(Loc.t("ui.max") if int(m[0]) < 0 else String(m[1]), "gray", 22)
		b.toggle_mode = true
		b.custom_minimum_size = Vector2(80, 52)
		var mode: int = m[0]
		b.pressed.connect(func(): G.set_buy_mode(mode))
		head.add_child(b)
		_mode_btns.append([mode, b])
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	_auto_btn = Kit.button("", "blue", 20)
	_auto_btn.custom_minimum_size = Vector2(196, 52)
	_auto_btn.pressed.connect(func(): G.set_auto_team(not bool(G.d.settings.auto_team)))
	head.add_child(_auto_btn)
	_slots_lbl = Kit.label("", 20, Pal.TEXT_DIM, 4, 600)
	add_child(_slots_lbl)
	# --- lista ---
	var s := Kit.scroll(10)
	add_child(s[0])
	_list = s[1]
	for id in HeroDefs.IDS:
		var c := HeroCard.new(id)
		_list.add_child(c)
		c.build()
		_cards[id] = c
	refresh()


func has_card(id: String) -> bool:
	return _cards.has(id)


func card_button_rect(id: String) -> Rect2:
	return _cards[id].btn.get_global_rect()


func refresh() -> void:
	for mb in _mode_btns:
		var b: Button = mb[1]
		b.set_pressed_no_signal(G.buy_mode == int(mb[0]))
		if int(mb[0]) < 0:
			b.text = Loc.t("ui.max")
	var cap := Econ.slots(G.d)
	_slots_lbl.text = Loc.t("hero.slots", [G.d.party.size(), cap])
	var auto_on := bool(G.d.settings.auto_team)
	_auto_btn.text = Loc.t("hero.auto_team") + (" ✓" if auto_on else "")
	if auto_on != _auto_styled:                     # style_button é caro (~2 ms): só quando o estado muda
		_auto_styled = auto_on
		Kit.style_button(_auto_btn, "green" if auto_on else "blue", 20)
	for id in _cards:
		_cards[id].refresh()


## Carta de herói
class HeroCard extends PanelContainer:
	var id: String
	var name_lbl: Label
	var lvl_lbl: Label
	var stats_lbl: Label
	var hp_lbl: Label
	var dps_icon: TextureRect
	var hp_icon: TextureRect
	var skill_lbl: Label
	var role_icon: TextureRect
	var portrait: TextureRect
	var pips: Array = []
	var btn: Kit.HoldButton
	var btn_title: Label
	var cost_lbl: Label
	var coin_icon: TextureRect
	var team_btn: Button
	var _state := ""
	var _team_styled := -1

	func _init(p_id: String) -> void:
		id = p_id

	func build() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		add_theme_stylebox_override("panel", Kit.box(Pal.PANEL, 24))
		custom_minimum_size = Vector2(0, 150)
		var m := MarginContainer.new()
		for k in ["left", "right", "top", "bottom"]:
			m.add_theme_constant_override("margin_" + k, 12)
		add_child(m)
		var row := Kit.hbox(12)
		m.add_child(row)
		# retrato
		var pw := Control.new()
		pw.custom_minimum_size = Vector2(112, 112)
		pw.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(pw)
		var role: String = HeroDefs.DATA[id].role
		var bg := Panel.new()
		bg.add_theme_stylebox_override("panel", Kit.box(Pal.PANEL3, 56))
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		pw.add_child(bg)
		portrait = TextureRect.new()
		var at := AtlasTexture.new()
		at.atlas = Art.tex("hero_" + id)
		at.region = HEAD_DOG if id == "caramelo" else HEAD
		portrait.texture = at
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
		portrait.offset_left = 4
		portrait.offset_top = 4
		portrait.offset_right = -4
		portrait.offset_bottom = -4
		pw.add_child(portrait)
		# info
		var info := Kit.vbox(2)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(info)
		var l1 := Kit.hbox(8)
		info.add_child(l1)
		name_lbl = Kit.label("", 27, Color.WHITE, 6, 700)
		name_lbl.clip_text = true
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l1.add_child(name_lbl)
		role_icon = Kit.icon("role_" + role, 34)
		l1.add_child(role_icon)
		var l2 := Kit.hbox(6)
		info.add_child(l2)
		lvl_lbl = Kit.label("", 24, Pal.GOLD, 5, 700)
		lvl_lbl.custom_minimum_size = Vector2(80, 0)
		l2.add_child(lvl_lbl)
		dps_icon = Kit.icon("ic_dps", 22)
		l2.add_child(dps_icon)
		stats_lbl = Kit.label("", 20, Color.WHITE, 4, 700)
		l2.add_child(stats_lbl)
		hp_icon = Kit.icon("ic_heart", 22)
		l2.add_child(hp_icon)
		hp_lbl = Kit.label("", 20, Color.WHITE, 4, 700)
		l2.add_child(hp_lbl)
		var l3 := Kit.hbox(6)
		info.add_child(l3)
		skill_lbl = Kit.label("", 20, Color("#9fe9ff"), 4, 600)
		skill_lbl.clip_text = true
		skill_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l3.add_child(skill_lbl)
		for i in 4:
			var s := Kit.icon("ic_star", 20)
			l3.add_child(s)
			pips.append(s)
		# compra
		var buy := Kit.vbox(6)
		buy.custom_minimum_size = Vector2(206, 0)
		buy.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(buy)
		btn = Kit.hold_button("", "green", 24)
		btn.custom_minimum_size = Vector2(206, 84)
		buy.add_child(btn)
		var bc := VBoxContainer.new()
		bc.set_anchors_preset(Control.PRESET_FULL_RECT)
		bc.alignment = BoxContainer.ALIGNMENT_CENTER
		bc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bc.add_theme_constant_override("separation", -2)
		btn.add_child(bc)
		btn_title = Kit.label("", 24, Color.WHITE, 6, 700)
		btn_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bc.add_child(btn_title)
		var cr := HBoxContainer.new()
		cr.alignment = BoxContainer.ALIGNMENT_CENTER
		cr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cr.add_theme_constant_override("separation", 6)
		bc.add_child(cr)
		coin_icon = Kit.icon("ic_coin", 28)
		cr.add_child(coin_icon)
		cost_lbl = Kit.label("", 24, Color.WHITE, 5, 700)
		cr.add_child(cost_lbl)
		btn.fired.connect(_on_buy)
		team_btn = Kit.button("", "blue", 20)
		team_btn.custom_minimum_size = Vector2(206, 44)
		team_btn.pressed.connect(func(): G.toggle_team(id))
		buy.add_child(team_btn)

	func _on_buy() -> void:
		var h: Dictionary = G.d.heroes[id]
		if bool(h.owned):
			var n := G.upgrade_hero(id)
			if n > 0:
				Sfx.play("upgrade", 1.0)
				Sfx.vibrate(10)
			else:
				Sfx.play("deny", 1.0)
		else:
			if G.recruit_hero(id):
				Sfx.play("recruit", 1.0)

	func _set_text(l, t: String) -> void:
		if l.text != t:
			l.text = t

	func refresh() -> void:
		var h: Dictionary = G.d.heroes[id]
		var gold := float(G.d.cur.gold)
		var owned: bool = h.owned
		var avail := Econ.hero_available(G.d, id)
		var state := "owned" if owned else ("avail" if avail else "locked")
		if state != _state:
			_state = state
			portrait.modulate = Color.WHITE if state != "locked" else Color(0.05, 0.03, 0.1, 0.85)
			team_btn.visible = owned
			role_icon.visible = state != "locked"
			dps_icon.visible = owned
			hp_icon.visible = owned
			for s in pips:
				s.visible = owned
		var skill: Dictionary = HeroDefs.DATA[id].skill
		match state:
			"owned":
				var lvl := int(h.lvl)
				_set_text(name_lbl, Loc.t("hero.%s.name" % id))
				_set_text(lvl_lbl, Loc.t("hero.level", [lvl]))
				var st := Econ.hero_stats(G.d, id, G.dir.mods)
				_set_text(stats_lbl, NumFmt.fmt(Econ.dps_of(st)))
				_set_text(hp_lbl, NumFmt.fmt(float(st.hp)))
				_set_text(skill_lbl, Loc.t("hero.%s.skill" % id))
				var rank := Econ.skill_rank(lvl)
				for i in pips.size():
					pips[i].modulate = Color.WHITE if i < rank else Color(0.3, 0.26, 0.4, 0.8)
				var n := G.buy_mode
				if n < 0:
					n = maxi(1, Econ.max_affordable(id, lvl, gold))
				var cost := Econ.bulk_cost(id, lvl, n)
				_set_text(btn_title, Loc.t("hero.upgrade") + (" x%d" % n if n > 1 else ""))
				_set_text(cost_lbl, NumFmt.fmt(cost))
				coin_icon.visible = true
				btn.disabled = gold < cost
				var inteam: bool = G.d.party.has(id)
				_set_text(team_btn, Loc.t("hero.in_team") if inteam else Loc.t("hero.bench"))
				if _team_styled != (1 if inteam else 0):
					_team_styled = 1 if inteam else 0
					Kit.style_button(team_btn, "green" if inteam else "gray", 20)
			"avail":
				_set_text(name_lbl, Loc.t("hero.%s.name" % id))
				_set_text(lvl_lbl, Loc.t("hero.%s.role" % id))
				_set_text(stats_lbl, "")
				_set_text(hp_lbl, "")
				_set_text(skill_lbl, Loc.t("hero.%s.skill" % id))
				var cost2 := Econ.recruit_cost(id)
				_set_text(btn_title, Loc.t("hero.recruit"))
				_set_text(cost_lbl, NumFmt.fmt(cost2))
				coin_icon.visible = true
				btn.disabled = gold < cost2
			_:
				_set_text(name_lbl, "???")
				_set_text(lvl_lbl, "")
				_set_text(stats_lbl, "")
				_set_text(hp_lbl, "")
				_set_text(skill_lbl, "")
				_set_text(btn_title, Loc.t("hero.locked", [int(HeroDefs.DATA[id].unlock)]))
				_set_text(cost_lbl, "")
				coin_icon.visible = false
				btn.disabled = true
