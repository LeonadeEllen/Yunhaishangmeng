extends Control
## Game shell: title screen, HUD, port panel, fleet list, dialogs, tutorial and the time loop.

const SAVE_PATH := "user://save.json"
const SPEEDS := [0, 1, 3, 8]          # days per second
const MapView := preload("res://scripts/ui/map_view.gd")
const TownView := preload("res://scripts/ui/town_view.gd")
const BattleView := preload("res://scripts/ui/battle_view.gd")

var sim: Sim
var speed_idx := 1
var _acc := 0.0
var _last_day := -1
var _flag_docked := true
var _game_on := false
var _port := ""                  # port shown in the side panel
var _spot := ""                  # fog point shown in the side panel (then _port is "")
var region_btn: Button
var _tab := 0
var _modal_open := false
var _difficulty := 1
var _gold_shown := 0.0
var _lh_seen := 0
var _crown_seen := false
var _trade_mode := 0      # 0 fleet<->market, 1 post<->market, 2 fleet<->post
var _trade_qty := 10
var _build_plot := -1
var _in_town := false
var _town_kind := ""        # building the protagonist is standing in ("" = street)

# nodes
var map: Control
var town: Control
var battle_view: Control
var hero_btn: Button
var crew_btn: Button
var hud: Control
var top_gold: Label
var top_net: Label
var top_date: Label
var top_rep: Label
var top_debt: Label
var rival_box: HBoxContainer
var speed_btns := []
var side: PanelContainer
var side_body: VBoxContainer
var fleet_box: VBoxContainer
var toast_box: VBoxContainer
var tut_panel: PanelContainer
var tut_label: Label
var hint_panel: PanelContainer
var hint_label: Label
var tut_skip: Button
var fade: ColorRect              # town enter/leave transition (round 23)
var _fx_tweens: Array = []       # cutscene tweens, killed when the modal closes
var _season_col := Color.WHITE
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
	var music := AudioStreamPlayer.new()
	var ms: AudioStreamOggVorbis = load("res://assets/sfx/music.ogg")
	ms.loop = true
	music.stream = ms
	music.volume_db = -13.0
	music.name = "Music"
	AudioServer.add_bus()
	var bi := AudioServer.bus_count - 1
	AudioServer.set_bus_name(bi, "Music")
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 900.0
	AudioServer.add_bus_effect(bi, lp)
	AudioServer.set_bus_effect_enabled(bi, 0, false)
	music.bus = "Music"
	add_child(music)
	_sfx_players.append(music)   # keeps it alive across screen changes
	music.play()
	for i in 4:
		var ap := AudioStreamPlayer.new()
		ap.volume_db = -8.0
		add_child(ap)
		_sfx_players.append(ap)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_show_title()
	if OS.get_environment("YUNHAI_SHOTS") != "":
		load("res://tests/shot_runner.gd").new().run(self)
	elif OS.get_environment("YUNHAI_TOWNSHOTS") != "":
		load("res://tests/town_shots.gd").new().run(self)


## Tutorial highlight: brass outline + gentle pulse on the exact button to press.
func _pulse(b: Button) -> void:
	var sb := UiKit.box(Color("f3d58a"), UiKit.BRASS, 5, 3, 8)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_color_override("font_color", UiKit.INK)
	var tw := b.create_tween().set_loops()
	tw.tween_property(b, "modulate", Color(1.15, 1.1, 0.9), 0.5)
	tw.tween_property(b, "modulate", Color.WHITE, 0.5)


func _tut_step() -> int:
	return int(sim.s["tutorial"]) if sim != null else -1


## A veteran save: the lighthouse is already under way, so the middle steps are moot.
func _tut_far() -> bool:
	return int(sim.house()["lh"]["stage"]) > 0 or bool(sim.house()["lh"]["building"])


func sfx(name: String) -> void:
	if not _sfx.has(name):
		return
	for ap in _sfx_players:
		if ap.name != "Music" and not ap.playing:
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
	v.add_child(UiKit.para("大地沉入云海之后，人们住在浮空岛上，靠飞艇沿气流往来。老水手说，十年后初风暴将席卷霞市。率领一家商会跑商、扩张船队、经营产业，赶在对手之前点亮三层灯塔。", 17))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	row.add_child(UiKit.button("  新的一局  ", _pick_house))
	var cont := UiKit.button("继续航程", func(): _start(true), true)
	cont.disabled = not FileAccess.file_exists(SAVE_PATH)
	row.add_child(cont)
	row.add_child(UiKit.button("怎么玩", _show_help, true))
	await get_tree().process_frame
	card.position = Vector2(90, size.y - card.size.y - 70)


func _pick_house() -> void:
	if modal_layer == null:
		modal_layer = Control.new()
		modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
		modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(modal_layer)
	var v := _modal("选择你的商会", "", ["三家商会同时争夺霞市盟主。你选一家，另外两家就是对手。"], [["返回", func(): _close_modal(), true]], 980)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	for hid in GameData.HOUSE_IDS:
		var d: Dictionary = GameData.HOUSES[hid]
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiKit.box(Color("fbf5e6"), Color(UiKit.BRASS, 0.7), 8, 1, 14))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 6)
		card.add_child(cv)
		var top := HBoxContainer.new()
		top.add_child(UiKit.icon(UiKit.portrait("hero_" + hid), 96))
		var tv := VBoxContainer.new()
		tv.add_theme_constant_override("separation", 2)
		var nm := HBoxContainer.new()
		nm.add_child(UiKit.icon(UiKit.sprite("emblems", d["emblem"]), 28))
		nm.add_child(UiKit.label(d["name"], 21, UiKit.INK, true))
		tv.add_child(nm)
		tv.add_child(UiKit.label("当家 · %s" % d["leader"], 14, UiKit.MUTED))
		tv.add_child(UiKit.label("母港 · %s" % GameData.port_name(d["home"]), 14, UiKit.MUTED))
		top.add_child(tv)
		cv.add_child(top)
		cv.add_child(UiKit.label("特长：" + d["perk_text"], 15, UiKit.JADE, true))
		var pitch := UiKit.para(d["pitch"], 14)
		pitch.custom_minimum_size = Vector2(260, 0)
		cv.add_child(pitch)
		var h2: String = hid
		var spacer := Control.new()
		spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cv.add_child(spacer)
		cv.add_child(UiKit.button("率领%s" % d["name"], func(): _close_modal(); _start(false, h2, _difficulty)))
		row.add_child(card)
	v.add_child(row)
	v.move_child(row, v.get_child_count() - 2)
	var dr := HBoxContainer.new()
	dr.add_child(UiKit.label("难度", 16, UiKit.INK, true))
	var od := OptionButton.new()
	for t in ["轻松：对手经商稍弱", "标准", "困难：对手经商更精明"]:
		od.add_item(t)
	od.select(_difficulty)
	od.item_selected.connect(func(i): _difficulty = i)
	dr.add_child(od)
	v.add_child(dr)
	v.move_child(dr, v.get_child_count() - 2)


func _show_help() -> void:
	var first := [
		"· 低买高卖：每座城天然出产两种招牌货（便宜），常年需要三四种货（昂贵）。同一条路线跑多了，价格会被你自己压平。",
		"· 时间：空格暂停，1/2/3 切换速度。旗舰抵港时自动暂停。左上角的教程会一步步带你走到灯塔基座，不想看可以跳过；第一次遇到新东西时，教程下面会多一条只说一次的提示。",
		"· 名声：赚钱、完成委托、建工坊都会提升名声。名声等级决定你能买几艘船、能不能开商馆、能买哪一阶图纸。",
		"· 委托与悬赏：酒馆的委托板张贴求购单，先把货送到的商会拿走全部酬金；云盗闹得凶时城主会出钱请商会剿匪。",
		"· 航行与空战：季风随季节转向，顺风航程更短。载货航行可能遇上云盗：应战、交过路费或甩开。空战是回合制六角格：炮击、接舷、修补、防御、撤退，主角升级学会指挥战术。",
		"· 城镇：旗舰进港后会走进城里。WASD 走动，点建筑进门办事，Esc 回到海图。路人会透露行情，伙伴也会在街上走动。",
		"· 主角：卖货、航行、委托和建坊都涨经验，升级得能力点，点顶栏的名字分配到航海 / 交易 / 魅力。",
		"· 伙伴：酒馆、船坞、行会里能遇到 14 位各有专长的人物，付安家费招入商会，每月发薪。安排岗位（航海长、账房、炮术长、接舷队长、船长）吃他们的能力加成；一起航行、打赢云盗、送礼都涨好感。",
		"· 产业：在城主府买地契、在工匠行会买图纸，然后在商馆页的地块上建工坊。原料 → 加工品 → 精品，越高阶利润越厚。",
		"· 里程碑：账簿里有一张 18 步的清单，从第一笔买卖到灯冠。做到一件勾一件，名声 +20，消息栏告诉你下一件是什么。",
	]
	var later := [
		"· 伙伴的故事：好感到 30 / 60 / 100 触发三章个人剧情，走完专长更强。好感到 60 的伙伴会托你办一件私事（限期送一批货到某港，在伙伴面板或那座港的酒馆交付），办成有谢礼、名声和好感，误期伤感情；办成后好感到 80 还有第二件更大的托付（送货、同行到某港或打赢一场空战），办成的伙伴从此不领薪水。两位、三位彼此相熟的伙伴之间也会有他们自己的场景。",
		"· 对手：灯油行会靠跑商、铁誓舰团靠船队（船便宜、航速快、载货多）、白塔议士靠产业（工坊便宜、产地多产）。云盗对谁都下手，对手的船也会被劫。点顶栏的商会名随时看对手情报。",
		"· 相遇：旗舰停进对手船所在的港口时，对手的当家可能来打招呼：赛船赌金、当众论道赌名声、向他们买地契和图纸、买通港务拖住他们的船，或者只是喝一杯。",
		"· 盟与敌：三家之间各有一条关系。喝酒、送礼、买图纸拉近，赛船论道输的一方记仇，收购工坊、买通港务最伤。关系到 20 可在对手面板提议结盟，对手关系好时也会主动提：盟友不抢你的工坊、你开工建灯塔时出一份钱、灯节带贺礼、在港时交换行情。关系跌到 −40 或你主动翻脸就是宿敌：收购他们的工坊便宜 25%，赢他们名声 ×1.5，但他们会盯上你的工坊，灯节必来挑战。两家对手之间同样会结盟或翻脸：落后的两家往往走到一起对付领头的，领头的招人嫉恨。盟友还有三样用处：当家在港时能把一艘空船借给你 60 天（付租金，编入船队一起跑一起打，丢了要赔一半船价）；你收购工坊时手头宽裕的盟友出三成；盟友周转不开时会写信求援，帮不帮都记在关系上。",
		"· 灯节：每年开春灯节，三项颁奖（赛船冠军看最快的船、年度商王看一年身家涨幅、建设之光看恩主城数），奖金与名声，并回顾各家这一年：三位当家各有一句话，你的伙伴里也有人上台。灯节 12 天里甜霞果、丝云绸、霞果酒卖价 +15%。灯节夜里对手的当家可能来约一场赛船或论道，赌注和名声都比平日大，谢绝不丢分。",
		"· 会馆：在老家的商馆页扩建商会总部（三级）：伙伴上限、每月名声、伙伴薪水折扣，最高一级船队上限 +1。",
		"· 城建：在任何城主府出资修码头（补给更省、修船更快）、集市（行情恢复更快）、学堂（本城工坊增产），每项三级，全城受益。出资最多的商会是本城恩主：买货更便宜、每月得名声、城中立像。对手有钱时也会出资来争。",
		"· 探索：名声「商董」后可在任何行会赞助探险队（40,000 金），海图上出现通往东云域的「风隙」。旗舰和单独行动的测绘艇能去雾里的「?」处探索（船队里有测绘艇时看得更远）：发现城市、遗迹、漂流物，每个发现都会让周围的雾散开一些。东边的城天然出产西边没人做的加工品，长途跑一趟利润厚，云盗也多一倍。",
		"· 灯塔：三层灯塔是云海盟主的象征，不建也可以一直玩下去。金币为负超过 30 天会破产；对手破产时，他们的当家会来告别。",
		"· 云海大工程：灯塔建到灯廊之后，灯塔页下方出现四项大工程：灯标网（云盗更少）、环海天梯（航程更短）、万商大学堂（工坊增产）、盟主金殿（只有盟主能建，其他商会每月交盟贡）。每项只有一家能建成，全云海受益，建造者受益更多，盟友会出一成；对手有了闲钱也会抢着建，所以灯冠之后的较量不会停。",
	]
	var v := _modal("怎么玩", "", [], [["明白了", func(): _close_modal()]], 780)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(760, 620)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_child(UiKit.label("第一年就会遇到的", 18, UiKit.INK, true))
	for line in first:
		var pa := UiKit.para(line, 15)
		pa.custom_minimum_size = Vector2(740, 0)
		col.add_child(pa)
	col.add_child(HSeparator.new())
	col.add_child(UiKit.label("之后才会遇到的", 18, UiKit.INK, true))
	for line in later:
		var pb := UiKit.para(line, 15)
		pb.custom_minimum_size = Vector2(740, 0)
		col.add_child(pb)
	scroll.add_child(col)
	v.add_child(scroll)
	v.move_child(scroll, v.get_child_count() - 2)


# =================================================================== game start

