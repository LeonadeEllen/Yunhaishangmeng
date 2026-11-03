extends SceneTree
func _init() -> void:
	var sim := Sim.new()
	sim.new_game(22)
	var hid := "iron"
	for d in 400:
		if sim.s["event"] != null:
			EventBook.resolve(sim, 0)
		for sh in sim.ships_of(sim.pid()):
			if sim.docked(sh):
				AiPlayer.ship_turn(sim, sh)
		if sim.s["day"] % 30 == 1:
			AiPlayer.monthly(sim, sim.pid())
		var g0: float = sim.house(hid)["gold"]
		sim.advance_day()
		var h := sim.house(hid)
		if absf(h["gold"] - g0) > 300 or d % 30 == 29:
			var sh := sim.ships_of(hid)
			print("d%d gold %d -> %d (%+d) ships %d bp %s %s" % [d, int(g0), int(h["gold"]), int(h["gold"] - g0), sh.size(), str(h["bp"].keys()), str(sh[0]["cargo"]).left(60) if sh.size() > 0 else ""])
		if sh_count_zero(sim, hid):
			break
	quit()
func sh_count_zero(sim: Sim, hid: String) -> bool:
	return sim.ships_of(hid).size() == 0
