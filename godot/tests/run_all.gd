extends SceneTree
## Headless regression + balance tests.
## Run: godot --headless --path godot -s res://tests/run_all.gd
## Exits with code 1 if any check fails.

var failures := 0


func _init() -> void:
	if OS.get_environment("YUNHAI_QUICK") != "":
		test_battle()
		test_encounters()
		test_crew()
		test_explore()
		test_rivals_and_hq()
		test_city_works()
		test_festival()
		test_quests()
		test_festival_challenge()
		test_milestones()
		test_leaders()
		test_ties()
		test_allies()
		print("FAILURES: %d" % failures)
		quit(1 if failures > 0 else 0)
		return
	test_price_feedback()
	test_save_load()
	test_idle_player_goes_bankrupt()
	test_contracts_and_buyout()
	test_production_chain()
	test_hero()
	test_fleet_and_refit()
	test_multi_stop_route()
	test_battle()
	test_encounters()
	test_crew()
	test_explore()
	test_rivals_and_hq()
	test_city_works()
	test_festival()
	test_quests()
	test_festival_challenge()
	test_milestones()
	test_leaders()
	test_ties()
	test_allies()
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
			EventBook.resolve(sim, sim.s["event"]["choices"].size() - 1 if str(sim.s["event"]["id"]).begins_with("rival:") else 0)
		if sim.s["encounter"] != null:
			sim.auto_encounter()
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
			EventBook.resolve(sim, sim.s["event"]["choices"].size() - 1 if str(sim.s["event"]["id"]).begins_with("rival:") else 0)
		sim.advance_day()
	check(sim.docked(fl) and hero_visited(sim, "chishi"), "arriving logs the visit and grants experience (exp %d)" % int(sim.hero()["exp"]))
	var sim2 := Sim.new()
	check(sim2.from_json(sim.to_json()) and sim2.hero_abil("sail") == 6 and int(sim2.hero()["lvl"]) == 2, "hero survives save/load")


func test_fleet_and_refit() -> void:
	print("fleet & refit")
	var sim := Sim.new()
	sim.new_game(8)
	sim.house()["gold"] = 200000.0
	var fl := sim.flagship()
	var home: String = fl["port"]
	var r := sim.buy_ship("freighter", home)
	check(r["ok"], "second ship bought")
	var esc := sim.ship(int(r["ship"]))
	check(sim.join_fleet(esc["id"])["ok"] and sim.fleet_ships(fl).size() == 2, "escort joins the flagship's fleet")
	check(sim.fleet_cargo_cap(fl) == sim.cargo_cap(fl) + sim.cargo_cap(esc), "fleet capacity is the sum of holds")
	var g: String = GameData.PORTS[home]["make"][0]
	sim.s["ports"][home]["market"][g]["stock"] = 2000.0
	check(sim.buy(fl["id"], g, 120)["ok"] and sim.fleet_cargo_used(fl) == 120 and sim.cargo_used(esc) > 0, "buying on the flagship spills into the escort")
	check(not sim.depart(esc["id"], "chishi")["ok"], "an escort cannot sail on its own")
	var d := sim.depart(fl["id"], "chishi")
	check(d["ok"] and not sim.docked(esc) and esc["arrive"] == fl["arrive"], "the fleet sails together")
	for i in 40:
		if sim.s["event"] != null:
			EventBook.resolve(sim, sim.s["event"]["choices"].size() - 1 if str(sim.s["event"]["id"]).begins_with("rival:") else 0)
		sim.advance_day()
	check(sim.docked(fl) and fl["port"] == "chishi" and esc["port"] == "chishi", "fleet arrives together")
	check(sim.sell(fl["id"], g, 120)["ok"] and sim.fleet_cargo_used(fl) == 0, "selling empties every hold in the fleet")
	check(not sim.set_route(esc["id"], {"a": "chishi", "b": "qianqi", "good": "stone"})["ok"], "an escort refuses an auto route")
	# refit: canvas from the market
	var cap0 := sim.cargo_cap(fl)
	var days0 := sim.ship_days(fl, "qianqi")
	sim.s["ports"]["chishi"]["market"]["canvas"]["stock"] = 500.0
	var plan := sim.refit_plan(fl, "sail")
	check(plan["ok"] and int(plan["gold"]) > int(plan["fee"]), "refit plan buys the missing canvas at the market")
	check(sim.refit(fl["id"], "sail")["ok"] and sim.mod_lvl(fl, "sail") == 1, "sails refitted")
	check(sim.speed_mult(fl) > 1.0 and sim.ship_days(fl, "qianqi") <= days0, "new sails make the ship faster")
	sim.s["ports"]["chishi"]["market"]["steel"]["stock"] = 500.0
	check(sim.refit(fl["id"], "hold")["ok"] and sim.cargo_cap(fl) > cap0, "hold extension adds capacity")
	sim.s["ports"]["chishi"]["market"]["cannon"]["stock"] = 0.0
	check(not sim.refit(fl["id"], "guns")["ok"], "no cannons on sale means no guns")
	check(sim.rename_ship(fl["id"], "青鸾号")["ok"] and fl["name"] == "青鸾号", "ship renamed")
	check(sim.set_slot(esc["id"], "van")["ok"] and esc["slot"] == "van", "escort takes the vanguard slot")
	var sim2 := Sim.new()
	check(sim2.from_json(sim.to_json()) and sim2.mod_lvl(sim2.flagship(), "sail") == 1 and sim2.fleet_ships(sim2.flagship()).size() == 2, "refits and fleets survive save/load")


func test_multi_stop_route() -> void:
	print("multi-stop route")
	var sim := Sim.new()
	sim.new_game(8)
	sim.house()["gold"] = 100000.0
	var r := sim.buy_ship("freighter", "qianqi")
	var sh := sim.ship(int(r["ship"]))
	check(not sim.set_route(sh["id"], {"stops": [{"port": "qianqi", "buy": []}, {"port": "muxia", "buy": []}]})["ok"], "a route with nothing to buy is refused")
	check(not sim.set_route(sh["id"], {"stops": [{"port": "qianqi", "buy": ["silk"]}, {"port": "qianqi", "buy": []}]})["ok"], "adjacent identical stops are refused")
	var ok := sim.set_route(sh["id"], {"stops": [{"port": "qianqi", "buy": ["silk"]}, {"port": "muxia", "buy": ["fish"]}, {"port": "chishi", "buy": ["stone"]}]})
	check(ok["ok"] and sh["route"]["stops"].size() == 3, "three-stop route accepted")
	var visited := {}
	for i in 200:
		if sim.s["event"] != null:
			EventBook.resolve(sim, sim.s["event"]["choices"].size() - 1 if str(sim.s["event"]["id"]).begins_with("rival:") else 0)
		sim.advance_day()
		visited[sh["port"] if sim.docked(sh) else sh["to"]] = true
	check(visited.has("muxia") and visited.has("chishi") and visited.has("qianqi"), "the ship works its way around the loop")
	check(int(sh["route"].get("total", 0)) != 0, "the loop books some profit or loss (%d)" % int(sh["route"].get("total", 0)))
	var legacy := sim.set_route(sh["id"], {"a": "qianqi", "b": "muxia", "good": "silk"})
	check(legacy["ok"] and sh["route"]["stops"].size() == 2 and sh["route"]["stops"][0]["buy"] == ["silk"], "old two-port routes convert")


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


