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
