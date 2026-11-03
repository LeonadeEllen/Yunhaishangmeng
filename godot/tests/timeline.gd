extends SceneTree
## Pacing probe (round 30): the greedy bot plays 12 years past the crown and every line of news
## about rivals, ties, grand works and milestones is printed with its day, plus a yearly summary.
## godot --headless --path godot -s res://tests/timeline.gd   (SEED=77 PLAYER=iron)

func _init() -> void:
	var sd := int(OS.get_environment("SEED")) if OS.get_environment("SEED") != "" else 66
	var sim := Sim.new()
	sim.new_game(sd, OS.get_environment("PLAYER") if OS.get_environment("PLAYER") != "" else "lamp")
	var keys := ["结盟", "盟友", "宿敌", "盟约", "翻脸", "宿怨", "贺礼", "求援", "替盟友", "盟贡", "落成", "开工", "里程碑", "挑战", "收购", "赛了一程", "灯冠", "盟主", "破产", "买通", "升为", "拦在"]
	sim.message.connect(func(t: String, k: String):
		for kw in keys:
			if kw in t:
				print("  d%4d y%.1f [%s] %s" % [int(sim.s["day"]), float(sim.s["day"]) / 360.0, k, t.substr(0, 110)])
				return)
	var guard := 0
	while sim.s["over"] == null and sim.s["day"] < 360 * 12 and guard < 360 * 13:
		guard += 1
		if sim.s["event"] != null:
			var id := str(sim.s["event"]["id"])
			var pick := 0
			if id.begins_with("rival:"):
				# the bot accepts an alliance when offered, never gambles
				pick = sim.s["event"]["choices"].size() - 1
				for i in sim.s["event"]["choices"].size():
					if sim.s["event"]["choices"][i]["effects"].has("ally"):
						pick = i
			print("  d%4d y%.1f [event] %s -> %s" % [int(sim.s["day"]), float(sim.s["day"]) / 360.0, sim.s["event"]["title"], sim.s["event"]["choices"][pick]["label"].substr(0, 40)])
			EventBook.resolve(sim, pick)
		if sim.s["encounter"] != null:
			sim.auto_encounter()
		if sim.s["discovery"] != null:
			sim.s["discovery"] = null
		if sim.s.get("grand_show") != null:
			sim.s["grand_show"] = null
		for sh in sim.ships_of(sim.pid()):
			if sim.docked(sh):
				AiPlayer.ship_turn(sim, sh)
		if sim.s["day"] % GameData.DAYS_MONTH == 1:
			AiPlayer.monthly(sim, sim.pid())
		sim.advance_day()
		if sim.s["day"] % 360 == 0:
			var row := []
			for hid in GameData.HOUSE_IDS:
				row.append("%s %dk L%d lh%d%s" % [hid, int(sim.net_worth(hid) / 1000.0), sim.rep_level(hid), sim.house(hid)["lh"]["stage"], " ✝" if sim.house(hid)["bankrupt"] else ""])
			print("== year %d  %s  ties %s  grand %s" % [sim.s["day"] / 360, " | ".join(row), str(sim.s["ties"]), str(sim.s["grand"].keys())])
	quit()
