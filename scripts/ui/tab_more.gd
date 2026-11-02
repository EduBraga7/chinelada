class_name TabMore
extends VBoxContainer
## Aba "Mais": Fornada da Vovó (timer em tempo real, rende com o app fechado) e atalhos.

var _desc: Label
var _locked: Label
var _idle: VBoxContainer
var _cook: VBoxContainer
var _cook_bar: ProgressBar
var _cook_lbl: Label
var _ready_btn: Kit.CostButton
var _kind_btns: Dictionary = {}


func _init() -> void:
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func build() -> void:
	var s := Kit.scroll(12)
	add_child(s[0])
	var v: VBoxContainer = s[1]
	# --- Fornada da Vovó ---
	var card := Kit.panel(Pal.PANEL, 28, 14)
	v.add_child(card)
	var row := Kit.hbox(14)
	card.add_child(row)
	var ic := Kit.icon("ic_pot", 110)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(ic)
	var col := Kit.vbox(8)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	col.add_child(Kit.label(Loc.t("fornada.title"), 30, Pal.GOLD, 7, 700))
	_desc = Kit.label(Loc.t("fornada.desc"), 19, Color.WHITE, 4, 600)
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.custom_minimum_size = Vector2(320, 0)
	col.add_child(_desc)
	_locked = Kit.label(Loc.t("fornada.locked"), 22, Pal.ORANGE, 5, 700)
	col.add_child(_locked)
	_idle = Kit.vbox(6)
	col.add_child(_idle)
	for k in ["short", "mid", "long"]:
		var b := Kit.cost_button("ic_gem", "orange", 20, Vector2(0, 62))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var kind: String = k
		b.pressed.connect(func():
			if G.fornada_start(kind):
				Sfx.play("upgrade", 1.0))
		_idle.add_child(b)
		_kind_btns[k] = b
	_cook = Kit.vbox(6)
	col.add_child(_cook)
	_cook_lbl = Kit.label("", 26, Color.WHITE, 6, 700)
	_cook.add_child(_cook_lbl)
	_cook_bar = Kit.bar(Pal.ORANGE, Color(0, 0, 0, 0.5), 26)
	_cook.add_child(_cook_bar)
	_ready_btn = Kit.cost_button("ic_gem", "green", 26, Vector2(0, 80))
	_ready_btn.pressed.connect(func():
		var g := G.fornada_claim()
		if g > 0:
			G.toast.emit(Loc.t("fornada.reward", [g]), "good")
			Sfx.play("fanfare", 1.0))
	col.add_child(_ready_btn)
	# --- atalhos ---
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(grid)
	var items := [
		["ic_camera", "more.photo", "pink", "photo"], ["ic_book", "more.bestiary", "purple", "bestiary"],
		["ic_trophy", "more.stats", "blue", "stats"], ["ic_share", "more.share", "green", "share"],
		["ic_gear", "more.settings", "gray", "settings"],
	]
	for it in items:
		var b2 := Kit.button(Loc.t(it[1]), it[2], 22)
		b2.custom_minimum_size = Vector2(0, 84)
		b2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b2.icon = Art.tex(it[0])
		b2.expand_icon = true
		b2.add_theme_constant_override("icon_max_width", 48)
		b2.add_theme_constant_override("h_separation", 10)
		var act: String = it[3]
		b2.pressed.connect(func(): _act(act))
		grid.add_child(b2)
	v.add_child(Kit.label(Loc.t("more.credits"), 18, Pal.TEXT_DIM, 4, 600))
	refresh()


func _act(what: String) -> void:
	var main := Main.find(self)
	if main == null:
		return
	match what:
		"photo": main.popups.photo()
		"bestiary": main.popups.bestiary()
		"stats": main.popups.stats()
		"share": main.popups.share_sheet(Share.progress_text())
		"settings": main.popups.settings()


func refresh() -> void:
	var st := Goals.fornada_state(G.d)
	var has_vovo: bool = G.d.heroes["vovo"].owned
	_locked.visible = not has_vovo
	_idle.visible = has_vovo and st.state == "idle"
	_cook.visible = has_vovo and st.state == "cooking"
	_ready_btn.visible = has_vovo and st.state == "ready"
	for k in _kind_btns:
		var f: Dictionary = Econ.FORNADA[k]
		_kind_btns[k].set_texts(Loc.t("fornada." + k), "+%d" % Goals.fornada_gems(k, G.dir.mods))
	if st.state == "cooking":
		var f2: Dictionary = Econ.FORNADA[String(st.kind)]
		var total := float(f2.dur)
		_cook_bar.value = 1.0 - float(st.remain) / total
		_cook_lbl.text = Loc.t("fornada.cooking", [NumFmt.clock(float(st.remain))])
	elif st.state == "ready":
		_ready_btn.set_texts(Loc.t("fornada.ready"), "+%d" % Goals.fornada_gems(String(st.kind), G.dir.mods))
