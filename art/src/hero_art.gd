class_name HeroArt
extends RefCounted
## Heróis "chibi" (256×256, virados para a direita) e armas (128×128, em pé, empunhadas por baixo).
## HAND = onde a mão segura a arma, em coordenadas do sprite do herói.

const HAND := {
	"neide": Vector2(196, 118),
	"vovo": Vector2(192, 152),
	"ze": Vector2(198, 150),
	"caramelo": Vector2(200, 190),
	"isadora": Vector2(194, 140),
	"marcao": Vector2(184, 170),
	"pedrinho": Vector2(198, 128),
	"fofoca": Vector2(190, 108),
}

const WEAPON := {
	"neide": "wpn_chinelo", "vovo": "wpn_colher", "ze": "wpn_espeto", "caramelo": "",
	"isadora": "wpn_celular", "marcao": "wpn_violao", "pedrinho": "wpn_estilingue", "fofoca": "wpn_binoculo",
}

## Parâmetros de cada humano. pose: onde fica a mão da frente.
const P := {
	"neide": {
		"skin": ["#d8996a", "#b27447"], "hair": ["#3a2428", "#1f1216"], "style": "bun_curlers",
		"torso": ["#f2589a", "#c42b6d"], "deco": "dots", "apron": "#ffe9a0", "pants": "skin", "shoes": "#2f78e8",
		"brow": "angry", "mouth": "smirk", "blush": true, "sleeve": "#f2589a", "pose": Vector2(196, 118),
	},
	"vovo": {
		"skin": ["#eec4a0", "#cf9e78"], "hair": ["#f0f0f4", "#bfc3d0"], "style": "grey_bun",
		"torso": ["#a88be0", "#7b5cc0"], "deco": "cardigan", "apron": "#ffffff", "pants": "#6b5b8a", "shoes": "#3b2a55",
		"brow": "calm", "mouth": "smile", "blush": true, "sleeve": "#a88be0", "pose": Vector2(192, 152), "glasses": true,
	},
	"ze": {
		"skin": ["#e0a572", "#b97d4a"], "hair": ["#2c1d1a", "#171010"], "style": "bald",
		"torso": ["#e8473f", "#b02a28"], "deco": "apron_grill", "apron": "#fff4dc", "pants": "#3f4a6b", "shoes": "#2b2230",
		"brow": "smug", "mouth": "grin", "blush": false, "sleeve": "#e8473f", "pose": Vector2(198, 150), "mustache": true, "width": 1.28,
	},
	"isadora": {
		"skin": ["#f3cfae", "#d6a882"], "hair": ["#7b3ff0", "#ff6fb5"], "style": "long",
		"torso": ["#33d1c0", "#1a9a8f"], "deco": "star", "apron": "#ffffff", "pants": "#f3f6ff", "shoes": "#ff6fb5",
		"brow": "smug", "mouth": "smile", "blush": true, "sleeve": "#33d1c0", "pose": Vector2(194, 140), "shades": true,
	},
	"marcao": {
		"skin": ["#a06a45", "#7b4b2d"], "hair": ["#3a2418", "#21140c"], "style": "hat",
		"torso": ["#d9483f", "#a02a2a"], "deco": "plaid", "apron": "#ffffff", "pants": "#3b6fc4", "shoes": "#5a3a24",
		"brow": "happy", "mouth": "grin", "blush": false, "sleeve": "#d9483f", "pose": Vector2(184, 170), "beard": true, "width": 1.1,
	},
	"pedrinho": {
		"skin": ["#f1c9a2", "#d3a077"], "hair": ["#5b3a22", "#3a2414"], "style": "cap",
		"torso": ["#ffd23f", "#e0a91c"], "deco": "stripes", "apron": "#ffffff", "pants": "#3f64d0", "shoes": "#f2f2f2",
		"brow": "worried", "mouth": "open", "blush": true, "sleeve": "#ffd23f", "pose": Vector2(198, 128), "freckles": true, "width": 0.92,
	},
	"fofoca": {
		"skin": ["#f6dcc2", "#d9b394"], "hair": ["#ff9a3c", "#d96a14"], "style": "rollers",
		"torso": ["#f08ad0", "#c25aa6"], "deco": "robe", "apron": "#ffffff", "pants": "#c25aa6", "shoes": "#fff0fa",
		"brow": "raised", "mouth": "oh", "blush": true, "sleeve": "#f08ad0", "pose": Vector2(190, 108), "nose": true,
	},
}


