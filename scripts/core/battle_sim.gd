class_name BattleSim
extends RefCounted
## Simulação de combate sem gráficos. Um "encontro" = um estágio (4 ondas) ou um chefão.
## O jogo usa o dt do frame; o motor offline e os bots usam dt maior. Os eventos para a view
## ficam em `events` (a view limpa a lista a cada frame). Nenhum Node é tocado aqui.

enum Result { RUNNING, WIN, WIPE, TIMEOUT }

const SPAWN_X := 800.0
const SLOT_X: Array[float] = [338.0, 268.0, 198.0, 128.0, 58.0]
const SPACING := 64.0
const MELEE_STOP := 58.0
const RANGED_STOP := 210.0
const SHOOT_X := 690.0          ## quem está além disso ainda não "apareceu" (AoE e toque ignoram)
const MELEE_X := 600.0          ## distância máxima em que um herói corpo a corpo "corre" até o alvo
const RANGED_X := 650.0
const MAX_STEP := 0.1
const FURY_PER_HIT := 0.9
const FURY_PER_KILL := 2.5
const WAVE_HEAL := 0.12
const MAX_ENEMIES := 16


class Unit extends RefCounted:
	var id := 0
	var def_id := ""
	var hero := false
	var role := ""
	var ranged := false
	var slot := 0
	var x := 0.0
	var hp := 1.0
	var max_hp := 1.0
	var atk := 1.0
	var aspd := 1.0
	var crit := 0.0
	var crit_mult := 2.0
	var speed := 0.0
	var stop := 0.0
	var cd := 0.0
	var skill: Dictionary = {}
	var skill_cd := 0.0
	var alive := true
	var boss := false
	var elite := false
	var scale := 1.0
	var gold := 0.0
	var traits: Array = []
	var shield := 0.0
	var shield_t := 0.0
	var stun_t := 0.0
	var burn_dps := 0.0
	var burn_t := 0.0
	var taunt_t := 0.0
	var buff_atk := 1.0
	var buff_aspd := 1.0
	var buff_t := 0.0
	var vuln := 1.0
	var vuln_t := 0.0
	var slow := 1.0
	var slow_t := 0.0
	var weak := 1.0
	var weak_t := 0.0
	var grow := 1.0
	var summon_id := ""
	var summon_every := 0.0
	var summon_t := 0.0
	var age := 0.0


var heroes: Array[Unit] = []
var enemies: Array[Unit] = []
var events: Array = []
var emit_events := true
var result: int = Result.RUNNING
var time := 0.0
var stage := 1
var boss_stage := false
var wave := 0
var waves_total := 4
var wave_delay := 0.3
var time_limit := 0.0
var rng := RandomNumberGenerator.new()
var mods: Dictionary = {}
var fury := 0.0
var fury_t := 0.0
var fury_dur := 8.0
var auto_fury := false
var revive_used := false
var loot := {"gold": 0.0, "kills": 0, "crits": 0}
var summary := {"dmg": 0.0, "taken": 0.0, "crits": 0, "fury_used": 0}
var _next_id := 0


func setup(party: Array, p_stage: int, p_mods: Dictionary, p_seed: int = 0) -> void:
	stage = p_stage
	mods = p_mods
	rng.seed = p_seed if p_seed != 0 else randi()
	boss_stage = WorldDefs.is_boss_stage(stage)
	waves_total = 1 if boss_stage else Econ.WAVES
	time_limit = float(mods.get("boss_time", Econ.BOSS_TIME)) if boss_stage else 0.0
	fury_dur = float(mods.get("fury_dur", 8.0))
	for i in mini(party.size(), SLOT_X.size()):
		heroes.append(_make_hero(party[i], i))


func _new_id() -> int:
	_next_id += 1
	return _next_id


func _make_hero(st: Dictionary, slot: int) -> Unit:
	var u := Unit.new()
	u.id = _new_id()
	u.def_id = st.id
	u.hero = true
	u.role = st.role
	u.ranged = st.ranged
	u.slot = slot
	u.x = SLOT_X[slot]
	u.max_hp = float(st.hp)
	u.hp = u.max_hp
	u.atk = float(st.atk)
	u.aspd = float(st.aspd)
	u.crit = float(st.crit)
	u.crit_mult = float(st.crit_mult)
	u.skill = st.skill.duplicate()
	u.skill_cd = float(u.skill.cd) * 0.5
	u.cd = rng.randf_range(0.2, 1.0)
	return u


