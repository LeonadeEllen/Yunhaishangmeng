extends Control
## A walkable paper-diorama town (大航海时代2 feel): the island floats over the cloud sea, the
## flagship is moored at the pier, and the protagonist walks cobbled streets between shops,
## stalls, houses and trees. Townsfolk keep their own errands; companions ashore wander too.
##
## Every port gets its own street plan, ground colours, fields and one landmark from a fixed seed,
## so a city always looks the same when you come back. The camera follows the protagonist.
## Click the ground to walk there (A* over a 16 px grid), click a building to walk in, or use WASD.

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
const HERO_SPEED := 200.0
const ENTER_DIST := 44.0
const WORLD := Vector2(2000, 1250)
const CELL := 16
const EDGE_Y := 1000.0
const NPC_LINES := [
	"今天的云海真平静，船来得多。",
	"你是%s的人？听说你们在抢灯塔。",
	"码头那边新到了一批货，去交易所看看吧。",
	"酒馆里有人在讲远方云域的事。",
	"城主府最近在招人做事，友好度高的商会才接得到。",
	"工匠行会的图纸可不便宜，但做出来的东西值钱。",
	"在这里多做买卖，城里人就会记住你。",
	"风向要变了，老船工的膝盖从来不骗人。",
	"昨晚又有云鲸从港外游过去，好大的影子。",
]
const VENDOR_LINES := ["新到的%s，看一眼不要钱！", "%s，今早刚到的，便宜卖了！", "要%s吗？整个霞市就我家最好。"]

## Ground, stone, roof colours and the landmark of each port.
const STYLE := {
	"qianqi":   {"grass": "a3b27c", "stone": "cdbb9b", "roof": "a8463a", "mark": "pailou", "plaza": "round", "pave": "cobble", "stalls": "avenue"},
	"hongxiao": {"grass": "a9b685", "stone": "d4c1a2", "roof": "b5583c", "mark": "cloth", "plaza": "square", "pave": "flag", "stalls": "plaza"},
	"muxia":    {"grass": "abb27e", "stone": "c9b395", "roof": "8a5a3a", "mark": "nets", "plaza": "octagon", "pave": "plank", "stalls": "avenue"},
	"xiajing":  {"grass": "95ad94", "stone": "c1c4bd", "roof": "3f6f7a", "mark": "bones", "plaza": "round", "pave": "flag", "stalls": "plaza"},
	"fengyue":  {"grass": "919c7a", "stone": "a39b8f", "roof": "4a4a52", "mark": "chimney", "plaza": "square", "pave": "cobble", "stalls": "avenue"},
	"cuijing":  {"grass": "80a570", "stone": "bbb291", "roof": "2f6f6a", "mark": "bigtree", "plaza": "octagon", "pave": "flag", "stalls": "plaza"},
	"tonghe":   {"grass": "9ca77c", "stone": "bca286", "roof": "8a6a3a", "mark": "windmill", "plaza": "square", "pave": "cobble", "stalls": "plaza"},
	"chishi":   {"grass": "b2a375", "stone": "c79275", "roof": "9a3a2a", "mark": "rock", "plaza": "round", "pave": "flag", "stalls": "avenue"},
	"qinglu":   {"grass": "9ab28c", "stone": "cac2a2", "roof": "5a7a4a", "mark": "jars", "plaza": "octagon", "pave": "plank", "stalls": "avenue"},
	"jinduo":   {"grass": "aaa47c", "stone": "cfb47e", "roof": "b08a3e", "mark": "belltower", "plaza": "square", "pave": "flag", "stalls": "plaza"},
	"baisha":   {"grass": "d6d0b8", "stone": "efe9d9", "roof": "4f8a9a", "mark": "kiln", "plaza": "round", "pave": "sand", "stalls": "plaza"},
	"jiaoyan":  {"grass": "77725f", "stone": "605a54", "roof": "2a2626", "mark": "watchtower", "plaza": "square", "pave": "flag", "stalls": "avenue"},
	"wuyin":    {"grass": "90a49e", "stone": "abb2b0", "roof": "5a5a7a", "mark": "pagoda", "plaza": "octagon", "pave": "cobble", "stalls": "plaza"},
}
## What grows or dries in the fields, by the port's signature goods.
const FIELD := {"wheat": "rows_gold", "fiber": "rows_green", "fruit": "orchard", "herb": "rows_dark", "incense": "grove",
	"timber": "grove", "ore": "rocks", "copper": "rocks", "stone": "rocks", "pearl": "racks", "fish": "racks", "blubber": "racks",
	"cocoon": "orchard", "silk": "cloth", "canvas": "cloth", "glass": "jars", "brass": "jars", "steel": "rocks", "oil": "jars",
	"wine": "jars", "smoked": "racks"}

var sim: Sim
var port := ""
var hero_pos := Vector2.ZERO
var _hero_dir := 3
var _phase := 0.0
var _moving := false
var _path := PackedVector2Array()
var _auto_enter := ""
var _near := ""
var _t := 0.0
var _cam := Vector2.ZERO
var _style := {}
var _grass := Color.WHITE
var _stone := Color.WHITE
var _plaza := Vector2.ZERO
var _island := PackedVector2Array()
var _roads := []        # Rect2
var _docks := []        # Rect2
var _buildings := []
var _props := []        # tall things, depth-sorted with people
var _flats := []        # flat ground decoration drawn once
var _ships := []
var _clouds := []
var _npcs := []
var _road_pts := []
var _grid: AStarGrid2D
var _ground_layer: Node2D
var _actor_layer: Node2D
var _ui_layer: Node2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	_ground_layer = Node2D.new()
	_ground_layer.draw.connect(_draw_ground)
	add_child(_ground_layer)
	_actor_layer = Node2D.new()
	_actor_layer.draw.connect(_draw_actors)
	add_child(_actor_layer)
	_ui_layer = Node2D.new()
	_ui_layer.draw.connect(_draw_ui)
	add_child(_ui_layer)
	resized.connect(func(): _snap_camera())


## Build the street plan for a port. Called every time the player walks into town.
func open(pid: String) -> void:
	port = pid
	_t = 0.0
	_auto_enter = ""
	_path = PackedVector2Array()
	_layout()
	_snap_camera()
	_ground_layer.queue_redraw()
	queue_redraw()


# ------------------------------------------------------------------ layout
func _season() -> int:
	return (int(sim.s["day"]) % GameData.DAYS_YEAR) / 90