static func build(out: Dictionary) -> void:
	for id in P:
		out["hero_" + id] = {"svg": _human(id), "w": 256, "h": 256}
	out["hero_caramelo"] = {"svg": _caramelo(), "w": 256, "h": 256}
	out["wpn_chinelo"] = {"svg": _chinelo(), "w": 128, "h": 128}
	out["wpn_colher"] = {"svg": _colher(), "w": 128, "h": 128}
	out["wpn_espeto"] = {"svg": _espeto(), "w": 128, "h": 128}
	out["wpn_celular"] = {"svg": _celular(), "w": 128, "h": 128}
	out["wpn_violao"] = {"svg": _violao(), "w": 128, "h": 128}
	out["wpn_estilingue"] = {"svg": _estilingue(), "w": 128, "h": 128}
	out["wpn_binoculo"] = {"svg": _binoculo(), "w": 128, "h": 128}


# ------------------------------------------------------------------ humanos

static func _human(id: String) -> String:
	var p: Dictionary = P[id]
	var sk: Array = p.skin
	var defs := SvgLib.lin("sk", sk[0], sk[1]) + SvgLib.lin("tr", p.torso[0], p.torso[1]) + SvgLib.lin("hr", p.hair[0], p.hair[1])
	var w: float = float(p.get("width", 1.0))
	var b := ""
	b += SvgLib.ground_shadow(128, 242, 66 * w, 11)
	# braço de trás
	b += SvgLib.stroke_path("M 94 156 Q 78 172 74 194", SvgLib.INK, 26)
	b += SvgLib.stroke_path("M 94 156 Q 78 172 74 194", p.sleeve, 15)
	b += SvgLib.circle(74, 196, 11, "url(#sk)")
	# pernas
	var leg_fill := "url(#sk)" if p.pants == "skin" else String(p.pants)
	b += SvgLib.rect(99, 198, 20, 34, 9, leg_fill)
	b += SvgLib.rect(137, 198, 20, 34, 9, leg_fill)
	b += SvgLib.ellipse(113, 237, 25, 9, p.shoes)
	b += SvgLib.ellipse(151, 237, 25, 9, p.shoes)
	if id == "neide":
		b += SvgLib.stroke_path("M 100 234 L 118 230 M 138 234 L 156 230", "#ffffff", 5)
	b += _torso(p, w)
	b += _hair_back(p)
	# orelhas e cabeça
	b += SvgLib.ellipse(74, 102, 11, 15, "url(#sk)")
	b += SvgLib.ellipse(182, 102, 11, 15, "url(#sk)")
	b += SvgLib.circle(128, 100, 58, "url(#sk)")
	b += _hair_front(p)
	b += _face(p)
	# braço da frente
	var h: Vector2 = p.pose
	var cx := (162.0 + h.x) * 0.5 + 10.0
	var cy := (152.0 + h.y) * 0.5 + 8.0
	var d := "M 162 154 Q %s %s %s %s" % [SvgLib.f(cx), SvgLib.f(cy), SvgLib.f(h.x - 2.0), SvgLib.f(h.y + 6.0)]
	b += SvgLib.stroke_path(d, SvgLib.INK, 28)
	b += SvgLib.stroke_path(d, p.sleeve, 17)
	b += SvgLib.circle(h.x, h.y, 13, "url(#sk)")
	return SvgLib.svg(256, 256, b, defs)


