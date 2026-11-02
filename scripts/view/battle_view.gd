class_name BattleView
extends Control
## Mostra a batalha (cenário + unidades + efeitos) a partir da BattleSim do Director.
## O cenário e as unidades vivem num espaço fixo de 720×500, escalado para cobrir o controle.

signal parrot_caught(reward: Dictionary)

const AREA := Vector2(720, 500)
const GROUND_Y := 400.0

var fx: FxLayer
var _content: Node2D
var _bg: Sprite2D
var _unit_root: Node2D
var _views: Dictionary = {}
var _sim: BattleSim = null
var _world := ""
var _shake := 0.0
var _t := 0.0
var _scale := 1.0
var _flash := 0.0
var _bubble_t := 6.0
var _bubble: PanelContainer
var _bubble_label: Label
var _bubble_life := 0.0
var _parrot: Sprite2D
var _parrot_t := 70.0
var _parrot_life := 0.0
var _parrot_y := 120.0
var _qa_hide_boss := false


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_content = Node2D.new()
	add_child(_content)
	_bg = Sprite2D.new()
	_bg.centered = false
	_content.add_child(_bg)
	_unit_root = Node2D.new()
	_content.add_child(_unit_root)
	_parrot = Sprite2D.new()
	_parrot.texture = Art.tex("ic_parrot")
	_parrot.visible = false
	_parrot.z_index = 45
	_content.add_child(_parrot)
	_bubble = Kit.panel(Color(1, 1, 1, 0.95), 18, 10)
	_bubble_label = Kit.label("", 26, Color("#2b1b2f"), 0, 700)
	_bubble.add_child(_bubble_label)
	_bubble.visible = false
	_bubble.z_index = 50
	_content.add_child(_bubble)
	resized.connect(_relayout)
	_relayout()


func _relayout() -> void:
	_scale = maxf(size.x / AREA.x, size.y / AREA.y)
	_content.scale = Vector2(_scale, _scale)
	_content.position = Vector2((size.x - AREA.x * _scale) * 0.5, (size.y - AREA.y * _scale) * 0.5)


func shake(amount: float) -> void:
	if bool(G.d.settings.shake):
		_shake = maxf(_shake, amount)


func to_screen(local: Vector2) -> Vector2:
	return _content.get_global_transform() * local


func _bind(sim: BattleSim) -> void:
	for v in _views.values():
		v.queue_free()
	_views.clear()
	_sim = sim
	if fx != null:
		fx.clear()
	if sim == null:
		return
	var wid: String = WorldDefs.DATA[WorldDefs.index_of(sim.stage)].id
	if wid != _world:
		_world = wid
		_bg.texture = Art.tex("bg_" + wid)
	for h in sim.heroes:
		_add_view(h)


func _add_view(u: BattleSim.Unit) -> UnitView:
	var v := UnitView.new()
	var y := GROUND_Y + (u.slot % 2) * 12.0 if u.hero else GROUND_Y + float(u.id % 3) * 9.0
	_unit_root.add_child(v)
	v.setup(u, y)
	_views[u.id] = v
	return v


func _process(delta: float) -> void:
	_t += delta
	var sim: BattleSim = G.dir.sim
	if sim != _sim:
		_bind(sim)
	if _sim == null:
		return
	for e in _sim.enemies:
		if not _views.has(e.id):
			_add_view(e)
	var fury_on := _sim.fury_t > 0.0
	for id in _views.keys():
		var v: UnitView = _views[id]
		v.fury = fury_on
		v.tick(delta, _t)
		if v.gone:
			v.queue_free()
			_views.erase(id)
	_consume_events()
	if _shake > 0.0:
		_shake = move_toward(_shake, 0.0, delta * 38.0)
	_content.position = Vector2((size.x - AREA.x * _scale) * 0.5, (size.y - AREA.y * _scale) * 0.5) \
		+ Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake
	_flash = maxf(0.0, _flash - delta * 2.5)
	_update_bubble(delta)
	_update_parrot(delta)
	queue_redraw()


