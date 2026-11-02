class_name AppIconArt
extends RefCounted
## Ícone do app: um chinelo voador com rastro e estrela de impacto sobre raios de sol.
## Saídas (tools/bake_art.gd grava em res://icon/): app_icon (512, tela cheia), app_icon_fg / app_icon_bg / app_icon_mono
## (432×432, camadas do ícone adaptativo do Android: o miolo seguro é o círculo de ~288 px do centro).

const INK := SvgLib.INK


static func build(out: Dictionary) -> void:
	out["app_icon"] = {"svg": _full(512), "w": 512, "h": 512}
	out["app_icon_bg"] = {"svg": _background(432), "w": 432, "h": 432}
	out["app_icon_fg"] = {"svg": _foreground(432), "w": 432, "h": 432}
	out["app_icon_mono"] = {"svg": _mono(432), "w": 432, "h": 432}


static func _defs() -> String:
	return SvgLib.rad("bgr", "#ffe066", "#e8401c", 0.5, 0.42, 0.78) \
		+ SvgLib.lin("sole", "#ffffff", "#cfdcf2") + SvgLib.lin("top", "#62a8ff", "#2358d0") \
		+ SvgLib.lin("star", "#fff27a", "#ffb81c")


## Raios de sol saindo de (cx, cy).
static func _rays(cx: float, cy: float, n: int, reach: float, op: float) -> String:
	var b := ""
	var step := TAU / float(n)
	for i in range(0, n, 2):
		var a0 := step * i - PI / 2.0
		var a1 := a0 + step
		b += '<polygon points="%s,%s %s,%s %s,%s" fill="#ffffff" fill-opacity="%s"/>' % [
			SvgLib.f(cx), SvgLib.f(cy), SvgLib.f(cx + cos(a0) * reach), SvgLib.f(cy + sin(a0) * reach),
			SvgLib.f(cx + cos(a1) * reach), SvgLib.f(cy + sin(a1) * reach), SvgLib.f(op)]
	return b


static func _star(cx: float, cy: float, ro: float, ri: float, points: int, fill: String) -> String:
	var pts: Array[String] = []
	for i in points * 2:
		var r := ro if i % 2 == 0 else ri
		var a := PI / float(points) * float(i) - PI / 2.0
		pts.append("%s,%s" % [SvgLib.f(cx + cos(a) * r), SvgLib.f(cy + sin(a) * r)])
	return '<polygon points="%s" fill="%s" stroke="%s" stroke-width="%s" stroke-linejoin="round"/>' % [" ".join(pts), fill, INK, SvgLib.f(ro * 0.07)]


## O chinelo (grade 128×128 de IconArt._slipper) centralizado em (cx, cy), com escala e giro.
static func _slipper_at(cx: float, cy: float, s: float, rot: float, sole: String, top: String, strap: String) -> String:
	return SvgLib.group(IconArt._slipper(sole, top, strap), "translate(%s %s) rotate(%s) scale(%s) translate(-64 -63)" % [SvgLib.f(cx), SvgLib.f(cy), SvgLib.f(rot), SvgLib.f(s)])


static func _trail(cx: float, cy: float, s: float) -> String:
	var b := ""
	for k in 3:
		var o := float(k) * 34.0 * s
		b += SvgLib.stroke_path("M %s %s Q %s %s %s %s" % [
			SvgLib.f(cx + 70.0 * s + o), SvgLib.f(cy + 150.0 * s - o * 0.35),
			SvgLib.f(cx + 130.0 * s + o), SvgLib.f(cy + 100.0 * s - o * 0.4),
			SvgLib.f(cx + 150.0 * s + o), SvgLib.f(cy + 20.0 * s - o * 0.2)], "#ffffff", 13.0 * s, 'stroke-opacity="%s"' % SvgLib.f(0.9 - 0.2 * k))
	return b


## Cena completa (chinelo + rastro + estrela) para o quadrado de tamanho `n`, com o miolo ocupando `fill` (0..1).
static func _scene(n: float, fill: float) -> String:
	var s := n / 512.0 * fill / 0.86
	var cx := n * 0.5
	var cy := n * 0.53
	var b := _trail(cx - 20.0 * s, cy - 10.0 * s, s)
	b += '<g opacity="0.28" transform="translate(%s %s) rotate(-24) scale(%s) translate(-64 -63)">%s</g>' % [
		SvgLib.f(cx + 12.0 * s), SvgLib.f(cy + 16.0 * s), SvgLib.f(3.0 * s), IconArt._slipper("#1a0f1f", "#1a0f1f", "#1a0f1f")]
	b += _slipper_at(cx, cy, 3.0 * s, -24.0, "url(#sole)", "url(#top)", "#ffffff")
	b += _star(cx - 120.0 * s, cy - 150.0 * s, 74.0 * s, 36.0 * s, 9, "url(#star)")
	b += _star(cx + 150.0 * s, cy - 175.0 * s, 30.0 * s, 14.0 * s, 4, "#ffffff")
	b += _star(cx + 175.0 * s, cy + 120.0 * s, 24.0 * s, 11.0 * s, 4, "#fff3b0")
	return b


static func _full(n: int) -> String:
	var fn := float(n)
	var body := '<rect width="%d" height="%d" fill="url(#bgr)"/>' % [n, n]
	body += _rays(fn * 0.5, fn * 0.46, 20, fn * 1.1, 0.16)
	body += _scene(fn, 0.86)
	return SvgLib.svg(n, n, body, _defs())


static func _background(n: int) -> String:
	var fn := float(n)
	var body := '<rect width="%d" height="%d" fill="url(#bgr)"/>' % [n, n]
	body += _rays(fn * 0.5, fn * 0.46, 20, fn * 1.1, 0.16)
	return SvgLib.svg(n, n, body, _defs())


static func _foreground(n: int) -> String:
	return SvgLib.svg(n, n, _scene(float(n), 0.62), _defs())


## Silhueta branca para o ícone "temático" do Android 13+.
static func _mono(n: int) -> String:
	var s := float(n) / 512.0 * 0.62 / 0.86
	var cx := float(n) * 0.5
	var cy := float(n) * 0.53
	var b := _slipper_at(cx, cy, 3.0 * s, -24.0, "#ffffff", "#ffffff", "#ffffff")
	b += '<g opacity="0.0"></g>'
	return SvgLib.svg(n, n, b, "")
