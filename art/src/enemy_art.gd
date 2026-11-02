class_name EnemyArt
extends RefCounted
## Inimigos 256×256 (chefões 320×320), virados para a ESQUERDA (andam em direção aos heróis).
## Objetos (cone, boleto...) ficam de frente e ganham carinha de bravo.

const INK := SvgLib.INK


static func build(out: Dictionary) -> void:
	var s := {
		"barata": _barata("#b0652d", "#6e3a15", false), "formiga": _formiga(), "rato": _rato(), "mosca": _mosca(),
		"pombo": _pombo(), "gato": _gato("#e89a4a", "#b3651c", false), "cachorro": _cachorro(), "caracol": _caracol(),
		"cone": _cone(), "moto": _moto(), "buraco": _buraco(), "camelo": _camelo(),
		"boleto": _boleto(), "planilha": _planilha(), "reuniao": _reuniao(), "notificacao": _notificacao(),
		"fila": _fila(), "juros": _juros(), "carimbo": _carimbo(), "senha": _senha(),
	}
	for k in s:
		out["en_" + k] = {"svg": s[k], "w": 256, "h": 256}
	out["en_baratona"] = {"svg": _baratona(), "w": 320, "h": 320}
	out["en_gatao"] = {"svg": _gatao(), "w": 320, "h": 320}
	out["en_engarrafamento"] = {"svg": _engarrafamento(), "w": 320, "h": 256}
	out["en_segunda"] = {"svg": _segunda(), "w": 320, "h": 320}
	out["en_leao"] = {"svg": _leao(), "w": 320, "h": 320}


## Dois olhos googly bravos (sobrancelhas inclinadas para dentro).
static func _angry(x1: float, y1: float, x2: float, y2: float, r: float, lx: float = -0.6) -> String:
	var b := SvgLib.eye(x1, y1, r, lx, 0.2) + SvgLib.eye(x2, y2, r, lx, 0.2)
	b += SvgLib.stroke_path("M %s %s L %s %s" % [SvgLib.f(x1 - r * 1.2), SvgLib.f(y1 - r * 1.7), SvgLib.f(x1 + r * 1.1), SvgLib.f(y1 - r * 1.15)], INK, maxf(r * 0.55, 4.0))
	b += SvgLib.stroke_path("M %s %s L %s %s" % [SvgLib.f(x2 + r * 1.2), SvgLib.f(y2 - r * 1.7), SvgLib.f(x2 - r * 1.1), SvgLib.f(y2 - r * 1.15)], INK, maxf(r * 0.55, 4.0))
	return b


static func _crown(cx: float, cy: float, s: float) -> String:
	var d := "M %s %s L %s %s L %s %s L %s %s L %s %s L %s %s Z" % [
		SvgLib.f(cx - 30 * s), SvgLib.f(cy + 18 * s), SvgLib.f(cx - 34 * s), SvgLib.f(cy - 18 * s), SvgLib.f(cx - 14 * s), SvgLib.f(cy),
		SvgLib.f(cx), SvgLib.f(cy - 26 * s), SvgLib.f(cx + 14 * s), SvgLib.f(cy), SvgLib.f(cx + 34 * s), SvgLib.f(cy - 18 * s)]
	d += " L %s %s Z" % [SvgLib.f(cx + 30 * s), SvgLib.f(cy + 18 * s)]
	return SvgLib.path(d, "#ffd23f", INK, 6 * s) + SvgLib.circle(cx, cy - 26 * s, 5 * s, "#ff5a64", INK, 3) \
		+ SvgLib.circle(cx - 34 * s, cy - 18 * s, 4.5 * s, "#4aa8ff", INK, 3) + SvgLib.circle(cx + 34 * s, cy - 18 * s, 4.5 * s, "#4aa8ff", INK, 3)


static func _scaled(inner: String, k: float, dx: float, dy: float) -> String:
	return SvgLib.group(inner, "translate(%s %s) scale(%s)" % [SvgLib.f(dx), SvgLib.f(dy), SvgLib.f(k)])


# ------------------------------------------------------------------ Mundo 1: Cozinha

static func _barata(c1: String, c2: String, extras: bool) -> String:
	var defs := SvgLib.rad("bd", c1, c2, 0.35, 0.3, 0.9) + SvgLib.lin("hd", "#5a2e12", "#341a0a")
	var b := ""
	b += SvgLib.ground_shadow(136, 234, 82, 12)
	for i in 3:
		var x := 110.0 + i * 36.0
		var d := "M %s 172 Q %s 202 %s 224" % [SvgLib.f(x), SvgLib.f(x - 18), SvgLib.f(x - 34 + i * 6)]
		b += SvgLib.stroke_path(d, INK, 14) + SvgLib.stroke_path(d, "#7a431b", 7)
	b += SvgLib.stroke_path("M 52 110 Q 30 72 6 66", INK, 8)
	b += SvgLib.stroke_path("M 66 102 Q 56 58 36 42", INK, 8)
	b += SvgLib.ellipse(146, 142, 82, 58, "url(#bd)")
	b += SvgLib.stroke_path("M 74 142 Q 146 136 218 142", INK, 4, 'stroke-opacity="0.5"')
	b += SvgLib.stroke_path("M 130 92 Q 138 142 128 192", INK, 5, 'stroke-opacity="0.5"')
	b += SvgLib.shine(128, 108, 40, 13, 0.4, -10.0)
	b += SvgLib.circle(66, 136, 38, "url(#hd)")
	b += SvgLib.eye(54, 122, 15, -0.7, 0.2) + SvgLib.eye(80, 118, 13, -0.7, 0.2)
	b += SvgLib.stroke_path("M 40 156 Q 56 168 74 154", INK, 5.5)
	if extras:
		b += SvgLib.stroke_path("M 38 100 L 66 112", INK, 7) + SvgLib.stroke_path("M 92 104 L 74 112", INK, 7)
	return SvgLib.svg(256, 256, b, defs)