# ---------------------------------------------------------------- eventos da simulação

func _front_enemy() -> UnitView:
	var best: UnitView = null
	for e in _sim.enemies:
		if e.alive and _views.has(e.id):
			if best == null or e.x < best.u.x:
				best = _views[e.id]
	return best


func _consume_events() -> void:
	if _sim.events.is_empty():
		return
	for e in _sim.events:
		match String(e.t):
			"hit":
				var v: UnitView = _views.get(int(e.dst))
				if v == null:
					continue
				v.hit()
				var col := Color.WHITE
				var sz := 30
				if bool(e.crit):
					col = Color("#ffd23f")
					sz = 46
					shake(3.0)
				elif bool(e.skill):
					col = Color("#7fe0ff")
					sz = 38
				elif int(e.src) == 0:
					col = Color("#bfe9ff")
					sz = 28
				fx.number(to_screen(v.head_pos()), NumFmt.fmt(float(e.dmg)), col, sz, bool(e.crit))
				Sfx.play("crit" if bool(e.crit) else "hit", 1.0)
			"atk":
				var a: UnitView = _views.get(int(e.src))
				var t: UnitView = _views.get(int(e.dst))
				if a == null or t == null:
					continue
				if a.u.ranged:
					fx.shot(to_screen(a.head_pos()), to_screen(t.head_pos()), Color("#ffe27a"))
					a.recoil()
				else:
					a.attack(clampf(t.u.x - a.u.x - 74.0, 30.0, 340.0))
			"eatk":
				var ea: UnitView = _views.get(int(e.src))
				var et: UnitView = _views.get(int(e.dst))
				if ea == null:
					continue
				if ea.u.ranged and et != null:
					fx.shot(to_screen(ea.head_pos()), to_screen(et.head_pos()), Color("#ff6a6a"), 0.2)
				else:
					ea.attack(-34.0)
			"hhit":
				var hv: UnitView = _views.get(int(e.dst))
				if hv == null:
					continue
				hv.hit()
				fx.number(to_screen(hv.head_pos()), NumFmt.fmt(float(e.dmg)), Color("#ff7a7a"), 26)
			"heal":
				var hl: UnitView = _views.get(int(e.dst))
				if hl != null and float(e.amt) > 0.0:
					fx.number(to_screen(hl.head_pos()), "+" + NumFmt.fmt(float(e.amt)), Color("#5dff9a"), 24)
			"death":
				var dv: UnitView = _views.get(int(e.id))
				if dv == null:
					continue
				dv.die()
				var p := to_screen(dv.head_pos())
				var n := 1
				if bool(e.boss):
					n = 14
					shake(10.0)
				elif bool(e.elite):
					n = 5
					shake(5.0)
				elif float(e.gold) > 0.0:
					n = 1 + randi() % 2
				fx.coins(p, n)
				fx.burst(p, 7 if not bool(e.boss) else 22, Color("#ffe27a"), 240.0, 0.5)
				fx.burst(p, 4, Color("#ffffff"), 120.0, 0.45, "puff", 60.0)
				Sfx.play("kill", 1.0)
			"hdeath":
				var hd: UnitView = _views.get(int(e.id))
				if hd != null:
					hd.set_down(true)
			"revive":
				for hv2 in _views.values():
					if hv2.is_hero:
						hv2.set_down(false)
						fx.rise(to_screen(hv2.head_pos()), 6, Color("#ffffff"), 1.0)
			"summon":
				var sv: UnitView = _views.get(int(e.id))
				if sv != null:
					fx.burst(to_screen(sv.head_pos()), 6, Color("#ffffff"), 140.0, 0.5, "puff", 70.0)
			"skill":
				_on_skill(e)
			"fury":
				if bool(e.on):
					shake(7.0)
					fx.ring(to_screen(Vector2(180, 330)), Color("#ff7a2a"), 360.0, 0.55)
					Sfx.play("fury", 1.0)
	_sim.events.clear()


