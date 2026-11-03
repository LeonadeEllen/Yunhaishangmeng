extends Node
## Visual smoke test: drives the real UI and saves screenshots.
## YUNHAI_SHOTS=/abs/out/dir xvfb-run godot --path godot --rendering-driver opengl3

var main: Control
var out := ""


func run(m: Control) -> void:
	main = m
	out = OS.get_environment("YUNHAI_SHOTS")
	DirAccess.make_dir_recursive_absolute(out)
	m.get_tree().root.call_deferred("add_child", self)
	await tree_entered
	await _wait(0.6)
	await _shot("01_title")
	main._pick_house()
	await _wait(0.4)
	await _shot("01b_pick_house")
	main._close_modal()
	main._start(false, "lamp")
	await _wait(0.5)
	await _shot("02_intro")
	main._close_modal()
	await _wait(0.3)
	await _shot("03_port_trade")
	main._trade(true, "silk", 9999)
	await _wait(0.3)
	main._on_port_clicked("muxia")
	await _wait(0.4)
	await _shot("04_after_buy_select_dest")
	main._sail("muxia")
	main._set_speed(3)
	await _wait(1.0)
	await _shot("05_sailing")
	# run until the flagship arrives (or an event pops)
	for i in 120:
		await _wait(0.1)
		if main._modal_open:
			await _shot("06_event")
			var ev = main.sim.s["event"]
			if ev != null:
				main._choose_event(0)
			else:
				main._close_modal()
		if main.sim.docked(main.sim.flagship()) and main.speed_idx == 0:
			break
	await _shot("07_arrived_town")
	main.town._enter("trade")
	await _wait(0.3)
	await _shot("07b_inside_trade")
	main.sim.add_exp(400)
	main._refresh_top()
	main._show_hero()
	await _wait(0.3)
	await _shot("07c_hero")
	main._close_modal()
	main._trade(false, "silk", 9999)
	await _wait(0.4)
	await _shot("08_sold")
	main.sim.house()["gold"] += 30000.0
	main._open_port(main.sim.flagship()["port"], 1)
	await _wait(0.3)
	await _shot("09_shipyard")
	main._act(main.sim.buy_ship("freighter", main.sim.flagship()["port"]))
	var ships: Array = main.sim.ships_of()
	main._show_route_dialog(ships[ships.size() - 1]["id"])
	await _wait(0.3)
	await _shot("10_route")
	main._close_modal()
	main._open_port("qianqi", 6)
	await _wait(0.3)
	await _shot("11_lighthouse")
	main._open_port("qianqi", 3)
	await _wait(0.3)
	await _shot("12_hall")
	main._open_port("qianqi", 4)
	await _wait(0.3)
	await _shot("12b_guild")
	main._open_port("qianqi", 5)
	await _wait(0.3)
	await _shot("13_tavern")
	main._show_ledger()
	await _wait(0.3)
	await _shot("14_ledger")
	main._close_modal()
	# hover card
	main._on_port_hovered("chishi")
	await _wait(0.3)
	await _shot("14b_hover")
	main._on_port_hovered("")
	# mid game: auto route + 150 fast days
	var sh2: Dictionary = main.sim.ships_of()[main.sim.ships_of().size() - 1]
	main.sim.set_route(sh2["id"], {"stops": [{"port": "qianqi", "buy": ["silk"]}, {"port": "chishi", "buy": ["stone"]}, {"port": "muxia", "buy": []}]})
	for i in 150:
		if main.sim.s["event"] != null:
			EventBook.resolve(main.sim, 0)
		if main.sim.s["encounter"] != null:
			main.sim.auto_encounter()
		main.sim.advance_day()
	main.sim.s["frac"] = 0.3
	main._refresh_all()
	main._open_port(main.sim.flagship()["port"], 0)
	await _wait(0.5)
	await _shot("14c_midgame")
	while main.sim.open_contracts().size() < 2:
		main.sim._post_contract()
	var c0: Dictionary = main.sim.open_contracts()[0]
	c0["chasers"].append("iron" if main.sim.pid() != "iron" else "tower")
	main._open_port(main.sim.flagship()["port"], 5)
	await _wait(0.4)
	await _shot("14d_contracts")
	main.sim.house()["gold"] += 90000
	main.sim.house()["rep"] = 700
	main.sim.house("tower")["bp"]["fish"] = true
	Industry.build(main.sim, "muxia", 0, "fish", "tower")
	main.sim.house()["bp"]["wheat"] = true
	main.sim.house()["bp"]["smoked"] = true
	main.sim.s["ports"]["muxia"]["friend"][main.sim.pid()] = 400
	Industry.build(main.sim, "muxia", 1, "wheat")
	Industry.build(main.sim, "muxia", 3, "smoked")
	main._open_port("muxia", 2)
	await _wait(0.4)
	await _shot("14e_post")
	main._build_plot = 4
	main._refresh_side()
	await _wait(0.3)
	await _shot("14f_build_menu")
	main._build_plot = -1
	main._trade_mode = 2
	main._open_port("muxia", 0)
	await _wait(0.3)
	await _shot("14g_trade_wh_mode")
	main._trade_mode = 0
	# fleet + refit
	main.sim.house()["gold"] += 60000
	var fp: String = main.sim.flagship()["port"]
	var r3: Dictionary = main.sim.buy_ship("galleon", fp)
	main.sim.join_fleet(int(r3["ship"]))
	main._refresh_fleet()
	main._open_port(fp, 1)
	await _wait(0.4)
	await _shot("14h_yard_refit")
	main._show_route_dialog(sh2["id"])
	await _wait(0.4)
	await _shot("14i_route_dialog")
	main._close_modal()
	# encounter + battle
	main.sim.house()["gold"] += 20000
	main.sim.add_exp(3000)
	main.sim.s["hero"]["abil"]["fight"] = 5
	main.sim.start_encounter("pirates")
	main._show_encounter()
	await _wait(0.4)
	await _shot("16_encounter")
	main._close_modal()
	main.sim.encounter_fight()
	main._open_battle()
	for i in 60:
		await _wait(0.2)
		var cu: Dictionary = main.battle_view.battle.current()
		if not cu.is_empty() and int(cu["side"]) == 0 and main.battle_view._anim.is_empty() and main.battle_view._events.is_empty():
			break
	await _wait(0.3)
	await _shot("16b_battle")
	main.battle_view.auto = true
	await _wait(5.0)
	main.battle_view.auto = false
	main.battle_view._refresh_panel()
	await _wait(0.3)
	await _shot("16c_battle_mid")
	main.battle_view.auto = true
	for i in 300:
		await _wait(0.2)
		if not main.battle_view.visible:
			break
	await _wait(0.4)
	await _shot("16d_battle_result")
	main._close_modal()
	main.sim._post_bounty()
	main._open_port(main.sim.flagship()["port"], 5)
	await _wait(0.3)
	await _shot("16e_bounty")
	# companions
	main.sim.house()["gold"] += 20000
	main.sim.s["story"] = 1
	main.sim.house()["rep"] = 700
	main._open_port("muxia", 5)
	await _wait(0.3)
	await _shot("17_tavern_recruit")
	main.sim.recruit("xiaoman", "muxia", "tavern")
	main.sim.recruit("qian", "qianqi", "tavern")
	main.sim.recruit("luqing", "xiajing", "tavern")
	main.sim.recruit("aman", "muxia", "tavern")
	main.sim.set_post("qian", "acct")
	main.sim.set_post("luqing", "nav")
	main.sim.set_post("aman", "gunner")
	main.sim.crew()["luqing"]["aff"] = 48
	main.sim.crew()["luqing"]["chapter"] = 1
	main._refresh_all()
	main._show_crew()
	await _wait(0.4)
	await _shot("17b_crew")
	main._close_modal()
	main.sim.crew()["xiaoman"]["aff"] = 30
	main.sim._tick_crew()
	main._show_event()
	await _wait(0.4)
	await _shot("17c_chapter")
	main._choose_event(0)
	main._close_modal()
	# round 10: the eastern fog
	main.sim.house()["rep"] = 700
	main.sim.house()["gold"] = 90000.0
	main._open_port("muxia", 4)
	await _wait(0.3)
	await _shot("18_guild_expedition")
	main.sim.sponsor_expedition()
	main.sim.s["explore"]["found"]["fengxi"] = true
	main.sim.s["explore"]["found"]["qinglu"] = true
	main.sim.s["explore"]["found"]["wreck_a"] = true
	main.map.set_region(2)
	main.map._vx = main.map.VIEW_EAST.position.x
	main._refresh_all()
	main._open_spot("jinduo")
	await _wait(0.5)
	await _shot("18b_east_fog")
	main.sim.s["day"] = 420
	main.sim.s["explore"]["found"].erase("jinduo")
	var fl2: Dictionary = main.sim.flagship()
	fl2["port"] = "jinduo"
	main.sim._discover(fl2, "jinduo")
	main._show_discovery()
	await _wait(0.4)
	await _shot("18c_discovery")
	main._close_modal()
	main.sim.s["explore"]["found"]["ruin_bell"] = true
	main.sim.s["discovery"] = null
	main._open_spot("ruin_bell")
	main._refresh_all()
	await _wait(0.4)
	await _shot("18d_east_charted")
	# round 11: an eastern event
	EventBook._open(main.sim, EventBook.EAST[0])
	main._show_event()
	await _wait(0.4)
	await _shot("19_east_event")
	main._choose_event(1)
	main._close_modal()
	main._show_rival("tower")
	await _wait(0.4)
	await _shot("20_rival_intel")
	main._close_modal()
	# round 13: a rival hails you on the quay; companions in town; the headquarters
	main.sim.house()["gold"] = 90000.0
	EventBook.rival_meeting(main.sim, "iron")
	main._show_event()
	await _wait(0.4)
	await _shot("21_rival_meeting")
	main._choose_event(4)
	main._close_modal()
	main.sim.house()["rep"] = 1600
	main.sim.s["stats"]["wins"] = 1
	main.sim.recruit("aman", "qianqi", "tavern")
	main.sim.recruit("qian", "qianqi", "tavern")
	main.sim.recruit("xiaoman", "muxia", "tavern")
	var fl3: Dictionary = main.sim.flagship()
	fl3["port"] = "qianqi"
	fl3["to"] = ""
	main._open_port("qianqi", 2)
	main._enter_town()
	await _wait(0.6)
	await _shot("22_town_companions")
	main.town._enter("post")
	await _wait(0.4)
	await _shot("23_hq")
	main._leave_town()
	main.sim.crew()["aman"]["aff"] = 50
	main.sim.crew()["qian"]["aff"] = 50
	EventBook.open_pair(main.sim, 0 if main.sim.crew().has("shen") else 1)
	main._show_event()
	await _wait(0.4)
	await _shot("24_pair_scene")
	main._choose_event(0)
	main._close_modal()
	# round 14: city works and the benefactor's statue
	main.sim.house()["gold"] = 120000.0
	main.sim.fund_work("qianqi", "dock")
	main.sim.fund_work("qianqi", "market")
	main.sim.house("tower")["gold"] = 100000.0
	main.sim.fund_work("qianqi", "school", "tower")
	main._open_port("qianqi", 3)
	await _wait(0.4)
	await _shot("25_city_works")
	main._enter_town()
	await _wait(0.6)
	await _shot("26_town_statue")
	main._leave_town()
	# round 15: the lantern festival and its year review
	main.sim.s["day"] = GameData.DAYS_YEAR - 1
	main.sim.s["event"] = null
	main.sim.advance_day()
	main._show_festival()
	await _wait(0.4)
	await _shot("27_festival")
	main._close_modal()
	main._open_port("qianqi", 0)
	main._enter_town()
	await _wait(0.6)
	await _shot("28_town_lanterns")
	main._leave_town()
	# round 17: a companion's errand and the crew panel
	main._close_modal()
	main.sim.s["event"] = null
	main.sim.s["encounter"] = null
	main.sim.crew()["aman"]["aff"] = Characters.QUEST_AFF
	main.sim.crew()["aman"]["chapter"] = 2
	EventBook.open_quest(main.sim, "aman")
	main._show_event()
	await _wait(0.4)
	await _shot("29_quest_offer")
	main._choose_event(0)
	main._close_modal()
	var fl4: Dictionary = main.sim.flagship()
	fl4["port"] = "chishi"
	fl4["to"] = ""
	main.sim._stow(fl4, "brass", 20, 100.0)
	main._open_port("chishi", 5)
	main._show_crew()
	await _wait(0.4)
	await _shot("30_crew_quest")
	main._close_modal()
	main.sim.s["crown"] = {"hid": main.sim.pid(), "day": main.sim.s["day"]}
	main._crown_celebration()
	await _wait(0.4)
	await _shot("15_crown")
	get_tree().quit()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	print("shot ", name)