static func _formiga() -> String:
	var defs := SvgLib.rad("ab", "#9a4a34", "#4a1a14", 0.35, 0.3, 0.9) + SvgLib.lin("ah", "#3a2430", "#1f1218")
	var b := ""
	b += SvgLib.ground_shadow(128, 236, 72, 10)
	for i in 3:
		var x := 96.0 + i * 28.0
		var d := "M %s 170 Q %s 198 %s 228" % [SvgLib.f(x), SvgLib.f(x - 14), SvgLib.f(x - 28)]
		b += SvgLib.stroke_path(d, INK, 12) + SvgLib.stroke_path(d, "#5a3030", 6)
	b += SvgLib.stroke_path("M 48 128 Q 30 94 8 88", INK, 7) + SvgLib.stroke_path("M 68 122 Q 66 86 46 70", INK, 7)
	b += SvgLib.ellipse(178, 168, 52, 40, "url(#ab)")
	b += SvgLib.shine(166, 150, 24, 8, 0.4, -12.0)
	b += SvgLib.ellipse(112, 162, 26, 22, "url(#ah)")
	b += SvgLib.circle(62, 152, 32, "url(#ah)")
	b += _angry(52, 144, 76, 140, 11)
	b += SvgLib.stroke_path("M 44 166 Q 58 174 72 164", INK, 5)
	return SvgLib.svg(256, 256, b, defs)


static func _rato() -> String:
	var defs := SvgLib.lin("rb", "#aab0c4", "#7a8098") + SvgLib.lin("rn", "#d6dae8", "#b5bbd0")
	var b := ""
	b += SvgLib.ground_shadow(140, 236, 84, 11)
	b += SvgLib.stroke_path("M 212 182 Q 254 176 246 122", INK, 15) + SvgLib.stroke_path("M 212 182 Q 254 176 246 122", "#ffa0b4", 8)
	b += SvgLib.ellipse(110, 228, 22, 9, "#ffa0b4") + SvgLib.ellipse(168, 228, 22, 9, "#ffa0b4")
	b += SvgLib.ellipse(152, 168, 70, 52, "url(#rb)")
	b += SvgLib.ellipse(170, 190, 36, 22, "url(#rn)", "", 0)
	b += SvgLib.circle(98, 112, 26, "url(#rb)") + SvgLib.circle(98, 112, 14, "#ffa0b4", "", 0)
	b += SvgLib.circle(128, 118, 22, "url(#rb)") + SvgLib.circle(128, 118, 11, "#ffa0b4", "", 0)
	b += SvgLib.circle(76, 150, 40, "url(#rb)")
	b += SvgLib.ellipse(46, 164, 28, 19, "url(#rn)") + SvgLib.circle(24, 164, 9, "#ff7a98")
	b += _angry(64, 142, 92, 138, 11)
	b += SvgLib.stroke_path("M 34 156 L 4 148 M 34 164 L 2 166 M 36 172 L 6 184", INK, 3.5)
	b += SvgLib.path("M 40 182 L 50 196 L 58 182 Z", "#ffffff", INK, 3.5)
	return SvgLib.svg(256, 256, b, defs)


static func _mosca() -> String:
	var defs := SvgLib.rad("mb", "#59506e", "#2b2640", 0.35, 0.3, 0.9)
	var b := ""
	b += SvgLib.ground_shadow(140, 238, 66, 9)
	for i in 3:
		var x := 120.0 + i * 24.0
		var d := "M %s 182 Q %s 208 %s 230" % [SvgLib.f(x), SvgLib.f(x - 10), SvgLib.f(x - 22)]
		b += SvgLib.stroke_path(d, INK, 9)
	b += SvgLib.ellipse(150, 96, 58, 26, "#ffffff", INK, 5, 'fill-opacity="0.65" transform="rotate(-18 150 96)"')
	b += SvgLib.ellipse(176, 110, 50, 22, "#ffffff", INK, 5, 'fill-opacity="0.55" transform="rotate(10 176 110)"')
	b += SvgLib.ellipse(150, 160, 54, 40, "url(#mb)")
	b += SvgLib.stroke_path("M 120 130 Q 124 160 120 188 M 150 126 Q 154 160 150 192", "#8b84a8", 4)
	b += SvgLib.circle(90, 150, 34, "url(#mb)")
	b += SvgLib.circle(78, 138, 20, "#e0343c") + SvgLib.circle(104, 134, 17, "#e0343c")
	b += SvgLib.eye(76, 138, 11, -0.7, 0.2) + SvgLib.eye(104, 134, 9.5, -0.7, 0.2)
	b += SvgLib.stroke_path("M 62 118 L 86 128", INK, 6) + SvgLib.stroke_path("M 120 116 L 100 126", INK, 6)
	b += SvgLib.stroke_path("M 62 166 Q 58 180 70 186", INK, 5)
	return SvgLib.svg(256, 256, b, defs)


