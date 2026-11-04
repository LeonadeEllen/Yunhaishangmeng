extends Control
## The air-combat screen: a hex board drawn by hand on the left, the command panel on the right.
## It only talks to a Battle object; the world (Sim) applies the result afterwards.

signal finished

const SQ3 := 1.7320508

var battle: Battle
var auto := false

var _hex := 40.0
var _origin := Vector2.ZERO
var _board := Rect2()
var _pos := {}            # uid -> Vector2 (animated screen centre)
var _hover := Vector2i(-1, -1)
var _mode := "move"       # move / fire / board / tactic:<id>
var _reach := {}
var _targets := {}        # uid -> true, for the current mode
var _events: Array = []
var _anim: Dictionary = {}
var _floats: Array = []
var _delay := 0.0
var _ended := false
var _flash: Array = []    # [from, to, t]
var _ship_tex := {}
var _t := 0.0
var _shots: Array = []    # cannonballs in flight: {a, b, t}
var _booms: Array = []    # explosions with debris: {p, t, seed}
var _sinking: Array = []  # wrecks falling into the clouds: {p, tex, mine, t}
var _shake := 0.0
var _bg_clouds: Array = []

var panel: PanelContainer
var body: VBoxContainer
var head_lbl: Label
var unit_box: VBoxContainer
var action_box: VBoxContainer
var tactic_box: VBoxContainer
var order_box: HBoxContainer
var log_box: VBoxContainer
var hint_lbl: Label
var auto_btn: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	for t in GameData.SHIPS:
		_ship_tex[t] = UiKit.sprite("ships", GameData.SHIPS[t]["sprite"])
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCH, 0.97), Color(UiKit.BRASS, 0.6), 8, 1, 14))
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -372
	panel.offset_top = 12
	panel.offset_bottom = -12
	panel.offset_right = -12
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	scroll.add_child(body)
	head_lbl = UiKit.label("", 22, UiKit.INK, true)
	body.add_child(head_lbl)
	hint_lbl = UiKit.para("", 14, UiKit.JADE)
	body.add_child(hint_lbl)
	unit_box = VBoxContainer.new()
	unit_box.add_theme_constant_override("separation", 2)
	body.add_child(unit_box)
	action_box = VBoxContainer.new()
	action_box.add_theme_constant_override("separation", 4)
	body.add_child(action_box)
	body.add_child(HSeparator.new())
	tactic_box = VBoxContainer.new()
	tactic_box.add_theme_constant_override("separation", 4)
	body.add_child(tactic_box)
	body.add_child(HSeparator.new())
	body.add_child(UiKit.label("行动顺序", 14, UiKit.INK, true))
	order_box = HBoxContainer.new()
	order_box.add_theme_constant_override("separation", 4)
	body.add_child(order_box)
	body.add_child(HSeparator.new())
	log_box = VBoxContainer.new()
	log_box.add_theme_constant_override("separation", 1)
	body.add_child(log_box)
	body.add_child(HSeparator.new())
	var legend := []
	for k in GameData.TERRAIN:
		legend.append("%s：%s" % [GameData.TERRAIN[k]["name"], GameData.TERRAIN[k]["desc"]])
	body.add_child(UiKit.para("地形 · " + "；".join(legend) + "。炮击射程 3 格，浮岩挡炮；接舷要贴在敌船旁边，赢了就俘获；士气低于 20 的船会自己逃跑。", 12, UiKit.MUTED))
	auto_btn = UiKit.button("自动战斗", func(): auto = not auto; _refresh_panel(), true)
	body.add_child(auto_btn)
	resized.connect(_layout)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in 26:
		_bg_clouds.append({"x": rng.randf(), "y": rng.randf_range(0.15, 1.0), "r": rng.randf_range(30, 90), "sp": rng.randf_range(0.004, 0.015)})


func open(bt: Battle) -> void:
	battle = bt
	auto = false
	_ended = false
	_events = []
	_anim = {}
	_floats = []
	_flash = []
	_shots = []
	_booms = []
	_sinking = []
	_shake = 0.0
	_mode = "move"
	_pos = {}
	_layout()
	for u in battle.b["units"]:
		_pos[int(u["id"])] = hex_center(int(u["col"]), int(u["row"]))
	if battle.current().is_empty():
		battle.next_unit()
	_drain_new_events()
	_refresh_panel()
	queue_redraw()