func _start(load_save: bool, house_id: String = "lamp", difficulty: int = 1) -> void:
	sim = Sim.new()
	if load_save:
		var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f == null or not sim.from_json(f.get_as_text()):
			sim.new_game(0, house_id, difficulty)
	else:
		sim.new_game(0, house_id, difficulty)
	sim.message.connect(_toast)
	sim.game_over.connect(func(_r): _show_end())
	_build_game()
	_game_on = true
	_gold_shown = sim.house()["gold"]
	_lh_seen = sim.house()["lh"]["stage"]
	_crown_seen = sim.s["crown"] != null
	_last_day = sim.s["day"]
	_flag_docked = sim.docked(sim.flagship())
	_open_port(sim.flagship()["port"] if _flag_docked else GameData.HOUSES[sim.pid()]["home"])
	speed_idx = 0 if not load_save else 1
	_refresh_speed()
	if sim.s["battle"] != null and sim.battle != null:
		_open_battle()
	elif sim.s["encounter"] != null:
		_show_encounter()
	if not load_save:
		var me: Dictionary = GameData.HOUSES[sim.pid()]
		var rivals := []
		for hid in GameData.HOUSE_IDS:
			if hid != sim.pid():
				rivals.append(GameData.HOUSES[hid]["name"])
		var tg := _tutorial_goal()
		_modal("%s · 第 1 年 春" % me["name"], "story_letter", [
			"你是%s的当家%s。商会只剩一艘货艇「飞云号」和 12,000 金。特长：%s。" % [me["name"], me["leader"], me["perk_text"]],
			"%s与%s都在争当云海盟主。先点亮三层灯塔的商会得盟主之位，但没有期限，这片云海随你经营。" % rivals,
			"先从一笔小生意开始：在%s买入特产%s，运到需要它的%s卖掉。" % [GameData.port_name(me["home"]), GameData.good_name(tg["good"]), GameData.port_name(tg["dest"])],
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
	region_btn = UiKit.button("东云域 ▶", _toggle_region)
	region_btn.tooltip_text = "在西边的霞市和东边的云域之间切换海图"
	region_btn.visible = false
	add_child(region_btn)
	town = TownView.new()
	town.sim = sim
	town.set_anchors_preset(Control.PRESET_FULL_RECT)
	town.offset_top = 64
	town.offset_right = -572
	town.visible = false
	town.building_entered.connect(_on_building_entered)
	add_child(town)
	_in_town = false
	_town_kind = ""
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
	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 8)
	left_col.position = Vector2(16, 78)
	add_child(left_col)
	tut_panel = PanelContainer.new()
	tut_panel.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.INK, 0.92), UiKit.BRASS, 6, 1, 12))
	tut_panel.custom_minimum_size = Vector2(440, 0)
	left_col.add_child(tut_panel)
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 4)
	tut_panel.add_child(tv)
	tut_label = UiKit.para("", 16, Color("f6efdc"))
	tut_label.custom_minimum_size = Vector2(410, 0)
	tv.add_child(tut_label)
	var trow := HBoxContainer.new()
	trow.alignment = BoxContainer.ALIGNMENT_END
	tut_skip = UiKit.button("跳过引导", func(): sim.s["tutorial"] = 9; _update_tutorial(), true)
	tut_skip.add_theme_font_size_override("font_size", 12)
	tut_skip.visible = false
	trow.add_child(tut_skip)
	tv.add_child(trow)
	# one-time hints the first time something new shows up (round 20)
	hint_panel = PanelContainer.new()
	hint_panel.add_theme_stylebox_override("panel", UiKit.box(Color(UiKit.PARCH, 0.97), UiKit.JADE, 6, 2, 12))
	hint_panel.custom_minimum_size = Vector2(440, 0)
	hint_panel.visible = false
	left_col.add_child(hint_panel)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 6)
	hint_panel.add_child(hv)
	hint_label = UiKit.para("", 15, UiKit.INK)
	hint_label.custom_minimum_size = Vector2(410, 0)
	hv.add_child(hint_label)
	var hrow := HBoxContainer.new()
	hrow.alignment = BoxContainer.ALIGNMENT_END
	hrow.add_child(UiKit.button("知道了", func(): hint_panel.visible = false, true))
	hv.add_child(hrow)
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
	battle_view = BattleView.new()
	battle_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	battle_view.visible = false
	battle_view.finished.connect(_on_battle_finished)
	add_child(battle_view)
	modal_layer = Control.new()
	modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(modal_layer)
	fade = ColorRect.new()
	fade.color = Color(0.07, 0.1, 0.13, 0.0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	_refresh_all()


func _build_topbar() -> void:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UiKit.box(UiKit.INK, Color.TRANSPARENT, 0, 0, 10))
	bar.set_anchors_preset(Control.PRESET_TOP_WIDE)
	bar.custom_minimum_size = Vector2(0, 64)
	add_child(bar)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	bar.add_child(h)
	h.add_child(UiKit.icon(UiKit.sprite("emblems", GameData.HOUSES[sim.pid()]["emblem"]), 40))
	h.add_child(UiKit.label(GameData.HOUSES[sim.pid()]["name"], 22, Color("f3e3b3"), true))
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
	hero_btn = UiKit.button("", _show_hero, true)
	hero_btn.tooltip_text = "主角能力与经验"
	h.add_child(hero_btn)
	crew_btn = UiKit.button("", _show_crew, true)
	crew_btn.tooltip_text = "伙伴：岗位、好感与个人剧情"
	h.add_child(crew_btn)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(sp)
	rival_box = HBoxContainer.new()
	rival_box.add_theme_constant_override("separation", 14)
	h.add_child(rival_box)
	var dv := VBoxContainer.new()
	dv.add_theme_constant_override("separation", 0)
	top_date = UiKit.label("", 16, Color("f6efdc"), true)
	top_rep = UiKit.label("", 13, Color("e9c98a"))
	top_rep.mouse_filter = Control.MOUSE_FILTER_PASS
	dv.add_child(top_date)
	dv.add_child(top_rep)
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
	h.add_child(UiKit.button("灯塔", func(): _open_port(GameData.HOUSES[sim.pid()]["home"], 6), true))
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
	if sim.s.get("festival_show") != null:
		sfx("bell")
		_set_speed(0)
		_show_festival()
		stop = true
	elif sim.s.get("discovery") != null:
		sfx("bell")
		_set_speed(0)
		_show_discovery()
		stop = true
	elif now_docked and not _flag_docked:
		sfx("bell")
		_set_speed(0)
		if GameData.PORTS.has(fl["port"]):
			_open_port(fl["port"], 0)
			_enter_town()
		else:
			_open_spot(fl["port"])
		stop = true
	_flag_docked = now_docked
	if int(sim.house()["lh"]["stage"]) > _lh_seen:
		_lh_seen = sim.house()["lh"]["stage"]
		_lighthouse_cutscene(_lh_seen)
		stop = true
	elif sim.s["encounter"] != null:
		sfx("bad")
		_set_speed(0)
		_show_encounter()
		stop = true
	elif sim.s["event"] != null:
		sfx("page")
		_show_event()
		stop = true
	if sim.s["crown"] != null and not _crown_seen:
		_crown_seen = true
		if sim.s["crown"]["hid"] == sim.pid():
			_crown_celebration()
			stop = true
	if sim.s.get("grand_show") != null and not _modal_open:
		var gs: Dictionary = sim.s["grand_show"]
		sim.s["grand_show"] = null
		_grand_ceremony(gs)
		stop = true
	if sim.s["day"] % 90 == 0 and sim.s["day"] > 0:
		var season: String = GameData.SEASONS[(int(sim.s["day"]) % 360) / 90]
		_toast("入%s。%s" % [season, GameData.date_text(sim.s["day"]).split(" · ")[0]], "info")
		_update_mood(true)
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
			elif _in_town:
				_leave_town()
		KEY_E:
			if _in_town and not _modal_open:
				town.try_enter()


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
	var target: float = h["gold"]
	if absf(target - _gold_shown) < 2.0:
		_gold_shown = target
	else:
		_gold_shown = lerpf(_gold_shown, target, 0.18)
	top_gold.text = UiKit.money(_gold_shown)
	top_gold.add_theme_color_override("font_color", Color("f6efdc") if absf(target - _gold_shown) < 2.0 else (Color("a8dcb8") if target > _gold_shown else Color("f2b8a6")))
	var net: float = h.get("last_net", 0.0)
	top_net.text = ("上月 %+s" % UiKit.money(net)) if sim.s["day"] >= 30 else ""
	top_net.add_theme_color_override("font_color", Color("a8dcb8") if net >= 0 else Color("f2b8a6"))
	top_debt.text = ("欠款 %s" % UiKit.money(h["debt"])) if h["debt"] > 0.5 else ""
	top_date.text = GameData.date_text(sim.s["day"])
	_refresh_region_btn()
	var hero: Dictionary = sim.hero()
	hero_btn.text = "%s %d 级%s" % [GameData.HOUSES[sim.pid()]["leader"], int(hero["lvl"]), (" · %d 点" % int(hero["pts"])) if int(hero["pts"]) > 0 else ""]
	hero_btn.tooltip_text = "主角能力与经验" + ("（有 %d 点能力点待分配）" % int(hero["pts"]) if int(hero["pts"]) > 0 else "")
	crew_btn.text = "伙伴 %d" % sim.crew().size()
	crew_btn.visible = not sim.crew().is_empty() or int(hero["lvl"]) >= 2
	if int(hero["pts"]) > 0 and not hero_btn.has_meta("pulsing"):
		hero_btn.set_meta("pulsing", true)
		_pulse(hero_btn)
	elif int(hero["pts"]) == 0 and hero_btn.has_meta("pulsing"):
		hero_btn.remove_meta("pulsing")
	var lvl := sim.rep_level()
	var pts := int(h["rep"])
	if lvl < 6:
		var nxt: int = GameData.REP_LEVELS[lvl]
		top_rep.text = "名声 %s · %d / %d" % [GameData.REP_NAMES[lvl - 1], pts, nxt]
		top_rep.tooltip_text = "下一级「%s」：%s" % [GameData.REP_NAMES[lvl], GameData.REP_UNLOCK[lvl]]
	else:
		top_rep.text = "名声 %s · %d" % [GameData.REP_NAMES[lvl - 1], pts]
		top_rep.tooltip_text = "名声已达顶级。"
	if rival_box.get_child_count() == 0:
		for hid in GameData.HOUSE_IDS:
			var hb := HBoxContainer.new()
			hb.add_theme_constant_override("separation", 4)
			hb.add_child(UiKit.icon(UiKit.sprite("emblems", GameData.HOUSES[hid]["emblem"]), 26))
			var l := UiKit.label("", 15, Color("f6efdc"))
			l.name = "L"
			hb.add_child(l)
			hb.name = hid
			hb.tooltip_text = "%s · 点开看它在做什么" % GameData.HOUSES[hid]["name"]
			hb.mouse_filter = Control.MOUSE_FILTER_STOP
			hb.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			var hh: String = hid
			hb.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT: _show_rival(hh))
			rival_box.add_child(hb)
	for hid in GameData.HOUSE_IDS:
		var lh: Dictionary = sim.house(hid)["lh"]
		var l2: Label = rival_box.get_node(hid).get_node("L")
		var tag := ""
		if hid != sim.pid() and not sim.house(hid)["bankrupt"]:
			var ts := sim.tie_state(hid)
			tag = " · 盟" if ts == "ally" else (" · 敌" if ts == "feud" else "")
		l2.text = "破产" if sim.house(hid)["bankrupt"] else ("灯塔 %d/3%s%s" % [lh["stage"], "↑" if lh["building"] else "", tag])
	var crisis: int = h["crisis"]
	var cp := get_node_or_null("Crisis")
	if cp:
		cp.visible = crisis > 0
		crisis_label.text = "债务危机：%d 天内金币必须转正，否则破产" % (GameData.CRISIS_DAYS - crisis)


func _refresh_side_soft() -> void:
	# prices move daily; rebuild only the parts that show numbers
	if _tab in [0, 2, 3, 5]:
		_refresh_side()


func _refresh_fleet() -> void:
	UiKit.clear(fleet_box)
	var head := HBoxContainer.new()
	var loans := sim.ships_of().size() - sim.own_ships().size()
	head.add_child(UiKit.label("船队 %d/%d%s" % [sim.own_ships().size(), sim.max_ships(), (" · 借 %d" % loans) if loans > 0 else ""], 18, UiKit.INK, true))
	fleet_box.add_child(head)
	var fl := sim.flagship()
	var ordered := sim.fleet_ships(fl)
	for sh in sim.ships_of():
		if not sh in ordered:
			ordered.append(sh)
	for sh in ordered:
		var row := HBoxContainer.new()
		var esc := sim.in_fleet(sh)
		if esc:
			var pad := Control.new()
			pad.custom_minimum_size = Vector2(14, 0)
			row.add_child(pad)
		row.add_child(UiKit.icon(UiKit.sprite("ships", GameData.SHIPS[sh["type"]]["sprite"]), 40 if not esc else 32))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var title := "%s%s · %s%s%s" % ["★ " if sh["flagship"] else ("↳ " if esc else ""), sh["name"], GameData.SHIPS[sh["type"]]["name"], (" · " + GameData.SLOTS[sh.get("slot", "main")]) if esc else "", (" · 借自%s，还 %d 天" % [GameData.HOUSES[sh["loan"]["hid"]]["name"], maxi(0, int(sh["loan"]["until"]) - int(sim.s["day"]))]) if sh.has("loan") else ""]
		v.add_child(UiKit.label(title, 16 if not esc else 14, UiKit.INK, true))
		var st := ""
		if sim.docked(sh):
			st = "停靠 %s" % GameData.port_name(sh["port"])
		else:
			st = "前往 %s · 剩 %d 天" % [GameData.port_name(sh["to"]), maxi(0, int(sh["arrive"]) - int(sim.s["day"]))]
		if sh["flagship"] and ordered.size() > 1 and sim.fleet_ships(fl).size() > 1:
			st += " · 船队货 %d/%d" % [sim.fleet_cargo_used(fl), sim.fleet_cargo_cap(fl)]
		else:
			st += " · 货 %d/%d" % [sim.cargo_used(sh), sim.cargo_cap(sh)]
		if int(sh.get("dmg", 0)) > 0:
			st += " · 战损 %d%%" % int(sh["dmg"])
		v.add_child(UiKit.label(st, 14 if not esc else 12, UiKit.MUTED if int(sh.get("dmg", 0)) == 0 else UiKit.TERRA))
		if sh["route"] != null:
			var r: Dictionary = sh["route"]
			var rt := "航线 " + Sim.route_text(r)
			if r.has("total"):
				rt += " · 累计 %+s" % UiKit.money(r["total"])
			if r.has("stalled"):
				rt += " · 停滞：" + r["stalled"]
			var rl := UiKit.label(rt, 13, UiKit.JADE)
			rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			v.add_child(rl)
		row.add_child(v)
		var id: int = sh["id"]
		if sh["flagship"]:
			if sim.docked(sh):
				row.add_child(UiKit.button("查看", func(): _open_port(sh["port"], 0), true))
		elif esc:
			var lb := UiKit.button("脱队", func(): _act(sim.leave_fleet(id)); _refresh_fleet(); _refresh_side(), true)
			lb.disabled = not sim.docked(sh)
			row.add_child(lb)
		else:
			if not fl.is_empty() and sim.docked(fl) and sim.docked(sh) and sh["port"] == fl["port"] and sh["route"] == null:
				var jb := UiKit.button("随行", func(): _act(sim.join_fleet(id)); _refresh_fleet(); _refresh_side(), true)
				jb.tooltip_text = "编入旗舰队：跟旗舰一起航行，货舱合并使用。"
				row.add_child(jb)
			var rb := UiKit.button("航线", func(): _show_route_dialog(id), true)
			if _tut_step() == 4 and sh["route"] == null:
				_pulse(rb)
			row.add_child(rb)
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
	var fl := sim.flagship()
	if not GameData.PORTS.has(pid):
		var found := sim.spot_found(pid)
		v.add_child(UiKit.label(GameData.SPOTS[pid]["name"] if found else "？ 迷雾中的去处", 18, UiKit.INK, true))
		if not fl.is_empty() and sim.docked(fl) and fl["port"] != pid and not found:
			v.add_child(UiKit.label("旗舰前往探索：%d 天 · 补给 %d 金" % [sim.ship_days(fl, pid), sim.fuel_cost_for(fl, pid)], 14, UiKit.JADE, true))
		hover_card.visible = true
		hover_card.reset_size()
		var mp0 := get_local_mouse_position() + Vector2(18, 18)
		hover_card.position = Vector2(minf(mp0.x, size.x - 572 - hover_card.size.x - 8), minf(mp0.y, size.y - hover_card.size.y - 8))
		return
	v.add_child(UiKit.label(GameData.port_name(pid), 18, UiKit.INK, true))
	if not fl.is_empty() and sim.docked(fl) and fl["port"] != pid:
		v.add_child(UiKit.label("旗舰前往：%d 天 · 补给 %d 金" % [sim.ship_days(fl, pid), sim.fuel_cost_for(fl, pid)], 14, UiKit.JADE, true))
	for c in sim.open_contracts(pid):
		v.add_child(UiKit.label("委托：%s %d 件 → %s 金（剩 %d 天）" % [GameData.good_name(c["good"]), int(c["qty"]), UiKit.money(c["reward"]), int(c["end"]) - int(sim.s["day"])], 14, UiKit.BRASS, true))
	var it = sim.s["intel"][pid]
	if it == null:
		v.add_child(UiKit.label("尚无行情", 14, UiKit.MUTED))
	else:
		v.add_child(UiKit.label("行情 %d 天前" % (int(sim.s["day"]) - int(it["day"])), 13, UiKit.MUTED))
		var fc := sim.fleet_cargo(fl) if not fl.is_empty() else {}
		var goods: Array = fc.keys()
		for g in GameData.PORTS[pid]["want"]:
			if not g in goods:
				goods.append(g)
		for g in goods:
			var line := "%s 卖 %d" % [GameData.good_name(g), int(it["prices"][g][1])]
			if fc.has(g):
				var m := int(it["prices"][g][1]) - int(fc[g]["cost"])
				line += "（货舱 %d 件，每件 %+d）" % [int(fc[g]["qty"]), m]
			v.add_child(UiKit.label(line, 14, UiKit.INK))
	hover_card.visible = true
	hover_card.reset_size()
	var mp := get_local_mouse_position() + Vector2(18, 18)
	hover_card.position = Vector2(minf(mp.x, size.x - 572 - hover_card.size.x - 8), minf(mp.y, size.y - hover_card.size.y - 8))


func _on_port_clicked(pid: String) -> void:
	if GameData.PORTS.has(pid):
		_open_port(pid, 0 if _port != pid else _tab)
	else:
		_open_spot(pid)


func _open_spot(sid: String) -> void:
	_spot = sid
	_port = ""
	map.selected_port = sid
	if _in_town:
		_leave_town()
	_refresh_side()


func _open_port(pid: String, tab: int = -1) -> void:
	_port = pid
	_spot = ""
	if tab >= 0:
		_tab = tab
	map.selected_port = pid
	if _in_town and pid != town.port:
		_leave_town()
	_refresh_side()


## Step off the flagship into the town of the port it is docked at.
func _enter_town() -> void:
	var fl := sim.flagship()
	if fl.is_empty() or not sim.docked(fl) or not GameData.PORTS.has(fl["port"]):
		return
	_port = fl["port"]
	_spot = ""
	map.selected_port = _port
	_in_town = true
	_town_kind = ""
	town.open(_port)
	_fade_through(func():
		town.visible = true
		map.visible = false)
	_refresh_region_btn()
	_refresh_side()


func _leave_town() -> void:
	_in_town = false
	_town_kind = ""
	_fade_through(func():
		town.visible = false
		map.visible = true)
	_refresh_region_btn()
	_refresh_side()


## A short dip to dark between two screens (round 23).
func _fade_through(swap: Callable) -> void:
	if fade == null:
		swap.call()
		return
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.16)
	tw.tween_callback(swap)
	tw.tween_property(fade, "color:a", 0.0, 0.28)


## Music sounds muffled inside a building; the map is tinted by the season (round 23).
func _update_mood(animate: bool = false) -> void:
	var bi := AudioServer.get_bus_index("Music")
	if bi >= 0:
		AudioServer.set_bus_effect_enabled(bi, 0, _in_town and _town_kind != "")
	if map == null or sim == null:
		return
	var season := (int(sim.s["day"]) % GameData.DAYS_YEAR) / 90
	var col: Color = [Color(0.96, 1.0, 0.96), Color(1.0, 0.985, 0.93), Color(1.0, 0.95, 0.88), Color(0.9, 0.94, 1.0)][season]
	if col == _season_col:
		return
	_season_col = col
	if animate:
		create_tween().tween_property(map, "modulate", col, 1.2)
	else:
		map.modulate = col


func _on_building_entered(kind: String) -> void:
	sfx("page")
	_town_kind = kind
	_tab = town.tab_of(kind)
	_build_plot = -1
	_refresh_side()



func _refresh_side() -> void:
	if side_body == null:
		return
	_update_mood()
	if _spot != "":
		UiKit.clear(side_body)
		_spot_panel()
		return
	if _port == "":
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
	if here:
		var tb := HBoxContainer.new()
		tb.add_theme_constant_override("separation", 6)
		if _in_town:
			tb.add_child(UiKit.button("回到海图（Esc）", _leave_town, true))
			if _town_kind != "":
				tb.add_child(UiKit.button("走出%s" % town.kind_name(_town_kind), func(): _town_kind = ""; _refresh_side(), true))
		else:
			var eb := UiKit.button("进城 · 在街上走走", _enter_town)
			eb.tooltip_text = "进入 %s 的街道，点建筑办事。" % p["name"]
			tb.add_child(eb)
		side_body.add_child(tb)
		if _in_town and _town_kind != "":
			side_body.add_child(_interior_strip(_town_kind))
	if not fl.is_empty() and sim.docked(fl) and not here:
		var days := sim.ship_days(fl, _port)
		var fc := sim.fuel_cost_for(fl, _port)
		var go := UiKit.button("旗舰起航前往此港 · %d 天 · 补给 %d 金" % [days, fc], func(): _sail(_port))
		if _tut_step() == 1 and _port == _tutorial_goal()["dest"]:
			_pulse(go)
		side_body.add_child(go)
	elif not fl.is_empty() and not sim.docked(fl):
		side_body.add_child(UiKit.label("旗舰航行中：前往 %s，剩 %d 天" % [GameData.port_name(fl["to"]), int(fl["arrive"]) - int(sim.s["day"])], 15, UiKit.JADE, true))
	# tabs
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	var names := ["交易", "船坞", "商馆", "城主府", "行会", "酒馆", "灯塔"]
	for i in names.size():
		if i == 6 and _port != GameData.HOUSES[sim.pid()]["home"]:
			continue
		var b := UiKit.button(names[i], func(): _tab = i; _build_plot = -1; _refresh_side(), i != _tab)
		b.add_theme_font_size_override("font_size", 15)
		if (_tut_step() == 3 and i == 1 and sim.house()["gold"] >= sim.ship_price("freighter") and _tab != 1) or (_tut_step() == 8 and i == 6 and _tab != 6):
			_pulse(b)
		tabs.add_child(b)
	side_body.add_child(tabs)
	if _tab == 6 and _port != GameData.HOUSES[sim.pid()]["home"]:
		_tab = 0
	match _tab:
		0: _tab_trade(here)
		1: _tab_yard(here)
		2: _tab_post(here)
		3: _tab_hall()
		4: _tab_guild()
		5: _tab_tavern()
		6: _tab_lighthouse()


