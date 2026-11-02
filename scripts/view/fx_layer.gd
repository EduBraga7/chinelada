class_name FxLayer
extends Control
## Camada de efeitos em tela cheia (acima de tudo): números de dano, partículas, moedas que voam
## até o contador de ouro e anéis de impacto. Desenha tudo com _draw (sem nodes por partícula).

signal coin_arrived(n: int)

const MAX_PARTS := 360

var coin_target := Vector2(150, 90)
var _nums: Array = []
var _parts: Array = []
var _coins: Array = []
var _rings: Array = []
var _shots: Array = []
var _flights: Array = []
var _font: Font
var _t_star: Texture2D
var _t_puff: Texture2D
var _t_coin: Texture2D
var _t_slash: Texture2D
var reduce := false          ## modo "menos efeitos"


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_font = Kit.font(700)
	_t_star = Art.tex("fx_star")
	_t_puff = Art.tex("fx_puff")
	_t_coin = Art.tex("ic_coin")
	_t_slash = Art.tex("fx_slash")


func clear() -> void:
	_nums.clear()
	_parts.clear()
	_coins.clear()
	_rings.clear()
	_shots.clear()
	_flights.clear()
	queue_redraw()


# ---------------------------------------------------------------- API

func number(p: Vector2, text: String, col: Color, size: int = 30, crit: bool = false) -> void:
	if _nums.size() > 48:
		_nums.remove_at(0)
	var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	_nums.append({
		"p": p + Vector2(randf_range(-14.0, 14.0), randf_range(-6.0, 6.0)),
		"v": Vector2(randf_range(-26.0, 26.0), -150.0 if crit else -105.0),
		"text": text, "col": col, "size": size, "w": w, "t": 0.0, "life": 1.15 if crit else 0.85, "crit": crit,
	})


func burst(p: Vector2, n: int, col: Color, speed: float = 220.0, life: float = 0.55, kind: String = "star", size: float = 22.0) -> void:
	if reduce:
		n = maxi(1, n / 3)
	for i in n:
		if _parts.size() >= MAX_PARTS:
			break
		var a := randf() * TAU
		var sp := randf_range(speed * 0.4, speed)
		_parts.append({
			"p": p, "v": Vector2(cos(a), sin(a)) * sp, "col": col, "t": 0.0, "life": life * randf_range(0.7, 1.2),
			"kind": kind, "size": size * randf_range(0.7, 1.2), "rot": randf() * TAU, "vr": randf_range(-6.0, 6.0), "grav": 260.0,
		})


## Faísca que sobe (cura, aura)
func rise(p: Vector2, n: int, col: Color, life: float = 0.9) -> void:
	for i in n:
		if _parts.size() >= MAX_PARTS:
			break
		_parts.append({
			"p": p + Vector2(randf_range(-26.0, 26.0), randf_range(-10.0, 10.0)), "v": Vector2(randf_range(-14.0, 14.0), randf_range(-90.0, -50.0)),
			"col": col, "t": 0.0, "life": life * randf_range(0.8, 1.2), "kind": "star", "size": randf_range(14.0, 22.0),
			"rot": randf() * TAU, "vr": randf_range(-3.0, 3.0), "grav": -20.0,
		})


func ring(p: Vector2, col: Color, r1: float = 90.0, life: float = 0.4, r0: float = 10.0) -> void:
	_rings.append({"p": p, "col": col, "r0": r0, "r1": r1, "t": 0.0, "life": life})


func coins(p: Vector2, n: int) -> void:
	for i in n:
		if _coins.size() > 60:
			break
		_coins.append({
			"p": p, "v": Vector2(randf_range(-110.0, 110.0), randf_range(-260.0, -140.0)), "t": 0.0,
			"hold": randf_range(0.32, 0.5), "fly": 0.0, "start": Vector2.ZERO,
		})


## Projétil rápido de um ponto a outro.
func shot(a: Vector2, b: Vector2, col: Color, life: float = 0.16) -> void:
	_shots.append({"a": a, "b": b, "col": col, "t": 0.0, "life": life})


## Sprite que voa de A até B (e volta, se `ret`), girando — ex.: o chinelo gigante.
func fly(tex: Texture2D, a: Vector2, b: Vector2, size: float, life: float, ret: bool = true, spin: float = 14.0) -> void:
	_flights.append({"tex": tex, "a": a, "b": b, "size": size, "t": 0.0, "life": life, "ret": ret, "spin": spin})


func slash(p: Vector2, col: Color, size: float = 110.0, angle: float = -0.5) -> void:
	_parts.append({"p": p, "v": Vector2.ZERO, "col": col, "t": 0.0, "life": 0.22, "kind": "slash", "size": size, "rot": angle, "vr": 0.0, "grav": 0.0})


# ---------------------------------------------------------------- loop

