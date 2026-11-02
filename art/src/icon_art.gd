class_name IconArt
extends RefCounted
## Ícones de interface (96×96), relíquias (96×96, fundo transparente), papéis (64×64) e sprites de efeito.

const INK := SvgLib.INK


static func build(out: Dictionary) -> void:
	var ui := {
		"ic_coin": _coin(), "ic_gem": _gem(), "ic_bless": _bless(), "ic_marmita": _marmita(), "ic_fury": _fury(),
		"ic_speed": _speed(), "ic_gear": _gear(), "ic_share": _share(), "ic_lock": _lock(), "ic_check": _check(),
		"ic_arrow_up": _arrow_up(), "ic_star": _star(), "ic_heart": _heart(), "ic_dps": _bolt(), "ic_shield": _shield(),
		"ic_clock": _clock(), "ic_gift": _gift(), "ic_trophy": _trophy(), "ic_camera": _camera(), "ic_chest": _chest(),
		"ic_pot": _pot(), "ic_book": _book(), "ic_skull": _skull(), "ic_x": _xbtn(), "ic_auto": _auto(), "ic_hand": _hand(),
		"tab_family": _tab_family(), "tab_relics": _tab_relics(), "tab_bless": _tab_bless(), "tab_goals": _trophy(), "tab_more": _tab_more(),
	}
	for k in ui:
		out[k] = {"svg": ui[k], "w": 96, "h": 96}
	out["ic_parrot"] = {"svg": _parrot(), "w": 128, "h": 128}
	for id in RelicDefs.DATA:
		out["rl_" + id] = {"svg": _relic(id), "w": 96, "h": 96}
	for r in ["tank", "melee", "ranged", "healer", "support", "debuff"]:
		out["role_" + r] = {"svg": _role(r), "w": 64, "h": 64}
	out["fx_star"] = {"svg": _fx_star(), "w": 64, "h": 64}
	out["fx_ring"] = {"svg": SvgLib.svg(128, 128, '<circle cx="64" cy="64" r="56" fill="none" stroke="#ffffff" stroke-width="10"/>'), "w": 128, "h": 128}
	out["fx_puff"] = {"svg": _fx_puff(), "w": 96, "h": 96}
	out["fx_slash"] = {"svg": _fx_slash(), "w": 128, "h": 64}


# ------------------------------------------------------------------ interface

static func _coin() -> String:
	var defs := SvgLib.rad("cg", "#ffe680", "#f0a81c", 0.35, 0.3, 0.85)
	var b := SvgLib.circle(48, 48, 40, "url(#cg)") + SvgLib.circle(48, 48, 29, "none", "#c27c0e", 5)
	b += SvgLib.path("M 48 28 L 54 42 L 69 43 L 57 53 L 61 68 L 48 60 L 35 68 L 39 53 L 27 43 L 42 42 Z", "#fff3b0", "#c27c0e", 3.5)
	b += SvgLib.shine(34, 30, 12, 6, 0.55, -35.0)
	return SvgLib.svg(96, 96, b, defs)


static func _gem() -> String:
	var defs := SvgLib.rad("pq", "#fbd98a", "#d68a26", 0.38, 0.3, 0.85)
	var b := SvgLib.ellipse(48, 76, 30, 7, "#1a0f1f", "", 0, 'fill-opacity="0.25"')
	b += SvgLib.circle(48, 50, 38, "url(#pq)")
	for p in [[34, 38, 8, 6], [60, 34, 7, 5], [64, 58, 9, 6], [30, 62, 8, 5], [48, 52, 6, 4]]:
		b += SvgLib.ellipse(p[0], p[1], p[2], p[3], "#b8701a", "", 0, 'fill-opacity="0.45"')
	for p in [[46, 28], [70, 46], [38, 70], [56, 70]]:
		b += SvgLib.circle(p[0], p[1], 2.4, "#fff3c4", "", 0)
	b += SvgLib.shine(34, 28, 14, 7, 0.55, -30.0)
	return SvgLib.svg(96, 96, b, defs)


static func _bless() -> String:
	var defs := SvgLib.lin("hg", "#d58bff", "#9a4ae0")
	var b := SvgLib.ellipse(48, 22, 24, 8, "none", "#ffd23f", 7)
	b += SvgLib.ellipse(48, 22, 24, 8, "none", INK, 2)
	b += SvgLib.path("M 48 84 C 14 60 12 34 30 32 C 40 31 46 38 48 44 C 50 38 56 31 66 32 C 84 34 82 60 48 84 Z", "url(#hg)")
	b += SvgLib.shine(34, 44, 8, 5, 0.5, -30.0)
	b += SvgLib.path("M 78 52 L 80 58 L 86 60 L 80 62 L 78 68 L 76 62 L 70 60 L 76 58 Z", "#fff3b0", "", 0)
	return SvgLib.svg(96, 96, b, defs)


