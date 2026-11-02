class_name Econ
extends RefCounted
## Fórmulas do jogo: curva de inimigos, custos, bônus globais, estatísticas dos heróis, prestígio.
## Tudo estático e trabalhando sobre o dicionário de save `d` — por isso roda em headless.
## As constantes abaixo foram ajustadas por tools/tune.gd (bot que joga como um jogador esperto: Actions.auto_buy)
## e conferidas com tools/sim_economy.gd e tools/test_offline.gd. Mexeu em algo? Rode as ferramentas de novo.

# --- curva por estágio ---
static var HP0 := 10.0
static var HP_G := 1.45
static var ATK0 := 1.6
static var ATK_G := 1.40
static var GOLD0 := 2.0
static var GOLD_G := 1.2899
static var WAVES := 4
static var BOSS_TIME := 30.0
static var ELITE_HP := 10.9106      ## = 0.4 x BOSS_HP
static var BOSS_HP := 27.2766

# --- heróis ---
static var LEVEL_G := 1.0929
static var MILESTONE := 25.0
static var RECRUIT_K := 6.9268
static var LATE_F := 0.5601         ## fator de poder base dos heróis que chegam a partir do estágio 14
static var REGEN := 0.012
static var TAP_FRAC := 0.12

# --- prestígio ---
static var PRESTIGE_MIN_STAGE := 40
static var PRESTIGE_DMG := 0.05
static var PRESTIGE_HP := 0.03
static var PRESTIGE_GOLD := 0.02

# --- Marmita (gacha de relíquias) ---
const MARMITA_COST := 30
const EPIC_PITY := 30
const LEGEND_PITY := 100

# --- Fornada da Vovó: duração (s) e Pães de Queijo ---
const FORNADA := {
	"short": {"dur": 1800.0, "gems": 4},
	"mid": {"dur": 14400.0, "gems": 40},
	"long": {"dur": 43200.0, "gems": 150},
}

static var _base_cache: Dictionary = {}


## Limpa o cache dos números base dos heróis (use depois de mudar as constantes acima, p.ex. no tuner).
static func reset_cache() -> void:
	_base_cache.clear()


static func enemy_hp(stage: int) -> float:
	return HP0 * pow(HP_G, stage - 1)


static func enemy_atk(stage: int) -> float:
	return ATK0 * pow(ATK_G, stage - 1)


static func enemy_gold(stage: int) -> float:
	return GOLD0 * pow(GOLD_G, stage - 1)


static func group_size(stage: int) -> int:
	return clampi(1 + floori((stage - 1) / 8.0), 1, 4)


static func stage_income(stage: int) -> float:
	return WAVES * group_size(stage) * enemy_gold(stage)


# ---------------------------------------------------------------- heróis

## Números base de um herói no nível 1 (derivados do estágio de desbloqueio).
static func hero_base(id: String) -> Dictionary:
	if _base_cache.has(id):
		return _base_cache[id]
	var h: Dictionary = HeroDefs.DATA[id]
	var u: int = h.unlock
	var late := LATE_F if u >= 14 else 1.0
	var b := {
		"atk": float(h.atk_f) * enemy_hp(u) * late,
		"hp": float(h.hp_f) * enemy_atk(u) * late,
		"cost": float(h.cost_f) * stage_income(u),
		"recruit": 0.0 if u <= 1 else RECRUIT_K * stage_income(u),
	}
	_base_cache[id] = b
	return b


static func milestone(level: int) -> float:
	return pow(2.0, floorf(level / MILESTONE))


static func skill_rank(level: int) -> int:
	var r := 0
	for t in [10, 25, 50, 100]:
		if level >= t:
			r += 1
	return r


static func level_cost(id: String, level: int) -> float:
	return float(hero_base(id).cost) * pow(LEVEL_G, level - 1)


## Custo de comprar `n` níveis a partir de `level`.
static func bulk_cost(id: String, level: int, n: int) -> float:
	if n <= 0:
		return 0.0
	return level_cost(id, level) * (pow(LEVEL_G, n) - 1.0) / (LEVEL_G - 1.0)


static func max_affordable(id: String, level: int, gold: float, cap: int = 3000) -> int:
	var c := level_cost(id, level)
	if gold < c:
		return 0
	var n := floori(log(1.0 + gold * (LEVEL_G - 1.0) / c) / log(LEVEL_G))
	n = clampi(n, 0, cap)
	while n > 0 and bulk_cost(id, level, n) > gold:
		n -= 1
	return n


static func recruit_cost(id: String) -> float:
	return float(hero_base(id).recruit)


static func slots(d: Dictionary) -> int:
	var b := int(d.stage.best)
	var s := 3
	if b >= 19:
		s += 1
	if b >= 39:
		s += 1
	return s


## Herói já pode ser recrutado (alcançamos o estágio de desbloqueio)?
static func hero_available(d: Dictionary, id: String) -> bool:
	return int(d.stage.best) + 1 >= int(HeroDefs.DATA[id].unlock)