static func _baratona() -> String:
	var cape := SvgLib.path("M 150 70 Q 240 76 262 200 L 196 190 Z", "#c42b3d", INK, 6)
	var body := _barata("#8a3b1c", "#4e210d", true)
	body = body.substr(body.find("</defs>") + 7, body.length() - body.find("</defs>") - 13)
	var defs := SvgLib.rad("bd", "#8a3b1c", "#4e210d", 0.35, 0.3, 0.9) + SvgLib.lin("hd", "#4a2410", "#2a1408")
	var b := cape + body + _crown(66, 98, 1.05)
	return SvgLib.svg(320, 320, _scaled(b, 1.2, 0, 8), defs)


# ------------------------------------------------------------------ Mundo 2: Quintal

static func _pombo() -> String:
	var defs := SvgLib.lin("pb", "#9fb0cc", "#6c7fa0") + SvgLib.lin("pn", "#5fd6a0", "#a06bff") + SvgLib.lin("pw", "#7b8cab", "#56668a")
	var b := ""
	b += SvgLib.ground_shadow(140, 238, 70, 10)
	b += SvgLib.path("M 196 172 L 246 160 L 244 196 L 200 196 Z", "#56668a")
	b += SvgLib.stroke_path("M 126 214 L 126 236 M 156 214 L 156 236", "#ff9a3c", 8)
	b += SvgLib.ellipse(126, 238, 14, 6, "#ff9a3c", INK, 4) + SvgLib.ellipse(158, 238, 14, 6, "#ff9a3c", INK, 4)
	b += SvgLib.ellipse(148, 166, 64, 54, "url(#pb)")
	b += SvgLib.ellipse(166, 170, 38, 28, "url(#pw)")
	b += SvgLib.circle(86, 118, 34, "url(#pb)")
	b += SvgLib.ellipse(106, 142, 24, 15, "url(#pn)", INK, 4)
	b += SvgLib.path("M 56 116 L 24 126 L 56 136 Z", "#ffb23c")
	b += _angry(78, 112, 100, 108, 9, -0.9)
	return SvgLib.svg(256, 256, b, defs)


static func _gato(c1: String, c2: String, extras: bool) -> String:
	var defs := SvgLib.lin("gb", c1, c2)
	var b := ""
	b += SvgLib.ground_shadow(140, 238, 80, 11)
	b += SvgLib.stroke_path("M 206 182 Q 252 166 240 110", INK, 24) + SvgLib.stroke_path("M 206 182 Q 252 166 240 110", c2, 13)
	b += SvgLib.ellipse(150, 178, 62, 48, "url(#gb)")
	b += SvgLib.ellipse(106, 228, 22, 9, c1) + SvgLib.ellipse(176, 228, 22, 9, c1)
	b += SvgLib.path("M 50 108 L 56 62 L 86 90 Z", "url(#gb)") + SvgLib.path("M 100 88 L 128 62 L 130 112 Z", "url(#gb)")
	b += SvgLib.path("M 58 94 L 60 74 L 74 88 Z", "#ffa0b4", "", 0) + SvgLib.path("M 108 88 L 120 76 L 120 100 Z", "#ffa0b4", "", 0)
	b += SvgLib.circle(88, 132, 44, "url(#gb)")
	b += SvgLib.stroke_path("M 76 92 L 80 104 M 90 90 L 92 102 M 104 92 L 102 104", c2, 5)
	b += _angry(70, 130, 102, 126, 11, -0.4)
	b += SvgLib.path("M 78 146 L 90 146 L 84 154 Z", "#ff7a98", INK, 3)
	b += SvgLib.stroke_path("M 62 158 Q 76 166 86 156 Q 96 166 110 158", INK, 4.5)
	b += SvgLib.path("M 70 160 L 74 170 L 78 160 Z", "#ffffff", INK, 2.5) + SvgLib.path("M 94 160 L 98 170 L 102 160 Z", "#ffffff", INK, 2.5)
	b += SvgLib.stroke_path("M 44 140 L 20 132 M 44 148 L 18 150 M 130 140 L 156 132 M 130 148 L 158 150", INK, 3)
	return SvgLib.svg(256, 256, b, defs)


static func _gatao() -> String:
	var cape := SvgLib.path("M 150 80 Q 244 90 262 214 L 190 200 Z", "#7a2bd0", INK, 6)
	var raw := _gato("#e8a04a", "#b36a1c", true)
	var body := raw.substr(raw.find("</defs>") + 7, raw.length() - raw.find("</defs>") - 13)
	var defs := SvgLib.lin("gb", "#e8a04a", "#b36a1c")
	var b := cape + body + _crown(88, 74, 1.0)
	return SvgLib.svg(320, 320, _scaled(b, 1.2, 0, 8), defs)


static func _cachorro() -> String:
	var defs := SvgLib.lin("db", "#b07a48", "#7b4f2a") + SvgLib.lin("dj", "#d8aa78", "#b8854f") + SvgLib.lin("de", "#5a3418", "#3a2010")
	var b := ""
	b += SvgLib.ground_shadow(150, 238, 90, 11)
	b += SvgLib.ellipse(156, 174, 70, 52, "url(#db)")
	b += SvgLib.rect(120, 204, 26, 30, 10, "url(#db)") + SvgLib.rect(176, 204, 26, 30, 10, "url(#db)")
	b += SvgLib.path("M 96 88 Q 70 70 60 96 Q 62 124 84 126 Z", "url(#de)")
	b += SvgLib.path("M 128 86 Q 154 70 160 100 Q 156 124 134 122 Z", "url(#de)")
	b += SvgLib.circle(94, 136, 48, "url(#db)")
	b += SvgLib.ellipse(60, 158, 36, 26, "url(#dj)") + SvgLib.ellipse(32, 150, 11, 8, "#2b1b2f", "", 0)
	b += _angry(78, 128, 108, 124, 11, -0.5)
	b += SvgLib.path("M 30 168 Q 60 188 92 164 L 84 176 Q 60 194 34 178 Z", "#7a2434", INK, 4)
	for x in [40, 52, 64, 76]:
		b += SvgLib.path("M %s 170 L %s 180 L %s 170 Z" % [SvgLib.f(x), SvgLib.f(x + 5), SvgLib.f(x + 10)], "#ffffff", INK, 2.5)
	b += SvgLib.path("M 70 176 Q 110 214 150 176 L 144 160 Q 110 190 76 160 Z", "#d8323c", INK, 5)
	for x in [84, 100, 116, 132]:
		b += SvgLib.path("M %s 184 L %s 170 L %s 184 Z" % [SvgLib.f(x - 5), SvgLib.f(x), SvgLib.f(x + 5)], "#e0e4ee", INK, 3)
	return SvgLib.svg(256, 256, b, defs)