func _layout() -> void:
	if port == "" or sim == null:
		return
	_style = STYLE.get(port, STYLE["qianqi"])
	var season := _season()
	_grass = Color(_style["grass"])
	match season:
		0: _grass = _grass.lightened(0.06)
		1: _grass = _grass.darkened(0.04)
		2: _grass = _grass.lerp(Color("c9a25a"), 0.35)
		3: _grass = _grass.lerp(Color("eef0f2"), 0.55)
	_stone = Color(_style["stone"])
	var r := RandomNumberGenerator.new()
	r.seed = port.hash()
	var m := 1.0 if r.randf() < 0.5 else -1.0
	_plaza = Vector2(WORLD.x * 0.5 + r.randf_range(-90, 90), 560)
	var P := _plaza
	# the island outline, with a cliff along the harbour edge
	_island = PackedVector2Array()
	_island.append(Vector2(70, -80))
	_island.append(Vector2(WORLD.x - 70, -80))
	var y := 0.0
	while y < EDGE_Y - 60:
		_island.append(Vector2(WORLD.x - 60 - r.randf_range(0, 26), y))
		y += 70.0
	var x := WORLD.x - 90
	while x > 90:
		_island.append(Vector2(x, EDGE_Y + r.randf_range(-10, 10) + (12.0 if absf(x - P.x) < 70 else 0.0)))
		x -= 60.0
	y = EDGE_Y - 60
	while y > 0:
		_island.append(Vector2(60 + r.randf_range(0, 26), y))
		y -= 70.0
	# streets
	_roads = [
		Rect2(P.x - 30, P.y, 60, EDGE_Y - P.y + 10),                     # avenue from the plaza to the pier
		Rect2(200, P.y - 28, WORLD.x - 400, 56),                         # the cross street
		Rect2(P.x - 560, 278, 1120, 44),                                  # upper street
		Rect2(P.x - 22, 300, 44, P.y - 300),                              # up to the hall
		Rect2(P.x - 580, 300, 40, P.y - 300), Rect2(P.x + 540, 300, 40, P.y - 300),
		Rect2(P.x - 660, 768, 1320, 44),                                  # lower street
		Rect2(240, EDGE_Y - 74, WORLD.x - 480, 46),                       # harbour promenade
	]
	_docks = []
	for dx in [0.0, -380.0 * m, 420.0 * m]:
		var dxx: float = P.x + dx
		_docks.append(Rect2(dxx - 24, EDGE_Y - 30, 48, 170 if dx == 0.0 else 130))
	# building lots: each sits on the north side of a street, its door on the street
	var slots := []
	for sx in [-380.0, 0.0, 380.0]:
		slots.append({"x": P.x + sx * m, "base": 276.0, "row": "upper"})
	for sx in [-270.0, 270.0, -590.0, 590.0]:
		slots.append({"x": P.x + sx * m, "base": P.y - 30.0, "row": "cross"})
	for sx in [-310.0, 310.0, -640.0, 640.0]:
		slots.append({"x": P.x + sx * m, "base": 766.0, "row": "lower"})
	var home: bool = GameData.HOUSES[sim.pid()]["home"] == port
	var want := {"hall": 1, "trade": 3, "tavern": 4}
	if home:
		want["lighthouse"] = 2
	var used := {}
	_buildings.clear()
	for k in want:
		var s: Dictionary = slots[want[k]]
		used[want[k]] = true
		_buildings.append(_make_building(k, s["x"], s["base"]))
	var rest := ["guild", "post", "bank", "works"]
	var free := []
	for i in slots.size():
		if not used.has(i):
			free.append(i)
	# keep the far corners for houses and gardens: fill the inner lots first
	free.sort_custom(func(a, b): return absf(slots[a]["x"] - P.x) + (0.0 if slots[a]["row"] == "cross" else 200.0) < absf(slots[b]["x"] - P.x) + (0.0 if slots[b]["row"] == "cross" else 200.0))
	# the landmark stands right by the plaza, where you see it on arrival
	var mark_slot: int = free.pop_front()
	for k in rest:
		var i: int = free.pop_front()
		_buildings.append(_make_building(k, slots[i]["x"], slots[i]["base"]))
	# the shipyard stands on the promenade beside the main pier
	_buildings.append(_make_building("yard", P.x + 230.0 * m, EDGE_Y - 76.0))
	# decoration
	_props.clear()
	_flats.clear()
	_ships.clear()
	_props.append({"kind": "mark", "mark": _style["mark"], "p": Vector2(slots[mark_slot]["x"], slots[mark_slot]["base"] - 20)})
	for i in free:
		var s: Dictionary = slots[i]
		if r.randf() < 0.6:
			_add_house(r, Vector2(s["x"] - 55, s["base"] - 4), r.randi_range(100, 124))
			_add_house(r, Vector2(s["x"] + 62, s["base"] - 4), r.randi_range(96, 118))
		else:
			_add_field(r, Rect2(s["x"] - 110, s["base"] - 150, 220, 130))
	# outer fields and houses along the edges
	for side in [-1.0, 1.0]:
		var fx: float = P.x + side * 820.0
		if fx > 180 and fx < WORLD.x - 180:
			_add_field(r, Rect2(fx - 90, 380, 180, 150))
			_add_house(r, Vector2(fx, 700), r.randi_range(100, 120))
	# plaza furniture
	var ben := sim.benefactor(port)
	_props.append({"kind": "statue" if ben != "" else "fountain", "p": P + Vector2(0, 18), "house": ben})
	for a in 4:
		var ang := PI * 0.25 + PI * 0.5 * a
		_props.append({"kind": "lamp", "p": P + Vector2(cos(ang), sin(ang) * 0.8) * 118.0})
	for a in [0.0, PI]:
		_props.append({"kind": "bench", "p": P + Vector2(cos(a) * 80.0, 70.0)})
	# lamps along the streets
	var lx := 260.0
	while lx < WORLD.x - 260:
		if absf(lx - P.x) > 140:
			_props.append({"kind": "lamp", "p": Vector2(lx, P.y + 40)})
		lx += 230.0
	var ly := P.y + 160
	while ly < EDGE_Y - 90:
		_props.append({"kind": "lamp", "p": Vector2(P.x + 44, ly)})
		ly += 170.0
	# market stalls on the avenue, selling this port's goods
	var makes: Array = GameData.PORTS[port]["make"]
	var stalls := []
	for k in 4:
		var sp := Vector2(P.x + (-78.0 if k % 2 == 0 else 78.0), P.y + 150 + (k / 2) * 92)
		if _style.get("stalls", "avenue") == "plaza":
			sp = P + Vector2(-150.0 if k % 2 == 0 else 150.0, 108.0 + (k / 2) * 84.0)
		var g: String = makes[k % makes.size()]
		var st := {"kind": "stall", "p": sp, "good": g, "awning": [Color("b5583c"), Color("2f6f6a"), Color("b08a3e"), Color("7a5a8a")][r.randi_range(0, 3)]}
		_props.append(st)
		stalls.append(st)
	# cargo on the promenade and the piers
	for d in _docks:
		var dr: Rect2 = d
		for k in r.randi_range(2, 4):
			_props.append({"kind": "crate" if r.randf() < 0.6 else "barrel", "p": Vector2(dr.position.x + r.randf_range(-40, -14) if r.randf() < 0.5 else dr.end.x + r.randf_range(14, 40), EDGE_Y - 82 + r.randf_range(-6, 4)), "s": r.randf_range(0.8, 1.15)})
	# moored airships: the flagship at the main pier
	var fl := sim.flagship()
	var fl_type: String = fl.get("type", "freighter") if not fl.is_empty() else "freighter"
	_ships.append({"p": Vector2(_docks[0].position.x + 128, EDGE_Y + 95), "tex": UiKit.sprite("ships", GameData.SHIPS[fl_type]["sprite"]), "w": 190.0, "ph": 0.0, "flag": true})
	for i in range(1, _docks.size()):
		var t_ids := ["freighter", "galleon", "survey", "gunboat"]
		var tid: String = t_ids[r.randi_range(0, t_ids.size() - 1)]
		var side_x := -110.0 if i == 1 else 112.0
		_ships.append({"p": Vector2(_docks[i].get_center().x + side_x, EDGE_Y + 78), "tex": UiKit.sprite("ships", GameData.SHIPS[tid]["sprite"]), "w": 150.0, "ph": r.randf() * TAU})
	# trees on whatever grass is left
	var tries := 0
	var trees := 0
	while trees < 46 and tries < 900:
		tries += 1
		var tp := Vector2(r.randf_range(90, WORLD.x - 90), r.randf_range(40, EDGE_Y - 110))
		if _blocked(tp, 34.0):
			continue
		_props.append({"kind": "tree", "p": tp, "s": r.randf_range(0.8, 1.3), "k": r.randi_range(0, 2)})
		trees += 1
	# grass tufts and flowers
	for i in 420:
		var gp := Vector2(r.randf_range(80, WORLD.x - 80), r.randf_range(10, EDGE_Y - 30))
		if _on_road(gp, 6.0):
			continue
		_flats.append({"kind": "tuft" if r.randf() < 0.75 else "flower", "p": gp, "c": r.randi_range(0, 3)})
	# clouds below and beside the island
	_clouds.clear()
	for i in 26:
		_clouds.append({"p": Vector2(r.randf_range(-200, WORLD.x + 200), r.randf_range(EDGE_Y - 60, WORLD.y + 120) if i < 18 else r.randf_range(0, EDGE_Y)), "r": r.randf_range(40, 90), "v": r.randf_range(4, 12)})
	_build_grid()
	# road sample points for wandering townsfolk
	_road_pts.clear()
	for rr in _roads:
		var rect: Rect2 = rr
		for k in 6:
			var rp := rect.position + Vector2(r.randf() * rect.size.x, r.randf() * rect.size.y)
			if _walkable(rp):
				_road_pts.append(rp)
	# the protagonist steps off the flagship onto the main pier
	hero_pos = Vector2(_docks[0].get_center().x, EDGE_Y + 60)
	_hero_dir = 3
	_spawn_npcs(r, stalls)


func _make_building(kind: String, x: float, base: float) -> Dictionary:
	var info: Dictionary = KIND_INFO[kind]
	var tex: Texture2D
	if kind == "lighthouse":
		var stage: int = sim.house()["lh"]["stage"]
		var idx: int = 0 if stage == 0 else int(GameData.LIGHTHOUSE[stage - 1]["sprite"])
		tex = UiKit.sprite("lighthouse", idx)
	else:
		tex = UiKit.sprite("city_buildings", info["sprite"])
	var w := 196.0 if kind in ["hall", "trade", "lighthouse"] else 172.0
	var h := w * float(tex.get_height()) / float(tex.get_width())
	var foot := Vector2(x, base)
	return {"kind": kind, "name": info["name"], "tex": tex, "foot": foot, "size": Vector2(w, h),
		"rect": Rect2(foot - Vector2(w * 0.5, h * 0.92), Vector2(w, h)), "door": foot + Vector2(0, 14)}


func _add_house(r: RandomNumberGenerator, foot: Vector2, w: int) -> void:
	_props.append({"kind": "house", "p": foot, "w": float(w), "h": float(w) * r.randf_range(0.62, 0.78),
		"wall": Color("eee4cc").lerp(Color("d9c7a4"), r.randf()), "roof": Color(_style["roof"]).lerp(Color("4a4a52"), r.randf() * 0.3),
		"smoke": r.randf() < 0.4, "two": r.randf() < 0.35})


func _add_field(r: RandomNumberGenerator, rect: Rect2) -> void:
	var makes: Array = GameData.PORTS[port]["make"]
	var kind: String = FIELD.get(makes[r.randi_range(0, makes.size() - 1)], "rows_green")
	_flats.append({"kind": "field", "rect": rect, "f": kind, "seed": r.randi()})
	# a few tall things in the field are depth sorted with people
	match kind:
		"orchard", "grove":
			for k in 6:
				_props.append({"kind": "tree", "p": rect.position + Vector2(30 + (k % 3) * 70, 40 + (k / 3) * 60), "s": 0.75, "k": 3 if kind == "orchard" else 0})
		"cloth":
			_props.append({"kind": "cloth", "p": rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.75), "w": rect.size.x * 0.8})
		"racks":
			_props.append({"kind": "rack", "p": rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.7), "w": rect.size.x * 0.75})
		"jars":
			for k in 7:
				_props.append({"kind": "jar", "p": rect.position + Vector2(30 + (k % 4) * 50, 50 + (k / 4) * 50), "s": r.randf_range(0.8, 1.2)})
		"rocks":
			_props.append({"kind": "cart", "p": rect.position + Vector2(rect.size.x * 0.6, rect.size.y * 0.7)})


func _on_road(p: Vector2, pad: float) -> bool:
	for rr in _roads:
		if (rr as Rect2).grow(pad).has_point(p):
			return true
	return p.distance_to(_plaza) < 120.0 + pad


func _blocked(p: Vector2, pad: float) -> bool:
	if _on_road(p, pad) or not Geometry2D.is_point_in_polygon(p, _island) or p.y > EDGE_Y - 60:
		return true
	for b in _buildings:
		if (b["rect"] as Rect2).grow(pad).has_point(p):
			return true
	for f in _flats:
		if f["kind"] == "field" and (f["rect"] as Rect2).grow(pad).has_point(p):
			return true
	for pr in _props:
		var pp: Vector2 = pr["p"]
		var rad := 40.0
		match pr["kind"]:
			"house": rad = pr["w"] * 0.6
			"mark": rad = 110.0
			"lamp": rad = 12.0
		if pp.distance_to(p) < rad + pad:
			return true
	return false


# ------------------------------------------------------------------ walking grid
func _build_grid() -> void:
	_grid = AStarGrid2D.new()
	_grid.region = Rect2i(0, 0, int(WORLD.x / CELL), int(WORLD.y / CELL))
	_grid.cell_size = Vector2(CELL, CELL)
	_grid.offset = Vector2(CELL, CELL) * 0.5
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.update()
	for cx in _grid.region.size.x:
		for cy in _grid.region.size.y:
			var c := Vector2(cx, cy) * CELL + Vector2(CELL, CELL) * 0.5
			if not _cell_open(c):
				_grid.set_point_solid(Vector2i(cx, cy), true)