static func _marmita() -> String:
	var defs := SvgLib.lin("mm", "#e9edf5", "#aab4c8")
	var b := SvgLib.ellipse(48, 86, 32, 6, "#1a0f1f", "", 0, 'fill-opacity="0.25"')
	b += SvgLib.rect(22, 58, 52, 24, 8, "url(#mm)")
	b += SvgLib.rect(24, 36, 48, 24, 8, "url(#mm)")
	b += SvgLib.rect(26, 16, 44, 22, 8, "#ff5a64")
	b += SvgLib.rect(40, 8, 16, 10, 4, "#2b2b3d")
	b += SvgLib.stroke_path("M 78 30 Q 92 48 78 70", INK, 6) + SvgLib.stroke_path("M 18 30 Q 4 48 18 70", INK, 6)
	b += SvgLib.line(26, 60, 70, 60, "#ffd23f", 5)
	b += SvgLib.shine(34, 70, 8, 3, 0.6, 0.0)
	return SvgLib.svg(96, 96, b, defs)


static func _fury() -> String:
	var defs := SvgLib.lin("f1", "#ffb21f", "#ff3b46") + SvgLib.lin("f2", "#fff3a0", "#ffb21f")
	var b := SvgLib.path("M 48 6 C 52 24 76 30 74 58 C 72 78 60 88 48 88 C 34 88 22 78 22 60 C 22 44 34 40 36 26 C 42 32 44 40 44 46 C 52 36 52 20 48 6 Z", "url(#f1)")
	b += SvgLib.path("M 48 40 C 50 52 64 56 62 70 C 61 80 55 84 48 84 C 40 84 34 78 34 68 C 34 58 44 54 48 40 Z", "url(#f2)", "", 0)
	return SvgLib.svg(96, 96, b, defs)


static func _speed() -> String:
	var b := SvgLib.circle(48, 48, 40, "#4aa8ff")
	b += SvgLib.path("M 26 30 L 50 48 L 26 66 Z", "#ffffff", INK, 5) + SvgLib.path("M 50 30 L 74 48 L 50 66 Z", "#ffffff", INK, 5)
	return SvgLib.svg(96, 96, b)


static func _gear() -> String:
	var defs := SvgLib.lin("gg", "#c9ced8", "#8c94a8")
	var b := ""
	for i in 8:
		var a := i * 45.0
		b += SvgLib.rect(40, 4, 16, 26, 4, "#9aa3b8", INK, 5, 'transform="rotate(%s 48 48)"' % SvgLib.f(a))
	b += SvgLib.circle(48, 48, 30, "url(#gg)") + SvgLib.circle(48, 48, 12, "#2b1b2f", INK, 4)
	b += SvgLib.shine(38, 34, 10, 5, 0.5, -30.0)
	return SvgLib.svg(96, 96, b, defs)


static func _share() -> String:
	var b := SvgLib.stroke_path("M 26 48 L 68 24 M 26 48 L 68 72", INK, 10)
	b += SvgLib.stroke_path("M 26 48 L 68 24 M 26 48 L 68 72", "#ffffff", 5)
	b += SvgLib.circle(24, 48, 15, "#3ddc7a") + SvgLib.circle(70, 24, 15, "#3ddc7a") + SvgLib.circle(70, 72, 15, "#3ddc7a")
	return SvgLib.svg(96, 96, b)


static func _lock() -> String:
	var b := SvgLib.stroke_path("M 28 44 L 28 30 Q 28 12 48 12 Q 68 12 68 30 L 68 44", INK, 14)
	b += SvgLib.stroke_path("M 28 44 L 28 30 Q 28 12 48 12 Q 68 12 68 30 L 68 44", "#c9ced8", 7)
	b += SvgLib.rect(20, 42, 56, 44, 12, "#ffb21f") + SvgLib.circle(48, 62, 7, INK, "", 0) + SvgLib.rect(45, 64, 6, 14, 3, INK, "", 0)
	return SvgLib.svg(96, 96, b)