static func _caracol() -> String:
	var defs := SvgLib.lin("cb", "#e8c898", "#c9a06a") + SvgLib.rad("cs", "#c88bff", "#7a3fd0", 0.35, 0.3, 0.9)
	var b := ""
	b += SvgLib.ground_shadow(130, 240, 100, 10)
	b += SvgLib.path("M 30 216 Q 30 190 62 188 L 214 198 Q 246 204 242 228 L 48 234 Q 28 232 30 216 Z", "url(#cb)")
	b += SvgLib.stroke_path("M 52 190 L 38 128", INK, 10) + SvgLib.stroke_path("M 52 190 L 38 128", "#e8c898", 5)
	b += SvgLib.stroke_path("M 74 190 L 82 124", INK, 10) + SvgLib.stroke_path("M 74 190 L 82 124", "#e8c898", 5)
	b += SvgLib.eye(36, 118, 12, -0.5, 0.2) + SvgLib.eye(84, 112, 12, -0.5, 0.2)
	b += SvgLib.stroke_path("M 22 106 L 44 110 M 98 102 L 76 106", INK, 6)
	b += SvgLib.circle(152, 138, 66, "url(#cs)")
	b += SvgLib.stroke_path("M 152 138 m -4 0 a 8 8 0 1 1 8 8 a 22 22 0 1 1 -22 -22 a 38 38 0 1 1 38 38", "#e8d6ff", 7)
	b += SvgLib.shine(128, 96, 20, 8, 0.35, -30.0)
	b += SvgLib.stroke_path("M 44 216 Q 58 226 74 214", INK, 5)
	return SvgLib.svg(256, 256, b, defs)


# ------------------------------------------------------------------ Mundo 3: Rua e Trânsito

static func _cone() -> String:
	var defs := SvgLib.lin("cn", "#ff8a2a", "#e85a0a")
	var b := ""
	b += SvgLib.ground_shadow(128, 240, 84, 10)
	b += SvgLib.ellipse(84, 238, 24, 9, "#2b2b3d") + SvgLib.ellipse(172, 238, 24, 9, "#2b2b3d")
	b += SvgLib.rect(36, 202, 184, 28, 8, "#d8480c")
	b += SvgLib.path("M 128 22 L 198 206 L 58 206 Z", "url(#cn)")
	b += SvgLib.path("M 112 70 L 144 70 L 152 98 L 104 98 Z", "#ffffff", "", 0)
	b += SvgLib.path("M 92 118 L 164 118 L 176 150 L 80 150 Z", "#ffffff", "", 0)
	b += SvgLib.stroke_path("M 128 22 L 198 206 L 58 206 Z", INK, 7, 'stroke-linejoin="round"')
	b += _angry(104, 168, 152, 168, 12, 0.0)
	b += SvgLib.stroke_path("M 108 192 Q 128 180 148 192", INK, 5.5)
	b += SvgLib.shine(104, 100, 8, 22, 0.35, 18.0)
	return SvgLib.svg(256, 256, b, defs)


static func _moto() -> String:
	var defs := SvgLib.lin("mt", "#ff5a64", "#c42b3d")
	var b := ""
	b += SvgLib.ground_shadow(130, 240, 100, 10)
	b += SvgLib.circle(224, 170, 14, "#c9ced8", "", 0, 'fill-opacity="0.7"') + SvgLib.circle(244, 156, 10, "#c9ced8", "", 0, 'fill-opacity="0.55"')
	b += SvgLib.path("M 78 156 L 112 122 L 206 122 L 226 164 L 204 196 L 92 196 Z", "url(#mt)")
	b += SvgLib.rect(122, 108, 74, 22, 9, "#2b2b3d")
	b += SvgLib.stroke_path("M 74 116 L 96 122 L 82 100", INK, 8)
	b += SvgLib.circle(70, 208, 32, "#2b2b3d") + SvgLib.circle(70, 208, 13, "#9aa0b4")
	b += SvgLib.circle(196, 208, 32, "#2b2b3d") + SvgLib.circle(196, 208, 13, "#9aa0b4")
	b += SvgLib.circle(66, 142, 24, "#fff8c4", INK, 6)
	b += SvgLib.eye(64, 140, 13, -0.6, 0.2)
	b += SvgLib.stroke_path("M 42 108 L 80 124", INK, 8)
	b += SvgLib.stroke_path("M 136 150 L 190 150", "#ffffff", 6)
	return SvgLib.svg(256, 256, b, defs)


