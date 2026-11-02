extends Control
## Game shell: title screen, HUD, port panel, fleet list, dialogs, tutorial and the time loop.

const SAVE_PATH := "user://save.json"
const SPEEDS := [0, 1, 3, 8]          # days per second
const MapView := preload("res://scripts/ui/map_view.gd")

var sim: Sim
var speed_idx := 1
var _acc := 0.0
var _last_day := -1
var _flag_docked := true
var _game_on := false
var _port := ""                  # port shown in the side panel
var _tab := 0
var _modal_open := false

# nodes
var map: Control
var hud: Control
var top_gold: Label
var top_net: Label
var top_date: Label
var top_storm: Label
var top_debt: Label
var rival_box: HBoxContainer
var speed_btns := []
var side: PanelContainer
var side_body: VBoxContainer
var fleet_box: VBoxContainer
var toast_box: VBoxContainer
var tut_panel: PanelContainer
var tut_label: Label
var crisis_label: Label
var modal_layer: Control
var hover_card: PanelContainer
var _sfx := {}
var _sfx_players := []


func _ready() -> void:
	theme = UiKit.build_theme()
	RenderingServer.set_default_clear_color(Color("cfe0e3"))
	for n in ["coin", "click", "sail", "bell", "gong", "bad", "page"]:
		_sfx[n] = load("res://assets/sfx/%s.wav" % n)
	for i in 4:
		var ap := AudioStreamPlayer.new()
		ap.volume_db = -8.0
		add_child(ap)
		_sfx_players.append(ap)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_show_title()
	if OS.get_environment("YUNHAI_SHOTS") != "":
		load("res://tests/shot_runner.gd").new().run(self)


func sfx(name: String) -> void:
	if not _sfx.has(name):
		return
	for ap in _sfx_players:
		if not ap.playing:
			ap.stream = _sfx[name]
			ap.play()
			return


# =================================================================== title

func _clear_ui() -> void:
	for c in get_children():
		if c in _sfx_players:
			continue
		remove_child(c)
		c.queue_free()


func _show_title() -> void:
	_game_on = false
	_clear_ui()
	var bg := TextureRect.new()
	bg.texture = UiKit.scene_art("title")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var shade := ColorRect.new()
	shade.color = Color(0.95, 0.92, 0.84, 0.0)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCH, 0.95), UiKit.BRASS, 8, 1, 30))
	card.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	card.position = Vector2(90, 0)
	add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(560, 0)
	card.add_child(v)
	v.add_child(UiKit.label("AIRSHIP TRADE  ·  霞市篇  ·  0.1", 13, UiKit.BRASS, true))
	v.add_child(UiKit.label("云海商盟", 72, UiKit.INK, true))
	v.add_child(UiKit.para("大地沉入云海之后，人们住在浮空岛上，靠飞艇沿气流往来。老水手说，十年后初风暴将席卷霞市。率领灯油行会跑商、扩张船队、经营产业，赶在对手之前点亮三层灯塔。", 17))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	row.add_child(UiKit.button("  新的一局  ", func(): _start(false)))
	var cont := UiKit.button("继续航程", func(): _start(true), true)
	cont.disabled = not FileAccess.file_exists(SAVE_PATH)
	row.add_child(cont)
	row.add_child(UiKit.button("怎么玩", _show_help, true))
	await get_tree().process_frame
	card.position = Vector2(90, size.y - card.size.y - 70)


func _show_help() -> void:
	_modal("怎么玩", "", [
		"· 低买高卖：每个港口有两种特产（便宜）和两种需求（昂贵）。同一条路线跑多了，价格会被你自己压平，要不断寻找新路线。",
		"· 时间：空格暂停，1/2/3 切换速度。旗舰抵港时自动暂停。",
		"· 扩张：赚到钱后在船坞买船，给新船设自动航线，让它替你跑商。",
		"· 灯塔：把指定物资运回母港千旗市，再支付金币开工。三层全部建成即胜利。",
		"· 失败：金币为负超过 30 天会破产；对手先点亮灯冠，或第 10 年冬天风暴来临时没有建完，也都算失败。",
	], [["明白了", func(): _close_modal()]])


# =================================================================== game start

func _start(load_save: bool) -> void:
	sim = Sim.new()
	if load_save:
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f == null or not sim.from_json(f.get_as_text()):
			sim.new_game()
	else:
		sim.new_game()
	sim.message.connect(_toast)
	sim.game_over.connect(func(_r): _show_end())
	_build_game()
	_game_on = true
	_last_day = sim.s["day"]
	_flag_docked = sim.docked(sim.flagship())
	_open_port(sim.flagship()["port"] if _flag_docked else GameData.HOUSES[GameData.PLAYER]["home"])
	speed_idx = 0 if not load_save else 1
	_refresh_speed()
	if not load_save:
		_modal("灯油行会 · 第 1 年 春", "story_letter", [
			"你是灯油行会的当家霍照野。行会只剩一艘货艇「飞云号」和 12,000 金。",
			"十年后初风暴将至。白塔议士与铁誓舰团都在抢建灯塔，谁先点亮灯冠，谁就是云海盟主。",
			"先从一笔小生意开始：在千旗市买入特产丝云绸，运到需要它的港口卖掉。",
		], [["起航", func(): _close_modal()]])
	_update_tutorial()


