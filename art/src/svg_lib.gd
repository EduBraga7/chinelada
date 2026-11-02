class_name SvgLib
extends RefCounted
## Utilidades para escrever SVG por código no estilo "sticker": contorno grosso, cores chapadas
## com um tom de sombra e um brilho. O Godot rasteriza com Image.load_svg_from_string (tools/bake_art.gd).

const INK := "#2b1b2f"
const SW := 7.0


static func f(v: float) -> String:
	return "%.1f" % v


static func svg(w: int, h: int, body: String, defs: String = "") -> String:
	return '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d"><defs>%s</defs>%s</svg>' % [w, h, w, h, defs, body]


static func lin(id: String, c1: String, c2: String, vertical: bool = true) -> String:
	var xy := 'x1="0" y1="0" x2="0" y2="1"' if vertical else 'x1="0" y1="0" x2="1" y2="0"'
	return '<linearGradient id="%s" %s><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></linearGradient>' % [id, xy, c1, c2]


static func rad(id: String, c1: String, c2: String, cx: float = 0.4, cy: float = 0.3, r: float = 0.8) -> String:
	return '<radialGradient id="%s" cx="%s" cy="%s" r="%s"><stop offset="0" stop-color="%s"/><stop offset="1" stop-color="%s"/></radialGradient>' % [id, f(cx), f(cy), f(r), c1, c2]


static func _st(stroke: String, sw: float) -> String:
	if stroke == "" or sw <= 0.0:
		return ""
	return ' stroke="%s" stroke-width="%s" stroke-linejoin="round" stroke-linecap="round"' % [stroke, f(sw)]


static func ellipse(cx: float, cy: float, rx: float, ry: float, fill: String, stroke: String = INK, sw: float = SW, extra: String = "") -> String:
	return '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"%s %s/>' % [f(cx), f(cy), f(rx), f(ry), fill, _st(stroke, sw), extra]


static func circle(cx: float, cy: float, r: float, fill: String, stroke: String = INK, sw: float = SW, extra: String = "") -> String:
	return '<circle cx="%s" cy="%s" r="%s" fill="%s"%s %s/>' % [f(cx), f(cy), f(r), fill, _st(stroke, sw), extra]


static func rect(x: float, y: float, w: float, h: float, r: float, fill: String, stroke: String = INK, sw: float = SW, extra: String = "") -> String:
	return '<rect x="%s" y="%s" width="%s" height="%s" rx="%s" ry="%s" fill="%s"%s %s/>' % [f(x), f(y), f(w), f(h), f(r), f(r), fill, _st(stroke, sw), extra]


static func path(d: String, fill: String, stroke: String = INK, sw: float = SW, extra: String = "") -> String:
	return '<path d="%s" fill="%s"%s %s/>' % [d, fill, _st(stroke, sw), extra]


static func line(x1: float, y1: float, x2: float, y2: float, stroke: String = INK, sw: float = SW) -> String:
	return '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s" stroke-linecap="round"/>' % [f(x1), f(y1), f(x2), f(y2), stroke, f(sw)]


static func stroke_path(d: String, stroke: String = INK, sw: float = SW, extra: String = "") -> String:
	return '<path d="%s" fill="none" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round" %s/>' % [d, stroke, f(sw), extra]


static func group(body: String, transform: String) -> String:
	return '<g transform="%s">%s</g>' % [transform, body]


## Olho "googly": branco com contorno, pupila e brilho. lx/ly em [-1, 1] dizem para onde olha.
static func eye(cx: float, cy: float, r: float, lx: float = 0.0, ly: float = 0.0) -> String:
	var px := cx + lx * r * 0.38
	var py := cy + ly * r * 0.38 + r * 0.08
	return ellipse(cx, cy, r, r * 1.12, "#ffffff", INK, maxf(r * 0.2, 2.5)) \
		+ circle(px, py, r * 0.56, INK, "", 0) \
		+ circle(px + r * 0.2, py - r * 0.2, r * 0.2, "#ffffff", "", 0)


## Brilho suave (elipse branca translúcida)
static func shine(cx: float, cy: float, rx: float, ry: float, op: float = 0.35, rot: float = 0.0) -> String:
	return '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#ffffff" fill-opacity="%s" transform="rotate(%s %s %s)"/>' % [f(cx), f(cy), f(rx), f(ry), f(op), f(rot), f(cx), f(cy)]


## Sombra no chão
static func ground_shadow(cx: float, cy: float, rx: float, ry: float, op: float = 0.28) -> String:
	return '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="#1a0f1f" fill-opacity="%s"/>' % [f(cx), f(cy), f(rx), f(ry), f(op)]