func _on_skill(e: Dictionary) -> void:
	var a: UnitView = _views.get(int(e.src))
	if a == null:
		return
	a.cast()
	var foe := _front_enemy()
	var apos := to_screen(a.head_pos())
	match String(e.kind):
		"burst":
			if foe != null:
				fx.fly(Art.tex("wpn_chinelo"), apos, to_screen(foe.head_pos()), 150.0, 0.62, true, 16.0)
				fx.ring(to_screen(foe.head_pos()), Color("#7fe0ff"), 120.0, 0.35)
			Sfx.play("skill_neide", 1.0)
		"heal":
			for v in _views.values():
				if v.is_hero and not v.down:
					fx.rise(to_screen(v.head_pos()), 6, Color("#5dff9a"))
			Sfx.play("heal", 1.0)
		"taunt_burn":
			for v in _views.values():
				if not v.is_hero:
					fx.burst(to_screen(v.head_pos()), 5, Color("#ff8a2a"), 120.0, 0.6, "puff", 50.0)
			fx.ring(apos, Color("#ff5a64"), 140.0, 0.4)
		"multihit":
			for v in _views.values():
				if not v.is_hero and randf() < 0.7:
					fx.slash(to_screen(v.head_pos()), Color("#ffffff"), 120.0, randf_range(-0.9, 0.9))
		"aoe_blind":
			_flash = 0.85
			shake(4.0)
		"buff_team":
			for v in _views.values():
				if v.is_hero and not v.down:
					fx.ring(to_screen(v.head_pos()), Color("#ffd23f"), 80.0, 0.5)
					fx.rise(to_screen(v.head_pos()), 3, Color("#ffd23f"))
		"barrage":
			for v in _views.values():
				if not v.is_hero and randf() < 0.9:
					fx.shot(apos, to_screen(v.head_pos()), Color("#7fd7ff"), 0.22)
		"vuln":
			for v in _views.values():
				if not v.is_hero:
					fx.ring(to_screen(v.head_pos()), Color("#c26bff"), 90.0, 0.5)


# ---------------------------------------------------------------- balões e papagaio

func _update_bubble(delta: float) -> void:
	if _bubble_life > 0.0:
		_bubble_life -= delta
		if _bubble_life <= 0.0:
			_bubble.visible = false
	_bubble_t -= delta
	if _bubble_t > 0.0 or _sim == null:
		return
	_bubble_t = randf_range(9.0, 16.0)
	var alive: Array = []
	for v in _views.values():
		if v.is_hero and not v.down:
			alive.append(v)
	if alive.is_empty():
		return
	var v: UnitView = alive[randi() % alive.size()]
	var keys: Array = []
	for i in range(1, 5):
		var k := "quote.%s.%d" % [v.u.def_id, i]
		if Loc.has_key(k):
			keys.append(k)
	if keys.is_empty():
		return
	_bubble_label.text = Loc.t(keys[randi() % keys.size()])
	_bubble.reset_size()
	_bubble.position = Vector2(clampf(v.position.x - _bubble.size.x * 0.5 + 40.0, 6.0, AREA.x - _bubble.size.x - 6.0), v.position.y + v.top() - 78.0)
	_bubble.visible = true
	_bubble_life = 2.4


func _update_parrot(delta: float) -> void:
	if _parrot_life > 0.0:
		_parrot_life -= delta
		var k := 1.0 - _parrot_life / 5.5
		_parrot.position = Vector2(-80.0 + k * (AREA.x + 160.0), _parrot_y + sin(k * 14.0) * 36.0)
		_parrot.scale = Vector2(0.8, 0.8) * (1.0 + sin(_t * 18.0) * 0.04)
		if _parrot_life <= 0.0:
			_parrot.visible = false
		return
	_parrot_t -= delta
	if _parrot_t <= 0.0 and _sim != null and G.d.stage.cleared >= 2:
		_parrot_t = randf_range(70.0, 130.0) / float(G.dir.mods.parrot)
		_parrot_life = 5.5
		_parrot_y = randf_range(70.0, 190.0)
		_parrot.visible = true
		Sfx.play("parrot", 1.0)


