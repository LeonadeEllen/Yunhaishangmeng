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
var _islets := []             # small floating rocks between the ports (finish plan, phase D)
var _currents := []           # cloud currents: streamlines drawn as drifting dashes
var _whales := []             # cloud whales swimming slow loops
var _lanes := []              # faint trade lanes between neighbouring ports
const STORMS := [Vector2(590, 700), Vector2(1110, 70), Vector2(1520, 880), Vector2(2280, 980), Vector2(2600, 470)]


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
	# scenery between the ports
	var dr := RandomNumberGenerator.new()
	dr.seed = 9090
	var tries := 0
	while _islets.size() < 70 and tries < 2000:
		tries += 1
		var ip := Vector2(dr.randf_range(140, 2960), dr.randf_range(-20, 1080))
		var ok := true
		for pid in GameData.PORT_IDS:
			if ip.distance_to(GameData.PORTS[pid]["pos"]) < 125:
				ok = false
		for sid in GameData.SPOT_IDS:
			if ip.distance_to(GameData.pos_of(sid)) < 70:
				ok = false
		for st in STORMS:
			if ip.distance_to(st) < 120:
				ok = false
		if ok:
			_islets.append({"p": ip, "r": dr.randf_range(10, 22), "k": dr.randi_range(0, 3), "ph": dr.randf() * TAU})
	for i in 14:
		var start := Vector2(dr.randf_range(100, 2800), dr.randf_range(40, 1040))
		var pts := PackedVector2Array()
		var amp := dr.randf_range(18, 46)
		var freq := dr.randf_range(0.004, 0.009)
		var len := dr.randf_range(380, 760)
		var x := 0.0
		while x < len:
			pts.append(start + Vector2(x, sin(x * freq + i) * amp))
			x += 18.0
		_currents.append({"pts": pts, "ph": dr.randf() * 10.0, "dir": 1.0 if i % 3 != 0 else -1.0})
	_whales = [{"c": Vector2(1040, 430), "rx": 190.0, "ry": 70.0, "sp": 0.05, "ph": 0.0, "s": 1.0},
		{"c": Vector2(640, 860), "rx": 160.0, "ry": 50.0, "sp": -0.04, "ph": 2.0, "s": 0.8},
		{"c": Vector2(2380, 650), "rx": 220.0, "ry": 90.0, "sp": 0.035, "ph": 4.0, "s": 1.2}]
	for i in GameData.PORT_IDS.size():
		for j in range(i + 1, GameData.PORT_IDS.size()):
			var a: Vector2 = GameData.PORTS[GameData.PORT_IDS[i]]["pos"]
			var b: Vector2 = GameData.PORTS[GameData.PORT_IDS[j]]["pos"]
			if a.distance_to(b) < 470:
				_lanes.append([GameData.PORT_IDS[i], GameData.PORT_IDS[j]])
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
	# the cloud sea deepens towards the bottom of the chart
	for i in 10:
		draw_rect(Rect2(0, size.y * (0.5 + i * 0.05), size.x, size.y * 0.05 + 1), Color(0.45, 0.6, 0.7, 0.012 * i))
	_draw_currents(sc)
	# far clouds
	for c in _clouds:
		if c["r"] > 90:
			_cloud(c, sc)
	if sim == null:
		return
	_draw_whales(sc)
	_draw_islets(sc)
	_draw_storms(sc)
	# well-worn trade lanes between neighbouring ports
	var open0: Array = sim.open_ports()
	for ln in _lanes:
		if open0.has(ln[0]) and open0.has(ln[1]):
			_dotted(to_screen(GameData.PORTS[ln[0]]["pos"]), to_screen(GameData.PORTS[ln[1]]["pos"]), Color(UiKit.INK, 0.13), 1.6 * maxf(sc, 0.7))
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
		# the island's shadow on the clouds below, swaying opposite to the bob
		draw_set_transform(p + Vector2(w * 0.08, h * 0.62 - bob * 0.5), 0.0, Vector2(1.0, 0.26))
		draw_circle(Vector2.ZERO, w * 0.36, Color(0.15, 0.25, 0.3, 0.13))
		draw_circle(Vector2.ZERO, w * 0.24, Color(0.15, 0.25, 0.3, 0.1))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
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
		var flip := false
		if not sim.docked(sh) and GameData.PORTS.has(sh["from"]) and GameData.PORTS.has(sh["to"]):
			var heading: Vector2 = (GameData.PORTS[sh["to"]]["pos"] - GameData.PORTS[sh["from"]]["pos"]).normalized()
			flip = heading.x < -0.05
			# a wake of little cloud puffs behind the ship
			for k in 7:
				var age := fmod(_t * 0.9 + float(k) / 7.0, 1.0)
				var wp := r2.get_center() + Vector2(0, h2 * 0.25) - heading * (w2 * 0.35 + age * 70.0 * sc) + Vector2(0, sin(_t * 3.0 + k) * 2.0)
				draw_circle(wp, (3.0 + age * 9.0) * maxf(sc, 0.7), Color(1, 1, 1, (1.0 - age) * 0.55))
		draw_set_transform(r2.get_center() + Vector2(0, h2 * 0.75), 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, w2 * 0.4, Color(0.1, 0.2, 0.25, 0.16))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var ship_rect := r2
		if flip:
			draw_set_transform(r2.get_center(), 0.0, Vector2(-1, 1))
			ship_rect = Rect2(-r2.size * 0.5, r2.size)
		if sh["owner"] != sim.pid():
			draw_texture_rect(tex2, ship_rect, false, Color(0.82, 0.86, 0.92, 0.95))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			draw_circle(r2.position + Vector2(r2.size.x * 0.5, -3), 4.5 * maxf(sc, 0.8), GameData.HOUSES[sh["owner"]]["color"])
		else:
			if sh.get("flagship", false):
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				draw_circle(r2.get_center(), w2 * 0.62, Color(UiKit.BRASS, 0.22))
				if flip:
					draw_set_transform(r2.get_center(), 0.0, Vector2(-1, 1))
			draw_texture_rect(tex2, ship_rect, false)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# dusk and night over the chart: the ports light their lamps
	var night := _night()
	if night > 0.01:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.09, 0.22, night * 0.8))
		for pid in open:
			var lp2 := to_screen(GameData.PORTS[pid]["pos"])
			draw_circle(lp2, ISLAND_W * sc * 0.45, Color(1.0, 0.78, 0.4, night * 0.28))
			for k in 5:
				var a := float(k) * 1.3 + float(pid.hash() % 7)
				draw_circle(lp2 + Vector2(cos(a), sin(a) * 0.5) * ISLAND_W * sc * 0.22, 2.2 * maxf(sc, 0.8), Color(1.0, 0.86, 0.5, night * (1.6 + 0.4 * sin(_t * 3.0 + k))))
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
		var ben := sim.benefactor(pid)
		if ben != "":
			# benefactor: a small diamond at the left of the plate
			var bc := plate.position + Vector2(-3, plate.size.y * 0.5)
			var rr := 6.0 * maxf(sc, 0.8)
			draw_colored_polygon(PackedVector2Array([bc + Vector2(0, -rr), bc + Vector2(rr, 0), bc + Vector2(0, rr), bc + Vector2(-rr, 0)]), GameData.HOUSES[ben]["color"])
			draw_polyline(PackedVector2Array([bc + Vector2(0, -rr), bc + Vector2(rr, 0), bc + Vector2(0, rr), bc + Vector2(-rr, 0), bc + Vector2(0, -rr)]), Color(1, 1, 1, 0.8), 1.0)
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
	# brass corner ornaments: this is a chart on the captain's table
	for corner: Vector2 in [Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), Vector2(1, 1)]:
		var cp2 := Vector2(corner.x * size.x, corner.y * size.y) + Vector2(14 - corner.x * 28, 14 - corner.y * 28)
		var dx := 1.0 - corner.x * 2.0
		var dy := 1.0 - corner.y * 2.0
		draw_polyline(PackedVector2Array([cp2 + Vector2(0, 46 * dy), cp2, cp2 + Vector2(46 * dx, 0)]), Color(UiKit.BRASS, 0.75), 3.0)
		draw_polyline(PackedVector2Array([cp2 + Vector2(6 * dx, 30 * dy), cp2 + Vector2(6 * dx, 6 * dy), cp2 + Vector2(30 * dx, 6 * dy)]), Color(UiKit.BRASS, 0.5), 1.5)
		draw_circle(cp2 + Vector2(6 * dx, 6 * dy), 3.0, Color(UiKit.BRASS, 0.8))


