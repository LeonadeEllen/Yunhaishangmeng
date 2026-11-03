class_name Battle
## Turn-based hex air combat (King's Bounty / 太阁5 合战 flavour). Pure logic on a plain
## dictionary (`b`) so it saves as JSON and runs headless; the UI drains `b["events"]` to animate.
##
## Hexes use odd-r offset coordinates (col, row). Side 0 = player (starts at the west edge),
## side 1 = enemy (east edge). Every unit is one ship: hull = hit points, crew = boarding
## strength and gunnery, guns = cannon count, move = hexes per round, morale 0-100.

const W := GameData.HEX_W
const H := GameData.HEX_H
const FIRE_RANGE := 3
const ROUND_CAP := 20
const FLEE_MORALE := 20

var b: Dictionary
var rng := RandomNumberGenerator.new()


# ---------------------------------------------------------------- setup

## player / enemy: arrays of unit dicts from `unit()`; hero: {fight, lvl}.
func setup(player: Array, enemy: Array, hero: Dictionary, seed_value: int, difficulty: int = 1) -> void:
	rng.seed = seed_value
	b = {
		"round": 0, "units": [], "terrain": {}, "smoke": {}, "order": [], "cur": -1,
		"cp": 0, "cp_max": 1 + (int(hero.get("fight", 1)) - 1) / 4 + int(hero.get("cp_bonus", 0)), "fight": int(hero.get("fight", 1)),
		"fire_mult": float(hero.get("fire_mult", 1.0)), "board_mult": float(hero.get("board_mult", 1.0)),
		"hero_lvl": int(hero.get("lvl", 1)), "used": [], "focus": -1, "bonus_move": 0,
		"log": [], "events": [], "over": "", "difficulty": difficulty,
	}
	var rows := [3, 2, 4, 1, 5, 0, 6]
	var taken := {}
	var uid := 0
	for side in 2:
		var src: Array = player if side == 0 else enemy
		for src_u in src:
			var u: Dictionary = src_u.duplicate(true)
			u["id"] = uid
			uid += 1
			u["side"] = side
			u["home"] = side
			u["status"] = "ok"
			u["moved"] = 0
			u["acted"] = false
			u["defend"] = false
			u["taken"] = false
			u["half"] = false
			u["morale"] = (70 + 2 * int(b["fight"]) + int(hero.get("morale_bonus", 0))) if side == 0 else (60 + 5 * difficulty)
			var front: bool = u.get("slot", "main") == "van"
			var col := (1 if front else 0) if side == 0 else (W - 2 if front else W - 1)
			var row := -1
			for r in rows:
				if not taken.has("%d,%d" % [col, r]):
					row = r
					break
			if row < 0:
				col = (2 if side == 0 else W - 3)
				for r in rows:
					if not taken.has("%d,%d" % [col, r]):
						row = r
						break
			taken["%d,%d" % [col, row]] = true
			u["col"] = col
			u["row"] = row
			b["units"].append(u)
	_gen_terrain()
	start_round()


## A battle unit built from ship stats (dmg = hull damage share 0-100 carried over from earlier fights).
static func unit(type: String, ship_name: String, mods: Dictionary, slot: String, flag: bool, dmg: int = 0, ship_id: int = -1) -> Dictionary:
	var d: Dictionary = GameData.SHIPS[type]
	var hp_max := int(roundf(float(d["hull"]) * (1.0 + 0.2 * float(mods.get("hull", 0)))))
	var speed := float(d["speed"]) * (1.0 + 0.1 * float(mods.get("sail", 0))) * (0.92 if int(mods.get("hold", 0)) > 0 else 1.0)
	return {
		"ship_id": ship_id, "type": type, "name": ship_name, "sprite": d["sprite"], "flag": flag, "slot": slot,
		"hp_max": hp_max, "hp": maxi(1, int(roundf(float(hp_max) * (1.0 - float(dmg) / 100.0)))),
		"crew_max": int(d["crew"]), "crew": int(d["crew"]),
		"guns": int(d["guns"]) + 2 * int(mods.get("guns", 0)),
		"move": clampi(int(roundf(speed * 3.0)), 2, 5),
		"value": int(d["price"]),
	}