func _layout() -> void:
	_board = Rect2(16, 16, maxf(200.0, size.x - 400), maxf(200.0, size.y - 32))
	var hw := _board.size.x / (SQ3 * (float(Battle.W) + 0.5))
	var hh := _board.size.y / (1.5 * float(Battle.H - 1) + 2.0)
	_hex = minf(hw, hh)
	var bw := SQ3 * _hex * (float(Battle.W) + 0.5)
	var bh := _hex * (1.5 * float(Battle.H - 1) + 2.0)
	_origin = _board.position + (_board.size - Vector2(bw, bh)) * 0.5 + Vector2(SQ3 * _hex * 0.5, _hex)
	for uid in _pos.keys():
		var u := battle.unit_by_id(uid) if battle != null else {}
		if not u.is_empty():
			_pos[uid] = hex_center(int(u["col"]), int(u["row"]))


func hex_center(c: int, r: int) -> Vector2:
	return _origin + Vector2(SQ3 * _hex * (float(c) + 0.5 * float(r & 1)), 1.5 * _hex * float(r))


func hex_at(p: Vector2) -> Vector2i:
	var best := Vector2i(-1, -1)
	var bd := _hex * 0.95
	for r in Battle.H:
		for c in Battle.W:
			var d := p.distance_to(hex_center(c, r))
			if d < bd:
				bd = d
				best = Vector2i(c, r)
	return best


# ---------------------------------------------------------------- flow

func _process(delta: float) -> void:
	if not visible or battle == null:
		return
	_t += delta
	for f in _floats:
		f["t"] += delta
	_floats = _floats.filter(func(f): return f["t"] < 1.1)
	for fl in _flash:
		fl[2] += delta
	_flash = _flash.filter(func(fl): return fl[2] < 0.35)
	for s in _shots:
		s["t"] += delta
		if s["t"] >= 0.32 and not s.get("hit", false):
			s["hit"] = true
			_booms.append({"p": s["b"], "t": 0.0, "seed": randi()})
			_shake = maxf(_shake, 5.0)
	_shots = _shots.filter(func(s): return s["t"] < 0.32)
	for bm in _booms:
		bm["t"] += delta
	_booms = _booms.filter(func(bm): return bm["t"] < 0.9)
	for sk in _sinking:
		sk["t"] += delta
	_sinking = _sinking.filter(func(sk): return sk["t"] < 2.2)
	_shake = maxf(0.0, _shake - delta * 18.0)
	queue_redraw()
	if not _anim.is_empty():
		_anim["t"] += delta
		var k: String = _anim["kind"]
		if k == "move":
			var p := clampf(_anim["t"] / 0.22, 0.0, 1.0)
			_pos[int(_anim["uid"])] = _anim["from"].lerp(_anim["to"], p)
			if p >= 1.0:
				_anim = {}
		elif _anim["t"] >= float(_anim["dur"]):
			_anim = {}
		return
	if not _events.is_empty():
		_start_anim(_events.pop_front())
		return
	if battle.b["over"] != "":
		if not _ended:
			_ended = true
			_refresh_panel()
			_delay = 0.0
		_delay += delta
		if _delay > 0.9:
			finished.emit()
		return
	var cur := battle.current()
	if cur.is_empty():
		battle.next_unit()
		_drain_new_events()
		_refresh_panel()
		return
	if int(cur["side"]) == 1 or auto:
		_delay += delta
		if _delay > 0.3:
			_delay = 0.0
			battle.ai_turn()
			battle.next_unit()
			_drain_new_events()
			_refresh_panel()
	else:
		_delay = 0.0


func _drain_new_events() -> void:
	for e in battle.b["events"]:
		_events.append(e)
	battle.b["events"].clear()


