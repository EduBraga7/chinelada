class_name Actions
extends RefCounted
## Operações que mudam o save `d` (compras, recrutar, prestígio...). Sem UI: o jogo e os bots usam o mesmo código.


# ---------------------------------------------------------------- time

static func sort_party(d: Dictionary) -> void:
	var order := HeroDefs.IDS
	var arr: Array = d.party.duplicate()
	arr.sort_custom(func(a: String, b: String) -> bool:
		var ra: int = HeroDefs.ROLE_ORDER[HeroDefs.DATA[a].role]
		var rb: int = HeroDefs.ROLE_ORDER[HeroDefs.DATA[b].role]
		if ra != rb:
			return ra < rb
		return order.find(a) < order.find(b))
	d.party = arr


## Remove duplicados/não recrutados, respeita o número de vagas e garante ao menos 1 herói.
static func fix_party(d: Dictionary) -> void:
	var seen := {}
	var out: Array = []
	var cap := Econ.slots(d)
	for id in d.party:
		if typeof(id) != TYPE_STRING or not HeroDefs.DATA.has(id) or seen.has(id):
			continue
		if not d.heroes[id].owned:
			continue
		seen[id] = true
		if out.size() < cap:
			out.append(id)
	if out.is_empty():
		d.heroes["neide"].owned = true
		d.heroes["neide"].lvl = maxi(int(d.heroes["neide"].lvl), 1)
		out.append("neide")
	d.party = out
	sort_party(d)


## Combinações de `k` itens de `items` (usado para achar o melhor time; no máximo C(8,5) = 56).
static func _combos(items: Array, k: int) -> Array:
	var out: Array = []
	var cur: Array = []
	_combos_rec(items, k, 0, cur, out)
	return out


static func _combos_rec(items: Array, k: int, start: int, cur: Array, out: Array) -> void:
	if cur.size() == k:
		out.append(cur.duplicate())
		return
	for i in range(start, items.size()):
		cur.append(items[i])
		_combos_rec(items, k, i + 1, cur, out)
		cur.pop_back()


## Melhor time possível (por poder do time) entre os heróis recrutados.
static func best_team(d: Dictionary) -> Array:
	var owned: Array = []
	for id in HeroDefs.IDS:
		if d.heroes[id].owned:
			owned.append(id)
	var cap := Econ.slots(d)
	if owned.size() <= cap:
		return owned
	var m := Econ.mods(d)
	var best: Array = owned.slice(0, cap)
	var best_p := -1.0
	# Dona Neide é fixa no time (personagem-título e dona da Fúria): só escolhemos os outros
	var rest: Array = owned.duplicate()
	rest.erase("neide")
	for c in _combos(rest, cap - 1):
		c.append("neide")
		var stats: Array = []
		for id in c:
			stats.append(Econ.hero_stats(d, id, m))
		var p := Econ.team_power(stats)
		if p > best_p:
			best_p = p
			best = c
	return best


## Escala o melhor time (só se a escalação automática estiver ligada).
static func auto_team(d: Dictionary) -> bool:
	if not bool(d.settings.auto_team):
		return false
	var best := best_team(d)
	var cur: Array = d.party.duplicate()
	cur.sort()
	var nxt: Array = best.duplicate()
	nxt.sort()
	if cur == nxt:
		return false
	d.party = best
	sort_party(d)
	return true


static func toggle_party(d: Dictionary, id: String) -> bool:
	if not d.heroes[id].owned:
		return false
	if d.party.has(id):
		if d.party.size() <= 1:
			return false
		d.party.erase(id)
	else:
		if d.party.size() >= Econ.slots(d):
			return false
		d.party.append(id)
	sort_party(d)
	return true


# ---------------------------------------------------------------- compras

static func upgrade(d: Dictionary, id: String, n: int) -> int:
	var h: Dictionary = d.heroes[id]
	if not h.owned:
		return 0
	var lvl := int(h.lvl)
	var gold := float(d.cur.gold)
	var k := n
	if n < 0:
		k = Econ.max_affordable(id, lvl, gold)
	if k <= 0:
		return 0
	var cost := Econ.bulk_cost(id, lvl, k)
	if cost > gold:
		return 0
	d.cur.gold = gold - cost
	h.lvl = lvl + k
	d.stats.upgrades = float(d.stats.upgrades) + k
	return k