static func power(u: Dictionary) -> int:
	return int(u["hp_max"]) + int(u["guns"]) * 12 + int(u["crew_max"]) * 2


func _gen_terrain() -> void:
	for c in range(2, W - 2):
		for r in H:
			var roll := rng.randf()
			var k := ""
			if roll < 0.08:
				k = "rock"
			elif roll < 0.15:
				k = "storm"
			elif roll < 0.22:
				k = "fog"
			elif roll < 0.29:
				k = "updraft"
			if k != "":
				b["terrain"][key(c, r)] = k


# ---------------------------------------------------------------- hex helpers

static func key(c: int, r: int) -> String:
	return "%d,%d" % [c, r]


static func cube(c: int, r: int) -> Vector3i:
	var x := c - (r - (r & 1)) / 2
	return Vector3i(x, -x - r, r)


static func from_cube(v: Vector3i) -> Vector2i:
	var r := v.z
	return Vector2i(v.x + (r - (r & 1)) / 2, r)


static func dist(c1: int, r1: int, c2: int, r2: int) -> int:
	var a := cube(c1, r1)
	var d := cube(c2, r2)
	return maxi(absi(a.x - d.x), maxi(absi(a.y - d.y), absi(a.z - d.z)))


static func neighbors(c: int, r: int) -> Array:
	var even := [[1, 0], [-1, 0], [0, -1], [-1, -1], [0, 1], [-1, 1]]
	var odd := [[1, 0], [-1, 0], [1, -1], [0, -1], [1, 1], [0, 1]]
	var out := []
	for d in (odd if r & 1 else even):
		var nc: int = c + d[0]
		var nr: int = r + d[1]
		if nc >= 0 and nc < W and nr >= 0 and nr < H:
			out.append(Vector2i(nc, nr))
	return out


func terrain_at(c: int, r: int) -> String:
	var k := key(c, r)
	if b["smoke"].has(k):
		return "fog"
	return b["terrain"].get(k, "")


func unit_at(c: int, r: int) -> Dictionary:
	for u in b["units"]:
		if u["status"] == "ok" and int(u["col"]) == c and int(u["row"]) == r:
			return u
	return {}


func unit_by_id(id: int) -> Dictionary:
	for u in b["units"]:
		if int(u["id"]) == id:
			return u
	return {}


func alive(side: int) -> Array:
	return b["units"].filter(func(u): return u["status"] == "ok" and int(u["side"]) == side)


func flag_of(side: int) -> Dictionary:
	for u in b["units"]:
		if u["flag"] and int(u["home"]) == side:
			return u
	return {}


## Hexes between a and b (exclusive) are free of rock.
func line_clear(c1: int, r1: int, c2: int, r2: int) -> bool:
	var n := dist(c1, r1, c2, r2)
	if n <= 1:
		return true
	var a := cube(c1, r1)
	var d := cube(c2, r2)
	for i in range(1, n):
		var t := float(i) / float(n)
		var x := lerpf(float(a.x), float(d.x), t) + 1e-5
		var y := lerpf(float(a.y), float(d.y), t) + 2e-5
		var z := lerpf(float(a.z), float(d.z), t) - 3e-5
		var rx := roundf(x)
		var ry := roundf(y)
		var rz := roundf(z)
		var dx := absf(rx - x)
		var dy := absf(ry - y)
		var dz := absf(rz - z)
		if dx > dy and dx > dz:
			rx = -ry - rz
		elif dy > dz:
			ry = -rx - rz
		else:
			rz = -rx - ry
		var p := from_cube(Vector3i(int(rx), int(ry), int(rz)))
		if b["terrain"].get(key(p.x, p.y), "") == "rock":
			return false
	return true


