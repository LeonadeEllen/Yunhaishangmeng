class_name Sim
extends RefCounted
## Whole-game simulation. Pure logic: no nodes, so it runs headless in tests.
## All state lives in `s` (JSON-safe Dictionary) so save/load is a straight dump.

signal message(text: String, kind: String)     # kind: info / good / bad / major
signal game_over(result: Dictionary)


const NEUTRAL_EQ := 180.0
const REVERT := 0.06
const MAKE_EQ := 2.0
const WANT_EQ := 0.5

var s: Dictionary = {}
var rng := RandomNumberGenerator.new()


# ---------------------------------------------------------------- setup

func pid() -> String:
	return s.get("player", "lamp")


func perk(hid: String) -> String:
	return GameData.HOUSES[hid].get("perk", "")


func new_game(seed_value: int = 0, player: String = "lamp", difficulty: int = 1) -> void:
	if seed_value == 0:
		seed_value = int(Time.get_unix_time_from_system())
	rng.seed = seed_value
	s = {
		"seed": seed_value, "day": 0, "over": null, "next_ship_id": 1,
		"ports": {}, "houses": {}, "ships": [], "intel": {}, "log": [],
		"event": null, "story": 0, "stats": {"trades": 0, "profit": 0, "best_trade": 0},
		"tutorial": 0, "player": player, "fashion": null, "difficulty": difficulty,
	}
	for pid in GameData.PORT_IDS:
		var p: Dictionary = GameData.PORTS[pid]
		var m := {}
		for g in GameData.GOOD_IDS:
			var eq := NEUTRAL_EQ
			if g in p["make"]:
				eq = NEUTRAL_EQ * MAKE_EQ
			elif g in p["want"]:
				eq = NEUTRAL_EQ * WANT_EQ
			if g in p["make"] or g in p["want"]:
				eq *= rng.randf_range(0.8, 1.25)   # every run has its own strong and weak routes
			m[g] = {"stock": eq * rng.randf_range(0.85, 1.15), "eq": eq}
		s["ports"][pid] = {"market": m, "workshops": {}}
	for hid in GameData.HOUSE_IDS:
		var h: Dictionary = GameData.HOUSES[hid]
		s["houses"][hid] = {
			"gold": float(h["gold"]), "debt": 0.0, "crisis": 0, "bankrupt": false,
			"lh": {"stage": 0, "building": false, "end": 0, "mats": {}},
			"month_in": 0.0, "month_out": 0.0, "last_net": 0.0,
		}
		_add_ship(hid, "freighter", h["home"], "飞云号" if hid == pid() else "")
	for pid in GameData.PORT_IDS:
		s["intel"][pid] = null
	_update_intel(GameData.HOUSES[pid()]["home"])


func _add_ship(hid: String, type: String, port: String, ship_name: String = "") -> Dictionary:
	var id: int = s["next_ship_id"]
	s["next_ship_id"] = id + 1
	if ship_name == "":
		ship_name = ["飞云号", "逐霞号", "听风号", "鸣鹤号", "望舒号", "长庚号", "照夜号", "揽月号"][id % 8]
	var sh := {
		"id": id, "owner": hid, "type": type, "name": ship_name, "port": port,
		"from": port, "to": "", "depart": 0, "arrive": 0, "cargo": {}, "route": null,
		"flagship": hid == pid() and _ships_of(hid).is_empty(),
	}
	s["ships"].append(sh)
	return sh


# ---------------------------------------------------------------- queries

func house(hid: String = "") -> Dictionary:
	if hid == "":
		hid = pid()
	return s["houses"][hid]


func ship(id: int) -> Dictionary:
	for sh in s["ships"]:
		if sh["id"] == id:
			return sh
	return {}


func _ships_of(hid: String) -> Array:
	return s["ships"].filter(func(x): return x["owner"] == hid)


func ships_of(hid: String = "") -> Array:
	if hid == "":
		hid = pid()
	return _ships_of(hid)


func flagship() -> Dictionary:
	for sh in _ships_of(pid()):
		if sh["flagship"]:
			return sh
	var all := _ships_of(pid())
	return all[0] if not all.is_empty() else {}


func docked(sh: Dictionary) -> bool:
	return sh["to"] == ""


func cargo_used(sh: Dictionary) -> int:
	var n := 0
	for g in sh["cargo"]:
		n += int(sh["cargo"][g]["qty"])
	return n


