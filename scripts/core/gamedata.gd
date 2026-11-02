class_name GameData
extends RefCounted
## Estrutura do save. new_data() cria um jogo novo; fix() completa campos que faltam (migração)
## e normaliza tipos (o JSON devolve todo número como float).

const VERSION := 1


static func new_data() -> Dictionary:
	var now := Time.get_unix_time_from_system()
	var heroes := {}
	for id in HeroDefs.IDS:
		heroes[id] = {"owned": id == "neide", "lvl": 1 if id == "neide" else 0}
	return {
		"v": VERSION,
		"created": now,
		"t_last": now,
		"cur": {"gold": 0.0, "gems": 0, "bless": 0},
		"stage": {"cleared": 0, "farm": 1, "blocked_power": 0.0, "fail": 0, "best": 0},
		"heroes": heroes,
		"party": ["neide"],
		"relics": {},
		"pity": {"epic": 0, "legend": 0, "opens": 0},
		"bless": {},
		"prestige": {"count": 0, "earned": 0.0, "run_best": 0},
		"settings": {
			"sfx": 1.0, "music": 0.7, "vibration": true, "shake": true, "lang": "auto",
			"fps30": false, "sci": false, "auto_advance": true, "auto_up": false, "auto_fury": false,
			"auto_team": true, "speed": 1,
		},
		"daily": {"date": "", "streak": 0, "last_claim_day": 0, "mission_date": "", "missions": []},
		"ach": {},
		"stats": {
			"kills": 0.0, "bosses": 0, "gold_total": 0.0, "stages": 0, "taps": 0, "fury": 0,
			"upgrades": 0, "marmitas": 0, "parrots": 0, "crits": 0, "offline_s": 0.0, "shares": 0, "play_s": 0.0,
		},
		"flags": {},
		"fornada": {"kind": "", "start": 0.0, "end": 0.0},
		"codes": [],
	}


## Completa campos ausentes e conserta tipos. Seguro para rodar em qualquer save.
static func fix(d: Dictionary) -> Dictionary:
	_fill(d, new_data())
	d.v = VERSION
	d.t_last = _num(d.t_last)
	d.created = _num(d.created)
	d.cur.gold = _num(d.cur.gold)
	d.cur.gems = int(_num(d.cur.gems))
	d.cur.bless = int(_num(d.cur.bless))
	for id in HeroDefs.IDS:
		var h: Dictionary = d.heroes[id]
		h.owned = bool(h.owned)
		h.lvl = maxi(int(_num(h.lvl)), 0)
		if h.owned and h.lvl < 1:
			h.lvl = 1
	for k in ["cleared", "farm", "fail", "best"]:
		d.stage[k] = maxi(int(_num(d.stage[k])), 0)
	d.stage.farm = maxi(int(d.stage.farm), 1)
	d.stage.blocked_power = _num(d.stage.blocked_power)
	for rid in d.relics.keys():
		if not RelicDefs.DATA.has(rid):
			d.relics.erase(rid)
		else:
			d.relics[rid].lvl = clampi(int(_num(d.relics[rid].lvl)), 1, RelicDefs.MAX_LEVEL)
	for tid in d.bless.keys():
		if not BlessDefs.DATA.has(tid):
			d.bless.erase(tid)
		else:
			d.bless[tid] = clampi(int(_num(d.bless[tid])), 0, int(BlessDefs.DATA[tid].max))
	d.prestige.earned = _num(d.prestige.earned)
	d.prestige.count = int(_num(d.prestige.count))
	d.prestige.run_best = int(_num(d.prestige.run_best))
	for k in ["epic", "legend", "opens"]:
		d.pity[k] = int(_num(d.pity[k]))
	for k in d.stats.keys():
		d.stats[k] = _num(d.stats[k])
	d.fornada.start = _num(d.fornada.start)
	d.fornada.end = _num(d.fornada.end)
	d.daily.streak = int(_num(d.daily.streak))
	Actions.fix_party(d)
	return d


static func _fill(dst: Dictionary, src: Dictionary) -> void:
	for k in src:
		if not dst.has(k):
			var v: Variant = src[k]
			dst[k] = v.duplicate(true) if (v is Dictionary or v is Array) else v
		elif dst[k] is Dictionary and src[k] is Dictionary:
			_fill(dst[k], src[k])


static func _num(v: Variant) -> float:
	var f := float(v)
	if is_nan(f) or is_inf(f):
		return 0.0
	return f