func spawn_parrot_now() -> void:
	_parrot_t = 0.0


func _gui_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb != null and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
		var p: Vector2 = (mb.position - _content.position) / _scale
		if _parrot.visible and p.distance_to(_parrot.position + Vector2(64, 64) * 0.8) < 100.0:
			var rw: Dictionary = G.catch_parrot()
			var sp := to_screen(_parrot.position + Vector2(64, 64) * 0.8)
			fx.coins(sp, 10)
			fx.burst(sp, 14, Color("#ffd23f"), 300.0, 0.7)
			var label := "+" + NumFmt.fmt(float(rw.gold))
			if int(rw.gems) > 0:
				label += "  +%d" % int(rw.gems)
			fx.number(sp, label, Color("#ffd23f"), 40, true)
			_parrot.visible = false
			_parrot_life = 0.0
			parrot_caught.emit(rw)
			return
		var dmg: float = G.tap()
		if dmg > 0.0:
			fx.ring(get_global_transform() * mb.position, Color(1, 1, 1, 0.8), 46.0, 0.22, 6.0)


# ---------------------------------------------------------------- sobreposições (flash, Fúria, barra do chefão)

func _draw() -> void:
	if _flash > 0.0:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, _flash * 0.8), true)
	if _sim == null:
		return
	if _sim.fury_t > 0.0:
		var a := 0.20 + 0.07 * sin(_t * 10.0)
		var c := Color(1.0, 0.32, 0.08, a)
		draw_rect(Rect2(0, 0, size.x, 26), c, true)
		draw_rect(Rect2(0, size.y - 26, size.x, 26), c, true)
		draw_rect(Rect2(0, 0, 20, size.y), c, true)
		draw_rect(Rect2(size.x - 20, 0, 20, size.y), c, true)
	# barra do chefão
	var boss: BattleSim.Unit = null
	for e in _sim.enemies:
		if e.alive and (e.boss or (e.elite and _sim.boss_stage)):
			boss = e
			break
	if boss != null and not _qa_hide_boss:
		var w := minf(size.x - 40.0, 520.0)
		var r := Rect2((size.x - w) * 0.5, 16.0, w, 34.0)
		var f := clampf(boss.hp / boss.max_hp, 0.0, 1.0)
		draw_rect(Rect2(r.position - Vector2(4, 4), r.size + Vector2(8, 8)), Color(0.08, 0.04, 0.12, 0.9), true)
		draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), Pal.RED, true)
		draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y * 0.4)), Color(1, 1, 1, 0.18), true)
		var nm := Loc.t("enemy." + boss.def_id)
		if boss.elite and not boss.boss:
			nm = Loc.t("enemy.elite", [nm])
		var font := Kit.font(700)
		var tw := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
		var tp := Vector2(r.position.x + (r.size.x - tw) * 0.5, r.position.y + 25.0)
		draw_string_outline(font, tp, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, 7, Pal.OUTLINE)
		draw_string(font, tp, nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color.WHITE)
		var left := maxf(0.0, _sim.time_limit - _sim.time)
		var ts := "%d" % ceili(left)
		var tcol := Color.WHITE if left > 8.0 else Color("#ff8a8a")
		var tpos := Vector2(r.end.x - 4.0 - font.get_string_size(ts, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x, r.end.y + 26.0)
		draw_string_outline(font, tpos, ts, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 7, Pal.OUTLINE)
		draw_string(font, tpos, ts, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, tcol)