func cargo_cap(sh: Dictionary) -> int:
	return int(GameData.SHIPS[sh["type"]]["cargo"])


func price_factor(stock: float, eq_ref: float = NEUTRAL_EQ) -> float:
	return clampf(pow(eq_ref / maxf(stock, 1.0), 0.7), 0.4, 2.8)


func unit_price(port: String, good: String, stock_override: float = -1.0) -> float:
	var st: float = s["ports"][port]["market"][good]["stock"] if stock_override < 0.0 else stock_override
	return float(GameData.GOODS[good]["base"]) * price_factor(st)


func _discount(hid: String, port: String) -> float:
	var lvl: int = int(s["ports"][port]["workshops"].get(hid, 0))
	return 1.0 - 0.025 * lvl


func buy_price(port: String, good: String, hid: String = "") -> int:
	if hid == "":
		hid = pid()
	return int(roundf(unit_price(port, good) * 1.06 * _discount(hid, port)))


const AI_BONUS := [0.98, 1.025, 1.06]   # rivals' selling edge per difficulty (easy / normal / hard)


func _sell_mult(hid: String) -> float:
	var m := 0.94 * (1.05 if perk(hid) == "sell" else 1.0)
	if hid != pid():
		m *= AI_BONUS[clampi(int(s.get("difficulty", 1)), 0, 2)]
	return m


func sell_price(port: String, good: String, hid: String = "") -> int:
	if hid == "":
		hid = pid()
	return int(roundf(unit_price(port, good) * _sell_mult(hid)))


## Quote buying `qty` units: price climbs as stock drops. Returns {qty, cost}.
func quote_buy(port: String, good: String, qty: int, hid: String = "", budget: float = INF) -> Dictionary:
	if hid == "":
		hid = pid()
	var st: float = s["ports"][port]["market"][good]["stock"]
	var cost := 0.0
	var n := 0
	var disc := _discount(hid, port)
	while n < qty and st > 1.0:
		var p := roundf(unit_price(port, good, st) * 1.06 * disc)
		if cost + p > budget:
			break
		cost += p
		st -= 1.0
		n += 1
	return {"qty": n, "cost": int(cost)}


func quote_sell(port: String, good: String, qty: int, hid: String = "") -> Dictionary:
	if hid == "":
		hid = pid()
	var mult := _sell_mult(hid)
	var st: float = s["ports"][port]["market"][good]["stock"]
	var rev := 0.0
	for i in qty:
		rev += roundf(unit_price(port, good, st) * mult)
		st += 1.0
	return {"qty": qty, "revenue": int(rev)}


func fuel_cost(type: String, from: String, to: String) -> int:
	return GameData.travel_days(from, to, type) * int(GameData.SHIPS[type]["fuel_day"]) * GameData.FUEL_PRICE


func net_worth(hid: String = "") -> float:
	if hid == "":
		hid = pid()
	var h := house(hid)
	var v: float = h["gold"] - h["debt"]
	for sh in _ships_of(hid):
		v += float(GameData.SHIPS[sh["type"]]["price"]) * 0.6
		for g in sh["cargo"]:
			v += float(sh["cargo"][g]["qty"]) * float(sh["cargo"][g]["cost"])
	for pid in GameData.PORT_IDS:
		var lvl: int = int(s["ports"][pid]["workshops"].get(hid, 0))
		for i in lvl:
			v += GameData.WORKSHOP_COST[i] * 0.5
	return v


func loan_limit(hid: String = "") -> float:
	if hid == "":
		hid = pid()
	return maxf(10000.0, net_worth(hid) * 0.5 + house(hid)["debt"])


func ship_pos(sh: Dictionary) -> Vector2:
	if docked(sh):
		return GameData.PORTS[sh["port"]]["pos"]
	var a: Vector2 = GameData.PORTS[sh["from"]]["pos"]
	var b: Vector2 = GameData.PORTS[sh["to"]]["pos"]
	var span := maxf(1.0, float(sh["arrive"] - sh["depart"]))
	var t := clampf((float(s["day"]) + float(s.get("frac", 0.0)) - float(sh["depart"])) / span, 0.0, 1.0)
	return a.lerp(b, t)


# ---------------------------------------------------------------- actions (return {ok, msg})