func _build_game() -> void:
	_clear_ui()
	map = MapView.new()
	map.sim = sim
	map.set_anchors_preset(Control.PRESET_FULL_RECT)
	map.offset_top = 64
	map.offset_right = -572
	map.port_clicked.connect(_on_port_clicked)
	map.port_hovered.connect(_on_port_hovered)
	add_child(map)
	_build_topbar()
	# side panel
	side = PanelContainer.new()
	side.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	side.offset_left = -560
	side.offset_top = 76
	side.offset_bottom = -12
	side.offset_right = -12
	add_child(side)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	side_body = VBoxContainer.new()
	side_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(side_body)
	# fleet panel
	var fp := PanelContainer.new()
	fp.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	fp.position = Vector2(12, 0)
	fp.grow_vertical = Control.GROW_DIRECTION_BEGIN
	fp.custom_minimum_size = Vector2(430, 0)
	fp.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCH, 0.94), Color(UiKit.BRASS, 0.55), 8, 1, 12))
	add_child(fp)
	fleet_box = VBoxContainer.new()
	fp.add_child(fleet_box)
	fp.resized.connect(func(): fp.position.y = size.y - fp.size.y - 12)
	# tutorial
	tut_panel = PanelContainer.new()
	tut_panel.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.INK, 0.92), UiKit.BRASS, 6, 1, 12))
	tut_panel.custom_minimum_size = Vector2(440, 0)
	tut_panel.position = Vector2(16, 78)
	add_child(tut_panel)
	tut_label = UiKit.para("", 16, Color("f6efdc"))
	tut_label.custom_minimum_size = Vector2(410, 0)
	tut_panel.add_child(tut_label)
	crisis_label = UiKit.label("", 18, Color.WHITE, true)
	var cp := PanelContainer.new()
	cp.add_theme_stylebox_override("panel", UiKit.box(UiKit.TERRA, Color.TRANSPARENT, 6, 0, 10))
	cp.add_child(crisis_label)
	cp.set_anchors_preset(Control.PRESET_CENTER_TOP)
	cp.position.y = 76
	cp.visible = false
	cp.name = "Crisis"
	add_child(cp)
	toast_box = VBoxContainer.new()
	toast_box.position = Vector2(size.x - 572 - 412, 78)
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_box)
	hover_card = PanelContainer.new()
	hover_card.add_theme_stylebox_override("panel", UiKit.box(Color("fffaf0"), UiKit.BRASS, 6, 1, 10))
	hover_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_card.visible = false
	add_child(hover_card)
	modal_layer = Control.new()
	modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modal_layer)
	_refresh_all()


func _build_topbar() -> void:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UiKit.box(UiKit.INK, Color.TRANSPARENT, 0, 0, 10))
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 64)
	add_child(bar)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	bar.add_child(h)
	h.add_child(UiKit.icon(UiKit.sprite("emblems", 0), 40))
	h.add_child(UiKit.label("灯油行会", 22, Color("f3e3b3"), true))
	var gold_box := HBoxContainer.new()
	gold_box.add_theme_constant_override("separation", 6)
	gold_box.add_child(UiKit.icon(UiKit.sprite("resources", 2), 30))
	top_gold = UiKit.label("", 22, Color("f6efdc"), true)
	gold_box.add_child(top_gold)
	top_net = UiKit.label("", 15, Color("cfe7d6"))
	gold_box.add_child(top_net)
	gold_box.tooltip_text = "金币与上月净收支"
	h.add_child(gold_box)
	top_debt = UiKit.label("", 15, Color("f2b8a6"))
	h.add_child(top_debt)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(sp)
	rival_box = HBoxContainer.new()
	rival_box.add_theme_constant_override("separation", 14)
	h.add_child(rival_box)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 0)
	top_date = UiKit.label("", 16, Color("f6efdc"), true)
	top_storm = UiKit.label("", 13, Color("e9c98a"))
	dv.add_child(top_date)
	dv.add_child(top_storm)
	h.add_child(dv)
	var sb := HBoxContainer.new()
	sb.add_theme_constant_override("separation", 4)
	speed_btns.clear()
	for i in SPEEDS.size():
		var b := UiKit.button("暂停" if i == 0 else "%d×" % SPEEDS[i], func(): _set_speed(i), true)
		b.custom_minimum_size = Vector2(46, 0)
		b.tooltip_text = "暂停（空格）" if i == 0 else "每秒 %d 天（按 %d）" % [SPEEDS[i], i]
		sb.add_child(b)
		speed_btns.append(b)
	h.add_child(sb)
	h.add_child(UiKit.button("灯塔", func(): _open_port(GameData.HOUSES[GameData.PLAYER]["home"], 4), true))
	h.add_child(UiKit.button("账簿", _show_ledger, true))
	h.add_child(UiKit.button("菜单", _show_menu, true))


# =================================================================== loop

func _process(delta: float) -> void:
	if not _game_on:
		return
	if not _modal_open and SPEEDS[speed_idx] > 0 and not sim.blocked():
		_acc += delta * SPEEDS[speed_idx]
		var steps := 0
		while _acc >= 1.0 and steps < 12 and not sim.blocked():
			_acc -= 1.0
			steps += 1
			sim.advance_day()
			if _after_day():
				_acc = 0.0
				break
		sim.s["frac"] = _acc
	_refresh_top()


## Returns true when time should stop (arrival, event, ending).
func _after_day() -> bool:
	var stop := false
	var fl := sim.flagship()
	var now_docked := not fl.is_empty() and sim.docked(fl)
	if now_docked and not _flag_docked:
		sfx("bell")
		_set_speed(0)
		_open_port(fl["port"], 0)
		stop = true
	_flag_docked = now_docked
	if sim.s["event"] != null:
		sfx("page")
		_show_event()
		stop = true
	if sim.s["day"] % GameData.DAYS_MONTH == 0:
		_save()
	if sim.s["day"] != _last_day:
		_last_day = sim.s["day"]
		_refresh_side_soft()
		_refresh_fleet()
		_update_tutorial()
	return stop or sim.s["over"] != null


func _unhandled_input(event: InputEvent) -> void:
	if not _game_on or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_SPACE:
			_set_speed(0 if speed_idx != 0 else 1)
		KEY_1:
			_set_speed(1)
		KEY_2:
			_set_speed(2)
		KEY_3:
			_set_speed(3)
		KEY_ESCAPE:
			if _modal_open:
				_close_modal()


