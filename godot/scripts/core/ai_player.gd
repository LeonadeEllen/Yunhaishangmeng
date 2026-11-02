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
	if port == home:
		sim.deliver_mats(sh["id"])
		# materials made right here: buy and hand them over directly
		var here_needs := _needs(sim, hid)
		for g in here_needs:
			if g in GameData.PORTS[home]["make"]:
				var free := sim.cargo_cap(sh) - sim.cargo_used(sh)
				var budget: float = h["gold"] - WORKING_CAPITAL * 0.3
				var q := sim.quote_buy(home, g, mini(int(here_needs[g]), free), hid, budget)
				if q["qty"] > 0:
					sim.buy(sh["id"], g, q["qty"])
		sim.deliver_mats(sh["id"])
	# sell everything that is not a needed material on its way home
	var needs := _needs(sim, hid)
	for g in sh["cargo"].keys():
		if needs.has(g) and port != home:
			continue
		sim.sell(sh["id"], g, int(sh["cargo"][g]["qty"]))
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
	# keep a reserve for wages, but never so much that the fleet stops trading altogether
	var budget: float = h["gold"] - minf(RESERVE, maxf(0.0, h["gold"]) * 0.3)
	if space <= 0 or budget <= 200.0:
		return {}
	# materials matter more once the gold for the stage is in hand
	var mat_w := MAT_WEIGHT
	var lh: Dictionary = h["lh"]
	if lh["stage"] < GameData.LIGHTHOUSE.size() and h["gold"] > float(GameData.LIGHTHOUSE[lh["stage"]]["gold"]) * 0.6:
		mat_w = MAT_WEIGHT * 2.5
	var best := {}
	var best_rate := 25.0
	for g in GameData.GOOD_IDS:
		var unit := sim.buy_price(port, g, hid)
		var max_qty := mini(space, int(budget / maxf(1.0, unit * 1.3)))
		if max_qty < 5:
			continue
		for qty in [max_qty, max_qty / 2, max_qty / 4]:
			if qty < 5:
				continue
			var q := sim.quote_buy(port, g, qty, hid, budget)
			if q["qty"] < 5:
				continue
			for dest in GameData.PORT_IDS:
				if dest == port:
					continue
				var value: float
				if needs.has(g) and dest == home:
					var n := mini(int(q["qty"]), int(needs[g]))
					value = n * float(GameData.GOODS[g]["base"]) * mat_w + sim.quote_sell(dest, g, int(q["qty"]) - n)["revenue"]
				else:
					value = sim.quote_sell(dest, g, q["qty"])["revenue"]
				var days := GameData.travel_days(port, dest, sh["type"])
				var profit: float = value - q["cost"] - sim.fuel_cost(sh["type"], port, dest)
				var rate := profit / float(days + 1)
				if rate > best_rate:
					best_rate = rate
					best = {"good": g, "dest": dest, "qty": q["qty"], "rate": rate}
	return best


static func _best_source(sim: Sim, sh: Dictionary) -> String:
	var best := ""
	var best_gap := 0.0
	for pid in GameData.PORT_IDS:
		for g in GameData.GOOD_IDS:
			var gap := 0.0
			for dest in GameData.PORT_IDS:
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
	# rich and between stages: build up industry at home
	if lh["stage"] >= 1 and lh["stage"] < GameData.LIGHTHOUSE.size():
		var next_cost: float = GameData.LIGHTHOUSE[lh["stage"]]["gold"]
		var home: String = GameData.HOUSES[hid]["home"]
		var wl: int = int(sim.s["ports"][home]["workshops"].get(hid, 0))
		if wl < 3 and h["gold"] > next_cost + GameData.WORKSHOP_COST[wl] + WORKING_CAPITAL:
			sim.invest(home, hid)
	# Keep enough for the next lighthouse stage before expanding.
	if ships.size() < 3 and h["gold"] > 26000 + 15000:
		var home: String = GameData.HOUSES[hid]["home"]
		h["gold"] -= GameData.SHIPS["galleon"]["price"]
		sim._add_ship(hid, "galleon", home)
	# cash crunch: sell an idle, empty ship rather than spiral into debt
	var upkeep := float(h.get("last_upkeep", 0.0))
	if h["gold"] < maxf(1500.0, upkeep * 1.5) and ships.size() > 1:
		for sh in ships:
			if sim.docked(sh) and sh["cargo"].is_empty() and not sh.get("flagship", false):
				h["gold"] += float(GameData.SHIPS[sh["type"]]["price"]) * 0.6
				sim.s["ships"].erase(sh)
				break