func _cell_open(c: Vector2) -> bool:
	var on_land := Geometry2D.is_point_in_polygon(c, _island) and c.y < EDGE_Y - 8
	var on_pier := false
	for d in _docks:
		if (d as Rect2).has_point(c):
			on_pier = true
	if not on_land and not on_pier:
		return false
	if c.y < 40:
		return false
	for b in _buildings:
		var rr: Rect2 = b["rect"]
		var foot: Vector2 = b["foot"]
		var fp := Rect2(Vector2(rr.position.x + rr.size.x * 0.12, foot.y - rr.size.y * 0.5), Vector2(rr.size.x * 0.76, rr.size.y * 0.5 - 2))
		if fp.has_point(c):
			return false
	for pr in _props:
		var pp: Vector2 = pr["p"]
		match pr["kind"]:
			"house":
				if Rect2(pp - Vector2(pr["w"] * 0.5, pr["h"] * 0.55), Vector2(pr["w"], pr["h"] * 0.55)).has_point(c):
					return false
			"tree":
				if c.distance_to(pp) < 10.0 * float(pr["s"]):
					return false
			"stall":
				if Rect2(pp - Vector2(30, 18), Vector2(60, 20)).has_point(c):
					return false
			"mark":
				if Rect2(pp - Vector2(70, 70), Vector2(140, 74)).has_point(c):
					return false
			"fountain", "statue":
				if c.distance_to(pp) < 32.0:
					return false
			"crate", "barrel", "jar", "cart":
				if c.distance_to(pp) < 10.0:
					return false
	return true


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(clampi(int(p.x / CELL), 0, _grid.region.size.x - 1), clampi(int(p.y / CELL), 0, _grid.region.size.y - 1))


func _walkable(p: Vector2) -> bool:
	if p.x < 0 or p.y < 0 or p.x >= WORLD.x or p.y >= WORLD.y:
		return false
	return not _grid.is_point_solid(_cell(p))


func _nearest_open(p: Vector2) -> Vector2i:
	var c := _cell(p)
	if not _grid.is_point_solid(c):
		return c
	for rad in range(1, 12):
		for dx in range(-rad, rad + 1):
			for dy in range(-rad, rad + 1):
				if absi(dx) != rad and absi(dy) != rad:
					continue
				var q := c + Vector2i(dx, dy)
				if _grid.is_in_boundsv(q) and not _grid.is_point_solid(q):
					return q
	return c


func _find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var a := _nearest_open(from)
	var b := _nearest_open(to)
	var path := _grid.get_point_path(a, b, true)
	if path.size() > 0 and _walkable(to):
		path[path.size() - 1] = to
	return path


# ------------------------------------------------------------------ people
func _spawn_npcs(r: RandomNumberGenerator, stalls: Array) -> void:
	_npcs.clear()
	var lines := NPC_LINES.duplicate()
	lines.shuffle()
	var seed0 := port.hash() + int(sim.s["day"]) / 30
	# stall keepers
	for i in stalls.size():
		var st: Dictionary = stalls[i]
		var pitch: String = VENDOR_LINES[i % VENDOR_LINES.size()] % GameData.good_name(st["good"])
		_npcs.append({"p": st["p"] + Vector2(0, -20), "look": PaperFolk.random_look(seed0 + i * 13, "vendor"), "job": "vendor", "dir": 0, "line": pitch})
	# guards at the hall
	for b in _buildings:
		if b["kind"] == "hall":
			for side in [-1.0, 1.0]:
				_npcs.append({"p": b["door"] + Vector2(side * 56, -4), "look": PaperFolk.random_look(seed0 + 900 + int(side), "guard"), "job": "guard", "dir": 0})
	# porters between the pier and the exchange
	var trade_door := Vector2.ZERO
	for b in _buildings:
		if b["kind"] == "trade":
			trade_door = b["door"]
	for i in 2:
		var lk := PaperFolk.random_look(seed0 + 300 + i, "porter")
		var empty := lk.duplicate()
		empty.erase("prop")
		_npcs.append({"p": Vector2(_docks[0].get_center().x + (i * 2 - 1) * 10, EDGE_Y + 20 + i * 30), "look": lk, "look2": empty, "job": "porter",
			"a": Vector2(_docks[0].get_center().x, EDGE_Y + 40), "b": trade_door, "leg": i, "wait": r.randf_range(0.0, 3.0), "speed": 62.0})
	# sailors on the piers
	for i in 2:
		var d: Rect2 = _docks[1 + i % 2]
		_npcs.append({"p": d.get_center(), "look": PaperFolk.random_look(seed0 + 500 + i, "sailor"), "job": "sailor", "box": d.grow_individual(0, 40, 0, -16), "wait": r.randf_range(0.0, 2.0), "speed": 48.0})
	# townsfolk and children
	for i in 7:
		var lk2 := PaperFolk.random_look(seed0 + 40 + i * 7, "kid" if i >= 5 else "")
		var line: String = _rumour(r) if i == 0 else (lines[i] if i < 4 else "")
		_npcs.append({"p": _road_pts[r.randi_range(0, _road_pts.size() - 1)], "look": lk2, "job": "kid" if i >= 5 else "walker", "line": line,
			"wait": r.randf_range(0.0, 2.0), "speed": 92.0 if i >= 5 else r.randf_range(48, 66)})
	# a few of your companions have come ashore too (round 13)
	var crew_ids: Array = sim.crew().keys()
	var cr := RandomNumberGenerator.new()
	cr.seed = int(sim.s["day"]) * 31 + port.hash()
	for i in mini(3, crew_ids.size()):
		var cid: String = crew_ids[cr.randi_range(0, crew_ids.size() - 1)]
		crew_ids.erase(cid)
		var banter: Array = Characters.BANTER.get(cid, ["……"])
		_npcs.append({"p": _road_pts[cr.randi_range(0, _road_pts.size() - 1)], "look": PaperFolk.crew_look(cid), "job": "walker", "cid": cid,
			"line": banter[cr.randi_range(0, banter.size() - 1)], "wait": cr.randf_range(0.0, 3.0), "speed": 52.0})
	for n in _npcs:
		n["path"] = PackedVector2Array()
		n["phase"] = r.randf() * TAU
		if not n.has("dir"):
			n["dir"] = r.randi_range(0, 3)


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
	if best == "":
		return NPC_LINES[0]
	return "听说%s的%s卖到 %d 金一件。" % [GameData.port_name(best), GameData.good_name(g), best_p]


func _tick_npc(n: Dictionary, delta: float) -> void:
	var job: String = n["job"]
	if job in ["vendor", "guard"]:
		# face the protagonist when they come close
		var d: Vector2 = hero_pos - n["p"]
		n["dir"] = _dir_of(d) if d.length() < 90.0 else 0
		return
	var path: PackedVector2Array = n["path"]
	if path.is_empty():
		n["wait"] = float(n["wait"]) - delta
		n["moving"] = false
		if n["wait"] > 0.0:
			return
		var goal: Vector2
		match job:
			"porter":
				n["leg"] = 1 - int(n["leg"])
				goal = n["b"] if int(n["leg"]) == 1 else n["a"]
			"sailor":
				var box: Rect2 = n["box"]
				goal = box.position + Vector2(randf() * box.size.x, randf() * box.size.y)
			"kid":
				goal = _plaza + Vector2.from_angle(randf() * TAU) * randf_range(60, 180)
			_:
				goal = _road_pts[randi() % _road_pts.size()]
		n["path"] = _find_path(n["p"], goal)
		n["wait"] = randf_range(0.5, 1.5) if job == "porter" else randf_range(1.5, 4.5)
		return
	var target: Vector2 = path[0]
	var step: Vector2 = target - n["p"]
	var mv: float = float(n["speed"]) * delta
	if step.length() <= mv:
		n["p"] = target
		path.remove_at(0)
		n["path"] = path
	else:
		n["p"] = n["p"] + step.normalized() * mv
		n["dir"] = _dir_of(step)
	n["moving"] = true
	n["phase"] = float(n["phase"]) + delta * float(n["speed"]) * 0.16


func _dir_of(v: Vector2) -> int:
	if absf(v.x) > absf(v.y):
		return 1 if v.x < 0 else 2
	return 0 if v.y > 0 else 3


# ------------------------------------------------------------------ frame
func _process(delta: float) -> void:
	if not visible or port == "" or _grid == null:
		return
	_t += delta
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
		_path = PackedVector2Array()
		_auto_enter = ""
		v = v.normalized()
		var np := hero_pos + v * HERO_SPEED * delta
		if _walkable(np):
			hero_pos = np
		elif _walkable(Vector2(np.x, hero_pos.y)):
			hero_pos.x = np.x
		elif _walkable(Vector2(hero_pos.x, np.y)):
			hero_pos.y = np.y
		_hero_dir = _dir_of(v)
		_moving = true
	elif not _path.is_empty():
		var target: Vector2 = _path[0]
		var step := target - hero_pos
		var mv := HERO_SPEED * delta
		if step.length() <= mv:
			hero_pos = target
			_path.remove_at(0)
			if _path.is_empty() and _auto_enter != "":
				var k := _auto_enter
				_auto_enter = ""
				_enter(k)
		else:
			hero_pos += step.normalized() * mv
			_hero_dir = _dir_of(step)
		_moving = true
	else:
		_moving = false
	if _moving:
		_phase += delta * 11.0
	# which door is close
	_near = ""
	var nd := ENTER_DIST
	for b in _buildings:
		var d := hero_pos.distance_to(b["door"])
		if d < nd:
			nd = d
			_near = b["kind"]
	for n in _npcs:
		_tick_npc(n, delta)
	# camera follows the protagonist
	var want := _cam_target()
	_cam = _cam.lerp(want, minf(1.0, delta * 5.0))
	_ground_layer.position = -_cam.round()
	_actor_layer.position = -_cam.round()
	_actor_layer.queue_redraw()
	_ui_layer.queue_redraw()
	queue_redraw()


func _cam_target() -> Vector2:
	var t := hero_pos - size * 0.5 + Vector2(0, -40)
	var c := Vector2.ZERO
	c.x = clampf(t.x, 0.0, maxf(0.0, WORLD.x - size.x)) if size.x < WORLD.x else (WORLD.x - size.x) * 0.5
	c.y = clampf(t.y, -60.0, maxf(0.0, WORLD.y - size.y)) if size.y < WORLD.y else (WORLD.y - size.y) * 0.5
	return c