## Side panel for a point in the eastern fog: what is known about it and the way to get there.
func _spot_panel() -> void:
	var sp: Dictionary = GameData.SPOTS[_spot]
	var found := sim.spot_found(_spot)
	var fl := sim.flagship()
	var here: bool = not fl.is_empty() and sim.docked(fl) and fl["port"] == _spot
	var head := HBoxContainer.new()
	head.add_child(UiKit.icon(UiKit.scene_art("explore_scene"), 74))
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 2)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hv.add_child(UiKit.label(("%s · %s" % [GameData.SPOT_KIND_NAMES[sp["kind"]], sp["name"]]) if found else "？ 迷雾中的去处", 24, UiKit.INK, true))
	hv.add_child(UiKit.para(sp.get("desc", "") if found else "雾里隐约有东西：也许是一座城，也许是遗迹或漂流的船。只有旗舰能去探个明白。", 14, UiKit.MUTED))
	if found and sp.has("found"):
		hv.add_child(UiKit.para(sp["found"], 13, UiKit.INK))
	head.add_child(hv)
	side_body.add_child(head)
	if here:
		side_body.add_child(UiKit.label("你的船队停在这里。点海图上的「?」继续探索，或回到任何一座城。", 14, UiKit.JADE, true))
	elif found:
		side_body.add_child(UiKit.label("已经探过了，不必再去。", 14, UiKit.MUTED))
	else:
		# the flagship and any survey boat sailing on its own can go and look
		var any := false
		for o in sim.ships_of(sim.pid()):
			if not sim.docked(o) or o["port"] == _spot or sim.in_fleet(o) or not (o["flagship"] or o["type"] == "survey"):
				continue
			any = true
			var ok := sim.sail_ok(o, _spot)
			var days := sim.ship_days(o, _spot)
			var fc := sim.fuel_cost_for(o, _spot)
			var oid: int = o["id"]
			var go := UiKit.button("%s%s 前往探索 · %d 天 · 补给 %d 金" % ["旗舰 " if o["flagship"] else "测绘艇 ", o["name"], days, fc], func(): _sail_ship(oid, _spot))
			if not ok["ok"]:
				go.disabled = true
				go.tooltip_text = ok["msg"]
			side_body.add_child(go)
		if not any and not fl.is_empty() and not sim.docked(fl):
			side_body.add_child(UiKit.label("旗舰航行中：前往 %s，剩 %d 天" % [GameData.port_name(fl["to"]), int(fl["arrive"]) - int(sim.s["day"])], 15, UiKit.JADE, true))
		elif not any:
			side_body.add_child(UiKit.label("没有能出发的船。旗舰或单独行动的测绘艇停在港口时可以来探索。", 13, UiKit.MUTED))
	side_body.add_child(HSeparator.new())
	side_body.add_child(UiKit.label("东云域探索 · 已发现 %d / %d" % [sim.found_spots().size(), GameData.SPOT_IDS.size()], 16, UiKit.INK, true))
	var seen := sim.seen_spots()
	side_body.add_child(UiKit.para("每个发现都会让周围的雾散开一些。现在能看见 %d 个未探索的去处。测绘艇和莫语的测绘能看得更远。" % seen.size(), 13, UiKit.MUTED))
	for sid in sim.found_spots():
		var s2: Dictionary = GameData.SPOTS[sid]
		side_body.add_child(UiKit.label("✓ %s · %s" % [GameData.SPOT_KIND_NAMES[s2["kind"]], s2["name"]], 13, UiKit.UP))


func _show_discovery() -> void:
	var d = sim.s["discovery"]
	if d == null:
		return
	sim.s["discovery"] = null
	if d["kind"] == "passage":
		map.set_region(2)
	_modal(d["title"], "explore_scene", d["lines"], [["继续", func(): _close_modal(); _after_discovery()]])


## New year's lantern festival: the prizes and a review of the year (round 15).
func _show_festival() -> void:
	var f = sim.s.get("festival_show")
	if f == null:
		return
	sim.s["festival_show"] = null
	_hint("festival")
	var lines := []
	if f["awards"].is_empty():
		lines.append("今年没有颁出奖项。")
	for a in f["awards"]:
		lines.append(("★ " if a["hid"] == sim.pid() else "· ") + a["text"] + "，奖金 %s 金、名声 +%d" % [UiKit.money(GameData.FESTIVAL_PRIZE), int(GameData.FESTIVAL_REP[a["kind"]])])
	if f.has("challenge"):
		lines.append("灯河边，%s正等着你。%s" % [GameData.HOUSES[f["challenge"]]["leader"], "宿敌之间，这一场躲不掉。" if sim.tie_state(f["challenge"]) == "feud" else ""])
	for gf in f.get("gifts", []):
		lines.append("盟友%s送来 %s 金的贺礼。" % [GameData.HOUSES[gf["hid"]]["leader"], UiKit.money(int(gf["gold"]))])
	var v := _modal("第 %d 年 · 灯节" % (int(f["year"]) + 1), "events/15", lines, [["继续", func():
		_close_modal()
		_refresh_all()
		if sim.s["event"] != null:
			_show_event()]], 760)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	box.add_child(UiKit.label("各家这一年", 17, UiKit.INK, true))
	for hrow in f["houses"]:
		var d: Dictionary = GameData.HOUSES[hrow["hid"]]
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 8)
		hb.add_child(UiKit.icon(UiKit.sprite("emblems", d["emblem"]), 24))
		var mine_row: bool = hrow["hid"] == sim.pid()
		var band := floorf(float(hrow["worth"]) / 10000.0) * 10000.0
		var txt := "%s · 身家约 %s（%s）· 船 %d · 工坊 %d · 恩主 %d 城 · 灯塔 %d/3%s%s" % [d["name"], UiKit.money(band), _signed(floorf(float(hrow["gain"]) / 1000.0) * 1000.0), int(hrow["ships"]), int(hrow["workshops"]), int(hrow["bens"]), int(hrow["lh"]), " · 已破产" if hrow["bankrupt"] else "", (" · 与你：%s" % hrow["tie"]) if hrow.has("tie") and not hrow["bankrupt"] else ""]
		hb.add_child(UiKit.label(txt, 13, UiKit.INK if mine_row else UiKit.MUTED, mine_row))
		box.add_child(hb)
		if hrow.has("say"):
			var sl := UiKit.label("　　" + str(hrow["say"]), 13, Color("6b5a3e"))
			box.add_child(sl)
	var m: Dictionary = f["mine"]
	box.add_child(HSeparator.new())
	box.add_child(UiKit.label("你的这一年", 17, UiKit.INK, true))
	box.add_child(UiKit.para("身家 %s 金 · 成交 %d 笔 · 委托 %d 件 · 剿匪 %d 胜 · 伙伴 %d 人 · 到过 %d 座港。灯节的 %d 天里，甜霞果、丝云绸、霞果酒各港卖价 +%d%%。" % [_signed(float(m["gain"])), int(m["trades"]), int(m["contracts"]), int(m["wins"]), int(m["crew"]), int(m["visited"]), GameData.FESTIVAL_DAYS, int(roundf((GameData.FESTIVAL_SELL - 1.0) * 100.0))], 14))
	var year_ms := []
	for ms in GameData.MILESTONES:
		if sim.milestone_done(ms["id"]) and int(sim.milestones()[ms["id"]]) / GameData.DAYS_YEAR == int(f["year"]) - 1:
			year_ms.append(ms["name"])
	if not year_ms.is_empty():
		box.add_child(UiKit.para("这一年的里程碑：%s" % "、".join(year_ms), 14, UiKit.INK))
	if f.has("act"):
		box.add_child(UiKit.para("灯节夜里 · %s" % f["act"]["text"], 14, UiKit.JADE))
	v.add_child(box)
	v.move_child(box, v.get_child_count() - 2)


func _signed(v: float) -> String:
	return ("+" if v >= 0.0 else "−") + UiKit.money(absf(v))


func _after_discovery() -> void:
	var fl := sim.flagship()
	if not fl.is_empty() and sim.docked(fl):
		if GameData.PORTS.has(fl["port"]):
			_open_port(fl["port"], 0)
			_enter_town()
		else:
			_open_spot(fl["port"])
	if sim.s["encounter"] != null:
		_show_encounter()
	_refresh_all()


func _toggle_region() -> void:
	map.set_region(3 - map.region)
	_refresh_region_btn()


func _refresh_region_btn() -> void:
	if region_btn == null:
		return
	region_btn.visible = sim.explore_open() and not _in_town
	region_btn.text = "东云域 ▶" if map.region == 1 else "◀ 霞市"
	region_btn.reset_size()
	region_btn.position = Vector2(size.x - 572 - region_btn.size.x - 16, size.y - region_btn.size.y - 16)


func _contract_row(c: Dictionary, fl: Dictionary, show_port: bool) -> Control:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.box(Color("f7e7bd"), UiKit.BRASS, 5, 1, 6))
	var row := HBoxContainer.new()
	row.add_child(UiKit.icon(UiKit.sprite("goods", GameData.GOODS[c["good"]]["icon"]), 30))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var head := "委托 · %s%s %d 件 · 酬金 %s" % [(GameData.port_name(c["port"]) + " 求购 ") if show_port else "求购 ", GameData.good_name(c["good"]), int(c["qty"]), UiKit.money(c["reward"])]
	v.add_child(UiKit.label(head, 15, UiKit.INK, true))
	var sub := "剩 %d 天 · 每件折合 %d 金" % [int(c["end"]) - int(sim.s["day"]), int(c["reward"]) / maxi(1, int(c["qty"]))]
	var chasers: Array = []
	for hid in c["chasers"]:
		chasers.append(GameData.HOUSES[hid]["name"])
	if not chasers.is_empty():
		sub += " · %s 已出发" % "、".join(chasers)
	v.add_child(UiKit.label(sub, 13, UiKit.TERRA if not chasers.is_empty() else UiKit.MUTED))
	row.add_child(v)
	var cid: int = c["id"]
	if show_port:
		var cp: String = c["port"]
		row.add_child(UiKit.button("查看", func(): _open_port(cp, 3), true))
	elif not fl.is_empty():
		var fid: int = fl["id"]
		var b := UiKit.button("交付", func(): _deliver_contract(fid, cid))
		b.disabled = not sim.can_fulfill(fl, c)
		b.tooltip_text = "旗舰需停在本港，货舱里至少有 %d 件%s。" % [int(c["qty"]), GameData.good_name(c["good"])]
		row.add_child(b)
	p.add_child(row)
	return p


func _deliver_contract(ship_id: int, cid: int) -> void:
	var res := sim.fulfill(ship_id, cid)
	if res["ok"]:
		sfx("coin")
		_float_profit(int(res["profit"]))
	else:
		_toast(res["msg"], "bad")
	_refresh_all()


## The counter inside a building: a portrait, a name and one line of greeting (大航海时代2 style).
func _interior_strip(kind: String) -> Control:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiKit.box(Color("fbf5e6"), Color(UiKit.BRASS, 0.6), 8, 1, 10))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	box.add_child(hb)
	var pid_face: String = town.npc_portrait(kind)
	if pid_face == "":
		pid_face = "hero_" + sim.pid()
	hb.add_child(UiKit.icon(UiKit.portrait(pid_face, "happy" if kind == "tavern" else ""), 72))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UiKit.label("%s · %s" % [town.kind_name(kind), town.npc_title(kind)], 15, UiKit.INK, true))
	var line := UiKit.para(_greeting(kind), 14)
	v.add_child(line)
	hb.add_child(v)
	return box


func _greeting(kind: String) -> String:
	var p: Dictionary = GameData.PORTS[_port]
	var f := sim.friend_level(_port)
	var leader: String = GameData.HOUSES[sim.pid()]["leader"]
	var warm := f >= 2
	match kind:
		"trade":
			var best := ""
			var best_r := 0.0
			for g in GameData.GOOD_IDS:
				var r := float(sim.sell_price(_port, g)) / float(GameData.GOODS[g]["base"])
				if r > best_r:
					best_r = r
					best = g
			return ("%s来了，今天%s收得最急。" % [leader, GameData.good_name(best)]) if warm else ("客官要买什么？今天%s行情最高。" % GameData.good_name(best))
		"yard":
			return "船要修要买都找我。名声到「%s」才能添第 %d 艘。" % [GameData.REP_NAMES[mini(sim.rep_level(), 5)], sim.max_ships() + 1] if sim.own_ships().size() >= sim.max_ships() else "新船随时能交付，%s，看看哪艘合眼缘。" % leader
		"post":
			return "账房见过少主。仓库 %d / %d，工坊 %d 座。" % [Industry.wh_used(sim, _port, sim.pid()), Industry.wh_cap(sim, _port, sim.pid()), Industry.count_buildings(sim, _port, sim.pid())] if Industry.has_wh(sim, _port, sim.pid()) else "这里还没有你的商馆。开了商馆，货和工坊才有地方落脚。"
		"hall":
			return ("%s商会的朋友，本城的地契可以谈。" % GameData.HOUSES[sim.pid()]["name"]) if warm else ("%s？没怎么听过。多在本城做些买卖再来。" % GameData.HOUSES[sim.pid()]["name"])
		"guild":
			return "图纸不外传，除非你证明经手过足够的料。" if sim.rep_level() < 3 else "行首请看，工艺图纸都在墙上。"
		"tavern":
			var rc := sim.recruitable_at(_port, "tavern")
			if not rc.is_empty():
				return "来壶霞果酒？角落里那位%s像是在等人。" % Characters.CHARS[rc[0]]["title"]
			return "来壶霞果酒？委托板在那边，消息也有的是。"
		"bank":
			return "存取借贷都在这里办，利息按月算。"
		"lighthouse":
			return "工地就等物资和金子了。" if sim.house()["lh"]["stage"] < 3 else "灯冠亮着呢，少主。"
	return "欢迎来到%s。" % p["name"]


func _show_hero() -> void:
	var hero: Dictionary = sim.hero()
	var d: Dictionary = GameData.HOUSES[sim.pid()]
	var v := _modal("%s · %d 级" % [d["leader"], int(hero["lvl"])], "", [
		"经验 %d / %d · 航行 %d 天 · 到过 %d 座城" % [int(hero["exp"]), GameData.hero_exp_needed(int(hero["lvl"])), int(hero["days_sailed"]), hero["visited"].size()],
		("有 %d 点能力点可以分配。" % int(hero["pts"])) if int(hero["pts"]) > 0 else "做买卖、跑航程、完成委托和建工坊都会积累经验。",
	], [["关闭", func(): _close_modal()]], 560)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	for k in GameData.HERO_ABIL:
		var kk: String = k
		var lvl := sim.hero_abil(k)
		var nl := UiKit.label("%s %d" % [GameData.HERO_ABIL_NAMES[k], lvl], 16, UiKit.INK, true)
		nl.custom_minimum_size = Vector2(90, 0)
		grid.add_child(nl)
		var dl := UiKit.label(GameData.HERO_ABIL_DESC[k], 13, UiKit.MUTED)
		dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(dl)
		var b := UiKit.button("+1", func(): _act(sim.spend_hero_pt(kk)); _close_modal(); _show_hero(), false)
		b.disabled = int(hero["pts"]) <= 0 or lvl >= GameData.HERO_MAX_ABIL
		grid.add_child(b)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	top.add_child(UiKit.icon(UiKit.portrait("hero_" + sim.pid()), 110))
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UiKit.label("%s当家 · 母港 %s" % [d["name"], GameData.port_name(d["home"])], 14, UiKit.MUTED))
	tv.add_child(UiKit.para(d["pitch"], 13))
	top.add_child(tv)
	v.add_child(top)
	v.move_child(top, 1)
	v.add_child(grid)
	v.move_child(grid, v.get_child_count() - 2)