static func _torso(p: Dictionary, w: float) -> String:
	var l1 := 128.0 - 38.0 * w
	var r1 := 128.0 + 38.0 * w
	var l2 := 128.0 - 52.0 * w
	var r2 := 128.0 + 52.0 * w
	var d := "M %s 144 Q 128 130 %s 144 L %s 208 Q 128 224 %s 208 Z" % [SvgLib.f(l1), SvgLib.f(r1), SvgLib.f(r2), SvgLib.f(l2)]
	var b := SvgLib.path(d, "url(#tr)")
	match String(p.deco):
		"dots":
			for q in [[100, 170], [122, 158], [150, 162], [166, 186], [90, 194], [130, 192], [112, 208], [158, 206]]:
				b += SvgLib.circle(q[0], q[1], 5.5, "#ffffff", "", 0, 'fill-opacity="0.9"')
			b += SvgLib.path("M 104 168 Q 128 162 152 168 L 158 210 Q 128 218 98 210 Z", p.apron)
			b += SvgLib.stroke_path("M 112 182 L 144 182", "#e0a63a", 4)
		"cardigan":
			b += SvgLib.path("M 112 148 L 144 148 L 150 210 Q 128 216 106 210 Z", "#fff6ea", "")
			b += SvgLib.stroke_path("M 128 150 L 128 214", SvgLib.INK, 4)
			for y in [166, 184, 202]:
				b += SvgLib.circle(128, y, 4, "#ffffff")
		"apron_grill":
			b += SvgLib.path("M 100 152 Q 128 146 156 152 L 166 212 Q 128 224 90 212 Z", p.apron)
			b += SvgLib.rect(112, 176, 32, 22, 6, "#e8473f", SvgLib.INK, 4)
			b += SvgLib.stroke_path("M 118 184 L 138 184 M 118 190 L 138 190", "#fff4dc", 3.5)
		"star":
			b += SvgLib.path("M 128 160 L 134 174 L 149 175 L 138 185 L 141 199 L 128 191 L 115 199 L 118 185 L 107 175 L 122 174 Z", "#ffffff", SvgLib.INK, 4)
		"plaid":
			for x in [100, 116, 132, 148, 164]:
				b += SvgLib.line(x, 150, x - 4, 206, "#2b1b2f", 4)
			for y in [162, 180, 198]:
				b += SvgLib.line(90, y, 168, y, "#2b1b2f", 4)
		"stripes":
			for y in [160, 176, 192]:
				b += SvgLib.line(98, y, 158, y, "#3f64d0", 8)
		"robe":
			b += SvgLib.path("M 112 146 L 144 146 L 140 210 L 116 210 Z", "#fff0fa", "")
			for x in [98, 112, 126, 140, 154, 168]:
				b += SvgLib.circle(x - 4, 210, 9, "#ffffff", SvgLib.INK, 4)
			b += SvgLib.stroke_path("M 112 146 L 128 176 L 144 146", "#ffffff", 9)
	return b


static func _hair_back(p: Dictionary) -> String:
	match String(p.style):
		"bun_curlers":
			return SvgLib.ellipse(128, 82, 62, 54, "url(#hr)") + SvgLib.circle(128, 34, 25, "url(#hr)") + SvgLib.rect(104, 52, 48, 12, 6, "#ff5fa2")
		"grey_bun":
			return SvgLib.ellipse(128, 84, 60, 52, "url(#hr)") + SvgLib.circle(128, 36, 23, "url(#hr)") + SvgLib.rect(108, 54, 40, 10, 5, "#a88be0")
		"long":
			return SvgLib.path("M 66 90 Q 56 150 70 196 Q 100 188 112 160 L 144 160 Q 156 188 186 196 Q 200 150 190 90 Z", "url(#hr)")
		"hat":
			return SvgLib.ellipse(128, 92, 60, 54, "url(#hr)")
		"rollers":
			return SvgLib.ellipse(128, 76, 66, 56, "url(#hr)")
	return ""