func _night() -> float:
	var tod := fposmod((float(sim.s["day"]) + float(sim.s.get("frac", 0.0))) * 0.37, 1.0)
	return clampf(absf(tod - 0.5) * 2.6 - 0.75, 0.0, 0.45)


## Streamlines of the cloud currents: dashes drift along them.
func _draw_currents(sc: float) -> void:
	for cur in _currents:
		var pts: PackedVector2Array = cur["pts"]
		var dir: float = cur["dir"]
		for i in range(0, pts.size() - 1):
			var phase := fmod(_t * 0.6 * dir + float(cur["ph"]) + i * 0.17, 1.0)
			if phase < 0.0:
				phase += 1.0
			if phase < 0.45:
				var a := to_screen(pts[i])
				var b := to_screen(pts[i + 1])
				draw_line(a, b, Color(1, 1, 1, 0.6 * (1.0 - absf(phase - 0.22) * 4.0)), 2.6 * maxf(sc, 0.7), true)
		# an arrowhead at the downstream end
		var e := to_screen(pts[pts.size() - 1] if dir > 0 else pts[0])
		var d2 := (to_screen(pts[pts.size() - 1]) - to_screen(pts[pts.size() - 2])).normalized() * dir
		draw_line(e, e - d2.rotated(0.5) * 9.0, Color(1, 1, 1, 0.35), 2.0, true)
		draw_line(e, e - d2.rotated(-0.5) * 9.0, Color(1, 1, 1, 0.35), 2.0, true)