static func _check() -> String:
	var b := SvgLib.circle(48, 48, 40, "#3ddc7a")
	b += SvgLib.stroke_path("M 26 50 L 42 66 L 72 32", INK, 14) + SvgLib.stroke_path("M 26 50 L 42 66 L 72 32", "#ffffff", 8)
	return SvgLib.svg(96, 96, b)


static func _arrow_up() -> String:
	var b := SvgLib.path("M 48 8 L 82 46 L 62 46 L 62 86 L 34 86 L 34 46 L 14 46 Z", "#3ddc7a")
	b += SvgLib.shine(38, 30, 6, 12, 0.5, 20.0)
	return SvgLib.svg(96, 96, b)


static func _star() -> String:
	var b := SvgLib.path("M 48 8 L 59 34 L 88 36 L 66 55 L 73 84 L 48 69 L 23 84 L 30 55 L 8 36 L 37 34 Z", "#ffd23f")
	b += SvgLib.shine(38, 34, 7, 5, 0.6, -30.0)
	return SvgLib.svg(96, 96, b)


static func _heart() -> String:
	var b := SvgLib.path("M 48 84 C 8 58 10 22 32 20 C 42 19 47 26 48 32 C 49 26 54 19 64 20 C 86 22 88 58 48 84 Z", "#ff5a64")
	b += SvgLib.shine(32, 34, 7, 5, 0.55, -30.0)
	return SvgLib.svg(96, 96, b)


static func _bolt() -> String:
	var b := SvgLib.path("M 56 6 L 20 54 L 44 54 L 36 90 L 78 38 L 52 38 Z", "#ffd23f")
	return SvgLib.svg(96, 96, b)


static func _shield() -> String:
	var b := SvgLib.path("M 48 8 L 82 20 L 80 52 Q 76 76 48 90 Q 20 76 16 52 L 14 20 Z", "#4aa8ff")
	b += SvgLib.path("M 48 20 L 70 28 L 68 52 Q 64 68 48 78 Z", "#8cc8ff", "", 0)
	return SvgLib.svg(96, 96, b)


static func _clock() -> String:
	var b := SvgLib.circle(48, 48, 40, "#ffffff") + SvgLib.stroke_path("M 48 24 L 48 48 L 66 58", INK, 8)
	return SvgLib.svg(96, 96, b)


static func _gift() -> String:
	var b := SvgLib.rect(14, 38, 68, 48, 8, "#ff5a64") + SvgLib.rect(10, 28, 76, 18, 6, "#ff7a84")
	b += SvgLib.rect(42, 28, 12, 58, 0, "#ffd23f", "", 0)
	b += SvgLib.path("M 48 28 C 30 6 14 20 30 28 Z M 48 28 C 66 6 82 20 66 28 Z", "#ffd23f")
	return SvgLib.svg(96, 96, b)


static func _trophy() -> String:
	var defs := SvgLib.lin("tg", "#ffe680", "#f0a81c")
	var b := SvgLib.stroke_path("M 22 24 Q 6 24 10 40 Q 14 52 30 54", INK, 12) + SvgLib.stroke_path("M 74 24 Q 90 24 86 40 Q 82 52 66 54", INK, 12)
	b += SvgLib.path("M 24 10 L 72 10 L 70 42 Q 66 62 48 64 Q 30 62 26 42 Z", "url(#tg)")
	b += SvgLib.rect(42, 62, 12, 14, 2, "#e8a31c") + SvgLib.rect(28, 76, 40, 12, 5, "#8a5a32")
	b += SvgLib.shine(36, 26, 6, 12, 0.5, 12.0)
	return SvgLib.svg(96, 96, b, defs)


static func _camera() -> String:
	var b := SvgLib.rect(8, 28, 80, 54, 12, "#2b2b3d") + SvgLib.rect(30, 18, 30, 14, 5, "#2b2b3d")
	b += SvgLib.circle(48, 56, 20, "#9aa0b4") + SvgLib.circle(48, 56, 12, "#4aa8ff", INK, 4) + SvgLib.circle(74, 40, 4, "#ff5a64", "", 0)
	return SvgLib.svg(96, 96, b)


static func _chest() -> String:
	var defs := SvgLib.lin("ch", "#c9843c", "#8a5226")
	var b := SvgLib.rect(8, 42, 80, 44, 8, "url(#ch)") + SvgLib.path("M 8 44 Q 8 14 48 14 Q 88 14 88 44 Z", "#d8944a")
	b += SvgLib.rect(8, 40, 80, 10, 3, "#ffd23f", INK, 5) + SvgLib.rect(40, 36, 16, 22, 5, "#ffd23f") + SvgLib.circle(48, 48, 3.5, INK, "", 0)
	return SvgLib.svg(96, 96, b, defs)


