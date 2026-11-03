extends SceneTree
## Headless regression + balance tests.
## Run: godot --headless --path godot -s res://tests/run_all.gd
## Exits with code 1 if any check fails.

var failures := 0


func _init() -> void:
	test_price_feedback()
	test_save_load()
	test_idle_player_goes_bankrupt()
	test_contracts_and_buyout()
	test_production_chain()
	test_hero()
	var seeds := [11, 22, 33, 44, 55]
	var crowns := 0
	var bot_stage := 0
	var early_bankrupt := 0
	for sd in seeds:
		var r := test_bot_player(sd)
		crowns += 1 if r["crown"] else 0
		bot_stage += 1 if r["bot_stage"] >= 1 else 0
		early_bankrupt += r["early_bankrupt"]
	print("crowns %d/%d, bot built stage 1 in %d/%d, early bankruptcies %d" % [crowns, seeds.size(), bot_stage, seeds.size(), early_bankrupt])
	# Rivals should light the crown in roughly 6-12 years; the greedy bot (no planning) should at
	# least raise the first stage, and nobody should go bankrupt in the opening two years.
	check(crowns >= 4, "someone lights the crown within 12 years in at least 4 of 5 seeds")
	check(bot_stage >= 3, "the trading bot builds the lighthouse base in at least 3 of 5 seeds")
	check(early_bankrupt == 0, "no rival goes bankrupt in the first two years")
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		failures += 1
		print("  FAIL ", what)


func run_until_over(sim: Sim, bot: bool, log_every: int = 0) -> void:
	var guard := 0
	while sim.s["over"] == null and sim.s["crown"] == null and guard < GameData.DAYS_YEAR * 12:
		if sim.s["event"] != null:
			EventBook.resolve(sim, 0)
		if bot:
			for sh in sim.ships_of(sim.pid()):
				if sim.docked(sh):
					AiPlayer.ship_turn(sim, sh)
			if sim.s["day"] % GameData.DAYS_MONTH == 1:
				AiPlayer.monthly(sim, sim.pid())
		sim.advance_day()
		guard += 1
		if log_every > 0 and sim.s["day"] % log_every == 0:
			var row := []
			for hid in GameData.HOUSE_IDS:
				var h := sim.house(hid)
				row.append("%s %7d g / lh %d / %d ships" % [hid, int(h["gold"]), h["lh"]["stage"], sim.ships_of(hid).size()])
			print("    y%-2d " % (sim.s["day"] / GameData.DAYS_YEAR), " | ".join(row))


func test_contracts_and_buyout() -> void:
	var sim := Sim.new()
	sim.new_game(7)
	sim._post_contract()
	var c: Dictionary = sim.open_contracts()[0]
	var fl := sim.flagship()
	fl["port"] = c["port"]
	fl["cargo"] = {c["good"]: {"qty": int(c["qty"]) + 3, "cost": 10.0}}
	var g0: float = sim.house()["gold"]
	var r := sim.fulfill(fl["id"], c["id"])
	check(r["ok"] and is_equal_approx(sim.house()["gold"], g0 + float(c["reward"])), "contract pays its reward")
	check(sim.open_contracts().is_empty() and int(fl["cargo"][c["good"]]["qty"]) == 3, "contract is consumed with its goods")
	check(not sim.fulfill(fl["id"], c["id"])["ok"], "a contract cannot be paid twice")
	# buildings: patron fee, buyout
	var port := "muxia"
	sim.house("tower")["gold"] = 50000.0
	sim.house("tower")["bp"]["fish"] = true
	check(Industry.build(sim, port, 0, "fish", "tower")["ok"], "rival builds a fishery")
	check(sim.patron(port) == "tower", "most buildings makes the patron")
	sim.house()["gold"] = 100000.0
	sim.house()["rep"] = 700
	sim.house()["bp"]["fish"] = true
	check(not Industry.build(sim, port, 1, "fish")["ok"], "a wheat plot refuses a fishery")
	var before := sim.buy_price(port, "fish")
	var tg: float = sim.house("tower")["gold"]
	check(Industry.buyout(sim, port, 0)["ok"], "buyout succeeds with enough gold")
	check(sim.s["ports"][port]["plots"][0]["owner"] == sim.pid(), "buyout moves the building")
	check(sim.house("tower")["gold"] > tg, "the seller is compensated")
	check(sim.buy_price(port, "fish") < before, "becoming patron removes the harbour fee")


