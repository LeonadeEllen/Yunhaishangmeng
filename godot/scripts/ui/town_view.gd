extends Control
## A walkable top-down town (placeholder art): the protagonist strolls between buildings,
## bumps into townsfolk with rumours, and enters a building to open its counter.
## Layouts are generated per port from a fixed seed, so every city has its own street plan.

signal building_entered(kind: String)
signal left_town()

const KIND_INFO := {
	"trade": {"name": "交易所", "sprite": 0, "tab": 0, "npc": 4, "who": "掌柜"},
	"yard": {"name": "船坞", "sprite": 1, "tab": 1, "npc": 3, "who": "船匠"},
	"post": {"name": "商馆", "sprite": 6, "tab": 2, "npc": -1, "who": "账房"},
	"hall": {"name": "城主府", "sprite": 2, "tab": 3, "npc": 6, "who": "城主"},
	"guild": {"name": "工匠行会", "sprite": 3, "tab": 4, "npc": 5, "who": "匠师"},
	"tavern": {"name": "酒馆", "sprite": 7, "tab": 5, "npc": 7, "who": "老板"},
	"bank": {"name": "商会银行", "sprite": 4, "tab": 5, "npc": 2, "who": "司库"},
	"works": {"name": "工坊区", "sprite": 5, "tab": 2, "npc": -1, "who": "工头"},
	"lighthouse": {"name": "灯塔工地", "sprite": -1, "tab": 6, "npc": 3, "who": "工头"},
}
const HERO_SPEED := 230.0
const ENTER_DIST := 52.0
const NPC_LINES := [
	"今天的云海真平静，船来得多。",
	"你是%s的人？听说你们在抢灯塔。",
	"码头那边新到了一批货，去交易所看看吧。",
	"酒馆里有人在讲远方云域的事。",
	"城主府最近在招人做事，友好度高的商会才接得到。",
	"工匠行会的图纸可不便宜，但做出来的东西值钱。",
	"在这里多做买卖，城里人就会记住你。",
]

var sim: Sim
var port := ""
var hero_pos := Vector2.ZERO
var _target := Vector2(-1, -1)
var _auto_enter := ""
var _buildings := []
var _npcs := []
var _trees := []
var _t := 0.0
var _facing := 1.0
var _moving := false
var _near := ""
var _ground: Texture2D
var _tex := {}
var _entered_at := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ground = UiKit.scene_art("paper_sea")
	resized.connect(_layout)


## Build the street plan for a port. Called every time the player walks into town.
func open(pid: String) -> void:
	port = pid
	_t = 0.0
	_entered_at = 0.0
	_auto_enter = ""
	_target = Vector2(-1, -1)
	_layout()
	queue_redraw()