static func _pot() -> String:
	var defs := SvgLib.lin("pt", "#b9c2d6", "#7c86a0")
	var b := SvgLib.stroke_path("M 36 22 Q 30 10 38 2 M 52 22 Q 46 10 54 2 M 68 22 Q 62 10 70 2", "#ffffff", 5, 'stroke-opacity="0.7"')
	b += SvgLib.rect(12, 34, 72, 46, 14, "url(#pt)") + SvgLib.rect(8, 30, 80, 12, 6, "#9aa3b8")
	b += SvgLib.rect(2, 46, 12, 8, 4, "#2b2b3d") + SvgLib.rect(82, 46, 12, 8, 4, "#2b2b3d")
	b += SvgLib.rect(40, 24, 16, 8, 4, "#2b2b3d") + SvgLib.shine(28, 58, 6, 10, 0.4, 0.0)
	return SvgLib.svg(96, 96, b, defs)


static func _book() -> String:
	var b := SvgLib.rect(14, 10, 68, 78, 8, "#7a4bd0") + SvgLib.rect(22, 10, 60, 78, 6, "#a56bff")
	b += SvgLib.rect(34, 24, 36, 30, 6, "#fff3b0", INK, 4)
	b += SvgLib.line(32, 66, 70, 66, "#ffffff", 5) + SvgLib.line(32, 76, 58, 76, "#ffffff", 5)
	return SvgLib.svg(96, 96, b)


static func _skull() -> String:
	var b := SvgLib.path("M 48 8 C 22 8 12 28 16 46 C 18 54 24 58 28 60 L 28 76 L 68 76 L 68 60 C 72 58 78 54 80 46 C 84 28 74 8 48 8 Z", "#ffffff")
	b += SvgLib.ellipse(34, 42, 10, 12, INK, "", 0) + SvgLib.ellipse(62, 42, 10, 12, INK, "", 0)
	b += SvgLib.path("M 48 52 L 42 64 L 54 64 Z", INK, "", 0) + SvgLib.stroke_path("M 38 76 L 38 66 M 48 76 L 48 66 M 58 76 L 58 66", INK, 4)
	return SvgLib.svg(96, 96, b)


static func _xbtn() -> String:
	var b := SvgLib.circle(48, 48, 40, "#ff5a64")
	b += SvgLib.stroke_path("M 30 30 L 66 66 M 66 30 L 30 66", INK, 14) + SvgLib.stroke_path("M 30 30 L 66 66 M 66 30 L 30 66", "#ffffff", 8)
	return SvgLib.svg(96, 96, b)


static func _auto() -> String:
	var b := SvgLib.stroke_path("M 74 32 A 28 28 0 1 0 76 60", INK, 14) + SvgLib.stroke_path("M 74 32 A 28 28 0 1 0 76 60", "#ffffff", 8)
	b += SvgLib.path("M 82 16 L 84 42 L 58 38 Z", "#ffffff", INK, 5)
	return SvgLib.svg(96, 96, b)


static func _hand() -> String:
	var b := SvgLib.path("M 38 10 Q 46 6 50 16 L 52 44 L 60 40 Q 70 38 72 48 L 74 70 Q 72 90 54 90 L 40 90 Q 24 86 22 68 L 18 50 Q 18 42 26 42 L 32 52 L 32 16 Q 32 10 38 10 Z", "#ffffff")
	return SvgLib.svg(96, 96, b)


static func _tab_family() -> String:
	var defs := SvgLib.lin("sk", "#d8996a", "#b27447") + SvgLib.lin("sk2", "#f3cfae", "#d6a882")
	var b := SvgLib.ellipse(34, 86, 26, 5, "#1a0f1f", "", 0, 'fill-opacity="0.25"')
	b += SvgLib.rect(14, 56, 40, 30, 14, "#f2589a") + SvgLib.circle(34, 38, 22, "url(#sk)")
	b += SvgLib.path("M 12 38 Q 14 14 34 14 Q 54 14 56 38 Q 44 26 34 26 Q 22 26 12 38 Z", "#2a1b1f")
	b += SvgLib.circle(34, 8, 8, "#2a1b1f")
	b += SvgLib.rect(52, 64, 28, 22, 10, "#ffd23f") + SvgLib.circle(66, 52, 15, "url(#sk2)")
	b += SvgLib.path("M 52 50 Q 54 34 66 34 Q 78 34 80 50 Q 72 42 66 42 Q 58 42 52 50 Z", "#5b3a22")
	return SvgLib.svg(96, 96, b, defs)


