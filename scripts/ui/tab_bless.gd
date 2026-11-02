class_name TabBless
extends VBoxContainer
## Aba "Bênçãos": prestígio ("Pedir a Bênção da Vovó") e árvore de talentos permanentes.

const ICONS := {
	"dmg": "ic_dps", "hp": "ic_heart", "gold": "ic_coin", "aspd": "ic_speed", "crit": "ic_star", "fury_gain": "ic_fury",
	"fury_dur": "ic_fury", "boss_time": "ic_clock", "auto_fury": "ic_auto", "off_cap": "ic_clock", "off_eff": "ic_clock",
	"fornada_slots": "ic_pot", "parrot": "ic_parrot", "start_stage": "ic_arrow_up", "pity_cut": "ic_marmita", "gems": "ic_gem",
}

var _have_lbl: Label
var _bonus_lbl: Label
var _best_lbl: Label
var _pray_btn: Kit.CostButton
var _rows: Dictionary = {}


func _init() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func build() -> void:
	var s := Kit.scroll(12)
	add_child(s[0])
	var v: VBoxContainer = s[1]
	var card := Kit.panel(Pal.PANEL, 28, 14)
	v.add_child(card)
	var row := Kit.hbox(14)
	card.add_child(row)
	var ic := Kit.icon("ic_bless", 120)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	var col := Kit.vbox(6)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	col.add_child(Kit.label(Loc.t("bless.title"), 30, Pal.GOLD, 7, 700))
	_have_lbl = Kit.label("", 28, Color.WHITE, 6, 700)
	col.add_child(_have_lbl)
	_bonus_lbl = Kit.label("", 19, Pal.TEXT_DIM, 4, 600)
	_bonus_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bonus_lbl.custom_minimum_size = Vector2(300, 0)
	col.add_child(_bonus_lbl)
	_best_lbl = Kit.label("", 19, Color("#9fe9ff"), 4, 600)
	col.add_child(_best_lbl)
	_pray_btn = Kit.cost_button("ic_bless", "purple", 24, Vector2(0, 84))
	_pray_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_pray_btn.pressed.connect(_pray)
	v.add_child(_pray_btn)
	v.add_child(Kit.label(Loc.t("bless.tree"), 28, Color.WHITE, 6, 700))
	for id in BlessDefs.ORDER:
		var r := TalentRow.new(id)
		v.add_child(r)
		r.build()
		_rows[id] = r
	refresh()


func _pray() -> void:
	var gain := Econ.bless_gain(G.d)
	var main := Main.find(self)
	if gain <= 0 or main == null:
		return
	var pct := roundi(Econ.PRESTIGE_DMG * gain * 100.0)
	var start := int(G.dir.mods.start_stage) + 1
	main.popups.confirm(Loc.t("bless.confirm_title"), Loc.t("bless.confirm", [gain, start, pct]), func():
		var g := G.prestige()
		if g > 0:
			main.show_toast(Loc.t("bless.done", [g]), "good")
			main.banner(Loc.t("bless.done", [g]), Pal.PURPLE, 1.6)
			Sfx.play("bless", 1.0), Loc.t("bless.pray"), "purple")


func refresh() -> void:
	var d := G.d
	_have_lbl.text = Loc.t("bless.have", [int(d.cur.bless)])
	var earned := float(d.prestige.earned)
	_bonus_lbl.text = Loc.t("bless.bonus", [roundi(Econ.PRESTIGE_DMG * earned * 100.0), roundi(Econ.PRESTIGE_HP * earned * 100.0), roundi(Econ.PRESTIGE_GOLD * earned * 100.0)])
	_best_lbl.text = Loc.t("bless.best", [int(d.prestige.run_best)])
	var gain := Econ.bless_gain(d)
	if gain > 0:
		_pray_btn.set_texts(Loc.t("bless.pray"), Loc.t("bless.gain", [gain]))
		_pray_btn.disabled = false
	else:
		_pray_btn.set_texts(Loc.t("bless.pray"), "")
		_pray_btn.disabled = true
		_pray_btn.title_lbl.text = Loc.t("bless.need", [Econ.PRESTIGE_MIN_STAGE])
		_pray_btn.title_lbl.add_theme_font_size_override("font_size", 20)
	for id in _rows:
		_rows[id].refresh()


## Linha de talento
class TalentRow extends PanelContainer:
	var id: String
	var name_lbl: Label
	var desc_lbl: Label
	var lvl_lbl: Label
	var btn: Kit.CostButton

	func _init(p_id: String) -> void:
		id = p_id

	func build() -> void:
		mouse_filter = Control.MOUSE_FILTER_PASS
		add_theme_stylebox_override("panel", Kit.box(Pal.PANEL, 22))
		var m := MarginContainer.new()
		for k in ["left", "right", "top", "bottom"]:
			m.add_theme_constant_override("margin_" + k, 10)
		add_child(m)
		var row := Kit.hbox(12)
		m.add_child(row)
		var t: Dictionary = BlessDefs.DATA[id]
		var ic := Kit.icon(TabBless.ICONS.get(t.stat, "ic_star"), 60)
		ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(ic)
		var col := Kit.vbox(2)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(col)
		name_lbl = Kit.label(Loc.t("bless." + id), 24, Color.WHITE, 5, 700)
		name_lbl.clip_text = true
		col.add_child(name_lbl)
		desc_lbl = Kit.label("", 18, Color("#9fe9ff"), 4, 600)
		desc_lbl.clip_text = true
		col.add_child(desc_lbl)
		lvl_lbl = Kit.label("", 18, Pal.GOLD, 4, 700)
		col.add_child(lvl_lbl)
		btn = Kit.cost_button("ic_bless", "purple", 20, Vector2(160, 76))
		btn.pressed.connect(func():
			if G.buy_bless(id):
				Sfx.play("upgrade", 1.0))
		row.add_child(btn)

	func refresh() -> void:
		var t: Dictionary = BlessDefs.DATA[id]
		var lvl := int(G.d.bless.get(id, 0))
		var mx := int(t.max)
		desc_lbl.text = Loc.stat_text(String(t.stat), float(t.per))
		lvl_lbl.text = Loc.t("bless.level", [lvl, mx])
		if lvl >= mx:
			btn.set_texts(Loc.t("ui.max"), "")
			btn.disabled = true
		else:
			var cost := BlessDefs.cost(id, lvl)
			btn.set_texts("", str(cost))
			btn.disabled = int(G.d.cur.bless) < cost
