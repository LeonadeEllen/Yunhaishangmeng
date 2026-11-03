extends SceneTree
func _init() -> void:
	var sim := Sim.new()
	sim.new_game(22)
	var hid := "iron"
	var trades := []
	for d in 720:
		if sim.s["event"] != null:
			EventBook.resolve(sim, 0)
		for sh in sim.ships_of(hid):
			if sim.docked(sh):
				var g0: float = sim.house(hid)["gold"]
				AiPlayer.ship_turn(sim, sh)
				trades.append("%s%+d" % [sh["port"] if sim.docked(sh) else sh["to"], int(sim.house(hid)["gold"] - g0)])
		if sim.s["day"] % 30 == 1:
			AiPlayer.monthly(sim, hid)
		sim.advance_day()
		var h := sim.house(hid)
		if d % 30 == 29:
			print("m%d gold %d debt %d net %+d upkeep %d ships %d | %s" % [d / 30, int(h["gold"]), int(h["debt"]), int(h["last_net"]), int(h.get("last_upkeep", 0)), sim.ships_of(hid).size(), " ".join(trades)])
			trades.clear()
		if sim.s["over"] != null:
			print("OVER ", sim.s["over"]["kind"])
			break
	quit()