func _set_speed(i: int) -> void:
	speed_idx = i
	_refresh_speed()


func _refresh_speed() -> void:
	for i in speed_btns.size():
		var b: Button = speed_btns[i]
		b.add_theme_stylebox_override("normal", UiKit.box(UiKit.BRASS if i == speed_idx else Color(UiKit.PARCH_DARK, 0.9), Color(UiKit.BRASS, 0.7), 5, 1, 7))


# =================================================================== refresh

func _refresh_all() -> void:
	_refresh_top()
	_refresh_side()
	_refresh_fleet()


func _refresh_top() -> void:
	var h := sim.house()
	top_gold.text = UiKit.money(h["gold"])
	var net: float = h.get("last_net", 0.0)
	top_net.text = ("上月 %+s" % UiKit.money(net)) if sim.s["day"] >= 30 else ""
	top_net.add_theme_color_override("font_color", Color("a8dcb8") if net >= 0 else Color("f2b8a6"))
	top_debt.text = ("欠款 %s" % UiKit.money(h["debt"])) if h["debt"] > 0.5 else ""
	top_date.text = GameData.date_text(sim.s["day"])
	var left: int = GameData.END_DAY - int(sim.s["day"])
	top_storm.text = "距初风暴 %d 年 %d 天" % [left / GameData.DAYS_YEAR, left % GameData.DAYS_YEAR]
	if rival_box.get_child_count() == 0:
		for hid in GameData.HOUSE_IDS:
			var hb := HBoxContainer.new()
			hb.add_theme_constant_override("separation", 4)
			hb.add_child(UiKit.icon(UiKit.sprite("emblems", GameData.HOUSES[hid]["emblem"]), 26))
			var l := UiKit.label("", 15, Color("f6efdc"))
			l.name = "L"
			hb.add_child(l)
			hb.name = hid
			hb.tooltip_text = "%s 的灯塔进度" % GameData.HOUSES[hid]["name"]
			rival_box.add_child(hb)
	for hid in GameData.HOUSE_IDS:
		var lh: Dictionary = sim.house(hid)["lh"]
		var l2: Label = rival_box.get_node(hid).get_node("L")
		l2.text = "破产" if sim.house(hid)["bankrupt"] else ("灯塔 %d/3%s" % [lh["stage"], "↑" if lh["building"] else ""])
	var crisis: int = h["crisis"]
	var cp := get_node_or_null("Crisis")
	if cp:
		cp.visible = crisis > 0
		crisis_label.text = "债务危机：%d 天内金币必须转正，否则破产" % (GameData.CRISIS_DAYS - crisis)


func _refresh_side_soft() -> void:
	# prices move daily; rebuild only the parts that show numbers
	if _tab in [0, 3, 4]:
		_refresh_side()


func _refresh_fleet() -> void:
	UiKit.clear(fleet_box)
	var head := HBoxContainer.new()
	head.add_child(UiKit.label("船队 %d/%d" % [sim.ships_of().size(), GameData.MAX_SHIPS], 18, UiKit.INK, true))
	fleet_box.add_child(head)
	for sh in sim.ships_of():
		var row := HBoxContainer.new()
		row.add_child(UiKit.icon(UiKit.sprite("ships", GameData.SHIPS[sh["type"]]["sprite"]), 40))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := "%s%s · %s" % ["★ " if sh["flagship"] else "", sh["name"], GameData.SHIPS[sh["type"]]["name"]]
		v.add_child(UiKit.label(title, 16, UiKit.INK, true))
		var st := ""
		if sim.docked(sh):
			st = "停靠 %s" % GameData.port_name(sh["port"])
		else:
			st = "前往 %s · 剩 %d 天" % [GameData.port_name(sh["to"]), maxi(0, int(sh["arrive"]) - int(sim.s["day"]))]
		st += " · 货 %d/%d" % [sim.cargo_used(sh), sim.cargo_cap(sh)]
		v.add_child(UiKit.label(st, 14, UiKit.MUTED))
		if sh["route"] != null:
			var r: Dictionary = sh["route"]
			var rt := "航线 %s ⇄ %s · %s" % [GameData.port_name(r["a"]), GameData.port_name(r["b"]), GameData.good_name(r["good"])]
			if r.has("total"):
				rt += " · 累计 %+s" % UiKit.money(r["total"])
			if r.has("stalled"):
				rt += " · 停滞：" + r["stalled"]
			v.add_child(UiKit.label(rt, 13, UiKit.JADE))
		row.add_child(v)
		var id: int = sh["id"]
		if not sh["flagship"]:
			row.add_child(UiKit.button("航线", func(): _show_route_dialog(id), true))
		elif sim.docked(sh):
			row.add_child(UiKit.button("查看", func(): _open_port(sh["port"], 0), true))
		fleet_box.add_child(row)


# =================================================================== port panel