static func _buraco() -> String:
	var defs := SvgLib.lin("br", "#8a8a9a", "#5e5e70") + SvgLib.rad("bh", "#4a2c26", "#150c0c", 0.5, 0.5, 0.7)
	var b := ""
	b += SvgLib.ellipse(128, 160, 112, 62, "url(#br)")
	b += SvgLib.stroke_path("M 30 130 L 8 110 M 226 130 L 248 108 M 60 214 L 40 236 M 196 216 L 218 238", "#4a4a5a", 6)
	b += SvgLib.ellipse(128, 156, 96, 50, "url(#bh)")
	var teeth := ""
	for i in 9:
		var x := 52.0 + i * 19.0
		teeth += SvgLib.path("M %s 124 L %s 144 L %s 124 Z" % [SvgLib.f(x - 8), SvgLib.f(x), SvgLib.f(x + 8)], "#ffffff", INK, 3)
		teeth += SvgLib.path("M %s 188 L %s 170 L %s 188 Z" % [SvgLib.f(x - 8), SvgLib.f(x), SvgLib.f(x + 8)], "#ffffff", INK, 3)
	b += teeth
	b += SvgLib.ellipse(94, 150, 17, 13, "#fff36b", INK, 5) + SvgLib.ellipse(162, 150, 17, 13, "#fff36b", INK, 5)
	b += SvgLib.ellipse(92, 152, 6, 8, INK, "", 0) + SvgLib.ellipse(160, 152, 6, 8, INK, "", 0)
	b += SvgLib.stroke_path("M 72 128 L 112 144 M 184 128 L 144 144", INK, 6)
	return SvgLib.svg(256, 256, b, defs)


static func _camelo() -> String:
	var defs := SvgLib.lin("cs", "#ffd23f", "#e0a91c") + SvgLib.lin("ck", "#f1c9a2", "#d3a077") + SvgLib.lin("cg", "#a8693a", "#6e4222")
	var b := ""
	b += SvgLib.ground_shadow(130, 240, 84, 10)
	b += SvgLib.rect(150, 84, 92, 116, 24, "url(#cg)")
	b += SvgLib.stroke_path("M 176 90 L 168 56 M 206 88 L 214 54", INK, 6)
	b += SvgLib.path("M 150 62 Q 168 30 190 62 Z", "#4aa8ff") + SvgLib.circle(214, 52, 11, "#ffd23f", INK, 4)
	b += SvgLib.rect(166, 130, 60, 28, 10, "#ff7a98", INK, 4) + SvgLib.rect(166, 168, 60, 18, 8, "#7fd7ff", INK, 4)
	b += SvgLib.ellipse(98, 232, 22, 8, "#2b2b3d") + SvgLib.ellipse(138, 232, 22, 8, "#2b2b3d")
	b += SvgLib.ellipse(116, 170, 50, 54, "url(#cs)")
	b += SvgLib.circle(104, 110, 38, "url(#ck)")
	b += SvgLib.path("M 66 104 Q 70 62 106 62 Q 142 64 142 100 Q 112 88 66 104 Z", "#2f78e8") + SvgLib.path("M 70 100 Q 38 98 34 112 Q 52 116 74 112 Z", "#1f58c0")
	b += SvgLib.eye(88, 112, 10, -0.7, 0.3) + SvgLib.eye(116, 110, 10, -0.7, 0.3)
	b += SvgLib.path("M 76 104 L 98 104 L 98 112 Q 88 106 76 112 Z", "#f1c9a2", INK, 3.5) + SvgLib.path("M 106 102 L 128 102 L 128 110 Q 118 104 106 110 Z", "#f1c9a2", INK, 3.5)
	b += SvgLib.path("M 84 130 Q 104 148 128 128 Z", "#ffffff", INK, 4.5)
	b += SvgLib.stroke_path("M 70 160 Q 46 170 40 190", INK, 22) + SvgLib.stroke_path("M 70 160 Q 46 170 40 190", "#ffd23f", 13)
	b += SvgLib.circle(38, 196, 14, "#ffd23f", INK, 5) + SvgLib.circle(38, 196, 8, "#ffffff", INK, 3)
	return SvgLib.svg(256, 256, b, defs)


static func _car(x: float, col: String, dark: String, lead: bool) -> String:
	var b := ""
	b += SvgLib.rect(x, 124, 118, 52, 18, col)
	b += SvgLib.path("M %s 124 L %s 92 L %s 92 L %s 124 Z" % [SvgLib.f(x + 22), SvgLib.f(x + 38), SvgLib.f(x + 84), SvgLib.f(x + 100)], dark)
	b += SvgLib.path("M %s 120 L %s 99 L %s 99 L %s 120 Z" % [SvgLib.f(x + 32), SvgLib.f(x + 42), SvgLib.f(x + 80), SvgLib.f(x + 92)], "#bfe9ff", INK, 4)
	b += SvgLib.circle(x + 28, 180, 17, "#2b2b3d") + SvgLib.circle(x + 28, 180, 7, "#9aa0b4", "", 0)
	b += SvgLib.circle(x + 92, 180, 17, "#2b2b3d") + SvgLib.circle(x + 92, 180, 7, "#9aa0b4", "", 0)
	if lead:
		b += _angry(x + 16, 146, x + 42, 146, 9, -0.6)
		b += SvgLib.stroke_path("M %s 166 Q %s 156 %s 166" % [SvgLib.f(x + 10), SvgLib.f(x + 28), SvgLib.f(x + 48)], INK, 5)
	else:
		b += SvgLib.circle(x + 10, 146, 8, "#fff8c4", INK, 4)
	return b