func _start_anim(e: Dictionary) -> void:
	var k: String = e["kind"]
	match k:
		"move":
			var path := [Vector2i(e["from"][0], e["from"][1]), Vector2i(e["to"][0], e["to"][1])]
			_anim = {"kind": "move", "t": 0.0, "uid": int(e["uid"]), "from": hex_center(path[0].x, path[0].y), "to": hex_center(path[1].x, path[1].y)}
		"fire":
			var a: Vector2 = _pos.get(int(e["uid"]), Vector2.ZERO)
			var bpos: Vector2 = _pos.get(int(e["tid"]), Vector2.ZERO)
			_flash.append([a, a, 0.0])
			_shots.append({"a": a, "b": bpos, "t": 0.0})
			_floats.append({"text": "−%d" % int(e["dmg"]), "pos": bpos + Vector2(0, -_hex * 0.9), "t": -0.3, "col": UiKit.TERRA})
			_anim = {"kind": "pause", "t": 0.0, "dur": 0.65}
		"board":
			var bpos2: Vector2 = _pos.get(int(e["tid"]), Vector2.ZERO)
			var txt := "俘获！" if e["captured"] else ("接舷得手" if e["win"] else "接舷受挫")
			_floats.append({"text": txt, "pos": bpos2 + Vector2(0, -_hex * 0.9), "t": 0.0, "col": UiKit.BRASS if e["win"] else UiKit.TERRA})
			_anim = {"kind": "pause", "t": 0.0, "dur": 0.6}
		"sunk":
			var p3: Vector2 = _pos.get(int(e["uid"]), Vector2.ZERO)
			var su := battle.unit_by_id(int(e["uid"]))
			if not su.is_empty():
				_sinking.append({"p": p3, "tex": _ship_tex[su["type"]], "mine": int(su["side"]) == 0, "t": 0.0})
				_booms.append({"p": p3, "t": 0.0, "seed": randi()})
				_shake = 9.0
			_floats.append({"text": "击沉", "pos": p3 + Vector2(0, -_hex * 0.9), "t": 0.0, "col": UiKit.INK})
			_anim = {"kind": "pause", "t": 0.0, "dur": 0.5}
		"flee":
			var p4: Vector2 = _pos.get(int(e["uid"]), Vector2.ZERO)
			_floats.append({"text": "撤离", "pos": p4 + Vector2(0, -_hex * 0.9), "t": 0.0, "col": UiKit.MUTED})
			_anim = {"kind": "pause", "t": 0.0, "dur": 0.4}
		"repair":
			var p5: Vector2 = _pos.get(int(e["uid"]), Vector2.ZERO)
			_floats.append({"text": "+%d" % int(e["heal"]), "pos": p5 + Vector2(0, -_hex * 0.9), "t": 0.0, "col": UiKit.UP})
			_anim = {"kind": "pause", "t": 0.0, "dur": 0.35}
		"defend":
			var p6: Vector2 = _pos.get(int(e["uid"]), Vector2.ZERO)
			_floats.append({"text": "防御", "pos": p6 + Vector2(0, -_hex * 0.9), "t": 0.0, "col": UiKit.JADE})
			_anim = {"kind": "pause", "t": 0.0, "dur": 0.3}
		"tactic":
			_floats.append({"text": "指挥：" + GameData.TACTICS[e["id"]]["name"], "pos": Vector2(_board.get_center().x, _board.position.y + 30), "t": 0.0, "col": UiKit.BRASS})
			_anim = {"kind": "pause", "t": 0.0, "dur": 0.5}
		_:
			_anim = {"kind": "pause", "t": 0.0, "dur": 0.2}


# ---------------------------------------------------------------- input

func _gui_input(event: InputEvent) -> void:
	if battle == null or battle.b["over"] != "":
		return
	if event is InputEventMouseMotion:
		var h := hex_at(event.position)
		if h != _hover:
			_hover = h
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			_mode = "move"
			_refresh_panel()
			return
		if event.button_index != MOUSE_BUTTON_LEFT:
			return
		var cur := battle.current()
		if cur.is_empty() or int(cur["side"]) != 0 or auto or not _anim.is_empty() or not _events.is_empty():
			return
		var h2 := hex_at(event.position)
		if h2.x < 0:
			return
		var clicked := battle.unit_at(h2.x, h2.y)
		var res := {"ok": true, "msg": ""}
		if _mode.begins_with("tactic:"):
			var id := _mode.substr(7)
			var need: String = GameData.TACTICS[id]["target"]
			if clicked.is_empty():
				return
			res = battle.tactic(id, int(clicked["id"]))
			_mode = "move"
		elif not clicked.is_empty() and int(clicked["side"]) == 1:
			if _mode == "board" or (int(cur["guns"]) <= 0 and _mode == "move"):
				res = battle.board(int(cur["id"]), int(clicked["id"]))
			else:
				res = battle.fire(int(cur["id"]), int(clicked["id"]))
			_mode = "move"
		elif clicked.is_empty() and _mode == "move":
			res = battle.move_to(int(cur["id"]), h2.x, h2.y)
		else:
			return
		if not res["ok"]:
			hint_lbl.text = res["msg"]
		_drain_new_events()
		if cur["acted"] and battle.b["over"] == "":
			battle.next_unit()
			_drain_new_events()
		_refresh_panel()
		accept_event()