func test_battle() -> void:
	print("battle")
	# hex maths
	check(Battle.dist(0, 0, 3, 0) == 3 and Battle.dist(0, 0, 0, 2) == 2 and Battle.dist(1, 1, 1, 2) == 1, "hex distance (odd-r)")
	check(Battle.neighbors(0, 0).size() == 2 and Battle.neighbors(5, 3).size() == 6, "hex neighbours clipped to the board")
	# a gunboat with the hero at fight 10 beats a lone sloop; a lone survey boat loses or runs
	var wins := 0
	var ends := {}
	for sd in 12:
		var bt := Battle.new()
		bt.setup([Battle.unit("gunboat", "炮舰", {"hull": 1, "guns": 1}, "main", true, 0, 1), Battle.unit("freighter", "货艇", {}, "rear", false, 0, 2)],
			[Battle.unit("p_sloop", "黑帆号", {}, "main", true), Battle.unit("p_sloop", "夜枭号", {}, "van", false)], {"fight": 6, "lvl": 5}, 100 + sd)
		var r := bt.auto_play()
		ends[r] = int(ends.get(r, 0)) + 1
		if r == "win":
			wins += 1
		check(bt.b["round"] <= Battle.ROUND_CAP + 1, "battle ends within the round cap")
	print("    gunboat+freighter vs 2 sloops: ", ends)
	check(wins >= 8, "a refitted gunboat with a seasoned captain wins most fights (%d/12)" % wins)
	var losses := 0
	for sd in 12:
		var bt2 := Battle.new()
		bt2.setup([Battle.unit("survey", "测绘艇", {}, "main", true, 0, 1)], [Battle.unit("p_raider", "黑帆号", {}, "main", true), Battle.unit("p_sloop", "夜枭号", {}, "van", false)], {"fight": 1, "lvl": 1}, 300 + sd)
		if bt2.auto_play() != "win":
			losses += 1
	check(losses >= 10, "an unarmed survey boat does not beat raiders (%d/12 non-wins)" % losses)
	# manual actions: move, fire, tactics, retreat
	var bt3 := Battle.new()
	bt3.setup([Battle.unit("gunboat", "炮舰", {}, "main", true, 0, 1)], [Battle.unit("p_sloop", "黑帆号", {}, "main", true)], {"fight": 3, "lvl": 8}, 7)
	var u := _player_turn(bt3)
	check(not u.is_empty() and int(u["side"]) == 0, "a player ship gets its turn")
	var reach := bt3.reachable(u)
	check(not reach.is_empty() and reach.values().max() <= int(u["move"]), "reachable hexes respect movement")
	var far := ""
	for k in reach:
		if far == "" or int(reach[k]) > int(reach[far]):
			far = k
	var parts: PackedStringArray = far.split(",")
	check(bt3.move_to(int(u["id"]), int(parts[0]), int(parts[1]))["ok"], "move to a reachable hex")
	check(not bt3.fire(int(u["id"]), 1)["ok"], "cannot fire across the whole board")
	check(bt3.tactic("rally", -1)["ok"] and bt3.b["cp"] == 0, "rally spends the command point")
	check(not bt3.tactic("lure", 1)["ok"], "lure needs hero level 10")
	check(bt3.defend(int(u["id"]))["ok"] and u["defend"], "defend sets the guard")
	var e := bt3.next_unit()
	check(not e.is_empty() and int(e["side"]) == 1, "then the enemy acts")
	bt3.ai_turn()
	check(e["acted"], "the pirate captain spends its action")
	# a brand new battle: the flagship starts at the edge and may retreat at once
	var bt4 := Battle.new()
	bt4.setup([Battle.unit("freighter", "货艇", {}, "main", true, 0, 1)], [Battle.unit("p_sloop", "黑帆号", {}, "main", true)], {"fight": 1, "lvl": 1}, 9)
	var u4 := _player_turn(bt4)
	check(bt4.can_retreat(u4) and bt4.retreat(int(u4["id"]))["ok"] and bt4.b["over"] == "withdraw", "retreating the only ship ends the fight as a withdrawal")
	# save round trip keeps the battle playable
	var sim := Sim.new()
	sim.new_game(5)
	sim.house()["gold"] = 50000.0
	var fl := sim.flagship()
	sim.start_encounter("pirates")
	check(sim.s["encounter"] != null and sim.blocked(), "an encounter stops the clock")
	sim.encounter_fight()
	var json := sim.to_json()
	var sim2 := Sim.new()
	check(sim2.from_json(json) and sim2.battle != null and sim2.battle.b["units"].size() == sim.battle.b["units"].size(), "a battle survives save/load")
	sim2.battle.auto_play()
	var out := sim2.end_battle()
	check(out.has("res") and sim2.s["battle"] == null and sim2.s["encounter"] == null and not sim2.blocked(), "ending the battle clears the encounter")


## Advance the battle (playing enemy turns) until a player ship is up.
func _player_turn(bt: Battle) -> Dictionary:
	var u := bt.next_unit()
	var guard := 0
	while not u.is_empty() and int(u["side"]) == 1 and guard < 20:
		bt.ai_turn()
		u = bt.next_unit()
		guard += 1
	return u


func test_encounters() -> void:
	print("encounters")
	var sim := Sim.new()
	sim.new_game(21)
	var fl := sim.flagship()
	sim.house()["gold"] = 40000.0
	# wind: the same leg takes a different time in opposite seasons
	var d_spring := sim.travel_days("muxia", "cuijing", "freighter")
	sim.s["day"] = 180
	var d_autumn := sim.travel_days("muxia", "cuijing", "freighter")
	check(d_spring != d_autumn, "seasonal wind changes travel time (%d vs %d days)" % [d_spring, d_autumn])
	sim.s["day"] = 0
	# toll
	sim.start_encounter("pirates")
	var g0: float = sim.house()["gold"]
	check(sim.encounter_pay()["ok"] and sim.house()["gold"] < g0 and sim.s["encounter"] == null, "paying the toll clears the encounter")
	# loss costs cargo and gold but never the flagship
	sim.start_encounter("pirates")
	fl["cargo"] = {"silk": {"qty": 20, "cost": 100.0}}
	sim.encounter_fight()
	for u in sim.battle.b["units"]:
		if int(u["home"]) == 0:
			u["hp"] = 0
			u["status"] = "sunk"
	sim.battle.b["over"] = "loss"
	var g1: float = sim.house()["gold"]
	var out := sim.end_battle()
	check(out["res"] == "loss" and sim.house()["gold"] < g1 and fl["cargo"].is_empty() and not sim.flagship().is_empty() and int(fl["dmg"]) > 0, "a lost battle costs gold and cargo, the flagship limps on")
	# repair
	fl["port"] = "muxia"
	var rc := sim.repair_cost(fl)
	check(rc > 0 and sim.repair_ship(fl["id"])["ok"] and int(fl["dmg"]) == 0, "the yard mends battle damage for gold (%d)" % rc)
	# win: loot, reputation, captured ship joins the fleet
	sim.start_encounter("pirates")
	sim.encounter_fight()
	var rep0: int = sim.house()["rep"]
	var n0 := sim.ships_of().size()
	for u in sim.battle.b["units"]:
		if int(u["home"]) == 1:
			u["side"] = 0
			u["taken"] = true
	sim.battle.b["over"] = "win"
	var out2 := sim.end_battle()
	check(out2["res"] == "win" and int(sim.house()["rep"]) > rep0 and sim.ships_of().size() == n0 + 1 and int(out2["gold"]) > 0, "a won battle brings loot, reputation and a captured ship")
	# bounty: posted, taken, fought on arrival
	sim._post_bounty()
	var bs := sim.open_bounties()
	check(bs.size() == 1 and bs[0]["reward"] > 0, "a bounty is posted at the tavern")
	var c: Dictionary = bs[0]
	check(sim.take_bounty(int(c["id"]))["ok"] and c["taker"] == sim.pid(), "the player takes the bounty")
	for sh in sim.ships_of():
		sh["port"] = c["port"]
		sh["to"] = ""
	fl["port"] = "qianqi" if c["port"] != "qianqi" else "muxia"
	fl["from"] = fl["port"]
	fl["to"] = c["port"]
	fl["depart"] = sim.s["day"]
	fl["arrive"] = sim.s["day"]
	fl["port"] = ""
	sim._tick_ships()
	check(sim.s["encounter"] != null and sim.s["encounter"]["kind"] == "bounty", "arriving at the bounty port starts the fight")
	check(not sim.encounter_pay()["ok"], "bounty targets take no toll")
	sim.encounter_fight()
	for u in sim.battle.b["units"]:
		if int(u["home"]) == 1:
			u["status"] = "sunk"
	sim.battle.b["over"] = "win"
	var g2: float = sim.house()["gold"]
	var out3 := sim.end_battle()
	check(int(out3["bounty"]) == int(c["reward"]) and sim.open_bounties().is_empty() and sim.house()["gold"] > g2, "the bounty pays out and is removed")
	# the contract board ignores bounties for deliveries
	check(not sim.can_fulfill(fl, {"kind": "bounty", "port": fl["port"], "good": "", "qty": 0}), "bounties are never delivered as goods")


func test_crew() -> void:
	print("companions")
	var sim := Sim.new()
	sim.new_game(31)
	var fl := sim.flagship()
	sim.house()["gold"] = 60000.0
	check(sim.recruitable_at("muxia", "tavern") == ["xiaoman"], "小满 waits in the 暮霞港 tavern")
	check(not sim.recruit("xiaoman", "qianqi", "tavern")["ok"], "a companion is only hired where they are")
	check(not sim.recruit_ok("qian", "qianqi", "tavern")["ok"], "钱不让 needs reputation first")
	var g0: float = sim.house()["gold"]
	check(sim.recruit("xiaoman", "muxia", "tavern")["ok"] and sim.crew().has("xiaoman") and sim.house()["gold"] < g0, "hiring 小满 costs the signing fee")
	check(sim.crew_wages() == 120, "wages are summed (%d)" % sim.crew_wages())
	# posts change travel time and prices
	sim.house()["rep"] = 700
	check(sim.recruit("qian", "qianqi", "tavern")["ok"], "钱不让 joins once reputation allows")
	var buy0 := sim.buy_price("qianqi", "silk")
	check(sim.set_post("qian", "acct")["ok"] and sim.buy_price("qianqi", "silk") < buy0, "an accountant lowers buy prices (%d -> %d)" % [buy0, sim.buy_price("qianqi", "silk")])
	var d0 := sim.travel_days("qianqi", "cuijing", "freighter")
	sim.house()["bp"]["silk"] = true
	sim.s["story"] = 1
	check(sim.recruit("luqing", "xiajing", "tavern")["ok"], "陆青 joins after the first story chapter")
	check(sim.set_post("luqing", "nav")["ok"] and sim.travel_days("qianqi", "cuijing", "freighter") <= d0, "a navigator shortens voyages")
	check(sim.set_post("qian", "nav")["ok"] and sim.crew()["luqing"]["post"] == "" and sim.crew()["qian"]["post"] == "nav", "a post holds one person; the previous holder steps down")
	check(not sim.set_post("luqing", "captain", fl["id"])["ok"], "nobody captains the flagship")
	var r2: Dictionary = sim.buy_ship("freighter", fl["port"])
	check(sim.set_post("luqing", "captain", int(r2["ship"]))["ok"] and sim.speed_mult(sim.ship(int(r2["ship"]))) > 1.0, "a captain speeds up her ship")
	# cap, gifts, affinity and story chapters
	check(sim.crew_cap() == Characters.CREW_CAP[sim.rep_level() - 1], "crew cap follows reputation")
	var a0: int = sim.crew()["xiaoman"]["aff"]
	check(sim.gift("xiaoman")["ok"] and sim.crew()["xiaoman"]["aff"] == a0 + Characters.GIFT_AFF and not sim.gift("xiaoman")["ok"], "one gift per month raises affinity")
	sim.crew()["xiaoman"]["aff"] = 30
	sim.s["event"] = null
	sim._tick_crew()
	check(sim.s["event"] != null and str(sim.s["event"]["id"]).begins_with("char:xiaoman:0"), "a chapter opens at affinity 30 in port")
	var res := EventBook.resolve(sim, 0)
	check(res["ok"] and sim.crew()["xiaoman"]["chapter"] == 1 and sim.crew()["xiaoman"]["aff"] > 30, "the chapter is resolved and remembered")
	sim.crew()["xiaoman"]["chapter"] = 2
	sim.crew()["xiaoman"]["aff"] = 100
	sim._tick_crew()
	EventBook.resolve(sim, 0)
	check(sim.crew()["xiaoman"]["spec_lvl"] == 2 and sim.spec_bonus("rumours") == 1.5, "finishing the story upgrades the specialty")
	# battle hero block and the shipwright's blueprint
	sim.s["ports"]["tonghe"]["friend"][sim.pid()] = 150
	check(sim.recruit("cen", "tonghe", "yard")["ok"] and sim.has_bp("astro"), "老岑 brings the astrolabe blueprint")
	sim.s["stats"]["wins"] = 1
	check(sim.recruit("aman", "chishi", "tavern")["ok"] and sim.battle_hero()["fire_mult"] > 1.1, "阿蛮 joins after a win and boosts gunnery")
	# wages are paid monthly
	var g1: float = sim.house()["gold"]
	sim.s["day"] = GameData.DAYS_MONTH - 1
	sim.advance_day()
	check(sim.house()["gold"] < g1 - float(sim.crew_wages()) + 1.0, "monthly wages are deducted")
	# save / load
	var sim2 := Sim.new()
	check(sim2.from_json(sim.to_json()) and sim2.crew().size() == sim.crew().size() and sim2.crew()["luqing"]["post"] == "captain", "companions survive save/load")
	check(sim.dismiss("qian")["ok"] and not sim.crew().has("qian") and not sim.recruit_ok("qian", "qianqi", "tavern")["ok"], "a dismissed companion does not come back")