func buy(ship_id: int, good: String, qty: int) -> Dictionary:
	var sh := ship(ship_id)
	if sh.is_empty() or not docked(sh):
		return _fail("飞艇不在港口。")
	var h := house(sh["owner"])
	qty = mini(qty, cargo_cap(sh) - cargo_used(sh))
	if qty <= 0:
		return _fail("货舱已满。")
	var q := quote_buy(sh["port"], good, qty, sh["owner"], h["gold"])
	if q["qty"] <= 0:
		return _fail("金币不足。")
	h["gold"] -= q["cost"]
	h["month_out"] += q["cost"]
	s["ports"][sh["port"]]["market"][good]["stock"] -= q["qty"]
	var c: Dictionary = sh["cargo"].get(good, {"qty": 0, "cost": 0.0})
	var total: float = float(c["qty"]) * float(c["cost"]) + q["cost"]
	c["qty"] = int(c["qty"]) + int(q["qty"])
	c["cost"] = total / float(c["qty"])
	sh["cargo"][good] = c
	if sh["owner"] == pid():
		_update_intel(sh["port"])
	return {"ok": true, "msg": "买入 %s ×%d，花费 %d 金。" % [GameData.good_name(good), q["qty"], q["cost"]], "qty": q["qty"], "cost": q["cost"]}


func sell(ship_id: int, good: String, qty: int) -> Dictionary:
	var sh := ship(ship_id)
	if sh.is_empty() or not docked(sh):
		return _fail("飞艇不在港口。")
	var c: Dictionary = sh["cargo"].get(good, {})
	if c.is_empty():
		return _fail("货舱里没有这种货。")
	qty = mini(qty, int(c["qty"]))
	if qty <= 0:
		return _fail("数量无效。")
	var q := quote_sell(sh["port"], good, qty, sh["owner"])
	var h := house(sh["owner"])
	h["gold"] += q["revenue"]
	h["month_in"] += q["revenue"]
	s["ports"][sh["port"]]["market"][good]["stock"] += qty
	var profit := int(q["revenue"] - float(c["cost"]) * qty)
	c["qty"] = int(c["qty"]) - qty
	if c["qty"] <= 0:
		sh["cargo"].erase(good)
	if sh["owner"] == pid():
		s["stats"]["trades"] += 1
		s["stats"]["profit"] += profit
		s["stats"]["best_trade"] = maxi(int(s["stats"]["best_trade"]), profit)
		_update_intel(sh["port"])
	return {"ok": true, "msg": "卖出 %s ×%d，收入 %d 金（利润 %+d）。" % [GameData.good_name(good), qty, q["revenue"], profit], "profit": profit, "revenue": q["revenue"]}


func depart(ship_id: int, dest: String) -> Dictionary:
	var sh := ship(ship_id)
	if sh.is_empty() or not docked(sh):
		return _fail("飞艇不在港口。")
	if dest == sh["port"] or not GameData.PORTS.has(dest):
		return _fail("目的地无效。")
	var h := house(sh["owner"])
	var fc := fuel_cost(sh["type"], sh["port"], dest)
	if h["gold"] < fc:
		return _fail("燃晶费用 %d 金，金币不足。" % fc)
	h["gold"] -= fc
	h["month_out"] += fc
	sh["from"] = sh["port"]
	sh["to"] = dest
	sh["depart"] = s["day"]
	sh["arrive"] = s["day"] + GameData.travel_days(sh["port"], dest, sh["type"])
	sh["port"] = ""
	if sh["owner"] == pid() and sh["flagship"]:
		s["sailed"] = true
	return {"ok": true, "msg": "%s 起航前往 %s，预计 %d 天，燃晶 %d 金。" % [sh["name"], GameData.port_name(dest), sh["arrive"] - sh["depart"], fc]}


func buy_ship(type: String, port: String) -> Dictionary:
	var h := house()
	if _ships_of(pid()).size() >= GameData.MAX_SHIPS:
		return _fail("船队最多 %d 艘。" % GameData.MAX_SHIPS)
	var price: int = ship_price(type)
	if h["gold"] < price:
		return _fail("需要 %d 金。" % price)
	h["gold"] -= price
	h["month_out"] += price
	var sh := _add_ship(pid(), type, port)
	return {"ok": true, "msg": "购得 %s「%s」。" % [GameData.SHIPS[type]["name"], sh["name"]], "ship": sh["id"]}


func ship_price(type: String, hid: String = "") -> int:
	if hid == "":
		hid = pid()
	return int(GameData.SHIPS[type]["price"] * (0.8 if perk(hid) == "ships" else 1.0))