## Reachable hexes for a unit with its remaining movement: {"c,r": cost}.
func reachable(u: Dictionary) -> Dictionary:
	var mp := move_left(u)
	var start := key(int(u["col"]), int(u["row"]))
	var best := {start: 0}
	var frontier := [[int(u["col"]), int(u["row"]), 0]]
	while not frontier.is_empty():
		var cur: Array = frontier.pop_front()
		for n in neighbors(cur[0], cur[1]):
			var k := key(n.x, n.y)
			if b["terrain"].get(k, "") == "rock" or not unit_at(n.x, n.y).is_empty():
				continue
			var cost: int = cur[2] + (0 if b["terrain"].get(k, "") == "updraft" else 1)
			if cost > mp or (best.has(k) and best[k] <= cost):
				continue
			best[k] = cost
			frontier.append([n.x, n.y, cost])
	best.erase(start)
	return best


func move_left(u: Dictionary) -> int:
	return maxi(0, int(u["move"]) + int(b["bonus_move"] if int(u["side"]) == 0 else 0) - int(u["moved"]))


func targets(u: Dictionary) -> Array:
	var out := []
	if int(u["guns"]) <= 0:
		return out
	for e in alive(1 - int(u["side"])):
		var d := dist(int(u["col"]), int(u["row"]), int(e["col"]), int(e["row"]))
		if d <= FIRE_RANGE and line_clear(int(u["col"]), int(u["row"]), int(e["col"]), int(e["row"])):
			out.append(e)
	return out


func boardable(u: Dictionary) -> Array:
	if int(u["crew"]) <= 0:
		return []
	return alive(1 - int(u["side"])).filter(func(e): return dist(int(u["col"]), int(u["row"]), int(e["col"]), int(e["row"])) == 1)


func can_retreat(u: Dictionary) -> bool:
	return (int(u["col"]) <= 1) if int(u["side"]) == 0 else (int(u["col"]) >= W - 2)


# ---------------------------------------------------------------- rounds & turns

func start_round() -> void:
	b["round"] = int(b["round"]) + 1
	b["cp"] = b["cp_max"]
	b["used"] = []
	b["focus"] = -1
	b["bonus_move"] = 0
	for k in b["smoke"].keys():
		b["smoke"][k] = int(b["smoke"][k]) - 1
		if int(b["smoke"][k]) <= 0:
			b["smoke"].erase(k)
	var order := []
	for u in b["units"]:
		if u["status"] == "ok":
			u["moved"] = 0
			u["acted"] = false
			u["defend"] = false
			order.append(u)
	order.sort_custom(func(x, y):
		if int(x["move"]) != int(y["move"]):
			return int(x["move"]) > int(y["move"])
		if int(x["side"]) != int(y["side"]):
			return int(x["side"]) < int(y["side"])
		return int(x["id"]) < int(y["id"]))
	b["order"] = order.map(func(u): return int(u["id"]))
	b["cur"] = -1
	_log("第 %d 回合" % int(b["round"]))
	if int(b["round"]) > ROUND_CAP:
		b["over"] = "withdraw"
		_log("云海起雾，双方失去了对方的踪影。")
		_event({"kind": "end"})


## The unit whose turn it is ({} when the battle is over).
func current() -> Dictionary:
	if b["over"] != "" or int(b["cur"]) < 0 or int(b["cur"]) >= b["order"].size():
		return {}
	return unit_by_id(int(b["order"][int(b["cur"])]))


