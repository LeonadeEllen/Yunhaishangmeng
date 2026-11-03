extends SceneTree
func _init() -> void:
	var sim := Sim.new()
	sim.new_game(11)
	var t_adv := 0
	var t_bot := 0
	var t_month := 0
	for d in 360:
		if sim.s["event"] != null:
			EventBook.resolve(sim, 0)
		var t0 := Time.get_ticks_msec()
		for sh in sim.ships_of(sim.pid()):
			if sim.docked(sh):
				AiPlayer.ship_turn(sim, sh)
		var t1 := Time.get_ticks_msec()
		if sim.s["day"] % GameData.DAYS_MONTH == 1:
			AiPlayer.monthly(sim, sim.pid())
		var t2 := Time.get_ticks_msec()
		sim.advance_day()
		var t3 := Time.get_ticks_msec()
		t_bot += t1 - t0
		t_month += t2 - t1
		t_adv += t3 - t2
	print("bot ship_turn %d ms, monthly %d ms, advance_day %d ms" % [t_bot, t_month, t_adv])
	# inside advance_day: markets vs rivals
	var t0 := Time.get_ticks_msec()
	for i in 100:
		sim._tick_markets()
	print("100x _tick_markets %d ms" % (Time.get_ticks_msec() - t0))
	t0 = Time.get_ticks_msec()
	for i in 20:
		for hid in GameData.HOUSE_IDS:
			if hid == sim.pid():
				continue
			for sh in sim.ships_of(hid):
				AiPlayer._best_plan(sim, sh, AiPlayer._needs(sim, hid))
	print("20x rival _best_plan for all ships %d ms" % (Time.get_ticks_msec() - t0))
	quit()