func _tab_trade(here: bool) -> void:
	var fl := sim.flagship()
	var intel = sim.s["intel"][_port]
	var p: Dictionary = GameData.PORTS[_port]
	var hid := sim.pid()
	var has_post := Industry.has_wh(sim, _port, hid)
	if not here and intel == null:
		side_body.add_child(UiKit.para("还没有这座城的行情。派船到访，或在酒馆买情报。", 15, UiKit.MUTED))
		return
	# header line: patron, friendliness, cargo
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 12)
	var pat := sim.patron(_port)
	info.add_child(UiKit.label("港主 " + (GameData.HOUSES[pat]["name"] if pat != "" else "无"), 13, UiKit.BRASS if pat == hid else UiKit.MUTED))
	var ben := sim.benefactor(_port)
	if ben != "":
		info.add_child(UiKit.label("恩主 " + GameData.HOUSES[ben]["name"], 13, UiKit.BRASS if ben == hid else UiKit.MUTED))
	info.add_child(UiKit.label("友好 " + GameData.FRIEND_NAMES[sim.friend_level(_port)], 13, UiKit.MUTED))
	if here:
		var nfl := sim.fleet_ships(fl).size()
		info.add_child(UiKit.label("货舱 %d / %d%s" % [sim.fleet_cargo_used(fl), sim.fleet_cargo_cap(fl), ("（%d 艘）" % nfl) if nfl > 1 else ""], 13, UiKit.INK, true))
	else:
		info.add_child(UiKit.label("行情 %d 天前 · 旗舰不在此港" % (int(sim.s["day"]) - int(intel["day"])), 13, UiKit.MUTED))
	if has_post:
		info.add_child(UiKit.label("商馆 %d / %d" % [Industry.wh_used(sim, _port, hid), Industry.wh_cap(sim, _port, hid)], 13, UiKit.INK, true))
	side_body.add_child(info)
	# mode + quantity selectors
	if here:
		var sel := HBoxContainer.new()
		sel.add_theme_constant_override("separation", 4)
		var modes := ["船队 ⇄ 市场", "商馆 ⇄ 市场", "船队 ⇄ 商馆"]
		for i in modes.size():
			var mb := UiKit.button(modes[i], func(): _trade_mode = i; _refresh_side(), i != _trade_mode)
			mb.add_theme_font_size_override("font_size", 13)
			mb.disabled = i > 0 and not has_post
			sel.add_child(mb)
		var sp := Control.new()
		sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sel.add_child(sp)
		sel.add_child(UiKit.label("每次", 13, UiKit.MUTED))
		for q in [1, 10, 50, 9999]:
			var qq: int = q
			var qb := UiKit.button("全部" if q == 9999 else str(q), func(): _trade_qty = qq; _refresh_side(), q != _trade_qty)
			qb.add_theme_font_size_override("font_size", 13)
			qb.custom_minimum_size = Vector2(40, 0)
			sel.add_child(qb)
		side_body.add_child(sel)
	for c in sim.open_contracts(_port):
		side_body.add_child(_contract_row(c, fl, false))
	# table
	var grid := GridContainer.new()
	grid.columns = 8
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 3)
	var left_name: String = ["船上", "商馆", "船上"][_trade_mode]
	var right_name: String = ["市场", "市场", "商馆"][_trade_mode]
	for hd in ["货物", "库存", "买价", "卖价", "均价", left_name, "商馆" if _trade_mode != 1 else "船上", ""]:
		var hl := UiKit.label(hd, 12, UiKit.MUTED, true)
		grid.add_child(hl)
	var order: Array = []
	for g in p["make"]:
		order.append(g)
	for g in p["want"]:
		if not g in order:
			order.append(g)
	for g in GameData.GOOD_IDS:
		if not g in order:
			order.append(g)
	var wh := Industry.wh(sim, _port, hid) if has_post else {}
	var fcargo := sim.fleet_cargo(fl) if not fl.is_empty() else {}
	for g in order:
		var t := GameData.tier(g)
		var gh := HBoxContainer.new()
		gh.add_theme_constant_override("separation", 3)
		gh.add_child(UiKit.icon(GameData.icon_of(g), 24))
		var tcol := UiKit.INK
		var bold := false
		if g in p["make"]:
			tcol = UiKit.UP
			bold = true
		elif g in p["want"]:
			tcol = UiKit.DOWN
			bold = true
		var nl := UiKit.label(GameData.good_name(g), 13, tcol, bold)
		nl.custom_minimum_size = Vector2(66, 0)
		var ghome: String = GameData.GOODS[g].get("home", "")
		var origin := "\n没有城市天然出产，只能靠工坊制造"
		if ghome != "" and GameData.PORTS.has(ghome):
			origin = "\n产地：" + GameData.port_name(ghome)
		nl.tooltip_text = "%s · 基准价 %d%s" % [GameData.TIER_NAMES[t], GameData.GOODS[g]["base"], origin]
		nl.mouse_filter = Control.MOUSE_FILTER_PASS
		gh.add_child(nl)
		grid.add_child(gh)
		var stock: int = int(sim.s["ports"][_port]["market"][g]["stock"]) if here else -1
		grid.add_child(UiKit.label(str(stock) if stock >= 0 else "?", 13, UiKit.MUTED))
		var bp: int = sim.buy_price(_port, g) if here else int(intel["prices"][g][0])
		var spr: int = sim.sell_price(_port, g) if here else int(intel["prices"][g][1])
		var base: float = GameData.GOODS[g]["base"]
		grid.add_child(UiKit.label(str(bp), 13, UiKit.UP if bp < base * 0.85 else (UiKit.DOWN if bp > base * 1.3 else UiKit.INK), true))
		var trend := ""
		var prev = sim.s.get("intel_prev", {}).get(_port)
		if prev != null:
			var old_s: int = int(prev["prices"][g][1])
			if spr > old_s * 1.03:
				trend = "▲"
			elif spr < old_s * 0.97:
				trend = "▼"
		var sl := UiKit.label(str(spr) + trend, 13, UiKit.UP if spr > base * 1.3 else UiKit.INK, true)
		if trend != "":
			sl.tooltip_text = "上次到访时卖价 %d" % int(prev["prices"][g][1])
			sl.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(sl)
		var held := 0
		var avg := 0.0
		if fcargo.has(g):
			held = int(fcargo[g]["qty"])
			avg = float(fcargo[g]["cost"])
		var in_wh := int(wh.get(g, 0))
		var al := UiKit.label(str(int(avg)) if held > 0 else "—", 13, UiKit.UP if held > 0 and spr > avg else UiKit.MUTED)
		if held > 0:
			al.tooltip_text = "船上这批货的平均成本；卖价高于它就是赚。"
			al.mouse_filter = Control.MOUSE_FILTER_PASS
		grid.add_child(al)
		var left_qty: int = [held, in_wh, held][_trade_mode]
		var other_qty: int = [in_wh, held, in_wh][_trade_mode]
		grid.add_child(UiKit.label(str(left_qty), 13, UiKit.INK, left_qty > 0))
		grid.add_child(UiKit.label(str(other_qty), 13, UiKit.MUTED))
		var btns := HBoxContainer.new()
		btns.add_theme_constant_override("separation", 2)
		if here:
			var gg: String = g
			var b_in := UiKit.button("◀", func(): _trade_op(true, gg), true)
			var b_out := UiKit.button("▶", func(): _trade_op(false, gg), true)
			b_in.tooltip_text = ["买入到船上", "买入到商馆", "从商馆装上船"][_trade_mode]
			b_out.tooltip_text = ["从船上卖出", "从商馆卖出", "从船上卸进商馆"][_trade_mode]
			match _trade_mode:
				0:
					b_in.disabled = sim.fleet_cargo_used(fl) >= sim.fleet_cargo_cap(fl) or sim.house()["gold"] < bp or stock <= 0
					b_out.disabled = held == 0
				1:
					b_in.disabled = Industry.wh_used(sim, _port, hid) >= Industry.wh_cap(sim, _port, hid) or sim.house()["gold"] < bp or stock <= 0
					b_out.disabled = in_wh == 0
				2:
					b_in.disabled = in_wh == 0 or sim.fleet_cargo_used(fl) >= sim.fleet_cargo_cap(fl)
					b_out.disabled = held == 0 or Industry.wh_used(sim, _port, hid) >= Industry.wh_cap(sim, _port, hid)
			if _tut_step() == 0 and gg == _tutorial_goal()["good"] and _trade_mode == 0:
				_pulse(b_in)
			if _tut_step() == 2 and held > 0 and _trade_mode == 0:
				_pulse(b_out)
			for b in [b_in, b_out]:
				b.add_theme_font_size_override("font_size", 12)
				b.custom_minimum_size = Vector2(30, 26)
				b.mouse_filter = Control.MOUSE_FILTER_STOP
				btns.add_child(b)
		grid.add_child(btns)
	side_body.add_child(grid)
	side_body.add_child(UiKit.label("绿色 = 本城招牌货，红色 = 本城常年需求。◀ 向左边栏买入或装货，▶ 向右卖出或卸货。", 12, UiKit.MUTED))


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
	side_body.add_child(UiKit.para("买船后它会停在这里。给非旗舰设自动航线，它就会替你往返跑商。船队上限由名声决定（现在 %d 艘）；每艘船每月要付薪水和维护。" % sim.max_ships(), 14, UiKit.MUTED))
	for t in GameData.yard_types():
		var d: Dictionary = GameData.SHIPS[t]
		var row := HBoxContainer.new()
		row.add_child(UiKit.icon(UiKit.sprite("ships", d["sprite"]), 64))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UiKit.label("%s  ·  %s 金" % [d["name"], UiKit.money(sim.ship_price(t))], 17, UiKit.INK, true))
		v.add_child(UiKit.label("货舱 %d · 航速 %.2f · 炮 %d · 耐久 %d · 船员 %d · 补给 %d/天 · 月薪 %d" % [d["cargo"], d["speed"], d["guns"], d["hull"], d["crew"], d["fuel_day"] * GameData.FUEL_PRICE, d["wage"]], 12, UiKit.MUTED))
		row.add_child(v)
		var tt: String = t
		var b := UiKit.button("购买", func(): _act(sim.buy_ship(tt, _port)); _refresh_fleet())
		b.disabled = sim.house()["gold"] < sim.ship_price(t) or sim.own_ships().size() >= sim.max_ships()
		row.add_child(b)
		side_body.add_child(row)
	var mine := sim.ships_of().filter(func(x): return sim.docked(x) and x["port"] == _port)
	if not mine.is_empty():
		side_body.add_child(HSeparator.new())
		side_body.add_child(UiKit.label("停在此港的船 · 改造与编队", 16, UiKit.INK, true))
		side_body.add_child(UiKit.para("改造在船坞做，每项最高 3 级。物料先用船上的，再用商馆里的，不够就按市价买。", 13, UiKit.MUTED))
		for sh in mine:
			side_body.add_child(_ship_card(sh))
	_recruit_rows("yard")


func _tab_post(here: bool) -> void:
	var hid := sim.pid()
	var p: Dictionary = GameData.PORTS[_port]
	var has_post := Industry.has_wh(sim, _port, hid)
	if _port == GameData.HOUSES[hid]["home"]:
		# the house's headquarters (round 13)
		var lvl := sim.hq_level()
		var cur: Dictionary = GameData.HQ[lvl]
		side_body.add_child(UiKit.label("商会总部 · %s" % cur["name"], 18, UiKit.INK, true))
		side_body.add_child(UiKit.para(cur["desc"] if lvl > 0 else "起家的小院子。会馆越大，能带的伙伴越多，每月还会为商会添名声。", 13, UiKit.MUTED))
		if lvl + 1 < GameData.HQ.size():
			var nxt: Dictionary = GameData.HQ[lvl + 1]
			var ok := sim.hq_ok()
			if ok["ok"]:
				_hint("hq")
			var hb := UiKit.button("扩建为「%s」· %s 金" % [nxt["name"], UiKit.money(nxt["cost"])], func(): _act(sim.upgrade_hq()); _refresh_side())
			hb.disabled = not ok["ok"]
			hb.tooltip_text = ("%s（名声「%s」）" % [nxt["desc"], GameData.REP_NAMES[int(GameData.HQ_REP[lvl + 1]) - 1]]) if ok["ok"] else ("%s — %s" % [nxt["desc"], ok["msg"]])
			side_body.add_child(hb)
			side_body.add_child(UiKit.label(nxt["desc"], 12, UiKit.JADE))
		side_body.add_child(HSeparator.new())
	if not has_post:
		side_body.add_child(UiKit.label("商馆", 18, UiKit.INK, true))
		side_body.add_child(UiKit.para("商馆是你在这座城的据点：有仓库可以囤货，工坊的原料和产出都放在这里。开设需要名声「船东」（2 级）和 %d 金，仓库按容量付租金。" % GameData.WH_OPEN, 14, UiKit.MUTED))
		var ob := UiKit.button("开设商馆 · %s 金" % UiKit.money(GameData.WH_OPEN), func(): _act(Industry.open_wh(sim, _port)))
		ob.disabled = not here or sim.rep_level() < 2 or sim.house()["gold"] < GameData.WH_OPEN
		if not here:
			ob.tooltip_text = "旗舰需要停在这座城。"
		side_body.add_child(ob)
	else:
		var cap := Industry.wh_cap(sim, _port, hid)
		var hd := HBoxContainer.new()
		var l := UiKit.label("商馆 · 仓库 %d / %d" % [Industry.wh_used(sim, _port, hid), cap], 18, UiKit.INK, true)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hd.add_child(l)
		if cap < GameData.WH_MAX:
			var ub := UiKit.button("扩建 +%d · %s 金" % [GameData.WH_STEP, UiKit.money(GameData.WH_UPGRADE)], func(): _act(Industry.upgrade_wh(sim, _port)), true)
			ub.disabled = sim.house()["gold"] < GameData.WH_UPGRADE
			hd.add_child(ub)
		side_body.add_child(hd)
		var wh := Industry.wh(sim, _port, hid)
		if wh.is_empty():
			side_body.add_child(UiKit.label("仓库是空的。在「交易」页切到「船队 ⇄ 商馆」可以卸货进来。", 13, UiKit.MUTED))
		else:
			var flow := HFlowContainer.new()
			flow.add_theme_constant_override("h_separation", 10)
			for g in wh:
				var cell := HBoxContainer.new()
				cell.add_theme_constant_override("separation", 2)
				cell.add_child(UiKit.icon(GameData.icon_of(g), 22))
				cell.add_child(UiKit.label("%s %d" % [GameData.good_name(g), int(wh[g])], 13))
				flow.add_child(cell)
			side_body.add_child(flow)
		side_body.add_child(UiKit.label("月租 %d 金" % int(float(cap) / 100.0 * GameData.WH_RENT_PER_100), 12, UiKit.MUTED))
	side_body.add_child(HSeparator.new())
	# plots
	var plots: Array = sim.s["ports"][_port]["plots"]
	var mine := Industry.count_buildings(sim, _port, hid)
	var limit := Industry.build_limit(sim, _port, hid)
	var pat := sim.patron(_port)
	side_body.add_child(UiKit.label("地块 · 你在此有 %d / %d 座（友好度越高越多）· 港主：%s" % [mine, limit, GameData.HOUSES[pat]["name"] if pat != "" else "无"], 15, UiKit.INK, true))
	for i in plots.size():
		var pl = plots[i]
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UiKit.box(Color("faf3e3") if pl == null else (Color("eef4ea") if pl["owner"] == hid else Color("f1ebe3")), Color(UiKit.BRASS, 0.5), 5, 1, 6))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 6)
		row.add_child(hb)
		var idx: int = i
		if pl == null:
			hb.add_child(UiKit.icon(UiKit.sprite("city_buildings", 8), 36))
			var tl := UiKit.label("%d · %s · 空地" % [i + 1, Industry.terrain_name(_port, i)], 14, UiKit.MUTED)
			tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hb.add_child(tl)
			var bb := UiKit.button("建造…" if _build_plot != i else "收起", func(): _build_plot = -1 if _build_plot == idx else idx; _refresh_side(), true)
			bb.disabled = not has_post and not here
			hb.add_child(bb)
			side_body.add_child(row)
			if _build_plot == i:
				_build_menu(i)
			continue
		var g: String = pl["b"]
		hb.add_child(UiKit.icon(GameData.icon_of(g), 36))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var owner_name: String = GameData.HOUSES[pl["owner"]]["name"]
		v.add_child(UiKit.label("%d · %s工坊 %d 级 · %s" % [i + 1, GameData.good_name(g), int(pl["lvl"]), "你的" if pl["owner"] == hid else owner_name], 14, UiKit.INK, true))
		var rec := []
		for k in GameData.GOODS[g].get("recipe", {}):
			rec.append("%s×%d" % [GameData.good_name(k), GameData.GOODS[g]["recipe"][k]])
		var st: String = pl["status"]
		var sub := "每天 %d 件" % Industry.output(sim, _port, pl) + (("，耗 " + "、".join(rec)) if not rec.is_empty() else "")
		if pl["owner"] == hid:
			sub += " · 原料：" + ("只用商馆" if pl["in_mode"] == "wh" else "不够就买") + " · 产出：" + {"wh": "入商馆", "sell": "直接卖", "lh": "送灯塔"}[pl["out_mode"]]
		v.add_child(UiKit.label(sub, 12, UiKit.MUTED))
		if st != "ok":
			v.add_child(UiKit.label("停工：" + st, 12, UiKit.TERRA, true))
		hb.add_child(v)
		if pl["owner"] == hid:
			var ops := VBoxContainer.new()
			ops.add_theme_constant_override("separation", 2)
			var r1 := HBoxContainer.new()
			r1.add_theme_constant_override("separation", 2)
			var im := UiKit.button("原料" + ("⟳" if pl["in_mode"] == "wh" else "$"), func(): _act(Industry.set_mode(sim, _port, idx, "in_mode", "buy" if sim.s["ports"][_port]["plots"][idx]["in_mode"] == "wh" else "wh")), true)
			im.tooltip_text = "切换：只从商馆取料 / 商馆不够就从市场买"
			var om := UiKit.button("产出" + {"wh": "▣", "sell": "$", "lh": "☼"}[pl["out_mode"]], func(): _cycle_out_mode(idx), true)
			om.tooltip_text = "切换：产出入商馆 / 直接卖给市场 / 送往灯塔工地（母港）"
			for b in [im, om]:
				b.add_theme_font_size_override("font_size", 12)
				r1.add_child(b)
			ops.add_child(r1)
			var r2 := HBoxContainer.new()
			r2.add_theme_constant_override("separation", 2)
			if int(pl["lvl"]) < GameData.MAX_BUILD_LEVEL:
				var uc := Industry.upgrade_cost(sim, g, hid)
				var ub2 := UiKit.button("升级 %s" % UiKit.money(uc), func(): _act(Industry.upgrade(sim, _port, idx)), true)
				ub2.disabled = sim.house()["gold"] < uc
				ub2.add_theme_font_size_override("font_size", 12)
				r2.add_child(ub2)
			var db := UiKit.button("拆", func(): _act(Industry.demolish(sim, _port, idx)), true)
			db.add_theme_font_size_override("font_size", 12)
			r2.add_child(db)
			ops.add_child(r2)
			hb.add_child(ops)
		else:
			var bc := Industry.buyout_cost(sim, _port, i)
			var bb2 := UiKit.button("收购 %s" % UiKit.money(bc), func(): _act(Industry.buyout(sim, _port, idx)), true)
			bb2.disabled = sim.house()["gold"] < bc or not sim.has_bp(g)
			bb2.tooltip_text = "按 %.1f 倍造价收购对手的工坊；需要你也有这种货的图纸。%s" % [GameData.BUYOUT_MULT, ("宿敌的工坊打 %d 折。" % int(roundf(GameData.FEUD_BUYOUT * 10.0))) if sim.tie_state(pl["owner"]) == "feud" else ""]
			if not sim.allies_of(hid).is_empty():
				bb2.tooltip_text += "手头宽裕的盟友会出 %d%%。" % int(roundf(GameData.ALLY_BUYOUT_SHARE * 100.0))
			bb2.add_theme_font_size_override("font_size", 12)
			hb.add_child(bb2)
		side_body.add_child(row)