func _draw_islets(sc: float) -> void:
	for it in _islets:
		var p := to_screen(it["p"]) + Vector2(0, sin(_t * 0.7 + float(it["ph"])) * 2.0 * sc)
		var r: float = float(it["r"]) * maxf(sc, 0.6)
		if p.x < -40 or p.x > size.x + 40:
			continue
		draw_set_transform(p + Vector2(0, r * 1.6), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, r, Color(0.15, 0.25, 0.3, 0.1))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var rock := Color("8d7b68").lerp(Color("a07a5a"), float(int(it["k"]) % 2) * 0.5)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-r, 0), p + Vector2(r, 0), p + Vector2(r * 0.3, r * 1.3), p + Vector2(-r * 0.2, r * 1.0)]), rock)
		draw_colored_polygon(PackedVector2Array([p + Vector2(-r * 1.05, 1), p + Vector2(r * 1.05, 1), p + Vector2(r * 0.8, -r * 0.35), p + Vector2(-r * 0.7, -r * 0.4)]), Color("8fae7a") if int(it["k"]) != 3 else Color("d8d8d0"))
		if int(it["k"]) == 1:
			draw_line(p + Vector2(r * 0.2, -r * 0.3), p + Vector2(r * 0.2, -r * 1.2), Color("6a4a30"), 1.4)
			draw_circle(p + Vector2(r * 0.2, -r * 1.3), r * 0.45, Color("6f9450"))
		elif int(it["k"]) == 2 and r > 12:
			# an old ruined tower
			draw_rect(Rect2(p + Vector2(-r * 0.25, -r * 1.3), Vector2(r * 0.5, r * 1.0)), Color("b9b0a0"))
			draw_rect(Rect2(p + Vector2(-r * 0.32, -r * 1.42), Vector2(r * 0.64, r * 0.2)), Color("a09888"))


func _draw_storms(sc: float) -> void:
	for st in STORMS:
		var p := to_screen(st)
		if p.x < -200 or p.x > size.x + 200:
			continue
		var r := 70.0 * sc
		for k in 6:
			var a := float(k) / 6.0 * TAU + _t * 0.08
			var cp := p + Vector2(cos(a) * r * 0.7, sin(a) * r * 0.32)
			draw_set_transform(cp, 0.0, Vector2(1.0, 0.55))
			draw_circle(Vector2(0, 6), r * 0.55, Color(0.2, 0.24, 0.32, 0.25))
			draw_circle(Vector2.ZERO, r * 0.5, Color(0.42, 0.46, 0.55, 0.55))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_set_transform(p, 0.0, Vector2(1.0, 0.55))
		draw_circle(Vector2.ZERO, r * 0.6, Color(0.3, 0.33, 0.42, 0.7))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# lightning now and then
		var flash := fmod(_t * 0.7 + st.x * 0.01, 3.0)
		if flash < 0.12:
			var bolt := PackedVector2Array([p + Vector2(-4, -6) * sc, p + Vector2(6, 10) * sc, p + Vector2(-2, 12) * sc, p + Vector2(8, 34) * sc])
			draw_polyline(bolt, Color(1.0, 0.95, 0.6, 0.95), 3.0 * maxf(sc, 0.7), true)
			draw_circle(p, r * 0.8, Color(1.0, 1.0, 0.85, 0.12))


func _draw_whales(sc: float) -> void:
	for wh in _whales:
		var ang: float = _t * float(wh["sp"]) + float(wh["ph"])
		var c: Vector2 = wh["c"]
		var mp := c + Vector2(cos(ang) * float(wh["rx"]), sin(ang) * float(wh["ry"]))
		var vel := Vector2(-sin(ang) * float(wh["rx"]), cos(ang) * float(wh["ry"])) * signf(float(wh["sp"]))
		var p := to_screen(mp)
		if p.x < -150 or p.x > size.x + 150:
			continue
		var s: float = float(wh["s"]) * sc
		var face := -1.0 if vel.x < 0 else 1.0
		var body := Color(0.55, 0.66, 0.74, 0.42)
		draw_set_transform(p, 0.0, Vector2(face, 1.0))
		draw_colored_polygon(PackedVector2Array([Vector2(46, 0) * s, Vector2(30, -14) * s, Vector2(-10, -16) * s, Vector2(-40, -6) * s, Vector2(-52, 0) * s, Vector2(-40, 6) * s, Vector2(-6, 14) * s, Vector2(32, 12) * s]), body)
		var flap := sin(_t * 1.6) * 6.0
		draw_colored_polygon(PackedVector2Array([Vector2(-48, 0) * s, Vector2(-70, -12 + flap) * s, Vector2(-62, 0) * s, Vector2(-70, 12 + flap) * s]), body)
		draw_colored_polygon(PackedVector2Array([Vector2(0, 8) * s, Vector2(14, 22 + flap * 0.5) * s, Vector2(18, 10) * s]), body)
		draw_circle(Vector2(30, -4) * s, 2.0 * s, Color(0.2, 0.25, 0.3, 0.5))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _dotted(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var d := a.distance_to(b)
	if d < 1.0:
		return
	var dir := (b - a) / d
	var x := 6.0
	while x < d - 6.0:
		draw_circle(a + dir * x, w, col)
		x += 11.0


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