func test_production_chain() -> void:
	var sim := Sim.new()
	sim.new_game(9)
	sim.house()["gold"] = 200000.0
	var port := "fengyue"
	check(not Industry.build(sim, port, 0, "ore")["ok"], "no deed, no mine")
	sim.house()["rep"] = 700
	sim.s["ports"][port]["friend"][sim.pid()] = 400
	check(sim.buy_deed(port, "ore")["ok"], "deed bought at friendliness 2")
	check(Industry.build(sim, port, 0, "ore")["ok"], "build a mine on an ore plot")
	check(not sim.craft_ok("steel")["ok"], "craft blueprint needs handled input")
	sim.s["stats"]["handled"]["ore"] = 150
	check(sim.buy_craft_bp("steel")["ok"], "craft blueprint bought at level 3 with experience")
	check(Industry.build(sim, port, 1, "steel")["ok"], "build a forge on a workshop plot")
	check(Industry.has_wh(sim, port, sim.pid()), "building opens a warehouse")
	for i in 10:
		sim.advance_day()
	var w := Industry.wh(sim, port, sim.pid())
	check(int(w.get("ore", 0)) > 0, "mine fills the warehouse with ore")
	check(sim.s["ports"][port]["plots"][1]["status"].begins_with("缺"), "forge without timber reports what it lacks")
	Industry.wh_add(sim, port, sim.pid(), "timber", 20)
	for i in 5:
		sim.advance_day()
	check(int(Industry.wh(sim, port, sim.pid()).get("steel", 0)) > 0, "forge turns ore + timber into steel")
	var fl := sim.flagship()
	fl["port"] = port
	var r := sim.load_wh(fl["id"], "steel", 5)
	check(r["ok"] and int(fl["cargo"]["steel"]["qty"]) == 5, "load steel from warehouse")
	check(not sim.secret_ok("cannon", "lamp")["ok"], "secret blueprint needs level 4")
	var json := sim.to_json()
	var sim2 := Sim.new()
	check(sim2.from_json(json) and sim2.s["ports"][port]["plots"][1]["b"] == "steel" and sim2.house()["bp"].has("steel"), "buildings and blueprints survive save/load")


func test_hero() -> void:
	print("protagonist")
	var sim := Sim.new()
	sim.new_game(5)
	var d0 := sim.travel_days("qianqi", "chishi", "freighter")
	var b0 := sim.buy_price("qianqi", "silk")
	var s0 := sim.sell_price("qianqi", "silk")
	sim.add_exp(99)
	check(int(sim.hero()["lvl"]) == 1 and int(sim.hero()["pts"]) == 0, "99 exp is not yet level 2")
	sim.add_exp(1)
	check(int(sim.hero()["lvl"]) == 2 and int(sim.hero()["pts"]) == 1, "100 exp reaches level 2 with one point")
	check(not sim.spend_hero_pt("nope")["ok"], "unknown ability is refused")
	check(sim.spend_hero_pt("trade")["ok"] and sim.hero_abil("trade") == 2, "point goes into trading")
	check(not sim.spend_hero_pt("trade")["ok"], "no second point to spend")
	check(sim.buy_price("qianqi", "silk") <= b0 and sim.sell_price("qianqi", "silk") >= s0, "trading skill tightens the spread (%d/%d -> %d/%d)" % [b0, s0, sim.buy_price("qianqi", "silk"), sim.sell_price("qianqi", "silk")])
	sim.hero()["abil"]["sail"] = 6
	check(sim.travel_days("qianqi", "chishi", "freighter") < d0, "seamanship shortens voyages (%d -> %d)" % [d0, sim.travel_days("qianqi", "chishi", "freighter")])
	check(sim.travel_days("qianqi", "chishi", "freighter", "iron") == d0, "rivals keep the plain travel time")
	var fl := sim.flagship()
	sim.depart(fl["id"], "chishi")
	for i in 30:
		if sim.s["event"] != null:
			EventBook.resolve(sim, 0)
		sim.advance_day()
	check(sim.docked(fl) and hero_visited(sim, "chishi"), "arriving logs the visit and grants experience (exp %d)" % int(sim.hero()["exp"]))
	var sim2 := Sim.new()
	check(sim2.from_json(sim.to_json()) and sim2.hero_abil("sail") == 6 and int(sim2.hero()["lvl"]) == 2, "hero survives save/load")


func hero_visited(sim: Sim, port: String) -> bool:
	return sim.hero()["visited"].has(port)


