class_name Goals
extends RefCounted
## Metas: login diário (7 dias), missões do dia, conquistas, códigos de resgate e Fornada da Vovó.
## Só lógica sobre o save `d` (sem UI), então dá para testar em headless.

## kind → chave em d.stats (ou cálculo em progress()). `gems` = recompensa.
const ACH: Array[Dictionary] = [
	{"id": "first_blood", "kind": "kills", "target": 1, "gems": 3},
	{"id": "kills_100", "kind": "kills", "target": 100, "gems": 5},
	{"id": "kills_1k", "kind": "kills", "target": 1000, "gems": 10},
	{"id": "kills_10k", "kind": "kills", "target": 10000, "gems": 25},
	{"id": "kills_100k", "kind": "kills", "target": 100000, "gems": 60},
	{"id": "stage_10", "kind": "stage", "target": 10, "gems": 5},
	{"id": "stage_20", "kind": "stage", "target": 20, "gems": 10},
	{"id": "stage_40", "kind": "stage", "target": 40, "gems": 20},
	{"id": "stage_60", "kind": "stage", "target": 60, "gems": 30},
	{"id": "stage_80", "kind": "stage", "target": 80, "gems": 40},
	{"id": "stage_100", "kind": "stage", "target": 100, "gems": 60},
	{"id": "heroes_3", "kind": "heroes", "target": 3, "gems": 5},
	{"id": "heroes_5", "kind": "heroes", "target": 5, "gems": 10},
	{"id": "heroes_8", "kind": "heroes", "target": 8, "gems": 25},
	{"id": "level_100", "kind": "level", "target": 100, "gems": 10},
	{"id": "level_300", "kind": "level", "target": 300, "gems": 30},
	{"id": "marmita_1", "kind": "marmita", "target": 1, "gems": 5},
	{"id": "marmita_25", "kind": "marmita", "target": 25, "gems": 20},
	{"id": "relics_5", "kind": "relics", "target": 5, "gems": 10},
	{"id": "relics_16", "kind": "relics", "target": 16, "gems": 50},
	{"id": "prestige_1", "kind": "prestige", "target": 1, "gems": 20},
	{"id": "prestige_10", "kind": "prestige", "target": 10, "gems": 60},
	{"id": "crit_500", "kind": "crit", "target": 500, "gems": 10},
	{"id": "fury_20", "kind": "fury", "target": 20, "gems": 10},
	{"id": "parrot_10", "kind": "parrot", "target": 10, "gems": 15},
	{"id": "bosses_25", "kind": "bosses", "target": 25, "gems": 20},
	{"id": "share_1", "kind": "share", "target": 1, "gems": 5},
]

## Modelos de missão diária: alvo = base + best × per; `stat` = chave de d.stats
const MISSIONS: Array[Dictionary] = [
	{"kind": "kills", "stat": "kills", "base": 100.0, "per": 8.0},
	{"kind": "stages", "stat": "stages", "base": 6.0, "per": 0.15},
	{"kind": "bosses", "stat": "bosses", "base": 1.0, "per": 0.04},
	{"kind": "upgrades", "stat": "upgrades", "base": 30.0, "per": 2.0},
	{"kind": "fury", "stat": "fury", "base": 2.0, "per": 0.04},
	{"kind": "parrots", "stat": "parrots", "base": 1.0, "per": 0.02},
	{"kind": "marmitas", "stat": "marmitas", "base": 1.0, "per": 0.0},
	{"kind": "crits", "stat": "crits", "base": 50.0, "per": 10.0},
]

## Presente de login: [tipo, quantidade]. gold = horas de renda; gems = Pães de Queijo.
const LOGIN: Array = [["gold", 0.5], ["gems", 5], ["gold", 1.0], ["gems", 10], ["gold", 2.0], ["gems", 15], ["gems", 40]]

## Códigos de resgate (divulgue com criadores de conteúdo). [gems]
const CODES := {"CHINELADA": 30, "VOVO": 20, "TOMA": 10, "BETA": 50, "FAMILIA": 30}


static func today() -> int:
	var t := Time.get_unix_time_from_system() + float(Time.get_time_zone_from_system().bias) * 60.0
	return int(floor(t / 86400.0))


# ---------------------------------------------------------------- conquistas

static func progress(d: Dictionary, kind: String) -> float:
	match kind:
		"kills": return float(d.stats.kills)
		"stage": return float(d.stage.best)
		"heroes":
			var n := 0
			for id in HeroDefs.IDS:
				if d.heroes[id].owned:
					n += 1
			return float(n)
		"level":
			var m := 0
			for id in HeroDefs.IDS:
				m = maxi(m, int(d.heroes[id].lvl))
			return float(m)
		"marmita": return float(d.stats.marmitas)
		"relics": return float(d.relics.size())
		"prestige": return float(d.prestige.count)
		"crit": return float(d.stats.crits)
		"fury": return float(d.stats.fury)
		"parrot": return float(d.stats.parrots)
		"bosses": return float(d.stats.bosses)
		"share": return float(d.stats.shares)
	return 0.0


static func ach_done(d: Dictionary, a: Dictionary) -> bool:
	return progress(d, a.kind) >= float(a.target)


static func ach_claimed(d: Dictionary, a: Dictionary) -> bool:
	return bool(d.ach.get(a.id, false))


static func claim_ach(d: Dictionary, id: String) -> int:
	for a in ACH:
		if a.id == id and ach_done(d, a) and not ach_claimed(d, a):
			d.ach[id] = true
			d.cur.gems = int(d.cur.gems) + int(a.gems)
			return int(a.gems)
	return 0