## Advance to the next living unit; returns it (enemy turns are not played here).
func next_unit() -> Dictionary:
	if b["over"] != "":
		return {}
	var cur := current()
	if not cur.is_empty():
		_end_of_turn(cur)
		if b["over"] != "":
			return {}
	while true:
		b["cur"] = int(b["cur"]) + 1
		if int(b["cur"]) >= b["order"].size():
			start_round()
			if b["over"] != "":
				return {}
			continue
		var u := unit_by_id(int(b["order"][int(b["cur"])]))
		if u.is_empty() or u["status"] != "ok":
			continue
		_start_of_turn(u)
		if u["status"] != "ok" or u["acted"]:
			continue
		return u
	return {}


func _start_of_turn(u: Dictionary) -> void:
	var foes := 0
	for n in neighbors(int(u["col"]), int(u["row"])):
		var o := unit_at(n.x, n.y)
		if not o.is_empty() and int(o["side"]) != int(u["side"]):
			foes += 1
	if foes >= 2:
		_morale(u, -10)
		_log("%s 被包夹，士气下降。" % u["name"])
	if int(u["morale"]) < FLEE_MORALE:
		_log("%s 士气崩溃，掉头逃跑！" % u["name"])
		_flee_step(u)
		u["acted"] = true
		_check_end()


func _end_of_turn(u: Dictionary) -> void:
	if u["status"] != "ok":
		return
	if terrain_at(int(u["col"]), int(u["row"])) == "storm":
		_damage(u, 6, {}, "雷云")
	_check_end()


## Play the current unit with the built-in captain (enemy ships, or auto-battle).
func ai_turn() -> void:
	var u := current()
	if u.is_empty():
		return
	if int(u["side"]) == 0:
		_ai_tactics()
	var foes := alive(1 - int(u["side"]))
	if foes.is_empty():
		u["acted"] = true
		return
	var fb := _fight_bonus(u)
	var best := {"score": -1.0}
	var reach := reachable(u)
	reach[key(int(u["col"]), int(u["row"]))] = 0
	for k in reach:
		var parts: PackedStringArray = k.split(",")
		var c := int(parts[0])
		var r := int(parts[1])
		for e in foes:
			var d := dist(c, r, int(e["col"]), int(e["row"]))
			if d == 1:
				var att := float(u["crew"]) * fb
				var def := float(e["crew"]) * (1.3 if e["defend"] else 1.0) * _fight_bonus(e)
				if att >= def * 1.2 or (int(u["guns"]) == 0 and att >= def * 0.95):
					var sc := 120.0 + float(e["value"]) / 200.0 + (40.0 if e["flag"] else 0.0) - float(reach[k]) * 2.0
					if sc > best["score"]:
						best = {"score": sc, "hex": [c, r], "act": "board", "target": int(e["id"])}
			if int(u["guns"]) > 0 and d <= FIRE_RANGE and line_clear(c, r, int(e["col"]), int(e["row"])):
				var dmg := _fire_estimate(u, e, d)
				var sc2 := minf(1.0, float(dmg) / maxf(1.0, float(e["hp"]))) * 100.0 + (25.0 if e["flag"] else 0.0) - float(reach[k]) * 1.5 - float(d) * 3.0
				if terrain_at(c, r) == "storm":
					sc2 -= 30.0
				if sc2 > best["score"]:
					best = {"score": sc2, "hex": [c, r], "act": "fire", "target": int(e["id"])}
	if best["score"] >= 0.0:
		var hx: Array = best["hex"]
		if hx[0] != int(u["col"]) or hx[1] != int(u["row"]):
			move_to(int(u["id"]), hx[0], hx[1])
		if best["act"] == "board":
			board(int(u["id"]), int(best["target"]))
		else:
			fire(int(u["id"]), int(best["target"]))
		return
	# nothing in reach: close in (or patch up when badly hurt)
	if float(u["hp"]) < float(u["hp_max"]) * 0.4:
		repair(int(u["id"]))
		return
	var near: Dictionary = foes[0]
	for e in foes:
		if dist(int(u["col"]), int(u["row"]), int(e["col"]), int(e["row"])) < dist(int(u["col"]), int(u["row"]), int(near["col"]), int(near["row"])):
			near = e
	var bk := ""
	var bd := dist(int(u["col"]), int(u["row"]), int(near["col"]), int(near["row"]))
	for k in reach:
		var parts: PackedStringArray = k.split(",")
		var c := int(parts[0])
		var r := int(parts[1])
		var d := dist(c, r, int(near["col"]), int(near["row"]))
		if terrain_at(c, r) == "storm":
			d += 2
		if d < bd:
			bd = d
			bk = k
	if bk != "":
		var parts2: PackedStringArray = bk.split(",")
		move_to(int(u["id"]), int(parts2[0]), int(parts2[1]))
	var adj := boardable(u)
	if not adj.is_empty() and int(u["guns"]) == 0:
		board(int(u["id"]), int(adj[0]["id"]))
	else:
		defend(int(u["id"]))