func _cycle_out_mode(idx: int) -> void:
	var cur: String = sim.s["ports"][_port]["plots"][idx]["out_mode"]
	var order := ["wh", "sell", "lh"] if _port == GameData.HOUSES[sim.pid()]["home"] else ["wh", "sell"]
	var nxt: String = order[(order.find(cur) + 1) % order.size()]
	_act(Industry.set_mode(sim, _port, idx, "out_mode", nxt))


func _build_menu(i: int) -> void:
	var hid := sim.pid()
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var any := false
	for g in Industry.goods_for(_port, i):
		var ok := sim.has_bp(g)
		if not ok and GameData.tier(g) == 3 and GameData.SECRET_BP_CITY[g] != _port:
			continue   # secrets you have not found are not advertised
		any = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.add_child(UiKit.icon(GameData.icon_of(g), 26))
		var rec := []
		for k in GameData.GOODS[g].get("recipe", {}):
			rec.append("%s×%d" % [GameData.good_name(k), GameData.GOODS[g]["recipe"][k]])
		var n: int = GameData.TIER_OUTPUT[GameData.tier(g)] + (GameData.SIGNATURE_BONUS if g in GameData.PORTS[_port]["make"] else 0) + (1 if sim.perk(hid) == "industry" else 0)
		var desc := "%s工坊 · 每天 %d 件" % [GameData.good_name(g), n] + ((" · 耗 " + "、".join(rec)) if not rec.is_empty() else "") + " · 每件毛利约 %d" % Industry.margin_hint(g)
		var dl := UiKit.label(desc, 12, UiKit.INK if ok else UiKit.MUTED)
		dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(dl)
		var cost := Industry.build_cost(sim, g, hid)
		var gg: String = g
		var idx: int = i
		var bb := UiKit.button("%s 金" % UiKit.money(cost) if ok else ["", "缺地契", "缺图纸", "缺秘传"][GameData.tier(g)], func(): _act(Industry.build(sim, _port, idx, gg)); _build_plot = -1, not ok)
		var can := Industry.can_build(sim, _port, i, g, hid)
		bb.disabled = not can["ok"]
		bb.tooltip_text = can.get("msg", "")
		bb.add_theme_font_size_override("font_size", 12)
		row.add_child(bb)
		box.add_child(row)
	if not any:
		box.add_child(UiKit.label("这块地上没有你能建的工坊。", 12, UiKit.MUTED))
	side_body.add_child(box)


func _tab_hall() -> void:
	var hid := sim.pid()
	var p: Dictionary = GameData.PORTS[_port]
	var pts := sim.friend_pts(_port)
	var lvl := sim.friend_level(_port)
	side_body.add_child(UiKit.label("城主府 · 友好度「%s」" % GameData.FRIEND_NAMES[lvl], 18, UiKit.INK, true))
	var bar := ProgressBar.new()
	if lvl < 5:
		bar.max_value = GameData.FRIEND_LEVELS[lvl + 1]
		bar.value = pts
	else:
		bar.max_value = 1
		bar.value = 1
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, 10)
	side_body.add_child(bar)
	side_body.add_child(UiKit.label(("%d / %d" % [pts, GameData.FRIEND_LEVELS[lvl + 1]]) if lvl < 5 else "已是最高", 12, UiKit.MUTED))
	side_body.add_child(UiKit.para("在这里成交、完成委托、建工坊都会提升友好度。友好度决定你能在这座城建几座工坊（%d 座），2 级起能买地契，3 级起行会才肯交秘传。" % Industry.build_limit(sim, _port, hid), 13, UiKit.MUTED))
	var db := UiKit.button("捐助城市 · %s 金 · 友好度 +%d" % [UiKit.money(GameData.DONATION), GameData.DONATION_FRIEND], func(): _act(sim.donate(_port)), true)
	db.disabled = sim.house()["gold"] < GameData.DONATION
	side_body.add_child(db)
	side_body.add_child(HSeparator.new())
	# city works (round 14)
	var ben := sim.benefactor(_port)
	var spent: Dictionary = sim.works(_port)["spent"]
	var mine := float(spent.get(hid, 0.0))
	var hd := HBoxContainer.new()
	if sim.work_ok(_port, "dock")["ok"] or sim.work_level(_port, "dock") > 0 or ben != "":
		_hint("works")
	var hl := UiKit.label("城建 · 恩主：%s" % (GameData.HOUSES[ben]["name"] if ben != "" else "暂无"), 16, UiKit.BRASS if ben == hid else UiKit.INK, true)
	hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hd.add_child(hl)
	hd.add_child(UiKit.label("你已出资 %s" % UiKit.money(mine), 12, UiKit.MUTED))
	side_body.add_child(hd)
	var lead := 0.0
	for o in spent:
		if o != hid:
			lead = maxf(lead, float(spent[o]))
	side_body.add_child(UiKit.para("出资最多的商会是本城恩主：在此买货 −%d%%，友好度随每级大涨，每月名声 +%d，城中立像。%s" % [int(roundf((1.0 - GameData.BENEFACTOR_DISCOUNT) * 100.0)), GameData.BENEFACTOR_REP, ("对手最多出了 %s。" % UiKit.money(lead)) if lead > 0.0 else "还没人出过钱。"], 12, UiKit.MUTED))
	for k in GameData.WORK_IDS:
		var w: Dictionary = GameData.WORKS[k]
		var wl := sim.work_level(_port, k)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var pips := ""
		for i in GameData.WORK_MAX:
			pips += "●" if i < wl else "○"
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(UiKit.label("%s %s" % [w["name"], pips], 14, UiKit.INK, true))
		col.add_child(UiKit.label(w["desc"], 12, UiKit.MUTED))
		row.add_child(col)
		if wl >= GameData.WORK_MAX:
			row.add_child(UiKit.label("已满级", 13, UiKit.UP, true))
		else:
			var kk: String = k
			var ok := sim.work_ok(_port, k)
			var b := UiKit.button("出资 %s" % UiKit.money(GameData.WORK_COST[wl + 1]), func(): _act(sim.fund_work(_port, kk)))
			b.disabled = not ok["ok"]
			b.tooltip_text = ok.get("msg", "升到 %d 级" % (wl + 1))
			b.add_theme_font_size_override("font_size", 13)
			row.add_child(b)
		side_body.add_child(row)
	side_body.add_child(HSeparator.new())
	side_body.add_child(UiKit.label("地契 · 本城天然出产", 16, UiKit.INK, true))
	for g in p["make"]:
		if GameData.tier(g) != 1:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.add_child(UiKit.icon(GameData.icon_of(g), 28))
		var l := UiKit.label("%s产地地契 · 可在本城的%s产地建工坊，每天 %d 件" % [GameData.good_name(g), GameData.good_name(g), GameData.TIER_OUTPUT[1] + GameData.SIGNATURE_BONUS], 13)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		if sim.has_bp(g):
			row.add_child(UiKit.label("已持有", 13, UiKit.UP, true))
		else:
			var gg: String = g
			var ok := sim.deed_ok(_port, g)
			var b := UiKit.button("%s 金" % UiKit.money(GameData.DEED_COST), func(): _act(sim.buy_deed(_port, gg)))
			b.disabled = not ok["ok"]
			b.tooltip_text = ok.get("msg", "")
			b.add_theme_font_size_override("font_size", 13)
			row.add_child(b)
		side_body.add_child(row)
	var cs := sim.open_contracts(_port).filter(func(c): return c.get("kind", "trade") == "trade")
	if not cs.is_empty():
		side_body.add_child(HSeparator.new())
		side_body.add_child(UiKit.label("本城委托", 16, UiKit.INK, true))
		for c in cs:
			side_body.add_child(_contract_row(c, sim.flagship(), false))


func _tab_guild() -> void:
	var hid := sim.pid()
	side_body.add_child(UiKit.label("工匠行会 · 名声「%s」" % GameData.REP_NAMES[sim.rep_level() - 1], 18, UiKit.INK, true))
	var exp_box := PanelContainer.new()
	exp_box.add_theme_stylebox_override("panel", UiKit.box(Color("eef3ef"), Color(UiKit.JADE, 0.5), 6, 1, 8))
	var ev := VBoxContainer.new()
	ev.add_theme_constant_override("separation", 4)
	exp_box.add_child(ev)
	if sim.explore_open():
		ev.add_child(UiKit.label("远航探险 · 东云域航路已开", 15, UiKit.JADE, true))
		ev.add_child(UiKit.para("已发现 %d / %d 处。把海图切到东云域，派旗舰去「?」处探索。" % [sim.found_spots().size(), GameData.SPOT_IDS.size()], 13, UiKit.MUTED))
	else:
		ev.add_child(UiKit.label("远航探险 · 东边的雾里有另一片云海", 15, UiKit.JADE, true))
		ev.add_child(UiKit.para("赞助一支探险队去找通往东云域的航路。需要名声「%s」。那边的城出产西边没人做的货，也有遗迹和云盗。" % GameData.REP_NAMES[GameData.EXPEDITION_REP - 1], 13, UiKit.MUTED))
		var eok := sim.expedition_ok()
		var eb := UiKit.button("赞助探险队 · %s 金" % UiKit.money(GameData.EXPEDITION_COST), func(): _act(sim.sponsor_expedition()); _refresh_all())
		eb.disabled = not eok["ok"]
		eb.tooltip_text = eok.get("msg", "")
		ev.add_child(eb)
	side_body.add_child(exp_box)
	side_body.add_child(UiKit.para("工艺图纸（二阶）：名声 3 级，并且经手过 %d 件主原料。秘传图纸（三阶）：名声 4 级、友好度 3，每座城只传一种。" % GameData.CRAFT_HANDLED, 13, UiKit.MUTED))
	side_body.add_child(UiKit.label("工艺图纸", 16, UiKit.INK, true))
	for g in GameData.GOOD_IDS:
		if GameData.tier(g) != 2:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.add_child(UiKit.icon(GameData.icon_of(g), 26))
		var rec := []
		for k in GameData.GOODS[g]["recipe"]:
			rec.append("%s×%d" % [GameData.good_name(k), GameData.GOODS[g]["recipe"][k]])
		var mi := GameData.main_input(g)
		var handled := int(sim.s["stats"]["handled"].get(mi, 0))
		var l := UiKit.label("%s · %s → 1 · 经手%s %d/%d" % [GameData.good_name(g), "+".join(rec), GameData.good_name(mi), mini(handled, GameData.CRAFT_HANDLED), GameData.CRAFT_HANDLED], 12)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		if sim.has_bp(g):
			row.add_child(UiKit.label("已持有", 13, UiKit.UP, true))
		else:
			var gg: String = g
			var ok := sim.craft_ok(g)
			var b := UiKit.button("%s 金" % UiKit.money(GameData.CRAFT_BP_COST), func(): _act(sim.buy_craft_bp(gg)), true)
			b.disabled = not ok["ok"]
			b.tooltip_text = ok.get("msg", "")
			b.add_theme_font_size_override("font_size", 12)
			row.add_child(b)
		side_body.add_child(row)
	side_body.add_child(HSeparator.new())
	side_body.add_child(UiKit.label("本城秘传", 16, UiKit.INK, true))
	for g in GameData.SECRET_BP_CITY:
		if GameData.SECRET_BP_CITY[g] != _port:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.add_child(UiKit.icon(GameData.icon_of(g), 30))
		var rec := []
		for k in GameData.GOODS[g]["recipe"]:
			rec.append("%s×%d" % [GameData.good_name(k), GameData.GOODS[g]["recipe"][k]])
		var l := UiKit.label("%s · %s → 1 · 基准价 %d" % [GameData.good_name(g), "+".join(rec), GameData.GOODS[g]["base"]], 13, UiKit.INK, true)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		if sim.has_bp(g):
			row.add_child(UiKit.label("已持有", 13, UiKit.UP, true))
		else:
			var gg: String = g
			var ok := sim.secret_ok(_port, g)
			var b := UiKit.button("%s 金" % UiKit.money(GameData.SECRET_BP_COST), func(): _act(sim.buy_secret_bp(_port, gg)))
			b.disabled = not ok["ok"]
			b.tooltip_text = ok.get("msg", "")
			b.add_theme_font_size_override("font_size", 12)
			row.add_child(b)
		side_body.add_child(row)
	var mine := []
	for g in sim.house()["bp"]:
		mine.append(GameData.good_name(g))
	side_body.add_child(HSeparator.new())
	side_body.add_child(UiKit.label("你持有的图纸：" + ("、".join(mine) if not mine.is_empty() else "无"), 12, UiKit.MUTED))
	_recruit_rows("guild")


func _tab_tavern() -> void:
	side_body.add_child(UiKit.label("委托板", 18, UiKit.INK, true))
	var cs := sim.open_contracts().filter(func(c): return c.get("kind", "trade") == "trade")
	if not cs.is_empty():
		_hint("contract")
	if cs.is_empty():
		side_body.add_child(UiKit.para("眼下没有委托。各港每隔一阵会张贴求购单，先把货送到的商会拿走全部酬金。", 14, UiKit.MUTED))
	for c in cs:
		side_body.add_child(_contract_row(c, {}, true))
	side_body.add_child(HSeparator.new())
	side_body.add_child(UiKit.label("悬赏榜", 18, UiKit.INK, true))
	var bs := sim.open_bounties()
	if bs.is_empty():
		side_body.add_child(UiKit.para("眼下没有悬赏。云盗闹得凶的时候，城主会出钱请商会剿匪：接下悬赏、驶抵那座港就会开战。", 14, UiKit.MUTED))
	for c in bs:
		var p := PanelContainer.new()
		p.add_theme_stylebox_override("panel", UiKit.box(Color("f3dcd0"), UiKit.TERRA, 5, 1, 6))
		var row := HBoxContainer.new()
		row.add_child(UiKit.icon(UiKit.sprite("ships", 7), 34))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_child(UiKit.label("剿匪 · %s 外海 · 赏金 %s" % [GameData.port_name(c["port"]), UiKit.money(c["reward"])], 15, UiKit.INK, true))
		var taken: bool = c.get("taker", "") == sim.pid()
		v.add_child(UiKit.label("剩 %d 天 · 对方战力约 %d（我方 %d）%s" % [int(c["end"]) - int(sim.s["day"]), int(float(c["power"]) * 1.25), sim.fleet_power(sim.flagship()), " · 已接下，驶抵即开战" if taken else ""], 13, UiKit.TERRA if taken else UiKit.MUTED))
		row.add_child(v)
		var cid: int = c["id"]
		row.add_child(UiKit.button("放弃" if taken else "接下", func(): _act(sim.take_bounty(cid)); _refresh_side(), taken))
		p.add_child(row)
		side_body.add_child(p)
	var here: Array = sim.quests_at(_port)
	if not here.is_empty():
		side_body.add_child(HSeparator.new())
		side_body.add_child(UiKit.label("伙伴的托付", 18, UiKit.INK, true))
		for qkey in here:
			var q := Characters.quest_def(qkey)
			var qcid := Characters.quest_cid(qkey)
			var qp := PanelContainer.new()
			qp.add_theme_stylebox_override("panel", UiKit.box(Color("f6ecd2"), UiKit.BRASS, 5, 1, 6))
			var qrow := HBoxContainer.new()
			qrow.add_child(UiKit.icon(UiKit.portrait(qcid), 34))
			var qv := VBoxContainer.new()
			qv.add_theme_constant_override("separation", 0)
			qv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			qv.add_child(UiKit.label("%s · %s · 谢礼 %s" % [Characters.name_of(qcid), q["title"], UiKit.money(q["gold"])], 15, UiKit.INK, true))
			if str(q.get("kind", "deliver")) == "deliver":
				var have := int(sim.fleet_cargo(sim.flagship()).get(q["good"], {}).get("qty", 0)) if not sim.flagship().is_empty() else 0
				qv.add_child(UiKit.label("%d 件%s（船上 %d）· 剩 %d 天" % [int(q["qty"]), GameData.good_name(q["good"]), have, int(sim.quests()[qkey]["end"]) - int(sim.s["day"])], 13, UiKit.MUTED))
			else:
				qv.add_child(UiKit.label("到这里就算办成 · 剩 %d 天" % (int(sim.quests()[qkey]["end"]) - int(sim.s["day"])), 13, UiKit.MUTED))
			qrow.add_child(qv)
			var qok := sim.quest_ok(qkey)
			var qcc: String = qkey
			var qb := UiKit.button("交付", func(): _act(sim.quest_deliver(qcc)); _refresh_side(), not qok["ok"])
			qb.tooltip_text = "" if qok["ok"] else qok["msg"]
			qrow.add_child(qb)
			qp.add_child(qrow)
			side_body.add_child(qp)
	_recruit_rows("tavern")
	side_body.add_child(HSeparator.new())
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
		if sim.s["crown"] != null:
			side_body.add_child(UiKit.label("云海盟主：%s（%s）" % [GameData.HOUSES[sim.s["crown"]["hid"]]["name"], GameData.date_text(sim.s["crown"]["day"])], 14, UiKit.BRASS, true))
		_grand_rows()
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
		side_body.add_child(UiKit.label("开工费 %s 金 · 工期 %d 天 · 需要名声「%s」" % [UiKit.money(st["gold"]), st["days"], GameData.REP_NAMES[int(st["rep"]) - 1]], 15, UiKit.INK if sim.rep_level() >= int(st["rep"]) else UiKit.TERRA))
		var docked_home := sim.ships_of().filter(func(x): return sim.docked(x) and x["port"] == _port)
		for sh in docked_home:
			var id: int = sh["id"]
			side_body.add_child(UiKit.button("从 %s 交付物资" % sh["name"], func(): _act(sim.deliver_mats(id)), true))
		if Industry.has_wh(sim, _port, sim.pid()):
			side_body.add_child(UiKit.button("从商馆仓库交付物资", func(): _act(sim.deliver_from_wh()), true))
		var go := UiKit.button("支付 %s 金开工" % UiKit.money(st["gold"]), func(): _act(sim.start_lighthouse()))
		go.disabled = not sim.mats_ready() or sim.house()["gold"] < st["gold"]
		side_body.add_child(go)
	side_body.add_child(HSeparator.new())
	side_body.add_child(UiKit.label("对手进度", 16, UiKit.INK, true))
	for hid in GameData.HOUSE_IDS:
		if hid == sim.pid():
			continue
		var rl: Dictionary = sim.house(hid)["lh"]
		var txt := "%s：%d/3 层%s" % [GameData.HOUSES[hid]["name"], rl["stage"], "（施工中）" if rl["building"] else ""]
		if sim.house(hid)["bankrupt"]:
			txt = "%s：已破产" % GameData.HOUSES[hid]["name"]
		side_body.add_child(UiKit.label(txt, 15, UiKit.MUTED))
	_grand_rows()


