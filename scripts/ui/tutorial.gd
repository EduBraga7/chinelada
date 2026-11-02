class_name Tutorial
extends Control
## Dicas de primeira vez (não bloqueiam o jogo): o progresso fica em d.flags["tut"].
##  0 → "Neide luta sozinha"  1 → "toque em MELHORAR"  2 → "recrute a Vovó"  3 → "saia e volte"  4 → fim

var main: Main
var _panel: PanelContainer
var _lbl: Label
var _hand: TextureRect
var _t := 0.0
var _check_t := 0.0
var _point_id := ""
var _shown_since := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = Kit.panel(Color(0.1, 0.06, 0.18, 0.96), 26, 14, Pal.GOLD, 4)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_lbl = Kit.label("", 24, Color.WHITE, 5, 700)
	_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl.custom_minimum_size = Vector2(500, 0)
	_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_lbl)
	add_child(_panel)
	_hand = Kit.icon("ic_hand", 76)
	_hand.rotation = PI
	add_child(_hand)
	_panel.visible = false
	_hand.visible = false


func _step() -> int:
	return int(G.d.flags.get("tut", 0))


func _set_step(s: int) -> void:
	G.d.flags["tut"] = s
	_shown_since = _t


func _process(delta: float) -> void:
	_t += delta
	_check_t += delta
	var want_a := 0.0 if main.banner_left > 0.0 else 1.0     # não cobre os banners de CHEFÃO/estágio
	_panel.modulate.a = move_toward(_panel.modulate.a, want_a, delta * 6.0)
	if _hand.visible and _point_id != "":
		var r := main.family_button_rect(_point_id)
		var bob := sin(_t * 6.0) * 10.0
		_hand.position = Vector2(r.get_center().x - 38.0, r.end.y + 4.0 + bob)
	if _check_t < 0.4:
		return
	_check_t = 0.0
	_logic()


func _show(key: String, point: String = "") -> void:
	var t := Loc.t(key)
	if _lbl.text != t:
		_lbl.text = t
		_panel.reset_size()
	_panel.visible = true
	_point_id = point
	_hand.visible = point != "" and main.cur_tab == 0
	var y := main.battle.position.y + 66.0
	_panel.position = Vector2((size.x - _panel.size.x) * 0.5, y)


func _hide() -> void:
	_panel.visible = false
	_hand.visible = false
	_point_id = ""


func _logic() -> void:
	var d := G.d
	if main.popups.is_open() or G.offline_busy:
		_hide()
		return
	var best := int(d.stage.best)
	match _step():
		0:
			if float(d.stats.play_s) < 9.0 and best == 0:
				_show("tut.1")
			else:
				_hide()
				_set_step(1)
		1:
			var cost := Econ.level_cost("neide", int(d.heroes["neide"].lvl))
			if float(d.stats.upgrades) >= 1.0 or best >= 3:
				_hide()
				_set_step(2)
			elif float(d.cur.gold) >= cost:
				_show("tut.2", "neide")
			else:
				_hide()
		2:
			var vovo_owned: bool = d.heroes["vovo"].owned
			if vovo_owned or best >= 9:
				_hide()
				_set_step(3)
			elif Econ.hero_available(d, "vovo"):
				_show("tut.3", "vovo")
			else:
				_hide()
		3:
			if best >= 6:
				if _shown_since == 0.0:
					_shown_since = _t
				if _t - _shown_since < 14.0:
					_show("tut.4")
				else:
					_hide()
					_set_step(4)
			else:
				_hide()
		_:
			_hide()