func test_rivals_and_hq() -> void:
	print("rival meetings, companion pairs and the headquarters")
	var sim := Sim.new()
	sim.new_game(13)
	var fl := sim.flagship()
	sim.house()["gold"] = 50000.0
	# a rival meeting offers a wager, a blueprint, a bribe and a drink
	sim.s["day"] = 100
	EventBook.rival_meeting(sim, "iron")
	var ev: Dictionary = sim.s["event"]
	check(ev["id"] == "rival:iron" and ev["choices"].size() == 5, "韦朔 hails you with five choices (%d)" % ev["choices"].size())
	var bp_choice := -1
	for i in ev["choices"].size():
		if ev["choices"][i]["effects"].has("buy_bp"):
			bp_choice = i
	check(bp_choice >= 0, "the rival sells a blueprint you do not own")
	var good: String = ev["choices"][bp_choice]["effects"]["buy_bp"]["good"]
	var g0: float = sim.house()["gold"]
	check(EventBook.resolve(sim, bp_choice)["ok"] and sim.has_bp(good) and sim.house()["gold"] < g0, "buying the rival's %s blueprint costs gold and grants it" % good)
	# the wager moves gold one way or the other and the rival pays or pockets it
	EventBook.rival_meeting(sim, "iron")
	var rg0: float = sim.house("iron")["gold"]
	g0 = sim.house()["gold"]
	EventBook.resolve(sim, 0)
	var diff: float = sim.house()["gold"] - g0
	check(absf(diff) >= 1000.0 and absf(sim.house("iron")["gold"] - rg0 + diff) < 1.0, "the race moves the stake between the houses (%+d)" % int(diff))
	# bribing the harbour master holds the rival's docked ships here
	var rival: Dictionary = sim.ships_of("iron")[0]
	rival["port"] = fl["port"]
	rival["to"] = ""
	EventBook.rival_meeting(sim, "iron")
	ev = sim.s["event"]
	var delay_choice := -1
	for i in ev["choices"].size():
		if ev["choices"][i]["effects"].has("delay_rival"):
			delay_choice = i
	var held := 0
	var caught := 0
	for k in 8:
		sim.house()["rep"] = 500
		rival["idle_until"] = 0
		EventBook.rival_meeting(sim, "iron")
		EventBook.resolve(sim, delay_choice)
		if int(rival.get("idle_until", 0)) > int(sim.s["day"]):
			held += 1
		elif int(sim.house()["rep"]) < 500:
			caught += 1
	check(held + caught == 8 and held >= 3, "the bribe holds the ship or gets found out (%d held, %d caught)" % [held, caught])
	# a debate with 殷望舒 moves reputation
	sim.house()["rep"] = 500
	EventBook.rival_meeting(sim, "tower")
	EventBook.resolve(sim, 0)
	check(int(sim.house()["rep"]) != 500, "the debate changes reputation (%d)" % int(sim.house()["rep"]))
	# meetings trigger on arrival when a rival ship is docked here, not too often
	var met := 0
	sim.s["story"] = 3   # keep the main story from pre-empting the quay
	for k in 40:
		sim.s["day"] = 200 + k * 60
		sim.s["event"] = null
		sim.s.erase("rival_met")
		rival["port"] = fl["port"]
		sim.s["arrived"] = fl["id"]
		EventBook.maybe_trigger(sim)
		if sim.s["event"] != null and str(sim.s["event"]["id"]).begins_with("rival:"):
			met += 1
	check(met >= 8 and met <= 32, "docking beside a rival sometimes brings a hail (%d/40)" % met)
	sim.s["event"] = null
	sim.s["rival_met"] = int(sim.s["day"])
	sim.s["arrived"] = fl["id"]
	EventBook.maybe_trigger(sim)
	check(sim.s["event"] == null or not str(sim.s["event"]["id"]).begins_with("rival:"), "a second hail waits %d days" % GameData.RIVAL_MEET_GAP)
	sim.s["event"] = null
	# companion pairs
	sim.house()["gold"] = 80000.0
	sim.house()["rep"] = 3600
	sim.s["stats"]["wins"] = 1
	check(sim.recruit("aman", "qianqi", "tavern")["ok"] and sim.recruit("shen", "fengyue", "tavern")["ok"], "阿蛮 and 沈白鹭 join")
	sim.crew()["aman"]["aff"] = 45
	sim.crew()["shen"]["aff"] = 45
	sim.crew()["aman"]["chapter"] = 1   # personal chapters come first; the next one needs 60
	sim.crew()["shen"]["chapter"] = 1
	sim.s["event"] = null
	sim._tick_crew()
	check(sim.s["event"] != null and str(sim.s["event"]["id"]).begins_with("pair:"), "two well-liked companions share a scene in port")
	var a0: int = sim.crew()["aman"]["aff"]
	var r := EventBook.resolve(sim, 0)
	check(r["ok"] and sim.crew()["aman"]["aff"] > a0 and sim.crew()["shen"]["aff"] > 45 and sim.s["pairs_done"].size() == 1, "the scene raises both affinities and is remembered")
	sim._tick_crew()
	check(sim.s["event"] == null, "a pair scene happens once")
	# the headquarters
	fl["port"] = "muxia"
	check(not sim.hq_ok()["ok"], "the HQ needs the flagship at home")
	fl["port"] = "qianqi"
	fl["to"] = ""
	var cap0 := sim.crew_cap()
	var w0 := sim.crew_wages()
	g0 = sim.house()["gold"]
	check(sim.upgrade_hq()["ok"] and sim.hq_level() == 1 and sim.crew_cap() == cap0 + 1 and sim.house()["gold"] == g0 - 20000.0, "the first hall adds a companion slot")
	var rep0: int = sim.house()["rep"]
	sim.house()["gold"] = 300000.0
	check(sim.upgrade_hq()["ok"] and sim.crew_wages() < w0, "the second hall discounts wages (%d -> %d)" % [w0, sim.crew_wages()])
	var ships0 := sim.max_ships()
	sim.house()["rep"] = 3600
	check(sim.upgrade_hq()["ok"] and sim.max_ships() == ships0 + 1 and not sim.hq_ok()["ok"], "the top hall adds a ship and is the last level")
	sim.house()["rep"] = rep0
	sim.s["day"] = GameData.DAYS_MONTH * 5 - 1
	sim.advance_day()
	check(int(sim.house()["rep"]) >= rep0 + int(GameData.HQ[3]["rep"]), "the hall earns reputation monthly (%d -> %d)" % [rep0, int(sim.house()["rep"])])
	var sim2 := Sim.new()
	check(sim2.from_json(sim.to_json()) and sim2.hq_level() == 3 and sim2.s["pairs_done"].size() == 1, "HQ level and pair scenes survive save/load")


