class_name Pal
extends RefCounted
## Paleta e cores de botões do jogo.

const BG := Color("#1d1530")
const PANEL := Color("#2d2147")
const PANEL2 := Color("#3b2c5e")
const PANEL3 := Color("#4a3877")
const OUTLINE := Color("#150c20")
const TEXT_DIM := Color("#b9aed6")

const GREEN := Color("#3ddc7a")
const GREEN_D := Color("#1c9a52")
const ORANGE := Color("#ffa51f")
const ORANGE_D := Color("#c46a00")
const RED := Color("#ff5a64")
const RED_D := Color("#b72a38")
const BLUE := Color("#4aa8ff")
const BLUE_D := Color("#2468c4")
const PURPLE := Color("#a66bff")
const PURPLE_D := Color("#6a36c4")
const GOLD := Color("#ffd23f")
const GOLD_D := Color("#c79a0a")
const PINK := Color("#ff6fa8")
const PINK_D := Color("#c23a76")
const GRAY := Color("#6b6280")
const GRAY_D := Color("#463e5a")
const TEAL := Color("#2ec4b6")

const RARITY := {
	"common": Color("#b8c4d6"),
	"rare": Color("#4aa8ff"),
	"epic": Color("#c26bff"),
	"legend": Color("#ffb21f"),
}


## [cor, cor escura] de um tipo de botão
static func kind(k: String) -> Array:
	match k:
		"green": return [GREEN, GREEN_D]
		"orange": return [ORANGE, ORANGE_D]
		"red": return [RED, RED_D]
		"blue": return [BLUE, BLUE_D]
		"purple": return [PURPLE, PURPLE_D]
		"gold": return [GOLD, GOLD_D]
		"pink": return [PINK, PINK_D]
		"gray": return [GRAY, GRAY_D]
		_: return [PANEL3, PANEL2]