static func _hair_front(p: Dictionary) -> String:
	var b := ""
	match String(p.style):
		"bun_curlers":
			b += SvgLib.path("M 70 90 Q 72 44 128 42 Q 184 44 188 90 Q 168 66 128 68 Q 90 66 70 90 Z", "url(#hr)")
			b += SvgLib.rect(84, 56, 20, 11, 5, "#ff8fb8", SvgLib.INK, 4.5, 'transform="rotate(-24 94 61)"')
			b += SvgLib.rect(152, 56, 20, 11, 5, "#ff8fb8", SvgLib.INK, 4.5, 'transform="rotate(24 162 61)"')
		"grey_bun":
			b += SvgLib.path("M 70 92 Q 70 46 128 44 Q 186 46 188 92 Q 170 70 150 72 Q 128 60 106 72 Q 86 70 70 92 Z", "url(#hr)")
		"bald":
			b += SvgLib.ellipse(72, 96, 9, 20, "url(#hr)") + SvgLib.ellipse(184, 96, 9, 20, "url(#hr)")
			b += SvgLib.shine(112, 58, 20, 8, 0.55, -20.0)
		"long":
			b += SvgLib.path("M 70 92 Q 72 42 128 40 Q 184 42 188 92 Q 176 72 150 66 Q 126 80 96 70 Q 80 76 70 92 Z", "url(#hr)")
			if p.get("shades", false):
				b += SvgLib.rect(92, 46, 28, 14, 7, "#2b1b2f", SvgLib.INK, 4) + SvgLib.rect(136, 46, 28, 14, 7, "#2b1b2f", SvgLib.INK, 4)
				b += SvgLib.line(120, 52, 136, 52, SvgLib.INK, 4)
		"hat":
			b += SvgLib.path("M 70 96 Q 72 72 90 66 L 90 90 Z", "url(#hr)", "")
			b += SvgLib.ellipse(128, 66, 82, 17, "#e8c27a")
			b += SvgLib.path("M 92 64 Q 92 14 128 12 Q 164 14 164 64 Z", "#f3d690")
			b += SvgLib.rect(92, 46, 72, 12, 4, "#b2453a", SvgLib.INK, 4)
			b += SvgLib.shine(112, 28, 12, 6, 0.4, -20.0)
		"cap":
			b += SvgLib.path("M 70 92 Q 76 40 128 38 Q 182 40 188 92 Q 176 76 128 74 Q 82 76 70 92 Z", "#e8473f")
			b += SvgLib.path("M 74 80 Q 40 82 36 98 Q 64 98 78 90 Z", "#c42f2f")
			b += SvgLib.circle(128, 38, 6, "#ffffff", SvgLib.INK, 4)
			b += SvgLib.path("M 96 66 Q 100 92 90 98 L 106 94 Z", "url(#hr)", "")
		"rollers":
			b += SvgLib.path("M 70 92 Q 72 48 128 46 Q 184 48 188 92 Q 170 72 128 74 Q 88 72 70 92 Z", "url(#hr)")
			var cols := ["#7fd7ff", "#ff8fb8", "#7fd7ff", "#ff8fb8", "#7fd7ff"]
			for i in 5:
				var x := 82.0 + i * 23.0
				b += SvgLib.rect(x - 9, 38 + absf(i - 2) * 4.0, 18, 22, 9, cols[i], SvgLib.INK, 4.5)
	return b