func _on_port_hovered(pid: String) -> void:
	if pid == "" or _modal_open:
		hover_card.visible = false
		return
	UiKit.clear(hover_card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	hover_card.add_child(v)
	v.add_child(UiKit.label(GameData.port_name(pid), 18, UiKit.INK, true))
	var fl := sim.flagship()
	if not fl.is_empty() and sim.docked(fl) and fl["port"] != pid:
		v.add_child(UiKit.label("旗舰前往：%d 天 · 燃晶 %d 金" % [GameData.travel_days(fl["port"], pid, fl["type"]), sim.fuel_cost(fl["type"], fl["port"], pid)], 14, UiKit.JADE, true))
	var it = sim.s["intel"][pid]
	if it == null:
		v.add_child(UiKit.label("尚无行情", 14, UiKit.MUTED))
	else:
		v.add_child(UiKit.label("行情 %d 天前" % (int(sim.s["day"]) - int(it["day"])), 13, UiKit.MUTED))
		var goods: Array = []
		if not fl.is_empty():
			goods = fl["cargo"].keys()
		for g in GameData.PORTS[pid]["want"]:
			if not g in goods:
				goods.append(g)
		for g in goods:
			var line := "%s 卖 %d" % [GameData.good_name(g), int(it["prices"][g][1])]
			if not fl.is_empty() and fl["cargo"].has(g):
				var m := int(it["prices"][g][1]) - int(fl["cargo"][g]["cost"])
				line += "（货舱 %d 件，每件 %+d）" % [int(fl["cargo"][g]["qty"]), m]
			v.add_child(UiKit.label(line, 14, UiKit.INK))
	hover_card.visible = true
	hover_card.reset_size()
	var mp := get_local_mouse_position() + Vector2(18, 18)
	hover_card.position = Vector2(minf(mp.x, size.x - 572 - hover_card.size.x - 8), minf(mp.y, size.y - hover_card.size.y - 8))


func _on_port_clicked(pid: String) -> void:
	_open_port(pid, 0 if _port != pid else _tab)


func _open_port(pid: String, tab: int = -1) -> void:
	_port = pid
	if tab >= 0:
		_tab = tab
	map.selected_port = pid
	_refresh_side()


func _refresh_side() -> void:
	if side_body == null or _port == "":
		return
	UiKit.clear(side_body)
	var p: Dictionary = GameData.PORTS[_port]
	var fl := sim.flagship()
	var here: bool = not fl.is_empty() and sim.docked(fl) and fl["port"] == _port
	# header
	var head := HBoxContainer.new()
	head.add_child(UiKit.icon(UiKit.sprite("map_islands", p["island"]), 74))
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := p["name"] as String
	for hid in GameData.HOUSE_IDS:
		if GameData.HOUSES[hid]["home"] == _port:
			title += " · %s母港" % GameData.HOUSES[hid]["name"]
	hv.add_child(UiKit.label(title, 24, UiKit.INK, true))
	hv.add_child(UiKit.para(p["desc"], 14, UiKit.MUTED))
	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation", 4)
	tags.add_child(UiKit.label("特产", 13, UiKit.UP, true))
	for g in p["make"]:
		tags.add_child(UiKit.icon(UiKit.sprite("goods", GameData.GOODS[g]["icon"]), 22))
		tags.add_child(UiKit.label(GameData.good_name(g), 13))
	tags.add_child(UiKit.label("  需求", 13, UiKit.DOWN, true))
	for g in p["want"]:
		tags.add_child(UiKit.icon(UiKit.sprite("goods", GameData.GOODS[g]["icon"]), 22))
		tags.add_child(UiKit.label(GameData.good_name(g), 13))
	hv.add_child(tags)
	head.add_child(hv)
	side_body.add_child(head)
	if not fl.is_empty() and sim.docked(fl) and not here:
		var days := GameData.travel_days(fl["port"], _port, fl["type"])
		var fc := sim.fuel_cost(fl["type"], fl["port"], _port)
		var go := UiKit.button("旗舰起航前往此港 · %d 天 · 燃晶 %d 金" % [days, fc], func(): _sail(_port))
		side_body.add_child(go)
	elif not fl.is_empty() and not sim.docked(fl):
		side_body.add_child(UiKit.label("旗舰航行中：前往 %s，剩 %d 天" % [GameData.port_name(fl["to"]), int(fl["arrive"]) - int(sim.s["day"])], 15, UiKit.JADE, true))
	# tabs
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	var names := ["交易", "船坞", "产业", "酒馆·银行", "灯塔"]
	for i in names.size():
		if i == 4 and _port != GameData.HOUSES[GameData.PLAYER]["home"]:
			continue
		var b := UiKit.button(names[i], func(): _tab = i; _refresh_side(), i != _tab)
		tabs.add_child(b)
	side_body.add_child(tabs)
	if _tab == 4 and _port != GameData.HOUSES[GameData.PLAYER]["home"]:
		_tab = 0
	match _tab:
		0: _tab_trade(here)
		1: _tab_yard(here)
		2: _tab_industry()
		3: _tab_tavern()
		4: _tab_lighthouse()


func _tab_trade(here: bool) -> void:
	var fl := sim.flagship()
	var intel = sim.s["intel"][_port]
	if here:
		var cap := HBoxContainer.new()
		cap.add_child(UiKit.label("货舱 %d / %d" % [sim.cargo_used(fl), sim.cargo_cap(fl)], 15, UiKit.INK, true))
		var bar := ProgressBar.new()
		bar.max_value = sim.cargo_cap(fl)
		bar.value = sim.cargo_used(fl)
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(160, 12)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cap.add_child(bar)
		side_body.add_child(cap)
	elif intel == null:
		side_body.add_child(UiKit.para("还没有这个港口的行情。派船到访，或在酒馆买情报。", 15, UiKit.MUTED))
		return
	else:
		side_body.add_child(UiKit.label("行情来自 %d 天前（旗舰不在此港，只能查看）" % (int(sim.s["day"]) - int(intel["day"])), 14, UiKit.MUTED))
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	for hd in ["货物", "买价", "卖价", "持有", "最佳去处", ""]:
		grid.add_child(UiKit.label(hd, 13, UiKit.MUTED, true))
	var order: Array = []
	var p: Dictionary = GameData.PORTS[_port]
	for g in p["make"]:
		order.append(g)
	for g in p["want"]:
		order.append(g)
	for g in GameData.GOOD_IDS:
		if not g in order:
			order.append(g)
	for g in order:
		var gh := HBoxContainer.new()
		gh.add_theme_constant_override("separation", 4)
		gh.add_child(UiKit.icon(UiKit.sprite("goods", GameData.GOODS[g]["icon"]), 30))
		var tag := ""
		var tcol := UiKit.INK
		if g in p["make"]:
			tag = "产"
			tcol = UiKit.UP
		elif g in p["want"]:
			tag = "需"
			tcol = UiKit.DOWN
		var nl := UiKit.label(GameData.good_name(g), 15, tcol, tag != "")
		nl.custom_minimum_size = Vector2(62, 0)
		gh.add_child(nl)
		grid.add_child(gh)
		var bp: int = sim.buy_price(_port, g) if here else int(intel["prices"][g][0])
		var spr: int = sim.sell_price(_port, g) if here else int(intel["prices"][g][1])
		var base: float = GameData.GOODS[g]["base"]
		grid.add_child(UiKit.label(str(bp), 15, UiKit.UP if bp < base * 0.85 else (UiKit.DOWN if bp > base * 1.2 else UiKit.INK), true))
		var trend := ""
		var prev = sim.s.get("intel_prev", {}).get(_port)
		if prev != null:
			var old_s: int = int(prev["prices"][g][1])
			if spr > old_s * 1.03:
				trend = " ▲"
			elif spr < old_s * 0.97:
				trend = " ▼"
		var sl := UiKit.label(str(spr) + trend, 15, UiKit.UP if spr > base * 1.2 else UiKit.INK, true)
		if trend != "":
			sl.tooltip_text = "上次到访时卖价 %d" % int(prev["prices"][g][1])
			sl.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(sl)
		var held := 0
		var avg := 0.0
		if here and fl["cargo"].has(g):
			held = fl["cargo"][g]["qty"]
			avg = fl["cargo"][g]["cost"]
		grid.add_child(UiKit.label(("%d" % held) + ((" @%d" % int(avg)) if held > 0 else ""), 14))
		# best known destination
		var best := _best_known_sell(g, _port)
		var cost_ref := avg if held > 0 else float(bp)
		if best.is_empty():
			grid.add_child(UiKit.label("—", 13, UiKit.MUTED))
		else:
			var margin := int(best["price"] - cost_ref)
			var bl := UiKit.label("%s %+d" % [GameData.port_name(best["port"]), margin], 13, UiKit.UP if margin > 0 else UiKit.MUTED)
			bl.tooltip_text = "已知最高卖价 %d（%d 天前的行情）" % [best["price"], best["age"]]
			bl.mouse_filter = Control.MOUSE_FILTER_PASS
			grid.add_child(bl)
		var btns := HBoxContainer.new()
		btns.add_theme_constant_override("separation", 3)
		if here:
			var gg: String = g
			var b1 := UiKit.button("买10", func(): _trade(true, gg, 10), true)
			var b2 := UiKit.button("买满", func(): _trade(true, gg, 9999), true)
			var b3 := UiKit.button("卖光", func(): _trade(false, gg, 9999), held == 0)
			b1.disabled = sim.cargo_used(fl) >= sim.cargo_cap(fl) or sim.house()["gold"] < bp
			b2.disabled = b1.disabled
			b3.disabled = held == 0
			for b in [b1, b2, b3]:
				b.add_theme_font_size_override("font_size", 13)
				b.custom_minimum_size = Vector2(0, 30)
				btns.add_child(b)
		grid.add_child(btns)
	side_body.add_child(grid)
	if here and _port == GameData.HOUSES[GameData.PLAYER]["home"] and sim.house()["lh"]["stage"] < 3:
		side_body.add_child(UiKit.button("把货舱里的灯塔物资交给工地", func(): _act(sim.deliver_mats(fl["id"])), true))


func _best_known_sell(g: String, exclude: String) -> Dictionary:
	var best := {}
	for pid in GameData.PORT_IDS:
		if pid == exclude:
			continue
		var it = sim.s["intel"][pid]
		if it == null:
			continue
		var price: int = int(it["prices"][g][1])
		if best.is_empty() or price > best["price"]:
			best = {"port": pid, "price": price, "age": int(sim.s["day"]) - int(it["day"])}
	return best


func _tab_yard(here: bool) -> void:
	side_body.add_child(UiKit.para("买船后它会停在这里。给非旗舰设自动航线，它就会替你往返跑商。船队上限 %d 艘；每艘船每月要付薪水和维护。" % GameData.MAX_SHIPS, 14, UiKit.MUTED))
	for t in GameData.SHIPS:
		var d: Dictionary = GameData.SHIPS[t]
		var row := HBoxContainer.new()
		row.add_child(UiKit.icon(UiKit.sprite("ships", d["sprite"]), 64))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UiKit.label("%s  ·  %s 金" % [d["name"], UiKit.money(d["price"])], 17, UiKit.INK, true))
		v.add_child(UiKit.label("货舱 %d · 航速 %.2f · 燃晶 %d/天 · 月薪 %d" % [d["cargo"], d["speed"], d["fuel_day"] * GameData.FUEL_PRICE, d["wage"]], 13, UiKit.MUTED))
		row.add_child(v)
		var tt: String = t
		var b := UiKit.button("购买", func(): _act(sim.buy_ship(tt, _port)); _refresh_fleet())
		b.disabled = sim.house()["gold"] < d["price"] or sim.ships_of().size() >= GameData.MAX_SHIPS
		row.add_child(b)
		side_body.add_child(row)
	var mine := sim.ships_of().filter(func(x): return sim.docked(x) and x["port"] == _port and not x["flagship"])
	if not mine.is_empty():
		side_body.add_child(HSeparator.new())
		for sh in mine:
			var id: int = sh["id"]
			var r2 := HBoxContainer.new()
			var l := UiKit.label("%s（%s）· 回收 %s 金" % [sh["name"], GameData.SHIPS[sh["type"]]["name"], UiKit.money(GameData.SHIPS[sh["type"]]["price"] * 0.6)], 15)
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r2.add_child(l)
			r2.add_child(UiKit.button("出售", func(): _act(sim.sell_ship(id)); _refresh_fleet(), true))
			side_body.add_child(r2)