static func recruit(d: Dictionary, id: String) -> bool:
	var h: Dictionary = d.heroes[id]
	if h.owned or not Econ.hero_available(d, id):
		return false
	var cost := Econ.recruit_cost(id)
	if float(d.cur.gold) < cost:
		return false
	d.cur.gold = float(d.cur.gold) - cost
	h.owned = true
	h.lvl = 1
	if d.party.size() < Econ.slots(d):
		d.party.append(id)
		sort_party(d)
	return true


static func _value(id: String, lvl: int) -> float:
	var h: Dictionary = HeroDefs.DATA[id]
	return float(h.weight) * float(Econ.hero_base(id).atk) * float(h.aspd) * lvl * Econ.milestone(lvl)


## Menor preço entre os heróis já liberados (estágio alcançado) que ainda não foram recrutados; -1 se não há.
static func cheapest_pending_recruit(d: Dictionary) -> float:
	var best := -1.0
	for id in HeroDefs.IDS:
		if not d.heroes[id].owned and Econ.hero_available(d, id):
			var c := Econ.recruit_cost(id)
			if best < 0.0 or c < best:
				best = c
	return best


## Espera estimada máxima (s) que a compra automática aceita para uma compra de nível melhor que o saldo atual.
const SAVE_WAIT_LEVEL := 75.0
## Idem para recrutar um herói novo (o maior salto de poder do jogo, vale esperar mais).
const SAVE_WAIT_RECRUIT := 300.0
## Enquanto junta dinheiro para um alvo, só compra o que custar até essa fração do preço do alvo ("trocados").
const CRUMB_FRAC := 0.005


## Renda estimada (ouro/s) farmando o estágio da vez; só serve para decidir se vale juntar dinheiro.
static func income_rate(d: Dictionary, m: Dictionary) -> float:
	var st := int(d.stage.cleared)
	if not bool(d.settings.auto_advance):
		st = clampi(int(d.stage.farm), 1, st + 1)
	st = maxi(1, st)
	var enc_secs := clampf(8.0 + 0.4 * float(st), 8.0, 30.0)         # duração típica de um encontro
	return Econ.stage_income(st) * float(m.get("gold", 1.0)) / enc_secs


## Compra automática: recruta e sobe os níveis que dão mais poder por ouro gasto.
## Ela escolhe como um jogador esperto: entre as compras que cabem no saldo OU que ficam alcançáveis em poucos segundos
## de renda (SAVE_WAIT_*), vai na de melhor ganho por custo, e se for uma que ainda não cabe, JUNTA o dinheiro em vez de
## gastar em níveis baratos e inúteis. As opções de nível são +1, +5, +25 e o pacote até o PRÓXIMO MARCO (dano x2 a
## cada 25 níveis). Sem isso o gasto contínuo nunca deixava o saldo chegar nos heróis novos nem nos marcos, e o farm
## offline (que gasta em lotes) ficava muito à frente do jogo online. Devolve quantos níveis/recrutas foram comprados.
static func auto_buy(d: Dictionary, max_ops: int = 30) -> int:
	var bought := 0
	var rate := income_rate(d, Econ.mods(d))
	var ms := int(Econ.MILESTONE)
	for _i in max_ops:
		var did := false
		for id in HeroDefs.IDS:
			if not d.heroes[id].owned and Econ.hero_available(d, id):
				if recruit(d, id):
					bought += 1
					did = true
					auto_team(d)
		var gold := float(d.cur.gold)
		if not did:
			var need := cheapest_pending_recruit(d)
			if need > 0.0 and need - gold <= rate * SAVE_WAIT_RECRUIT:
				break                       # junta dinheiro para o herói novo
		var reach := rate * SAVE_WAIT_LEVEL
		var best_id := ""
		var best_n := 0
		var best_cost := 0.0
		var best_ratio := 0.0
		for id in d.party:
			var lvl := int(d.heroes[id].lvl)
			var v0 := _value(id, lvl)
			for n in [1, 5, 25, ms - lvl % ms]:
				var cost := Econ.bulk_cost(id, lvl, n)
				if cost - gold > reach:
					continue                # longe demais para valer a espera
				var ratio := (_value(id, lvl + n) - v0) / cost
				if ratio > best_ratio:
					best_ratio = ratio
					best_id = id
					best_n = n
					best_cost = cost
		if best_id == "":
			break                           # nada a comprar
		if best_cost > gold:
			# Juntando para o melhor alvo: só gasta "trocados" (compras minúsculas perto do alvo), assim os
			# heróis antigos do time não ficam parados no nível 1 e o alvo quase não atrasa.
			var crumb_cap := best_cost * CRUMB_FRAC
			var c_id := ""
			var c_n := 0
			var c_ratio := 0.0
			for id in d.party:
				var lvl := int(d.heroes[id].lvl)
				var v0 := _value(id, lvl)
				for n in [1, 5]:
					var cost := Econ.bulk_cost(id, lvl, n)
					if cost > gold or cost > crumb_cap:
						continue
					var ratio := (_value(id, lvl + n) - v0) / cost
					if ratio > c_ratio:
						c_ratio = ratio
						c_id = id
						c_n = n
			if c_id == "":
				break
			var kc := upgrade(d, c_id, c_n)
			bought += kc
			if kc <= 0:
				break
			continue
		var k := upgrade(d, best_id, best_n)
		bought += k
		if k <= 0:
			break
	if bought > 0:
		auto_team(d)
	return bought


