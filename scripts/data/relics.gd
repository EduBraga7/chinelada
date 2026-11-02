class_name RelicDefs
extends RefCounted
## Relíquias globais (vêm da Marmita). Duplicata sobe o nível. Cada nível soma `base × raridade` ao stat.
## `revive` é especial: nível ≥ 1 liga a ressurreição uma vez por combate.

const MAX_LEVEL := 30
const RARITY_ORDER: Array[String] = ["common", "rare", "epic", "legend"]
const RARITY_MULT := {"common": 1.0, "rare": 1.8, "epic": 3.0, "legend": 5.0}
## Chance base de cada raridade na Marmita (soma 1.0)
const RARITY_ODDS := {"common": 0.68, "rare": 0.24, "epic": 0.07, "legend": 0.01}

const DATA := {
	"chinelo_sorte": {"rarity": "common", "stat": "dmg", "base": 0.05},
	"panela_pressao": {"rarity": "common", "stat": "aspd", "base": 0.015},
	"cofrinho": {"rarity": "common", "stat": "gold", "base": 0.06},
	"terco_vovo": {"rarity": "common", "stat": "hp", "base": 0.05},
	"ventilador": {"rarity": "common", "stat": "crit", "base": 0.004},
	"garrafa_termica": {"rarity": "common", "stat": "haste", "base": 0.02},
	"controle_remoto": {"rarity": "rare", "stat": "haste", "base": 0.03},
	"novela": {"rarity": "rare", "stat": "fury_gain", "base": 0.05},
	"guarda_chuva": {"rarity": "rare", "stat": "armor", "base": 0.01},
	"panelao": {"rarity": "rare", "stat": "heal", "base": 0.06},
	"caderninho": {"rarity": "epic", "stat": "off_eff", "base": 0.01},
	"bola_futebol": {"rarity": "epic", "stat": "crit_mult", "base": 0.04},
	"fogao_lenha": {"rarity": "epic", "stat": "regen", "base": 0.003},
	"cartao_pao": {"rarity": "legend", "stat": "gems", "base": 0.03},
	"chinelo_ouro": {"rarity": "legend", "stat": "dmg", "base": 0.10},
	"santinho": {"rarity": "legend", "stat": "revive", "base": 0.0},
}


static func ids() -> Array:
	return DATA.keys()


static func ids_of(rarity: String) -> Array:
	var out: Array = []
	for id in DATA:
		if DATA[id].rarity == rarity:
			out.append(id)
	return out


## Valor somado ao stat no nível `lvl`.
static func value(id: String, lvl: int) -> float:
	var r: Dictionary = DATA[id]
	return float(r.base) * float(RARITY_MULT[r.rarity]) * lvl