func _snap_camera() -> void:
	if _ground_layer == null:
		return
	_cam = _cam_target()
	_ground_layer.position = -_cam.round()
	_actor_layer.position = -_cam.round()


func _building_at(p: Vector2) -> Dictionary:
	for b in _buildings:
		if (b["rect"] as Rect2).has_point(p):
			return b
	return {}


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _grid != null:
		var wp: Vector2 = event.position + _cam
		var b := _building_at(wp)
		if not b.is_empty():
			if hero_pos.distance_to(b["door"]) < ENTER_DIST:
				_enter(b["kind"])
			else:
				_path = _find_path(hero_pos, b["door"])
				_auto_enter = b["kind"]
		else:
			_path = _find_path(hero_pos, wp)
			_auto_enter = ""
		accept_event()


## Enter the building the protagonist stands in front of (E key).
func try_enter() -> void:
	if _near != "":
		_enter(_near)


func _enter(kind: String) -> void:
	_moving = false
	_path = PackedVector2Array()
	building_entered.emit(kind)


## The portrait behind each counter; "" for your own premises (you see yourself).
func npc_portrait(kind: String) -> String:
	return {"trade": "shop_trade", "yard": "shop_yard", "hall": "shop_hall", "guild": "shop_guild", "tavern": "shop_tavern",
		"bank": "shop_bank", "lighthouse": "shop_yard"}.get(kind, "")


func npc_title(kind: String) -> String:
	return str(KIND_INFO.get(kind, {}).get("who", ""))


func kind_name(kind: String) -> String:
	return str(KIND_INFO.get(kind, {}).get("name", ""))


func tab_of(kind: String) -> int:
	return int(KIND_INFO.get(kind, {}).get("tab", 0))


# ------------------------------------------------------------------ drawing: the sky below
func _draw() -> void:
	if port == "":
		return
	# the cloud sea seen past the island's edge, with slow parallax
	var top := Color("dfe9ec")
	var bot := Color("b9cdd6") if _season() != 3 else Color("cfdbe2")
	var steps := 12
	for i in steps:
		var y0 := size.y * float(i) / steps
		draw_rect(Rect2(0, y0, size.x, size.y / steps + 1), top.lerp(bot, float(i) / steps))
	for c in _clouds:
		var cp: Vector2 = c["p"] - _cam * 0.75 + Vector2(fmod(_t * float(c["v"]), WORLD.x + 400.0), 0)
		cp.x = fposmod(cp.x + 200.0, WORLD.x + 400.0) - 200.0
		_puff(self, cp, float(c["r"]), 0.9)


func _puff(ci: CanvasItem, c: Vector2, r: float, a: float) -> void:
	var lobes := [Vector2(-0.9, 0.1), Vector2(-0.35, -0.3), Vector2(0.3, -0.4), Vector2(0.95, 0.05), Vector2(0.0, 0.15)]
	var radii := [0.55, 0.7, 0.75, 0.5, 0.8]
	for i in lobes.size():
		ci.draw_circle(c + lobes[i] * r + Vector2(0, r * 0.12), radii[i] * r, Color(0.62, 0.72, 0.78, a * 0.35))
	for i in lobes.size():
		ci.draw_circle(c + lobes[i] * r, radii[i] * r, Color(1, 1, 1, a))


# ------------------------------------------------------------------ drawing: ground (once per visit)
func _draw_ground() -> void:
	if port == "" or _island.is_empty():
		return
	var ci := _ground_layer
	var r := RandomNumberGenerator.new()
	r.seed = port.hash() + 7
	# cliff under the harbour edge
	var cliff := PackedVector2Array()
	var edge := []
	for p in _island:
		if p.y > EDGE_Y - 20:
			edge.append(p)
	edge.sort_custom(func(a, b): return a.x < b.x)
	if edge.size() > 1:
		for p in edge:
			cliff.append(p)
		for i in range(edge.size() - 1, -1, -1):
			var p: Vector2 = edge[i]
			cliff.append(p + Vector2(0, 70 + 26 * sin(p.x * 0.013) + r.randf_range(0, 18)))
		var rock := Color("8d7b68") if port != "baisha" else Color("cbbfa6")
		if port == "chishi":
			rock = Color("9a5a44")
		elif port == "jiaoyan":
			rock = Color("3e3a38")
		ci.draw_colored_polygon(cliff, rock)
		for k in 4:
			var strata := PackedVector2Array()
			for p in edge:
				strata.append(p + Vector2(0, 16 + k * 14 + 4 * sin(p.x * 0.02 + k)))
			ci.draw_polyline(strata, rock.darkened(0.18 + k * 0.04), 2.0)
		# hanging roots and rocks
		for k in 14:
			var hx: float = r.randf_range(edge[0].x + 30, edge[edge.size() - 1].x - 30)
			var hy := EDGE_Y + 60 + r.randf_range(0, 30)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(hx - 14, hy - 10), Vector2(hx + 14, hy - 10), Vector2(hx + r.randf_range(-4, 4), hy + r.randf_range(24, 50))]), rock.darkened(0.12))
	# grass with soft mottling
	ci.draw_colored_polygon(_island, _grass)
	for k in 70:
		var mp := Vector2(r.randf_range(80, WORLD.x - 80), r.randf_range(0, EDGE_Y - 40))
		if Geometry2D.is_point_in_polygon(mp, _island):
			ci.draw_colored_polygon(PaperFolk._ell(mp, r.randf_range(40, 120), r.randf_range(20, 50), 18), Color(_grass.lightened(0.12) if k % 2 == 0 else _grass.darkened(0.08), 0.35))
	# a lighter rim along the island's edge
	var rim := _island.duplicate()
	rim.append(_island[0])
	ci.draw_polyline(rim, _grass.lightened(0.25), 3.0, true)
	# fields
	for f in _flats:
		if f["kind"] == "field":
			_draw_field(ci, f)
	# streets and plaza
	for rr in _roads:
		_draw_road(ci, rr, r)
	_draw_plaza(ci, r)
	# piers
	for d in _docks:
		_draw_pier(ci, d)
	# tufts and flowers
	for f in _flats:
		if f["kind"] == "tuft":
			var p: Vector2 = f["p"]
			var gc := _grass.darkened(0.25)
			ci.draw_line(p, p + Vector2(-3, -6), gc, 1.2)
			ci.draw_line(p, p + Vector2(0, -8), gc, 1.2)
			ci.draw_line(p, p + Vector2(3, -6), gc, 1.2)
		elif f["kind"] == "flower":
			var fc: Color = [Color("e8a0a0"), Color("f2e6a0"), Color("ffffff"), Color("c9a0e0")][int(f["c"])]
			if _season() == 3:
				continue
			ci.draw_circle(f["p"], 2.4, fc)
			ci.draw_circle(f["p"] + Vector2(4, 2), 2.0, fc)
	# winter: snow drifts
	if _season() == 3:
		for k in 40:
			var sp := Vector2(r.randf_range(80, WORLD.x - 80), r.randf_range(0, EDGE_Y - 40))
			if Geometry2D.is_point_in_polygon(sp, _island) and not _on_road(sp, 0):
				ci.draw_colored_polygon(PaperFolk._ell(sp, r.randf_range(20, 50), r.randf_range(6, 12), 14), Color(1, 1, 1, 0.6))


func _draw_road(ci: CanvasItem, rect: Rect2, r: RandomNumberGenerator) -> void:
	var edge_c := _stone.darkened(0.25)
	ci.draw_rect(rect.grow(3), Color(edge_c, 0.7))
	ci.draw_rect(rect, _stone)
	match _style.get("pave", "cobble"):
		"flag":
			# big square flagstones
			var fy := rect.position.y + 2
			var row2 := 0
			while fy < rect.end.y - 3:
				var fx := rect.position.x + 2 + (12.0 if row2 % 2 == 1 else 0.0)
				while fx < rect.end.x - 4:
					var fw := minf(24.0, rect.end.x - 2 - fx)
					var fh := minf(20.0, rect.end.y - 2 - fy)
					ci.draw_rect(Rect2(fx, fy, fw - 2, fh - 2), _stone.lerp(_stone.darkened(0.1) if r.randf() < 0.5 else _stone.lightened(0.08), r.randf()))
					fx += 24.0
				fy += 20.0
				row2 += 1
			return
		"plank":
			var wood := _stone.lerp(Color("a7834f"), 0.6)
			ci.draw_rect(rect, wood)
			var horiz := rect.size.x > rect.size.y
			var k := 0.0
			var span := rect.size.y if horiz else rect.size.x
			while k < (rect.size.x if horiz else rect.size.y):
				if horiz:
					ci.draw_line(rect.position + Vector2(k, 0), rect.position + Vector2(k, span), wood.darkened(0.22), 1.2)
				else:
					ci.draw_line(rect.position + Vector2(0, k), rect.position + Vector2(span, k), wood.darkened(0.22), 1.2)
				k += 9.0
			return
		"sand":
			for i in int(rect.size.x * rect.size.y / 260.0):
				ci.draw_circle(rect.position + Vector2(r.randf() * rect.size.x, r.randf() * rect.size.y), 1.2, _stone.darkened(0.12))
			return
	# cobbles in staggered rows
	var row := 0
	var y := rect.position.y + 3
	while y < rect.end.y - 4:
		var x := rect.position.x + 3 + (7.0 if row % 2 == 1 else 0.0)
		while x < rect.end.x - 6:
			var w := r.randf_range(10, 15)
			var cw := minf(w, rect.end.x - 3 - x)
			if cw > 4:
				var cc := _stone.lerp(_stone.darkened(0.12) if r.randf() < 0.5 else _stone.lightened(0.1), r.randf())
				ci.draw_rect(Rect2(x, y, cw - 2, 8), cc)
				ci.draw_line(Vector2(x, y + 8), Vector2(x + cw - 2, y + 8), Color(edge_c, 0.35), 1.0)
			x += w
		y += 10
		row += 1


