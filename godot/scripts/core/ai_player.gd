class_name AiPlayer
## Rival merchant houses. They use exactly the same market and costs as the player.

const RESERVE := 2500.0
const WORKING_CAPITAL := 15000.0   # cash kept for trading after paying for a lighthouse stage
const MAT_WEIGHT := 1.35   # how much a needed lighthouse material is worth vs. its base price


static func ship_turn(sim: Sim, sh: Dictionary) -> void:
	var hid: String = sh["owner"]
	var h := sim.house(hid)
	if h["bankrupt"] or not sim.docked(sh) or int(sh.get("idle_until", 0)) > int(sim.s["day"]):
		return
	var port: String = sh["port"]
	var home: String = GameData.HOUSES[hid]["home"]
	if sim.in_fleet(sh):
		sim.leave_fleet(int(sh["id"]))   # a captured prize trades on its own under the bot
	# another house's captain docked here: now and then the two race (round 15)
	if int(sim.s["day"]) - int(sim.s.get("rival_race_day", -999)) >= GameData.RIVAL_RACE_GAP and sim.rng.randf() < GameData.RIVAL_RACE:
		for other in sim.s["ships"]:
			if other["owner"] != hid and other["owner"] != sim.pid() and other["port"] == port and not sim.house(other["owner"])["bankrupt"]:
				sim.rival_race(sh, other)
				break
	for c in sim.open_contracts(port):
		if sim.can_fulfill(sh, c):
			sim.fulfill(sh["id"], c["id"])
	# hand materials to the lighthouse site only while there is working cash left; a poor
	# house sells what it carries instead of starving next to a pile of stone
	if port == home and h["gold"] >= WORKING_CAPITAL:
		sim.deliver_from_wh(hid)
		sim.deliver_mats(sh["id"])
		# materials on sale right here: buy and hand them over directly (cheap signature goods
		# freely, scarce imports only while a working reserve stays in the chest)
		var here_needs := _needs(sim, hid)
		for g in here_needs:
			var free := sim.cargo_cap(sh) - sim.cargo_used(sh)
			var local: bool = g in GameData.PORTS[home]["make"]
			var budget: float = h["gold"] - (WORKING_CAPITAL * 0.3 if local else WORKING_CAPITAL)
			var q := sim.quote_buy(home, g, mini(int(here_needs[g]), free), hid, budget)
			if q["qty"] > 0:
				sim.buy(sh["id"], g, q["qty"])
		sim.deliver_mats(sh["id"])
	# sell everything that is not a needed material on its way home
	# (a house short of working cash sells its materials too rather than starve)
	var needs := _needs(sim, hid)
	if h["gold"] < WORKING_CAPITAL:
		needs = {}
	var chase := _held_contract(sim, sh)
	for g in sh["cargo"].keys():
		if needs.has(g) and port != home:
			continue
		if not chase.is_empty() and g == chase["good"]:
			continue
		if not GameData.trades(port, g):
			continue
		sim.sell(sh["id"], g, int(sh["cargo"][g]["qty"]))
	if not chase.is_empty():
		_announce_chase(sim, hid, chase)
		sim.depart(sh["id"], chase["port"])
		return
	# carrying lighthouse materials: head home, topping up with whatever pays on the way
	var carrying := false
	for g in sh["cargo"]:
		if needs.has(g):
			carrying = true
	var plan := _best_plan(sim, sh, needs)
	if carrying and port != home:
		if not plan.is_empty() and plan["dest"] == home:
			sim.buy(sh["id"], plan["good"], plan["qty"])
		sim.depart(sh["id"], home)
		return
	if plan.is_empty():
		# nothing worth carrying from here: reposition to the best source port
		var dest := _best_source(sim, sh)
		if dest != "" and dest != port:
			sim.depart(sh["id"], dest)
		else:
			sh["idle_until"] = int(sim.s["day"]) + 5
		return
	sim.buy(sh["id"], plan["good"], plan["qty"])
	sim.depart(sh["id"], plan["dest"])


## An open contract this ship already carries enough goods for (and can still reach in time).
static func _held_contract(sim: Sim, sh: Dictionary) -> Dictionary:
	for c in sim.open_contracts():
		if c["port"] == sh["port"] or not sh["cargo"].has(c["good"]):
			continue
		if int(sh["cargo"][c["good"]]["qty"]) >= int(c["qty"]) and int(sim.s["day"]) + GameData.travel_days(sh["port"], c["port"], sh["type"]) <= int(c["end"]):
			return c
	return {}