func workshop_cost(lvl: int, hid: String = "") -> int:
	if hid == "":
		hid = pid()
	return int(GameData.WORKSHOP_COST[lvl] * (0.75 if perk(hid) == "industry" else 1.0))


func dividend(lvl: int, hid: String) -> float:
	return GameData.WORKSHOP_DIVIDEND[lvl] * (1.25 if perk(hid) == "industry" else 1.0)


func sell_ship(ship_id: int) -> Dictionary:
	var sh := ship(ship_id)
	if sh.is_empty() or sh["owner"] != pid() or not docked(sh):
		return _fail("只能出售停在港口的飞艇。")
	if _ships_of(pid()).size() <= 1:
		return _fail("至少保留一艘飞艇。")
	if not sh["cargo"].is_empty():
		return _fail("请先清空货舱。")
	var v := int(GameData.SHIPS[sh["type"]]["price"] * 0.6)
	house()["gold"] += v
	var was_flag: bool = sh["flagship"]
	s["ships"].erase(sh)
	if was_flag:
		_ships_of(pid())[0]["flagship"] = true
	return {"ok": true, "msg": "出售 %s，回收 %d 金。" % [sh["name"], v]}


## Auto route: buy `good` at `a`, sell at `b`, loop. Empty dict clears it.
func set_route(ship_id: int, route: Dictionary) -> Dictionary:
	var sh := ship(ship_id)
	if sh.is_empty() or sh["owner"] != pid():
		return _fail("无效飞艇。")
	if sh["flagship"] and not route.is_empty():
		return _fail("旗舰由你亲自指挥，不能设自动航线。")
	sh["route"] = null if route.is_empty() else route
	return {"ok": true, "msg": "航线已更新。"}


func take_loan(amount: int) -> Dictionary:
	var h := house()
	if h["debt"] + amount > loan_limit():
		return _fail("超过贷款上限 %d 金。" % int(loan_limit() - h["debt"]))
	h["debt"] += amount
	h["gold"] += amount
	return {"ok": true, "msg": "贷款 %d 金，月息 2%%。" % amount}


func repay(amount: int) -> Dictionary:
	var h := house()
	amount = mini(amount, int(ceil(h["debt"])))
	if amount <= 0 or h["gold"] < amount:
		return _fail("金币不足或没有欠款。")
	h["debt"] -= amount
	h["gold"] -= amount
	return {"ok": true, "msg": "还款 %d 金。" % amount}


func invest(port: String, hid: String = "") -> Dictionary:
	if hid == "":
		hid = pid()
	var w: Dictionary = s["ports"][port]["workshops"]
	var lvl: int = int(w.get(hid, 0))
	if lvl >= 3:
		return _fail("工坊已是最高级。")
	var cost: int = workshop_cost(lvl, hid)
	var h := house(hid)
	if h["gold"] < cost:
		return _fail("需要 %d 金。" % cost)
	h["gold"] -= cost
	h["month_out"] += cost
	w[hid] = lvl + 1
	var make: Array = GameData.PORTS[port]["make"]
	for g in make:
		s["ports"][port]["market"][g]["eq"] += NEUTRAL_EQ * 0.25
	return {"ok": true, "msg": "%s 工坊升到 %d 级：特产增产，每月分红 %d 金。" % [GameData.port_name(port), lvl + 1, int(dividend(lvl, hid))]}


## Deliver cargo from a docked ship at the house's home port toward the current lighthouse stage.
func deliver_mats(ship_id: int) -> Dictionary:
	var sh := ship(ship_id)
	var hid: String = sh["owner"]
	var home: String = GameData.HOUSES[hid]["home"]
	if not docked(sh) or sh["port"] != home:
		return _fail("物资只能在母港 %s 交付。" % GameData.port_name(home))
	var lh: Dictionary = house(hid)["lh"]
	if lh["stage"] >= GameData.LIGHTHOUSE.size() or lh["building"]:
		return _fail("当前没有需要物资的工程。")
	var need: Dictionary = GameData.LIGHTHOUSE[lh["stage"]]["mats"]
	var parts := []
	for g in need:
		var have: int = int(lh["mats"].get(g, 0))
		var want: int = int(need[g]) - have
		if want <= 0 or not sh["cargo"].has(g):
			continue
		var n := mini(want, int(sh["cargo"][g]["qty"]))
		lh["mats"][g] = have + n
		sh["cargo"][g]["qty"] -= n
		if sh["cargo"][g]["qty"] <= 0:
			sh["cargo"].erase(g)
		parts.append("%s ×%d" % [GameData.good_name(g), n])
	if parts.is_empty():
		return _fail("货舱里没有灯塔需要的物资。")
	return {"ok": true, "msg": "交付 " + "、".join(parts) + "。"}