func _layout() -> void:
	if port == "" or sim == null:
		return
	var p: Dictionary = GameData.PORTS[port]
	var r := RandomNumberGenerator.new()
	r.seed = 1000 + int(p["island"]) * 17
	var home: bool = GameData.HOUSES[sim.pid()]["home"] == port
	var kinds := ["trade", "tavern", "hall", "guild", "post", "bank", "works"]
	if home:
		kinds.append("lighthouse")
	# the shipyard sits on the harbour edge at the bottom; everything else rings the plaza
	var c := size * Vector2(0.5, 0.5)
	var rad := Vector2(size.x * 0.36, size.y * 0.3)
	var start := r.randf_range(0.0, TAU)
	var dir := 1.0 if r.randf() < 0.5 else -1.0
	_buildings.clear()
	for i in kinds.size():
		var ang := start + dir * TAU * float(i) / float(kinds.size())
		# keep the bottom arc free for the harbour
		if sin(ang) > 0.55:
			ang += PI * 0.5 * dir
		var pos := c + Vector2(cos(ang) * rad.x, sin(ang) * rad.y * 0.85) + Vector2(r.randf_range(-24, 24), r.randf_range(-16, 16))
		pos.x = clampf(pos.x, 110, size.x - 110)
		pos.y = clampf(pos.y, 120, size.y - 150)
		_buildings.append(_make_building(kinds[i], pos))
	_buildings.append(_make_building("yard", Vector2(c.x + r.randf_range(-160, 160), size.y - 118)))
	# spread crowded buildings apart so nothing overlaps
	for it in 40:
		for i in _buildings.size():
			for j in range(i + 1, _buildings.size()):
				var a: Dictionary = _buildings[i]
				var b: Dictionary = _buildings[j]
				var d: Vector2 = b["pos"] - a["pos"]
				var want: float = (a["size"].x + b["size"].x) * 0.5 + 24
				var want_y: float = (a["size"].y + b["size"].y) * 0.5 + 30
				if absf(d.x) < want and absf(d.y) < want_y:
					var push := Vector2(signf(d.x) * (want - absf(d.x)), signf(d.y) * (want_y - absf(d.y))) * 0.25
					if absf(d.x) / want > absf(d.y) / want_y:
						push.y = 0
					else:
						push.x = 0
					if a["kind"] != "yard":
						a["pos"] -= push
					if b["kind"] != "yard":
						b["pos"] += push
		for b in _buildings:
			b["pos"].x = clampf(b["pos"].x, 100, size.x - 100)
			b["pos"].y = clampf(b["pos"].y, 120, size.y - 110)
			b["door"] = b["pos"] + Vector2(0, b["size"].y * 0.5 + 8)
	_trees.clear()
	for i in 26:
		var tp := Vector2(r.randf_range(30, size.x - 30), r.randf_range(90, size.y - 40))
		var ok := true
		for b in _buildings:
			if tp.distance_to(b["pos"]) < 120:
				ok = false
		if ok:
			_trees.append({"p": tp, "r": r.randf_range(9, 18), "k": r.randi_range(0, 2)})
	# the protagonist steps off the ship at the harbour
	hero_pos = Vector2(c.x, size.y - 60)
	_npcs.clear()
	var lines := NPC_LINES.duplicate()
	lines.shuffle()
	for i in 4:
		var np := Vector2(r.randf_range(140, size.x - 140), r.randf_range(160, size.y - 170))
		_npcs.append({"p": np, "v": Vector2.ZERO, "t": r.randf_range(0.0, 2.0), "line": _rumour(r) if i == 0 else lines[i], "hue": r.randf()})
	# a few of your companions have come ashore too (round 13)
	var crew_ids: Array = sim.crew().keys()
	var cr := RandomNumberGenerator.new()
	cr.seed = int(sim.s["day"]) * 31 + int(p["island"])
	for i in mini(3, crew_ids.size()):
		var cid: String = crew_ids[cr.randi_range(0, crew_ids.size() - 1)]
		crew_ids.erase(cid)
		var banter: Array = Characters.BANTER.get(cid, ["……"])
		var cp := Vector2(cr.randf_range(180, size.x - 180), cr.randf_range(180, size.y - 180))
		_npcs.append({"p": cp, "v": Vector2.ZERO, "t": cr.randf_range(0.0, 2.0), "line": banter[cr.randi_range(0, banter.size() - 1)],
			"hue": fposmod(float(cid.hash() % 1000) / 1000.0, 1.0), "cid": cid})


func _make_building(kind: String, pos: Vector2) -> Dictionary:
	var info: Dictionary = KIND_INFO[kind]
	var tex: Texture2D
	if kind == "lighthouse":
		var stage: int = sim.house()["lh"]["stage"]
		var idx: int = 0 if stage == 0 else int(GameData.LIGHTHOUSE[stage - 1]["sprite"])
		tex = UiKit.sprite("lighthouse", idx)
	else:
		tex = UiKit.sprite("city_buildings", info["sprite"])
	var w := 164.0 if kind in ["hall", "trade", "lighthouse"] else 138.0
	var h := w * float(tex.get_height()) / float(tex.get_width())
	return {"kind": kind, "name": info["name"], "tex": tex, "pos": pos, "size": Vector2(w, h), "door": pos + Vector2(0, h * 0.5 + 8)}


