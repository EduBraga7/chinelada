class_name BlessDefs
extends RefCounted
## Árvore de Bênçãos (talentos permanentes comprados com Bênçãos do prestígio).
## `per` é somado ao stat por nível. Custo do próximo nível = ceil(cost × grow^nível_atual).

const DATA := {
	"forca": {"stat": "dmg", "per": 0.10, "max": 20, "cost": 1.0, "grow": 1.30},
	"saude": {"stat": "hp", "per": 0.10, "max": 20, "cost": 1.0, "grow": 1.30},
	"ouro": {"stat": "gold", "per": 0.10, "max": 20, "cost": 1.0, "grow": 1.30},
	"pressa": {"stat": "aspd", "per": 0.02, "max": 15, "cost": 2.0, "grow": 1.30},
	"sorte": {"stat": "crit", "per": 0.01, "max": 15, "cost": 2.0, "grow": 1.30},
	"furia": {"stat": "fury_gain", "per": 0.10, "max": 10, "cost": 2.0, "grow": 1.35},
	"furia_dur": {"stat": "fury_dur", "per": 1.0, "max": 6, "cost": 3.0, "grow": 1.40},
	"tempo_boss": {"stat": "boss_time", "per": 2.0, "max": 10, "cost": 2.0, "grow": 1.30},
	"auto_furia": {"stat": "auto_fury", "per": 1.0, "max": 1, "cost": 6.0, "grow": 1.0},
	"off_cap": {"stat": "off_cap", "per": 7200.0, "max": 8, "cost": 3.0, "grow": 1.45},
	"off_eff": {"stat": "off_eff", "per": 0.04, "max": 5, "cost": 4.0, "grow": 1.50},
	"forno_extra": {"stat": "fornada_slots", "per": 1.0, "max": 1, "cost": 10.0, "grow": 1.0},
	"papagaio": {"stat": "parrot", "per": 0.20, "max": 5, "cost": 2.0, "grow": 1.40},
	"inicio": {"stat": "start_stage", "per": 5.0, "max": 5, "cost": 5.0, "grow": 1.60},
	"marmita": {"stat": "pity_cut", "per": 2.0, "max": 5, "cost": 4.0, "grow": 1.45},
	"gemas": {"stat": "gems", "per": 0.10, "max": 5, "cost": 3.0, "grow": 1.45},
}

## Ordem de exibição na árvore
const ORDER: Array[String] = ["forca", "saude", "ouro", "pressa", "sorte", "furia", "furia_dur", "tempo_boss",
	"auto_furia", "off_cap", "off_eff", "forno_extra", "papagaio", "inicio", "marmita", "gemas"]


static func cost(id: String, lvl_now: int) -> int:
	var t: Dictionary = DATA[id]
	return maxi(1, ceili(float(t.cost) * pow(float(t.grow), lvl_now)))