static func _face(p: Dictionary) -> String:
	var b := ""
	var ex := 0.7
	# olhos
	b += SvgLib.eye(108, 104, 9.5, ex, 0.0)
	b += SvgLib.eye(150, 104, 9.5, ex, 0.0)
	if p.get("glasses", false):
		b += SvgLib.circle(108, 104, 17, "none", SvgLib.INK, 4.5)
		b += SvgLib.circle(150, 104, 17, "none", SvgLib.INK, 4.5)
		b += SvgLib.line(125, 102, 133, 102, SvgLib.INK, 4)
		b += SvgLib.shine(101, 96, 6, 3, 0.55, -30.0)
	# sobrancelhas
	match String(p.brow):
		"angry":
			b += SvgLib.stroke_path("M 92 84 L 120 93", SvgLib.INK, 6.5) + SvgLib.stroke_path("M 138 93 L 168 82", SvgLib.INK, 6.5)
		"smug":
			b += SvgLib.stroke_path("M 92 88 L 120 90", SvgLib.INK, 6.5) + SvgLib.stroke_path("M 138 86 L 166 78", SvgLib.INK, 6.5)
		"calm":
			b += SvgLib.stroke_path("M 94 86 Q 106 80 120 86", SvgLib.INK, 5) + SvgLib.stroke_path("M 138 86 Q 152 80 166 86", SvgLib.INK, 5)
		"happy":
			b += SvgLib.stroke_path("M 94 86 Q 108 76 122 86", SvgLib.INK, 6) + SvgLib.stroke_path("M 136 86 Q 150 76 164 86", SvgLib.INK, 6)
		"worried":
			b += SvgLib.stroke_path("M 94 90 L 120 82", SvgLib.INK, 5.5) + SvgLib.stroke_path("M 138 82 L 164 90", SvgLib.INK, 5.5)
		"raised":
			b += SvgLib.stroke_path("M 94 82 Q 108 70 122 80", SvgLib.INK, 5.5) + SvgLib.stroke_path("M 136 78 Q 150 66 166 76", SvgLib.INK, 5.5)
	if p.get("blush", false):
		b += SvgLib.circle(94, 124, 9, "#ff7a8a", "", 0, 'fill-opacity="0.45"')
		b += SvgLib.circle(164, 124, 9, "#ff7a8a", "", 0, 'fill-opacity="0.45"')
	if p.get("freckles", false):
		for q in [[100, 120], [108, 124], [96, 128], [158, 120], [150, 124], [162, 128]]:
			b += SvgLib.circle(q[0], q[1], 2.2, "#a06a45", "", 0)
	if p.get("nose", false):
		b += SvgLib.path("M 126 108 L 138 124 L 124 124 Z", "url(#sk)", SvgLib.INK, 4.5)
	# boca
	match String(p.mouth):
		"smirk":
			b += SvgLib.stroke_path("M 114 130 Q 132 142 152 126", SvgLib.INK, 5.5)
		"smile":
			b += SvgLib.stroke_path("M 112 128 Q 130 146 150 128", SvgLib.INK, 5.5)
		"grin":
			b += SvgLib.path("M 108 126 Q 130 152 154 126 Z", "#ffffff", SvgLib.INK, 5)
			b += SvgLib.stroke_path("M 112 134 L 150 134", SvgLib.INK, 3)
		"open":
			b += SvgLib.ellipse(130, 134, 12, 10, "#7a2434", SvgLib.INK, 5) + SvgLib.ellipse(130, 138, 7, 4, "#ff7a8a", "", 0)
		"oh":
			b += SvgLib.ellipse(130, 134, 8, 11, "#7a2434", SvgLib.INK, 5)
	if p.get("mustache", false):
		b += SvgLib.path("M 100 124 Q 112 112 130 120 Q 148 112 160 124 Q 146 132 130 126 Q 114 132 100 124 Z", "#171010", SvgLib.INK, 3)
	if p.get("beard", false):
		b += SvgLib.path("M 78 120 Q 80 164 128 166 Q 176 164 180 120 Q 170 140 128 142 Q 90 140 78 120 Z", "url(#hr)", SvgLib.INK, 5)
		b += SvgLib.stroke_path("M 112 132 Q 130 146 150 130", "#ffffff", 5)
	b += SvgLib.shine(106, 70, 22, 8, 0.2, -15.0)
	return b


# ------------------------------------------------------------------ Caramelo (vira-lata)