func mats_ready(hid: String = "") -> bool:
	if hid == "":
		hid = pid()
	var lh: Dictionary = house(hid)["lh"]
	if lh["stage"] >= GameData.LIGHTHOUSE.size():
		return false
	var need: Dictionary = GameData.LIGHTHOUSE[lh["stage"]]["mats"]
	for g in need:
		if int(lh["mats"].get(g, 0)) < int(need[g]):
			return false
	return true


func start_lighthouse(hid: String = "") -> Dictionary:
	if hid == "":
		hid = pid()
	var h := house(hid)
	var lh: Dictionary = h["lh"]
	if lh["building"] or lh["stage"] >= GameData.LIGHTHOUSE.size():
		return _fail("现在不能开工。")
	var st: Dictionary = GameData.LIGHTHOUSE[lh["stage"]]
	if not mats_ready(hid):
		return _fail("物资尚未备齐。")
	if h["gold"] < st["gold"]:
		return _fail("需要 %d 金。" % st["gold"])
	h["gold"] -= st["gold"]
	h["month_out"] += st["gold"]
	lh["building"] = true
	lh["end"] = s["day"] + int(st["days"])
	if hid != pid():
		_say("%s 开始建造灯塔%s（第 %d 层）。" % [GameData.HOUSES[hid]["name"], st["name"], int(lh["stage"]) + 1], "major")
	return {"ok": true, "msg": "灯塔%s开工，%d 天后完工。" % [st["name"], st["days"]]}


func buy_intel() -> Dictionary:
	var h := house()
	if h["gold"] < 400:
		return _fail("需要 400 金。")
	h["gold"] -= 400
	h["month_out"] += 400
	for pid in GameData.PORT_IDS:
		_update_intel(pid)
	return {"ok": true, "msg": "酒馆的消息贩子带来了全部港口的最新行情。"}


func _update_intel(port: String) -> void:
	var old = s["intel"].get(port)
	if old != null and int(old["day"]) != int(s["day"]):
		if not s.has("intel_prev"):
			s["intel_prev"] = {}
		s["intel_prev"][port] = old
	var prices := {}
	for g in GameData.GOOD_IDS:
		prices[g] = [buy_price(port, g), sell_price(port, g)]
	s["intel"][port] = {"day": s["day"], "prices": prices}


func _fail(msg: String) -> Dictionary:
	return {"ok": false, "msg": msg}


func _say(text: String, kind: String = "info") -> void:
	s["log"].append([s["day"], text, kind])
	if s["log"].size() > 200:
		s["log"].pop_front()
	message.emit(text, kind)


# ---------------------------------------------------------------- time

func blocked() -> bool:
	return s["over"] != null or s["event"] != null


func advance_day() -> void:
	if blocked():
		return
	s["day"] += 1
	var day: int = s["day"]
	_tick_markets()
	_tick_fashion()
	_tick_ships()
	_tick_lighthouses()
	if day % GameData.DAYS_MONTH == 0:
		_monthly()
	_tick_crisis()
	EventBook.maybe_trigger(self)
	if s["over"] == null and day >= GameData.END_DAY:
		_storm_ending()


func _tick_markets() -> void:
	for pid in GameData.PORT_IDS:
		var m: Dictionary = s["ports"][pid]["market"]
		for g in GameData.GOOD_IDS:
			var e: Dictionary = m[g]
			e["stock"] = maxf(0.0, e["stock"] + (e["eq"] - e["stock"]) * REVERT)


func _tick_fashion() -> void:
	var f = s.get("fashion")
	if f != null:
		if int(s["day"]) >= int(f["end"]):
			s["ports"][f["port"]]["market"][f["good"]]["eq"] = float(f["eq"])
			_say("风尚退潮：%s 的%s价格回落。" % [GameData.port_name(f["port"]), GameData.good_name(f["good"])], "info")
			s["fashion"] = null
		return
	if int(s["day"]) > 45 and rng.randf() < 1.0 / 75.0:
		var port: String = GameData.PORT_IDS[rng.randi() % GameData.PORT_IDS.size()]
		var options: Array = GameData.GOOD_IDS.filter(func(g): return not g in GameData.PORTS[port]["make"])
		var good: String = options[rng.randi() % options.size()]
		var m: Dictionary = s["ports"][port]["market"][good]
		s["fashion"] = {"port": port, "good": good, "eq": m["eq"], "end": int(s["day"]) + 60}
		m["eq"] = m["eq"] * 0.35
		_say("风尚：%s 突然追捧%s，未来两个月价格会大涨。" % [GameData.port_name(port), GameData.good_name(good)], "major")