func _make_enemy(sp: Dictionary, x: float) -> Unit:
	var u := Unit.new()
	u.id = _new_id()
	u.def_id = sp.id
	u.hero = false
	u.ranged = bool(sp.ranged)
	u.x = x
	u.max_hp = float(sp.hp)
	u.hp = u.max_hp
	u.atk = float(sp.atk)
	u.aspd = float(sp.aspd)
	u.speed = float(sp.speed)
	u.stop = RANGED_STOP if u.ranged else MELEE_STOP
	u.gold = float(sp.gold)
	u.scale = float(sp.scale)
	u.boss = bool(sp.boss)
	u.elite = bool(sp.elite)
	u.traits = sp.traits
	u.cd = rng.randf_range(0.3, 1.2)
	if sp.has("summon"):
		u.summon_id = sp.summon
		u.summon_every = float(sp.summon_every)
		u.summon_t = u.summon_every * 0.6
	if u.traits.has("shield"):
		u.shield = u.max_hp * 0.5
		u.shield_t = 9999.0
	return u


## Atualiza os números dos heróis já em campo (depois de comprar nível, relíquia...), mantendo a % de vida.
func refresh_party(party: Array) -> void:
	for st in party:
		for h in heroes:
			if h.def_id == st.id:
				var frac := h.hp / h.max_hp if h.max_hp > 0.0 else 1.0
				h.max_hp = float(st.hp)
				h.hp = h.max_hp * frac if h.alive else 0.0
				h.atk = float(st.atk)
				h.aspd = float(st.aspd)
				h.crit = float(st.crit)
				h.crit_mult = float(st.crit_mult)
				var cd_left := h.skill_cd
				h.skill = st.skill.duplicate()
				h.skill_cd = minf(cd_left, float(h.skill.cd))


func step(dt: float) -> void:
	if result != Result.RUNNING:
		return
	time += dt
	_status(dt)
	_spawn_logic(dt)
	_move_enemies(dt)
	_heroes_act(dt)
	_enemies_act(dt)
	_fury_tick(dt)
	_cleanup()
	_check_end()


# ---------------------------------------------------------------- consultas

func _front_hero() -> Unit:
	for h in heroes:
		if h.alive:
			return h
	return null


func _front_enemy() -> Unit:
	for e in enemies:
		if e.alive and e.x <= SHOOT_X:
			return e
	return null


## Alvo do herói `h`: o inimigo da frente, se estiver dentro do alcance de engajamento dele.
func _front_enemy_for(h: Unit) -> Unit:
	var e := _front_enemy()
	if e != null and e.x <= (RANGED_X if h.ranged else MELEE_X):
		return e
	return null


func _visible_enemies() -> Array[Unit]:
	var out: Array[Unit] = []
	for e in enemies:
		if e.alive and e.x <= SHOOT_X:
			out.append(e)
	return out


func _any_hurt(frac: float) -> bool:
	for h in heroes:
		if h.alive and h.hp < h.max_hp * frac:
			return true
	return false


func _enemy_target(e: Unit) -> Unit:
	for h in heroes:
		if h.alive and h.taunt_t > 0.0:
			return h
	if e.traits.has("snipe"):
		var best: Unit = null
		for h in heroes:
			if h.alive and (best == null or h.hp / h.max_hp < best.hp / best.max_hp):
				best = h
		return best
	return _front_hero()


# ---------------------------------------------------------------- fases do passo

func _tick_timers(u: Unit, dt: float) -> void:
	if u.stun_t > 0.0:
		u.stun_t -= dt
	if u.burn_t > 0.0:
		u.burn_t -= dt
		if u.burn_t <= 0.0:
			u.burn_dps = 0.0
	if u.taunt_t > 0.0:
		u.taunt_t -= dt
	if u.shield_t > 0.0:
		u.shield_t -= dt
		if u.shield_t <= 0.0:
			u.shield = 0.0
	if u.buff_t > 0.0:
		u.buff_t -= dt
		if u.buff_t <= 0.0:
			u.buff_atk = 1.0
			u.buff_aspd = 1.0
	if u.vuln_t > 0.0:
		u.vuln_t -= dt
		if u.vuln_t <= 0.0:
			u.vuln = 1.0
	if u.slow_t > 0.0:
		u.slow_t -= dt
		if u.slow_t <= 0.0:
			u.slow = 1.0
	if u.weak_t > 0.0:
		u.weak_t -= dt
		if u.weak_t <= 0.0:
			u.weak = 1.0