func _tab_industry() -> void:
	var p: Dictionary = GameData.PORTS[_port]
	var w: Dictionary = sim.s["ports"][_port]["workshops"]
	var lvl: int = int(w.get(GameData.PLAYER, 0))
	side_body.add_child(UiKit.label("工坊 · 当前 %d 级" % lvl, 18, UiKit.INK, true))
	side_body.add_child(UiKit.para("投资工坊会让本港特产（%s、%s）增产、价格更低，每月分红，你在这里买货也更便宜（每级 −2.5%%）。" % [GameData.good_name(p["make"][0]), GameData.good_name(p["make"][1])], 14, UiKit.MUTED))
	if lvl < 3:
		var cost: int = GameData.WORKSHOP_COST[lvl]
		var b := UiKit.button("升到 %d 级 · %s 金 · 月分红 %d" % [lvl + 1, UiKit.money(cost), GameData.WORKSHOP_DIVIDEND[lvl]], func(): _act(sim.invest(_port)))
		b.disabled = sim.house()["gold"] < cost
		side_body.add_child(b)
	for hid in GameData.HOUSE_IDS:
		if hid != GameData.PLAYER and int(w.get(hid, 0)) > 0:
			side_body.add_child(UiKit.label("%s 在此有 %d 级工坊" % [GameData.HOUSES[hid]["name"], int(w[hid])], 14, UiKit.MUTED))