func test_city_works() -> void:
	print("city works and benefactors")
	var sim := Sim.new()
	sim.new_game(14)
	var fl := sim.flagship()
	var port: String = fl["port"]
	check(not sim.work_ok(port, "dock")["ok"], "city works need reputation 船东 first")
	sim.house()["rep"] = 200
	sim.house()["gold"] = 200000.0
	var fuel0 := sim.fuel_cost_for(fl, "muxia")
	var f0 := sim.friend_pts(port)
	var g0: float = sim.house()["gold"]
	check(sim.fund_work(port, "dock")["ok"] and sim.work_level(port, "dock") == 1 and sim.house()["gold"] == g0 - 10000.0 and sim.friend_pts(port) > f0, "funding the docks costs 10,000 and raises friendship")
	check(sim.benefactor(port) == sim.pid() and sim.benefactor_ports() == [port], "the only funder is the city's benefactor")
	check(sim.fuel_cost_for(fl, "muxia") < fuel0, "docks cut supplies for voyages from here (%d -> %d)" % [fuel0, sim.fuel_cost_for(fl, "muxia")])
	var buy_plain := sim.buy_price(port, "silk", "iron")
	check(sim.buy_price(port, "silk") < buy_plain, "the benefactor buys cheaper here")
	# the market recovers faster with a bigger marketplace
	var m: Dictionary = sim.s["ports"][port]["market"]["silk"]
	m["stock"] = float(m["eq"]) * 0.5
	sim._tick_markets()
	var slow: float = m["stock"]
	m["stock"] = float(m["eq"]) * 0.5
	sim.fund_work(port, "market")
	sim._tick_markets()
	check(m["stock"] > slow, "a bigger market recovers faster (%.1f vs %.1f)" % [m["stock"], slow])
	# the school raises workshop output in this city
	sim.house()["bp"]["cocoon"] = true
	var pl := {"b": "cocoon", "lvl": 1, "owner": sim.pid()}
	var out0 := Industry.output(sim, port, pl)
	sim.fund_work(port, "school")
	sim.fund_work(port, "school")
	check(Industry.output(sim, port, pl) > out0, "a school raises output here (%d -> %d)" % [out0, Industry.output(sim, port, pl)])
	check(sim.fund_work(port, "school")["ok"] and not sim.fund_work(port, "school")["ok"], "each work stops at level %d" % GameData.WORK_MAX)
	# a rival can outspend you and take the title
	sim.house("iron")["gold"] = 500000.0
	for k in ["dock", "dock", "market", "market"]:
		sim.fund_work(port, k, "iron")
	check(sim.benefactor(port) == "iron", "the biggest funder becomes the benefactor")
	# monthly reputation for the benefactor, and the AI funds works when flush
	var rep0: int = sim.house("iron")["rep"]
	sim.s["day"] = GameData.DAYS_MONTH * 3 - 1
	sim.advance_day()
	check(int(sim.house("iron")["rep"]) >= rep0 + GameData.BENEFACTOR_REP, "a benefactor earns reputation monthly")
	var tw := sim.house("tower")
	tw["gold"] = 400000.0
	var funded := false
	for k in 12:
		AiPlayer.monthly(sim, "tower")
		if float(sim.works("xiajing")["spent"].get("tower", 0.0)) > 0.0:
			funded = true
			break
	check(funded, "a rich rival funds works in its home city")
	var sim2 := Sim.new()
	check(sim2.from_json(sim.to_json()) and sim2.work_level(port, "school") == 3 and sim2.benefactor(port) == "iron", "works survive save/load")


func test_festival() -> void:
	print("the lantern festival and rival races")
	var sim := Sim.new()
	sim.new_game(15)
	var fl := sim.flagship()
	check(not sim.festival_on(), "no festival in the first year")
	var sell0 := sim.sell_price(fl["port"], "fruit")
	sim.house()["gold"] = 90000.0   # the biggest gain in worth this year
	var rep := {}
	for hid in GameData.HOUSE_IDS:
		rep[hid] = int(sim.house(hid)["rep"])
	sim.s["day"] = GameData.DAYS_YEAR - 1
	sim.s["event"] = null
	sim.advance_day()
	var f = sim.s["festival_show"]
	check(f != null and int(f["year"]) == 1 and f["houses"].size() == 3, "the new year opens the festival with a review of every house")
	var kinds: Array = f["awards"].map(func(a): return a["kind"])
	check("race" in kinds and "trade" in kinds, "a race prize and a merchant prize are handed out (%s)" % str(kinds))
	var trade_winner := ""
	for a in f["awards"]:
		if a["kind"] == "trade":
			trade_winner = a["hid"]
	check(trade_winner == sim.pid() and int(sim.house()["rep"]) >= rep[sim.pid()] + GameData.FESTIVAL_REP["trade"], "the merchant prize goes to the biggest gain and pays reputation")
	check(sim.festival_on() and sim.sell_price(fl["port"], "fruit") > sell0, "festival goods sell for more while the lanterns are up")
	sim.s["day"] = GameData.DAYS_YEAR + GameData.FESTIVAL_DAYS
	check(not sim.festival_on(), "the festival ends after %d days" % GameData.FESTIVAL_DAYS)
	check(sim.s["festival"]["worth"].has("iron") and int(sim.s["festival"]["year"]) == 1, "the year's worth is remembered for next year's prize")
	# a benefactor of two cities takes the builders' prize
	sim.house()["rep"] = 1000
	sim.house()["gold"] = 100000.0
	sim.fund_work("qianqi", "dock")
	sim.fund_work("muxia", "dock")
	sim.s["day"] = GameData.DAYS_YEAR * 2 - 1
	sim.s["festival_show"] = null
	sim.s["story"] = 3   # the main story would otherwise block the day
	sim.s["event"] = null
	sim.advance_day()
	var works_winner := ""
	for a in sim.s["festival_show"]["awards"]:
		if a["kind"] == "works":
			works_winner = a["hid"]
	check(works_winner == sim.pid(), "the builders' prize goes to the house with most benefactor cities")
	# two rival ships in one port race now and then
	sim.s["festival_show"] = null
	var a: Dictionary = sim.ships_of("iron")[0]
	var b: Dictionary = sim.ships_of("tower")[0]
	var races := 0
	for k in 60:
		sim.s["day"] = 800 + k * 40
		a["port"] = "fengyue"
		a["to"] = ""
		b["port"] = "fengyue"
		b["to"] = ""
		var n0 := int(sim.s["stats"].get("rival_races", 0))
		AiPlayer.ship_turn(sim, a)
		if int(sim.s["stats"].get("rival_races", 0)) > n0:
			races += 1
	check(races >= 1 and races <= 20, "rival captains race each other now and then (%d/60)" % races)
	var sim2 := Sim.new()
	check(sim2.from_json(sim.to_json()) and int(sim2.s["festival"]["year"]) == 2, "festival state survives save/load")


## Sail the flagship to dest and run days until it is docked again (or something interrupts).
func _sail_to(sim: Sim, dest: String) -> Dictionary:
	var fl := sim.flagship()
	var r := sim.depart(fl["id"], dest)
	if not r["ok"]:
		return r
	for i in 60:
		sim.advance_day()
		if sim.s["event"] != null:
			EventBook.resolve(sim, sim.s["event"]["choices"].size() - 1 if str(sim.s["event"]["id"]).begins_with("rival:") else 0)
		if sim.s["encounter"] != null:
			sim.encounter_pay()
		if sim.docked(sim.flagship()):
			break
	return r