static func _announce_chase(sim: Sim, hid: String, c: Dictionary) -> void:
	if hid in c["chasers"]:
		return
	c["chasers"].append(hid)
	sim._say("%s 的飞艇正载着%s赶往 %s 交付委托。" % [GameData.HOUSES[hid]["name"], GameData.good_name(c["good"]), GameData.port_name(c["port"])], "rival")


static func _needs(sim: Sim, hid: String) -> Dictionary:
	var lh: Dictionary = sim.house(hid)["lh"]
	var out := {}
	if lh["stage"] >= GameData.LIGHTHOUSE.size() or lh["building"]:
		return out
	var need: Dictionary = GameData.LIGHTHOUSE[lh["stage"]]["mats"]
	for g in need:
		var left := int(need[g]) - int(lh["mats"].get(g, 0))
		# count what is already aboard the fleet
		for o in sim.ships_of(hid):
			if o["cargo"].has(g):
				left -= int(o["cargo"][g]["qty"])
		if left > 0:
			out[g] = left
	return out


static func _best_plan(sim: Sim, sh: Dictionary, needs: Dictionary) -> Dictionary:
	var hid: String = sh["owner"]
	var h := sim.house(hid)
	var port: String = sh["port"]
	var home: String = GameData.HOUSES[hid]["home"]
	var space := sim.cargo_cap(sh) - sim.cargo_used(sh)
	# keep a reserve for wages, but never so much that the fleet stops trading altogether;
	# a trading house keeps less back and puts more of its chest on the line
	var share := 0.15 if sim.perk(hid) == "sell" else 0.3
	var budget: float = h["gold"] - minf(RESERVE, maxf(0.0, h["gold"]) * share)
	if space <= 0 or budget <= 200.0:
		return {}
	# materials matter more once the gold for the stage is in hand
	var mat_w := MAT_WEIGHT
	var lh: Dictionary = h["lh"]
	if lh["stage"] < GameData.LIGHTHOUSE.size() and h["gold"] > float(GameData.LIGHTHOUSE[lh["stage"]]["gold"]) * 0.6:
		mat_w = MAT_WEIGHT * 2.5
	var best := {}
	var best_rate := 8.0 if sim.perk(hid) == "sell" else 12.0
	for g in GameData.traded_goods(port):
		var unit := sim.buy_price(port, g, hid)
		var max_qty := mini(space, int(budget / maxf(1.0, unit * 1.3)))
		if max_qty < 5:
			continue
		for qty in [max_qty, max_qty / 2, max_qty / 4]:
			if qty < 5:
				continue
			var q := sim.est_buy(port, g, qty, hid, budget)
			if q["qty"] < 5:
				continue
			for dest in sim.open_ports():
				if dest == port or not GameData.trades(dest, g):
					continue
				var value: float
				var days := GameData.travel_days(port, dest, sh["type"])
				var deal := {}
				for c in sim.open_contracts(dest):
					if c["good"] == g and int(q["qty"]) >= int(c["qty"]) and int(sim.s["day"]) + days <= int(c["end"]):
						deal = c
				if not deal.is_empty():
					value = float(deal["reward"]) + sim.est_sell(dest, g, int(q["qty"]) - int(deal["qty"]), hid)["revenue"]
				elif needs.has(g) and dest == home and h["gold"] - float(q["cost"]) >= WORKING_CAPITAL:
					# a needed material is worth its weight, and a rich house pays whatever it costs
					var n := mini(int(q["qty"]), int(needs[g]))
					var per := maxf(float(GameData.GOODS[g]["base"]) * mat_w, unit * 1.25)
					value = n * per + sim.est_sell(dest, g, int(q["qty"]) - n, hid)["revenue"]
				else:
					value = sim.est_sell(dest, g, q["qty"], hid)["revenue"]
				var profit: float = value - q["cost"] - sim.fuel_cost(sh["type"], port, dest)
				var rate := profit / float(days + 1)
				if rate > best_rate:
					best_rate = rate
					best = {"good": g, "dest": dest, "qty": q["qty"], "rate": rate}
	return best


static func _best_source(sim: Sim, sh: Dictionary) -> String:
	var best := ""
	var best_gap := 0.0
	for pid in sim.open_ports():
		if pid == sh["port"]:
			continue
		for g in GameData.traded_goods(pid):
			var gap := 0.0
			for dest in sim.open_ports():
				if GameData.trades(dest, g):
					gap = maxf(gap, float(sim.sell_price(dest, g) - sim.buy_price(pid, g)))
			var score := gap / float(1 + GameData.travel_days(sh["port"], pid, sh["type"]))
			if score > best_gap:
				best_gap = score
				best = pid
	return best