func _tick_ships() -> void:
	for sh in s["ships"].duplicate():
		if not docked(sh) and s["day"] >= sh["arrive"]:
			sh["port"] = sh["to"]
			sh["to"] = ""
			_on_arrive(sh)
		elif docked(sh):
			if sh["owner"] == pid() and sh["route"] != null:
				_run_route(sh)
			elif sh["owner"] != pid():
				AiPlayer.ship_turn(self, sh)


func _on_arrive(sh: Dictionary) -> void:
	if sh["owner"] == pid():
		_update_intel(sh["port"])
		if sh["route"] != null:
			_run_route(sh)
		elif sh["flagship"]:
			_say("%s 抵达 %s。" % [sh["name"], GameData.port_name(sh["port"])])
			s["arrived"] = sh["id"]
	else:
		AiPlayer.ship_turn(self, sh)


func _run_route(sh: Dictionary) -> void:
	var r: Dictionary = sh["route"]
	var a: String = r["a"]
	var b: String = r["b"]
	var g: String = r["good"]
	var port: String = sh["port"]
	if port == b and sh["cargo"].has(g):
		var res := sell(sh["id"], g, int(sh["cargo"][g]["qty"]))
		if res["ok"]:
			r["last_profit"] = res["profit"]
			r["total"] = int(r.get("total", 0)) + int(res["profit"])
	if port == a and cargo_used(sh) < cargo_cap(sh):
		# only buy while it still pays: stop when price reaches 85% of target's sell price
		var limit := float(sell_price(b, g)) * 0.85
		var h := house()
		var reserve := 1500.0
		var n := 0
		while cargo_used(sh) < cargo_cap(sh) and buy_price(a, g) <= limit and h["gold"] - buy_price(a, g) > reserve:
			buy(sh["id"], g, 1)
			n += 1
			if n > 400:
				break
	var dest := b if port == a else a
	if port != a and port != b:
		dest = a
	var res2 := depart(sh["id"], dest)
	if not res2["ok"]:
		sh["route"]["stalled"] = res2["msg"]
	else:
		sh["route"].erase("stalled")


func _tick_lighthouses() -> void:
	for hid in GameData.HOUSE_IDS:
		var h: Dictionary = s["houses"][hid]
		if h["bankrupt"]:
			continue
		var lh: Dictionary = h["lh"]
		if lh["building"] and s["day"] >= lh["end"]:
			lh["building"] = false
			var st: Dictionary = GameData.LIGHTHOUSE[lh["stage"]]
			lh["stage"] += 1
			lh["mats"] = {}
			var who: String = GameData.HOUSES[hid]["name"]
			_say("%s 的灯塔%s落成（%d/3）。" % [who, st["name"], lh["stage"]], "good" if hid == pid() else "major")
			if lh["stage"] >= GameData.LIGHTHOUSE.size():
				_end("first_light" if hid == pid() else "rival_light", hid)
				return


func _monthly() -> void:
	for hid in GameData.HOUSE_IDS:
		var h: Dictionary = s["houses"][hid]
		if h["bankrupt"]:
			continue
		var cost := 0.0
		for sh in _ships_of(hid):
			cost += float(GameData.SHIPS[sh["type"]]["wage"]) + float(GameData.SHIPS[sh["type"]]["price"]) * 0.01
		var interest: float = h["debt"] * GameData.LOAN_RATE
		var div := 0.0
		for pid in GameData.PORT_IDS:
			var lvl: int = int(s["ports"][pid]["workshops"].get(hid, 0))
			if lvl > 0:
				div += dividend(lvl - 1, hid)
		h["gold"] += div - cost - interest
		h["month_in"] += div
		h["month_out"] += cost + interest
		h["last_net"] = h["month_in"] - h["month_out"]
		h["last_upkeep"] = cost + interest
		h["month_in"] = 0.0
		h["month_out"] = 0.0
		if hid != pid():
			AiPlayer.monthly(self, hid)
		else:
			_say("月结：上月净收支 %+d 金（固定开支 %d）。" % [int(h["last_net"]), int(cost + interest)], "month")
		if hid == pid() and h["gold"] < 0.0:
			# automatic emergency loan before a crisis starts
			var room: float = loan_limit() - h["debt"]
			var need: float = -h["gold"] + 500.0
			if room >= need:
				h["debt"] += need
				h["gold"] += need
				_say("金库见底，商会银行自动放贷 %d 金。" % int(need), "bad")