static func _caramelo() -> String:
	var defs := SvgLib.lin("cb", "#efb35c", "#c47b2c") + SvgLib.lin("cl", "#f8dcaa", "#e9bd78") + SvgLib.lin("ce", "#9a5a22", "#6e3d14")
	var b := ""
	b += SvgLib.ground_shadow(128, 240, 78, 11)
	b += SvgLib.stroke_path("M 62 176 Q 32 160 42 124", SvgLib.INK, 24)
	b += SvgLib.stroke_path("M 62 176 Q 32 160 42 124", "#d9922f", 13)
	b += SvgLib.rect(78, 196, 22, 34, 10, "url(#cb)")
	b += SvgLib.rect(106, 200, 22, 32, 10, "url(#cb)")
	b += SvgLib.ellipse(118, 180, 64, 46, "url(#cb)")
	b += SvgLib.ellipse(138, 202, 32, 20, "url(#cl)", "", 0)
	b += SvgLib.rect(146, 196, 22, 36, 10, "url(#cb)")
	b += SvgLib.rect(172, 196, 22, 36, 10, "url(#cb)")
	# cabeça
	b += SvgLib.circle(178, 128, 50, "url(#cb)")
	b += SvgLib.ellipse(214, 146, 28, 22, "url(#cl)")
	b += SvgLib.ellipse(234, 138, 9, 7, "#2b1b2f", "", 0)
	b += SvgLib.path("M 200 160 Q 218 176 238 158", "#ffffff", SvgLib.INK, 5)
	b += SvgLib.path("M 214 164 Q 222 184 232 166 Z", "#ff7a9a", SvgLib.INK, 4)
	# orelhas caídas
	b += SvgLib.path("M 142 96 Q 118 110 126 150 Q 148 146 156 112 Z", "url(#ce)")
	b += SvgLib.path("M 196 84 Q 214 72 226 88 Q 224 110 204 108 Z", "url(#ce)")
	# olhos
	b += SvgLib.eye(168, 118, 10, 0.5, 0.0)
	b += SvgLib.eye(198, 112, 9, 0.5, 0.0)
	b += SvgLib.stroke_path("M 156 100 L 178 106", SvgLib.INK, 5.5) + SvgLib.stroke_path("M 190 100 L 208 98", SvgLib.INK, 5.5)
	# coleira
	b += SvgLib.path("M 146 158 Q 166 176 190 168 L 186 154 Q 166 164 150 146 Z", "#e8473f", SvgLib.INK, 5)
	b += SvgLib.circle(170, 176, 7, "#ffd23f")
	b += SvgLib.shine(160, 92, 20, 7, 0.3, -20.0)
	return SvgLib.svg(256, 256, b, defs)


# ------------------------------------------------------------------ armas (128×128, empunhadas pela base)

static func _chinelo() -> String:
	var defs := SvgLib.lin("so", "#4c93ff", "#2563d4") + SvgLib.lin("bo", "#ffffff", "#d3e0f5")
	var b := ""
	b += SvgLib.path("M 64 4 C 100 4 110 36 104 72 C 100 102 88 122 64 122 C 40 122 28 102 24 72 C 18 36 28 4 64 4 Z", "url(#bo)")
	b += SvgLib.path("M 64 12 C 94 12 101 38 96 70 C 93 96 83 114 64 114 C 45 114 35 96 32 70 C 27 38 34 12 64 12 Z", "url(#so)", "", 0)
	b += SvgLib.stroke_path("M 64 22 L 64 50 M 64 50 L 42 82 M 64 50 L 86 82", SvgLib.INK, 15)
	b += SvgLib.stroke_path("M 64 22 L 64 50 M 64 50 L 42 82 M 64 50 L 86 82", "#ffffff", 8)
	b += SvgLib.circle(64, 50, 7, "#ffd23f")
	b += SvgLib.shine(48, 36, 8, 16, 0.4, 12.0)
	return SvgLib.svg(128, 128, b, defs)


static func _colher() -> String:
	var defs := SvgLib.lin("wd", "#e2b070", "#b87a3a")
	var b := ""
	b += SvgLib.rect(56, 52, 16, 70, 8, "url(#wd)")
	b += SvgLib.ellipse(64, 30, 26, 32, "url(#wd)")
	b += SvgLib.ellipse(64, 34, 16, 20, "#c58a4a", "", 0)
	b += SvgLib.shine(54, 20, 6, 10, 0.4, 10.0)
	return SvgLib.svg(128, 128, b, defs)