func _do(res: Dictionary) -> void:
	if not res["ok"]:
		hint_lbl.text = res["msg"]
		return
	_drain_new_events()
	var cur := battle.current()
	if not cur.is_empty() and cur["acted"] and battle.b["over"] == "":
		battle.next_unit()
		_drain_new_events()
	_mode = "move"
	_refresh_panel()


# ---------------------------------------------------------------- panel

func _refresh_panel() -> void:
	if battle == null:
		return
	var b := battle.b
	head_lbl.text = "空战 · 第 %d 回合 · 指挥点 %d/%d" % [int(b["round"]), int(b["cp"]), int(b["cp_max"])]
	auto_btn.text = "自动战斗：%s" % ("开" if auto else "关")
	UiKit.clear(unit_box)
	UiKit.clear(action_box)
	UiKit.clear(tactic_box)
	UiKit.clear(order_box)
	UiKit.clear(log_box)
	var cur := battle.current()
	_reach = {}
	_targets = {}
	if b["over"] != "":
		hint_lbl.text = {"win": "敌船溃散，我方大胜！", "loss": "旗舰失守，船队溃败……", "withdraw": "我方撤出了战场。"}[b["over"]]
	elif cur.is_empty():
		hint_lbl.text = ""
	elif int(cur["side"]) == 1:
		hint_lbl.text = "云盗 %s 行动中……" % cur["name"]
	elif auto:
		hint_lbl.text = "自动战斗中……"
	else:
		match _mode:
			"move":
				hint_lbl.text = "点亮着的格子移动；点射程内的敌船开炮；右键取消。"
			"fire":
				hint_lbl.text = "选择一艘射程内的敌船开炮。"
			"board":
				hint_lbl.text = "选择一艘相邻的敌船接舷。"
			_:
				hint_lbl.text = "选择目标：" + GameData.TACTICS[_mode.substr(7)]["desc"]
	if not cur.is_empty():
		var mine := int(cur["side"]) == 0
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(UiKit.icon(_ship_tex[cur["type"]], 48))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UiKit.label("%s%s · %s" % ["★ " if cur["flag"] else "", cur["name"], GameData.SHIPS[cur["type"]]["name"]], 16, UiKit.INK if mine else UiKit.TERRA, true))
		v.add_child(UiKit.label("耐久 %d/%d · 船员 %d/%d · 炮 %d" % [int(cur["hp"]), int(cur["hp_max"]), int(cur["crew"]), int(cur["crew_max"]), int(cur["guns"])], 13, UiKit.MUTED))
		v.add_child(UiKit.label("移动力 %d/%d · 士气 %d%s" % [battle.move_left(cur), int(cur["move"]) + (int(b["bonus_move"]) if mine else 0), int(cur["morale"]), " · 防御中" if cur["defend"] else ""], 13, UiKit.MUTED))
		row.add_child(v)
		unit_box.add_child(row)
		if mine and not auto:
			_reach = battle.reachable(cur)
			var tg := battle.targets(cur)
			var bd := battle.boardable(cur)
			if _mode == "board":
				for e in bd:
					_targets[int(e["id"])] = true
			elif _mode.begins_with("tactic:"):
				var need: String = GameData.TACTICS[_mode.substr(7)]["target"]
				for u in battle.alive(1 if need == "enemy" else 0):
					_targets[int(u["id"])] = true
			else:
				for e in tg:
					_targets[int(e["id"])] = true
				if int(cur["guns"]) <= 0:
					for e in bd:
						_targets[int(e["id"])] = true
			var uid := int(cur["id"])
			var grid := GridContainer.new()
			grid.columns = 3
			grid.add_theme_constant_override("h_separation", 4)
			grid.add_theme_constant_override("v_separation", 4)
			var fb := UiKit.button("炮击 (%d)" % tg.size(), func(): _mode = "fire"; _refresh_panel())
			fb.disabled = int(cur["guns"]) <= 0 or tg.is_empty()
			fb.tooltip_text = "射程 3 格，伤害 = 炮数 × 4 × 船员比例 × 船长战斗加成；远距离和浓雾里打得轻，浮岩挡炮。"
			grid.add_child(fb)
			var bb := UiKit.button("接舷 (%d)" % bd.size(), func(): _mode = "board"; _refresh_panel())
			bb.disabled = bd.is_empty() or int(cur["crew"]) <= 0
			bb.tooltip_text = "船员对拼：我方船员 × 战斗加成 对 敌方船员（防御中 ×1.3）。大胜就俘获整艘船。"
			grid.add_child(bb)
			var rb := UiKit.button("修补", func(): _do(battle.repair(uid)), true)
			rb.disabled = int(cur["hp"]) >= int(cur["hp_max"])
			rb.tooltip_text = "恢复最大耐久的四分之一。"
			grid.add_child(rb)
			var db := UiKit.button("防御", func(): _do(battle.defend(uid)), true)
			db.tooltip_text = "到下回合前受到的炮击减半、接舷更难得手，士气 +5。"
			grid.add_child(db)
			var tb := UiKit.button("撤退", func(): _do(battle.retreat(uid)), true)
			tb.disabled = not battle.can_retreat(cur)
			tb.tooltip_text = "在己方边缘两列内才能离开战场；船和货都保住，但拿不到战利品。"
			grid.add_child(tb)
			grid.add_child(UiKit.button("待命", func(): _do(battle.wait(uid)), true))
			action_box.add_child(grid)
			# tactics
			tactic_box.add_child(UiKit.label("主角指挥 · 指挥点 %d" % int(b["cp"]), 14, UiKit.INK, true))
			var tg2 := GridContainer.new()
			tg2.columns = 3
			tg2.add_theme_constant_override("h_separation", 4)
			tg2.add_theme_constant_override("v_separation", 4)
			for id in GameData.TACTICS:
				var t: Dictionary = GameData.TACTICS[id]
				var locked := int(b["hero_lvl"]) < int(t["lvl"])
				var tid: String = id
				var btn := UiKit.button(t["name"] if not locked else "%s · %d 级" % [t["name"], int(t["lvl"])], func():
					if GameData.TACTICS[tid]["target"] == "":
						_do(battle.tactic(tid, -1))
					else:
						_mode = "tactic:" + tid
						_refresh_panel(), true)
				btn.disabled = not battle.tactic_ok(id)
				btn.tooltip_text = t["desc"] + ("（主角 %d 级解锁）" % int(t["lvl"]) if locked else "")
				btn.add_theme_font_size_override("font_size", 13)
				tg2.add_child(btn)
			tactic_box.add_child(tg2)
	# order strip
	for i in range(int(b["cur"]), b["order"].size()):
		if i < 0:
			continue
		var u := battle.unit_by_id(int(b["order"][i]))
		if u.is_empty() or u["status"] != "ok":
			continue
		var ic := UiKit.icon(_ship_tex[u["type"]], 30)
		ic.modulate = Color(1, 1, 1, 1.0) if int(u["side"]) == 0 else Color(1.0, 0.75, 0.7, 1.0)
		ic.tooltip_text = "%s · 耐久 %d/%d" % [u["name"], int(u["hp"]), int(u["hp_max"])]
		order_box.add_child(ic)
	# log
	var lines: Array = b["log"]
	for i in range(maxi(0, lines.size() - 7), lines.size()):
		log_box.add_child(UiKit.para(lines[i], 12, UiKit.INK if i == lines.size() - 1 else UiKit.MUTED))
	queue_redraw()


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	_draw_backdrop()
	if battle == null:
		return
	if _shake > 0.0:
		draw_set_transform(Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake)) * 0.5, 0.0, Vector2.ONE)
	var font := UiKit.font_bold if UiKit.font_bold else ThemeDB.fallback_font
	var cur := battle.current()
	var cur_id := int(cur["id"]) if not cur.is_empty() else -1
	# hexes
	for r in Battle.H:
		for c in Battle.W:
			var p := hex_center(c, r)
			var k := Battle.key(c, r)
			var terr := battle.terrain_at(c, r)
			var fill := Color(0.97, 0.98, 0.985, 0.55) if (c + r) % 2 == 0 else Color(0.93, 0.95, 0.96, 0.55)
			if c <= 1:
				fill = Color(UiKit.BRASS, 0.12)
			elif c >= Battle.W - 2:
				fill = Color(UiKit.TERRA, 0.10)
			match terr:
				"rock":
					fill = Color("7a6a55")
				"storm":
					fill = Color(0.35, 0.32, 0.5, 0.75)
				"fog":
					fill = Color(1, 1, 1, 0.85)
				"updraft":
					fill = Color(0.7, 0.9, 0.95, 0.7)
			if terr == "":
				fill.a *= 0.75
			_hex_poly(p, fill)
			if _reach.has(k):
				_hex_poly(p, Color(UiKit.BRASS, 0.3))
			draw_polyline(_hex_points(p, 1.0), Color(UiKit.INK, 0.18), 1.0, true)
			if _hover == Vector2i(c, r):
				draw_polyline(_hex_points(p, 0.92), Color(UiKit.INK, 0.6), 2.0, true)
			match terr:
				"storm":
					var z := [p + Vector2(-4, -10), p + Vector2(3, -2), p + Vector2(-2, -1), p + Vector2(5, 9)]
					draw_polyline(PackedVector2Array(z), Color(1.0, 0.9, 0.5, 0.9), 2.0, true)
				"updraft":
					for i in 3:
						var ox := float(i - 1) * 9.0
						draw_polyline(PackedVector2Array([p + Vector2(ox - 4, 6), p + Vector2(ox, -2), p + Vector2(ox + 4, 6)]), Color(UiKit.JADE, 0.6), 1.5, true)
				"rock":
					draw_circle(p + Vector2(-5, 3), _hex * 0.22, Color("5e5042"))
					draw_circle(p + Vector2(6, -4), _hex * 0.18, Color("8b7a62"))
				"fog":
					for i in 3:
						draw_circle(p + Vector2(float(i - 1) * 9.0, float(i % 2) * 6.0 - 3.0), _hex * 0.25, Color(1, 1, 1, 0.6))
	# muzzle smoke at the firing ship
	for fl in _flash:
		var a: float = 1.0 - fl[2] / 0.35
		draw_circle(fl[0], 6.0 + 18.0 * (1.0 - a), Color(1, 1, 1, a * 0.7))
		draw_circle(fl[0], 5.0 * a, Color(1.0, 0.8, 0.35, a))
	# wrecks tumbling into the clouds
	for sk in _sinking:
		var st: float = sk["t"]
		var tex3: Texture2D = sk["tex"]
		var w3 := _hex * 1.55
		var h3 := w3 * tex3.get_height() / tex3.get_width()
		var c3: Vector2 = sk["p"] + Vector2(st * 10.0, st * st * 40.0)
		var flipx := 1.0 if sk["mine"] else -1.0
		draw_set_transform(c3, st * 0.6 * flipx, Vector2(flipx, 1.0))
		draw_texture_rect(tex3, Rect2(-Vector2(w3, h3) * 0.5, Vector2(w3, h3)), false, Color(0.55, 0.5, 0.48, clampf(1.0 - st / 2.2, 0.0, 1.0)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		for k in 4:
			var sm := c3 + Vector2(sin(k * 2.1) * 10.0, -st * 30.0 * (k + 1) * 0.4)
			draw_circle(sm, 6.0 + st * 6.0, Color(0.3, 0.28, 0.3, 0.35 * (1.0 - st / 2.2)))
	# units
	for u in battle.b["units"]:
		if u["status"] != "ok":
			continue
		var uid := int(u["id"])
		var p2: Vector2 = _pos.get(uid, hex_center(int(u["col"]), int(u["row"]))) + Vector2(0, sin(_t * 1.8 + uid * 1.3) * 2.0)
		var tex: Texture2D = _ship_tex[u["type"]]
		var w := _hex * 1.55
		var h := w * tex.get_height() / tex.get_width()
		var mine := int(u["side"]) == 0
		if uid == cur_id:
			var pulse := 0.5 + 0.5 * sin(_t * 5.0)
			draw_circle(p2, _hex * (0.78 + 0.08 * pulse), Color(UiKit.BRASS if mine else UiKit.TERRA, 0.35 + 0.25 * pulse))
		if _targets.has(uid):
			draw_arc(p2, _hex * 0.8, 0.0, TAU, 32, Color(UiKit.TERRA, 0.9), 3.0, true)
		draw_set_transform(p2 + Vector2(0, h * 0.42), 0.0, Vector2(1.0, 0.3))
		draw_circle(Vector2.ZERO, w * 0.38, Color(0.1, 0.2, 0.25, 0.18))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		var rect := Rect2(p2 - Vector2(w, h) * 0.5 + Vector2(0, -6), Vector2(w, h))
		if mine:
			draw_texture_rect(tex, rect, false, Color(1, 1, 1, 1) if not u["taken"] else Color(0.9, 0.95, 1.0))
		else:
			draw_set_transform(Vector2(p2.x * 2.0, 0.0), 0.0, Vector2(-1.0, 1.0))
			draw_texture_rect(tex, rect, false, Color(0.85, 0.8, 0.85))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		# bars
		var bw := _hex * 1.3
		var bx := p2.x - bw * 0.5
		var by := p2.y + h * 0.5 - 2.0
		draw_rect(Rect2(bx, by, bw, 5), Color(0, 0, 0, 0.35))
		draw_rect(Rect2(bx, by, bw * float(u["hp"]) / maxf(1.0, float(u["hp_max"])), 5), UiKit.UP if mine else UiKit.TERRA)
		draw_rect(Rect2(bx, by + 6, bw * float(u["crew"]) / maxf(1.0, float(u["crew_max"])), 3), Color(UiKit.BRASS, 0.9))
		if u["flag"]:
			draw_string(font, Vector2(bx - 2, by - h - 2), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiKit.BRASS if mine else UiKit.TERRA)
		if u["defend"]:
			draw_arc(p2, _hex * 0.7, 0.0, TAU, 24, Color(UiKit.JADE, 0.8), 2.0, true)
		if int(u["morale"]) < 35:
			draw_string(font, Vector2(bx + bw - 14, by - h - 2), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, UiKit.TERRA)
		draw_string(font, Vector2(bx, by + 22), u["name"], HORIZONTAL_ALIGNMENT_LEFT, bw + 20, 11, UiKit.INK if mine else Color("6b2f2f"))
	# cannonballs on a shallow arc, then the explosion and splinters
	for s in _shots:
		var q: float = s["t"] / 0.32
		var bp: Vector2 = s["a"].lerp(s["b"], q) + Vector2(0, -sin(q * PI) * _hex * 0.9)
		for k in 3:
			var q2 := maxf(0.0, q - 0.06 * (k + 1))
			draw_circle(s["a"].lerp(s["b"], q2) + Vector2(0, -sin(q2 * PI) * _hex * 0.9), 4.0 - k, Color(1, 1, 1, 0.5 - k * 0.12))
		draw_circle(bp, 4.5, Color("2b2a2e"))
	for bm in _booms:
		var bt: float = bm["t"]
		var bpp: Vector2 = bm["p"]
		var fade := 1.0 - bt / 0.9
		draw_circle(bpp, _hex * (0.3 + bt * 0.8), Color(1.0, 0.55, 0.2, fade * 0.55))
		draw_circle(bpp, _hex * (0.18 + bt * 0.4), Color(1.0, 0.9, 0.5, fade * 0.8))
		var rs := RandomNumberGenerator.new()
		rs.seed = int(bm["seed"])
		for k in 7:
			var ang := rs.randf() * TAU
			var spd := rs.randf_range(40, 90)
			var dp := bpp + Vector2(cos(ang), sin(ang) - 0.6) * spd * bt + Vector2(0, 120.0 * bt * bt)
			draw_rect(Rect2(dp, Vector2(4, 2.5)), Color(0.35, 0.25, 0.15, fade))
		for k in 3:
			draw_circle(bpp + Vector2((k - 1) * 12.0, -bt * 30.0), 8.0 + bt * 14.0, Color(0.35, 0.33, 0.35, fade * 0.4))
	# floating texts
	for f in _floats:
		if f["t"] < 0.0:
			continue
		var a2 := clampf(1.2 - f["t"], 0.0, 1.0)
		var pos: Vector2 = f["pos"] + Vector2(0, -28.0 * f["t"])
		draw_string(font, pos + Vector2(1, 1), f["text"], HORIZONTAL_ALIGNMENT_CENTER, 200, 18, Color(1, 1, 1, a2 * 0.8))
		draw_string(font, pos, f["text"], HORIZONTAL_ALIGNMENT_CENTER, 200, 18, Color(f["col"], a2))
	# edges label
	draw_string(font, Vector2(_board.position.x + 6, _board.position.y + 18), "◀ 我方（在这两列内可撤退）", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(UiKit.INK, 0.7))
	draw_string(font, Vector2(_board.end.x - 170, _board.position.y + 18), "云盗 ▶", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(UiKit.TERRA, 0.8))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A sky above the cloud sea: sun, distant floating isles and slow clouds under the hex board.
func _draw_backdrop() -> void:
	var steps := 16
	for i in steps:
		var k := float(i) / float(steps - 1)
		draw_rect(Rect2(0, size.y * float(i) / float(steps), size.x, size.y / float(steps) + 2.0), Color("7fa6bd").lerp(Color("e8dccb"), k))
	draw_circle(Vector2(size.x * 0.62, size.y * 0.16), 60, Color(1.0, 0.93, 0.7, 0.35))
	draw_circle(Vector2(size.x * 0.62, size.y * 0.16), 34, Color(1.0, 0.95, 0.8, 0.8))
	# distant isles
	var isles := [Vector2(0.12, 0.22), Vector2(0.35, 0.14), Vector2(0.78, 0.25), Vector2(0.52, 0.3)]
	for i in isles.size():
		var ip: Vector2 = isles[i] * size + Vector2(0, sin(_t * 0.4 + i) * 3.0)
		var r := 26.0 + i * 6.0
		var col := Color(0.45, 0.55, 0.62, 0.45)
		draw_colored_polygon(PackedVector2Array([ip + Vector2(-r, 0), ip + Vector2(r, 0), ip + Vector2(r * 0.3, r * 1.1), ip + Vector2(-r * 0.25, r * 0.8)]), col)
		draw_colored_polygon(PackedVector2Array([ip + Vector2(-r, 1), ip + Vector2(-r * 0.6, -r * 0.4), ip + Vector2(0, -r * 0.55), ip + Vector2(r * 0.7, -r * 0.3), ip + Vector2(r, 1)]), Color(0.5, 0.62, 0.6, 0.45))
	# drifting cloud banks
	for c in _bg_clouds:
		var cx := fposmod(float(c["x"]) + _t * float(c["sp"]), 1.2) - 0.1
		var cp := Vector2(cx * size.x, float(c["y"]) * size.y)
		var r2: float = c["r"]
		var a := 0.12 + 0.2 * float(c["y"])
		draw_circle(cp + Vector2(0, r2 * 0.2), r2, Color(0.75, 0.8, 0.86, a * 0.5))
		draw_circle(cp, r2 * 0.8, Color(1, 1, 1, a))
		draw_circle(cp + Vector2(r2 * 0.7, r2 * 0.15), r2 * 0.55, Color(1, 1, 1, a))
		draw_circle(cp + Vector2(-r2 * 0.7, r2 * 0.2), r2 * 0.5, Color(1, 1, 1, a))


func _hex_points(p: Vector2, scale: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 7:
		var ang := deg_to_rad(60.0 * float(i) - 30.0)
		pts.append(p + Vector2(cos(ang), sin(ang)) * _hex * 0.96 * scale)
	return pts


func _hex_poly(p: Vector2, col: Color) -> void:
	var pts := _hex_points(p, 1.0)
	pts.remove_at(6)
	draw_colored_polygon(pts, col)