func test_explore() -> void:
	print("exploring the eastern fog")
	var sim := Sim.new()
	sim.new_game(77)
	var fl := sim.flagship()
	check(sim.open_ports().size() == GameData.WEST_IDS.size(), "the eastern cities start off the charts")
	check(not sim.depart(fl["id"], "qinglu")["ok"], "nobody can sail to an uncharted city")
	check(not sim.depart(fl["id"], "fengxi")["ok"], "the strait is unknown before the expedition")
	check(not sim.expedition_ok()["ok"], "an expedition needs reputation")
	sim.house()["rep"] = GameData.REP_LEVELS[GameData.EXPEDITION_REP - 1]
	sim.house()["gold"] = 100000.0
	var g0: float = sim.house()["gold"]
	check(sim.sponsor_expedition()["ok"] and sim.explore_open() and sim.house()["gold"] == g0 - GameData.EXPEDITION_COST, "sponsoring the expedition charts the strait")
	check(sim.seen_spots() == ["fengxi"], "only the strait is visible at first (%s)" % str(sim.seen_spots()))
	check(not sim.depart(fl["id"], "qinglu")["ok"], "the eastern cities are still hidden")
	# a rival cannot sail east; an escort cannot explore
	var rival: Dictionary = sim.ships_of("iron")[0]
	check(not sim.depart(rival["id"], "fengxi")["ok"], "rivals do not explore")
	sim.s["day"] = 100
	var r := _sail_to(sim, "fengxi")
	check(r["ok"] and sim.docked(sim.flagship()) and sim.flagship()["port"] == "fengxi", "the flagship anchors at the strait")
	check(sim.spot_found("fengxi") and sim.s["discovery"] != null and sim.s["discovery"]["kind"] == "passage", "reaching the strait is a discovery")
	sim.s["discovery"] = null
	var seen := sim.seen_spots()
	check("qinglu" in seen and "wreck_a" in seen and "jinduo" in seen, "the strait reveals what lies within sight (%s)" % str(seen))
	check(not ("wuyin" in seen), "the deep fog stays hidden")
	# a hidden city becomes a real port
	var exp0 := int(sim.hero()["exp"])
	r = _sail_to(sim, "qinglu")
	check(r["ok"] and sim.flagship()["port"] == "qinglu" and sim.port_open("qinglu"), "the flagship reaches and charts 青芦港")
	check(sim.open_ports().size() == GameData.WEST_IDS.size() + 1 and sim.s["intel"]["qinglu"] != null, "a found city joins the charts with fresh intel")
	check(int(sim.hero()["exp"]) > exp0 and sim.friend_level("qinglu") >= 1, "discovery pays experience and friendship")
	check(sim.buy_price("qinglu", "wine") < sim.buy_price("qianqi", "wine"), "the east makes the processed goods the west lacks (%d vs %d)" % [sim.buy_price("qinglu", "wine"), sim.buy_price("qianqi", "wine")])
	check(sim.sail_ok(rival, "qinglu")["ok"], "once charted, rivals may trade there too")
	sim.s["discovery"] = null
	# a ruin: rewards, then the fleet waits in the fog for the next order
	var found0 := sim.found_spots().size()
	sim.s["explore"]["found"]["jinduo"] = true   # pretend the bell ruin is in sight
	sim.s["day"] = 400
	g0 = sim.house()["gold"]
	r = _sail_to(sim, "ruin_bell")
	check(r["ok"] and sim.docked(sim.flagship()) and sim.flagship()["port"] == "ruin_bell", "the flagship anchors at the ruin")
	check(sim.house()["gold"] >= g0 + 6000 - 4000 and sim.found_spots().size() == found0 + 2, "the ruin pays out (%d -> %d)" % [int(g0), int(sim.house()["gold"])])
	check(not sim.depart(sim.flagship()["id"], "ruin_bell")["ok"], "a found spot is not a destination again")
	check(sim.depart(sim.flagship()["id"], "jinduo")["ok"], "the fleet can sail on from the fog")
	# the derelict gunboat
	sim.s["explore"]["found"]["jiaoyan"] = true
	for i in 30:
		sim.advance_day()
		if sim.docked(sim.flagship()):
			break
	sim.s["discovery"] = null
	var n0 := sim.ships_of(sim.pid()).size()
	r = _sail_to(sim, "wreck_c")
	check(r["ok"] and sim.ships_of(sim.pid()).size() == n0 + 1, "the stranded gunboat joins the fleet (%d -> %d)" % [n0, sim.ships_of(sim.pid()).size()])
	sim.s["discovery"] = null
	# a survey boat explores on its own, and can be called back from the fog
	sim.s["explore"]["found"]["baisha"] = true
	var sv: Dictionary = sim.buy_ship("survey", sim.flagship()["port"])
	check(sv["ok"], "a survey boat can be bought in the east")
	var svs := sim.ship(int(sv["ship"]))
	var sight0 := sim.sight()
	check(sight0 > GameData.SIGHT, "a survey boat in the fleet widens the view (%.0f)" % sight0)
	check(sim.sail_ok(svs, "ruin_garden")["ok"] and sim.depart(int(sv["ship"]), "ruin_garden")["ok"], "the survey boat may go exploring alone")
	for i in 60:
		sim.advance_day()
		if sim.docked(sim.ship(int(sv["ship"]))):
			break
	check(sim.spot_found("ruin_garden") and sim.has_bp("balm"), "the survey boat's find counts: the balm secret from the hanging garden")
	sim.s["discovery"] = null
	check(sim.depart(int(sv["ship"]), sim.nearest_open_port("ruin_garden"))["ok"], "the survey boat sails back to the nearest charted port")
	# pirates rob rivals too
	var rv: Dictionary = sim.ships_of("iron")[0]
	var rh := sim.house("iron")
	rh["gold"] = 50000.0
	rv["port"] = "tonghe"
	rv["to"] = ""
	sim._stow(rv, "copper", 20, 40.0)
	var raid := sim._rival_raid(rv, "qianqi", true)
	check(raid.has("result") and (raid["result"] != "toll" or rh["gold"] == 50000.0 - raid["gold"]), "a raided rival pays the toll or fights (%s)" % str(raid))
	rh["gold"] = 100.0
	var raid2 := sim._rival_raid(rv, "qianqi", true)
	check(raid2["result"] != "toll", "a broke rival loses cargo instead (%s)" % str(raid2))
	# eastern companions
	sim.house()["gold"] = 60000.0
	check("lusheng" in sim.recruitable_at("qinglu", "tavern"), "芦生 waits in the 青芦港 tavern")
	var west_sell := sim.sell_price("qianqi", "wine")
	check(sim.recruit("lusheng", "qinglu", "tavern")["ok"] and sim.sell_price("qianqi", "wine") > west_sell, "芦生 raises western prices for eastern wares (%d -> %d)" % [west_sell, sim.sell_price("qianqi", "wine")])
	sim.add_friend("jinduo", sim.pid(), 150)
	var east_days := sim.travel_days("qinglu", "jinduo", "freighter")
	check(sim.recruit("duoyin", "jinduo", "guild")["ok"] and sim.travel_days("qinglu", "jinduo", "freighter") <= east_days, "铎音 shortens eastern voyages")
	# save / load keeps the charts
	var json := sim.to_json()
	var sim2 := Sim.new()
	check(sim2.from_json(json) and sim2.explore_open() and sim2.spot_found("qinglu") and sim2.open_ports().size() == sim.open_ports().size(), "exploration survives save and load")
	# an old save without the eastern ports gets them
	var parsed = JSON.parse_string(json)
	for pid in GameData.EAST_IDS:
		parsed["ports"].erase(pid)
	parsed["explore"] = {"open": false, "found": {}}
	var sim3 := Sim.new()
	check(sim3.from_json(JSON.stringify(parsed)) and sim3.s["ports"].has("wuyin") and sim3.s["intel"].has("wuyin"), "old saves gain the eastern ports")


func test_bot_player(sd: int) -> Dictionary:
	print("bot player seed %d" % sd)
	var sim := Sim.new()
	sim.new_game(sd)
	var early := 0
	var guard := 0
	while sim.s["over"] == null and sim.s["crown"] == null and guard < GameData.DAYS_YEAR * 12:
		if sim.s["event"] != null:
			EventBook.resolve(sim, sim.s["event"]["choices"].size() - 1 if str(sim.s["event"]["id"]).begins_with("rival:") else 0)
		if sim.s["encounter"] != null:
			sim.auto_encounter()
		if sim.s["discovery"] != null:
			sim.s["discovery"] = null
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


