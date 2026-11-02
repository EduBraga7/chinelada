class_name TabRelics
extends VBoxContainer
## Aba "Relíquias": Marmita da Vovó (gacha com pity) + coleção das 16 relíquias.

var _btn1: Kit.CostButton
var _btn10: Kit.CostButton
var _pity_lbl: Label
var _owned_lbl: Label
var _cells: Dictionary = {}


func _init() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func build() -> void:
	var s := Kit.scroll(12)
	add_child(s[0])
	var v: VBoxContainer = s[1]
	# --- Marmita ---
	var card := Kit.panel(Pal.PANEL, 28, 14)
	v.add_child(card)
	var row := Kit.hbox(14)
	card.add_child(row)
	var ic := Kit.icon("ic_marmita", 130)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	var col := Kit.vbox(6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	col.add_child(Kit.label(Loc.t("relic.marmita"), 32, Pal.GOLD, 7, 700))
	var d := Kit.label(Loc.t("relic.marmita_d"), 21, Color.WHITE, 4, 600)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size = Vector2(300, 0)
	col.add_child(d)
	_pity_lbl = Kit.label("", 19, Pal.TEXT_DIM, 4, 600)
	_pity_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_pity_lbl)
	var br := Kit.hbox(8)
	col.add_child(br)
	_btn1 = Kit.cost_button("ic_gem", "green", 22, Vector2(0, 76))
	_btn1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn1.pressed.connect(func(): _open(1))
	br.add_child(_btn1)
	_btn10 = Kit.cost_button("ic_gem", "orange", 22, Vector2(0, 76))
	_btn10.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_btn10.pressed.connect(func(): _open(10))
	br.add_child(_btn10)
	_owned_lbl = Kit.label("", 24, Color.WHITE, 5, 700)
	v.add_child(_owned_lbl)
	# --- coleção ---
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(grid)
	var ids: Array = RelicDefs.ids()
	ids.sort_custom(func(a: String, b: String) -> bool:
		var ra: int = RelicDefs.RARITY_ORDER.find(RelicDefs.DATA[a].rarity)
		var rb: int = RelicDefs.RARITY_ORDER.find(RelicDefs.DATA[b].rarity)
		return ra < rb if ra != rb else a < b)
	for id in ids:
		var cell := RelicCell.new(id)
		grid.add_child(cell)
		cell.build()
		cell.pressed.connect(func(): _detail(id))
		_cells[id] = cell
	refresh()


func _open(n: int) -> void:
	var res := G.open_marmitas(n)
	if res.is_empty():
		G.toast.emit(Loc.t("relic.need_gems"), "info")
		Sfx.play("deny", 1.0)
		return
	Sfx.play("marmita", 1.0)
	var main := get_tree().root.get_node_or_null("Boot/Main")
	var pops := _popups()
	if pops != null:
		pops.marmita_reveal(res)


func _popups() -> Popups:
	var n: Node = self
	while n != null:
		if n is Main:
			return (n as Main).popups
		n = n.get_parent()
	return null


func _detail(id: String) -> void:
	var pops := _popups()
	if pops != null:
		pops.relic_detail(id)


func refresh() -> void:
	var gems := int(G.d.cur.gems)
	var cut := int(G.dir.mods.pity_cut)
	_btn1.set_texts(Loc.t("relic.open1"), str(Econ.MARMITA_COST))
	_btn1.disabled = gems < Econ.MARMITA_COST
	_btn10.set_texts(Loc.t("relic.open10"), "270")
	_btn10.disabled = gems < 270
	var ep := maxi(1, Econ.EPIC_PITY - cut - int(G.d.pity.epic))
	var lg := maxi(1, Econ.LEGEND_PITY - cut - int(G.d.pity.legend))
	_pity_lbl.text = Loc.t("relic.pity", [ep, lg])
	_owned_lbl.text = Loc.t("relic.owned", [G.d.relics.size(), RelicDefs.DATA.size()])
	for id in _cells:
		_cells[id].refresh()


## Célula da coleção
class RelicCell extends Button:
	var id: String
	var icon_rect: TextureRect
	var name_lbl: Label
	var lvl_lbl: Label

	func _init(p_id: String) -> void:
		id = p_id

	func build() -> void:
		custom_minimum_size = Vector2(0, 168)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		focus_mode = Control.FOCUS_NONE
		var col: Color = Pal.RARITY[RelicDefs.DATA[id].rarity]
		var sb := Kit.box(Pal.PANEL, 20)
		sb.set_border_width_all(4)
		sb.border_color = col
		add_theme_stylebox_override("normal", sb)
		add_theme_stylebox_override("hover", sb)
		add_theme_stylebox_override("pressed", sb)
		add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_theme_constant_override("separation", 2)
		add_child(v)
		icon_rect = Kit.icon("rl_" + id, 88)
		icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(icon_rect)
		name_lbl = Kit.label("", 17, Color.WHITE, 4, 600)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.custom_minimum_size = Vector2(0, 40)
		v.add_child(name_lbl)
		lvl_lbl = Kit.label("", 20, Pal.GOLD, 5, 700)
		lvl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(lvl_lbl)

	func refresh() -> void:
		var has: bool = G.d.relics.has(id)
		icon_rect.modulate = Color.WHITE if has else Color(0.04, 0.02, 0.08, 0.8)
		name_lbl.text = Loc.t("relic." + id) if has else Loc.t("relic.unknown")
		lvl_lbl.text = Loc.t("relic.lvl", [int(G.d.relics[id].lvl)]) if has else ""