## A tip built from the real market: where one of this city's signature goods sells best.
func _rumour(r: RandomNumberGenerator) -> String:
	var g: String = GameData.PORTS[port]["make"][r.randi_range(0, 1)]
	var best := ""
	var best_p := 0
	for pid in sim.open_ports():
		if pid == port:
			continue
		var sp := sim.sell_price(pid, g)
		if sp > best_p:
			best_p = sp
			best = pid
	return "听说%s的%s卖到 %d 金一件。" % [GameData.port_name(best), GameData.good_name(g), best_p]


func _process(delta: float) -> void:
	if not visible or port == "":
		return
	_t += delta
	_entered_at += delta
	# keyboard
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		v.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		v.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		v.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		v.y += 1
	if v != Vector2.ZERO:
		_target = Vector2(-1, -1)
		_auto_enter = ""
		v = v.normalized()
	elif _target.x >= 0:
		var d := _target - hero_pos
		if d.length() < 4.0:
			_target = Vector2(-1, -1)
			if _auto_enter != "":
				var k := _auto_enter
				_auto_enter = ""
				_enter(k)
		else:
			v = d.normalized()
	_moving = v != Vector2.ZERO
	if _moving:
		if absf(v.x) > 0.1:
			_facing = signf(v.x)
		var np := hero_pos + v * HERO_SPEED * delta
		np.x = clampf(np.x, 24, size.x - 24)
		np.y = clampf(np.y, 100, size.y - 30)
		# buildings are solid: slide along their footprint
		for b in _buildings:
			var foot := _footprint(b)
			if foot.has_point(np):
				if foot.has_point(Vector2(hero_pos.x, np.y)):
					np.y = hero_pos.y
				if foot.has_point(Vector2(np.x, hero_pos.y)):
					np.x = hero_pos.x
				if foot.has_point(np):
					np = hero_pos
		hero_pos = np
	# who is close
	_near = ""
	var nd := ENTER_DIST
	for b in _buildings:
		var d := hero_pos.distance_to(b["door"])
		if d < nd:
			nd = d
			_near = b["kind"]
	# townsfolk wander
	for n in _npcs:
		n["t"] -= delta
		if n["t"] <= 0.0:
			n["t"] = randf_range(1.5, 4.0)
			n["v"] = Vector2.ZERO if randf() < 0.4 else Vector2.from_angle(randf_range(0.0, TAU)) * randf_range(25, 55)
		var np: Vector2 = n["p"] + n["v"] * delta
		np.x = clampf(np.x, 60, size.x - 60)
		np.y = clampf(np.y, 130, size.y - 120)
		for b in _buildings:
			if _footprint(b).has_point(np):
				np = n["p"]
				n["v"] = -n["v"]
		n["p"] = np
	queue_redraw()


func _footprint(b: Dictionary) -> Rect2:
	var sz: Vector2 = b["size"]
	return Rect2(b["pos"] - Vector2(sz.x * 0.38, sz.y * 0.05), Vector2(sz.x * 0.76, sz.y * 0.45))


func _building_at(p: Vector2) -> Dictionary:
	for b in _buildings:
		var sz: Vector2 = b["size"]
		if Rect2(b["pos"] - sz * 0.5, sz).has_point(p):
			return b
	return {}


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var b := _building_at(event.position)
		if not b.is_empty():
			if hero_pos.distance_to(b["door"]) < ENTER_DIST:
				_enter(b["kind"])
			else:
				_target = b["door"]
				_auto_enter = b["kind"]
		else:
			_target = event.position
			_auto_enter = ""
		accept_event()


## Enter the building the protagonist stands in front of (E key).
func try_enter() -> void:
	if _near != "":
		_enter(_near)


func _enter(kind: String) -> void:
	_moving = false
	building_entered.emit(kind)


func npc_portrait(kind: String) -> int:
	return int(KIND_INFO.get(kind, {}).get("npc", -1))


func npc_title(kind: String) -> String:
	return str(KIND_INFO.get(kind, {}).get("who", ""))