func _draw_plaza(ci: CanvasItem, r: RandomNumberGenerator) -> void:
	var P := _plaza
	var shape: String = _style.get("plaza", "round")
	if shape != "round":
		var n := 4 if shape == "square" else 8
		var outer := PackedVector2Array()
		var inner := PackedVector2Array()
		for k in n:
			var a := TAU * float(k) / n + (PI / n)
			outer.append(P + Vector2(cos(a) * 150.0, sin(a) * 122.0))
			inner.append(P + Vector2(cos(a) * 144.0, sin(a) * 116.0))
		ci.draw_colored_polygon(outer, _stone.darkened(0.25))
		ci.draw_colored_polygon(inner, _stone)
		var gy := P.y - 100.0
		while gy < P.y + 100.0:
			var gx := P.x - 120.0
			while gx < P.x + 120.0:
				var q := Vector2(gx, gy)
				if Geometry2D.is_point_in_polygon(q + Vector2(9, 9), inner):
					ci.draw_rect(Rect2(q, Vector2(17, 17)), _stone.lerp(_stone.darkened(0.12), r.randf() * 0.7))
				gx += 19.0
			gy += 19.0
		var ring := inner.duplicate()
		ring.append(inner[0])
		ci.draw_polyline(ring, Color(UiKit.BRASS, 0.55), 2.0, true)
		return
	ci.draw_colored_polygon(PaperFolk._ell(P, 126, 104, 40), _stone.darkened(0.25))
	ci.draw_colored_polygon(PaperFolk._ell(P, 122, 100, 40), _stone)
	for ring in [96.0, 72.0, 48.0]:
		var pts := PaperFolk._ell(P, ring * 1.2, ring, 40)
		pts.append(pts[0])
		ci.draw_polyline(pts, _stone.darkened(0.15), 1.4, true)
	for k in 24:
		var a := TAU * k / 24.0
		ci.draw_line(P + Vector2(cos(a) * 58, sin(a) * 48), P + Vector2(cos(a) * 144, sin(a) * 120) * 0.8, Color(_stone.darkened(0.12), 0.6), 1.0)


func _draw_pier(ci: CanvasItem, d: Rect2) -> void:
	var wood := Color("a7834f")
	ci.draw_rect(Rect2(d.position + Vector2(3, 5), d.size), Color(0, 0, 0, 0.18))
	ci.draw_rect(d, wood)
	var y := d.position.y
	while y < d.end.y:
		ci.draw_line(Vector2(d.position.x, y), Vector2(d.end.x, y), wood.darkened(0.25), 1.2)
		y += 9
	ci.draw_line(Vector2(d.get_center().x, d.position.y), Vector2(d.get_center().x, d.end.y), wood.darkened(0.15), 1.0)
	for k in int(d.size.y / 40.0) + 1:
		var py := d.position.y + 20 + k * 40
		if py > d.end.y:
			break
		for sx in [d.position.x - 2, d.end.x + 2]:
			ci.draw_rect(Rect2(sx - 3, py - 4, 6, 10), wood.darkened(0.35))
	ci.draw_line(Vector2(d.position.x - 2, d.position.y + 20), Vector2(d.position.x - 2, d.end.y), Color("6a4a2a"), 1.4)
	ci.draw_line(Vector2(d.end.x + 2, d.position.y + 20), Vector2(d.end.x + 2, d.end.y), Color("6a4a2a"), 1.4)


func _draw_field(ci: CanvasItem, f: Dictionary) -> void:
	var rect: Rect2 = f["rect"]
	var r := RandomNumberGenerator.new()
	r.seed = int(f["seed"])
	var soil := Color("8a6a48")
	match f["f"]:
		"rows_gold", "rows_green", "rows_dark":
			ci.draw_rect(rect, soil.lightened(0.1))
			var crop := Color("d8b45a") if f["f"] == "rows_gold" else (Color("6f9a5a") if f["f"] == "rows_green" else Color("4f7a4a"))
			if _season() == 3:
				crop = Color("d8d0c0")
			var y := rect.position.y + 10
			while y < rect.end.y - 6:
				ci.draw_line(Vector2(rect.position.x + 6, y), Vector2(rect.end.x - 6, y), crop.darkened(0.2), 7.0)
				var x := rect.position.x + 8
				while x < rect.end.x - 8:
					ci.draw_line(Vector2(x, y + 2), Vector2(x + r.randf_range(-2, 2), y - 7), crop, 2.0)
					x += 6
				y += 16
		"orchard", "grove":
			ci.draw_rect(rect, _grass.darkened(0.08))
		"rocks":
			ci.draw_rect(rect, Color("9a8a78"))
			for k in 12:
				var rp := rect.position + Vector2(r.randf() * rect.size.x, r.randf() * rect.size.y)
				PaperFolk._paper(ci, PaperFolk._ell(rp, r.randf_range(8, 18), r.randf_range(5, 10), 8), Color("7a6a5a").lerp(Color("a07a5a"), r.randf()))
		"cloth", "racks", "jars":
			ci.draw_rect(rect, _stone.darkened(0.05))
	# fence
	var fence := Color("8a6a40")
	var pts := PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y), rect.position])
	ci.draw_polyline(pts, fence, 2.0)
	var x2 := rect.position.x
	while x2 <= rect.end.x:
		ci.draw_rect(Rect2(x2 - 1.5, rect.end.y - 8, 3, 9), fence.darkened(0.2))
		ci.draw_rect(Rect2(x2 - 1.5, rect.position.y - 8, 3, 9), fence.darkened(0.2))
		x2 += 22


# ------------------------------------------------------------------ drawing: actors (every frame)
func _draw_actors() -> void:
	if port == "":
		return
	var ci := _actor_layer
	var view := Rect2(_cam - Vector2(200, 200), size + Vector2(400, 400))
	var night := _night()
	# moored ships first: they hang below the island
	for sh in _ships:
		var tex: Texture2D = sh["tex"]
		var w: float = sh["w"]
		var h := w * float(tex.get_height()) / float(tex.get_width())
		var bob := sin(_t * 1.3 + float(sh["ph"])) * 3.0
		var p: Vector2 = sh["p"] + Vector2(0, bob)
		ci.draw_colored_polygon(PaperFolk._ell(p + Vector2(0, h * 0.62), w * 0.34, 8, 18), Color(0.2, 0.3, 0.35, 0.12))
		ci.draw_texture_rect(tex, Rect2(p - Vector2(w, h) * 0.5, Vector2(w, h)), false)
		# mooring line to the pier
		ci.draw_line(p + Vector2(-w * 0.32, -h * 0.05), p + Vector2(-w * 0.62, -h * 0.4), Color("6a4a2a"), 1.2)
		if sh.get("flag", false):
			var fc: Color = GameData.HOUSES[sim.pid()]["color"]
			var fp := p + Vector2(w * 0.05, -h * 0.55)
			ci.draw_line(fp, fp + Vector2(0, -22), Color("4a3a2a"), 1.5)
			ci.draw_colored_polygon(PackedVector2Array([fp + Vector2(0, -22), fp + Vector2(18 + sin(_t * 4.0) * 2, -18), fp + Vector2(0, -13)]), fc)
	var items := []
	for b in _buildings:
		if view.intersects(b["rect"]):
			items.append({"y": b["foot"].y, "b": b})
	for pr in _props:
		if view.has_point(pr["p"]):
			items.append({"y": pr["p"].y, "pr": pr})
	for n in _npcs:
		if view.has_point(n["p"]):
			items.append({"y": n["p"].y, "n": n})
	items.append({"y": hero_pos.y, "hero": true})
	items.sort_custom(func(a, c): return a["y"] < c["y"])
	for it in items:
		if it.has("b"):
			_draw_building(ci, it["b"])
		elif it.has("pr"):
			_draw_prop(ci, it["pr"], night)
		elif it.has("n"):
			var n: Dictionary = it["n"]
			var lk: Dictionary = n["look"]
			if n["job"] == "porter" and int(n.get("leg", 0)) == 0:
				lk = n["look2"]
			PaperFolk.draw(ci, n["p"], lk, int(n["dir"]), float(n["phase"]), n.get("moving", false), _t + float(n["phase"]))
		else:
			PaperFolk.draw(ci, hero_pos, PaperFolk.hero_look(sim.pid()), _hero_dir, _phase, _moving, _t, 1.1)
	# smoke from chimneys and the workshops
	for b in _buildings:
		if b["kind"] in ["works", "yard"]:
			_smoke(ci, b["rect"].position + Vector2(b["rect"].size.x * 0.7, b["rect"].size.y * 0.15), 1.0)
	for pr in _props:
		if (pr["kind"] == "house" and pr["smoke"]) and view.has_point(pr["p"]):
			_smoke(ci, pr["p"] + Vector2(pr["w"] * 0.28, -pr["h"] - 18), 0.7)
		elif pr["kind"] == "mark" and pr["mark"] in ["chimney", "kiln"]:
			_smoke(ci, pr["p"] + Vector2(-30, -150), 1.4)
			_smoke(ci, pr["p"] + Vector2(34, -120), 1.1)


func _smoke(ci: CanvasItem, base: Vector2, s: float) -> void:
	for k in 6:
		var age := fmod(_t * 0.35 + float(k) / 6.0 + base.x * 0.001, 1.0)
		var p := base + Vector2(age * 26.0 + sin(_t + k) * 3.0, -age * 70.0) * s
		ci.draw_circle(p, (5.0 + age * 12.0) * s, Color(0.55, 0.55, 0.55, (1.0 - age) * 0.3))


func _draw_building(ci: CanvasItem, b: Dictionary) -> void:
	var rr: Rect2 = b["rect"]
	var foot: Vector2 = b["foot"]
	ci.draw_colored_polygon(PaperFolk._ell(foot + Vector2(6, -6), rr.size.x * 0.44, 14, 24), Color(0, 0, 0, 0.16))
	# the protagonist walking behind a building sees through it
	var a := 1.0
	if hero_pos.y < foot.y - 12 and rr.grow(-10).has_point(hero_pos + Vector2(0, -24)):
		a = 0.5
	ci.draw_texture_rect(b["tex"], rr, false, Color(1, 1, 1, a))
	# doorstep and mat
	var door: Vector2 = b["door"]
	ci.draw_rect(Rect2(door + Vector2(-22, -14), Vector2(44, 8)), Color("8a7a66"))
	ci.draw_rect(Rect2(door + Vector2(-16, -12), Vector2(32, 5)), Color(GameData.HOUSES[sim.pid()]["color"] if b["kind"] == "post" else Color("9a4a3a"), 0.85))