func test_price_feedback() -> void:
	print("price feedback")
	var sim := Sim.new()
	sim.new_game(1)
	var p0 := sim.buy_price("qianqi", "silk")
	var fl := sim.flagship()
	var r := sim.buy(fl["id"], "silk", 60)
	check(r["ok"], "buying 60 silk at home works")
	var p1 := sim.buy_price("qianqi", "silk")
	check(p1 > p0, "buying raises the price (%d -> %d)" % [p0, p1])
	for i in 40:
		sim._tick_markets()
	var p2 := sim.buy_price("qianqi", "silk")
	var eq: float = sim.s["ports"]["qianqi"]["market"]["silk"]["eq"]
	var p_eq := roundf(sim.unit_price("qianqi", "silk", eq) * 1.06)
	check(absf(p2 - p_eq) <= maxf(2.0, (p1 - p_eq) * 0.15), "price recovers toward equilibrium after 40 days (%d -> %d -> %d, eq %d)" % [p0, p1, p2, p_eq])
	check(sim.sell_price("muxia", "silk") > sim.buy_price("qianqi", "silk"), "silk sells higher where it is wanted")
	check(sim.sell_price("qianqi", "lamp") > GameData.GOODS["lamp"]["base"] * 1.3, "fine goods nobody makes are dear everywhere")


func test_save_load() -> void:
	print("save / load")
	var a := Sim.new()
	a.new_game(7)
	for i in 50:
		if a.s["event"] != null:
			EventBook.resolve(a, 0)
		a.advance_day()
	var txt := a.to_json()
	var b := Sim.new()
	check(b.from_json(txt), "save parses")
	check(b.s["day"] == a.s["day"], "day restored")
	check(absf(b.house()["gold"] - a.house()["gold"]) < 0.5, "gold restored")
	for i in 30:
		if a.s["event"] != null:
			EventBook.resolve(a, 0)
		if b.s["event"] != null:
			EventBook.resolve(b, 0)
		a.advance_day()
		b.advance_day()
	check(absf(b.house("iron")["gold"] - a.house("iron")["gold"]) < 1.0, "simulation continues identically after load")


func test_idle_player_goes_bankrupt() -> void:
	print("idle player")
	var sim := Sim.new()
	sim.new_game(3)
	run_until_over(sim, false)
	check(sim.s["over"] != null and sim.s["over"]["kind"] == "bankrupt", "idle player goes bankrupt (%s)" % (sim.s["over"]["kind"] if sim.s["over"] else "none"))
	check(sim.house()["gold"] > -50000, "gold never runs away to huge negatives (%d)" % int(sim.house()["gold"]))


func test_bot_player(sd: int) -> Dictionary:
	print("bot player seed %d" % sd)
	var sim := Sim.new()
	sim.new_game(sd)
	var early := 0
	var guard := 0
	while sim.s["over"] == null and sim.s["crown"] == null and guard < GameData.DAYS_YEAR * 12:
		if sim.s["event"] != null:
			EventBook.resolve(sim, 0)
		for sh in sim.ships_of(sim.pid()):
			if sim.docked(sh):
				AiPlayer.ship_turn(sim, sh)
		if sim.s["day"] % GameData.DAYS_MONTH == 1:
			AiPlayer.monthly(sim, sim.pid())
		sim.advance_day()
		guard += 1
		if sim.s["day"] == GameData.DAYS_YEAR * 2:
			for hid in GameData.HOUSE_IDS:
				if hid != sim.pid() and sim.house(hid)["bankrupt"]:
					early += 1
		if sim.s["day"] % (GameData.DAYS_YEAR * 2) == 0:
			var row := []
			for hid in GameData.HOUSE_IDS:
				var h := sim.house(hid)
				row.append("%s %7d g / lh %d / %d ships / %d bld" % [hid, int(h["gold"]), h["lh"]["stage"], sim.ships_of(hid).size(), Industry.all_buildings(sim, hid).size()])
			print("    y%-2d " % (sim.s["day"] / GameData.DAYS_YEAR), " | ".join(row))
	var crown = sim.s["crown"]
	print("    crown: %s (year %d)" % [str(crown["hid"]) if crown != null else "none", sim.s["day"] / GameData.DAYS_YEAR + 1])
	for hid in GameData.HOUSE_IDS:
		check(sim.house(hid)["gold"] > -60000, "%s gold bounded (%d)" % [hid, int(sim.house(hid)["gold"])])
	return {"crown": crown != null, "bot_stage": int(sim.house()["lh"]["stage"]), "early_bankrupt": early}