func _ai_tactics() -> void:
	if int(b["cp"]) <= 0:
		return
	var foes := alive(1)
	if foes.is_empty():
		return
	if tactic_ok("focus") and int(b["focus"]) < 0:
		var t: Dictionary = foes[0]
		for e in foes:
			if e["flag"]:
				t = e
		tactic("focus", int(t["id"]))
	var low := 0.0
	var mine := alive(0)
	for u in mine:
		low += float(u["morale"])
	if int(b["cp"]) > 0 and tactic_ok("rally") and not mine.is_empty() and low / float(mine.size()) < 45.0:
		tactic("rally", -1)


# ---------------------------------------------------------------- actions (return {ok, msg})

func move_to(uid: int, c: int, r: int) -> Dictionary:
	var u := unit_by_id(uid)
	if u.is_empty() or u["status"] != "ok" or u["acted"]:
		return _fail("这艘船已经行动过了。")
	var reach := reachable(u)
	var k := key(c, r)
	if not reach.has(k):
		return _fail("走不到那里。")
	var from := [int(u["col"]), int(u["row"])]
	u["col"] = c
	u["row"] = r
	u["moved"] = int(u["moved"]) + int(reach[k])
	_event({"kind": "move", "uid": uid, "from": from, "to": [c, r]})
	return {"ok": true, "msg": ""}


func fire(uid: int, tid: int) -> Dictionary:
	var u := unit_by_id(uid)
	var t := unit_by_id(tid)
	if u.is_empty() or t.is_empty() or u["status"] != "ok" or u["acted"]:
		return _fail("这艘船已经行动过了。")
	if int(u["guns"]) <= 0:
		return _fail("%s 没有炮。" % u["name"])
	var d := dist(int(u["col"]), int(u["row"]), int(t["col"]), int(t["row"]))
	if t["status"] != "ok" or int(t["side"]) == int(u["side"]) or d > FIRE_RANGE:
		return _fail("目标不在射程内。")
	if not line_clear(int(u["col"]), int(u["row"]), int(t["col"]), int(t["row"])):
		return _fail("浮岩挡住了炮火。")
	var dmg := _fire_estimate(u, t, d, rng.randf_range(0.85, 1.15))
	u["acted"] = true
	_log("%s 炮击 %s，造成 %d 点伤害。" % [u["name"], t["name"], dmg])
	_event({"kind": "fire", "uid": uid, "tid": tid, "dmg": dmg})
	_damage(t, dmg, u, "炮击")
	_check_end()
	return {"ok": true, "msg": ""}