func _process(delta: float) -> void:
	var any := false
	var i := _nums.size() - 1
	while i >= 0:
		var n: Dictionary = _nums[i]
		n.t += delta
		n.p += n.v * delta
		n.v.y += 140.0 * delta
		n.v.x *= 0.96
		if n.t >= n.life:
			_nums.remove_at(i)
		i -= 1
	i = _parts.size() - 1
	while i >= 0:
		var q: Dictionary = _parts[i]
		q.t += delta
		q.p += q.v * delta
		q.v.y += q.grav * delta
		q.rot += q.vr * delta
		if q.t >= q.life:
			_parts.remove_at(i)
		i -= 1
	i = _rings.size() - 1
	while i >= 0:
		var r: Dictionary = _rings[i]
		r.t += delta
		if r.t >= r.life:
			_rings.remove_at(i)
		i -= 1
	i = _shots.size() - 1
	while i >= 0:
		var s: Dictionary = _shots[i]
		s.t += delta
		if s.t >= s.life:
			_shots.remove_at(i)
		i -= 1
	i = _flights.size() - 1
	while i >= 0:
		var f: Dictionary = _flights[i]
		f.t += delta
		if f.t >= f.life:
			_flights.remove_at(i)
		i -= 1
	var arrived := 0
	i = _coins.size() - 1
	while i >= 0:
		var c: Dictionary = _coins[i]
		c.t += delta
		if c.t < c.hold:
			c.p += c.v * delta
			c.v.y += 760.0 * delta
		else:
			if c.fly == 0.0:
				c.start = c.p
			c.fly += delta / 0.38
			var k := minf(c.fly, 1.0)
			var e := k * k * (3.0 - 2.0 * k)
			c.p = c.start.lerp(coin_target, e)
			if c.fly >= 1.0:
				arrived += 1
				_coins.remove_at(i)
		i -= 1
	if arrived > 0:
		coin_arrived.emit(arrived)
	any = not (_nums.is_empty() and _parts.is_empty() and _coins.is_empty() and _rings.is_empty() and _shots.is_empty() and _flights.is_empty())
	if any:
		queue_redraw()


func _draw() -> void:
	for r in _rings:
		var k: float = r.t / r.life
		var rad: float = lerpf(r.r0, r.r1, 1.0 - pow(1.0 - k, 3.0))
		var col: Color = r.col
		col.a *= 1.0 - k
		draw_arc(r.p, rad, 0.0, TAU, 40, col, lerpf(10.0, 2.0, k))
	for q in _parts:
		var k: float = q.t / q.life
		var col: Color = q.col
		col.a *= 1.0 - k * k
		match q.kind:
			"star":
				var sz: float = q.size * (1.0 - k * 0.5)
				draw_set_transform(q.p, q.rot, Vector2.ONE)
				draw_texture_rect(_t_star, Rect2(-sz * 0.5, -sz * 0.5, sz, sz), false, col)
			"puff":
				var sz2: float = q.size * (0.6 + k * 1.2)
				draw_set_transform(q.p, 0.0, Vector2.ONE)
				col.a *= 0.7
				draw_texture_rect(_t_puff, Rect2(-sz2 * 0.5, -sz2 * 0.5, sz2, sz2), false, col)
			"slash":
				draw_set_transform(q.p, q.rot, Vector2.ONE)
				var w: float = q.size * (0.7 + k * 0.5)
				draw_texture_rect(_t_slash, Rect2(-w * 0.5, -w * 0.25, w, w * 0.5), false, col)
			_:
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				draw_circle(q.p, q.size * 0.3 * (1.0 - k), col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for s in _shots:
		var k2: float = s.t / s.life
		var a: Vector2 = s.a
		var b: Vector2 = s.b
		var p: Vector2 = a.lerp(b, k2)
		var tail: Vector2 = a.lerp(b, maxf(k2 - 0.25, 0.0))
		draw_line(tail, p, s.col, 8.0)
		draw_circle(p, 8.0, Color(1, 1, 1, 0.95))
	for f in _flights:
		var k3: float = f.t / f.life
		var pos: Vector2
		if f.ret:
			var u := k3 * 2.0
			var along := u if u <= 1.0 else 2.0 - u
			var arc := sin(along * PI) * 40.0
			pos = f.a.lerp(f.b, along) + Vector2(0.0, -arc)
		else:
			pos = f.a.lerp(f.b, k3)
		var sz3: float = f.size
		draw_set_transform(pos, f.t * f.spin, Vector2.ONE)
		draw_texture_rect(f.tex, Rect2(-sz3 * 0.5, -sz3 * 0.5, sz3, sz3), false)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for c in _coins:
		var cs := 30.0
		draw_texture_rect(_t_coin, Rect2(c.p.x - cs * 0.5, c.p.y - cs * 0.5, cs, cs), false)
	for n in _nums:
		var k4: float = n.t / n.life
		var pop := 1.0 + (0.55 if n.crit else 0.3) * maxf(0.0, 1.0 - n.t / 0.14)
		var alpha := 1.0 if k4 < 0.6 else 1.0 - (k4 - 0.6) / 0.4
		var col2: Color = n.col
		col2.a = alpha
		var oc := Pal.OUTLINE
		oc.a = alpha
		var sz4: int = n.size
		draw_set_transform(n.p, 0.0, Vector2(pop, pop))
		draw_string_outline(_font, Vector2(-n.w * 0.5, 0.0), n.text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz4, 9, oc)
		draw_string(_font, Vector2(-n.w * 0.5, 0.0), n.text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz4, col2)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