func _status(dt: float) -> void:
	var regen := float(mods.get("regen", Econ.REGEN))
	for h in heroes:
		if not h.alive:
			continue
		_tick_timers(h, dt)
		if h.hp < h.max_hp:
			h.hp = minf(h.max_hp, h.hp + h.max_hp * regen * dt)
		if h.burn_t > 0.0:
			_hit_hero(h, h.burn_dps * dt, null, true)
	for e in enemies:
		if not e.alive:
			continue
		_tick_timers(e, dt)
		if e.burn_t > 0.0:
			_hit_enemy(e, e.burn_dps * dt, null, false, false, true)


func _spawn_logic(dt: float) -> void:
	if not enemies.is_empty() or wave >= waves_total:
		return
	wave_delay -= dt
	if wave_delay > 0.0:
		return
	var specs := Econ.make_wave(stage, wave, rng)
	var x := SPAWN_X
	for sp in specs:
		enemies.append(_make_enemy(sp, x))
		x += SPACING
	wave += 1
	wave_delay = 0.45
	if wave > 1:
		for h in heroes:
			if h.alive:
				_heal(h, h.max_hp * WAVE_HEAL)
	if emit_events:
		events.append({"t": "wave", "n": wave, "of": waves_total})


func _move_enemies(dt: float) -> void:
	var fh := _front_hero()
	var base_x := fh.x if fh != null else SLOT_X[0]
	var prev_x := -1.0e9
	for e in enemies:
		if not e.alive:
			continue
		var stop_x := base_x + e.stop
		if prev_x > -1.0e8:
			stop_x = maxf(stop_x, prev_x + SPACING)
		if e.stun_t <= 0.0 and e.x > stop_x:
			e.x = maxf(stop_x, e.x - e.speed * e.slow * dt)
		prev_x = e.x


func _heroes_act(dt: float) -> void:
	var fury_on := fury_t > 0.0
	var aspd_mult := 2.0 if fury_on else 1.0
	var haste := 1.0 + float(mods.get("haste", 0.0)) + (0.5 if fury_on else 0.0)
	for h in heroes:
		if not h.alive or h.stun_t > 0.0:
			continue
		h.cd -= dt * h.aspd * h.buff_aspd * aspd_mult
		if h.cd <= 0.0:
			var foe := _front_enemy_for(h)
			if foe != null:
				_hero_attack(h, foe)
				h.cd += 1.0
			else:
				h.cd = 0.0
		_try_skill(h, dt, haste)


func _try_skill(h: Unit, dt: float, haste: float) -> void:
	h.skill_cd -= dt * haste
	if h.skill_cd > 0.0:
		return
	var kind: String = h.skill.kind
	var foe := _front_enemy_for(h)
	if kind == "heal":
		if not _any_hurt(0.85):
			return
	elif foe == null:
		return
	_cast(h, kind, foe)
	h.skill_cd = float(h.skill.cd)


func _hero_attack(h: Unit, foe: Unit) -> void:
	var dmg := h.atk * h.buff_atk * _fury_dmg()
	var crit := rng.randf() < h.crit
	if crit:
		dmg *= h.crit_mult
	_hit_enemy(foe, dmg, h, crit, false)
	_add_fury(FURY_PER_HIT)
	if emit_events:
		events.append({"t": "atk", "src": h.id, "dst": foe.id, "ranged": h.ranged})


func _enemies_act(dt: float) -> void:
	var fh := _front_hero()
	for e in enemies:
		if not e.alive:
			continue
		e.age += dt
		if e.traits.has("grow"):
			e.grow += dt * 0.03
		if e.summon_id != "":
			e.summon_t -= dt
			if e.summon_t <= 0.0 and enemies.size() < MAX_ENEMIES:
				_summon(e)
				e.summon_t = e.summon_every
		if e.stun_t > 0.0 or fh == null:
			continue
		e.cd -= dt * e.aspd
		if e.cd <= 0.0:
			var tgt := _enemy_target(e)
			if tgt != null and e.x - fh.x <= e.stop + 14.0:
				_enemy_attack(e, tgt)
				e.cd += 1.0
			else:
				e.cd = 0.0


