extends SceneTree
## Replays a bot-player seed and prints one house's monthly finances.
## SEED=55 HID=iron YEARS=3 godot --headless -s res://tests/debug_seed.gd
func _init() -> void:
	var sim := Sim.new()
	sim.new_game(int(OS.get_environment("SEED")))
	var hid := OS.get_environment("HID")
	var years := int(OS.get_environment("YEARS")) if OS.get_environment("YEARS") != "" else 3
	var enc := 0
	for d in GameData.DAYS_YEAR * years:
		if sim.s["event"] != null:
			EventBook.resolve(sim, 0)
		if sim.s["encounter"] != null:
			enc += 1
			var r := sim.auto_encounter()
			print("   day %d encounter -> %s" % [sim.s["day"], r.get("res", r.get("msg", ""))])
		for sh in sim.ships_of(sim.pid()):
			if sim.docked(sh):
				AiPlayer.ship_turn(sim, sh)
		if sim.s["day"] % GameData.DAYS_MONTH == 1:
			AiPlayer.monthly(sim, sim.pid())
		sim.advance_day()
		var h := sim.house(hid)
		if d % 30 == 29:
			print("m%d gold %d debt %d net %+d upkeep %d lh %d/%s ships %d bld %d crisis %d" % [d / 30, int(h["gold"]), int(h["debt"]), int(h["last_net"]), int(h.get("last_upkeep", 0)), h["lh"]["stage"], str(h["lh"]["building"]), sim.ships_of(hid).size(), Industry.all_buildings(sim, hid).size(), int(h["crisis"])])
		if sim.s["over"] != null or h["bankrupt"]:
			print("OVER/bankrupt at day ", sim.s["day"])
			break
	quit()
