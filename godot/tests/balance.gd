extends SceneTree
## Quick balance probe: N seeds of the greedy bot, prints when each house finishes each stage.
## godot --headless --path godot -s res://tests/balance.gd

func _init() -> void:
	var res := {}
	for sd in [11, 22, 33, 44, 55, 66]:
		var sim := Sim.new()
		sim.new_game(sd)
		var stage_day := {}
		var won := {}
		var buys := 0
		sim.message.connect(func(t: String, k: String):
			for hid in GameData.HOUSE_IDS:
				if t.begins_with(GameData.HOUSES[hid]["name"] + " 完成了"):
					won[hid] = int(won.get(hid, 0)) + 1
			if "收购" in t:
				buys += 1)
		while sim.s["over"] == null and sim.s["crown"] == null and sim.s["day"] < 360 * 12:
			if sim.s["event"] != null:
				EventBook.resolve(sim, 0)
			for sh in sim.ships_of(sim.pid()):
				if sim.docked(sh):
					AiPlayer.ship_turn(sim, sh)
			if sim.s["day"] % GameData.DAYS_MONTH == 1:
				AiPlayer.monthly(sim, sim.pid())
			sim.advance_day()
			for hid in GameData.HOUSE_IDS:
				var k: String = "%s%d" % [hid, sim.house(hid)["lh"]["stage"]]
				if not stage_day.has(k):
					stage_day[k] = snappedf(float(sim.s["day"]) / 360.0, 0.1)
		var o: Dictionary = sim.s["over"] if sim.s["over"] != null else {"kind": ("crown:" + sim.s["crown"]["hid"]) if sim.s["crown"] != null else "none", "day": sim.s["day"]}
		var row := []
		for hid in GameData.HOUSE_IDS:
			var stg := []
			for i in [1, 2, 3]:
				stg.append(str(stage_day.get("%s%d" % [hid, i], "-")))
			row.append("%s[%s] %dk c%d L%d b%d" % [hid, ",".join(stg), int(sim.house(hid)["gold"] / 1000.0), int(won.get(hid, 0)), sim.rep_level(hid), Industry.all_buildings(sim, hid).size()])
		print("seed %d  %-12s y%.1f  %s" % [sd, o["kind"], float(o["day"]) / 360.0, "  ".join(row) + "  buyouts %d open %d" % [buys, sim.s["contracts"].size()]])
	quit()