# ---------------------------------------------------------------- Marmita / relíquias

## Abre `count` Marmitas (já cobradas?) — cobra os Pães de Queijo aqui. Devolve a lista de resultados.
static func open_marmitas(d: Dictionary, count: int, rng: RandomNumberGenerator) -> Array:
	var cost := Econ.MARMITA_COST * count
	if count == 10:
		cost = 270
	if int(d.cur.gems) < cost:
		return []
	d.cur.gems = int(d.cur.gems) - cost
	var m := Econ.mods(d)
	var out: Array = []
	for _i in count:
		var rar := Econ.roll_rarity(d, rng, m)
		var pool := RelicDefs.ids_of(rar)
		var rid: String = pool[rng.randi() % pool.size()]
		var is_new: bool = not d.relics.has(rid)
		if is_new:
			d.relics[rid] = {"lvl": 1}
		else:
			d.relics[rid].lvl = mini(int(d.relics[rid].lvl) + 1, RelicDefs.MAX_LEVEL)
		out.append({"id": rid, "rarity": rar, "new": is_new, "lvl": int(d.relics[rid].lvl)})
	d.stats.marmitas = float(d.stats.marmitas) + count
	return out


# ---------------------------------------------------------------- bênçãos e prestígio

static func buy_bless(d: Dictionary, id: String) -> bool:
	var lvl := int(d.bless.get(id, 0))
	if lvl >= int(BlessDefs.DATA[id].max):
		return false
	var cost := BlessDefs.cost(id, lvl)
	if int(d.cur.bless) < cost:
		return false
	d.cur.bless = int(d.cur.bless) - cost
	d.bless[id] = lvl + 1
	return true


## Pede a Bênção da Vovó: zera estágio/níveis e dá Bênções. Devolve quantas ganhou (0 = não pode).
static func prestige(d: Dictionary) -> int:
	var gain := Econ.bless_gain(d)
	if gain <= 0:
		return 0
	d.cur.bless = int(d.cur.bless) + gain
	d.prestige.earned = float(d.prestige.earned) + gain
	d.prestige.count = int(d.prestige.count) + 1
	d.prestige.run_best = 0
	d.cur.gold = 0.0
	for id in HeroDefs.IDS:
		var h: Dictionary = d.heroes[id]
		if h.owned:
			h.lvl = 1
	var m := Econ.mods(d)
	d.stage.cleared = int(m.start_stage)
	d.stage.farm = 1
	d.stage.blocked_power = 0.0
	d.stage.fail = 0
	return gain