func board(uid: int, tid: int) -> Dictionary:
	var u := unit_by_id(uid)
	var t := unit_by_id(tid)
	if u.is_empty() or t.is_empty() or u["status"] != "ok" or u["acted"]:
		return _fail("这艘船已经行动过了。")
	if t["status"] != "ok" or int(t["side"]) == int(u["side"]) or dist(int(u["col"]), int(u["row"]), int(t["col"]), int(t["row"])) != 1:
		return _fail("要贴到敌船旁边才能接舷。")
	if int(u["crew"]) <= 0:
		return _fail("船员已经打光了。")
	u["acted"] = true
	var att := float(u["crew"]) * _fight_bonus(u) * rng.randf_range(0.8, 1.2) * (float(b.get("board_mult", 1.0)) if int(u["home"]) == 0 else 1.0)
	var def := float(t["crew"]) * _fight_bonus(t) * (1.3 if t["defend"] else 1.0) * rng.randf_range(0.8, 1.2)
	var win := att >= def
	var u_loss := int(ceil(float(u["crew"]) * (0.15 if win else 0.3)))
	var t_loss := int(ceil(float(t["crew"]) * (0.3 if win else 0.15)))
	u["crew"] = maxi(0, int(u["crew"]) - u_loss)
	t["crew"] = maxi(0, int(t["crew"]) - t_loss)
	var captured := win and (att >= def * 1.25 or int(t["crew"]) <= int(t["crew_max"]) / 4)
	_event({"kind": "board", "uid": uid, "tid": tid, "win": win, "captured": captured})
	if captured:
		_log("%s 接舷俘获了 %s！" % [u["name"], t["name"]])
		t["side"] = int(u["side"])
		t["taken"] = true
		t["acted"] = true
		t["defend"] = false
		t["morale"] = 50
		t["crew"] = maxi(1, int(t["crew"]))
		for o in alive(1 - int(u["side"])):
			_morale(o, -10)
		for o in alive(int(u["side"])):
			_morale(o, 8)
	else:
		_log("%s 与 %s 接舷血战，%s。" % [u["name"], t["name"], "攻方占上风" if win else "守方顶住了"])
		_morale(t if win else u, -15)
		_morale(u if win else t, 5)
	_check_end()
	return {"ok": true, "msg": ""}


func repair(uid: int) -> Dictionary:
	var u := unit_by_id(uid)
	if u.is_empty() or u["status"] != "ok" or u["acted"]:
		return _fail("这艘船已经行动过了。")
	var heal := mini(int(u["hp_max"]) / 4, int(u["hp_max"]) - int(u["hp"]))
	u["hp"] = int(u["hp"]) + heal
	u["acted"] = true
	_log("%s 修补船体，恢复 %d 点耐久。" % [u["name"], heal])
	_event({"kind": "repair", "uid": uid, "heal": heal})
	return {"ok": true, "msg": ""}


func defend(uid: int) -> Dictionary:
	var u := unit_by_id(uid)
	if u.is_empty() or u["status"] != "ok" or u["acted"]:
		return _fail("这艘船已经行动过了。")
	u["defend"] = true
	u["acted"] = true
	_morale(u, 5)
	_event({"kind": "defend", "uid": uid})
	return {"ok": true, "msg": ""}


func wait(uid: int) -> Dictionary:
	var u := unit_by_id(uid)
	if u.is_empty() or u["status"] != "ok" or u["acted"]:
		return _fail("这艘船已经行动过了。")
	u["acted"] = true
	return {"ok": true, "msg": ""}


func retreat(uid: int) -> Dictionary:
	var u := unit_by_id(uid)
	if u.is_empty() or u["status"] != "ok" or u["acted"]:
		return _fail("这艘船已经行动过了。")
	if not can_retreat(u):
		return _fail("要先退到己方边缘才能撤离战场。")
	u["acted"] = true
	u["status"] = "fled"
	_log("%s 撤出了战场。" % u["name"])
	_event({"kind": "flee", "uid": uid})
	_check_end()
	return {"ok": true, "msg": ""}


func tactic_ok(id: String) -> bool:
	return int(b["cp"]) > 0 and int(b["hero_lvl"]) >= int(GameData.TACTICS[id]["lvl"]) and not id in b["used"]


