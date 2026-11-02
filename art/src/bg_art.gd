class_name BgArt
extends RefCounted
## Cenários dos 5 mundos (720×500). O chão (onde os heróis pisam) começa em y≈330.

const W := 720
const H := 500
const INK := SvgLib.INK


static func build(out: Dictionary) -> void:
	out["bg_cozinha"] = {"svg": _cozinha(), "w": W, "h": H}
	out["bg_quintal"] = {"svg": _quintal(), "w": W, "h": H}
	out["bg_rua"] = {"svg": _rua(), "w": W, "h": H}
	out["bg_escritorio"] = {"svg": _escritorio(), "w": W, "h": H}
	out["bg_banco"] = {"svg": _banco(), "w": W, "h": H}


static func _vignette() -> String:
	return '<rect x="0" y="330" width="720" height="170" fill="url(#vg)"/><rect x="0" y="0" width="720" height="500" fill="url(#vt)"/>'


static func _vdefs() -> String:
	return '<linearGradient id="vg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity="0.32"/></linearGradient>' \
		+ '<linearGradient id="vt" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0.18"/><stop offset="0.25" stop-color="#000" stop-opacity="0"/></linearGradient>'


static func _checker(y0: float, y1: float, size: float, c1: String, c2: String) -> String:
	var b := ""
	var rows := int(ceil((y1 - y0) / size))
	var cols := int(ceil(W / size)) + 1
	for r in rows:
		for c in cols:
			var col := c1 if (r + c) % 2 == 0 else c2
			b += '<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>' % [SvgLib.f(c * size), SvgLib.f(y0 + r * size), SvgLib.f(size), SvgLib.f(size), col]
	return b


# ------------------------------------------------------------------ Cozinha

static func _cozinha() -> String:
	var defs := _vdefs() + SvgLib.lin("wd", "#c98a4a", "#a5672e") + SvgLib.lin("sk", "#9fe0ff", "#d8f3ff")
	var b := '<rect x="0" y="0" width="720" height="330" fill="#f7e8c8"/>'
	for x in range(0, 721, 60):
		b += SvgLib.line(x, 0, x, 330, "#e6d0a2", 3)
	for y in range(0, 331, 60):
		b += SvgLib.line(0, y, 720, y, "#e6d0a2", 3)
	# armários superiores
	for i in 6:
		var x := i * 124.0 - 6.0
		b += SvgLib.rect(x, -10, 120, 112, 10, "url(#wd)", INK, 5)
		b += SvgLib.rect(x + 12, 14, 96, 72, 6, "#d8a064", "#8a5a32", 3)
		b += SvgLib.rect(x + 50, 84, 20, 8, 4, "#ffd23f", INK, 3)
	# janela
	b += SvgLib.rect(70, 130, 170, 130, 8, "url(#sk)", INK, 6)
	b += SvgLib.line(155, 130, 155, 260, "#ffffff", 8) + SvgLib.line(70, 195, 240, 195, "#ffffff", 8)
	b += SvgLib.path("M 70 126 Q 100 190 82 262 L 70 262 Z", "#ff8a8a", INK, 4) + SvgLib.path("M 240 126 Q 210 190 228 262 L 240 262 Z", "#ff8a8a", INK, 4)
	b += SvgLib.circle(190, 160, 14, "#fff3a0", "", 0)
	# fogão com panelas
	b += SvgLib.rect(500, 190, 190, 140, 10, "#3b3b4f", INK, 6)
	b += SvgLib.rect(516, 232, 158, 80, 8, "#2b2b3d", INK, 4) + SvgLib.circle(545, 212, 12, "#9aa0b4", INK, 3) + SvgLib.circle(595, 212, 12, "#9aa0b4", INK, 3)
	b += SvgLib.rect(528, 138, 70, 56, 10, "#b9c2d6", INK, 5) + SvgLib.rect(520, 132, 86, 14, 6, "#aab3c8", INK, 4)
	b += SvgLib.rect(614, 156, 60, 38, 8, "#e8473f", INK, 5)
	b += SvgLib.stroke_path("M 550 120 Q 540 100 552 84 M 574 120 Q 564 100 576 84", "#ffffff", 6, 'stroke-opacity="0.7"')
	# bancada
	b += SvgLib.rect(-10, 306, 740, 34, 6, "url(#wd)", INK, 5)
	# chão xadrez
	b += _checker(340, 500, 80, "#ffe4b0", "#f1b866")
	b += _vignette()
	return SvgLib.svg(W, H, b, defs)


# ------------------------------------------------------------------ Quintal