func test_quests() -> void:
	print("companion errands, trios and festival moments")
	var sim := Sim.new()
	sim.new_game(17)
	sim.s["day"] = 1   # every tenth day adds +1 affinity to all; keep the arithmetic exact
	var fl := sim.flagship()
	sim.house()["gold"] = 80000.0
	sim.house()["rep"] = 3600
	sim.s["stats"]["wins"] = 1
	sim.s["story"] = 3
	check(sim.recruit("aman", "qianqi", "tavern")["ok"], "阿蛮 joins")
	sim.crew()["aman"]["aff"] = Characters.QUEST_AFF
	sim.crew()["aman"]["chapter"] = 2   # the next chapter needs 100, so the errand comes first
	sim.s["event"] = null
	sim._tick_crew()
	check(sim.s["event"] != null and str(sim.s["event"]["id"]) == "quest:aman", "at affinity %d a companion asks a personal errand" % Characters.QUEST_AFF)
	check(EventBook.resolve(sim, 0)["ok"] and sim.quest_state("aman") == "active", "accepting makes the errand active")
	sim._tick_crew()
	check(sim.s["event"] == null, "an errand is asked once")
	var q: Dictionary = Characters.QUESTS["aman"]
	check(not sim.quest_ok("aman")["ok"], "delivery needs the flagship at %s with the goods" % GameData.port_name(q["port"]))
	fl["port"] = q["port"]
	fl["to"] = ""
	sim._stow(fl, q["good"], int(q["qty"]), 100.0)
	var g0: float = sim.house()["gold"]
	var r0: int = sim.house()["rep"]
	var a0: int = sim.crew()["aman"]["aff"]
	var d := sim.quest_deliver("aman")
	check(d["ok"] and sim.quest_state("aman") == "done" and sim.house()["gold"] == g0 + float(q["gold"]) and sim.house()["rep"] > r0 and sim.crew()["aman"]["aff"] == a0 + Characters.QUEST_DONE_AFF and int(sim.fleet_cargo(fl).get(q["good"], {}).get("qty", 0)) == 0, "delivering pays %d gold, reputation and affinity and takes the goods" % int(q["gold"]))
	# the second, larger errand: 阿蛮 asks for a battle won (round 19)
	var wage0 := sim.crew_wages()
	sim.crew()["aman"]["aff"] = Characters.QUEST2_AFF
	sim.s["event"] = null
	sim._tick_crew()
	check(sim.s["event"] != null and str(sim.s["event"]["id"]) == "quest:aman#2" and str(sim.s["event"]["text"]).contains("不再领薪水"), "after the first errand and affinity %d a second one is asked" % Characters.QUEST2_AFF)
	check(EventBook.resolve(sim, 0)["ok"] and sim.quest_state("aman#2") == "active" and not sim.quest_ok("aman#2")["ok"], "a fight errand cannot be handed in, only won")
	sim._tick_quests()
	check(sim.quest_state("aman#2") == "active", "no battle yet, still waiting")
	sim.s["stats"]["wins"] = int(sim.s["stats"].get("wins", 0)) + 1
	var g2: float = sim.house()["gold"]
	sim._tick_quests()
	check(sim.quest_state("aman#2") == "done" and sim.house()["gold"] == g2 + float(Characters.QUESTS2["aman"]["gold"]) and sim.crew()["aman"].get("free", false) and sim.crew_wages() == wage0 - int(Characters.CHARS["aman"]["wage"]), "winning a battle completes it; 阿蛮 keeps a keepsake and stops taking wages (%d -> %d)" % [wage0, sim.crew_wages()])
	sim.crew()["aman"]["chapter"] = 3   # affinity 100 would open his last chapter; not what we test here
	sim.s["event"] = null
	sim._tick_crew()
	check(sim.s["event"] == null, "no third errand")
	# declining and failing
	check(sim.recruit("shen", "fengyue", "tavern")["ok"], "沈白鹭 joins")
	sim.crew()["shen"]["aff"] = Characters.QUEST_AFF
	sim.crew()["shen"]["chapter"] = 2
	sim.s["pairs_done"] = {"0": true}
	sim.s["event"] = null
	sim._tick_crew()
	check(sim.s["event"] != null and str(sim.s["event"]["id"]) == "quest:shen", "the next companion asks hers")
	check(EventBook.resolve(sim, 1)["ok"] and sim.quest_state("shen") == "declined" and sim.crew()["shen"]["aff"] == Characters.QUEST_AFF - 3, "declining costs a little affinity")
	sim.quests()["shen"] = {"state": "active", "end": int(sim.s["day"]) - 1}
	var s0: int = sim.crew()["shen"]["aff"]
	sim._tick_crew()
	check(sim.quest_state("shen") == "failed" and sim.crew()["shen"]["aff"] == s0 - Characters.QUEST_FAIL_AFF, "an overdue errand fails and costs %d affinity" % Characters.QUEST_FAIL_AFF)
	# three companions share a scene
	sim.s["crew"]["sang"] = sim.s["crew"]["aman"].duplicate(true)
	sim.s["crew"]["sang"]["post"] = ""
	for cid in ["aman", "shen", "sang"]:
		sim.crew()[cid]["aff"] = Characters.TRIO_AFF
		sim.crew()[cid]["chapter"] = 2
	sim.quests()["sang"] = {"state": "declined", "end": 0}
	sim.quests()["shen"] = {"state": "declined", "end": 0}
	sim.s["event"] = null
	sim._tick_crew()
	check(sim.s["event"] != null and str(sim.s["event"]["id"]) == "trio:0", "three fond companions share a scene")
	check(EventBook.resolve(sim, 0)["ok"] and sim.crew()["sang"]["aff"] == Characters.TRIO_AFF + 10 and sim.s["trios_done"].has("0"), "the trio scene raises all three affinities and is remembered")
	sim._tick_crew()
	check(sim.s["event"] == null, "a trio scene happens once")
	# a companion's moment at the festival
	sim.s["day"] = GameData.DAYS_YEAR - 1
	sim.s["event"] = null
	sim.advance_day()
	var f = sim.s["festival_show"]
	check(f != null and f.has("act") and sim.crew().has(f["act"]["cid"]), "a companion has a moment at the lantern festival (%s)" % str(f["act"]["cid"] if f != null and f.has("act") else ""))
	# a visit errand is done by docking there (round 19)
	sim.s["crew"]["moyu"] = sim.s["crew"]["aman"].duplicate(true)
	sim.s["crew"]["moyu"]["post"] = ""
	sim.s["crew"]["moyu"].erase("free")
	sim.crew()["moyu"]["aff"] = Characters.QUEST2_AFF
	sim.crew()["moyu"]["chapter"] = 2
	sim.quests()["moyu"] = {"state": "done", "end": 0}
	sim.s["event"] = null
	sim.s["festival_show"] = null
	sim._tick_crew()
	check(sim.s["event"] != null and str(sim.s["event"]["id"]) == "quest:moyu#2", "莫语 asks to be taken to 翠鲸岛")
	EventBook.resolve(sim, 0)
	check(not sim.quest_ok("moyu#2")["ok"] and sim.quests_at("cuijing") == ["moyu#2"], "the visit shows up at that port's tavern and nowhere else")
	fl["port"] = "cuijing"
	fl["to"] = ""
	check(sim.quest_deliver("moyu#2")["ok"] and sim.quest_state("moyu#2") == "done" and sim.crew()["moyu"].get("free", false), "docking there completes the visit")
	# save and load keep it all
	var sim2 := Sim.new()
	sim2.from_json(sim.to_json())
	check(sim2.quest_state("aman") == "done" and sim2.quest_state("aman#2") == "done" and sim2.crew()["aman"].get("free", false) and sim2.s["trios_done"].has("0"), "errands, keepsakes and trio scenes survive a save")


func test_milestones() -> void:
	print("milestones")
	var sim := Sim.new()
	sim.new_game(21)
	sim.s["day"] = 1
	check(sim.next_milestones(1)[0]["id"] == "first_trade" and sim.milestones().is_empty(), "a new game starts with the first trade ahead")
	var r0: int = sim.house()["rep"]
	sim.s["stats"]["trades"] = 1
	sim._tick_milestones()
	check(sim.milestone_done("first_trade") and sim.house()["rep"] == r0 + GameData.MILESTONE_REP and sim.next_milestones(1)[0]["id"] == "profit_10k", "the first trade is a milestone worth %d reputation; the next one is named" % GameData.MILESTONE_REP)
	sim._tick_milestones()
	check(sim.house()["rep"] == r0 + GameData.MILESTONE_REP, "a milestone pays once")
	var ids: Array = GameData.MILESTONES.map(func(m): return m["id"])
	for id in ids:
		sim.milestone_check(id)   # every check runs without error
	sim.s["hero"]["visited"]["jinduo"] = true
	sim.house()["gold"] = 1500000.0
	sim._tick_milestones()
	check(sim.milestone_done("east") and sim.milestone_done("worth_1m") and not sim.milestone_done("lh3"), "milestones are independent of order")
	var sim2 := Sim.new()
	sim2.from_json(sim.to_json())
	check(sim2.milestone_done("east") and int(sim2.milestones()["east"]) == 1, "milestones survive a save with their day")
	# the festival stat feeds the award milestone
	sim.s["stats"]["awards"] = 1
	sim._tick_milestones()
	check(sim.milestone_done("award"), "a festival prize counts")


func test_festival_challenge() -> void:
	print("a rival's challenge at the lantern festival")
	var sim := Sim.new()
	sim.new_game(18)
	sim.s["story"] = 3
	sim.house()["gold"] = 50000.0
	var got := 0
	var declined := false
	var fought := false
	for i in 24:
		sim.s["day"] = (i + 1) * GameData.DAYS_YEAR - 1
		sim.s["event"] = null
		sim.s["encounter"] = null
		sim.advance_day()
		var f = sim.s["festival_show"]
		if f == null or not f.has("challenge"):
			continue
		got += 1
		check(sim.s["event"] != null and str(sim.s["event"]["id"]) == "rival:%s" % f["challenge"] and sim.s["event"]["title"].begins_with("灯节"), "the review names the challenger and the challenge waits behind it")
		if not declined:
			var r0: int = sim.house()["rep"]
			var g0: float = sim.house()["gold"]
			check(EventBook.resolve(sim, sim.s["event"]["choices"].size() - 1)["ok"] and sim.house()["rep"] == r0 and sim.house()["gold"] == g0, "declining costs nothing")
			declined = true
		elif not fought:
			var r1: int = sim.house()["rep"]
			var g1: float = sim.house()["gold"]
			var fx: Dictionary = sim.s["event"]["choices"][0]["effects"]
			check(EventBook.resolve(sim, 0)["ok"] and (sim.house()["rep"] != r1 or sim.house()["gold"] != g1), "the duel moves reputation or gold")
			check(int(fx.get("race", {}).get("rep", 0)) == GameData.FESTIVAL_DUEL_REP["win"] or int(fx.get("debate", {}).get("win", 0)) == GameData.FESTIVAL_DUEL_REP["win"], "festival stakes are higher than a quay-side hail")
			fought = true
		if declined and fought:
			break
	check(got >= 2, "rivals challenge at some festivals (%d of 24)" % got)
	# every house's leader has their own words when they hail you
	var sim2 := Sim.new()
	sim2.new_game(18, "iron")
	EventBook.rival_meeting(sim2, "lamp")
	check(str(sim2.s["event"]["text"]).contains("霍照野") and not str(sim2.s["event"]["text"]).contains("殷望舒"), "霍照野 hails an iron player in his own words")
	EventBook.rival_meeting(sim2, "tower")
	check(str(sim2.s["event"]["text"]).contains("殷望舒"), "殷望舒 still hails in hers")


func test_leaders() -> void:
	print("rival leaders speak at the review and say goodbye when they go under")
	var sim := Sim.new()
	sim.new_game(24)
	sim.s["story"] = 3
	sim.s["day"] = GameData.DAYS_YEAR - 1
	sim.s["event"] = null
	sim.advance_day()
	var f = sim.s["festival_show"]
	var said := 0
	for row in f["houses"]:
		if row["hid"] != sim.pid():
			check(row.has("say") and str(row["say"]).contains(GameData.HOUSES[row["hid"]]["leader"]), "%s has a line of their own" % GameData.HOUSES[row["hid"]]["leader"])
			said += 1
		else:
			check(not row.has("say"), "the player's row has no line")
	check(said == 2, "both rivals speak")
	check(sim.leader_line("iron", ["iron"], "tower") == GameData.LEADER_LINES["iron"]["award"] and sim.leader_line("iron", [], "iron") == GameData.LEADER_LINES["iron"]["lead"] and sim.leader_line("iron", [], "tower") == GameData.LEADER_LINES["iron"]["behind"], "a prize, the lead or trailing each get their own words")
	sim.s["crown"] = {"hid": "tower", "day": 1}
	check(sim.leader_line("tower", [], "") == GameData.LEADER_LINES["tower"]["crown"] and sim.leader_line("iron", [], "") == GameData.LEADER_LINES["iron"]["crown_other"], "the crown changes what everyone says")
	sim.s["crown"] = null
	# a farewell when a rival goes under
	sim.s["event"] = null
	sim.s["festival_show"] = null
	var r0: int = sim.house()["rep"]
	sim._bankrupt("iron")
	check(sim.house("iron")["bankrupt"] and sim.s["event"] != null and str(sim.s["event"]["id"]) == "farewell:iron" and str(sim.s["event"]["text"]).contains("韦朔"), "韦朔 says goodbye when 铁誓舰团 goes under")
	check(EventBook.resolve(sim, 0)["ok"] and sim.house()["rep"] == r0 + 30, "seeing him off is worth a little reputation")
	check(sim.leader_line("iron", [], "") == GameData.LEADER_LINES["iron"]["bankrupt"], "his empty seat is remembered at the next review")