func _tab_tavern() -> void:
	side_body.add_child(UiKit.label("酒馆", 18, UiKit.INK, true))
	side_body.add_child(UiKit.para("消息贩子能告诉你所有港口此刻的价格。行情会变，过期的情报要小心。", 14, UiKit.MUTED))
	var b := UiKit.button("买全部港口行情 · 400 金", func(): _act(sim.buy_intel()))
	b.disabled = sim.house()["gold"] < 400
	side_body.add_child(b)
	side_body.add_child(HSeparator.new())
	var h := sim.house()
	side_body.add_child(UiKit.label("商会银行", 18, UiKit.INK, true))
	side_body.add_child(UiKit.para("欠款 %s 金 · 月息 2%% · 可再借 %s 金。金币为负时银行会自动放贷，额度用完就会进入债务危机。" % [UiKit.money(h["debt"]), UiKit.money(maxf(0.0, sim.loan_limit() - h["debt"]))], 14, UiKit.MUTED))
	var row := HBoxContainer.new()
	for amt in [5000, 20000]:
		var a: int = amt
		row.add_child(UiKit.button("借 %s" % UiKit.money(a), func(): _act(sim.take_loan(a)), true))
	for amt in [5000, 20000]:
		var a2: int = amt
		var rb := UiKit.button("还 %s" % UiKit.money(a2), func(): _act(sim.repay(a2)), true)
		rb.disabled = h["debt"] <= 0.5
		row.add_child(rb)
	side_body.add_child(row)


func _tab_lighthouse() -> void:
	var lh: Dictionary = sim.house()["lh"]
	var stage: int = lh["stage"]
	var art := UiKit.icon(UiKit.sprite("lighthouse", 0 if stage == 0 else GameData.LIGHTHOUSE[stage - 1]["sprite"]), 150)
	side_body.add_child(art)
	if stage >= GameData.LIGHTHOUSE.size():
		side_body.add_child(UiKit.label("三层灯塔已全部落成。", 18, UiKit.UP, true))
		return
	var st: Dictionary = GameData.LIGHTHOUSE[stage]
	side_body.add_child(UiKit.label("第 %d 层 · %s" % [stage + 1, st["name"]], 20, UiKit.INK, true))
	if lh["building"]:
		side_body.add_child(UiKit.label("施工中，还剩 %d 天。" % (int(lh["end"]) - int(sim.s["day"])), 16, UiKit.JADE, true))
	else:
		for g in st["mats"]:
			var have: int = int(lh["mats"].get(g, 0))
			var need: int = st["mats"][g]
			var row := HBoxContainer.new()
			row.add_child(UiKit.icon(UiKit.sprite("goods", GameData.GOODS[g]["icon"]), 30))
			var l := UiKit.label("%s %d / %d" % [GameData.good_name(g), have, need], 15, UiKit.UP if have >= need else UiKit.INK, have >= need)
			l.custom_minimum_size = Vector2(150, 0)
			row.add_child(l)
			var bar := ProgressBar.new()
			bar.max_value = need
			bar.value = have
			bar.show_percentage = false
			bar.custom_minimum_size = Vector2(200, 12)
			bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			row.add_child(bar)
			side_body.add_child(row)
		side_body.add_child(UiKit.label("开工费 %s 金 · 工期 %d 天" % [UiKit.money(st["gold"]), st["days"]], 15))
		var docked_home := sim.ships_of().filter(func(x): return sim.docked(x) and x["port"] == _port)
		for sh in docked_home:
			var id: int = sh["id"]
			side_body.add_child(UiKit.button("从 %s 交付物资" % sh["name"], func(): _act(sim.deliver_mats(id)), true))
		var go := UiKit.button("支付 %s 金开工" % UiKit.money(st["gold"]), func(): _act(sim.start_lighthouse()))
		go.disabled = not sim.mats_ready() or sim.house()["gold"] < st["gold"]
		side_body.add_child(go)
	side_body.add_child(HSeparator.new())
	side_body.add_child(UiKit.label("对手进度", 16, UiKit.INK, true))
	for hid in GameData.HOUSE_IDS:
		if hid == GameData.PLAYER:
			continue
		var rl: Dictionary = sim.house(hid)["lh"]
		var txt := "%s：%d/3 层%s" % [GameData.HOUSES[hid]["name"], rl["stage"], "（施工中）" if rl["building"] else ""]
		if sim.house(hid)["bankrupt"]:
			txt = "%s：已破产" % GameData.HOUSES[hid]["name"]
		side_body.add_child(UiKit.label(txt, 15, UiKit.MUTED))


# =================================================================== actions