static func _quintal() -> String:
	var defs := _vdefs() + SvgLib.lin("sk", "#8fd0ff", "#fff3d0") + SvgLib.lin("gr", "#86d672", "#58b04a") + SvgLib.lin("fn", "#e8c88a", "#c9a15e")
	var b := '<rect x="0" y="0" width="720" height="340" fill="url(#sk)"/>'
	b += SvgLib.circle(620, 70, 40, "#fff0a0", "", 0, 'fill-opacity="0.9"')
	for c in [[110, 60, 1.0], [330, 90, 0.8], [520, 46, 0.9]]:
		b += '<g fill="#ffffff" fill-opacity="0.92" transform="translate(%s %s) scale(%s)"><circle cx="0" cy="0" r="26"/><circle cx="30" cy="8" r="22"/><circle cx="-30" cy="10" r="20"/><rect x="-40" y="2" width="84" height="26" rx="13"/></g>' % [SvgLib.f(c[0]), SvgLib.f(c[1]), SvgLib.f(c[2])]
	# árvore
	b += SvgLib.rect(600, 150, 30, 170, 8, "#8a5a32", INK, 5)
	for p in [[615, 120, 52], [575, 150, 40], [655, 150, 42], [615, 90, 36]]:
		b += SvgLib.circle(p[0], p[1], p[2], "#58b04a", INK, 5)
	b += SvgLib.shine(600, 100, 22, 10, 0.3, -20.0)
	# cerca
	for x in range(0, 740, 46):
		b += SvgLib.path("M %s 330 L %s 176 L %s 164 L %s 176 L %s 330 Z" % [SvgLib.f(x), SvgLib.f(x), SvgLib.f(x + 18), SvgLib.f(x + 36), SvgLib.f(x + 36)], "url(#fn)", INK, 4)
	b += SvgLib.rect(-6, 206, 732, 14, 4, "#b98a4e", INK, 4) + SvgLib.rect(-6, 270, 732, 14, 4, "#b98a4e", INK, 4)
	# varal
	b += SvgLib.stroke_path("M 0 120 Q 360 150 720 110", INK, 4)
	for c in [[90, "#ff6fa8"], [200, "#ffd23f"], [310, "#4aa8ff"], [430, "#a56bff"]]:
		var x: float = c[0]
		b += SvgLib.path("M %s 128 L %s 128 L %s 176 L %s 176 Z" % [SvgLib.f(x - 20), SvgLib.f(x + 20), SvgLib.f(x + 24), SvgLib.f(x - 24)], c[1], INK, 4)
	# chão: grama e caminho
	b += '<rect x="0" y="330" width="720" height="170" fill="url(#gr)"/>'
	b += SvgLib.path("M 0 372 Q 360 350 720 372 L 720 430 Q 360 408 0 430 Z", "#e6c88e", "", 0, 'fill-opacity="0.9"')
	for p in [[60, 360], [200, 400], [330, 470], [480, 385], [620, 450], [690, 360]]:
		b += SvgLib.ellipse(p[0], p[1], 18, 6, "#4a9a3e", "", 0, 'fill-opacity="0.6"')
	b += _vignette()
	return SvgLib.svg(W, H, b, defs)


# ------------------------------------------------------------------ Rua

static func _rua() -> String:
	var defs := _vdefs() + SvgLib.lin("sk", "#5a3f9a", "#ff9a5a") + SvgLib.lin("rd", "#5a5a6e", "#3e3e50")
	var b := '<rect x="0" y="0" width="720" height="340" fill="url(#sk)"/>'
	b += SvgLib.circle(560, 210, 50, "#ffd9a0", "", 0, 'fill-opacity="0.85"')
	var cols := ["#6b5a9a", "#85689c", "#5b4c8a", "#9a6a9c", "#6b5a9a", "#7a5f9a"]
	var xs := [-10, 100, 200, 330, 450, 590]
	var hs := [220, 170, 250, 190, 230, 160]
	var ws := [120, 110, 140, 130, 150, 140]
	for i in 6:
		b += SvgLib.rect(xs[i], 320 - hs[i], ws[i], hs[i], 4, cols[i], INK, 5)
		for r in int(hs[i] / 40.0) - 1:
			for c in int(ws[i] / 36.0) - 1:
				var lit := (i * 3 + r + c) % 3 != 0
				b += SvgLib.rect(xs[i] + 14 + c * 34, 320 - hs[i] + 16 + r * 38, 20, 24, 3, "#ffe27a" if lit else "#3b2f66", "", 0)
	# semáforo
	b += SvgLib.rect(36, 120, 18, 200, 4, "#3b3b4f", INK, 4) + SvgLib.rect(18, 90, 54, 94, 12, "#2b2b3d", INK, 5)
	b += SvgLib.circle(45, 114, 12, "#ff3b46", "", 0) + SvgLib.circle(45, 138, 12, "#5a4a2a", "", 0) + SvgLib.circle(45, 162, 12, "#2a5a3a", "", 0)
	# calçada e rua
	b += '<rect x="0" y="318" width="720" height="38" fill="#a8a4b8"/>' + SvgLib.line(0, 318, 720, 318, INK, 5) + SvgLib.line(0, 356, 720, 356, INK, 4)
	b += '<rect x="0" y="356" width="720" height="144" fill="url(#rd)"/>'
	for x in range(10, 720, 120):
		b += SvgLib.rect(x, 446, 70, 10, 5, "#fff3b0", "", 0)
	b += SvgLib.rect(300, 372, 120, 6, 3, "#ffffff", "", 0, 'fill-opacity="0.3"')
	b += _vignette()
	return SvgLib.svg(W, H, b, defs)