func _draw_prop(ci: CanvasItem, pr: Dictionary, night: float) -> void:
	var p: Vector2 = pr["p"]
	match pr["kind"]:
		"tree":
			_draw_tree(ci, p, float(pr["s"]), int(pr["k"]))
		"lamp":
			ci.draw_colored_polygon(PaperFolk._ell(p, 6, 2.5, 10), Color(0, 0, 0, 0.18))
			ci.draw_line(p, p + Vector2(0, -46), Color("3a3028"), 2.6)
			ci.draw_line(p + Vector2(0, -44), p + Vector2(9, -44), Color("3a3028"), 2.0)
			ci.draw_line(p + Vector2(9, -44), p + Vector2(9, -40), Color("3a3028"), 1.2)
			var lc := Color("c9402e").lerp(Color("ffcf70"), night * 1.5)
			PaperFolk._paper(ci, PaperFolk._ell(p + Vector2(9, -33), 6.5, 7.5, 14), lc)
			ci.draw_line(p + Vector2(4, -33), p + Vector2(14, -33), lc.darkened(0.25), 1.0)
			ci.draw_rect(Rect2(p + Vector2(6, -41.5), Vector2(6, 2)), Color("d9b45a"))
			ci.draw_rect(Rect2(p + Vector2(6, -26.5), Vector2(6, 2)), Color("d9b45a"))
			ci.draw_line(p + Vector2(9, -25), p + Vector2(9 + sin(_t * 2.0 + p.x) * 1.5, -19), Color("c9402e"), 1.2)
		"bench":
			ci.draw_rect(Rect2(p + Vector2(-20, -10), Vector2(40, 6)), Color("8a6440"))
			ci.draw_rect(Rect2(p + Vector2(-18, -4), Vector2(4, 6)), Color("5a4028"))
			ci.draw_rect(Rect2(p + Vector2(14, -4), Vector2(4, 6)), Color("5a4028"))
		"stall":
			_draw_stall(ci, pr)
		"crate":
			var s: float = pr["s"]
			PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-11, 0) * s, p + Vector2(11, 0) * s, p + Vector2(11, -18) * s, p + Vector2(-11, -18) * s]), Color("b0834e"))
			ci.draw_line(p + Vector2(-11, -18) * s, p + Vector2(11, 0) * s, Color("7a5530"), 1.4)
			ci.draw_line(p + Vector2(-11, 0) * s, p + Vector2(11, -18) * s, Color("7a5530"), 1.4)
		"barrel":
			var s2: float = pr["s"]
			PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-9, 0) * s2, p + Vector2(9, 0) * s2, p + Vector2(10, -10) * s2, p + Vector2(9, -20) * s2, p + Vector2(-9, -20) * s2, p + Vector2(-10, -10) * s2]), Color("8a5a36"))
			ci.draw_line(p + Vector2(-10, -6) * s2, p + Vector2(10, -6) * s2, Color("4a4040"), 1.6)
			ci.draw_line(p + Vector2(-10, -15) * s2, p + Vector2(10, -15) * s2, Color("4a4040"), 1.6)
		"jar":
			var s3: float = pr["s"]
			PaperFolk._paper(ci, PaperFolk._ell(p + Vector2(0, -10) * s3, 10 * s3, 11 * s3, 14), Color("8a4a2e"))
			ci.draw_rect(Rect2(p + Vector2(-5, -24) * s3, Vector2(10, 4) * s3), Color("e0d0a0"))
		"cart":
			PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-22, -10), p + Vector2(22, -10), p + Vector2(18, -26), p + Vector2(-18, -26)]), Color("6a5040"))
			for k in 5:
				ci.draw_circle(p + Vector2(-12 + k * 6, -28), 5.0, Color("6a6060").lerp(Color("a07a5a"), float(k % 2)))
			ci.draw_circle(p + Vector2(-14, -6), 6, Color("3a3028"))
			ci.draw_circle(p + Vector2(14, -6), 6, Color("3a3028"))
		"house":
			_draw_house(ci, pr, night)
		"cloth":
			var w: float = pr["w"]
			ci.draw_line(p + Vector2(-w * 0.5, -50), p + Vector2(w * 0.5, -50), Color("5a4030"), 1.4)
			for sx in [-w * 0.5, w * 0.5]:
				ci.draw_line(p + Vector2(sx, 0), p + Vector2(sx, -54), Color("6a4a30"), 3.0)
			var cols := [Color("b5583c"), Color("2f6f6a"), Color("e8d8b0"), Color("7a5a8a"), Color("d9b45a")]
			for k in 5:
				var cx := p.x - w * 0.42 + k * w * 0.21
				var sway := sin(_t * 2.0 + k) * 3.0
				PaperFolk._paper(ci, PackedVector2Array([Vector2(cx - 12, p.y - 50), Vector2(cx + 12, p.y - 50), Vector2(cx + 12 + sway, p.y - 18), Vector2(cx - 12 + sway, p.y - 18)]), cols[k], false)
		"rack":
			var w2: float = pr["w"]
			for sx in [-w2 * 0.5, w2 * 0.5]:
				ci.draw_line(p + Vector2(sx, 0), p + Vector2(sx, -40), Color("6a4a30"), 3.0)
			ci.draw_line(p + Vector2(-w2 * 0.5, -38), p + Vector2(w2 * 0.5, -38), Color("6a4a30"), 2.0)
			for k in 7:
				var fx := p.x - w2 * 0.42 + k * w2 * 0.14
				PaperFolk._paper(ci, PaperFolk._ell(Vector2(fx, p.y - 26 + sin(_t + k) * 1.5), 4, 10, 10), Color("9ab0b8") if port != "xiajing" else Color("e0d8c0"), false)
		"fountain":
			PaperFolk._paper(ci, PaperFolk._ell(p, 34, 16, 24), _stone.darkened(0.2))
			ci.draw_colored_polygon(PaperFolk._ell(p + Vector2(0, -2), 28, 12, 24), Color("8fb7c4"))
			ci.draw_rect(Rect2(p + Vector2(-4, -30), Vector2(8, 28)), _stone.darkened(0.1))
			for k in 6:
				var a := float(k) / 6.0 * TAU + _t
				ci.draw_circle(p + Vector2(cos(a) * 10, -30 + absf(sin(_t * 3.0 + k)) * 12), 2.0, Color(1, 1, 1, 0.7))
		"statue":
			_draw_statue(ci, pr)
		"mark":
			_draw_landmark(ci, p, pr["mark"], night)


func _draw_tree(ci: CanvasItem, p: Vector2, s: float, k: int) -> void:
	var season := _season()
	ci.draw_colored_polygon(PaperFolk._ell(p + Vector2(4, 0), 18 * s, 6 * s, 14), Color(0, 0, 0, 0.16))
	ci.draw_rect(Rect2(p + Vector2(-3.5, -26) * s, Vector2(7, 26) * s), Color("6a4a30"))
	var leaf: Color = [Color("5f8a52"), Color("6f9450"), Color("4f7a5a"), Color("7a9a4a")][k % 4]
	match season:
		0: leaf = leaf.lightened(0.12)
		2: leaf = leaf.lerp([Color("d9822e"), Color("c9a23a"), Color("b5583c")][k % 3], 0.65)
		3: leaf = leaf.lerp(Color("8a9a92"), 0.5)
	var blobs := [Vector2(0, -44), Vector2(-14, -34), Vector2(14, -34), Vector2(0, -28)]
	var rad := [20.0, 15.0, 15.0, 16.0]
	for i in blobs.size():
		PaperFolk._paper(ci, PaperFolk._ell(p + blobs[i] * s, rad[i] * s, rad[i] * 0.85 * s, 16), leaf.darkened(0.06 * i), i == 0)
	ci.draw_circle(p + Vector2(-6, -50) * s, 6 * s, Color(1, 1, 1, 0.16))
	if k == 3 and season in [1, 2]:
		for f in 5:
			ci.draw_circle(p + Vector2(-12 + f * 6, -36 + (f % 2) * 8) * s, 2.4 * s, Color("d9402e"))
	if season == 3:
		PaperFolk._paper(ci, PaperFolk._ell(p + Vector2(0, -56) * s, 14 * s, 6 * s, 12), Color("f6f8fa"), false)


func _draw_stall(ci: CanvasItem, st: Dictionary) -> void:
	var p: Vector2 = st["p"]
	var aw: Color = st["awning"]
	ci.draw_colored_polygon(PaperFolk._ell(p + Vector2(3, 2), 34, 6, 14), Color(0, 0, 0, 0.15))
	for sx in [-28.0, 28.0]:
		ci.draw_line(p + Vector2(sx, 0), p + Vector2(sx, -50), Color("5a4030"), 3.0)
	PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-32, -2), p + Vector2(32, -2), p + Vector2(32, -18), p + Vector2(-32, -18)]), Color("a07a4a"))
	var icon := UiKit.sprite("goods", int(GameData.GOODS[st["good"]]["icon"]))
	if icon:
		for k in 3:
			ci.draw_texture_rect(icon, Rect2(p + Vector2(-28 + k * 19, -34), Vector2(20, 20)), false)
	# striped awning
	var top := p + Vector2(0, -50)
	for k in 6:
		var x0 := -36.0 + k * 12.0
		var col := aw if k % 2 == 0 else Color("f3e9d2")
		ci.draw_colored_polygon(PackedVector2Array([top + Vector2(x0, -8), top + Vector2(x0 + 12, -8), top + Vector2(x0 + 13, 8), top + Vector2(x0 + 1, 8)]), col)
	for k in 6:
		ci.draw_circle(top + Vector2(-30 + k * 12, 9), 6.0, aw if k % 2 == 0 else Color("f3e9d2"))