static func _engarrafamento() -> String:
	var b := ""
	b += SvgLib.ground_shadow(160, 232, 150, 10)
	b += _car(196, "#4aa8ff", "#2468c4", false)
	b += _car(104, "#ffd23f", "#c79a0a", false)
	b += _car(10, "#ff5a64", "#b72a38", true)
	b += SvgLib.stroke_path("M 40 64 L 40 92 M 68 56 L 62 86 M 24 70 L 8 84", "#ffd23f", 7) + SvgLib.circle(40, 100, 4, "#ffd23f", "", 0)
	b += SvgLib.stroke_path("M 150 70 L 150 96 M 178 62 L 172 90", "#ffd23f", 7)
	return SvgLib.svg(320, 256, b)


# ------------------------------------------------------------------ Mundo 4: Escritório

static func _boleto() -> String:
	var defs := SvgLib.lin("pp", "#fffbea", "#f1e6c4")
	var b := ""
	b += SvgLib.ground_shadow(128, 240, 70, 9)
	b += SvgLib.rect(94, 214, 22, 22, 8, "#8b84a8") + SvgLib.rect(142, 214, 22, 22, 8, "#8b84a8")
	b += SvgLib.path("M 58 30 L 168 30 L 200 62 L 200 214 L 58 214 Z", "url(#pp)")
	b += SvgLib.path("M 168 30 L 168 62 L 200 62 Z", "#d9c99a", INK, 5)
	b += SvgLib.rect(74, 44, 60, 9, 4, "#a8a4b8", "", 0) + SvgLib.rect(74, 60, 40, 8, 4, "#a8a4b8", "", 0)
	for i in 14:
		b += SvgLib.line(76 + i * 8.5, 184, 76 + i * 8.5, 204, INK, 3 + (i % 3) * 1.5)
	b += _angry(98, 98, 140, 98, 12, 0.0)
	b += SvgLib.stroke_path("M 104 124 Q 120 112 138 124", INK, 5.5)
	b += SvgLib.rect(70, 132, 118, 40, 8, "none", "#e0343c", 7, 'transform="rotate(-14 129 152)"')
	b += SvgLib.stroke_path("M 84 152 L 176 144", "#e0343c", 9)
	return SvgLib.svg(256, 256, b, defs)


static func _planilha() -> String:
	var defs := SvgLib.lin("pl", "#f6fff6", "#dff3df")
	var b := ""
	b += SvgLib.ground_shadow(128, 240, 70, 9)
	b += SvgLib.rect(94, 210, 22, 26, 8, "#2e9e5b") + SvgLib.rect(142, 210, 22, 26, 8, "#2e9e5b")
	b += SvgLib.rect(44, 34, 168, 182, 10, "url(#pl)")
	b += SvgLib.rect(44, 34, 168, 28, 10, "#2e9e5b")
	for i in 1:
		pass
	for y in [92, 122, 152, 182]:
		b += SvgLib.line(44, y, 212, y, "#9ccfae", 3)
	for x in [88, 132, 172]:
		b += SvgLib.line(x, 62, x, 216, "#9ccfae", 3)
	b += SvgLib.rect(138, 154, 70, 26, 4, "#ff5a64", "#b72a38", 4)
	b += SvgLib.stroke_path("M 150 168 L 196 168", "#ffffff", 5)
	b += _angry(88, 110, 126, 110, 11, 0.0)
	b += SvgLib.stroke_path("M 92 140 Q 108 130 124 140", INK, 5)
	b += SvgLib.stroke_path("M 44 34 L 212 34 L 212 216 L 44 216 Z", INK, 7)
	return SvgLib.svg(256, 256, b, defs)


static func _reuniao() -> String:
	var defs := SvgLib.rad("rc", "#ffffff", "#e6ecf8", 0.4, 0.35, 0.8)
	var b := ""
	b += SvgLib.ground_shadow(128, 240, 70, 9)
	b += SvgLib.rect(88, 206, 24, 30, 9, "#4a5070") + SvgLib.rect(144, 206, 24, 30, 9, "#4a5070")
	b += SvgLib.circle(128, 122, 90, "#7a5be0")
	b += SvgLib.circle(128, 122, 76, "url(#rc)")
	for i in 12:
		var a := deg_to_rad(i * 30.0)
		var r1 := 62.0 if i % 3 == 0 else 68.0
		b += SvgLib.line(128 + sin(a) * 72, 122 - cos(a) * 72, 128 + sin(a) * r1, 122 - cos(a) * r1, INK, 4)
	b += SvgLib.stroke_path("M 128 122 L 128 78", INK, 6) + SvgLib.stroke_path("M 128 122 L 160 138", INK, 6) + SvgLib.circle(128, 122, 6, INK)
	b += SvgLib.eye(100, 104, 11, 0.0, 0.5) + SvgLib.eye(156, 104, 11, 0.0, 0.5)
	b += SvgLib.path("M 86 98 L 114 98 L 114 106 L 86 106 Z", "#7a5be0", "", 0) + SvgLib.path("M 142 98 L 170 98 L 170 106 L 142 106 Z", "#7a5be0", "", 0)
	b += SvgLib.ellipse(100, 120, 12, 5, "#b9a8f0", "", 0) + SvgLib.ellipse(156, 120, 12, 5, "#b9a8f0", "", 0)
	b += SvgLib.ellipse(128, 156, 14, 12, "#7a2434", SvgLib.INK, 5)
	return SvgLib.svg(256, 256, b, defs)


