extends SceneTree
## Renders every PortraitArt bust into assets/art/portraits/<id>[_mood].webp (finish plan, phase C).
## xvfb-run -a godot --path godot --rendering-driver opengl3 -s res://tools/render_portraits.gd
## ONLY=<id,id> renders a subset; OUT=<dir> writes somewhere else (previews).

var vp: SubViewport
var canvas: Control
var cur_id := ""
var cur_mood := ""


func _init() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(512, 512)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	canvas = Control.new()
	canvas.size = Vector2(512, 512)
	canvas.draw.connect(func(): PortraitArt.draw(canvas, cur_id, cur_mood))
	vp.add_child(canvas)
	var out := OS.get_environment("OUT")
	if out == "":
		out = ProjectSettings.globalize_path("res://assets/art/portraits")
	DirAccess.make_dir_recursive_absolute(out)
	var only := OS.get_environment("ONLY")
	var ids: Array = PortraitArt.IDS if only == "" else Array(only.split(","))
	for id in ids:
		for mood in PortraitArt.MOODS:
			cur_id = id
			cur_mood = mood
			canvas.queue_redraw()
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var img := vp.get_texture().get_image()
			var name: String = id + ("" if mood == "" else "_" + mood)
			img.resize(384, 384, Image.INTERPOLATE_LANCZOS)
			img.save_webp(out.path_join(name + ".webp"), true, 0.88)
	print("portraits rendered: %d" % (ids.size() * PortraitArt.MOODS.size()))
	quit()