## Protagonist's command; target = unit id for enemy/ally tactics, -1 otherwise.
func tactic(id: String, target: int) -> Dictionary:
	if b["over"] != "":
		return _fail("战斗已经结束。")
	if not GameData.TACTICS.has(id):
		return _fail("没有这个战术。")
	if int(b["hero_lvl"]) < int(GameData.TACTICS[id]["lvl"]):
		return _fail("主角 %d 级才能使用「%s」。" % [int(GameData.TACTICS[id]["lvl"]), GameData.TACTICS[id]["name"]])
	if int(b["cp"]) <= 0:
		return _fail("本回合的指挥点用完了。")
	if id in b["used"]:
		return _fail("每个战术每回合只能用一次。")
	var t := unit_by_id(target)
	var need: String = GameData.TACTICS[id]["target"]
	if need == "enemy" and (t.is_empty() or t["status"] != "ok" or int(t["side"]) != 1):
		return _fail("请选择一艘敌船。")
	if need == "ally" and (t.is_empty() or t["status"] != "ok" or int(t["side"]) != 0):
		return _fail("请选择一艘我方船。")
	var fl := flag_of(0)
	match id:
		"focus":
			b["focus"] = target
			_log("指挥：集火 %s！" % t["name"])
		"rally":
			for u in alive(0):
				_morale(u, 25)
			_log("指挥：鼓舞，全军士气大振。")
		"wind":
			b["bonus_move"] = int(b["bonus_move"]) + 2
			_log("指挥：顺风，全军加速。")
		"smoke":
			b["smoke"][key(int(t["col"]), int(t["row"]))] = 3
			_log("指挥：烟幕掩护 %s。" % t["name"])
		"fire":
			if fl.is_empty() or dist(int(fl["col"]), int(fl["row"]), int(t["col"]), int(t["row"])) > FIRE_RANGE:
				return _fail("火攻只能打旗舰 3 格内的敌船。")
			_log("指挥：火攻！")
			var hit := [t]
			for n in neighbors(int(t["col"]), int(t["row"])):
				var o := unit_at(n.x, n.y)
				if not o.is_empty() and int(o["side"]) == 1:
					hit.append(o)
			for o in hit:
				_damage(o, 12, {}, "火攻")
		"lure":
			if fl.is_empty():
				return _fail("旗舰不在场。")
			for i in 2:
				var bestk := Vector2i(-1, -1)
				var bd := dist(int(t["col"]), int(t["row"]), int(fl["col"]), int(fl["row"]))
				for n in neighbors(int(t["col"]), int(t["row"])):
					if b["terrain"].get(key(n.x, n.y), "") == "rock" or not unit_at(n.x, n.y).is_empty():
						continue
					var d := dist(n.x, n.y, int(fl["col"]), int(fl["row"]))
					if d < bd:
						bd = d
						bestk = n
				if bestk.x >= 0:
					_event({"kind": "move", "uid": int(t["id"]), "from": [int(t["col"]), int(t["row"])], "to": [bestk.x, bestk.y]})
					t["col"] = bestk.x
					t["row"] = bestk.y
			_morale(t, -10)
			_log("指挥：诱敌，%s 被引了过来。" % t["name"])
	b["cp"] = int(b["cp"]) - 1
	b["used"].append(id)
	_event({"kind": "tactic", "id": id, "target": target})
	_check_end()
	return {"ok": true, "msg": ""}


# ---------------------------------------------------------------- internals

func _fight_bonus(u: Dictionary) -> float:
	if int(u["home"]) == 0:
		return 1.0 + 0.08 * float(int(b["fight"]) - 1)
	return 0.9 + 0.1 * float(b["difficulty"])