func _act(res: Dictionary) -> void:
	_toast(res["msg"], "good" if res["ok"] else "bad")
	_refresh_all()
	_update_tutorial()


func _trade(is_buy: bool, g: String, qty: int) -> void:
	var fl := sim.flagship()
	var res := sim.buy(fl["id"], g, qty) if is_buy else sim.sell(fl["id"], g, qty)
	if res["ok"] and not is_buy and int(res["profit"]) > 0:
		_float_profit(int(res["profit"]))
		sfx("coin")
	elif res["ok"]:
		sfx("click")
	_act(res)


func _sail(dest: String) -> void:
	var fl := sim.flagship()
	var res := sim.depart(fl["id"], dest)
	_act(res)
	if res["ok"]:
		sfx("sail")
		_flag_docked = false
		if speed_idx == 0:
			_set_speed(1)


func _float_profit(v: int) -> void:
	var l := UiKit.label("+%s 金" % UiKit.money(v), 34, UiKit.UP, true)
	l.add_theme_color_override("font_outline_color", Color.WHITE)
	l.add_theme_constant_override("outline_size", 8)
	l.position = Vector2(size.x * 0.5 - 80, size.y * 0.45)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 90, 1.4)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.4).set_delay(0.5)
	tw.tween_callback(l.queue_free)


func _toast(text: String, kind: String = "info") -> void:
	if toast_box == null or text == "":
		return
	if kind == "bad":
		sfx("bad")
	elif "落成" in text and "灯油行会" in text:
		sfx("gong")
	if kind == "month":
		return
	var col: Color = {"info": UiKit.INK, "good": UiKit.JADE, "bad": UiKit.TERRA, "major": UiKit.BRASS}.get(kind, UiKit.INK)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCH, 0.97), col, 6, 2, 10))
	var l := UiKit.para(text, 15, UiKit.INK)
	l.custom_minimum_size = Vector2(380, 0)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_box.add_child(p)
	toast_box.position = Vector2(size.x - 572 - 412, 78)
	while toast_box.get_child_count() > 4:
		var old := toast_box.get_child(0)
		toast_box.remove_child(old)
		old.queue_free()
	var tw := create_tween()
	tw.tween_interval(5.0)
	tw.tween_property(p, "modulate:a", 0.0, 0.8)
	tw.tween_callback(p.queue_free)


# =================================================================== dialogs

func _modal(title: String, art: String, lines: Array, buttons: Array, width: int = 640) -> VBoxContainer:
	_close_modal()
	_modal_open = true
	modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.12, 0.16, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_layer.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(UiKit.PARCH, UiKit.BRASS, 8, 2, 22))
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.custom_minimum_size = Vector2(width, 0)
	panel.add_child(v)
	if art != "":
		var img := TextureRect.new()
		img.texture = UiKit.scene_art(art)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.custom_minimum_size = Vector2(width, 240)
		img.clip_contents = true
		v.add_child(img)
	v.add_child(UiKit.label(title, 26, UiKit.INK, true))
	for line in lines:
		v.add_child(UiKit.para(line, 17))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	for b in buttons:
		row.add_child(UiKit.button(b[0], b[1], b.size() > 2 and b[2]))
	v.add_child(row)
	return v


func _close_modal() -> void:
	if modal_layer == null:
		return
	UiKit.clear(modal_layer)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_open = false


func _show_event() -> void:
	var ev: Dictionary = sim.s["event"]
	var btns := []
	for i in ev["choices"].size():
		btns.append([ev["choices"][i]["label"], _choose_event.bind(i), i > 0])
	_modal(ev["title"], ev["art"] if ev["art"] != "" else "explore_scene", [ev["text"]], btns)


func _choose_event(idx: int) -> void:
	var res := EventBook.resolve(sim, idx)
	_close_modal()
	_refresh_all()
	if res["msg"] != "":
		_toast(res["msg"], "info")
	if sim.s["event"] != null:
		_show_event()


func _confirm_route(ship_id: int, og: OptionButton, oa: OptionButton, ob: OptionButton) -> void:
	var a: String = GameData.PORT_IDS[oa.selected]
	var b: String = GameData.PORT_IDS[ob.selected]
	if a == b:
		_toast("A 港和 B 港不能相同。", "bad")
		return
	_act(sim.set_route(ship_id, {"a": a, "b": b, "good": GameData.GOOD_IDS[og.selected]}))
	_close_modal()
	_refresh_fleet()


func _show_route_dialog(ship_id: int) -> void:
	var sh := sim.ship(ship_id)
	var cur = sh["route"]
	var v := _modal("自动航线 · %s" % sh["name"], "", ["这艘船会在 A 港买入货物，运到 B 港卖出，然后返回 A 港，循环往复。价格不划算时它会少买或空跑。"], [], 620)
	var grid := GridContainer.new()
	grid.columns = 2
	var og := OptionButton.new()
	for g in GameData.GOOD_IDS:
		og.add_item(GameData.good_name(g))
	var oa := OptionButton.new()
	var ob := OptionButton.new()
	for pid in GameData.PORT_IDS:
		oa.add_item(GameData.port_name(pid))
		ob.add_item(GameData.port_name(pid))
	if cur != null:
		og.select(GameData.GOOD_IDS.find(cur["good"]))
		oa.select(GameData.PORT_IDS.find(cur["a"]))
		ob.select(GameData.PORT_IDS.find(cur["b"]))
	else:
		og.select(GameData.GOOD_IDS.find("silk"))
		oa.select(GameData.PORT_IDS.find("qianqi"))
		ob.select(GameData.PORT_IDS.find("muxia"))
	grid.add_child(UiKit.label("货物", 16))
	grid.add_child(og)
	grid.add_child(UiKit.label("买入港 A", 16))
	grid.add_child(oa)
	grid.add_child(UiKit.label("卖出港 B", 16))
	grid.add_child(ob)
	v.add_child(grid)
	var est := UiKit.para("", 15, UiKit.JADE)
	v.add_child(est)
	var upd := func(_i = 0):
		var g: String = GameData.GOOD_IDS[og.selected]
		var a: String = GameData.PORT_IDS[oa.selected]
		var b: String = GameData.PORT_IDS[ob.selected]
		var ia = sim.s["intel"][a]
		var ib = sim.s["intel"][b]
		if a == b:
			est.text = "A 港和 B 港不能相同。"
		elif ia == null or ib == null:
			est.text = "缺少其中一个港口的行情，无法估算。"
		else:
			var margin := int(ib["prices"][g][1]) - int(ia["prices"][g][0])
			var days := GameData.travel_days(a, b, sh["type"]) * 2
			est.text = "按已知行情：每件差价 %+d，往返约 %d 天，满载 %d 件。" % [margin, days, sim.cargo_cap(sh)]
	og.item_selected.connect(upd)
	oa.item_selected.connect(upd)
	ob.item_selected.connect(upd)
	upd.call()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_child(UiKit.button("取消", func(): _close_modal(), true))
	if cur != null:
		row.add_child(UiKit.button("清除航线", func(): _act(sim.set_route(ship_id, {})); _close_modal(); _refresh_fleet(), true))
	row.add_child(UiKit.button("确认航线", _confirm_route.bind(ship_id, og, oa, ob)))
	v.add_child(row)


