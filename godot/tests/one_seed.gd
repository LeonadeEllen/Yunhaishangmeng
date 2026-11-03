extends SceneTree
func _init() -> void:
	var sd := int(OS.get_environment("SEED"))
	var sim := Sim.new()
	sim.new_game(sd)
	var guard := 0
	while sim.s["over"] == null and sim.s["crown"] == null and guard < 360 * 12:
		if sim.s["event"] != null:
			EventBook.resolve(sim, 0)
		for sh in sim.ships_of(sim.pid()):
			if sim.docked(sh):
				AiPlayer.ship_turn(sim, sh)
		if sim.s["day"] % 30 == 1:
			AiPlayer.monthly(sim, sim.pid())
		sim.advance_day()
		guard += 1
		if sim.s["day"] % 360 == 0:
			var row := []
			for hid in GameData.HOUSE_IDS:
				var h := sim.house(hid)
				row.append("%s %8d g lh%d m%s sh%d b%d bp%d" % [hid, int(h["gold"]), h["lh"]["stage"], str(h["lh"]["mats"]).replace(" ", ""), sim.ships_of(hid).size(), Industry.all_buildings(sim, hid).size(), h["bp"].size()])
			print("y%-2d " % (sim.s["day"] / 360), " | ".join(row))
	print("seed %d: crown %s over %s" % [sd, str(sim.s["crown"]), str(sim.s["over"])])
	quit()