static func auto_up_unlocked(d: Dictionary) -> bool:
	return int(d.stage.best) >= 11


# ---------------------------------------------------------------- bônus globais

static func _g(dict: Dictionary, k: String) -> float:
	return float(dict.get(k, 0.0))


## Bônus de relíquias + bênçãos + prestígio (somam dentro de cada fonte e multiplicam entre fontes).
static func mods(d: Dictionary) -> Dictionary:
	var rs := {}
	for rid in d.relics:
		if not RelicDefs.DATA.has(rid):
			continue
		var lvl := int(d.relics[rid].lvl)
		var r: Dictionary = RelicDefs.DATA[rid]
		rs[r.stat] = float(rs.get(r.stat, 0.0)) + RelicDefs.value(rid, lvl)
		if r.stat == "revive" and lvl > 0:
			rs["revive"] = 1.0
	var bs := {}
	for tid in d.bless:
		if not BlessDefs.DATA.has(tid):
			continue
		var l2 := int(d.bless[tid])
		if l2 <= 0:
			continue
		var t: Dictionary = BlessDefs.DATA[tid]
		bs[t.stat] = float(bs.get(t.stat, 0.0)) + float(t.per) * l2
	var pb := float(d.prestige.earned)
	var m := {}
	m["dmg"] = (1.0 + _g(rs, "dmg") + _g(bs, "dmg")) * (1.0 + PRESTIGE_DMG * pb)
	m["hp"] = (1.0 + _g(rs, "hp") + _g(bs, "hp")) * (1.0 + PRESTIGE_HP * pb)
	m["aspd"] = 1.0 + _g(rs, "aspd") + _g(bs, "aspd")
	m["gold"] = (1.0 + _g(rs, "gold") + _g(bs, "gold")) * (1.0 + PRESTIGE_GOLD * pb)
	m["crit"] = _g(rs, "crit") + _g(bs, "crit")
	m["crit_mult"] = _g(rs, "crit_mult")
	m["haste"] = _g(rs, "haste") + _g(bs, "haste")
	m["fury_gain"] = 1.0 + _g(rs, "fury_gain") + _g(bs, "fury_gain")
	m["fury_dur"] = 8.0 + _g(bs, "fury_dur")
	m["heal"] = 1.0 + _g(rs, "heal")
	m["boss_time"] = BOSS_TIME + _g(bs, "boss_time")
	m["off_eff"] = clampf(0.8 + _g(rs, "off_eff") + _g(bs, "off_eff"), 0.0, 1.5)
	m["off_cap"] = 8.0 * 3600.0 + _g(bs, "off_cap")
	m["gems"] = 1.0 + _g(rs, "gems") + _g(bs, "gems")
	m["armor"] = clampf(_g(rs, "armor"), 0.0, 0.6)
	m["revive"] = _g(rs, "revive") > 0.0
	m["auto_fury"] = _g(bs, "auto_fury") > 0.0
	m["start_stage"] = int(_g(bs, "start_stage"))
	m["fornada_slots"] = 1 + int(_g(bs, "fornada_slots"))
	m["parrot"] = 1.0 + _g(bs, "parrot")
	m["pity_cut"] = int(_g(bs, "pity_cut"))
	m["regen"] = REGEN + _g(rs, "regen")
	m["tap"] = TAP_FRAC
	return m


## Estatísticas de combate de um herói (já com todos os bônus).
static func hero_stats(d: Dictionary, id: String, m: Dictionary) -> Dictionary:
	var h: Dictionary = HeroDefs.DATA[id]
	var b := hero_base(id)
	var lvl := int(d.heroes[id].lvl)
	var ms := milestone(lvl)
	var rank := skill_rank(lvl)
	var sk: Dictionary = h.skill.duplicate()
	var rm := 1.0 + 0.4 * rank
	if sk.has("mult"):
		sk.mult = float(sk.mult) * rm
	if sk.has("pct"):
		sk.pct = float(sk.pct) * (1.0 + 0.15 * rank)
	if sk.has("atk_up"):
		sk.atk_up = float(sk.atk_up) * (1.0 + 0.15 * rank)
	if sk.has("vuln"):
		sk.vuln = float(sk.vuln) * (1.0 + 0.15 * rank)
	if sk.has("burn_mult"):
		sk.burn_mult = float(sk.burn_mult) * rm
	sk.cd = float(sk.cd) * (1.0 - 0.04 * rank)
	return {
		"id": id,
		"role": h.role,
		"ranged": h.ranged,
		"lvl": lvl,
		"atk": float(b.atk) * lvl * ms * float(m.dmg),
		"hp": float(b.hp) * lvl * ms * float(m.hp),
		"aspd": float(h.aspd) * float(m.aspd),
		"crit": clampf(float(h.crit) + float(m.crit), 0.0, 0.9),
		"crit_mult": 2.0 + float(m.crit_mult),
		"skill": sk,
	}