func test_ties() -> void:
	print("alliances and feuds between the houses (round 26)")
	var sim := Sim.new()
	sim.new_game(26)
	sim.s["story"] = 3
	sim.s["day"] = 1
	var me := sim.pid()
	check(sim.tie("iron") == 0 and sim.tie_state("iron") == "plain" and sim.tie_name("iron") == "平常", "a new game starts with every pair at 0")
	var g0: float = sim.house()["gold"]
	check(sim.tie_gift("iron")["ok"] and sim.tie("iron") == GameData.TIE_GIFT and sim.house()["gold"] == g0 - GameData.TIE_GIFT_COST, "a gift costs %d and warms the pair by %d" % [GameData.TIE_GIFT_COST, GameData.TIE_GIFT])
	check(not sim.tie_gift("iron")["ok"], "no second gift within %d days" % GameData.TIE_GIFT_GAP)
	check(not sim.propose_ally("iron")["ok"], "an alliance needs the relationship at %d first" % GameData.TIE_ASK_MIN)
	var accepted := false
	var refused := false
	for i in 40:
		sim.set_tie(me, "iron", GameData.TIE_ALLY - 1)
		sim.s["tie_ask"] = {}
		var n0: int = sim.s["log"].size()
		check(sim.propose_ally("iron")["ok"], "the proposal itself is a valid move")
		if sim.tie_state("iron") == "ally":
			accepted = true
			check(sim.allies_of(me) == ["iron"] and sim.s["log"].size() > n0 and str(sim.s["log"][-1][1]).contains("结为盟友"), "the alliance makes the news")
			break
		refused = true
		check(sim.tie("iron") == GameData.TIE_ALLY - 1 - 5 and not sim.propose_ally("iron")["ok"], "a refusal costs 5 and %d days" % GameData.TIE_ASK_GAP)
	check(accepted, "a warm house accepts the alliance sooner or later")
	if not refused:
		print("  (every proposal was accepted this time)")
	check(not sim.propose_ally("iron")["ok"], "no proposing to an ally")
	sim._tick_milestones()
	check(sim.milestone_done("first_ally"), "the first alliance is a milestone")
	# feud with the other house
	check(sim.break_off("tower")["ok"] and sim.tie_state("tower") == "feud" and sim.tie("tower") == GameData.TIE_FEUD - 10, "翻脸 drops the pair straight into a feud")
	check(not sim.break_off("tower")["ok"], "no breaking off twice")
	var port := "muxia"
	sim.house("tower")["gold"] = 100000.0
	sim.house("tower")["bp"]["fish"] = true
	var built := false
	for i in sim.s["ports"][port]["plots"].size():
		if Industry.build(sim, port, i, "fish", "tower")["ok"]:
			var full := int(float(GameData.build_cost("fish")) * GameData.BUYOUT_MULT)
			check(Industry.buyout_cost(sim, port, i) == int(float(full) * GameData.FEUD_BUYOUT) and Industry.buyout_cost(sim, port, i, "iron") == full, "a 宿敌's workshop sells for %d%% of the usual price, to the 宿敌 only" % int(roundf(GameData.FEUD_BUYOUT * 100.0)))
			built = true
			break
	check(built, "the rival could build a fishery for the buyout check")
	check(AiPlayer._buyout_targets(sim, "iron") == ["tower"] and AiPlayer._buyout_targets(sim, "tower") == [me, "iron"], "the bot buys from feuds first and never from an ally")
	# the festival: an ally brings a gift and never challenges; a feud always does
	sim.house("iron")["gold"] = 100000.0
	sim.s["day"] = GameData.DAYS_YEAR - 1
	sim.s["event"] = null
	sim.s["encounter"] = null
	sim.advance_day()
	var f: Dictionary = sim.s["festival_show"]
	check(f.get("challenge", "") == "tower" and sim.s["event"] != null and str(sim.s["event"]["id"]) == "rival:tower", "the 宿敌 always challenges at the festival")
	check(f.has("gifts") and f["gifts"].size() == 1 and f["gifts"][0]["hid"] == "iron" and int(f["gifts"][0]["gold"]) >= GameData.ALLY_GIFT_MIN and int(f["gifts"][0]["gold"]) <= GameData.ALLY_GIFT_MAX and sim.s["log"].any(func(l): return str(l[1]).contains("贺礼")), "the ally brings a gift of %d%% of their gold (%d)" % [int(roundf(GameData.ALLY_GIFT * 100.0)), int(f.get("gifts", [{"gold": 0}])[0]["gold"])])
	for row in f["houses"]:
		if row["hid"] == "iron":
			check(row.get("tie", "") == "盟友", "the review names the relationship")
	# duelling a 宿敌 pays more reputation
	var fx: Dictionary = sim.s["event"]["choices"][0]["effects"]
	var base := int(fx.get("race", {}).get("rep", 0)) if fx.has("race") else int(fx.get("debate", {}).get("win", 0))
	var r0: int = sim.house()["rep"]
	var gold0: float = sim.house()["gold"]
	var t0 := sim.tie("tower")
	check(EventBook.resolve(sim, 0)["ok"], "the festival duel resolves")
	var won: bool = sim.house()["rep"] > r0
	check(won == false or sim.house()["rep"] - r0 == int(float(base) * GameData.FEUD_REP_MULT), "a win over a 宿敌 pays ×%.1f reputation (base %d)" % [GameData.FEUD_REP_MULT, base])
	check(sim.tie("tower") == t0 - (GameData.TIE_DUEL if fx.has("debate") else GameData.TIE_RACE), "a duel sours the pair whoever wins")
	check(gold0 != sim.house()["gold"] or fx.has("debate"), "a race moves gold")
	# meetings: an ally shares intel, a 宿敌 can be appeased, a warm house proposes
	sim.s["day"] += 1
	sim.s["event"] = null
	EventBook.rival_meeting(sim, "iron")
	var ci := -1
	for i in sim.s["event"]["choices"].size():
		if sim.s["event"]["choices"][i]["effects"].has("intel_share"):
			ci = i
	check(ci >= 0 and str(sim.s["event"]["text"]).contains("盟友"), "an ally's captain offers to swap market news")
	sim.s["intel"] = {}
	check(EventBook.resolve(sim, ci)["ok"] and sim.s["intel"].size() == sim.open_ports().size(), "the swap fills in every open port")
	sim.s["event"] = null
	EventBook.rival_meeting(sim, "tower")
	var cj := -1
	for i in sim.s["event"]["choices"].size():
		if sim.s["event"]["choices"][i]["effects"].has("tie") and sim.s["event"]["choices"][i]["effects"].has("gold"):
			cj = i
	check(cj >= 0 and str(sim.s["event"]["text"]).contains("脸色") and not sim.s["event"]["choices"].any(func(c): return c["effects"].has("friend")), "a 宿敌 gets no friendly drink, only an apology")
	var t1 := sim.tie("tower")
	check(EventBook.resolve(sim, cj)["ok"] and sim.tie("tower") == t1 + 10, "the apology warms the pair by 10")
	sim.set_tie(me, "tower", GameData.TIE_ASK_MIN)
	sim.s["event"] = null
	EventBook.rival_meeting(sim, "tower")
	var ck := -1
	for i in sim.s["event"]["choices"].size():
		if sim.s["event"]["choices"][i]["effects"].has("ally"):
			ck = i
	check(ck >= 0, "a warm house proposes the alliance itself")
	check(EventBook.resolve(sim, ck)["ok"] and sim.tie_state("tower") == "ally", "accepting seals it")
	# two rivals: an ally pays a share of a lighthouse stage; feuding houses trip each other up
	var sim2 := Sim.new()
	sim2.new_game(26)
	sim2.s["story"] = 3
	sim2.s["day"] = 1
	sim2.set_tie("iron", "tower", 50)
	check(sim2.tie_state("iron", "tower") == "ally" and str(sim2.s["log"][-1][1]).contains("结了盟"), "two rivals can ally, and the news says so")
	sim2.house("tower")["gold"] = 200000.0
	sim2.house("tower")["rep"] = 100000
	sim2.house("iron")["gold"] = 100000.0
	var st0: Dictionary = GameData.LIGHTHOUSE[0]
	for g in st0["mats"]:
		sim2.house("tower")["lh"]["mats"][g] = int(st0["mats"][g])
	check(sim2.start_lighthouse("tower")["ok"], "the rival starts its lighthouse")
	var share := int(float(st0["gold"]) * GameData.ALLY_LH_SHARE) / 100 * 100
	check(sim2.house("iron")["gold"] == 100000.0 - share and sim2.house("tower")["gold"] == 200000.0 - float(st0["gold"]) + share, "the ally pays %d%% of the stage (%d)" % [int(roundf(GameData.ALLY_LH_SHARE * 100.0)), share])
	var end0: int = sim2.house("tower")["lh"]["end"]
	var hit := false
	sim2.house()["gold"] = 1.0e9
	sim2.house("iron")["gold"] = 1.0e6   # the richer of the two does the hitting
	for i in 80:
		sim2.set_tie("iron", "tower", -60)
		sim2._tick_ties()
		if int(sim2.house("tower")["lh"]["end"]) > end0:
			hit = true
			break
	check(hit, "feuding rivals eventually sabotage each other's lighthouse")
	# monthly drift: the two trailing houses draw together, the leader is envied, the player never drifts into a pact
	var sim3 := Sim.new()
	sim3.new_game(26)
	sim3.house()["gold"] = 1.0e9
	sim3._tick_ties()
	check(sim3.tie("iron", "tower") == GameData.TIE_LEADER_DRIFT and sim3.tie("iron") == -GameData.TIE_ENVY and sim3.tie("tower") == -GameData.TIE_ENVY, "when the player leads, the rivals warm to each other and cool toward the player")
	sim3.house()["gold"] = 1000.0
	sim3.house("iron")["gold"] = 1.0e9
	sim3.set_tie(sim3.pid(), "tower", GameData.TIE_DRIFT_CAP)
	sim3._tick_ties()
	check(sim3.tie("tower") == GameData.TIE_DRIFT_CAP and sim3.tie("iron", "tower") == GameData.TIE_LEADER_DRIFT - GameData.TIE_DECAY - GameData.TIE_ENVY, "drift alone never allies the player; old feelings fade by %d a month and the leader is envied" % GameData.TIE_DECAY)
	# save round-trip
	var sim4 := Sim.new()
	check(sim4.from_json(sim.to_json()) and sim4.tie("iron") == sim.tie("iron") and typeof(sim4.s["ties"].values()[0]) == TYPE_INT and sim4.tie_state("tower") == "ally", "relationships survive a save")