static func ach_claimable(d: Dictionary) -> int:
	var n := 0
	for a in ACH:
		if ach_done(d, a) and not ach_claimed(d, a):
			n += 1
	return n


# ---------------------------------------------------------------- missões do dia

static func ensure_daily(d: Dictionary) -> void:
	var day := str(today())
	if String(d.daily.mission_date) == day:
		return
	d.daily.mission_date = day
	var rng := RandomNumberGenerator.new()
	rng.seed = today() * 7919 + 13
	var pool: Array = MISSIONS.duplicate()
	var out: Array = []
	var best := float(d.stage.best)
	for _i in 3:
		var idx := rng.randi() % pool.size()
		var tpl: Dictionary = pool[idx]
		pool.remove_at(idx)
		var target := maxf(1.0, roundf(float(tpl.base) + best * float(tpl.per)))
		out.append({
			"kind": tpl.kind, "stat": tpl.stat, "target": target, "from": float(d.stats[tpl.stat]),
			"gems": 4 + rng.randi() % 5, "claimed": false,
		})
	d.daily.missions = out


static func mission_progress(d: Dictionary, m: Dictionary) -> float:
	return clampf(float(d.stats[m.stat]) - float(m.from), 0.0, float(m.target))


static func claim_mission(d: Dictionary, idx: int) -> int:
	var arr: Array = d.daily.missions
	if idx < 0 or idx >= arr.size():
		return 0
	var m: Dictionary = arr[idx]
	if bool(m.claimed) or mission_progress(d, m) < float(m.target):
		return 0
	m.claimed = true
	d.cur.gems = int(d.cur.gems) + int(m.gems)
	return int(m.gems)


static func missions_claimable(d: Dictionary) -> int:
	var n := 0
	for m in d.daily.missions:
		if not bool(m.claimed) and mission_progress(d, m) >= float(m.target):
			n += 1
	return n


# ---------------------------------------------------------------- login diário

static func login_can_claim(d: Dictionary) -> bool:
	return int(d.daily.get("last_claim_day", 0)) != today()


## Dia atual do ciclo de 7 (1..7) se o jogador pegar hoje.
static func login_day(d: Dictionary) -> int:
	var last := int(d.daily.get("last_claim_day", 0))
	var streak := int(d.daily.streak)
	if last == today() - 1:
		streak += 1
	elif last != today():
		streak = 1
	return (maxi(streak, 1) - 1) % 7 + 1


## Pega o presente. Devolve {"gold": x, "gems": n} ou {} se já pegou hoje.
static func claim_login(d: Dictionary, income_ph: float, best_stage: int) -> Dictionary:
	if not login_can_claim(d):
		return {}
	var last := int(d.daily.get("last_claim_day", 0))
	if last == today() - 1:
		d.daily.streak = int(d.daily.streak) + 1
	else:
		d.daily.streak = 1
	d.daily.last_claim_day = today()
	var day := (int(d.daily.streak) - 1) % 7 + 1
	var rw: Array = LOGIN[day - 1]
	var out := {"gold": 0.0, "gems": 0, "day": day}
	if rw[0] == "gold":
		var g := maxf(income_ph * float(rw[1]), Econ.stage_income(maxi(1, best_stage)) * 4.0 * float(rw[1]))
		d.cur.gold = float(d.cur.gold) + g
		out.gold = g
	else:
		d.cur.gems = int(d.cur.gems) + int(rw[1])
		out.gems = int(rw[1])
	if day == 7:
		# dia 7 também dá ouro
		var g2 := maxf(income_ph * 4.0, Econ.stage_income(maxi(1, best_stage)) * 16.0)
		d.cur.gold = float(d.cur.gold) + g2
		out.gold = g2
	return out


# ---------------------------------------------------------------- códigos

## 0 = ok, 1 = inválido, 2 = já usado. `gems` recebe a recompensa.
static func redeem(d: Dictionary, code: String) -> Array:
	var c := code.strip_edges().to_upper()
	if not CODES.has(c):
		return [1, 0]
	if d.codes.has(c):
		return [2, 0]
	d.codes.append(c)
	var g: int = CODES[c]
	d.cur.gems = int(d.cur.gems) + g
	return [0, g]


# ---------------------------------------------------------------- Fornada da Vovó

static func fornada_state(d: Dictionary) -> Dictionary:
	var f: Dictionary = d.fornada
	if String(f.kind) == "":
		return {"state": "idle", "remain": 0.0}
	var now := Time.get_unix_time_from_system()
	var remain := float(f.end) - now
	if remain <= 0.0:
		return {"state": "ready", "remain": 0.0, "kind": f.kind}
	return {"state": "cooking", "remain": remain, "kind": f.kind}


static func fornada_start(d: Dictionary, kind: String) -> bool:
	if not Econ.FORNADA.has(kind) or not bool(d.heroes["vovo"].owned):
		return false
	if String(d.fornada.kind) != "":
		return false
	var now := Time.get_unix_time_from_system()
	d.fornada.kind = kind
	d.fornada.start = now
	d.fornada.end = now + float(Econ.FORNADA[kind].dur)
	return true


static func fornada_gems(kind: String, m: Dictionary) -> int:
	return maxi(1, roundi(float(Econ.FORNADA[kind].gems) * float(m.gems)))


static func fornada_claim(d: Dictionary, m: Dictionary) -> int:
	var st := fornada_state(d)
	if st.state != "ready":
		return 0
	var g := fornada_gems(String(st.kind), m)
	d.cur.gems = int(d.cur.gems) + g
	d.fornada.kind = ""
	d.fornada.start = 0.0
	d.fornada.end = 0.0
	return g
