class_name HeroDefs
extends RefCounted
## Heróis da família. Os números base saem de Econ.hero_base(), derivados do estágio de
## desbloqueio (`unlock`), então mexer na curva de inimigos rebalanceia os heróis sozinho.

const IDS: Array[String] = ["neide", "vovo", "ze", "caramelo", "isadora", "marcao", "pedrinho", "fofoca"]

## Ordem de formação (frente → fundo)
const ROLE_ORDER := {"tank": 0, "melee": 1, "ranged": 2, "debuff": 3, "support": 4, "healer": 5}

## atk_f/hp_f: fator sobre o HP/ATK de um inimigo no estágio `unlock`. cost_f: fator do custo de nível.
## weight: prioridade do auto-melhorar. skill.kind define o efeito em BattleSim._cast().
const DATA := {
	"neide": {
		"role": "melee", "ranged": false, "unlock": 1,
		"atk_f": 0.50, "hp_f": 56.0, "aspd": 1.2, "crit": 0.06, "cost_f": 1.0, "weight": 1.0,
		"skill": {"kind": "burst", "cd": 8.0, "mult": 3.5, "stun": 1.6},
	},
	"vovo": {
		"role": "healer", "ranged": true, "unlock": 4,
		"atk_f": 0.20, "hp_f": 70.0, "aspd": 0.9, "crit": 0.03, "cost_f": 1.0, "weight": 0.35,
		"skill": {"kind": "heal", "cd": 9.0, "mult": 6.0, "pct": 0.10},
	},
	"ze": {
		"role": "tank", "ranged": false, "unlock": 8,
		"atk_f": 0.30, "hp_f": 130.0, "aspd": 0.8, "crit": 0.03, "cost_f": 1.1, "weight": 0.6,
		"skill": {"kind": "taunt_burn", "cd": 10.0, "taunt": 5.0, "shield": 0.6, "burn_mult": 0.8, "burn_t": 4.0},
	},
	"caramelo": {
		"role": "melee", "ranged": false, "unlock": 14,
		"atk_f": 0.45, "hp_f": 60.0, "aspd": 1.7, "crit": 0.12, "cost_f": 1.2, "weight": 1.0,
		"skill": {"kind": "multihit", "cd": 7.0, "hits": 4, "mult": 1.2},
	},
	"isadora": {
		"role": "ranged", "ranged": true, "unlock": 22,
		"atk_f": 0.75, "hp_f": 45.0, "aspd": 1.0, "crit": 0.22, "cost_f": 1.3, "weight": 1.0,
		"skill": {"kind": "aoe_blind", "cd": 10.0, "mult": 2.2, "weak": 0.7, "dur": 4.0},
	},
	"marcao": {
		"role": "support", "ranged": true, "unlock": 32,
		"atk_f": 0.35, "hp_f": 70.0, "aspd": 1.0, "crit": 0.05, "cost_f": 1.4, "weight": 0.5,
		"skill": {"kind": "buff_team", "cd": 14.0, "dur": 8.0, "atk_up": 0.35, "aspd_up": 0.25},
	},
	"pedrinho": {
		"role": "ranged", "ranged": true, "unlock": 45,
		"atk_f": 0.85, "hp_f": 40.0, "aspd": 1.4, "crit": 0.12, "cost_f": 1.5, "weight": 1.0,
		"skill": {"kind": "barrage", "cd": 8.0, "n": 6, "mult": 1.4},
	},
	"fofoca": {
		"role": "debuff", "ranged": true, "unlock": 60,
		"atk_f": 0.60, "hp_f": 55.0, "aspd": 1.0, "crit": 0.08, "cost_f": 1.6, "weight": 0.6,
		"skill": {"kind": "vuln", "cd": 12.0, "dur": 8.0, "vuln": 0.30, "slow": 0.30},
	},
}