func _show_ledger() -> void:
	var h := sim.house()
	var lines := [
		"金币 %s · 欠款 %s · 净资产 %s" % [UiKit.money(h["gold"]), UiKit.money(h["debt"]), UiKit.money(sim.net_worth())],
		"上月净收支 %+s · 每月固定开支约 %s（薪水、维护、利息）" % [UiKit.money(h.get("last_net", 0.0)), UiKit.money(h.get("last_upkeep", 0.0))],
		"累计成交 %d 笔 · 累计利润 %s · 最佳单笔 %s" % [sim.s["stats"]["trades"], UiKit.money(sim.s["stats"]["profit"]), UiKit.money(sim.s["stats"]["best_trade"])],
	]
	for hid in GameData.HOUSE_IDS:
		if hid != GameData.PLAYER:
			lines.append("%s：%d 艘船 · 灯塔 %d/3%s" % [GameData.HOUSES[hid]["name"], sim.ships_of(hid).size(), sim.house(hid)["lh"]["stage"], " · 已破产" if sim.house(hid)["bankrupt"] else ""])
	_modal("账簿", "", lines, [["关闭", func(): _close_modal()]])


func _show_menu() -> void:
	_modal("菜单", "", ["游戏每月自动存档。"], [
		["保存", func(): _save(); _toast("已保存。", "good"); _close_modal(), true],
		["回到标题", func(): _save(); _close_modal(); _show_title(), true],
		["继续", func(): _close_modal()],
	])


func _show_end() -> void:
	_set_speed(0)
	var o: Dictionary = sim.s["over"]
	var lines := [o["text"],
		"用时 %s · 净资产 %s · 灯塔 %d/3 · 陆青的故事 %d/3" % [GameData.date_text(o["day"]), UiKit.money(sim.net_worth()), sim.house()["lh"]["stage"], sim.s["story"]],
		"评分 %d" % o["score"]]
	_modal(("胜利 · " if o["win"] else "") + o["title"], "story_loyalty" if o["win"] else "explore_scene", lines, [
		["回到标题", func(): _close_modal(); _show_title(), true],
		["再来一局", func(): _close_modal(); _start(false)],
	])
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _save() -> void:
	if sim == null or sim.s["over"] != null:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(sim.to_json())


# =================================================================== tutorial

func _update_tutorial() -> void:
	if tut_panel == null:
		return
	var step: int = sim.s["tutorial"]
	var fl := sim.flagship()
	var home: String = GameData.HOUSES[GameData.PLAYER]["home"]
	# advance
	var advanced := true
	while advanced:
		advanced = false
		match step:
			0:
				if sim.cargo_used(fl) > 0 or not sim.docked(fl):
					step = 1; advanced = true
			1:
				if not sim.docked(fl) or sim.s["stats"]["trades"] > 0:
					step = 2; advanced = true
			2:
				if sim.s["stats"]["trades"] > 0:
					step = 3; advanced = true
			3:
				if sim.ships_of().size() >= 2:
					step = 4; advanced = true
			4:
				if sim.ships_of().any(func(x): return x["route"] != null):
					step = 5; advanced = true
			5:
				if sim.house()["lh"]["stage"] > 0 or sim.house()["lh"]["building"]:
					step = 6; advanced = true
	sim.s["tutorial"] = step
	map.highlight_port = ""
	var text := ""
	match step:
		0:
			text = "① 在千旗市的「交易」页，给丝云绸点「买满」。绿色的「产」表示本港特产，价格便宜。"
		1:
			text = "② 点击地图上闪光的暮霞港，再点「旗舰起航」。暮霞港需要丝云绸，会出高价。"
			map.highlight_port = "muxia"
		2:
			text = "③ 抵港后点「卖光」。看看「最佳去处」一列：它按你知道的行情告诉你每种货运到哪里最赚。" if sim.docked(fl) else "③ 航行中……右上角可以加速。抵港时会自动暂停。"
		3:
			text = "④ 继续跑商攒钱。金币够了就去任意港口的「船坞」买第二艘船（货艇 12,000 金）。"
		4:
			text = "⑤ 在左下角船队里点新船的「航线」，让它自己往返跑一条赚钱的路线。"
		5:
			text = "⑥ 灯塔第一层需要精钢件 80、云麻 120 和 40,000 金。把物资运回千旗市，在「灯塔」页交付并开工。"
			map.highlight_port = home if sim.mats_ready() else ""
		_:
			text = ""
	tut_panel.visible = text != ""
	tut_label.text = text
