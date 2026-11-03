extends SceneTree
func _init() -> void:
	var ok := true
	for path in ["res://scripts/core/data.gd", "res://scripts/core/sim.gd", "res://scripts/core/industry.gd", "res://scripts/core/ai_player.gd", "res://scripts/core/event_book.gd", "res://scripts/core/battle.gd", "res://scripts/core/characters.gd", "res://scripts/ui/battle_view.gd", "res://scripts/ui/map_view.gd", "res://scripts/ui/town_view.gd", "res://scripts/ui/main.gd", "res://scripts/ui/ui_kit.gd", "res://tests/shot_runner.gd"]:
		var sc = load(path)
		if sc == null or not sc.can_instantiate():
			print("BAD ", path)
			ok = false
	print("compile ", "ok" if ok else "FAILED")
	quit(0 if ok else 1)