func _tick_crisis() -> void:
	for hid in GameData.HOUSE_IDS:
		var h: Dictionary = s["houses"][hid]
		if h["bankrupt"]:
			continue
		if h["gold"] < 0.0:
			if h["crisis"] == 0 and hid == pid():
				_say("债务危机：%d 天内金币必须转正，否则商会破产！" % GameData.CRISIS_DAYS, "bad")
			h["crisis"] += 1
			if h["crisis"] >= GameData.CRISIS_DAYS:
				_bankrupt(hid)
		else:
			h["crisis"] = 0


func _bankrupt(hid: String) -> void:
	var h: Dictionary = s["houses"][hid]
	h["bankrupt"] = true
	if hid == pid():
		_end("bankrupt", hid)
		return
	_say("%s 宣告破产，退出云海。" % GameData.HOUSES[hid]["name"], "major")
	s["ships"] = s["ships"].filter(func(x): return x["owner"] != hid)
	for pid in GameData.PORT_IDS:
		s["ports"][pid]["workshops"].erase(hid)


func _storm_ending() -> void:
	var st: int = house()["lh"]["stage"]
	_end("long_night" if st == 0 else "partial", pid())


const ENDINGS := {
	"first_light": {"title": "灯冠先亮", "win": true, "text": "初风暴压境之前，你的灯塔第一个点亮了灯冠。云海诸港奉{house}为盟主。"},
	"partial": {"title": "残灯守夜", "win": false, "text": "风暴来临时你的灯塔尚未完工，残缺的灯火只照亮了{home}周围的航道。"},
	"long_night": {"title": "长夜", "win": false, "text": "大风暴降临，没有一座灯塔为你而亮。{house}在黑暗中解散。"},
	"rival_light": {"title": "他人之灯", "win": false, "text": "{winner}先一步点亮灯冠，云海诸港改奉他们为盟主。"},
	"bankrupt": {"title": "破产", "win": false, "text": "债主收走了最后一艘飞艇。{house}的旗帜从{home}降下。"},
}


func _end(kind: String, hid: String) -> void:
	if s["over"] != null:
		return
	var e: Dictionary = ENDINGS[kind]
	var score := int(net_worth() / 100.0) + int(house()["lh"]["stage"]) * 500 + int(s["story"]) * 150
	if e["win"]:
		score += 1000 + maxi(0, GameData.END_DAY - int(s["day"]))
	var me: Dictionary = GameData.HOUSES[pid()]
	var text: String = e["text"].format({"house": me["name"], "home": GameData.port_name(me["home"]), "winner": GameData.HOUSES[hid]["name"]})
	s["over"] = {"kind": kind, "title": e["title"], "text": text, "win": e["win"], "by": hid, "day": s["day"], "score": score}
	_say("结局 · " + e["title"], "major")
	game_over.emit(s["over"])


# ---------------------------------------------------------------- save / load

func to_json() -> String:
	s["rng_state"] = str(rng.state)
	return JSON.stringify(s)


func from_json(text: String) -> bool:
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	s = parsed
	rng.seed = int(s["seed"])
	rng.state = int(s.get("rng_state", "0"))
	# JSON turns ints into floats; normalise the ones we use as ints/ids
	for k in ["day", "next_ship_id", "story", "tutorial"]:
		s[k] = int(s[k])
	for sh in s["ships"]:
		for k in ["id", "depart", "arrive"]:
			sh[k] = int(sh[k])
		for g in sh["cargo"]:
			sh["cargo"][g]["qty"] = int(sh["cargo"][g]["qty"])
	for hid in s["houses"]:
		var lh: Dictionary = s["houses"][hid]["lh"]
		lh["stage"] = int(lh["stage"])
		lh["end"] = int(lh["end"])
		s["houses"][hid]["crisis"] = int(s["houses"][hid]["crisis"])
	return true