static func _notificacao() -> String:
	var defs := SvgLib.lin("bl", "#ffd45a", "#f0a01c")
	var b := ""
	b += SvgLib.ground_shadow(128, 240, 66, 9)
	b += SvgLib.circle(128, 34, 12, "#e8a31c")
	b += SvgLib.path("M 128 40 C 66 40 64 110 52 152 L 204 152 C 192 110 190 40 128 40 Z", "url(#bl)")
	b += SvgLib.ellipse(128, 154, 82, 14, "#e8a31c")
	b += SvgLib.circle(128, 184, 18, "#e8a31c")
	b += SvgLib.shine(98, 80, 12, 28, 0.4, 16.0)
	b += _angry(104, 108, 152, 108, 12, 0.0)
	b += SvgLib.ellipse(128, 138, 13, 9, "#7a2434", INK, 5)
	b += SvgLib.circle(192, 62, 28, "#ff3b46") + SvgLib.rect(188, 46, 8, 18, 4, "#ffffff", "", 0) + SvgLib.circle(192, 74, 5, "#ffffff", "", 0)
	return SvgLib.svg(256, 256, b, defs)


static func _segunda() -> String:
	var defs := SvgLib.lin("cl", "#fffdf4", "#f3ecd6")
	var b := ""
	b += SvgLib.ground_shadow(128, 240, 90, 10)
	b += SvgLib.rect(88, 214, 26, 24, 9, "#4a3a6a") + SvgLib.rect(146, 214, 26, 24, 9, "#4a3a6a")
	b += SvgLib.rect(34, 30, 188, 192, 16, "url(#cl)")
	b += SvgLib.path("M 34 46 Q 34 30 50 30 L 206 30 Q 222 30 222 46 L 222 76 L 34 76 Z", "#e8473f")
	b += SvgLib.circle(84, 28, 9, "#2b1b2f") + SvgLib.circle(172, 28, 9, "#2b1b2f")
	b += SvgLib.stroke_path("M 108 96 Q 108 82 126 82 Q 146 82 146 100 Q 146 112 112 140 L 150 140", INK, 12)
	b += SvgLib.ellipse(100, 164, 14, 6, "#8a6bd0", "", 0, 'fill-opacity="0.8"') + SvgLib.ellipse(156, 164, 14, 6, "#8a6bd0", "", 0, 'fill-opacity="0.8"')
	b += _angry(98, 156, 158, 156, 13, 0.0)
	b += SvgLib.stroke_path("M 104 196 Q 128 180 154 196", INK, 7)
	b += SvgLib.circle(190, 112, 16, "none", "#8a5a32", 6) + SvgLib.stroke_path("M 202 118 Q 214 118 212 132", "#8a5a32", 5)
	b += SvgLib.stroke_path("M 60 96 L 76 100 M 60 110 L 74 112", "#9aa0b4", 4)
	b += SvgLib.stroke_path("M 34 30 L 222 30 L 222 222 L 34 222 Z", INK, 7)
	return SvgLib.svg(320, 320, _scaled(b, 1.2, 6, 6), defs)


# ------------------------------------------------------------------ Mundo 5: Banco e Repartição

static func _fila() -> String:
	var defs := SvgLib.lin("fk", "#d2cce2", "#a69fc2") + SvgLib.lin("ft", "#8b84a8", "#645d82")
	var b := ""
	b += SvgLib.ground_shadow(128, 240, 56, 9)
	b += SvgLib.rect(100, 196, 20, 36, 9, "#4a4468") + SvgLib.rect(138, 196, 20, 36, 9, "#4a4468")
	b += SvgLib.ellipse(110, 236, 24, 8, "#2b2b3d") + SvgLib.ellipse(150, 236, 24, 8, "#2b2b3d")
	b += SvgLib.rect(88, 116, 80, 90, 24, "url(#ft)")
	b += SvgLib.stroke_path("M 92 132 Q 70 150 66 176", INK, 22) + SvgLib.stroke_path("M 92 132 Q 70 150 66 176", "#8b84a8", 12)
	b += SvgLib.rect(46, 168, 34, 26, 4, "#ffffff", INK, 4) + SvgLib.stroke_path("M 52 178 L 74 178 M 52 186 L 66 186", INK, 3)
	b += SvgLib.circle(128, 84, 36, "url(#fk)")
	b += SvgLib.eye(116, 84, 10, -0.6, 0.4) + SvgLib.eye(144, 84, 10, -0.6, 0.4)
	b += SvgLib.path("M 104 76 L 128 76 L 128 84 L 104 84 Z", "#d2cce2", INK, 3.5) + SvgLib.path("M 132 76 L 156 76 L 156 84 L 132 84 Z", "#d2cce2", INK, 3.5)
	b += SvgLib.stroke_path("M 114 106 L 142 106", INK, 5)
	b += SvgLib.path("M 94 70 Q 128 34 164 70 Q 128 60 94 70 Z", "#3a3550")
	return SvgLib.svg(256, 256, b, defs)


static func _juros() -> String:
	var defs := SvgLib.lin("jr", "#ff6a74", "#d8323c")
	var b := ""
	b += SvgLib.ground_shadow(128, 240, 70, 9)
	b += SvgLib.rect(98, 214, 22, 24, 8, "#7a1f2a") + SvgLib.rect(150, 214, 22, 24, 8, "#7a1f2a")
	b += SvgLib.stroke_path("M 178 46 L 78 206", INK, 40) + SvgLib.stroke_path("M 178 46 L 78 206", "url(#jr)", 28)
	b += SvgLib.circle(82, 82, 44, "url(#jr)") + SvgLib.circle(82, 82, 26, "#ffffff")
	b += SvgLib.eye(80, 82, 17, -0.4, 0.2)
	b += SvgLib.stroke_path("M 46 44 L 100 62", INK, 8)
	b += SvgLib.circle(176, 168, 44, "url(#jr)") + SvgLib.ellipse(176, 170, 26, 20, "#4a0c14", INK, 4)
	for x in [158, 172, 186]:
		b += SvgLib.path("M %s 152 L %s 168 L %s 152 Z" % [SvgLib.f(x - 7), SvgLib.f(x), SvgLib.f(x + 7)], "#ffffff", INK, 3)
	b += SvgLib.shine(64, 62, 12, 7, 0.45, -35.0)
	return SvgLib.svg(256, 256, b, defs)