func _draw_house(ci: CanvasItem, pr: Dictionary, night: float) -> void:
	var p: Vector2 = pr["p"]
	var w: float = pr["w"]
	var h: float = pr["h"]
	var wall: Color = pr["wall"]
	var roof: Color = pr["roof"]
	ci.draw_colored_polygon(PaperFolk._ell(p + Vector2(6, -4), w * 0.55, 12, 18), Color(0, 0, 0, 0.15))
	var wall_h := h * (0.62 if pr["two"] else 0.5)
	# walls with timber frame
	PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-w * 0.42, 0), p + Vector2(w * 0.42, 0), p + Vector2(w * 0.42, -wall_h), p + Vector2(-w * 0.42, -wall_h)]), wall)
	var timber := Color("5a4030")
	ci.draw_line(p + Vector2(-w * 0.42, -wall_h * 0.52), p + Vector2(w * 0.42, -wall_h * 0.52), timber, 2.0)
	for sx in [-0.42, -0.14, 0.14, 0.42]:
		ci.draw_line(p + Vector2(w * sx, 0), p + Vector2(w * sx, -wall_h), timber, 2.0)
	# door and windows
	ci.draw_rect(Rect2(p + Vector2(-8, -24), Vector2(16, 24)), Color("6a3a24"))
	ci.draw_circle(p + Vector2(4, -12), 1.4, Color("d9b45a"))
	var lit := Color("f0d070").lerp(Color("ffd27a"), night) if night > 0.05 else Color("4a5a62")
	for sx in [-0.28, 0.28]:
		ci.draw_rect(Rect2(p + Vector2(w * sx - 8, -wall_h * 0.42 - 10), Vector2(16, 14)), lit)
		ci.draw_rect(Rect2(p + Vector2(w * sx - 8, -wall_h * 0.42 - 10), Vector2(16, 14)), timber, false, 1.6)
		if pr["two"]:
			ci.draw_rect(Rect2(p + Vector2(w * sx - 7, -wall_h * 0.82 - 8), Vector2(14, 12)), lit)
	# sweeping roof with upturned eaves
	var ry := -wall_h
	var roof_pts := PackedVector2Array([
		p + Vector2(-w * 0.58, ry + 6), p + Vector2(-w * 0.5, ry - 2), p + Vector2(-w * 0.36, ry - h * 0.36),
		p + Vector2(w * 0.36, ry - h * 0.36), p + Vector2(w * 0.5, ry - 2), p + Vector2(w * 0.58, ry + 6), p + Vector2(0, ry + 1)])
	PaperFolk._paper(ci, roof_pts, roof)
	for k in 6:
		var x := -w * 0.4 + k * w * 0.16
		ci.draw_line(p + Vector2(x, ry - 1), p + Vector2(x * 0.75, ry - h * 0.34), roof.darkened(0.2), 1.2)
	ci.draw_line(p + Vector2(-w * 0.38, ry - h * 0.36), p + Vector2(w * 0.38, ry - h * 0.36), roof.darkened(0.35), 4.0)
	if _season() == 3:
		PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-w * 0.36, ry - h * 0.36), p + Vector2(w * 0.36, ry - h * 0.36), p + Vector2(w * 0.3, ry - h * 0.26), p + Vector2(-w * 0.3, ry - h * 0.26)]), Color("f6f8fa"), false)
	if pr["smoke"]:
		ci.draw_rect(Rect2(p + Vector2(w * 0.24, ry - h * 0.36 - 16), Vector2(10, 18)), Color("7a6a5a"))


func _draw_statue(ci: CanvasItem, pr: Dictionary) -> void:
	var p: Vector2 = pr["p"]
	PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-26, 0), p + Vector2(26, 0), p + Vector2(22, -22), p + Vector2(-22, -22)]), _stone.darkened(0.15))
	var lk := PaperFolk.hero_look(pr["house"]).duplicate()
	var stone := Color("b9b5aa")
	for key in ["robe", "trim", "pants", "hair", "hat_col", "apron", "cape"]:
		if lk.has(key):
			lk[key] = stone.darkened(0.1 * (key.length() % 3))
	lk["skin"] = stone.lightened(0.1)
	lk.erase("pin")
	PaperFolk.draw(ci, p + Vector2(0, -22), lk, 0, 0.0, false, 0.0, 1.5)


func _draw_landmark(ci: CanvasItem, p: Vector2, mark: String, night: float) -> void:
	var dark := Color("3a3028")
	ci.draw_colored_polygon(PaperFolk._ell(p + Vector2(6, 0), 80, 16, 24), Color(0, 0, 0, 0.14))
	match mark:
		"pailou":
			var red := Color("a8463a")
			for sx in [-60.0, -22.0, 22.0, 60.0]:
				PaperFolk._paper(ci, PackedVector2Array([p + Vector2(sx - 5, 0), p + Vector2(sx + 5, 0), p + Vector2(sx + 5, -110), p + Vector2(sx - 5, -110)]), red)
			PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-86, -104), p + Vector2(86, -104), p + Vector2(74, -128), p + Vector2(-74, -128)]), Color("2f5a5a"))
			PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-50, -132), p + Vector2(50, -132), p + Vector2(40, -150), p + Vector2(-40, -150)]), Color("2f5a5a"))
			ci.draw_rect(Rect2(p + Vector2(-30, -100), Vector2(60, 16)), Color("e3b45a"))
			for k in 6:
				var fx := -70.0 + k * 28.0
				ci.draw_line(p + Vector2(fx, -150), p + Vector2(fx, -176), dark, 1.6)
				ci.draw_colored_polygon(PackedVector2Array([p + Vector2(fx, -176), p + Vector2(fx + 16 + sin(_t * 3.0 + k) * 2, -171), p + Vector2(fx, -164)]), [Color("b5583c"), Color("e3b45a"), Color("2f6f6a")][k % 3])
		"cloth", "nets":
			var cols := [Color("b5583c"), Color("e8d8b0"), Color("c9603e"), Color("e3b45a")] if mark == "cloth" else [Color("6a7a7a"), Color("8a9a9a"), Color("5a6a6a"), Color("7a8a8a")]
			for sx in [-70.0, 0.0, 70.0]:
				ci.draw_line(p + Vector2(sx, 0), p + Vector2(sx, -120), Color("6a4a30"), 4.0)
			for row in 2:
				var yy := -116.0 + row * 50.0
				ci.draw_line(p + Vector2(-70, yy), p + Vector2(70, yy), Color("5a4030"), 1.4)
				for k in 6:
					var cx := -62.0 + k * 25.0
					var sway := sin(_t * 1.8 + k + row) * 4.0
					if mark == "cloth":
						PaperFolk._paper(ci, PackedVector2Array([p + Vector2(cx - 10, yy), p + Vector2(cx + 10, yy), p + Vector2(cx + 10 + sway, yy + 42), p + Vector2(cx - 10 + sway, yy + 42)]), cols[(k + row) % 4], false)
					else:
						for g in 4:
							ci.draw_line(p + Vector2(cx - 10 + g * 6, yy), p + Vector2(cx - 12 + g * 6 + sway, yy + 40), cols[g], 1.0)
						ci.draw_line(p + Vector2(cx - 12, yy + 20), p + Vector2(cx + 12 + sway, yy + 20), cols[0], 1.0)
		"bones":
			var bone := Color("ece4d0")
			for side in [-1.0, 1.0]:
				var pts := PackedVector2Array()
				for k in 12:
					var a: float = PI * 0.5 + side * (float(k) / 11.0) * 1.3
					pts.append(p + Vector2(side * 70 - cos(a) * 40 * side, -sin(a) * 150))
				ci.draw_polyline(pts, bone.darkened(0.25), 14.0, true)
				ci.draw_polyline(pts, bone, 10.0, true)
			PaperFolk._paper(ci, PaperFolk._ell(p + Vector2(0, -10), 34, 12, 16), bone)
		"chimney":
			for sx in [-30.0, 34.0]:
				var hh := 150.0 if sx < 0 else 120.0
				PaperFolk._paper(ci, PackedVector2Array([p + Vector2(sx - 14, 0), p + Vector2(sx + 14, 0), p + Vector2(sx + 10, -hh), p + Vector2(sx - 10, -hh)]), Color("7a4a3a"))
				for k in int(hh / 14.0):
					ci.draw_line(p + Vector2(sx - 12, -k * 14), p + Vector2(sx + 12, -k * 14), Color("5a3a2a"), 1.0)
			ci.draw_circle(p + Vector2(0, -20), 16, Color(1.0, 0.55, 0.2, 0.35 + 0.15 * sin(_t * 5.0)))
		"bigtree":
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(-26, 0), p + Vector2(26, 0), p + Vector2(14, -90), p + Vector2(-14, -90)]), Color("5a3a26"))
			for k in 7:
				var a := float(k) / 7.0 * TAU
				PaperFolk._paper(ci, PaperFolk._ell(p + Vector2(cos(a) * 60, -130 + sin(a) * 34), 44, 34, 16), Color("3f6a46").lightened(0.04 * k))
			PaperFolk._paper(ci, PaperFolk._ell(p + Vector2(0, -140), 56, 40, 18), Color("4f7a4a"))
			for k in 8:
				ci.draw_circle(p + Vector2(-50 + k * 14, -100 + (k % 3) * 6), 3.0, Color(1.0, 0.95, 0.6, 0.3 + 0.3 * night))
		"windmill":
			PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-28, 0), p + Vector2(28, 0), p + Vector2(16, -110), p + Vector2(-16, -110)]), Color("b08a5a"))
			PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-20, -108), p + Vector2(20, -108), p + Vector2(0, -132)]), Color("8a6a3a"))
			var hub := p + Vector2(0, -100)
			for k in 4:
				var a := _t * 0.8 + k * PI * 0.5
				var tip := hub + Vector2(cos(a), sin(a)) * 76.0
				var side := Vector2(cos(a + PI * 0.5), sin(a + PI * 0.5)) * 10.0
				PaperFolk._paper(ci, PackedVector2Array([hub + side * 0.3, tip + side, tip, hub]), Color("e8dcc0"))
			ci.draw_circle(hub, 6, Color("b08a3e"))
			# the bronze crane on top
			ci.draw_line(p + Vector2(0, -132), p + Vector2(-10, -150), Color("b0763e"), 3.0)
			ci.draw_circle(p + Vector2(-12, -152), 4.0, Color("b0763e"))
		"rock":
			PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-50, 0), p + Vector2(46, 0), p + Vector2(30, -60), p + Vector2(18, -150), p + Vector2(-16, -138), p + Vector2(-36, -70)]), Color("a85a40"))
			for k in 6:
				ci.draw_line(p + Vector2(-30 + k * 10, -20 - k * 18), p + Vector2(-10 + k * 8, -30 - k * 18), Color("e0b090"), 2.0)
		"jars":
			for k in 9:
				var jp := p + Vector2(-64 + (k % 5) * 32, -(k / 5) * 26)
				PaperFolk._paper(ci, PaperFolk._ell(jp + Vector2(0, -14), 13, 15, 14), Color("8a4a2e").lerp(Color("5a3a2a"), float(k % 2) * 0.5))
				ci.draw_rect(Rect2(jp + Vector2(-6, -32), Vector2(12, 5)), Color("e0d0a0"))
			for k in 8:
				ci.draw_line(p + Vector2(-90 + k * 6, 0), p + Vector2(-92 + k * 6 + sin(_t + k) * 3, -50 - (k % 3) * 10), Color("8aa070"), 2.0)
		"belltower":
			PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-34, 0), p + Vector2(34, 0), p + Vector2(28, -120), p + Vector2(-28, -120)]), Color("c9b48e"))
			PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-46, -116), p + Vector2(46, -116), p + Vector2(0, -170)]), Color("b08a3e"))
			var sw := sin(_t * 2.0) * 0.15
			var bc := p + Vector2(0, -92)
			ci.draw_set_transform(bc, sw, Vector2.ONE)
			PaperFolk._paper(ci, PackedVector2Array([Vector2(-14, 0), Vector2(14, 0), Vector2(10, -22), Vector2(-10, -22)]), Color("b0763e"))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			ci.draw_rect(Rect2(p + Vector2(-12, -40), Vector2(24, 40)), Color("6a4a30"))
		"kiln":
			for sx in [-40.0, 40.0]:
				PaperFolk._paper(ci, _dome(p + Vector2(sx, 0), 38, 70), Color("e8e0d0"))
				ci.draw_colored_polygon(_dome(p + Vector2(sx, 0), 12, 22), Color(1.0, 0.6, 0.25, 0.7 + 0.2 * sin(_t * 4.0 + sx)))
		"watchtower":
			PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-34, 0), p + Vector2(34, 0), p + Vector2(26, -150), p + Vector2(-26, -150)]), Color("3e3a38"))
			for k in 4:
				ci.draw_rect(Rect2(p + Vector2(-30 + k * 16, -166), Vector2(10, 16)), Color("3e3a38"))
			ci.draw_rect(Rect2(p + Vector2(-6, -110), Vector2(12, 18)), Color(1.0, 0.7, 0.3, 0.5 + 0.4 * night))
			ci.draw_line(p + Vector2(0, -166), p + Vector2(0, -200), dark, 2.0)
			ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -200), p + Vector2(22 + sin(_t * 3.0) * 3, -194), p + Vector2(0, -186)]), Color("2a2626"))
		"pagoda":
			for k in 4:
				var w := 70.0 - k * 12.0
				var y0 := -k * 42.0
				PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-w * 0.55, y0), p + Vector2(w * 0.55, y0), p + Vector2(w * 0.55, y0 - 26), p + Vector2(-w * 0.55, y0 - 26)]), Color("c9c2b0"))
				PaperFolk._paper(ci, PackedVector2Array([p + Vector2(-w, y0 - 22), p + Vector2(w, y0 - 22), p + Vector2(w * 0.6, y0 - 42), p + Vector2(-w * 0.6, y0 - 42)]), Color("5a5a7a"))
				ci.draw_circle(p + Vector2(-w * 0.9, y0 - 18), 4.0, Color(1.0, 0.75, 0.35, 0.6 + 0.4 * night))
				ci.draw_circle(p + Vector2(w * 0.9, y0 - 18), 4.0, Color(1.0, 0.75, 0.35, 0.6 + 0.4 * night))