## The grand works of the cloud sea (round 28), under the lighthouse.
func _grand_rows() -> void:
	var stage: int = sim.house()["lh"]["stage"]
	side_body.add_child(HSeparator.new())
	side_body.add_child(UiKit.label("云海大工程", 16, UiKit.INK, true))
	if stage < GameData.GRAND_STAGE:
		side_body.add_child(UiKit.para("灯塔建到%s之后，可以出资建造改变整个云海的大工程：每项只有一家能建成，建成者留名，全云海受益，建造者受益更多。" % GameData.LIGHTHOUSE[GameData.GRAND_STAGE - 1]["name"], 13, UiKit.MUTED))
		return
	_hint("grand")
	for gw in GameData.GRAND:
		var g := sim.grand_state(gw["id"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 0)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var done_by: String = ""
		if not g.is_empty():
			done_by = "%s%s" % [GameData.HOUSES[g["hid"]]["name"], ("建成于 " + GameData.date_text(int(g["end"]))) if g["done"] else ("在建，还 %d 天" % maxi(0, int(g["end"]) - int(sim.s["day"])))]
		col.add_child(UiKit.label("%s · %s 金 · %d 天 · 名声 +%d" % [gw["name"], UiKit.money(gw["gold"]), int(gw["days"]), int(gw["prize"])], 14, UiKit.BRASS if not g.is_empty() and g["hid"] == sim.pid() else UiKit.INK, true))
		var d := UiKit.label(gw["desc"] + (("　" + done_by) if done_by != "" else ""), 12, UiKit.UP if not g.is_empty() and g["done"] else UiKit.MUTED)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(d)
		row.add_child(col)
		if g.is_empty():
			var gid: String = gw["id"]
			var ok := sim.grand_ok(gid)
			var b := UiKit.button("开工", func(): _act(sim.start_grand(gid)))
			b.disabled = not ok["ok"]
			b.tooltip_text = ok.get("msg", "出资开工")
			b.add_theme_font_size_override("font_size", 13)
			row.add_child(b)
		side_body.add_child(row)


# =================================================================== actions

func _act(res: Dictionary) -> void:
	_toast(res["msg"], "good" if res["ok"] else "bad")
	_refresh_all()
	_update_tutorial()


## One click on ◀ / ▶ in the trade table, following the current mode and quantity.
func _trade_op(left: bool, g: String) -> void:
	var fl := sim.flagship()
	var q := _trade_qty
	var res: Dictionary
	match _trade_mode:
		0:
			res = sim.buy(fl["id"], g, q) if left else sim.sell(fl["id"], g, q)
		1:
			res = sim.buy_to_wh(_port, g, q) if left else sim.sell_from_wh(_port, g, q)
		2:
			res = sim.load_wh(fl["id"], g, q) if left else sim.unload_wh(fl["id"], g, q)
	if res["ok"] and res.has("profit") and int(res["profit"]) > 0:
		_float_profit(int(res["profit"]))
		sfx("coin")
	elif res["ok"]:
		sfx("click")
	_act(res)


func _trade(is_buy: bool, g: String, qty: int) -> void:
	var fl := sim.flagship()
	var res := sim.buy(fl["id"], g, qty) if is_buy else sim.sell(fl["id"], g, qty)
	if res["ok"] and not is_buy and int(res["profit"]) > 0:
		_float_profit(int(res["profit"]))
		sfx("coin")
	elif res["ok"]:
		sfx("click")
	_act(res)


## Send one of the player's own ships (a survey boat exploring on its own) somewhere.
func _sail_ship(ship_id: int, dest: String) -> void:
	var sh := sim.ship(ship_id)
	if sh.get("flagship", false):
		_sail(dest)
		return
	var res := sim.depart(ship_id, dest)
	_act(res)
	if res["ok"]:
		sfx("sail")
		map.set_region(GameData.region_of(dest))
		_refresh_region_btn()
		_refresh_fleet()
		_refresh_side()


func _sail(dest: String) -> void:
	var fl := sim.flagship()
	var res := sim.depart(fl["id"], dest)
	_act(res)
	if res["ok"]:
		sfx("sail")
		_flag_docked = false
		map.set_region(GameData.region_of(dest))
		_refresh_region_btn()
		if _in_town:
			_leave_town()
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
	elif "落成" in text and GameData.HOUSES[sim.pid()]["name"] in text:
		sfx("gong")
	if kind == "month":
		return
	if kind == "contract":
		sfx("bell")
	var col: Color = {"info": UiKit.INK, "good": UiKit.JADE, "bad": UiKit.TERRA, "major": UiKit.BRASS, "contract": UiKit.BRASS, "rival": Color("8a5a7a")}.get(kind, UiKit.INK)
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

func _modal(title: String, art: String, lines: Array, buttons: Array, width: int = 640, faces: Array = []) -> VBoxContainer:
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
	var text_box: VBoxContainer = v
	if not faces.is_empty():
		# who is speaking: their portraits beside the text (finish plan, phase C)
		var fh := HBoxContainer.new()
		fh.add_theme_constant_override("separation", 14)
		var fv := VBoxContainer.new()
		fv.add_theme_constant_override("separation", 6)
		for f in faces:
			var fr := PanelContainer.new()
			fr.add_theme_stylebox_override("panel", UiKit.box(Color("fbf5e6"), UiKit.BRASS, 6, 2, 2))
			fr.add_child(UiKit.icon(UiKit.portrait(f[0], f[1]), 112 if faces.size() == 1 else 84))
			fv.add_child(fr)
		fh.add_child(fv)
		text_box = VBoxContainer.new()
		text_box.add_theme_constant_override("separation", 10)
		text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fh.add_child(text_box)
		v.add_child(fh)
	text_box.add_child(UiKit.label(title, 26, UiKit.INK, true))
	for line in lines:
		text_box.add_child(UiKit.para(line, 17))
	var row: Container
	if buttons.size() > 3:
		# many choices wrap onto a second line instead of squeezing past the screen edge
		var flow := HFlowContainer.new()
		flow.alignment = FlowContainer.ALIGNMENT_END
		flow.add_theme_constant_override("h_separation", 10)
		flow.add_theme_constant_override("v_separation", 8)
		row = flow
	else:
		var hb := HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_END
		hb.add_theme_constant_override("separation", 10)
		row = hb
	for b in buttons:
		row.add_child(UiKit.button(b[0], b[1], b.size() > 2 and b[2]))
	v.add_child(row)
	return v


func _close_modal() -> void:
	for tw in _fx_tweens:
		if tw is Tween and tw.is_valid():
			tw.kill()
	_fx_tweens.clear()
	if modal_layer == null:
		return
	UiKit.clear(modal_layer)
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_modal_open = false


func _show_event() -> void:
	var ev: Dictionary = sim.s["event"]
	var eid := str(ev["id"])
	for pre in ["rival", "quest", "pair", "trio"]:
		if eid.begins_with(pre + ":"):
			_hint("pair" if pre == "trio" else pre)
	var btns := []
	for i in ev["choices"].size():
		btns.append([ev["choices"][i]["label"], _choose_event.bind(i), i > 0])
	_modal(ev["title"], ev["art"] if ev["art"] != "" else "explore_scene", [ev["text"]], btns, 640, _event_faces(eid))


## Portraits for the people in an event: [[portrait id, mood], ...].
func _event_faces(eid: String) -> Array:
	var parts := eid.split(":")
	match parts[0]:
		"char":
			return [[parts[1], ""]]
		"quest":
			return [[Characters.quest_cid(eid.substr(6)), ""]]
		"pair":
			var pr: Dictionary = Characters.PAIRS[int(parts[1])]
			return [[pr["a"], ""], [pr["b"], ""]]
		"trio":
			return Characters.TRIOS[int(parts[1])]["who"].map(func(c): return [c, ""])
		"rival":
			return [["hero_" + parts[1], ""]]
		"bail", "farewell":
			return [["hero_" + parts[1], "upset"]]
	if eid.begins_with("story_"):
		return [["luqing", "upset" if eid == "story_1" else ""]]
	return []


func _choose_event(idx: int) -> void:
	EventBook.resolve(sim, idx)   # its outcome reaches the toasts through Sim.message
	_close_modal()
	_refresh_all()
	if sim.s["event"] != null:
		_show_event()


func _recruit_rows(where: String) -> void:
	var rc := sim.recruitable_at(_port, where)
	if rc.is_empty():
		return
	_hint("recruit")
	side_body.add_child(HSeparator.new())
	side_body.add_child(UiKit.label("在这里能遇到的人", 16, UiKit.INK, true))
	for cid in rc:
		side_body.add_child(_char_card(cid, where))


func _abil_text(cid: String) -> String:
	var a: Dictionary = Characters.CHARS[cid]["abil"]
	return "航海 %d · 交易 %d · 战斗 %d · 魅力 %d" % [int(a["sail"]), int(a["trade"]), int(a["fight"]), int(a["charm"])]


func _char_card(cid: String, where: String) -> Control:
	var c: Dictionary = Characters.CHARS[cid]
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiKit.box(Color("fbf5e6"), Color(UiKit.BRASS, 0.55), 6, 1, 8))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	box.add_child(hb)
	hb.add_child(UiKit.icon(UiKit.portrait(cid), 64))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(UiKit.label("%s · %s" % [c["name"], c["title"]], 15, UiKit.INK, true))
	var st := UiKit.label(c["style"], 12, UiKit.MUTED)
	st.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(st)
	v.add_child(UiKit.label(_abil_text(cid), 12, UiKit.INK))
	var sp := UiKit.label("专长「%s」：%s" % [c["spec_name"], c["spec_desc"]], 12, UiKit.JADE)
	sp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(sp)
	var ok := sim.recruit_ok(cid, _port, where)
	v.add_child(UiKit.label("条件：%s · 安家费 %s 金 · 月薪 %d" % [Characters.cond_text(cid), UiKit.money(c["fee"]), int(c["wage"])] + ("" if ok["ok"] else " · " + ok["msg"]), 12, UiKit.MUTED if ok["ok"] else UiKit.TERRA))
	hb.add_child(v)
	var b := UiKit.button("招募", func(): _act(sim.recruit(cid, _port, where)); _refresh_all())
	b.disabled = not ok["ok"]
	b.tooltip_text = ok.get("msg", "")
	hb.add_child(b)
	return box


func _show_crew() -> void:
	var v := _modal("伙伴 · %d / %d" % [sim.crew().size(), sim.crew_cap()], "", [
		"岗位加成来自各人的能力；送礼（%d 金，每月一次）、一起航行、打赢云盗、完成委托都涨好感，好感到 %d / %d / %d 会在港口触发个人剧情，走完三章专长更强；两位好感都过 %d 的伙伴之间还会有他们自己的故事，好感到 %d 时伙伴会托你办一件私事，限期送一批货，办成有谢礼与名声，误期会伤感情；办成后好感到 %d 还有第二件更大的托付，办成的伙伴从此不领薪水。每月薪水合计 %d 金%s。" % [Characters.GIFT_COST, Characters.CHAPTER_AFF[0], Characters.CHAPTER_AFF[1], Characters.CHAPTER_AFF[2], Characters.PAIR_AFF, Characters.QUEST_AFF, Characters.QUEST2_AFF, sim.crew_wages(), ("（会馆折扣 %d%%）" % int(round((1.0 - float(GameData.HQ[sim.hq_level()]["wage"])) * 100.0))) if sim.hq_level() >= 2 else ""],
	], [["关闭", func(): _close_modal()]], 760)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	if sim.crew().is_empty():
		list.add_child(UiKit.para("还没有伙伴。去各城的酒馆、船坞和行会看看，有人在等一个像样的商会。", 14, UiKit.MUTED))
	for cid in Characters.IDS:
		if not sim.crew().has(cid):
			continue
		var c: Dictionary = Characters.CHARS[cid]
		var m: Dictionary = sim.crew()[cid]
		var box := PanelContainer.new()
		box.add_theme_stylebox_override("panel", UiKit.box(Color("fbf5e6"), Color(UiKit.BRASS, 0.5), 6, 1, 8))
		var hb := HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		box.add_child(hb)
		hb.add_child(UiKit.icon(UiKit.portrait(cid, "happy" if int(sim.crew()[cid]["aff"]) >= 60 else ""), 60))
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 1)
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(UiKit.label("%s · %s · 剧情 %d/3" % [c["name"], c["title"], int(m["chapter"])], 15, UiKit.INK, true))
		col.add_child(UiKit.label(_abil_text(cid) + (" · 不领薪水" if m.get("free", false) else " · 月薪 %d" % int(c["wage"])), 12, UiKit.MUTED))
		col.add_child(UiKit.label("专长「%s」%s：%s" % [c["spec_name"], "★" if int(m["spec_lvl"]) >= 2 else "", c["spec_desc"]], 12, UiKit.JADE))
		var bar := ProgressBar.new()
		bar.max_value = 100
		bar.value = int(m["aff"])
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 8)
		col.add_child(bar)
		var nxt := ""
		if int(m["chapter"]) < 3:
			nxt = " · 下一章 %d" % Characters.CHAPTER_AFF[int(m["chapter"])]
		col.add_child(UiKit.label("好感 %d%s" % [int(m["aff"]), nxt], 12, UiKit.MUTED))
		var active_key := ""
		for key in [cid, cid + "#2"]:
			var qs := sim.quest_state(key)
			if qs == "":
				continue
			var q := Characters.quest_def(key)
			var which := "第二件托付" if key.ends_with("#2") else "托付"
			var qtxt := ""
			match qs:
				"active":
					qtxt = "%s「%s」：%s，还剩 %d 天，谢礼 %d 金" % [which, q["title"], Characters.quest_ask(key), int(sim.quests()[key]["end"]) - int(sim.s["day"]), int(q["gold"])]
					active_key = key
				"done":
					qtxt = "%s「%s」已办成。" % [which, q["title"]]
				"failed":
					qtxt = "%s「%s」没能赶上。" % [which, q["title"]]
				"declined":
					qtxt = "%s「%s」你当时没有接。" % [which, q["title"]]
			col.add_child(UiKit.label(qtxt, 12, UiKit.TERRA if qs == "active" else UiKit.MUTED))
		if m.get("free", false):
			col.add_child(UiKit.label("信物：%s · 不再领薪水" % str(m.get("keepsake", "")), 12, UiKit.JADE))
		hb.add_child(col)
		var ctl := VBoxContainer.new()
		ctl.add_theme_constant_override("separation", 4)
		var ob := OptionButton.new()
		var opts := [["", "无岗位"]]
		for pk in Characters.POSTS:
			if pk == "captain":
				for sh in sim.ships_of():
					if not sh["flagship"]:
						opts.append(["captain:%d" % int(sh["id"]), "船长 · %s" % sh["name"]])
			else:
				opts.append([pk, "%s（%s）" % [Characters.POSTS[pk]["name"], Characters.POSTS[pk]["desc"]]])
		var cur_key: String = m["post"] + (":%d" % int(m["ship"]) if m["post"] == "captain" else "")
		for i in opts.size():
			ob.add_item(opts[i][1])
			if opts[i][0] == cur_key:
				ob.select(i)
		var ccid: String = cid
		ob.item_selected.connect(func(i):
			var key: String = opts[i][0]
			if key.begins_with("captain:"):
				_act(sim.set_post(ccid, "captain", int(key.substr(8))))
			else:
				_act(sim.set_post(ccid, key))
			_show_crew())
		ctl.add_child(ob)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 4)
		var gb := UiKit.button("送礼 %d" % Characters.GIFT_COST, func(): _act(sim.gift(ccid)); _show_crew(), true)
		gb.disabled = int(m["gift_month"]) == int(sim.s["day"]) / GameData.DAYS_MONTH or sim.house()["gold"] < Characters.GIFT_COST
		gb.add_theme_font_size_override("font_size", 12)
		row.add_child(gb)
		var db := UiKit.button("辞退", func(): _act(sim.dismiss(ccid)); _show_crew(), true)
		db.add_theme_font_size_override("font_size", 12)
		db.tooltip_text = "辞退后不会再回来。"
		row.add_child(db)
		ctl.add_child(row)
		if active_key != "" and str(Characters.quest_def(active_key).get("kind", "deliver")) != "fight":
			var qok := sim.quest_ok(active_key)
			var qkey := active_key
			var qb := UiKit.button("交付托付", func(): _act(sim.quest_deliver(qkey)); _show_crew(), true)
			qb.disabled = not qok["ok"]
			qb.tooltip_text = "" if qok["ok"] else qok["msg"]
			qb.add_theme_font_size_override("font_size", 12)
			ctl.add_child(qb)
		hb.add_child(ctl)
		list.add_child(box)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(740, minf(600.0, 20.0 + 150.0 * maxf(1.0, float(sim.crew().size()))))
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	v.add_child(scroll)
	v.move_child(scroll, v.get_child_count() - 2)