static func _tab_relics() -> String:
	var defs := SvgLib.lin("rg", "#d58bff", "#7a3fd0")
	var b := SvgLib.stroke_path("M 28 8 Q 48 38 68 8", INK, 8) + SvgLib.stroke_path("M 28 8 Q 48 38 68 8", "#ffd23f", 4)
	b += SvgLib.path("M 48 34 L 74 56 L 64 86 L 32 86 L 22 56 Z", "url(#rg)") + SvgLib.path("M 48 34 L 62 56 L 48 86 L 34 56 Z", "#b27aff", "", 0)
	b += SvgLib.shine(36, 54, 5, 10, 0.5, 20.0)
	return SvgLib.svg(96, 96, b, defs)


static func _tab_bless() -> String:
	var b := SvgLib.rect(36, 42, 24, 46, 6, "#fff3d6") + SvgLib.path("M 48 8 C 56 20 62 26 56 38 C 54 44 42 44 40 38 C 34 26 44 20 48 8 Z", "#ffb21f")
	b += SvgLib.path("M 48 22 C 52 28 54 32 50 38 C 48 40 46 40 46 38 C 44 32 46 28 48 22 Z", "#fff3a0", "", 0)
	b += SvgLib.ellipse(48, 88, 26, 5, "#ffd23f", INK, 4)
	return SvgLib.svg(96, 96, b)


static func _tab_more() -> String:
	var b := SvgLib.circle(48, 48, 40, "#6b6280", INK, 6)
	for x in [26, 48, 70]:
		b += SvgLib.circle(x, 48, 8, "#ffffff", INK, 4)
	return SvgLib.svg(96, 96, b)


static func _parrot() -> String:
	var defs := SvgLib.lin("pg", "#ffe680", "#f0a81c")
	var b := SvgLib.path("M 96 70 L 124 96 L 120 70 L 126 52 Z", "#ff5a64")
	b += SvgLib.path("M 84 46 Q 112 30 120 60 Q 108 54 84 62 Z", "#4aa8ff", INK, 5)
	b += SvgLib.ellipse(64, 72, 34, 30, "url(#pg)")
	b += SvgLib.path("M 50 66 Q 76 40 98 64 Q 80 84 50 66 Z", "#ff8a1c", INK, 5)
	b += SvgLib.circle(40, 46, 22, "url(#pg)")
	b += SvgLib.path("M 20 44 Q 8 50 14 62 Q 28 58 26 48 Z", "#ffffff", INK, 5)
	b += SvgLib.eye(40, 42, 8, -0.5, 0.0)
	b += SvgLib.path("M 30 22 L 36 10 L 42 22 Z", "#ff5a64", INK, 4)
	b += SvgLib.stroke_path("M 56 100 L 56 114 M 74 100 L 74 114", "#ff8a1c", 6)
	return SvgLib.svg(128, 128, b, defs)


# ------------------------------------------------------------------ papéis (64×64)

static func _role(r: String) -> String:
	var cols := {"tank": "#4aa8ff", "melee": "#ff5a64", "ranged": "#3ddc7a", "healer": "#ff6fa8", "support": "#ffb21f", "debuff": "#a66bff"}
	var col: String = cols[r]
	var b := SvgLib.circle(32, 32, 28, col)
	match r:
		"tank":
			b += SvgLib.path("M 32 14 L 48 20 L 46 36 Q 44 46 32 52 Q 20 46 18 36 L 16 20 Z", "#ffffff", INK, 4)
		"melee":
			b += SvgLib.stroke_path("M 20 44 L 44 20", INK, 9) + SvgLib.stroke_path("M 20 44 L 44 20", "#ffffff", 4) + SvgLib.stroke_path("M 20 20 L 44 44", INK, 9) + SvgLib.stroke_path("M 20 20 L 44 44", "#ffffff", 4)
		"ranged":
			b += SvgLib.circle(32, 32, 16, "none", "#ffffff", 5) + SvgLib.circle(32, 32, 5, "#ffffff", "", 0)
		"healer":
			b += SvgLib.rect(26, 14, 12, 36, 3, "#ffffff", INK, 3) + SvgLib.rect(14, 26, 36, 12, 3, "#ffffff", INK, 3)
		"support":
			b += SvgLib.path("M 22 46 L 22 20 L 44 14 L 44 40", "none", INK, 7) + SvgLib.path("M 22 46 L 22 20 L 44 14 L 44 40", "none", "#ffffff", 3.5) + SvgLib.circle(18, 46, 6, "#ffffff", INK, 3) + SvgLib.circle(40, 40, 6, "#ffffff", INK, 3)
		"debuff":
			b += SvgLib.stroke_path("M 20 24 Q 32 12 44 24 Q 36 34 32 40 Q 28 46 20 44", INK, 8) + SvgLib.stroke_path("M 20 24 Q 32 12 44 24 Q 36 34 32 40 Q 28 46 20 44", "#ffffff", 4)
	return SvgLib.svg(64, 64, b)


