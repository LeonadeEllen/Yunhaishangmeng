extends SceneTree
## Replays a bot seed and prints, each year, where every house stands on its lighthouse:
## gold, stage, materials in hand vs needed, blueprints and workshops.
## SEED=66 YEARS=8 godot --headless -s res://tests/debug_lh.gd
func _init() -> void:
	var sim := Sim.new()
	sim.new_game(int(OS.get_environment("SEED")))
	var years := int(OS.get_environment("YEARS")) if OS.get_environment("YEARS") != "" else 8
	for d in GameData.DAYS_YEAR * years:
		if sim.s["event"] != null:
			EventBook.resolve(sim, 0)
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
		if sim.s["day"] % GameData.DAYS_YEAR == 0 or sim.s["crown"] != null:
			print("== year %d" % (sim.s["day"] / GameData.DAYS_YEAR))
			for hid in GameData.HOUSE_IDS:
				var h := sim.house(hid)
				var lh: Dictionary = h["lh"]
				var mats := []
				if lh["stage"] < GameData.LIGHTHOUSE.size():
					for g in GameData.LIGHTHOUSE[lh["stage"]]["mats"]:
						mats.append("%s %d/%d" % [g, int(lh["mats"].get(g, 0)), int(GameData.LIGHTHOUSE[lh["stage"]]["mats"][g])])
				var ws := []
				for b in Industry.all_buildings(sim, hid):
					ws.append("%s:%s%d" % [b["port"], b["plot"]["b"], int(b["plot"]["lvl"])])
				var cargo := {}
				for sh in sim.ships_of(hid):
					for g in sh["cargo"]:
						cargo[g] = int(cargo.get(g, 0)) + int(sh["cargo"][g]["qty"])
				print("  %-5s gold %8d rep L%d lh %d%s [%s] bp %s ws %s cargo %s" % [hid, int(h["gold"]), sim.rep_level(hid), lh["stage"], "+" if lh["building"] else "", ", ".join(mats), str(h["bp"].keys()), str(ws), str(cargo)])
			if sim.s["crown"] != null:
				print("CROWN ", sim.s["crown"])
				break
	quit()