func _show_encounter() -> void:
	var e = sim.s["encounter"]
	if e == null:
		return
	_hint("encounter")
	var bounty: bool = e["kind"] == "bounty"
	var fl := sim.flagship()
	var lines := [sim.encounter_text()]
	var mine := []
	for o in sim.fleet_ships(fl):
		var u := sim.unit_of(o)
		mine.append("%s 耐久 %d · 船员 %d · 炮 %d" % [o["name"], int(u["hp"]), int(u["crew"]), int(u["guns"])])
	lines.append("我方：" + "；".join(mine) + "。主角战斗 %d 级，指挥点 %d。" % [sim.hero_abil("fight"), 1 + (sim.hero_abil("fight") - 1) / 4])
	if bounty:
		lines.append("这是你接下的悬赏目标，没有退路：打赢了领赏，输了就得付出代价。")
	else:
		lines.append("交过路费最省事；甩开要看航海本事和船速（成功率约 %d%%），甩不掉就只能硬碰硬。" % int(roundf(sim.flee_chance() * 100.0)))
	var btns := [["应战", func(): _close_modal(); sim.encounter_fight(); _open_battle()]]
	if not bounty:
		btns.append(["交过路费 · %s 金" % UiKit.money(sim.toll()), func(): _act(sim.encounter_pay()); _close_modal(); _refresh_all(), true])
		btns.append(["甩开他们", func():
			var r := sim.encounter_flee()
			_close_modal()
			if r.get("escaped", false):
				sfx("sail")
				_toast(r["msg"], "good")
				_refresh_all()
			else:
				_toast("甩不掉，接战！", "bad")
				_open_battle(), true])
	_modal("剿匪 · %s" % GameData.port_name(fl["port"]) if bounty else "云盗拦路", "events/00", lines, btns, 720)


func _open_battle() -> void:
	if sim.battle == null:
		return
	_set_speed(0)
	sfx("gong")
	battle_view.visible = true
	battle_view.open(sim.battle)


func _on_battle_finished() -> void:
	battle_view.visible = false
	var out := sim.end_battle()
	if not out.get("ok", true):
		return
	var res: String = out["res"]
	var lines := [{"win": "云盗的旗舰失守，残部四散逃进云层。", "loss": "旗舰被打得千疮百孔，云盗搬空了货舱才扬长而去。", "withdraw": "船队退出了战场，云盗没有追来。"}[res]]
	var parts := []
	if int(out["bounty"]) > 0:
		parts.append("悬赏 %s 金" % UiKit.money(out["bounty"]))
	if int(out["gold"]) != 0:
		parts.append("金币 %+d" % int(out["gold"]))
	for gq in out["goods"]:
		parts.append("%s ×%d" % [GameData.good_name(gq[0]), int(gq[1])])
	if int(out["rep"]) > 0:
		parts.append("名声 +%d" % int(out["rep"]))
	if int(out["exp"]) > 0:
		parts.append("主角经验 +%d" % int(out["exp"]))
	if not parts.is_empty():
		lines.append("收获：" + "、".join(parts) + "。")
	if not out["won"].is_empty():
		lines.append("俘获：" + "、".join(out["won"]) + "。")
	if not out["lost"].is_empty():
		lines.append("失去：" + "、".join(out["lost"]) + "。")
	if res == "win":
		sfx("coin")
	_modal({"win": "大获全胜", "loss": "败北", "withdraw": "撤退"}[res], "events/09" if res == "loss" else "events/00", lines, [["继续", func(): _close_modal(); _refresh_all()]], 640)
	_refresh_all()


func _confirm_route(ship_id: int, stops: Array) -> void:
	var res := sim.set_route(ship_id, {"stops": stops})
	_act(res)
	if res["ok"]:
		_close_modal()
		_refresh_fleet()


func _lighthouse_cutscene(stage: int) -> void:
	_set_speed(0)
	sfx("gong")
	var st: Dictionary = GameData.LIGHTHOUSE[stage - 1]
	var v := _modal("灯塔%s落成" % st["name"], "", [
		"第 %d 层已经立起来了。%s" % [stage, "灯冠点亮之时，你就是云海盟主。" if stage < 3 else "灯冠点亮了！"],
		"名声 +%d。" % [300, 600, 2000][stage - 1],
	], [["继续", func(): _close_modal(); if sim.s["event"] != null: _show_event()]], 520)
	var holder := CenterContainer.new()
	holder.custom_minimum_size = Vector2(520, 300)
	holder.clip_contents = true
	# a warm glow behind the tower, lit once it stands
	var glow := TextureRect.new()
	var gt := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color(1.0, 0.86, 0.5, 0.95))
	gr.set_color(1, Color(1.0, 0.8, 0.4, 0.0))
	gt.gradient = gr
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	gt.width = 64
	gt.height = 64
	glow.texture = gt
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.custom_minimum_size = Vector2(300, 300)
	glow.pivot_offset = Vector2(150, 150)
	glow.modulate.a = 0.0
	holder.add_child(glow)
	# the beam that sweeps once the lamp is lit
	var beam := ColorRect.new()
	beam.color = Color(1.0, 0.95, 0.7, 0.0)
	beam.custom_minimum_size = Vector2(900, 26)
	beam.pivot_offset = Vector2(0, 13)
	beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var img := UiKit.icon(UiKit.sprite("lighthouse", st["sprite"]), 280)
	img.pivot_offset = Vector2(140, 280)
	img.scale = Vector2(1.0, 0.05)
	img.modulate.a = 0.0
	holder.add_child(img)
	holder.add_child(beam)
	v.add_child(holder)
	v.move_child(holder, 0)
	var tw := create_tween()
	_fx_tweens.append(tw)
	tw.tween_property(img, "modulate:a", 1.0, 0.3)
	tw.parallel().tween_property(img, "scale", Vector2.ONE, 1.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(glow, "modulate:a", 1.0, 0.8)
	tw.parallel().tween_property(glow, "scale", Vector2(1.15, 1.15), 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func():
		beam.position = Vector2(260, 40)
		beam.rotation = -0.9
		var bt := create_tween()
		_fx_tweens.append(bt)
		bt.tween_property(beam, "color:a", 0.55, 0.2)
		bt.parallel().tween_property(beam, "rotation", 0.9, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		bt.tween_property(beam, "color:a", 0.0, 0.4)
		if not is_instance_valid(glow) or not glow.is_inside_tree():
			return
		var pulse := create_tween().set_loops()
		_fx_tweens.append(pulse)
		pulse.tween_property(glow, "scale", Vector2(1.0, 1.0), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		pulse.tween_property(glow, "scale", Vector2(1.15, 1.15), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT))


## A grand work is finished: the scene, what it changes, and what the three leaders say (round 29).
func _grand_ceremony(gs: Dictionary) -> void:
	_set_speed(0)
	sfx("gong")
	var gw := Sim.grand_def(gs["id"])
	var hid: String = gs["hid"]
	var mine := hid == sim.pid()
	var lines := ["%s 的%s落成了。%s" % [GameData.HOUSES[hid]["name"], gw["name"], gw["desc"]],
		"%s名声 +%d。" % ["你的" if mine else GameData.HOUSES[hid]["name"], int(gw["prize"])]]
	var v := _modal("%s落成" % gw["name"], GameData.GRAND_ART.get(gs["id"], ""), lines, [["继续", func(): _close_modal(); if sim.s["event"] != null: _show_event()]], 700)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	var said: Dictionary = GameData.GRAND_LINES[gs["id"]]
	var order := [hid]
	for o in GameData.HOUSE_IDS:
		if o != hid and not sim.house(o)["bankrupt"]:
			order.append(o)
	for o in order:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(UiKit.icon(UiKit.sprite("emblems", GameData.HOUSES[o]["emblem"]), 26))
		var l := UiKit.label(said[o]["built" if o == hid else "other"], 14, UiKit.INK if o == hid else Color("6b5a3e"))
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(l)
		box.add_child(row)
	v.add_child(box)
	v.move_child(box, v.get_child_count() - 2)


func _crown_celebration() -> void:
	_set_speed(0)
	sfx("gong")
	_modal("云海盟主", "story_loyalty", [
		"你的灯冠第一个点亮。云海诸港奉%s为盟主，各城友好度大增。" % GameData.HOUSES[sim.pid()]["name"],
		"这不是结束。云海还在，生意还在，继续经营你的商会吧。",
		"净资产 %s · 用时 %s" % [UiKit.money(sim.net_worth()), GameData.date_text(sim.s["day"])],
	], [["继续经营", func(): _close_modal()]])
	for port in GameData.PORT_IDS:
		sim.add_friend(port, sim.pid(), 300)


func _ship_card(sh: Dictionary) -> Control:
	var id: int = sh["id"]
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", UiKit.box(Color("faf3e3"), Color(UiKit.BRASS, 0.5), 6, 1, 8))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	box.add_child(v)
	var hd := HBoxContainer.new()
	hd.add_theme_constant_override("separation", 8)
	hd.add_child(UiKit.icon(UiKit.sprite("ships", GameData.SHIPS[sh["type"]]["sprite"]), 44))
	var tv := VBoxContainer.new()
	tv.add_theme_constant_override("separation", 0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UiKit.label("%s%s · %s" % ["★ " if sh["flagship"] else "", sh["name"], GameData.SHIPS[sh["type"]]["name"]], 16, UiKit.INK, true))
	var bu := sim.unit_of(sh)
	tv.add_child(UiKit.label("货舱 %d · 航速 ×%.2f · 炮 %d · 耐久 %d/%d · 船员 %d" % [sim.cargo_cap(sh), sim.speed_mult(sh), int(bu["guns"]), int(bu["hp"]), int(bu["hp_max"]), int(bu["crew"])], 12, UiKit.MUTED if int(sh.get("dmg", 0)) == 0 else UiKit.TERRA))
	hd.add_child(tv)
	if sim.docked(sh) and not GameData.PORTS.has(sh["port"]) and not sh["flagship"] and not sim.in_fleet(sh):
		# a survey boat anchored in the fog: call it back to the nearest charted port
		var back := sim.nearest_open_port(sh["port"])
		var bb := UiKit.button("返航 %s · %d 天" % [GameData.port_name(back), sim.ship_days(sh, back)], func(): _sail_ship(id, back), true)
		bb.add_theme_font_size_override("font_size", 12)
		bb.tooltip_text = "停在 %s。也可以在海图上点一个「?」派它继续探索。" % GameData.port_name(sh["port"])
		hd.add_child(bb)
	if int(sh.get("dmg", 0)) > 0:
		var rpb := UiKit.button("修理 %s 金" % UiKit.money(sim.repair_cost(sh)), func(): _act(sim.repair_ship(id)); _refresh_fleet(); _refresh_side())
		rpb.add_theme_font_size_override("font_size", 12)
		rpb.tooltip_text = "战损 %d%%。停在港口每天也会自己修好一点。" % int(sh["dmg"])
		rpb.disabled = sim.house()["gold"] < sim.repair_cost(sh)
		hd.add_child(rpb)
	var name_edit := LineEdit.new()
	name_edit.text = sh["name"]
	name_edit.max_length = 8
	name_edit.custom_minimum_size = Vector2(84, 0)
	name_edit.tooltip_text = "改名后按回车（最多 8 字）"
	name_edit.text_submitted.connect(func(t): _act(sim.rename_ship(id, t)); _refresh_fleet(); _refresh_side())
	hd.add_child(name_edit)
	if sim.in_fleet(sh):
		var ob := OptionButton.new()
		var keys := GameData.SLOTS.keys()
		for k in keys:
			ob.add_item(GameData.SLOTS[k])
		ob.select(keys.find(sh.get("slot", "main")))
		ob.item_selected.connect(func(i): _act(sim.set_slot(id, keys[i])); _refresh_fleet())
		ob.tooltip_text = "编队位置：影响空战的开局站位（第 8 轮）"
		hd.add_child(ob)
	if not sh["flagship"] and not sh.has("loan"):
		var sb := UiKit.button("出售", func(): _act(sim.sell_ship(id)); _refresh_fleet(); _refresh_side(), true)
		sb.add_theme_font_size_override("font_size", 12)
		sb.tooltip_text = "卖掉这艘船，得 %s 金（船价六成）；船上的货会一并处理掉" % UiKit.money(GameData.SHIPS[sh["type"]]["price"] * 0.6)
		hd.add_child(sb)
	v.add_child(hd)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 2)
	for k in GameData.REFITS:
		var r: Dictionary = GameData.REFITS[k]
		var lvl := sim.mod_lvl(sh, k)
		grid.add_child(UiKit.label("%s %d/%d" % [r["name"], lvl, GameData.REFIT_MAX], 13, UiKit.INK, true))
		var dl := UiKit.label(r["desc"], 12, UiKit.MUTED)
		dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		dl.custom_minimum_size = Vector2(120, 0)
		grid.add_child(dl)
		if lvl >= GameData.REFIT_MAX:
			grid.add_child(UiKit.label("满级", 12, UiKit.UP, true))
			grid.add_child(Control.new())
			continue
		var plan := sim.refit_plan(sh, k)
		var need := sim.refit_cost(sh, k)
		_hint("refit")
		var mats := []
		for g in need["mats"]:
			mats.append("%s×%d" % [GameData.good_name(g), int(need["mats"][g])])
		var ml := UiKit.label("、".join(mats), 12, UiKit.INK if plan["ok"] else UiKit.TERRA)
		ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ml.custom_minimum_size = Vector2(96, 0)
		grid.add_child(ml)
		var kk: String = k
		var b := UiKit.button("%s 金" % UiKit.money(plan["gold"]), func(): _act(sim.refit(id, kk)); _refresh_fleet(); _refresh_side(), true)
		b.add_theme_font_size_override("font_size", 12)
		b.disabled = not plan["ok"] or sim.house()["gold"] < plan["gold"]
		var src := []
		for pt in plan["parts"]:
			src.append("%s：船上 %d · 商馆 %d · 市场 %d%s" % [GameData.good_name(pt["good"]), int(pt["hold"]), int(pt["wh"]), int(pt["mkt"]), ("（缺 %d）" % int(pt["short"])) if int(pt["short"]) > 0 else ""])
		b.tooltip_text = "工费 %d 金 + 采购 %d 金\n" % [int(plan["fee"]), int(plan["gold"]) - int(plan["fee"])] + "\n".join(src)
		grid.add_child(b)
	v.add_child(grid)
	return box


func _show_route_dialog(ship_id: int) -> void:
	var sh := sim.ship(ship_id)
	var cur = sh["route"]
	var v := _modal("自动航线 · %s" % sh["name"], "", ["船会沿着这些站循环：每到一站卖掉船上不在该站采购单里的货，再按采购单装货（价格不划算时少买或空跑）。2–4 站，每站最多买 3 种。"], [], 700)
	var stops: Array = []
	if cur != null:
		for st in Sim.normalize_route(cur)["stops"]:
			stops.append({"port": st["port"], "buy": st["buy"].duplicate()})
	else:
		var tg := _tutorial_goal()
		stops = [{"port": tg["home"], "buy": [tg["good"]]}, {"port": tg["dest"], "buy": []}]
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	v.add_child(list)
	v.move_child(list, v.get_child_count() - 2)
	var est := UiKit.para("", 14, UiKit.JADE)
	v.add_child(est)
	v.move_child(est, v.get_child_count() - 2)
	var rebuild: Callable
	var update_est := func():
		var days := 0
		for i in stops.size():
			days += GameData.travel_days(stops[i]["port"], stops[(i + 1) % stops.size()]["port"], sh["type"])
		var hints := []
		for i in stops.size():
			for g in stops[i]["buy"]:
				var ia = sim.s["intel"][stops[i]["port"]]
				var best := -99999
				for j in range(1, stops.size()):
					var o: Dictionary = stops[(i + j) % stops.size()]
					var io = sim.s["intel"][o["port"]]
					if io != null and ia != null and not g in o["buy"]:
						best = maxi(best, int(io["prices"][g][1]) - int(ia["prices"][g][0]))
				hints.append("%s %s" % [GameData.good_name(g), ("每件 %+d" % best) if best > -99999 else "无行情"])
		est.text = "一圈约 %d 天 · 满载 %d 件 · 按已知行情：%s" % [days, sim.cargo_cap(sh), "，".join(hints) if not hints.is_empty() else "还没选要买的货"]
	rebuild = func():
		UiKit.clear(list)
		for i in stops.size():
			var idx: int = i
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 6)
			row.add_child(UiKit.label("第 %d 站" % (i + 1), 14, UiKit.MUTED, true))
			var op := OptionButton.new()
			var ports: Array = sim.open_ports()
			for pid in ports:
				op.add_item(GameData.port_name(pid))
			op.select(ports.find(stops[i]["port"]))
			op.item_selected.connect(func(k): stops[idx]["port"] = ports[k]; update_est.call())
			row.add_child(op)
			row.add_child(UiKit.label("买", 14, UiKit.MUTED))
			for slot in GameData.ROUTE_MAX_BUYS:
				var og := OptionButton.new()
				og.add_item("—")
				for g in GameData.GOOD_IDS:
					og.add_item(GameData.good_name(g))
				var cur_g: String = stops[i]["buy"][slot] if slot < stops[i]["buy"].size() else ""
				og.select(0 if cur_g == "" else GameData.GOOD_IDS.find(cur_g) + 1)
				var ss: int = slot
				og.item_selected.connect(func(k):
					var buys: Array = stops[idx]["buy"]
					while buys.size() <= ss:
						buys.append("")
					buys[ss] = "" if k == 0 else GameData.GOOD_IDS[k - 1]
					stops[idx]["buy"] = buys.filter(func(x): return x != "")
					update_est.call())
				row.add_child(og)
			var sp := Control.new()
			sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(sp)
			var del := UiKit.button("✕", func(): stops.remove_at(idx); rebuild.call(), true)
			del.disabled = stops.size() <= 2
			row.add_child(del)
			list.add_child(row)
		if stops.size() < GameData.ROUTE_MAX_STOPS:
			list.add_child(UiKit.button("+ 加一站", func(): var ps: Array = sim.open_ports(); stops.append({"port": ps[(ps.find(stops[stops.size() - 1]["port"]) + 1) % ps.size()], "buy": []}); rebuild.call(), true))
		update_est.call()
	rebuild.call()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	row.add_child(UiKit.button("取消", func(): _close_modal(), true))
	if cur != null:
		row.add_child(UiKit.button("清除航线", func(): _act(sim.set_route(ship_id, {})); _close_modal(); _refresh_fleet(), true))
	row.add_child(UiKit.button("确认航线", func(): _confirm_route(ship_id, stops)))
	v.add_child(row)


func _show_ledger() -> void:
	var h := sim.house()
	var lines := [
		"金币 %s · 欠款 %s · 净资产 %s" % [UiKit.money(h["gold"]), UiKit.money(h["debt"]), UiKit.money(sim.net_worth())],
		"上月净收支 %+s · 每月固定开支约 %s（薪水、维护、利息）" % [UiKit.money(h.get("last_net", 0.0)), UiKit.money(h.get("last_upkeep", 0.0))],
		"累计成交 %d 笔 · 累计利润 %s · 最佳单笔 %s · 完成委托 %d 单" % [sim.s["stats"]["trades"], UiKit.money(sim.s["stats"]["profit"]), UiKit.money(sim.s["stats"]["best_trade"]), int(sim.s["stats"].get("contracts", 0))],
	]
	var pats: Array = []
	for port in GameData.PORT_IDS:
		if sim.patron(port) == sim.pid():
			pats.append(GameData.port_name(port))
	lines.append("你是港主的港口：%s" % ("、".join(pats) if not pats.is_empty() else "暂无"))
	lines.append("名声 %d（%s）· 图纸 %d 份 · 工坊 %d 座 · 每月产业开销 %s" % [int(h["rep"]), GameData.REP_NAMES[sim.rep_level() - 1], h["bp"].size(), Industry.all_buildings(sim, sim.pid()).size(), UiKit.money(Industry.upkeep(sim, sim.pid()))])
	for hid in GameData.HOUSE_IDS:
		if hid != sim.pid():
			lines.append("%s：%d 艘船 · 灯塔 %d/3 · 名声 %s · 工坊 %d 座%s" % [GameData.HOUSES[hid]["name"], sim.ships_of(hid).size(), sim.house(hid)["lh"]["stage"], GameData.REP_NAMES[sim.rep_level(hid) - 1], Industry.all_buildings(sim, hid).size(), " · 已破产" if sim.house(hid)["bankrupt"] else ""])
	var v := _modal("账簿", "", lines, [["关闭", func(): _close_modal()]], 700)
	# milestones (round 21)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	var done_n := 0
	for m in GameData.MILESTONES:
		if sim.milestone_done(m["id"]):
			done_n += 1
	box.add_child(UiKit.label("里程碑 %d / %d" % [done_n, GameData.MILESTONES.size()], 17, UiKit.INK, true))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 18)
	grid.add_theme_constant_override("v_separation", 2)
	var nxt: Array = sim.next_milestones(1)
	for m in GameData.MILESTONES:
		var done := sim.milestone_done(m["id"])
		var is_next: bool = not nxt.is_empty() and nxt[0]["id"] == m["id"]
		var when := ""
		if done:
			when = " · " + GameData.date_text(int(sim.milestones()[m["id"]])).split(" · ")[0]
		var l := UiKit.label("%s %s%s" % ["✓" if done else ("▶" if is_next else "○"), m["name"], when], 13, UiKit.JADE if done else (UiKit.INK if is_next else UiKit.MUTED), is_next)
		l.tooltip_text = m["desc"]
		l.custom_minimum_size = Vector2(310, 0)
		grid.add_child(l)
	box.add_child(grid)
	if not nxt.is_empty():
		box.add_child(UiKit.para("下一个：%s——%s" % [nxt[0]["name"], nxt[0]["desc"]], 13, UiKit.MUTED))
	v.add_child(box)
	v.move_child(box, v.get_child_count() - 2)