# ------------------------------------------------------------------ Escritório

static func _escritorio() -> String:
	var defs := _vdefs() + SvgLib.lin("sk", "#a8dcff", "#e6f6ff") + SvgLib.lin("cp", "#8aa0c0", "#6a7ea0")
	var b := '<rect x="0" y="0" width="720" height="330" fill="#d6e6ee"/>'
	for x in range(0, 721, 90):
		b += SvgLib.line(x, 0, x, 330, "#c2d6e0", 3)
	# janelão com a cidade
	b += SvgLib.rect(150, 40, 420, 210, 10, "url(#sk)", INK, 6)
	for i in 8:
		var h := 40.0 + ((i * 37) % 90)
		b += SvgLib.rect(166 + i * 48, 250 - h, 40, h, 3, "#9fb6cc", INK, 3)
	b += SvgLib.line(290, 40, 290, 250, "#ffffff", 7) + SvgLib.line(430, 40, 430, 250, "#ffffff", 7)
	# relógio de parede
	b += SvgLib.circle(640, 80, 34, "#ffffff", INK, 6) + SvgLib.stroke_path("M 640 80 L 640 58 M 640 80 L 656 88", INK, 5)
	# baias
	b += SvgLib.rect(-10, 200, 130, 130, 8, "url(#cp)", INK, 5) + SvgLib.rect(600, 214, 130, 116, 8, "url(#cp)", INK, 5)
	b += SvgLib.rect(18, 220, 56, 40, 4, "#ffffff", INK, 3) + SvgLib.rect(630, 232, 56, 40, 4, "#fff3a0", INK, 3)
	# planta
	b += SvgLib.path("M 130 330 L 140 276 L 170 276 L 180 330 Z", "#b9733c", INK, 5)
	for a in [-30, 0, 30, -55, 55]:
		b += SvgLib.ellipse(155, 250, 10, 34, "#3ddc7a", INK, 4, 'transform="rotate(%s 155 276)"' % SvgLib.f(a))
	# mesa
	b += SvgLib.rect(300, 290, 130, 40, 6, "#b98a4e", INK, 5) + SvgLib.rect(330, 250, 70, 42, 6, "#2b2b3d", INK, 4) + SvgLib.rect(338, 258, 54, 28, 3, "#7fd7ff", "", 0)
	# carpete
	b += '<rect x="0" y="330" width="720" height="170" fill="#7b8fb2"/>'
	for y in range(350, 500, 30):
		b += SvgLib.line(0, y, 720, y, "#6a7ea0", 3)
	b += _vignette()
	return SvgLib.svg(W, H, b, defs)


# ------------------------------------------------------------------ Banco e Repartição

static func _banco() -> String:
	var defs := _vdefs() + SvgLib.lin("cl", "#fff6e0", "#d8c9a4") + SvgLib.lin("wl", "#f4f1fa", "#d9d4e8")
	var b := '<rect x="0" y="0" width="720" height="330" fill="url(#wl)"/>'
	# arcos ao fundo
	for i in 3:
		var x := 60.0 + i * 220.0
		b += SvgLib.path("M %s 330 L %s 150 Q %s 70 %s 150 L %s 330 Z" % [SvgLib.f(x), SvgLib.f(x), SvgLib.f(x + 80), SvgLib.f(x + 160), SvgLib.f(x + 160)], "#e4dff2", "#bdb5d6", 5)
	# colunas
	for x in [20, 250, 480, 690]:
		b += SvgLib.rect(x - 22, 26, 44, 300, 6, "url(#cl)", INK, 5)
		b += SvgLib.rect(x - 32, 18, 64, 20, 5, "#e8d8a8", INK, 5) + SvgLib.rect(x - 32, 314, 64, 18, 5, "#e8d8a8", INK, 5)
		b += SvgLib.line(x - 8, 46, x - 8, 310, "#d8c9a4", 3) + SvgLib.line(x + 8, 46, x + 8, 310, "#d8c9a4", 3)
	# relógio grande
	b += SvgLib.circle(360, 96, 42, "#ffffff", INK, 7) + SvgLib.stroke_path("M 360 96 L 360 68 M 360 96 L 382 108", INK, 6) + SvgLib.circle(360, 96, 5, INK)
	# cordões de fila
	for x in [120, 300, 480, 640]:
		b += SvgLib.rect(x - 5, 262, 10, 70, 4, "#e8a31c", INK, 4) + SvgLib.circle(x, 260, 9, "#ffd23f", INK, 4)
	b += SvgLib.stroke_path("M 120 268 Q 210 296 300 268 M 300 268 Q 390 296 480 268 M 480 268 Q 560 296 640 268", "#e0343c", 6)
	# piso de mármore
	b += _checker(332, 500, 84, "#f4f2fa", "#c7c2da")
	b += _vignette()
	return SvgLib.svg(W, H, b, defs)