func _enemy_attack(e: Unit, tgt: Unit) -> void:
	_hit_hero(tgt, e.atk * e.weak * e.grow, e)
	if e.traits.has("stun") and rng.randf() < 0.2:
		tgt.stun_t = maxf(tgt.stun_t, 1.2)
	if e.traits.has("dot"):
		tgt.burn_dps = maxf(tgt.burn_dps, e.atk * 0.22)
		tgt.burn_t = 3.0
	if emit_events:
		events.append({"t": "eatk", "src": e.id, "dst": tgt.id, "ranged": e.ranged})


func _summon(boss: Unit) -> void:
	var last_x := boss.x
	for o in enemies:
		if o.alive:
			last_x = maxf(last_x, o.x)
	var sp := Econ.enemy_spec(boss.summon_id, stage, false, false)
	sp.hp = float(sp.hp) * 0.6
	var m := _make_enemy(sp, last_x + SPACING)
	enemies.append(m)
	if emit_events:
		events.append({"t": "summon", "id": m.id})


func _cleanup() -> void:
	var i := enemies.size() - 1
	while i >= 0:
		if not enemies[i].alive:
			enemies.remove_at(i)
		i -= 1


func _check_end() -> void:
	var any_hero := false
	for h in heroes:
		if h.alive:
			any_hero = true
			break
	if not any_hero:
		if bool(mods.get("revive", false)) and not revive_used:
			revive_used = true
			for h in heroes:
				h.alive = true
				h.hp = h.max_hp * 0.4
				h.stun_t = 0.0
			if emit_events:
				events.append({"t": "revive"})
			return
		result = Result.WIPE
		if emit_events:
			events.append({"t": "wipe"})
		return
	if wave >= waves_total and enemies.is_empty():
		result = Result.WIN
		if emit_events:
			events.append({"t": "win"})
		return
	if boss_stage and time >= time_limit:
		result = Result.TIMEOUT
		if emit_events:
			events.append({"t": "timeout"})


# ---------------------------------------------------------------- dano, cura, status

func _hit_enemy(e: Unit, dmg: float, src: Unit, crit: bool, is_skill: bool, silent: bool = false) -> void:
	if not e.alive:
		return
	dmg *= e.vuln
	summary.dmg += dmg
	var rest := dmg
	if e.shield > 0.0:
		var absorbed := minf(e.shield, rest)
		e.shield -= absorbed
		rest -= absorbed
	e.hp -= rest
	if crit:
		summary.crits += 1
		loot.crits += 1
	if emit_events and not silent:
		events.append({"t": "hit", "src": src.id if src != null else 0, "dst": e.id, "dmg": dmg, "crit": crit, "skill": is_skill})
	if e.hp <= 0.0:
		_kill_enemy(e)


func _kill_enemy(e: Unit) -> void:
	if not e.alive:
		return
	e.alive = false
	var g := e.gold * float(mods.get("gold", 1.0))
	loot.gold += g
	loot.kills += 1
	_add_fury(FURY_PER_KILL)
	if emit_events:
		events.append({"t": "death", "id": e.id, "boss": e.boss, "elite": e.elite, "gold": g, "x": e.x})
	if e.boss:
		for o in enemies:
			if o.alive and o != e:
				o.alive = false
				if emit_events:
					events.append({"t": "death", "id": o.id, "boss": false, "elite": false, "gold": 0.0, "x": o.x})


func _hit_hero(h: Unit, dmg: float, src: Unit, silent: bool = false) -> void:
	if not h.alive:
		return
	dmg *= 1.0 - float(mods.get("armor", 0.0))
	if h.role == "tank":
		dmg *= 0.85
	summary.taken += dmg
	var rest := dmg
	if h.shield > 0.0:
		var absorbed := minf(h.shield, rest)
		h.shield -= absorbed
		rest -= absorbed
	h.hp -= rest
	if emit_events and not silent:
		events.append({"t": "hhit", "src": src.id if src != null else 0, "dst": h.id, "dmg": dmg})
	if h.hp <= 0.0:
		h.hp = 0.0
		h.alive = false
		if emit_events:
			events.append({"t": "hdeath", "id": h.id})