static func _espeto() -> String:
	var b := ""
	b += SvgLib.line(64, 8, 64, 118, "#c9ced8", 7)
	b += SvgLib.line(64, 8, 64, 118, SvgLib.INK, 2)
	var cols := ["#b43a2e", "#e8794a", "#8f2d26", "#e8794a"]
	for i in 4:
		b += SvgLib.rect(40, 14 + i * 20, 48, 18, 8, cols[i])
	b += SvgLib.rect(54, 96, 20, 26, 8, "#8a5a32")
	b += SvgLib.shine(52, 24, 8, 4, 0.4, 0.0)
	return SvgLib.svg(128, 128, b)


static func _celular() -> String:
	var defs := SvgLib.lin("sc", "#5be0d0", "#2b7fe0")
	var b := ""
	b += SvgLib.circle(64, 44, 38, "none", "#ffe27a", 8)
	b += SvgLib.circle(64, 44, 38, "none", SvgLib.INK, 2)
	b += SvgLib.rect(38, 16, 52, 100, 12, "#2b2b3d")
	b += SvgLib.rect(43, 24, 42, 80, 7, "url(#sc)", "", 0)
	b += SvgLib.circle(64, 112, 4, "#ffffff", "", 0)
	b += SvgLib.shine(52, 40, 6, 14, 0.4, 14.0)
	return SvgLib.svg(128, 128, b, defs)


static func _violao() -> String:
	var defs := SvgLib.lin("vw", "#e08a3c", "#a8531c")
	var b := ""
	b += SvgLib.rect(58, 2, 12, 56, 5, "#5a3a24")
	b += SvgLib.rect(56, 2, 16, 12, 4, "#3a2418")
	b += SvgLib.path("M 64 54 C 36 54 28 74 40 86 C 26 96 30 122 64 122 C 98 122 102 96 88 86 C 100 74 92 54 64 54 Z", "url(#vw)")
	b += SvgLib.circle(64, 88, 11, "#2b1b2f", SvgLib.INK, 4)
	b += SvgLib.line(64, 14, 64, 112, "#f5f0e0", 2.5)
	b += SvgLib.shine(46, 74, 6, 12, 0.35, 15.0)
	return SvgLib.svg(128, 128, b, defs)


static func _estilingue() -> String:
	var b := ""
	b += SvgLib.stroke_path("M 64 120 L 64 76 M 64 76 L 38 30 M 64 76 L 90 30", SvgLib.INK, 20)
	b += SvgLib.stroke_path("M 64 120 L 64 76 M 64 76 L 38 30 M 64 76 L 90 30", "#a8693a", 11)
	b += SvgLib.stroke_path("M 38 30 Q 64 70 90 30", "#2b1b2f", 5)
	b += SvgLib.circle(64, 56, 9, "#7fd7ff")
	b += SvgLib.shine(61, 53, 3, 3, 0.7, 0.0)
	return SvgLib.svg(128, 128, b)


static func _binoculo() -> String:
	var b := ""
	b += SvgLib.rect(26, 30, 30, 70, 12, "#3b3b4f")
	b += SvgLib.rect(72, 30, 30, 70, 12, "#3b3b4f")
	b += SvgLib.rect(52, 52, 24, 14, 5, "#2b2b3d")
	b += SvgLib.circle(41, 28, 17, "#7fd7ff", SvgLib.INK, 6)
	b += SvgLib.circle(87, 28, 17, "#7fd7ff", SvgLib.INK, 6)
	b += SvgLib.shine(35, 22, 6, 4, 0.7, -20.0) + SvgLib.shine(81, 22, 6, 4, 0.7, -20.0)
	b += SvgLib.rect(26, 74, 30, 12, 5, "#e8473f", SvgLib.INK, 4) + SvgLib.rect(72, 74, 30, 12, 5, "#e8473f", SvgLib.INK, 4)
	return SvgLib.svg(128, 128, b)