func kind_name(kind: String) -> String:
	return str(KIND_INFO.get(kind, {}).get("name", ""))


func tab_of(kind: String) -> int:
	return int(KIND_INFO.get(kind, {}).get("tab", 0))


# ------------------------------------------------------------------ drawing
func _draw() -> void:
	if port == "" or sim == null:
		return
	var font := UiKit.font_bold if UiKit.font_bold else ThemeDB.fallback_font
	var p: Dictionary = GameData.PORTS[port]
	# ground: tinted paper per island
	var tints := [Color(0.93, 0.9, 0.8), Color(0.88, 0.93, 0.86), Color(0.95, 0.88, 0.8), Color(0.86, 0.9, 0.94), Color(0.9, 0.86, 0.84), Color(0.86, 0.92, 0.9), Color(0.9, 0.9, 0.82), Color(0.93, 0.86, 0.78), Color(0.9, 0.9, 0.9)]
	draw_texture_rect(_ground, Rect2(Vector2.ZERO, size), true, tints[int(p["island"]) % tints.size()])
	# harbour strip
	draw_rect(Rect2(0, size.y - 70, size.x, 70), Color(0.72, 0.82, 0.86, 0.55))
	for i in 7:
		var x := size.x * (0.08 + 0.14 * i)
		draw_line(Vector2(x, size.y - 70), Vector2(x + 30, size.y), Color(1, 1, 1, 0.25), 3.0)
	# roads from the plaza
	var plaza := size * 0.5
	draw_circle(plaza, 70, Color(0.82, 0.74, 0.58, 0.9))
	draw_circle(plaza, 70, Color(0.6, 0.5, 0.32, 0.6), false, 2.0)
	for b in _buildings:
		var d: Vector2 = b["door"]
		var mid := Vector2(d.x, plaza.y) if absf(d.x - plaza.x) > absf(d.y - plaza.y) else Vector2(plaza.x, d.y)
		draw_polyline([plaza, mid, d], Color(0.82, 0.74, 0.58, 0.95), 22.0)
		draw_polyline([plaza, mid, d], Color(0.95, 0.9, 0.78, 0.5), 4.0)
	# trees
	for t in _trees:
		var tp: Vector2 = t["p"]
		var tr: float = t["r"]
		draw_circle(tp + Vector2(3, 4), tr, Color(0, 0, 0, 0.12))
		draw_circle(tp, tr, [Color(0.45, 0.6, 0.42), Color(0.55, 0.66, 0.4), Color(0.4, 0.56, 0.5)][int(t["k"])])
		draw_circle(tp + Vector2(-tr * 0.3, -tr * 0.3), tr * 0.45, Color(1, 1, 1, 0.18))
	# lantern festival: strings of lanterns along the roads (round 15)
	if sim.festival_on():
		var lr := RandomNumberGenerator.new()
		lr.seed = 77 + int(p["island"])
		for b in _buildings:
			var d: Vector2 = b["door"]
			var mid := Vector2(d.x, plaza.y) if absf(d.x - plaza.x) > absf(d.y - plaza.y) else Vector2(plaza.x, d.y)
			for seg in [[plaza, mid], [mid, d]]:
				var n := int(seg[0].distance_to(seg[1]) / 46.0)
				for i in n:
					var lp2: Vector2 = seg[0].lerp(seg[1], (float(i) + 0.5) / float(maxi(n, 1))) + Vector2(0, -26 + sin(_t * 2.0 + i) * 2.0)
					var lc: Color = [Color(0.95, 0.45, 0.3), Color(0.98, 0.78, 0.35), Color(0.9, 0.35, 0.45)][lr.randi_range(0, 2)]
					draw_circle(lp2, 9, Color(lc, 0.22))
					draw_circle(lp2, 5, lc)
					draw_line(lp2 + Vector2(0, -5), lp2 + Vector2(0, -11), Color(0.35, 0.25, 0.2), 1.5)
	# the benefactor's statue on the plaza (round 14)
	var ben := sim.benefactor(port)
	if ben != "":
		var bc: Color = GameData.HOUSES[ben]["color"]
		draw_ellipse_shadow(plaza + Vector2(0, 14), Vector2(26, 9))
		draw_rect(Rect2(plaza + Vector2(-20, -6), Vector2(40, 18)), Color(0.78, 0.72, 0.6))
		draw_rect(Rect2(plaza + Vector2(-20, -6), Vector2(40, 18)), Color(0.45, 0.38, 0.28, 0.8), false, 1.0)
		_draw_person(plaza + Vector2(0, -6), bc.lightened(0.15), Color(0.72, 0.7, 0.62), false, 1.0)
		var sn := "恩主 · %s" % GameData.HOUSES[ben]["name"]
		var sw := font.get_string_size(sn, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_rect(Rect2(plaza + Vector2(-sw * 0.5 - 5, 16), Vector2(sw + 10, 17)), Color(bc, 0.92))
		draw_string(font, plaza + Vector2(-sw * 0.5, 29), sn, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	# depth-sorted actors
	var items := []
	for b in _buildings:
		items.append({"y": b["pos"].y + b["size"].y * 0.5, "b": b})
	for n in _npcs:
		items.append({"y": n["p"].y, "n": n})
	items.append({"y": hero_pos.y, "hero": true})
	items.sort_custom(func(a, c): return a["y"] < c["y"])
	for it in items:
		if it.has("b"):
			_draw_building(it["b"], font)
		elif it.has("n"):
			var is_crew: bool = it["n"].has("cid")
			_draw_person(it["n"]["p"], Color.from_hsv(it["n"]["hue"], 0.6 if is_crew else 0.35, 0.7 if is_crew else 0.6), Color(0.9, 0.8, 0.66) if is_crew else Color(0.85, 0.75, 0.6), it["n"]["v"] != Vector2.ZERO and is_crew, 1.0)
		else:
			var col: Color = GameData.HOUSES[sim.pid()]["color"]
			_draw_person(hero_pos, col, Color(0.95, 0.85, 0.7), _moving, _facing)
	for b in _buildings:
		_draw_label(b, font)
	# companions wear a name tag
	for n in _npcs:
		if n.has("cid"):
			var nm: String = Characters.name_of(n["cid"])
			var nw := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var tp: Vector2 = n["p"] + Vector2(-nw * 0.5 - 5, -62)
			draw_rect(Rect2(tp, Vector2(nw + 10, 17)), Color(UiKit.JADE, 0.9))
			draw_string(font, tp + Vector2(5, 13), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	# rumours
	for n in _npcs:
		if hero_pos.distance_to(n["p"]) < 64:
			var line: String = n["line"] % GameData.HOUSES[sim.pid()]["name"] if "%s" in n["line"] else n["line"]
			_bubble(n["p"] + Vector2(0, -52 - (14 if n.has("cid") else 0)), line, font)
	# prompt
	if _near != "":
		_bubble(hero_pos + Vector2(0, -58), "按 E 或点击 进入%s" % kind_name(_near), font, true)
	# day / night
	# time of day drifts with the calendar so some visits land at dusk
	var tod := fposmod((float(sim.s["day"]) + float(sim.s.get("frac", 0.0))) * 0.37, 1.0)
	var night := clampf(absf(tod - 0.5) * 2.6 - 0.75, 0.0, 0.45)
	if night > 0.01:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.09, 0.22, night))
		for b in _buildings:
			draw_circle(b["pos"] + Vector2(0, b["size"].y * 0.1), 34, Color(1.0, 0.8, 0.45, night * 0.35))
	# title & hint
	var title := "%s · 城中%s" % [p["name"], " · 灯节" if sim.festival_on() else ""]
	var hint := "WASD / 方向键走动 · 点击建筑进入 · Esc 回到海图"
	var tw1 := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	var tw2 := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	draw_string(font, Vector2(size.x - tw1 - 18, size.y - 40), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(UiKit.INK, 0.9))
	draw_string(font, Vector2(size.x - tw2 - 18, size.y - 18), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(UiKit.INK, 0.8))


func _draw_building(b: Dictionary, font: Font) -> void:
	var sz: Vector2 = b["size"]
	var pos: Vector2 = b["pos"]
	draw_ellipse_shadow(pos + Vector2(0, sz.y * 0.42), Vector2(sz.x * 0.42, sz.y * 0.12))
	draw_texture_rect(b["tex"], Rect2(pos - sz * 0.5, sz), false)


func _draw_label(b: Dictionary, font: Font) -> void:
	var near: bool = b["kind"] == _near
	var fs := 15
	var tw := font.get_string_size(b["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var lp: Vector2 = b["door"] + Vector2(-tw * 0.5 - 8, 6)
	draw_rect(Rect2(lp, Vector2(tw + 16, 22)), Color(UiKit.PARCH, 0.95) if not near else Color(UiKit.BRASS, 0.95))
	draw_rect(Rect2(lp, Vector2(tw + 16, 22)), Color(UiKit.BRASS, 0.8), false, 1.0)
	draw_string(font, lp + Vector2(8, 16), b["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiKit.INK if not near else Color.WHITE)


func draw_ellipse_shadow(c: Vector2, r: Vector2) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * float(i) / 24.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y))
	draw_colored_polygon(pts, Color(0, 0, 0, 0.14))


## A small paper-doll figure: cloak, head, hat. Bobs while walking.
func _draw_person(p: Vector2, cloak: Color, skin: Color, moving: bool, facing: float) -> void:
	var bob := absf(sin(_t * 11.0)) * 3.0 if moving else 0.0
	draw_ellipse_shadow(p + Vector2(0, 2), Vector2(12, 5))
	var base := p + Vector2(0, -bob)
	# legs
	var step := sin(_t * 11.0) * 4.0 if moving else 0.0
	draw_line(base + Vector2(-4, -4), base + Vector2(-4 + step, 2), Color(0.25, 0.2, 0.18), 3.0)
	draw_line(base + Vector2(4, -4), base + Vector2(4 - step, 2), Color(0.25, 0.2, 0.18), 3.0)
	# cloak
	var body := PackedVector2Array([base + Vector2(-10, -4), base + Vector2(10, -4), base + Vector2(7, -26), base + Vector2(-7, -26)])
	draw_colored_polygon(body, cloak)
	draw_polyline([base + Vector2(-10, -4), base + Vector2(10, -4), base + Vector2(7, -26), base + Vector2(-7, -26), base + Vector2(-10, -4)], Color(0, 0, 0, 0.35), 1.0)
	# scarf stripe
	draw_line(base + Vector2(-7, -22), base + Vector2(7, -22), Color(1, 1, 1, 0.35), 2.0)
	# head
	draw_circle(base + Vector2(0, -33), 8, skin)
	draw_circle(base + Vector2(0, -33), 8, Color(0, 0, 0, 0.35), false, 1.0)
	# hair / hat
	draw_arc(base + Vector2(0, -34), 8.5, PI + 0.3, TAU - 0.3, 10, cloak.darkened(0.35), 4.0)
	# eye
	draw_circle(base + Vector2(3.0 * facing, -33), 1.3, Color(0.1, 0.1, 0.1))


func _bubble(at: Vector2, text: String, font: Font, strong: bool = false) -> void:
	var fs := 14
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var w := tw + 20
	var tl := at + Vector2(-w * 0.5, -30)
	tl.x = clampf(tl.x, 6, size.x - w - 6)
	draw_rect(Rect2(tl + Vector2(2, 3), Vector2(w, 28)), Color(0, 0, 0, 0.15))
	draw_rect(Rect2(tl, Vector2(w, 28)), Color(UiKit.INK, 0.94) if strong else Color("fbf5e6"))
	draw_rect(Rect2(tl, Vector2(w, 28)), UiKit.BRASS, false, 1.0)
	draw_string(font, tl + Vector2(10, 19), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("f6efdc") if strong else UiKit.INK)
