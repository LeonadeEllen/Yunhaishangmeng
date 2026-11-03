extends Control
## The cloud-sea map: islands, routes, drifting clouds and moving airships.
## Logical map space is 1600 x 1000 (GameData port positions); it is fitted into this control.

signal port_clicked(port_id: String)
signal port_hovered(port_id: String)

const MAP_SIZE := Vector2(1600, 1000)
const ISLAND_W := 128.0

var sim: Sim
var selected_port := ""
var hover_port := ""
var highlight_port := ""      # tutorial hint target
var _clouds := []
var _t := 0.0
var _island_tex := {}
var _ship_tex := {}
var _paper: Texture2D
var region := 1               # 1 = the western charts, 2 = the eastern fog
var _vx := 200.0              # current view x (animates between the two regions)
var _fog := []                # paper fog over the eastern sea


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	for i in 46:
		_clouds.append({"p": Vector2(r.randf_range(-100, 1700), r.randf_range(-60, 1060)),
			"r": r.randf_range(40, 140), "v": r.randf_range(3, 10), "a": r.randf_range(0.18, 0.45)})
	_paper = UiKit.scene_art("paper_sea")
	var fr := RandomNumberGenerator.new()
	fr.seed = 777
	for gx in range(1460, 3100, 110):
		for gy in range(-80, 1140, 100):
			_fog.append({"p": Vector2(gx + fr.randf_range(-70, 70), gy + fr.randf_range(-60, 60)),
				"r": fr.randf_range(110, 210), "a": fr.randf_range(0.8, 0.98), "ph": fr.randf_range(0, TAU)})
	for pid in GameData.PORT_IDS:
		_island_tex[pid] = UiKit.sprite("map_islands", GameData.PORTS[pid]["island"])
	for t in GameData.SHIPS:
		_ship_tex[t] = UiKit.sprite("ships", GameData.SHIPS[t]["sprite"])


const VIEW_WEST := Rect2(200, -40, 1320, 1180)   # western ports bounding box + margins, in map space
const VIEW_EAST := Rect2(1560, -40, 1400, 1180)  # the strait and the eastern sea
const SPOT_R := 34.0                             # click radius of a fog point, in map pixels


func _view() -> Rect2:
	return Rect2(_vx, -40, VIEW_WEST.size.x, VIEW_WEST.size.y)


func set_region(r: int) -> void:
	region = clampi(r, 1, 2)


func _scale() -> float:
	var v := _view()
	return minf(size.x / v.size.x, size.y / v.size.y)


func _offset() -> Vector2:
	var v := _view()
	return (size - v.size * _scale()) * 0.5 - v.position * _scale()


func to_screen(p: Vector2) -> Vector2:
	return _offset() + p * _scale()


func to_map(p: Vector2) -> Vector2:
	return (p - _offset()) / _scale()


func _process(delta: float) -> void:
	_t += delta
	var target := VIEW_WEST.position.x if region == 1 else VIEW_EAST.position.x
	if absf(_vx - target) > 0.5:
		_vx = lerpf(_vx, target, minf(1.0, delta * 4.0))
	else:
		_vx = target
	for c in _clouds:
		c["p"].x += c["v"] * delta
		if c["p"].x > 1760:
			c["p"].x = -160
	queue_redraw()


func _port_at(screen_pos: Vector2) -> String:
	var mp := to_map(screen_pos)
	if sim == null:
		return ""
	for pid in sim.open_ports():
		if mp.distance_to(GameData.PORTS[pid]["pos"]) < ISLAND_W * 0.5:
			return pid
	for sid in sim.seen_spots():
		if mp.distance_to(GameData.pos_of(sid)) < SPOT_R:
			return sid
	for sid in sim.found_spots():
		if not GameData.PORTS.has(sid) and mp.distance_to(GameData.pos_of(sid)) < SPOT_R:
			return sid
	return ""


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var p := _port_at(event.position)
		if p != hover_port:
			hover_port = p
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if p != "" else Control.CURSOR_ARROW
			port_hovered.emit(p)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var p := _port_at(event.position)
		if p != "":
			port_clicked.emit(p)
			accept_event()