func _dome(c: Vector2, r: float, h: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for k in 13:
		var a := PI * float(k) / 12.0
		pts.append(c + Vector2(-cos(a) * r, -sin(a) * h))
	return pts


# ------------------------------------------------------------------ drawing: overlays
func _night() -> float:
	# time of day drifts with the calendar so some visits land at dusk
	var tod := fposmod((float(sim.s["day"]) + float(sim.s.get("frac", 0.0))) * 0.37, 1.0)
	return clampf(absf(tod - 0.5) * 2.6 - 0.75, 0.0, 0.45)


func _draw_ui() -> void:
	if port == "":
		return
	var ci := _ui_layer
	var font := UiKit.font_bold if UiKit.font_bold else ThemeDB.fallback_font
	var o := -_cam.round()
	# lantern festival: strings of lanterns over the streets (round 15)
	if sim.festival_on():
		var lr := RandomNumberGenerator.new()
		lr.seed = 77 + port.hash()
		for rr in [_roads[0], _roads[1], _roads[6]]:
			var rect: Rect2 = rr
			var horiz := rect.size.x > rect.size.y
			var a := rect.position + (Vector2(0, rect.size.y * 0.5) if horiz else Vector2(rect.size.x * 0.5, 0))
			var b := a + (Vector2(rect.size.x, 0) if horiz else Vector2(0, rect.size.y))
			var n := int(a.distance_to(b) / 40.0)
			var prev := a + o + Vector2(0, -64)
			for i in n + 1:
				var lp := a.lerp(b, float(i) / float(maxi(n, 1))) + o + Vector2(0, -64 + sin(float(i) * 0.7) * 6.0)
				ci.draw_line(prev, lp, Color(0.3, 0.2, 0.15, 0.6), 1.0)
				prev = lp
				var lc: Color = [Color(0.95, 0.4, 0.28), Color(0.98, 0.76, 0.32), Color(0.9, 0.32, 0.42)][lr.randi_range(0, 2)]
				var sw := sin(_t * 2.0 + i) * 2.0
				ci.draw_circle(lp + Vector2(sw, 8), 11, Color(lc, 0.2))
				ci.draw_colored_polygon(PaperFolk._ell(lp + Vector2(sw, 8), 6, 7.5, 12), lc)
	# dusk and night, with lamps glowing through it
	var night := _night()
	if night > 0.01:
		ci.draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.09, 0.22, night))
		for pr in _props:
			var sp: Vector2 = pr["p"] + o
			if sp.x < -60 or sp.y < -60 or sp.x > size.x + 60 or sp.y > size.y + 60:
				continue
			if pr["kind"] == "lamp":
				ci.draw_circle(sp + Vector2(9, -36), 34, Color(1.0, 0.78, 0.4, night * 0.45))
				ci.draw_circle(sp + Vector2(9, -36), 10, Color(1.0, 0.85, 0.5, night * 0.9))
			elif pr["kind"] == "house":
				ci.draw_circle(sp + Vector2(0, -pr["h"] * 0.3), pr["w"] * 0.4, Color(1.0, 0.8, 0.45, night * 0.22))
		for b in _buildings:
			var bc: Vector2 = (b["rect"] as Rect2).get_center() + o
			ci.draw_circle(bc + Vector2(0, 30), 46, Color(1.0, 0.8, 0.45, night * 0.3))
		# the protagonist's own lantern light
		ci.draw_circle(hero_pos + o + Vector2(0, -20), 60, Color(1.0, 0.85, 0.55, night * 0.25))
	# building name plates at the doors
	for b in _buildings:
		var near: bool = b["kind"] == _near
		var fs := 15
		var tw := font.get_string_size(b["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var lp: Vector2 = b["door"] + o + Vector2(-tw * 0.5 - 9, -6)
		if lp.x < -100 or lp.x > size.x + 100 or lp.y < -40 or lp.y > size.y + 40:
			continue
		ci.draw_rect(Rect2(lp + Vector2(2, 3), Vector2(tw + 18, 23)), Color(0, 0, 0, 0.18))
		ci.draw_rect(Rect2(lp, Vector2(tw + 18, 23)), Color(UiKit.PARCH, 0.96) if not near else Color(UiKit.BRASS, 0.98))
		ci.draw_rect(Rect2(lp, Vector2(tw + 18, 23)), Color(UiKit.BRASS, 0.85), false, 1.2)
		ci.draw_string(font, lp + Vector2(9, 17), b["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, fs, UiKit.INK if not near else Color.WHITE)
	# companions wear a name tag
	for n in _npcs:
		if n.has("cid"):
			var nm: String = Characters.name_of(n["cid"])
			var nw := font.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
			var tp: Vector2 = n["p"] + o + Vector2(-nw * 0.5 - 5, -84)
			ci.draw_rect(Rect2(tp, Vector2(nw + 10, 17)), Color(UiKit.JADE, 0.92))
			ci.draw_string(font, tp + Vector2(5, 13), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	# what the nearest townsperson says when you pass
	var talker := {}
	var td := 70.0
	for n in _npcs:
		var dd: float = hero_pos.distance_to(n["p"])
		if str(n.get("line", "")) != "" and dd < td:
			td = dd
			talker = n
	if not talker.is_empty():
		var line: String = talker["line"]
		if "%s" in line:
			line = line % GameData.HOUSES[sim.pid()]["name"]
		_bubble(talker["p"] + o + Vector2(0, -70 - (16 if talker.has("cid") else 0)), line, font)
	# door prompt
	if _near != "":
		_bubble(hero_pos + o + Vector2(0, -78), "按 E 或点击 进入%s" % kind_name(_near), font, true)
	# title and hint, fixed on screen
	var p: Dictionary = GameData.PORTS[port]
	var title := "%s · 城中%s" % [p["name"], " · 灯节" if sim.festival_on() else ""]
	var hint := "WASD / 方向键走动 · 点地面或建筑走过去 · Esc 回到海图"
	var tw1 := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	var tw2 := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
	var box := Rect2(Vector2(size.x - maxf(tw1, tw2) - 34, size.y - 70), Vector2(maxf(tw1, tw2) + 24, 60))
	ci.draw_rect(box, Color(UiKit.PARCH, 0.85))
	ci.draw_rect(box, Color(UiKit.BRASS, 0.7), false, 1.0)
	ci.draw_string(font, Vector2(size.x - tw1 - 22, size.y - 40), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UiKit.INK)
	ci.draw_string(font, Vector2(size.x - tw2 - 22, size.y - 18), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(UiKit.INK, 0.8))


func _bubble(at: Vector2, text: String, font: Font, strong: bool = false) -> void:
	var ci := _ui_layer
	var fs := 14
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var w := tw + 20
	var tl := at + Vector2(-w * 0.5, -30)
	tl.x = clampf(tl.x, 6, size.x - w - 6)
	tl.y = maxf(tl.y, 4)
	ci.draw_rect(Rect2(tl + Vector2(2, 3), Vector2(w, 28)), Color(0, 0, 0, 0.15))
	ci.draw_rect(Rect2(tl, Vector2(w, 28)), Color(UiKit.INK, 0.94) if strong else Color("fbf5e6"))
	ci.draw_rect(Rect2(tl, Vector2(w, 28)), UiKit.BRASS, false, 1.0)
	ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-6, -2), at + Vector2(6, -2), at + Vector2(0, 7)]), Color(UiKit.INK, 0.94) if strong else Color("fbf5e6"))
	ci.draw_string(font, tl + Vector2(10, 19), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color("f6efdc") if strong else UiKit.INK)