static func monthly(sim: Sim, hid: String) -> void:
	var h := sim.house(hid)
	var lh: Dictionary = h["lh"]
	if not lh["building"] and lh["stage"] < GameData.LIGHTHOUSE.size() and sim.mats_ready(hid):
		var cost: int = GameData.LIGHTHOUSE[lh["stage"]]["gold"]
		if h["gold"] >= cost + WORKING_CAPITAL:
			sim.start_lighthouse(hid)
			return
	var ships := sim.ships_of(hid)
	var style := sim.perk(hid)   # "sell" trades, "ships" sails, "industry" builds
	# build industry with money not earmarked for the next lighthouse stage
	if lh["stage"] < GameData.LIGHTHOUSE.size():
		var next_cost: float = GameData.LIGHTHOUSE[lh["stage"]]["gold"]
		var spare: float = h["gold"] - WORKING_CAPITAL - (next_cost * 0.5 if lh["stage"] == 0 else next_cost)
		Industry.ai_blueprints(sim, hid)
		if spare > (2000.0 if style == "industry" else 4000.0):
			Industry.ai_build(sim, hid, spare)
		if spare > (40000.0 if style == "industry" else 60000.0):
			Industry.ai_upgrade(sim, hid, spare * 0.5)
		# contest someone else's strongest foothold now and then (the player's, or a rival's)
		elif lh["stage"] >= 1 and sim.rng.randf() < 0.15:
			var done := false
			for other in GameData.HOUSE_IDS:
				if other == hid or sim.house(other)["bankrupt"] or done:
					continue
				for port in sim.open_ports():
					if sim.patron(port) != other or Industry.count_buildings(sim, port, other) < 2:
						continue
					var plots: Array = sim.s["ports"][port]["plots"]
					for i in plots.size():
						if plots[i] != null and plots[i]["owner"] == other and h["gold"] > next_cost + Industry.buyout_cost(sim, port, i) + WORKING_CAPITAL * 1.5:
							var r := Industry.buyout(sim, port, i, hid)
							if r["ok"]:
								sim._say("%s 收购了%s在 %s 的%s工坊。" % [GameData.HOUSES[hid]["name"], GameData.HOUSES[other]["name"], GameData.port_name(port), GameData.good_name(plots[i]["b"])], "rival")
								done = true
							break
					if done:
						break
		# a rich house puts money into the cities it cares about (round 14)
		if spare > (30000.0 if style == "industry" else 50000.0) and sim.rng.randf() < 0.5:
			_fund_works(sim, hid, spare)
	# Keep enough for the next lighthouse stage before expanding.
	# a new hull only when the chest can also fill it: ships without trading capital just eat wages
	if ships.size() < sim.max_ships(hid) and float(h.get("last_net", 0.0)) > 0.0 and h["gold"] > sim.ship_price("galleon", hid) + WORKING_CAPITAL * (1.5 if style == "ships" else 2.5):
		var home: String = GameData.HOUSES[hid]["home"]
		h["gold"] -= sim.ship_price("galleon", hid)
		sim._add_ship(hid, "galleon", home)
	# cash crunch: sell an idle, empty ship rather than spiral into debt
	var upkeep := float(h.get("last_upkeep", 0.0))
	if h["gold"] < maxf(1500.0, upkeep * 1.5) and ships.size() > 1:
		for sh in ships:
			if sim.docked(sh) and sh["cargo"].is_empty() and not sh.get("flagship", false):
				h["gold"] += float(GameData.SHIPS[sh["type"]]["price"]) * 0.6
				sim.s["ships"].erase(sh)
				break


## Fund the cheapest unfinished work in the home city, or in a city where the house is patron
## or already the benefactor, keeping its spare cash positive.
static func _fund_works(sim: Sim, hid: String, spare: float) -> void:
	var cands := [GameData.HOUSES[hid]["home"]]
	for port in sim.open_ports():
		if port in cands:
			continue
		if sim.patron(port) == hid or sim.benefactor(port) == hid:
			cands.append(port)
	var best_port := ""
	var best_k := ""
	var best_cost := INF
	for port in cands:
		for k in GameData.WORK_IDS:
			var lvl := sim.work_level(port, k)
			if lvl >= GameData.WORK_MAX:
				continue
			var cost := float(GameData.WORK_COST[lvl + 1])
			if cost < best_cost and cost < spare * 0.6:
				best_cost = cost
				best_port = port
				best_k = k
	if best_port != "":
		sim.fund_work(best_port, best_k, hid)