## What a house is up to: ships and their cargo, workshops, lighthouse needs, strongholds.
func _show_rival(hid: String) -> void:
	if hid == sim.pid():
		_show_ledger()
		return
	_hint("intel")
	var d: Dictionary = GameData.HOUSES[hid]
	var h := sim.house(hid)
	var lines := []
	lines.append("当家 %s · 特长：%s · 名声「%s」%s" % [d["leader"], d["perk_text"], GameData.REP_NAMES[sim.rep_level(hid) - 1], " · 已破产" if h["bankrupt"] else ""])
	# relationships (round 26)
	if sim.tie(hid) != 0:
		_hint("ties")
	var tst := sim.tie_state(hid)
	var st_text := {"ally": "不争你的工坊，你开工建灯塔时出一份钱，灯节带贺礼，当家在港时交换行情。", "feud": "收购他们的工坊便宜 %d%%，赛船论道赢了名声 ×%.1f；他们盯着你的工坊，灯节必来挑战。" % [int(roundf((1.0 - GameData.FEUD_BUYOUT) * 100.0)), GameData.FEUD_REP_MULT], "plain": "到 %d 可提议结盟（%d 起算盟友）；跌到 %d 就是宿敌。喝酒、买图纸、送礼拉近；赛船论道输的一方记仇，收购工坊、买通港务更伤。" % [GameData.TIE_ASK_MIN, GameData.TIE_ALLY, GameData.TIE_FEUD]}
	lines.append("与你的关系：%s（%d）· %s" % [sim.tie_name(hid), sim.tie(hid), st_text[tst]])
	var others := []
	for o in GameData.HOUSE_IDS:
		if o != hid and o != sim.pid() and not sim.house(o)["bankrupt"]:
			others.append("与%s：%s（%d）" % [GameData.HOUSES[o]["name"], sim.tie_name(hid, o), sim.tie(hid, o)])
	if not others.is_empty():
		lines.append("、".join(others) + "。两家对手结了盟会互相出钱建灯塔、合力争地；翻了脸则见面就赛、互使绊子。")
	var band := int(maxf(0.0, float(h["gold"])) / 10000.0) * 10000
	lines.append("家底：约 %s 金%s" % [UiKit.money(band), ("，欠款 %s" % UiKit.money(h["debt"])) if h["debt"] > 0.5 else ""])
	var lh: Dictionary = h["lh"]
	var lh_text := "灯塔 %d/3" % int(lh["stage"])
	if lh["building"]:
		lh_text += "，正在施工，还要 %d 天" % maxi(0, int(lh["end"]) - int(sim.s["day"]))
	elif int(lh["stage"]) < GameData.LIGHTHOUSE.size():
		var need := AiPlayer._needs(sim, hid)
		var parts := []
		for g in need:
			parts.append("%s %d" % [GameData.good_name(g), int(need[g])])
		var cost: int = GameData.LIGHTHOUSE[int(lh["stage"])]["gold"]
		var gold_gap := ("还差约 %s 金" % UiKit.money(cost - h["gold"])) if h["gold"] < cost else "钱够了"
		lh_text += "，下一阶「%s」：%s，%s" % [GameData.LIGHTHOUSE[int(lh["stage"])]["name"], ("还缺 " + "、".join(parts)) if not parts.is_empty() else "材料齐了", gold_gap]
	lines.append(lh_text)
	for sh in sim.ships_of(hid):
		var st := ""
		if sim.docked(sh):
			st = "停靠 %s" % GameData.port_name(sh["port"])
		else:
			st = "%s → %s，剩 %d 天" % [GameData.port_name(sh["from"]), GameData.port_name(sh["to"]), maxi(0, int(sh["arrive"]) - int(sim.s["day"]))]
		var cargo := []
		for g in sh["cargo"]:
			cargo.append("%s %d" % [GameData.good_name(g), int(sh["cargo"][g]["qty"])])
		lines.append("· %s（%s）：%s%s" % [sh["name"] if sh["name"] != "" else GameData.SHIPS[sh["type"]]["name"], GameData.SHIPS[sh["type"]]["name"], st, ("，载 " + "、".join(cargo)) if not cargo.is_empty() else "，空载"])
	var builds := {}
	for b in Industry.all_buildings(sim, hid):
		var key: String = GameData.port_name(b["port"])
		if not builds.has(key):
			builds[key] = []
		builds[key].append("%s%s" % [GameData.good_name(b["plot"]["b"]), ("×%d 级" % int(b["plot"]["lvl"])) if int(b["plot"]["lvl"]) > 1 else ""])
	var bl := []
	for k in builds:
		bl.append("%s（%s）" % [k, "、".join(builds[k])])
	lines.append("工坊：%s" % ("；".join(bl) if not bl.is_empty() else "暂无"))
	var pats := []
	for port in sim.open_ports():
		if sim.patron(port) == hid:
			pats.append(GameData.port_name(port))
	lines.append("港主：%s" % ("、".join(pats) if not pats.is_empty() else "暂无"))
	var bens := sim.benefactor_ports(hid).map(func(pp): return GameData.port_name(pp))
	lines.append("恩主：%s" % ("、".join(bens) if not bens.is_empty() else "暂无"))
	var bps := []
	for g in h["bp"]:
		bps.append(GameData.good_name(g))
	lines.append("持有图纸：%s" % ("、".join(bps) if not bps.is_empty() else "无"))
	var btns := []
	if not h["bankrupt"]:
		var hh: String = hid
		var gok := sim.tie_gift_ok(hid)
		var gb_label := "赠礼示好（%s 金，关系 +%d）" % [UiKit.money(GameData.TIE_GIFT_COST), GameData.TIE_GIFT]
		btns.append([gb_label if gok["ok"] else gb_label + " · " + str(gok["msg"]), func(): _act(sim.tie_gift(hh)); _show_rival(hh), true])
		if tst != "ally":
			var pok := sim.propose_ok(hid)
			btns.append([("提议结盟" if pok["ok"] else "提议结盟 · " + str(pok["msg"])), func(): _act(sim.propose_ally(hh)); _show_rival(hh), true])
		if tst != "feud":
			btns.append(["翻脸", func(): _modal("与%s翻脸？" % d["name"], "", ["从今天起两家是宿敌：收购他们的工坊便宜，赢他们名声更多，但他们会盯上你的工坊，灯节必来挑战。关系会跌到 %d，要靠送礼和赔酒慢慢修。" % (GameData.TIE_FEUD - 10)],
				[["翻脸", func(): _act(sim.break_off(hh)); _show_rival(hh), true], ["算了", func(): _show_rival(hh)]]), true])
	btns.append(["关闭", func(): _close_modal()])
	_modal("%s · 动向" % d["name"], "", lines, btns, 720)


func _show_menu() -> void:
	var music: AudioStreamPlayer = get_node("Music")
	_modal("菜单", "", ["游戏每月自动存档。"], [
		["音乐：" + ("开" if music.playing else "关"), func(): (music.stop() if music.playing else music.play()); _close_modal(), true],
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
	_modal(o["title"], "explore_scene", lines, [
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

## Shows a short explanation the first time something new appears; remembered in the save.
const HINTS := {
	"contract": "委托板：求购单先到先得，期限内把货送到就一次拿走全部酬金，比普通跑商划算得多。接下前先看看船上装不装得下。",
	"recruit": "有人愿意加入商会：伙伴安家费只付一次、月薪每月扣，派到岗位上就有加成，还各有一样专长。好感高了会有剧情、托付，办成托付的伙伴甚至不再领薪水。",
	"rival": "对手的当家来打招呼：赛船看航速和航海本事，论道看魅力和名声，都有输有赢；买他们的图纸最稳妥；买通港务拖住他们的船可能败露，会伤名声。",
	"encounter": "遇上云盗：交过路费最省事，甩开看航海本事和船速，开战是回合制空战——炮手和船只的火力、耐久决定胜负，打赢有好感与悬赏。",
	"festival": "灯节：每年开春颁三项奖——赛船冠军、年度商王、建设之光，各有奖金与名声。灯节 12 天里甜霞果、丝云绸、霞果酒卖价 +15%，对手的当家也可能来下战书。",
	"quest": "伙伴的托付：接下后记在伙伴面板里，送货类在目的港的酒馆或伙伴面板交付，同行类到港即成，误期会伤好感。",
	"pair": "伙伴之间的故事：两位（或三位）好感够高的伙伴在港口会有他们自己的场景，选项会影响各人的好感，偶尔还有小收获。",
	"works": "城建：在城主府出资修码头（补给更省、修船更快）、集市（行情恢复更快）、学堂（本城工坊增产）。出资最多的商会是本城恩主，买货更便宜、每月得名声。",
	"hq": "商会总部：回到母港的商馆页可以扩建会馆，伙伴上限更高、每月添名声、薪水有折扣，最高一级还能多带一艘船。",
	"intel": "对手情报：点顶栏的商会名随时查看对手的船、工坊、恩主城和灯塔进度。他们在同一港时，当家会来打招呼。",
	"refit": "船坞改装：给船换炮、加货舱、升引擎都要花钱和时间，船员越多改得越快。旗舰和编队里的船一起改最省事。",
	"grand": "云海大工程：灯塔建到灯廊之后，可以出资建造改变整个云海的工程——灯标网、天梯、大学堂，盟主还能建金殿。每项只有一家能建成，建成者留名得名声，全云海受益，建造者受益更多。对手有钱了也会抢着建。",
	"ties": "三家的关系：喝酒、送礼、买图纸拉近，赛船论道输的一方记仇，收购工坊、买通港务最伤。关系够好可以结盟（不抢地、灯塔互助、灯节贺礼、交换行情），跌到底就是宿敌（收购他们的工坊便宜、赢他们名声更多，但他们会盯上你）。两家对手之间也会结盟或翻脸——落后的两家往往走到一起。",
}


func _hint(key: String) -> void:
	if hint_panel == null or sim == null or not HINTS.has(key):
		return
	if not sim.s.has("hints"):
		sim.s["hints"] = {}
	if sim.s["hints"].has(key):
		return
	sim.s["hints"][key] = true
	hint_label.text = HINTS[key]
	hint_panel.visible = true


func _tutorial_goal() -> Dictionary:
	var home: String = GameData.HOUSES[sim.pid()]["home"]
	var good: String = GameData.PORTS[home]["make"][0]
	var dest := ""
	for g in GameData.PORTS[home]["make"]:
		for pid in GameData.WEST_IDS:
			if g in GameData.PORTS[pid]["want"] and (dest == "" or GameData.distance(home, pid) < GameData.distance(home, dest)):
				dest = pid
				good = g
		if dest != "":
			break
	if dest == "":
		# nobody lists it as a want: send the player where it sells best
		var best := -1
		for pid in GameData.WEST_IDS:
			if pid == home:
				continue
			var sp := sim.sell_price(pid, good)
			if sp > best:
				best = sp
				dest = pid
	return {"home": home, "good": good, "dest": dest}


func _update_tutorial() -> void:
	if tut_panel == null:
		return
	var step: int = sim.s["tutorial"]
	var fl := sim.flagship()
	var home: String = GameData.HOUSES[sim.pid()]["home"]
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
				if int(sim.s["stats"].get("contracts", 0)) > 0 or _tut_far():
					step = 6; advanced = true
			6:
				if not sim.crew().is_empty() or _tut_far():
					step = 7; advanced = true
			7:
				if not Industry.all_buildings(sim, sim.pid()).is_empty() or _tut_far():
					step = 8; advanced = true
			8:
				if sim.house()["lh"]["stage"] > 0 or sim.house()["lh"]["building"]:
					step = 9; advanced = true
	sim.s["tutorial"] = step
	map.highlight_port = ""
	var text := ""
	var tg := _tutorial_goal()
	var gname := GameData.good_name(tg["good"])
	var dname := GameData.port_name(tg["dest"])
	var st0: Dictionary = GameData.LIGHTHOUSE[0]
	var mats := []
	for g in st0["mats"]:
		mats.append("%s %d" % [GameData.good_name(g), st0["mats"][g]])
	match step:
		0:
			text = "①在%s的「交易」页，把右上的「每次」切到「全部」，再按%s那一行的「◀」买入。绿色的是本城招牌货，便宜。" % [GameData.port_name(home), gname]
		1:
			text = "②点击地图上闪光的%s，再点「旗舰起航」。%s需要%s，会出高价。" % [dname, dname, gname]
			map.highlight_port = tg["dest"]
		2:
			text = "③抵港后按「▶」卖出。「均价」是你这批货的成本，卖价高于它就是赚。" if sim.docked(fl) else "③航行中……右上角可以加速，抵港时会自动暂停。把鼠标移到港口上可以看到航程和卖价。"
		3:
			text = "④继续跑商攒钱。名声到「船东」后就能开商馆、建工坊；金币够了去「船坞」买第二艘船。"
		4:
			text = "⑤在左下角船队里点新船的「航线」，让它自己往返跑一条赚钱的路线。"
		5:
			text = "⑥各港酒馆的「委托板」会张贴求购单：接下一张，在期限内把货送到，酬金一次拿走，比普通跑商划算。"
		6:
			text = "⑦名声到「船东」后，去各城的酒馆、船坞、行会找愿意加入的人。第一位伙伴派到岗位上就有加成，好感高了还有剧情。" if sim.rep_level() < 2 else "⑦去各城的酒馆、船坞、行会看看谁愿意加入：第一位伙伴派到岗位上就有加成，好感高了还有剧情和托付。"
		7:
			text = "⑧在友好度够的城，去「商馆」页买下一块地或一份图纸建工坊：货会自己长出来，比买来的便宜得多。"
		8:
			text = "⑨灯塔第一层需要%s和 %s 金。把物资运回%s，在「灯塔」页交付并开工。做到这里，你已经会玩了。" % ["、".join(mats), UiKit.money(st0["gold"]), GameData.port_name(home)]
			map.highlight_port = home if sim.mats_ready() else ""
		_:
			text = ""
	tut_panel.visible = text != ""
	tut_label.text = text
	if tut_skip != null:
		tut_skip.visible = step >= 5
