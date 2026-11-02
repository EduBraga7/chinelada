class_name UnitView
extends Node2D
## Representação visual de uma unidade da BattleSim: sprite, arma, animações procedurais
## (respirar, andar, investida, squash, flash) e barras de vida/estados. A origem do nó fica nos PÉS.

const HERO_SCALE := 0.56

var u: BattleSim.Unit
var spr: Sprite2D
var wpn: Sprite2D = null
var is_hero := false
var s0 := 0.6
var box := Vector2(256, 256)
var y0 := 0.0
var phase := 0.0
var flash := 0.0
var squash := 0.0
var jump := 0.0
var lunge_t := -1.0
var lunge_dist := 0.0
var lunge_time := 0.22
var dying := -1.0
var gone := false
var down := false            ## herói caído
var fury := false
var _last_x := 0.0
var _t := 0.0
var _star: Texture2D
var _walking := false


func setup(unit: BattleSim.Unit, ground_y: float) -> void:
	u = unit
	is_hero = unit.hero
	phase = randf() * 10.0
	_star = Art.tex("fx_star")
	spr = Sprite2D.new()
	spr.centered = false
	add_child(spr)
	if is_hero:
		var tex := Art.tex("hero_" + unit.def_id)
		spr.texture = tex
		box = tex.get_size()
		s0 = HERO_SCALE
		var wn: String = HeroArt.WEAPON.get(unit.def_id, "")
		if wn != "":
			wpn = Sprite2D.new()
			wpn.centered = false
			wpn.texture = Art.tex(wn)
			wpn.offset = Vector2(-64.0, -104.0)
			wpn.scale = Vector2(0.5, 0.5)
			var h: Vector2 = HeroArt.HAND[unit.def_id]
			wpn.position = Vector2((h.x - box.x * 0.5) * s0, (h.y - box.y * 0.925) * s0)
			wpn.rotation = deg_to_rad(18.0)
			add_child(wpn)
	else:
		var tex2 := Art.tex("en_" + unit.def_id)
		spr.texture = tex2
		box = tex2.get_size()
		var target_h := 300.0 if unit.boss else 150.0 * unit.scale
		s0 = target_h / box.y
	spr.offset = Vector2(-box.x * 0.5, -box.y * 0.925)
	spr.scale = Vector2(s0, s0)
	y0 = ground_y
	_last_x = unit.x
	position = Vector2(unit.x, y0)


func top() -> float:
	return -(box.y * 0.92 - 18.0) * s0


func head_pos() -> Vector2:
	return position + Vector2(0.0, top() * 0.55)


func hit() -> void:
	flash = 1.0
	squash = 1.0


func attack(dx: float) -> void:
	lunge_t = 0.0
	lunge_dist = dx
	lunge_time = 0.2 if is_hero else 0.3


func recoil() -> void:
	lunge_t = 0.0
	lunge_dist = -14.0
	lunge_time = 0.14


func cast() -> void:
	jump = 1.0
	flash = 0.6


func die() -> void:
	dying = 0.0


func set_down(v: bool) -> void:
	down = v


func tick(dt: float, t: float) -> void:
	_t = t
	flash = maxf(0.0, flash - dt * 5.0)
	squash = maxf(0.0, squash - dt * 6.0)
	jump = maxf(0.0, jump - dt * 3.2)
	if dying >= 0.0:
		dying += dt
		var k := dying / 0.42
		spr.scale = Vector2(s0 * (1.0 + k * 0.45), s0 * maxf(0.04, 1.0 - k))
		spr.modulate = Color(1, 1, 1, 1.0 - k)
		if wpn != null:
			wpn.visible = false
		if k >= 1.0:
			gone = true
		queue_redraw()
		return
	_walking = absf(u.x - _last_x) > 0.04
	_last_x = u.x
	var bob := 0.0
	var tilt := 0.0
	var breath := 1.0
	if is_hero:
		breath += sin(t * 3.2 + phase) * 0.022
	elif _walking:
		var w := sin(t * 9.0 + phase)
		bob = -absf(w) * 10.0
		tilt = w * 0.06
	else:
		breath += sin(t * 4.0 + phase) * 0.02
	var lx := 0.0
	var sw := 0.0
	if lunge_t >= 0.0:
		lunge_t += dt / lunge_time
		if lunge_t >= 1.0:
			lunge_t = -1.0
		else:
			var s := sin(lunge_t * PI)
			lx = s * lunge_dist
			sw = s
	var hop := -sin(jump * PI) * 46.0
	position = Vector2(u.x + lx, y0 + bob + hop)
	z_index = clampi(int(y0) - 380, 0, 40)      # faixa pequena: a interface fica sempre por cima
	var sq := squash
	spr.scale = Vector2(s0 * (1.0 + sq * 0.10), s0 * breath * (1.0 - sq * 0.12))
	spr.rotation = tilt + (sin(t * 22.0) * 0.12 if u.stun_t > 0.0 else 0.0)
	var m := Color(1.0 + flash * 1.6, 1.0 + flash * 1.6, 1.0 + flash * 1.6, 1.0)
	if u.burn_t > 0.0:
		var f := 0.75 + 0.25 * sin(t * 18.0)
		m = Color(m.r, m.g * f, m.b * f * 0.8, 1.0)
	elif u.vuln_t > 0.0:
		m = Color(m.r * 0.9, m.g * 0.78, m.b * 1.15, 1.0)
	if down:
		m = Color(0.45, 0.45, 0.55, 0.55)
	spr.modulate = m
	if wpn != null:
		wpn.rotation = deg_to_rad(18.0 + sw * 95.0)
		wpn.modulate = m
		wpn.visible = not down
	queue_redraw()


func _draw() -> void:
	if dying >= 0.0 or down:
		return
	var tp := top()
	var cy := -box.y * s0 * 0.45
	if fury and is_hero:
		draw_circle(Vector2(0.0, cy), 64.0 + sin(_t * 12.0) * 5.0, Color(1.0, 0.45, 0.15, 0.30))
	# barra de vida
	var frac := clampf(u.hp / u.max_hp, 0.0, 1.0)
	if is_hero or frac < 0.999:
		var w := 64.0 if is_hero else 56.0
		var y := tp - 20.0
		draw_rect(Rect2(-w * 0.5 - 2.0, y - 2.0, w + 4.0, 12.0), Color(0.08, 0.04, 0.12, 0.85), true)
		var col := Pal.GREEN if is_hero else Pal.RED
		if is_hero and frac < 0.35:
			col = Pal.ORANGE
		draw_rect(Rect2(-w * 0.5, y, w * frac, 8.0), col, true)
		if u.shield > 0.0:
			draw_rect(Rect2(-w * 0.5, y - 5.0, w * clampf(u.shield / u.max_hp, 0.0, 1.0), 4.0), Pal.BLUE, true)
	if u.shield > 0.0 and u.shield_t < 100.0:
		draw_arc(Vector2(0.0, cy), 66.0, 0.0, TAU, 32, Color(0.5, 0.9, 1.0, 0.85), 5.0)
	if u.stun_t > 0.0:
		for i in 3:
			var a := _t * 6.0 + i * TAU / 3.0
			var p := Vector2(cos(a) * 26.0, tp - 34.0 + sin(a) * 7.0)
			draw_texture_rect(_star, Rect2(p.x - 9.0, p.y - 9.0, 18.0, 18.0), false, Color(1.0, 0.9, 0.3))
	if u.taunt_t > 0.0:
		draw_circle(Vector2(0.0, tp - 30.0), 11.0, Color(0.95, 0.2, 0.25))
		draw_string(Kit.font(700), Vector2(-5.0, tp - 23.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)