func _draw() -> void:
	var sc := _scale()
	# sky: tiled paper texture tinted by season
	var tint := Color(1, 1, 1)
	if sim != null:
		tint = [Color(0.97, 1.0, 0.97), Color(1.0, 0.98, 0.92), Color(1.0, 0.93, 0.85), Color(0.9, 0.94, 1.0)][(int(sim.s["day"]) % 360) / 90]
	draw_texture_rect(_paper, Rect2(Vector2.ZERO, size), true, tint)
	# soft paper vignette
	for i in 6:
		var inset := float(i) * 18.0
		draw_rect(Rect2(Vector2(inset, inset), size - Vector2(inset, inset) * 2.0), Color(0.86, 0.91, 0.91, 0.08), false, 18.0)
	# far clouds
	for c in _clouds:
		if c["r"] > 90:
			_cloud(c, sc)
	if sim == null:
		return
	# routes of player ships
	var fl := sim.flagship()
	for sh in sim.ships_of(sim.pid()):
		if not sim.docked(sh):
			var a := to_screen(GameData.pos_of(sh["from"]))
			var b := to_screen(GameData.pos_of(sh["to"]))
			_dashed(a, b, Color(UiKit.BRASS, 0.85) if sh["id"] == fl.get("id", -1) else Color(UiKit.JADE, 0.55), 3.0 * sc + 1.0)
		elif sh["route"] != null and sh["route"].has("stops"):
			var stops: Array = sh["route"]["stops"]
			for i in stops.size():
				var a2 := to_screen(GameData.PORTS[stops[i]["port"]]["pos"])
				var b2 := to_screen(GameData.PORTS[stops[(i + 1) % stops.size()]["port"]]["pos"])
				_dashed(a2, b2, Color(UiKit.JADE, 0.35), 2.0)
	# hover route preview from flagship
	if not fl.is_empty() and sim.docked(fl) and hover_port != "" and hover_port != fl["port"]:
		_dashed(to_screen(GameData.pos_of(fl["port"])), to_screen(GameData.pos_of(hover_port)), Color(UiKit.BRASS, 0.9), 3.0)
	# islands
	var font := UiKit.font_bold if UiKit.font_bold else ThemeDB.fallback_font
	var open: Array = sim.open_ports()
	for pid in open:
		var p := to_screen(GameData.PORTS[pid]["pos"])
		var tex: Texture2D = _island_tex[pid]
		var w := ISLAND_W * sc
		var bob := sin(_t * 0.8 + p.x * 0.01) * 3.0 * sc
		var h := w * tex.get_height() / tex.get_width()
		if pid == highlight_port:
			var pulse := 0.5 + 0.5 * sin(_t * 4.0)
			draw_circle(p + Vector2(0, bob), w * (0.58 + 0.06 * pulse), Color(UiKit.BRASS, 0.25 + 0.2 * pulse))
		if pid == selected_port or pid == hover_port:
			draw_circle(p + Vector2(0, bob), w * 0.55, Color(1, 1, 1, 0.35))
		draw_texture_rect(tex, Rect2(p - Vector2(w, h) * 0.5 + Vector2(0, bob), Vector2(w, h)), false)
	_draw_fog(sc, font)
	# ships
	for sh in sim.s["ships"]:
		var sp := to_screen(sim.ship_pos(sh))
		var tex2: Texture2D = _ship_tex[sh["type"]]
		var w2 := (84.0 if sh["owner"] == sim.pid() else 64.0) * sc
		var h2 := w2 * tex2.get_height() / tex2.get_width()
		var off := Vector2.ZERO
		if sim.docked(sh):
			# fan out docked ships around the island
			var idx := _dock_slot(sh)
			off = Vector2(ISLAND_W * 0.62 * (1 if idx % 2 == 0 else -1), -10.0 + 34.0 * (idx / 2)) * sc
		var bob2 := sin(_t * 2.0 + float(sh["id"])) * 2.5 * sc
		var r2 := Rect2(sp + off - Vector2(w2, h2) * 0.5 + Vector2(0, bob2 - 18.0 * sc), Vector2(w2, h2))
		draw_set_transform(r2.get_center() + Vector2(0, h2 * 0.75), 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, w2 * 0.4, Color(0.1, 0.2, 0.25, 0.16))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		if sh["owner"] != sim.pid():
			draw_texture_rect(tex2, r2, false, Color(0.82, 0.86, 0.92, 0.95))
			draw_circle(r2.position + Vector2(r2.size.x * 0.5, -3), 4.5 * maxf(sc, 0.8), GameData.HOUSES[sh["owner"]]["color"])
		else:
			if sh.get("flagship", false):
				draw_circle(r2.get_center(), w2 * 0.62, Color(UiKit.BRASS, 0.22))
			draw_texture_rect(tex2, r2, false)
	# seasonal wind rose (bottom right of the map)
	var day: int = sim.s["day"]
	var wv: Vector2 = GameData.WIND[(day % GameData.DAYS_YEAR) / 90]
	var wc := Vector2(size.x - 70, size.y - 150)
	draw_circle(wc, 30.0, Color(1, 1, 1, 0.55))
	draw_arc(wc, 30.0, 0.0, TAU, 40, Color(UiKit.BRASS, 0.8), 1.5, true)
	var sway := sin(_t * 1.7) * 0.08
	var dir := wv.rotated(sway)
	var tip := wc + dir * 24.0
	draw_line(wc - dir * 20.0, tip, UiKit.INK, 3.0, true)
	draw_line(tip, tip - dir.rotated(0.5) * 9.0, UiKit.INK, 3.0, true)
	draw_line(tip, tip - dir.rotated(-0.5) * 9.0, UiKit.INK, 3.0, true)
	draw_string(font, wc + Vector2(-32, 50), "%s · %s" % [GameData.SEASONS[(day % GameData.DAYS_YEAR) / 90], GameData.wind_name(day)], HORIZONTAL_ALIGNMENT_CENTER, 64, 13, UiKit.INK)
	# port name plates on top of ships
	for pid in open:
		var p := to_screen(GameData.PORTS[pid]["pos"])
		var tex: Texture2D = _island_tex[pid]
		var w := ISLAND_W * sc
		var bob := sin(_t * 0.8 + p.x * 0.01) * 3.0 * sc
		var h := w * tex.get_height() / tex.get_width()
		var home_of := ""
		for hid in GameData.HOUSE_IDS:
			if GameData.HOUSES[hid]["home"] == pid:
				home_of = hid
		var name: String = GameData.PORTS[pid]["name"]
		var fs := int(maxf(13.0, 20.0 * sc))
		var tw := font.get_string_size(name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var lp := p + Vector2(-tw * 0.5, h * 0.5 + fs + 2 + bob)
		var plate := Rect2(lp + Vector2(-8, -fs - 2), Vector2(tw + 16, fs + 10))
		draw_style_box(UiKit.box(Color(UiKit.PARCH, 0.92), Color(UiKit.BRASS, 0.7), 4, 1, 0), plate)
		draw_string(font, lp, name, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiKit.INK)
		if home_of != "":
			var col: Color = GameData.HOUSES[home_of]["color"]
			draw_circle(plate.position + Vector2(plate.size.x + 2, plate.size.y * 0.5), 6.0 * maxf(sc, 0.8), col)
		var pat := sim.patron(pid)
		if pat != "":
			# patron: a coloured band under the name plate
			draw_rect(Rect2(plate.position + Vector2(4, plate.size.y - 3), Vector2(plate.size.x - 8, 3)), GameData.HOUSES[pat]["color"])
		var cs := sim.open_contracts(pid)
		if not cs.is_empty():
			# contract notice pinned above the island
			var c: Dictionary = cs[0]
			var cp := p + Vector2(w * 0.32, -h * 0.42 + bob)
			var bounce := sin(_t * 3.0) * 2.0
			var r := 15.0 * maxf(sc, 0.8)
			draw_circle(cp + Vector2(0, bounce), r + 2.0, UiKit.BRASS)
			draw_circle(cp + Vector2(0, bounce), r, Color("fff4d6"))
			var ifs := int(r * 1.2)
			draw_string(font, cp + Vector2(-ifs * 0.5, ifs * 0.42 + bounce), "委", HORIZONTAL_ALIGNMENT_LEFT, -1, ifs, UiKit.TERRA)
			if not c["chasers"].is_empty():
				draw_arc(cp + Vector2(0, bounce), r + 5.0, 0.0, TAU, 24, Color(UiKit.TERRA, 0.5 + 0.4 * sin(_t * 5.0)), 2.0)
	# near clouds over everything
	for c in _clouds:
		if c["r"] <= 90:
			_cloud(c, sc)


## The eastern sea: dense paper fog that thins around what the player has found, and the
## question marks of places seen but not yet visited.
func _draw_fog(sc: float, font: Font) -> void:
	var clear: Array = sim.clear_points()
	var open_east: bool = sim.explore_open()
	var cr := 300.0 if open_east else 0.0
	for f in _fog:
		var fp: Vector2 = f["p"]
		var mind := 1e9
		for c in clear:
			mind = minf(mind, fp.distance_to(c))
		var k := clampf((mind - cr) / 220.0, 0.0, 1.0)
		if fp.x < GameData.EAST_X:
			k *= clampf((fp.x - 1430.0) / 140.0, 0.0, 1.0)   # the fog bank fades in at the edge of the charts
		if k <= 0.02:
			continue
		var drift := Vector2(sin(_t * 0.25 + f["ph"]) * 14.0, cos(_t * 0.2 + f["ph"]) * 8.0)
		_cloud({"p": fp + drift, "r": f["r"], "a": f["a"] * k}, sc)
	if not open_east:
		if region == 2 or size.x / _scale() + _vx > 1700.0:
			var c := to_screen(Vector2(2250, 500))
			draw_string(font, c + Vector2(-140, 0), "东方 · 未知的云海", HORIZONTAL_ALIGNMENT_CENTER, 280, 26, Color(UiKit.INK, 0.45))
			draw_string(font, c + Vector2(-200, 34), "行会里可以赞助探险队，找出通往那里的航路", HORIZONTAL_ALIGNMENT_CENTER, 400, 14, Color(UiKit.INK, 0.4))
		return
	# places found (that are not cities): a small plate that remembers what was there
	for sid in sim.found_spots():
		if GameData.PORTS.has(sid):
			continue
		var sp: Dictionary = GameData.SPOTS[sid]
		var p := to_screen(GameData.pos_of(sid))
		var r := 14.0 * maxf(sc, 0.8)
		var glyph: String = {"passage": "隙", "wreck": "漂", "ruin": "遗"}.get(sp["kind"], "·")
		draw_circle(p, r + 1.5, Color(UiKit.INK, 0.55))
		draw_circle(p, r, Color(UiKit.PARCH, 0.95))
		draw_string(font, p + Vector2(-r * 0.55, r * 0.42), glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 1.1), UiKit.INK)
		if sid == selected_port or sid == hover_port:
			draw_arc(p, r + 5.0, 0.0, TAU, 24, Color(UiKit.BRASS, 0.9), 2.0)
		var fs := int(maxf(11.0, 14.0 * sc))
		draw_string(font, p + Vector2(-60, r + fs + 2), sp["name"], HORIZONTAL_ALIGNMENT_CENTER, 120, fs, Color(UiKit.INK, 0.8))
	# places seen but not visited: a question mark drifting in the thin fog
	for sid in sim.seen_spots():
		var p := to_screen(GameData.pos_of(sid))
		var pulse := 0.5 + 0.5 * sin(_t * 2.2 + p.x * 0.02)
		var r := 20.0 * maxf(sc, 0.8)
		var bob := sin(_t * 1.1 + p.y * 0.01) * 3.0
		var c := p + Vector2(0, bob)
		draw_circle(c, r + 6.0 + 3.0 * pulse, Color(UiKit.BRASS, 0.18 + 0.12 * pulse))
		draw_circle(c, r + 1.5, Color(UiKit.INK, 0.7))
		draw_circle(c, r, Color("fff4d6"))
		draw_string(font, c + Vector2(-r * 0.4, r * 0.5), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 1.5), UiKit.TERRA)
		if sid == selected_port or sid == hover_port:
			draw_arc(c, r + 9.0, 0.0, TAU, 28, Color(UiKit.BRASS, 0.95), 2.5)