func _heal(u: Unit, amt: float) -> void:
	if not u.alive:
		return
	var before := u.hp
	u.hp = minf(u.max_hp, u.hp + amt)
	if emit_events and u.hp > before:
		events.append({"t": "heal", "dst": u.id, "amt": u.hp - before})


func _stun(e: Unit, t: float) -> void:
	if t <= 0.0:
		return
	if e.boss:
		t *= 0.3
	e.stun_t = maxf(e.stun_t, t)


func _cast(h: Unit, kind: String, foe: Unit) -> void:
	var s: Dictionary = h.skill
	if emit_events:
		events.append({"t": "skill", "src": h.id, "kind": kind})
	var base := h.atk * h.buff_atk * _fury_dmg()
	match kind:
		"burst":
			var crit := rng.randf() < h.crit
			_hit_enemy(foe, base * float(s.mult) * (h.crit_mult if crit else 1.0), h, crit, true)
			_stun(foe, float(s.get("stun", 0.0)))
		"heal":
			var heal_mult := float(mods.get("heal", 1.0))
			for a in heroes:
				if a.alive:
					_heal(a, (a.max_hp * float(s.get("pct", 0.1)) + h.atk * float(s.mult)) * heal_mult)
		"taunt_burn":
			h.taunt_t = float(s.taunt)
			h.shield = h.max_hp * float(s.shield)
			h.shield_t = float(s.taunt)
			var bd := h.atk * float(s.burn_mult)
			for e in _visible_enemies():
				e.burn_dps = maxf(e.burn_dps, bd)
				e.burn_t = float(s.burn_t)
		"multihit":
			for _i in int(s.hits):
				var tgt := _front_enemy()
				var vis := _visible_enemies()
				if not vis.is_empty():
					tgt = vis[rng.randi() % vis.size()]
				if tgt == null:
					break
				var crit2 := rng.randf() < h.crit
				_hit_enemy(tgt, base * float(s.mult) * (h.crit_mult if crit2 else 1.0), h, crit2, true)
		"aoe_blind":
			for e in _visible_enemies():
				_hit_enemy(e, base * float(s.mult), h, false, true)
				if e.alive:
					e.weak = float(s.weak)
					e.weak_t = float(s.dur)
		"buff_team":
			for a in heroes:
				if a.alive:
					a.buff_atk = 1.0 + float(s.atk_up)
					a.buff_aspd = 1.0 + float(s.aspd_up)
					a.buff_t = float(s.dur)
		"barrage":
			for _i in int(s.n):
				var vis2 := _visible_enemies()
				if vis2.is_empty():
					break
				var t2 := vis2[rng.randi() % vis2.size()]
				_hit_enemy(t2, base * float(s.mult), h, false, true)
		"vuln":
			for e in _visible_enemies():
				e.vuln = 1.0 + float(s.vuln)
				e.vuln_t = float(s.dur)
				e.slow = 1.0 - float(s.slow)
				e.slow_t = float(s.dur)


# ---------------------------------------------------------------- Fúria da Mãe

func _fury_dmg() -> float:
	return 1.5 if fury_t > 0.0 else 1.0


func _add_fury(v: float) -> void:
	if fury_t <= 0.0:
		fury = minf(100.0, fury + v * float(mods.get("fury_gain", 1.0)))


func _fury_tick(dt: float) -> void:
	if fury_t > 0.0:
		fury_t -= dt
		if fury_t <= 0.0:
			fury_t = 0.0
			if emit_events:
				events.append({"t": "fury", "on": false})
	elif auto_fury and fury >= 100.0:
		activate_fury()


func activate_fury() -> bool:
	if fury < 100.0 or fury_t > 0.0 or result != Result.RUNNING:
		return false
	fury = 0.0
	fury_t = fury_dur
	summary.fury_used += 1
	for h in heroes:
		if h.alive:
			h.stun_t = 0.0
			_heal(h, h.max_hp * 0.15)
	if emit_events:
		events.append({"t": "fury", "on": true})
	return true


## "Dedada": toque do jogador causa dano ao inimigo da frente.
func tap(dmg: float) -> bool:
	var foe := _front_enemy()
	if foe == null or result != Result.RUNNING:
		return false
	_hit_enemy(foe, dmg, null, false, false)
	_add_fury(0.25)
	return true


func take_loot() -> Dictionary:
	var l := loot.duplicate()
	loot.gold = 0.0
	loot.kills = 0
	loot.crits = 0
	return l