# ------------------------------------------------------------------ efeitos

static func _fx_star() -> String:
	return SvgLib.svg(64, 64, '<path d="M 32 2 L 39 25 L 62 32 L 39 39 L 32 62 L 25 39 L 2 32 L 25 25 Z" fill="#ffffff"/>')


static func _fx_puff() -> String:
	var b := '<circle cx="34" cy="52" r="24" fill="#ffffff"/><circle cx="62" cy="50" r="26" fill="#ffffff"/><circle cx="48" cy="34" r="26" fill="#ffffff"/>'
	return SvgLib.svg(96, 96, b)


static func _fx_slash() -> String:
	return SvgLib.svg(128, 64, '<path d="M 4 56 Q 60 52 124 6 Q 70 36 4 56 Z" fill="#ffffff"/>')


# ------------------------------------------------------------------ relíquias (96×96)

## Chinelo (mesmo contorno da arma, em 128×128) para reaproveitar nas relíquias.
static func _slipper(sole: String, top: String, strap: String) -> String:
	var b := SvgLib.path("M 64 4 C 100 4 110 36 104 72 C 100 102 88 122 64 122 C 40 122 28 102 24 72 C 18 36 28 4 64 4 Z", sole)
	b += SvgLib.path("M 64 12 C 94 12 101 38 96 70 C 93 96 83 114 64 114 C 45 114 35 96 32 70 C 27 38 34 12 64 12 Z", top, "", 0)
	b += SvgLib.stroke_path("M 64 22 L 64 50 M 64 50 L 42 82 M 64 50 L 86 82", SvgLib.INK, 15)
	b += SvgLib.stroke_path("M 64 22 L 64 50 M 64 50 L 42 82 M 64 50 L 86 82", strap, 8)
	return b