func _dock_slot(sh: Dictionary) -> int:
	# stable slot among the ships docked at the same port
	var n := 0
	for o in sim.s["ships"]:
		if o["id"] == sh["id"]:
			return n
		if sim.docked(o) and o["port"] == sh["port"]:
			n += 1
	return n


func _cloud(c: Dictionary, sc: float) -> void:
	# flat paper cloud: stacked lobes with a slightly darker cut edge underneath
	var p := to_screen(c["p"])
	var r: float = c["r"] * sc
	var a: float = c["a"]
	var lobes := [Vector2(0, 0), Vector2(r * 0.85, r * 0.12), Vector2(-r * 0.8, r * 0.16), Vector2(r * 0.35, -r * 0.35)]
	var radii := [r * 0.62, r * 0.48, r * 0.44, r * 0.42]
	draw_set_transform(p + Vector2(0, r * 0.12), 0.0, Vector2(1.0, 0.55))
	for i in lobes.size():
		draw_circle(lobes[i] + Vector2(0, r * 0.08), radii[i], Color(0.62, 0.72, 0.76, a * 0.35))
	for i in lobes.size():
		draw_circle(lobes[i], radii[i], Color(1, 1, 1, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _dashed(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var d := a.distance_to(b)
	if d < 1.0:
		return
	var dir := (b - a) / d
	var step := 14.0
	var phase := fmod(_t * 18.0, step)
	var x := phase
	while x < d:
		draw_line(a + dir * x, a + dir * minf(x + step * 0.55, d), col, w, true)
		x += step