static func party_stats(d: Dictionary, m: Dictionary) -> Array:
	var out: Array = []
	for id in d.party:
		if d.heroes[id].owned:
			out.append(hero_stats(d, id, m))
	return out


static func dps_of(st: Dictionary) -> float:
	return float(st.atk) * float(st.aspd) * (1.0 + float(st.crit) * (float(st.crit_mult) - 1.0))


## Poder do time (média geométrica entre DPS total e vida total). Usado para decidir quando tentar de novo.
static func team_power(stats: Array) -> float:
	var dps := 0.0
	var hp := 0.0
	var buff := false
	var debuff := false
	var heal := false
	for st in stats:
		dps += dps_of(st)
		hp += float(st.hp)
		match String(st.skill.kind):
			"buff_team": buff = true
			"vuln": debuff = true
			"heal": heal = true
	# utilidade das skills de apoio (aproximação do efeito médio em combate)
	if buff:
		dps *= 1.25
	if debuff:
		dps *= 1.20
	if heal:
		hp *= 1.35
	return sqrt(maxf(dps, 0.0) * maxf(hp, 0.0))


static func tap_damage(stats: Array, m: Dictionary) -> float:
	var dps := 0.0
	for st in stats:
		dps += dps_of(st)
	return dps * float(m.tap)


# ---------------------------------------------------------------- inimigos

static func enemy_spec(id: String, stage: int, elite: bool, boss: bool) -> Dictionary:
	var e: Dictionary = EnemyDefs.DATA[id]
	var hp := enemy_hp(stage) * float(e.hp)
	var atk := enemy_atk(stage) * float(e.atk)
	var gold := enemy_gold(stage) * float(e.gold)
	var scale := float(e.scale)
	if boss:
		hp *= BOSS_HP
		atk *= 1.4
		gold *= 6.0
	elif elite:
		hp *= ELITE_HP
		atk *= 1.25
		gold *= 4.0
		scale *= 1.35
	var sp := {
		"id": id,
		"hp": hp,
		"atk": atk,
		"aspd": float(e.aspd),
		"speed": float(e.speed),
		"ranged": bool(e.get("ranged", false)),
		"gold": gold,
		"scale": scale,
		"traits": e.get("traits", []),
		"boss": boss,
		"elite": elite,
		"swarm": int(e.get("swarm", 1)),
	}
	if e.has("summon"):
		sp["summon"] = e.summon
		sp["summon_every"] = float(e.summon_every)
	return sp


## Unidades de uma onda (cada unidade de enxame já vem expandida).
static func make_wave(stage: int, _wave: int, rng: RandomNumberGenerator) -> Array:
	var w: Dictionary = WorldDefs.DATA[WorldDefs.index_of(stage)]
	var out: Array = []
	var reg: Array = w.regular
	if WorldDefs.is_boss_stage(stage):
		if WorldDefs.is_world_boss(stage):
			out.append(enemy_spec(w.boss, stage, false, true))
		else:
			var pick: String = reg[(floori(stage / 5.0) + 1) % reg.size()]
			out.append(enemy_spec(pick, stage, true, false))
		return out
	for _i in group_size(stage):
		var id: String = reg[rng.randi() % reg.size()]
		var sp := enemy_spec(id, stage, false, false)
		for _k in int(sp.swarm):
			out.append(sp.duplicate())
	return out


# ---------------------------------------------------------------- recompensas e prestígio

static func stage_clear_gems(stage: int, m: Dictionary) -> int:
	if not WorldDefs.is_boss_stage(stage):
		return 0
	var w := WorldDefs.index_of(stage)
	var g := 8 + 2 * w if WorldDefs.is_world_boss(stage) else 2 + w
	return maxi(1, roundi(g * float(m.gems)))


static func bless_gain(d: Dictionary) -> int:
	var s := int(d.prestige.run_best)
	if s < PRESTIGE_MIN_STAGE:
		return 0
	return maxi(1, floori(pow(float(s - 30), 1.55) / 8.0))


## Rola a raridade de uma Marmita, mexendo no contador de pity.
static func roll_rarity(d: Dictionary, rng: RandomNumberGenerator, m: Dictionary) -> String:
	var cut := int(m.pity_cut)
	var pity: Dictionary = d.pity
	pity.epic = int(pity.epic) + 1
	pity.legend = int(pity.legend) + 1
	pity.opens = int(pity.opens) + 1
	if int(pity.legend) >= LEGEND_PITY - cut:
		pity.legend = 0
		pity.epic = 0
		return "legend"
	if int(pity.epic) >= EPIC_PITY - cut:
		pity.epic = 0
		return "epic"
	var x := rng.randf()
	var acc := 0.0
	for r in RelicDefs.RARITY_ORDER:
		acc += float(RelicDefs.RARITY_ODDS[r])
		if x < acc:
			if r == "epic":
				pity.epic = 0
			elif r == "legend":
				pity.legend = 0
				pity.epic = 0
			return r
	return "common"