static func _carimbo() -> String:
	var defs := SvgLib.lin("wd", "#b8773c", "#7e4d22") + SvgLib.lin("bs", "#d88a48", "#a8602a")
	var b := ""
	b += SvgLib.ellipse(128, 226, 86, 14, "#ff3b46", "", 0, 'fill-opacity="0.85"')
	b += SvgLib.rect(56, 120, 144, 70, 14, "url(#bs)")
	b += SvgLib.rect(56, 178, 144, 22, 8, "#ff3b46", INK, 6)
	b += SvgLib.rect(112, 84, 32, 44, 10, "url(#wd)")
	b += SvgLib.rect(94, 22, 68, 70, 28, "url(#wd)")
	b += SvgLib.shine(112, 44, 8, 18, 0.35, 14.0)
	b += SvgLib.ellipse(84, 236, 24, 8, "#2b2b3d") + SvgLib.ellipse(172, 236, 24, 8, "#2b2b3d")
	b += _angry(98, 148, 158, 148, 12, 0.0)
	b += SvgLib.stroke_path("M 108 172 Q 128 160 150 172", INK, 6)
	b += SvgLib.shine(80, 132, 18, 7, 0.3, -10.0)
	return SvgLib.svg(256, 256, b, defs)


static func _senha() -> String:
	var defs := SvgLib.lin("tk", "#fffbea", "#f1e6c4")
	var b := ""
	b += SvgLib.ground_shadow(128, 242, 70, 9)
	b += SvgLib.ellipse(100, 238, 24, 8, "#2b2b3d") + SvgLib.ellipse(156, 238, 24, 8, "#2b2b3d")
	b += SvgLib.path("M 52 40 L 204 40 L 204 98 A 14 14 0 0 0 204 126 L 204 220 L 52 220 L 52 126 A 14 14 0 0 0 52 98 Z", "url(#tk)")
	b += SvgLib.rect(52, 40, 152, 26, 6, "#ff5a64", "", 0)
	b += SvgLib.rect(74, 78, 108, 44, 8, "#1a1a2b")
	for x in [88, 118, 148]:
		b += SvgLib.rect(x, 86, 22, 28, 5, "none", "#ff9a3c", 5)
	b += SvgLib.line(60, 132, 196, 132, "#c9b98a", 3)
	b += _angry(100, 168, 156, 168, 12, 0.0)
	b += SvgLib.stroke_path("M 108 194 Q 128 182 148 194", INK, 5.5)
	b += SvgLib.stroke_path("M 52 40 L 204 40 L 204 220 L 52 220 Z", INK, 7)
	return SvgLib.svg(256, 256, b, defs)


static func _leao() -> String:
	var defs := SvgLib.rad("mn", "#f0a02a", "#c9701a", 0.4, 0.35, 0.8) + SvgLib.lin("fc", "#ffd98a", "#f0b04a") + SvgLib.lin("st", "#3a4f9a", "#27346e")
	var b := ""
	b += SvgLib.ground_shadow(128, 242, 96, 10)
	b += SvgLib.rect(60, 188, 136, 56, 18, "url(#st)")
	b += SvgLib.path("M 108 180 L 128 206 L 148 180 L 160 192 L 128 222 L 96 192 Z", "#ffffff")
	b += SvgLib.path("M 118 190 L 138 190 L 146 232 L 128 244 L 110 232 Z", "#e0343c", INK, 5)
	for i in 12:
		var a := deg_to_rad(i * 30.0)
		b += SvgLib.circle(128 + sin(a) * 84, 112 - cos(a) * 80, 32, "#d9801e")
	b += SvgLib.circle(128, 112, 88, "url(#mn)")
	b += SvgLib.circle(70, 62, 22, "url(#fc)") + SvgLib.circle(186, 62, 22, "url(#fc)")
	b += SvgLib.circle(128, 118, 62, "url(#fc)")
	b += SvgLib.ellipse(128, 146, 38, 30, "#fff3cf")
	b += SvgLib.path("M 114 128 L 142 128 L 128 144 Z", "#d8587a", INK, 4)
	b += SvgLib.stroke_path("M 128 144 L 128 156 M 100 160 Q 114 172 128 156 Q 142 172 156 160", INK, 5)
	b += SvgLib.path("M 112 164 L 116 176 L 122 164 Z", "#ffffff", INK, 3) + SvgLib.path("M 134 164 L 140 176 L 144 164 Z", "#ffffff", INK, 3)
	b += _angry(100, 110, 156, 110, 13, 0.0)
	b += SvgLib.rect(26, 196, 40, 36, 4, "#ffffff", INK, 4, 'transform="rotate(-12 46 214)"')
	b += SvgLib.rect(190, 200, 40, 36, 4, "#ffffff", INK, 4, 'transform="rotate(10 210 218)"')
	b += SvgLib.stroke_path("M 34 208 L 54 204 M 198 214 L 220 218", "#e0343c", 5)
	return SvgLib.svg(320, 320, _scaled(b, 1.2, 6, 6), defs)
