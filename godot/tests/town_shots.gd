extends Node
## Visual check of the towns (finish plan, phase B): walks into several ports and saves screenshots.
## YUNHAI_TOWNSHOTS=/abs/out/dir xvfb-run godot --path godot --rendering-driver opengl3

var main: Control
var out := ""


func run(m: Control) -> void:
	main = m
	out = OS.get_environment("YUNHAI_TOWNSHOTS")
	DirAccess.make_dir_recursive_absolute(out)
	m.get_tree().root.call_deferred("add_child", self)
	await tree_entered
	await _wait(0.4)
	main._start(false, "lamp")
	await _wait(0.3)
	main._close_modal()
	var sim: Sim = main.sim
	sim.s["story"] = 5
	var ports := OS.get_environment("PORTS").split(",") if OS.get_environment("PORTS") != "" else PackedStringArray(["qianqi", "muxia", "fengyue", "xiajing"])
	var k := 0
	for pid in ports:
		var fl: Dictionary = sim.flagship()
		fl["port"] = pid
		fl["from"] = pid
		fl["to"] = ""
		fl["arrive"] = int(sim.s["day"])
		sim.s["day"] = 10 + k * 97
		main._enter_town()
		await _wait(0.6)
		await _shot("town_%s_a" % pid)
		# walk up the avenue into the plaza
		main.town._path = main.town._find_path(main.town.hero_pos, main.town._plaza + Vector2(40, 120))
		await _wait(2.6)
		await _shot("town_%s_b" % pid)
		main._leave_town()
		await _wait(0.4)
		k += 1
	get_tree().quit()


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