static func _relic(id: String) -> String:
	var defs := ""
	var b := ""
	match id:
		"chinelo_sorte":
			defs = SvgLib.lin("so", "#4c93ff", "#2563d4") + SvgLib.lin("bo", "#ffffff", "#d3e0f5")
			b += SvgLib.group(_slipper("url(#bo)", "url(#so)", "#ffffff"), "translate(6 10) rotate(-18 40 40) scale(0.72)")
			b += SvgLib.circle(74, 22, 8, "#3ddc7a", INK, 3) + SvgLib.circle(84, 32, 8, "#3ddc7a", INK, 3) + SvgLib.circle(74, 42, 8, "#3ddc7a", INK, 3) + SvgLib.circle(64, 32, 8, "#3ddc7a", INK, 3)
		"panela_pressao":
			defs = SvgLib.lin("pt", "#c9d0e0", "#8791aa")
			b += SvgLib.stroke_path("M 36 22 Q 30 10 38 2 M 54 22 Q 48 10 56 2", "#ffffff", 5, 'stroke-opacity="0.8"')
			b += SvgLib.rect(14, 44, 68, 40, 12, "url(#pt)") + SvgLib.rect(10, 34, 76, 16, 8, "#aab3c8") + SvgLib.rect(2, 52, 12, 8, 4, "#2b2b3d") + SvgLib.rect(82, 52, 12, 8, 4, "#2b2b3d")
			b += SvgLib.rect(42, 24, 12, 12, 4, "#e8473f")
		"cofrinho":
			defs = SvgLib.lin("pg", "#ffa0c4", "#ff6fa8")
			b += SvgLib.ellipse(48, 56, 36, 28, "url(#pg)") + SvgLib.path("M 26 36 L 28 20 L 42 32 Z", "#ff6fa8") + SvgLib.path("M 62 32 L 70 18 L 76 36 Z", "#ff6fa8")
			b += SvgLib.ellipse(80, 58, 11, 10, "#ff8ab8") + SvgLib.circle(78, 58, 2.5, INK, "", 0) + SvgLib.circle(84, 58, 2.5, INK, "", 0)
			b += SvgLib.circle(66, 48, 4.5, INK, "", 0) + SvgLib.rect(36, 30, 20, 5, 2, INK, "", 0)
			b += SvgLib.rect(26, 78, 12, 12, 4, "#ff6fa8") + SvgLib.rect(58, 78, 12, 12, 4, "#ff6fa8") + SvgLib.stroke_path("M 14 54 Q 6 44 12 38", INK, 5)
		"terco_vovo":
			for i in 14:
				var a := deg_to_rad(i * 360.0 / 14.0)
				b += SvgLib.circle(48 + sin(a) * 28, 40 - cos(a) * 28, 6, "#a56bff", INK, 3)
			b += SvgLib.line(48, 68, 48, 84, INK, 7) + SvgLib.rect(42, 70, 12, 22, 3, "#ffd23f", INK, 4) + SvgLib.rect(36, 76, 24, 10, 3, "#ffd23f", INK, 4)
		"ventilador":
			b += SvgLib.circle(48, 48, 38, "#e9edf5", INK, 5)
			for i in 4:
				b += SvgLib.ellipse(48, 28, 11, 20, "#4aa8ff", INK, 4, 'transform="rotate(%s 48 48)"' % SvgLib.f(i * 90.0 + 20.0))
			b += SvgLib.circle(48, 48, 9, "#ffd23f", INK, 4)
		"garrafa_termica":
			defs = SvgLib.lin("rb", "#ff6a74", "#d8323c")
			b += SvgLib.rect(30, 22, 36, 66, 12, "url(#rb)") + SvgLib.rect(34, 8, 28, 18, 6, "#c9ced8") + SvgLib.stroke_path("M 68 36 Q 86 40 80 64 Q 76 72 66 72", INK, 8)
			b += SvgLib.rect(30, 44, 36, 8, 0, "#ffffff", "", 0) + SvgLib.shine(40, 50, 4, 20, 0.45, 0.0)
		"controle_remoto":
			b += SvgLib.rect(28, 6, 40, 84, 14, "#2b2b3d")
			b += SvgLib.circle(48, 22, 8, "#ff3b46", INK, 3) + SvgLib.circle(38, 42, 6, "#3ddc7a", INK, 3) + SvgLib.circle(58, 42, 6, "#4aa8ff", INK, 3)
			for y in [58, 70, 82]:
				b += SvgLib.rect(36, y - 4, 24, 8, 4, "#9aa0b4", "", 0)
		"novela":
			b += SvgLib.stroke_path("M 36 22 L 24 6 M 60 22 L 72 6", INK, 5) + SvgLib.rect(10, 22, 76, 56, 12, "#8a5a32") + SvgLib.rect(18, 30, 60, 40, 8, "#7fd7ff", INK, 4)
			b += SvgLib.path("M 48 62 C 28 50 30 38 40 38 C 44 38 47 41 48 44 C 49 41 52 38 56 38 C 66 38 68 50 48 62 Z", "#ff5a64", INK, 3)
			b += SvgLib.rect(20, 82, 12, 8, 3, INK, "", 0) + SvgLib.rect(64, 82, 12, 8, 3, INK, "", 0)
		"guarda_chuva":
			b += SvgLib.stroke_path("M 48 44 L 48 80 Q 48 90 58 90 Q 68 90 68 80", INK, 9) + SvgLib.stroke_path("M 48 44 L 48 80 Q 48 90 58 90 Q 68 90 68 80", "#8a5a32", 4.5)
			b += SvgLib.path("M 6 50 Q 8 10 48 8 Q 88 10 90 50 Q 80 42 70 50 Q 60 42 48 50 Q 36 42 26 50 Q 16 42 6 50 Z", "#ff5a64")
			b += SvgLib.path("M 48 8 Q 36 26 36 48 Q 42 42 48 50 Z", "#ffffff", "", 0) + SvgLib.path("M 48 8 Q 60 26 60 48 Q 54 42 48 50 Z", "#ffffff", "", 0)
		"panelao":
			defs = SvgLib.lin("pb", "#7b5a42", "#4a3424")
			b += SvgLib.stroke_path("M 34 18 Q 28 8 36 0 M 52 18 Q 46 8 54 0 M 70 18 Q 64 8 72 0", "#ffffff", 5, 'stroke-opacity="0.8"')
			b += SvgLib.rect(8, 44, 80, 44, 16, "#2b2b3d") + SvgLib.ellipse(48, 44, 40, 12, "url(#pb)", INK, 5)
			for p in [[30, 44], [46, 41], [62, 45], [38, 48], [56, 50]]:
				b += SvgLib.ellipse(p[0], p[1], 5, 3.5, "#c9843c", "", 0)
			b += SvgLib.rect(0, 56, 12, 8, 4, "#9aa3b8") + SvgLib.rect(84, 56, 12, 8, 4, "#9aa3b8")
		"caderninho":
			b += SvgLib.rect(18, 8, 56, 80, 8, "#4aa8ff") + SvgLib.rect(26, 8, 48, 80, 6, "#7fc0ff")
			b += SvgLib.rect(36, 22, 28, 20, 4, "#ffffff", INK, 3)
			for y in [52, 62, 72]:
				b += SvgLib.line(34, y, 66, y, "#ffffff", 4)
			for y in [18, 34, 50, 66, 80]:
				b += SvgLib.circle(22, y, 4, INK, "", 0)
			b += SvgLib.stroke_path("M 78 70 L 90 28", INK, 9) + SvgLib.stroke_path("M 78 70 L 90 28", "#ffd23f", 4.5) + SvgLib.path("M 76 72 L 80 82 L 84 72 Z", "#f1c9a2", INK, 3)
		"bola_futebol":
			b += SvgLib.circle(48, 48, 38, "#ffffff")
			b += SvgLib.path("M 48 30 L 62 40 L 57 57 L 39 57 L 34 40 Z", INK, INK, 2)
			for p in [[48, 12], [82, 36], [70, 80], [26, 80], [14, 36]]:
				b += SvgLib.circle(p[0], p[1], 7, INK, "", 0)
			b += SvgLib.stroke_path("M 48 30 L 48 14 M 62 40 L 78 34 M 57 57 L 68 74 M 39 57 L 28 74 M 34 40 L 18 34", INK, 3)
		"fogao_lenha":
			b += SvgLib.rect(56, 4, 18, 22, 3, "#6b6280") + SvgLib.rect(12, 22, 72, 66, 8, "#3b3b4f") + SvgLib.rect(18, 28, 60, 10, 4, "#2b2b3d")
			b += SvgLib.rect(26, 46, 44, 34, 10, "#ffb21f", INK, 4)
			b += SvgLib.path("M 48 52 C 52 60 60 62 58 72 C 57 78 52 78 48 78 C 44 78 38 76 38 70 C 38 64 46 62 48 52 Z", "#e8473f", "", 0)
		"cartao_pao":
			defs = SvgLib.lin("cd", "#ffe680", "#f0a81c") + SvgLib.rad("pq", "#fbd98a", "#d68a26", 0.38, 0.3, 0.85)
			b += SvgLib.rect(6, 22, 84, 54, 10, "url(#cd)") + SvgLib.rect(6, 34, 84, 10, 0, "#2b2b3d", "", 0)
			b += SvgLib.circle(66, 60, 14, "url(#pq)", INK, 3) + SvgLib.rect(14, 54, 22, 16, 3, "#c79a0a", INK, 3)
		"chinelo_ouro":
			defs = SvgLib.lin("go", "#fff0a0", "#e8a31c") + SvgLib.lin("gb", "#ffe27a", "#c98a14")
			b += SvgLib.group(_slipper("url(#gb)", "url(#go)", "#fff8d0"), "translate(14 4) rotate(12 40 40) scale(0.78)")
			b += SvgLib.path("M 78 14 L 81 22 L 89 25 L 81 28 L 78 36 L 75 28 L 67 25 L 75 22 Z", "#ffffff", "", 0) + SvgLib.path("M 14 70 L 16 75 L 21 77 L 16 79 L 14 84 L 12 79 L 7 77 L 12 75 Z", "#ffffff", "", 0)
		"santinho":
			b += SvgLib.rect(20, 8, 56, 80, 8, "#fff6dc") + SvgLib.rect(28, 16, 40, 64, 4, "#ffe9a8", INK, 3)
			b += SvgLib.ellipse(48, 28, 14, 5, "none", "#ffd23f", 4) + SvgLib.circle(48, 40, 10, "#d8996a", INK, 3) + SvgLib.path("M 30 74 Q 32 52 48 50 Q 64 52 66 74 Z", "#a88be0", INK, 3)
			b += SvgLib.path("M 74 14 L 76 20 L 82 22 L 76 24 L 74 30 L 72 24 L 66 22 L 72 20 Z", "#ffd23f", "", 0)
	return SvgLib.svg(96, 96, b, defs)