func _fire_estimate(u: Dictionary, t: Dictionary, d: int, roll: float = 1.0) -> int:
	var base := float(u["guns"]) * 4.0 * clampf(float(u["crew"]) / maxf(1.0, float(u["crew_max"])), 0.4, 1.0) * _fight_bonus(u)
	base *= [1.0, 1.0, 0.9, 0.7][clampi(d, 0, 3)]
	if terrain_at(int(t["col"]), int(t["row"])) == "fog":
		base *= 0.65
	if t["defend"]:
		base *= 0.5
	if int(u["side"]) == 0 and int(b["focus"]) == int(t["id"]):
		base *= 1.5
	if int(u["home"]) == 0:
		base *= float(b.get("fire_mult", 1.0))
	return maxi(1, int(roundf(base * roll)))


func _damage(t: Dictionary, dmg: int, by: Dictionary, cause: String) -> void:
	if t["status"] != "ok":
		return
	t["hp"] = int(t["hp"]) - dmg
	if cause == "炮击":
		t["crew"] = maxi(0, int(t["crew"]) - int(ceil(float(dmg) / 6.0)))
	_morale(t, -8)
	if not t["half"] and float(t["hp"]) < float(t["hp_max"]) * 0.5:
		t["half"] = true
		_morale(t, -15)
	if t["flag"]:
		for o in alive(int(t["side"])):
			if int(o["id"]) != int(t["id"]):
				_morale(o, -5)
	if int(t["hp"]) <= 0:
		t["hp"] = 0
		t["status"] = "sunk"
		_log("%s 被%s击沉！" % [t["name"], cause])
		_event({"kind": "sunk", "uid": int(t["id"])})
		for o in alive(int(t["side"])):
			_morale(o, -10)
		for o in alive(1 - int(t["side"])):
			_morale(o, 10)


func _morale(u: Dictionary, delta: int) -> void:
	u["morale"] = clampi(int(u["morale"]) + delta, 0, 100)


func _flee_step(u: Dictionary) -> void:
	var edge := 0 if int(u["side"]) == 0 else W - 1
	var reach := reachable(u)
	var bestk := ""
	var bd := absi(int(u["col"]) - edge)
	for k in reach:
		var parts: PackedStringArray = k.split(",")
		var d := absi(int(parts[0]) - edge)
		if d < bd:
			bd = d
			bestk = k
	if bestk != "":
		var parts2: PackedStringArray = bestk.split(",")
		move_to(int(u["id"]), int(parts2[0]), int(parts2[1]))
		u["acted"] = false
	if can_retreat(u):
		u["status"] = "fled"
		_log("%s 逃离了战场。" % u["name"])
		_event({"kind": "flee", "uid": int(u["id"])})


func _check_end() -> void:
	if b["over"] != "":
		return
	var ef := flag_of(1)
	var pf := flag_of(0)
	var res := ""
	if not pf.is_empty() and (pf["status"] == "sunk" or (pf["status"] == "ok" and int(pf["side"]) != 0)):
		res = "loss"
	elif alive(1).is_empty() or (not ef.is_empty() and (ef["status"] == "sunk" or (ef["status"] == "ok" and int(ef["side"]) == 0))):
		res = "win"
	elif alive(0).is_empty():
		res = "withdraw"
	if res != "":
		b["over"] = res
		_log({"win": "敌船溃散，我方大胜！", "loss": "旗舰失守，船队溃败。", "withdraw": "我方全部撤出了战场。"}[res])
		_event({"kind": "end"})


func _log(text: String) -> void:
	b["log"].append(text)
	if b["log"].size() > 60:
		b["log"].pop_front()


func _event(e: Dictionary) -> void:
	b["events"].append(e)


func _fail(msg: String) -> Dictionary:
	return {"ok": false, "msg": msg}


## Resolve the whole fight with captains on both sides (bots, tests, the 自动战斗 button).
func auto_play() -> String:
	var guard := 0
	if current().is_empty():
		next_unit()
	while b["over"] == "" and guard < 2000:
		guard += 1
		if current().is_empty():
			next_unit()
			continue
		ai_turn()
		next_unit()
	if b["over"] == "":
		b["over"] = "withdraw"
	return b["over"]