func test_allies() -> void:
	print("what an ally is good for: borrowed ships, joint buyouts, bail-outs (round 27)")
	var sim := Sim.new()
	sim.new_game(27)
	sim.s["story"] = 3
	sim.s["day"] = 1
	var me := sim.pid()
	var fl := sim.flagship()
	sim.house()["gold"] = 50000.0
	sim.set_tie(me, "iron", 50)
	var ls: Dictionary = sim._add_ship("iron", "galleon", fl["port"])
	check(sim.loan_candidates("iron", fl["port"]).size() == 1 and sim.loan_candidates("tower", fl["port"]).is_empty(), "an ally's empty ship docked beside the flagship can be borrowed")
	EventBook.rival_meeting(sim, "iron")
	var ci := -1
	for i in sim.s["event"]["choices"].size():
		if sim.s["event"]["choices"][i]["effects"].has("borrow"):
			ci = i
	check(ci >= 0, "the ally's captain offers the ship")
	var rent := sim.loan_rent(ls)
	var ig0: float = sim.house("iron")["gold"]
	check(EventBook.resolve(sim, ci)["ok"] and ls["owner"] == me and sim.in_fleet(ls) and ls["loan"]["hid"] == "iron" and int(ls["loan"]["until"]) == 1 + GameData.LOAN_DAYS and sim.house()["gold"] == 50000.0 - rent and sim.house("iron")["gold"] == ig0 + rent, "borrowing pays %d rent and puts the ship in the fleet for %d days" % [rent, GameData.LOAN_DAYS])
	check(sim.fleet_ships(fl).size() == 2 and sim.fleet_cargo_cap(fl) > sim.cargo_cap(fl) and not sim.sell_ship(int(ls["id"]))["ok"], "it carries cargo with the fleet and cannot be sold")
	check(sim.own_ships().size() == sim.ships_of().size() - 1, "a borrowed ship does not count against the fleet limit")
	var sim_b := Sim.new()
	check(sim_b.from_json(sim.to_json()) and sim_b.ship(int(ls["id"])).has("loan") and typeof(sim_b.ship(int(ls["id"]))["loan"]["until"]) == TYPE_INT, "the loan survives a save")
	var good: String = GameData.traded_goods(fl["port"])[0]
	ls["cargo"] = {good: {"qty": 10, "cost": 1.0}}
	var g1: float = sim.house()["gold"]
	sim.s["day"] = int(ls["loan"]["until"])
	sim._tick_loans()
	check(ls["owner"] == "iron" and not sim.in_fleet(ls) and not ls.has("loan") and ls["cargo"].is_empty() and sim.house()["gold"] > g1 and str(sim.s["log"][-1][1]).contains("到期还给"), "when the time is up it goes home and its cargo is sold")
	check(sim.borrow_ship("iron", int(ls["id"]))["ok"], "it can be borrowed again")
	sim.set_tie(me, "iron", 0)
	sim._tick_loans()
	check(ls["owner"] == "iron", "the alliance ending sends it home early")
	sim.set_tie(me, "iron", 50)
	check(sim.borrow_ship("iron", int(ls["id"]))["ok"], "borrowed a third time")
	sim.house("iron")["bankrupt"] = true
	sim._tick_loans()
	check(ls["owner"] == me and not ls.has("loan"), "a lender going under leaves the ship with you")
	sim.house("iron")["bankrupt"] = false
	ls["owner"] = "iron"
	ls["fleet"] = 0
	check(sim.borrow_ship("iron", int(ls["id"]))["ok"], "borrowed a fourth time")
	var t0 := sim.tie("iron")
	var g2: float = sim.house()["gold"]
	sim._loan_lost(ls)
	check(sim.house()["gold"] == g2 - int(float(GameData.SHIPS["galleon"]["price"]) * GameData.LOAN_LOST) and sim.tie("iron") == t0 - GameData.LOAN_LOST_TIE, "losing a borrowed ship costs half its price and %d relationship" % GameData.LOAN_LOST_TIE)
	sim._remove_ship(ls)
	# a joint buyout: an ally pays 30%
	sim.set_tie(me, "iron", 50)
	sim.house("iron")["gold"] = 100000.0
	sim.house("tower")["gold"] = 100000.0
	sim.house("tower")["bp"]["fish"] = true
	sim.house()["bp"]["fish"] = true
	sim.house()["gold"] = 50000.0
	var plot := -1
	for i in sim.s["ports"]["muxia"]["plots"].size():
		if Industry.build(sim, "muxia", i, "fish", "tower")["ok"]:
			plot = i
			break
	check(plot >= 0, "the third house built a fishery")
	var cost := Industry.buyout_cost(sim, "muxia", plot)
	var r := Industry.buyout(sim, "muxia", plot)
	check(r["ok"] and sim.house()["gold"] == 50000.0 - cost + int(float(cost) * GameData.ALLY_BUYOUT_SHARE) and sim.house("iron")["gold"] == 100000.0 - int(float(cost) * GameData.ALLY_BUYOUT_SHARE) and str(r["msg"]).contains("盟友铁誓舰团出了"), "the ally pays %d%% of a buyout against the third house" % int(roundf(GameData.ALLY_BUYOUT_SHARE * 100.0)))
	sim.set_tie("iron", "tower", 50)
	check(sim._allies_pay(me, 1000, "tower").is_empty(), "nobody funds a move against their own ally")
	# bail-outs
	var sim2 := Sim.new()
	sim2.new_game(27)
	sim2.s["story"] = 3
	sim2.s["day"] = 1
	sim2.set_tie("iron", "tower", 50)
	sim2.house("tower")["gold"] = 200000.0
	sim2.house("iron")["gold"] = -5000.0
	sim2.s["event"] = null
	sim2._tick_crisis()
	check(sim2.house("iron")["gold"] == 2000.0 and sim2.house("tower")["gold"] == 193000.0 and sim2.tie("iron", "tower") == 50 + GameData.BAIL_TIE and str(sim2.s["log"][-1][1]).contains("还了"), "an AI ally pays an ally's debt and the pair warms")
	sim2.set_tie(sim2.pid(), "tower", 50)
	sim2.house("tower")["gold"] = -3000.0
	sim2.house("tower")["crisis"] = 0
	sim2.house()["gold"] = 100000.0
	sim2.s["event"] = null
	sim2._tick_crisis()
	check(sim2.s["event"] != null and str(sim2.s["event"]["id"]) == "bail:tower", "an allied house without a rich AI ally asks the player")
	check(EventBook.resolve(sim2, 0)["ok"] and sim2.house()["gold"] == 95000.0 and sim2.house("tower")["gold"] == 2000.0 and sim2.tie("tower") == 50 + GameData.BAIL_TIE, "helping costs the need and warms the pair by %d" % GameData.BAIL_TIE)
	sim2.set_tie(sim2.pid(), "iron", 50)
	sim2.house("iron")["gold"] = -1000.0
	sim2.house("iron")["crisis"] = 0
	sim2.house("tower")["gold"] = 1000.0
	sim2.s["event"] = null
	sim2._tick_crisis()
	check(sim2.s["event"] != null and str(sim2.s["event"]["id"]) == "bail:iron", "the poorer AI ally cannot help, so the player is asked")
	check(EventBook.resolve(sim2, 1)["ok"] and sim2.tie("iron") == 50 - GameData.BAIL_REFUSE_TIE and sim2.tie_state("iron") == "plain", "refusing costs %d and can end the alliance" % GameData.BAIL_REFUSE_TIE)
	sim2.set_tie(sim2.pid(), "iron", 50)
	sim2.house("iron")["gold"] = -50000.0
	sim2.house("iron")["crisis"] = 0
	sim2.s["event"] = null
	sim2._tick_crisis()
	check(sim2.s["event"] == null, "no request when the need is beyond %d%% of the player's gold" % int(roundf(GameData.BAIL_MAX * 100.0)))
