class_name EventBook
## Random voyage events and the 陆青 story line. Effects are small data dicts so they stay testable.
##
## effect keys: gold (int), good ([id, qty]) added to flagship, lose_cargo (fraction), intel (bool),
## story (int, sets story stage), stock ([port, good, delta]), say (String)


const STORY := [
	{"id": "story_1", "day": 20, "art": "story_rescue", "title": "雾中求救 · 第一章",
	 "text": "浓雾里传来断续的铃声。一艘小艇卡在乱流里，掌舵的少女叫陆青，她说父亲留下的航图被债主扣在了风月坞。",
	 "choices": [
		{"label": "拖她回港（补给 −300 金）", "effects": {"gold": -300, "story": 1, "say": "陆青记下了你的旗号。"}},
		{"label": "给她一些口粮就走", "effects": {"good": ["wheat", 0], "story": 1, "say": "陆青向你道谢，眼里有些失望。"}},
	 ]},
	{"id": "story_2", "day": 150, "art": "story_letter", "title": "未送达的信匣 · 第二章",
	 "text": "陆青托人送来一只信匣：她父亲曾为风月坞的锻炉运送精钢件，账本记着一条被人遗忘的近路。",
	 "choices": [
		{"label": "出 1,500 金替她赎回航图", "effects": {"gold": -1500, "story": 2, "intel": true, "say": "航图到手：你得知了全部港口的行情走向。"}},
		{"label": "只抄下账本里的行情", "effects": {"story": 2, "intel": true, "say": "账本上的价格虽旧，却足够你规划下一程。"}},
	 ]},
	{"id": "story_3", "day": 420, "art": "story_loyalty", "title": "重逢与航图 · 终章",
	 "text": "陆青带着自己的商会找到你：她愿意把父亲的老主顾全部介绍给你的商会，只求灯塔点亮时，第一束光照向风月坞。",
	 "choices": [
		{"label": "立约：灯塔为风月坞而亮", "effects": {"gold": 6000, "story": 3, "stock": ["fengyue", "steel", 60], "say": "风月坞的工匠们为你开了库房。"}},
		{"label": "婉拒，各走各路", "effects": {"gold": 2000, "story": 3, "say": "陆青留下一笔谢礼，转身驶入云海。"}},
	 ]},
]

const PIRATES := {"id": "pirates", "title": "云盗拦路", "art": "events/00", "text": "一艘涂黑帆的快艇从云层里钻出来，挂起了云盗的旗子：交钱，或者丢货。",
	"choices": [
		{"label": "交过路费（金币的 8%，至少 300）", "effects": {"toll": 0.08, "say": "云盗收了钱，大笑着钻回云里。"}},
		{"label": "甩开他们", "effects": {"lose_cargo": 0.2, "say": "飞艇冲进乱流甩掉了追兵，但货舱被打破，丢了两成货。"}},
	]}

const RANDOM := [
	{"id": "whales", "title": "云鲸迁徙", "art": "events/03", "text": "一群云鲸横穿航道，带起的上升气流把飞艇托得老高。",
	 "choices": [{"label": "顺着气流滑翔", "effects": {"gold": 200, "say": "省下了一大笔补给。"}}]},
	{"id": "smuggler", "title": "走私贩的提议", "art": "events/01", "text": "码头的阴影里有人压低声音：一批来路不明的雾珍珠，半价。",
	 "choices": [
		{"label": "买下 10 颗（1,200 金）", "effects": {"gold": -1200, "good": ["pearl", 10], "say": "珍珠成色不错，只是别问来历。"}},
		{"label": "拒绝", "effects": {"say": "你没有冒这个险。"}},
	 ]},
	{"id": "crew", "title": "乘员不满", "art": "events/02", "text": "连续的航行让船员们怨声载道，水手长来找你谈加饷。",
	 "choices": [
		{"label": "发放犒赏（−600 金）", "effects": {"gold": -600, "say": "船员们欢呼起来。"}},
		{"label": "好言安抚", "effects": {"lose_cargo": 0.1, "say": "有人趁夜偷搬了一些货。"}},
	 ]},
	{"id": "storm_omen", "title": "雷暴预兆", "art": "events/10", "text": "老水手说，云层的颜色和四十年前那场风暴一模一样。",
	 "choices": [{"label": "记在航海日志里", "effects": {"say": "风暴还远，但它会来的。"}}]},
	{"id": "scholar", "title": "游学者", "art": "events/04", "text": "一位游学者想搭船去下一个港口，愿意用各地见闻抵船费。",
	 "choices": [
		{"label": "欢迎上船", "effects": {"intel": true, "say": "游学者把沿途港口的行情讲得清清楚楚。"}},
		{"label": "收 300 金船费", "effects": {"gold": 300}},
	 ]},
	{"id": "fashion", "title": "风尚预言", "art": "events/07", "text": "千旗市的贵妇们突然迷上了香木熏衣，香木价格应声上涨。",
	 "choices": [{"label": "记下这个消息", "effects": {"stock": ["qianqi", "incense", -40], "say": "千旗市香木短缺。"}}]},
	{"id": "wreck", "title": "古代残骸", "art": "events/09", "text": "云层下露出一艘古代商船的残骸，货舱似乎还没被打开过。",
	 "choices": [
		{"label": "派人下去打捞（−200 金）", "effects": {"gold": -200, "good": ["silk", 12], "say": "捞上来一箱保存完好的丝云绸。"}},
		{"label": "不冒险", "effects": {}},
	 ]},
	{"id": "plague", "title": "疫病", "art": "events/05", "text": "港口传出疫病的消息，药价飞涨，船员们人心惶惶。",
	 "choices": [
		{"label": "买药预防（−500 金）", "effects": {"gold": -500, "say": "全员平安。"}},
		{"label": "尽快离港", "effects": {"lose_cargo": 0.05, "say": "匆忙中丢下了一些货。"}},
	 ]},
	{"id": "councilor", "title": "议员的请托", "art": "events/11", "text": "一位议员请你为他的庄园捎去一批云麦，报酬丰厚。",
	 "choices": [{"label": "答应", "effects": {"gold": 900, "say": "议员的管家付了钱。"}}]},
	{"id": "envoy", "title": "密使来访", "art": "events/06", "text": "一位蒙面密使带来对手商会工地的内应名单，开价一千。",
	 "choices": [
		{"label": "买下（−1,000 金，领先对手工期 +30 天）", "effects": {"gold": -1000, "rival_delay": 30, "say": "对手的工地接连出了岔子。"}},
		{"label": "拒之门外", "effects": {"say": "你不屑于这种手段。"}},
	 ]},
	{"id": "refugees", "title": "投奔者", "art": "events/08", "text": "一群失了家园的浮民想上船做工，他们说自己会采珠。",
	 "choices": [
		{"label": "收留他们（−400 金）", "effects": {"gold": -400, "good": ["pearl", 6], "say": "浮民们用采来的雾珍珠报答你。"}},
		{"label": "爱莫能助", "effects": {}},
	 ]},
	{"id": "oldmap", "title": "古地图", "art": "events/13", "text": "旧货摊上有一张标着气流的古航图，摊主要价六百。",
	 "choices": [
		{"label": "买下（−600 金）", "effects": {"gold": -600, "intel": true, "say": "古图上的气流帮你算准了每个港口的行情。"}},
		{"label": "算了", "effects": {}},
	 ]},
	{"id": "auction", "title": "码头拍卖", "art": "events/14", "text": "一位破产商人在码头拍卖存货：二十盏琉璃灯，起价一千五。",
	 "choices": [
		{"label": "出价（−1,500 金）", "effects": {"gold": -1500, "good": ["glass", 20], "say": "你拍下了整箱琉璃。"}},
		{"label": "旁观", "effects": {}},
	 ]},
	{"id": "festival", "title": "灯会", "art": "events/15", "text": "港口正逢灯会，烟火与飞艇把夜空照得通亮，市民抢购甜霞果和丝云绸。",
	 "choices": [{"label": "凑个热闹", "effects": {"festival": true, "say": "这个港口的甜霞果和丝云绸暂时供不应求。"}}]},
	{"id": "artisan", "title": "灯塔匠人", "art": "events/12", "text": "一位年迈的灯塔匠人愿意为你的工地出谋划策，只要一笔路费。",
	 "choices": [
		{"label": "资助他（−800 金）", "effects": {"gold": -800, "good": ["steel", 10], "say": "老匠人带来了十件精钢件作为见面礼。"}},
		{"label": "婉拒", "effects": {}},
	 ]},
]


# Only met in the eastern sea (round 11): the other culture's ways of doing business.
const EAST := [
	{"id": "bell_fair", "title": "铜钟集市", "art": "events/14", "text": "整点钟响，码头上摆开了铜匠行会的集市。东边的商人对西边的货好奇得很，愿意出高价。",
	 "choices": [
		{"label": "把船上的货全卖给他们（卖价 +25%）", "effects": {"sell_bonus": 0.25, "say": "铜匠们用铜铃付账，叮叮当当装了一箱。"}},
		{"label": "按市价慢慢卖", "effects": {}},
	 ]},
	{"id": "interpreter", "title": "通译", "art": "events/04", "text": "一个会说两边话的少年挤到船边，愿意替你跟城里人打交道，只要一点工钱。",
	 "choices": [
		{"label": "雇下他（−300 金）", "effects": {"gold": -300, "friend": 80, "say": "有了通译，城里人对你的脸色好了许多。"}},
		{"label": "比划着也能做生意", "effects": {"say": "你用手势谈成了买卖，少付了一点，也多花了半天。"}},
	 ]},
	{"id": "east_storm", "title": "东海风暴", "art": "events/10", "text": "东边的风暴来得毫无预兆，整片云海翻成了灰色。",
	 "choices": [
		{"label": "进港避风（补给 −400 金）", "effects": {"gold": -400, "say": "风暴过后，船一点没伤。"}},
		{"label": "硬闯", "effects": {"lose_cargo": 0.1, "say": "船穿过了风暴，货舱进了水，丢了一成货。"}},
	 ]},
	{"id": "lantern_night", "title": "灯夜", "art": "events/15", "text": "雾隐泊的灯夜：全城的灯一起点亮，灯油铺子半价清仓。",
	 "choices": [
		{"label": "买下 12 桶灯油（−900 金）", "effects": {"gold": -900, "good": ["oil", 12], "say": "灯油装满了货舱的一角。"}},
		{"label": "只看灯", "effects": {"say": "你在灯下站了一夜。"}},
	 ]},
	{"id": "bell_rumour", "title": "钟楼的传闻", "art": "events/11", "text": "酒馆里有人说，雾的更深处还有一座会响的钟楼，谁找到谁就能发财。",
	 "choices": [{"label": "记下来", "effects": {"say": "传闻记进了航海日志。"}}]},
]


static func maybe_trigger(sim: Sim) -> void:
	var s := sim.s
	if s["event"] != null or s["over"] != null:
		return
	var story: int = int(s["story"])
	if story < STORY.size() and int(s["day"]) >= int(STORY[story]["day"]):
		_open(sim, STORY[story])
		return
	if s.has("sailed"):
		var mult := float(s["sailed"])
		s.erase("sailed")
		if int(s["day"]) > 60 and sim.rng.randf() < GameData.ENCOUNTER_CHANCE * mult and sim.fleet_cargo_used(sim.flagship()) > 0:
			sim.start_encounter("pirates")
			return
	if s.has("arrived"):
		s.erase("arrived")
		# a rival captain docked beside you may hail you (round 13)
		var fl0 := sim.flagship()
		if not fl0.is_empty() and sim.docked(fl0) and int(s["day"]) - int(s.get("rival_met", -999)) >= GameData.RIVAL_MEET_GAP:
			var here := []
			for hid in GameData.HOUSE_IDS:
				if hid == sim.pid() or sim.house(hid)["bankrupt"]:
					continue
				for sh in sim._ships_of(hid):
					if sh["port"] == fl0["port"]:
						here.append(hid)
						break
			if not here.is_empty() and sim.rng.randf() < GameData.RIVAL_MEET:
				s["rival_met"] = int(s["day"])
				rival_meeting(sim, here[sim.rng.randi() % here.size()])
				return
		if sim.rng.randf() < 0.14:
			var fl := sim.flagship()
			var pool: Array = RANDOM
			if not fl.is_empty() and sim.docked(fl) and GameData.region_of(fl["port"]) == 2 and sim.rng.randf() < 0.6:
				pool = EAST
			_open(sim, pool[sim.rng.randi() % pool.size()])


static func _open(sim: Sim, ev: Dictionary) -> void:
	sim.s["event"] = {"id": ev["id"], "title": ev["title"], "text": ev["text"], "art": ev.get("art", ""),
		"choices": ev["choices"].map(func(c): return {"label": c["label"]})}


static func _find(id: String) -> Dictionary:
	if id.begins_with("quest:"):
		var qc := id.split(":")[1]
		var q: Dictionary = Characters.QUESTS[qc]
		return {"id": id, "title": q["title"], "text": q["text"], "art": "", "quest": qc,
			"choices": [{"label": "答应下来", "effects": {"quest_accept": qc}}, {"label": "现在腾不出手", "effects": {"quest_decline": qc}}]}
	if id.begins_with("trio:"):
		var ti := int(id.split(":")[1])
		var tr: Dictionary = Characters.TRIOS[ti]
		return {"id": id, "title": tr["title"], "text": tr["text"], "art": "", "trio": ti,
			"choices": tr["choices"].map(func(c): return {"label": c["label"], "effects": c["fx"]})}
	if id.begins_with("pair:"):
		var idx := int(id.split(":")[1])
		var pr: Dictionary = Characters.PAIRS[idx]
		return {"id": id, "title": pr["title"], "text": pr["text"], "art": "", "pair": idx,
			"choices": pr["choices"].map(func(c): return {"label": c["label"], "effects": c["fx"]})}
	if id.begins_with("char:"):
		var parts := id.split(":")
		var ch: Dictionary = Characters.CHARS[parts[1]]["story"][int(parts[2])]
		return {"id": id, "title": ch["title"], "text": ch["text"], "art": "", "cid": parts[1], "chapter": int(parts[2]),
			"choices": ch["choices"].map(func(c): return {"label": c["label"], "effects": c["fx"]})}
	for e in STORY + RANDOM + EAST + [PIRATES]:
		if e["id"] == id:
			return e
	return {}


## A companion's personal story chapter (0-2).
static func open_chapter(sim: Sim, cid: String, chapter: int) -> void:
	var c: Dictionary = Characters.CHARS[cid]
	var ch: Dictionary = c["story"][chapter]
	sim.s["event"] = {"id": "char:%s:%d" % [cid, chapter], "title": "%s · %s（第 %d 章）" % [c["name"], ch["title"], chapter + 1], "text": ch["text"],
		"art": ["story_rescue", "story_letter", "story_loyalty"][chapter], "cid": cid,
		"choices": ch["choices"].map(func(x): return {"label": x["label"]})}


## A scene between two companions (index into Characters.PAIRS).
static func open_pair(sim: Sim, idx: int) -> void:
	var pr: Dictionary = Characters.PAIRS[idx]
	sim.s["event"] = {"id": "pair:%d" % idx, "title": "%s与%s · %s" % [Characters.name_of(pr["a"]), Characters.name_of(pr["b"]), pr["title"]],
		"text": pr["text"], "art": "story_loyalty", "choices": pr["choices"].map(func(x): return {"label": x["label"]})}


## A companion asks a personal errand of you (round 17).
static func open_quest(sim: Sim, cid: String) -> void:
	var q: Dictionary = Characters.QUESTS[cid]
	sim.s["event"] = {"id": "quest:%s" % cid, "title": "%s的托付 · %s" % [Characters.name_of(cid), q["title"]],
		"text": q["text"] + "（送 %d 件%s到 %s，%d 天内，谢礼 %s 金）" % [int(q["qty"]), GameData.good_name(q["good"]), GameData.port_name(q["port"]), int(q["days"]), UiKit.money(q["gold"])],
		"art": "story_letter", "choices": [{"label": "答应下来"}, {"label": "现在腾不出手"}]}


static func open_trio(sim: Sim, idx: int) -> void:
	var tr: Dictionary = Characters.TRIOS[idx]
	var names: Array = tr["who"].map(func(c): return Characters.name_of(c))
	sim.s["event"] = {"id": "trio:%d" % idx, "title": "%s · %s" % ["、".join(names), tr["title"]], "text": tr["text"],
		"art": "story_loyalty", "choices": tr["choices"].map(func(x): return {"label": x["label"]})}


## A rival captain hails you on the quay (round 13). The choices depend on what the rival owns, so
## their effects travel inside the event itself instead of a static table.
static func rival_meeting(sim: Sim, hid: String) -> void:
	var hh: Dictionary = GameData.HOUSES[hid]
	var me: String = GameData.HOUSES[sim.pid()]["leader"]
	var fl := sim.flagship()
	var port: String = fl["port"]
	var ship_name := "飞艇"
	for sh in sim._ships_of(hid):
		if sh["port"] == port:
			ship_name = sh["name"]
			break
	var gold: float = sim.house()["gold"]
	var stake := int(clampf(gold * 0.1, 1000.0, 8000.0)) / 100 * 100
	var choices := []
	var text := ""
	if hid == "iron":
		text = "码头上停着铁誓舰团的%s。韦朔靠在船舷上冲你喊：「%s！敢不敢赛一程？从这里到灯标，先到的拿走赌金。」" % [ship_name, me]
		choices.append({"label": "赛船：赌 %s 金" % UiKit.money(stake), "effects": {"race": {"hid": hid, "stake": stake}}})
	else:
		text = "白塔议士的%s泊在隔壁泊位。殷望舒撑着伞走过来，像在谈天气一样问起你的账目：「%s，当众论一论生意之道？输的那位，名声要折一些。」" % [ship_name, me]
		choices.append({"label": "论道：赢了名声 +80，输了 −30", "effects": {"debate": {"hid": hid}}})
	# a blueprint they own and you do not (tier 1 deeds and tier 2 craft blueprints only)
	var bp := ""
	for g in sim.house(hid)["bp"]:
		if not sim.has_bp(g) and GameData.tier(g) <= 2:
			bp = g
			break
	if bp != "":
		var cost := int(float(GameData.DEED_COST) * 1.5) if GameData.tier(bp) == 1 else int(float(GameData.CRAFT_BP_COST) * 1.25)
		choices.append({"label": "买%s的%s%s（%s 金）" % ["他" if hid == "iron" else "她", GameData.good_name(bp), "地契" if GameData.tier(bp) == 1 else "图纸", UiKit.money(cost)],
			"effects": {"buy_bp": {"hid": hid, "good": bp, "cost": cost}}})
	choices.append({"label": "买通港务，拖住%s的船 %d 天（%s 金，可能败露）" % [hh["name"], GameData.RIVAL_DELAY_DAYS, UiKit.money(GameData.RIVAL_DELAY_COST)],
		"effects": {"delay_rival": {"hid": hid, "port": port}}})
	choices.append({"label": "请%s喝一杯（300 金，本城友好度 +40）" % ("他" if hid == "iron" else "她"),
		"effects": {"gold": -300, "friend": 40, "say": ("韦朔酒量惊人，临走拍着你的肩说下次再赛。" if hid == "iron" else "殷望舒只喝了半杯茶，却把本城哪位官员好说话都告诉了你。")}})
	choices.append({"label": "点头致意，各忙各的", "effects": {}})
	sim.s["event"] = {"id": "rival:%s" % hid, "title": "%s · %s在港" % [hh["leader"], hh["name"]], "text": text, "art": "events/14", "choices": choices}


static func resolve(sim: Sim, choice: int) -> Dictionary:
	var cur = sim.s["event"]
	if cur == null:
		return {"ok": false, "msg": "没有待处理的事件。"}
	var ev := _find(cur["id"])
	if ev.is_empty():
		ev = cur   # choices carry their own effects (rival meetings)
	var c: Dictionary = ev["choices"][clampi(choice, 0, ev["choices"].size() - 1)]
	var fx: Dictionary = c["effects"]
	var h := sim.house()
	var fl := sim.flagship()
	var msgs := []
	if fx.has("gold"):
		h["gold"] += float(fx["gold"])
	if fx.has("good") and not fl.is_empty():
		var g: String = fx["good"][0]
		var n := mini(int(fx["good"][1]), sim.cargo_cap(fl) - sim.cargo_used(fl))
		if n > 0:
			var cg: Dictionary = fl["cargo"].get(g, {"qty": 0, "cost": 0.0})
			cg["cost"] = (float(cg["qty"]) * float(cg["cost"])) / float(int(cg["qty"]) + n)
			cg["qty"] = int(cg["qty"]) + n
			fl["cargo"][g] = cg
	if fx.has("lose_cargo") and not fl.is_empty():
		for g in fl["cargo"].keys():
			var lost := int(ceil(float(fl["cargo"][g]["qty"]) * float(fx["lose_cargo"])))
			fl["cargo"][g]["qty"] -= lost
			if fl["cargo"][g]["qty"] <= 0:
				fl["cargo"].erase(g)
	if fx.has("intel"):
		for pid in sim.open_ports():
			sim._update_intel(pid)
	if fx.has("sell_bonus") and not fl.is_empty() and sim.docked(fl):
		var bonus := 0.0
		for g in fl["cargo"].keys():
			var r := sim.sell(int(fl["id"]), g, int(fl["cargo"][g]["qty"]))
			if r["ok"]:
				bonus += float(r.get("revenue", 0)) * float(fx["sell_bonus"])
		h["gold"] += bonus
		h["month_in"] += bonus
		if bonus > 0.0:
			msgs.append("多赚了 %d 金。" % int(bonus))
	if fx.has("friend") and not fl.is_empty() and sim.docked(fl):
		sim.add_friend(fl["port"], sim.pid(), int(fx["friend"]))
	if fx.has("explore"):
		sim.open_east()
	if fx.has("stock"):
		var m: Dictionary = sim.s["ports"][fx["stock"][0]]["market"][fx["stock"][1]]
		m["stock"] = maxf(1.0, m["stock"] + float(fx["stock"][2]))
	if fx.has("toll"):
		h["gold"] -= maxf(300.0, maxf(0.0, h["gold"]) * float(fx["toll"]))
	if fx.has("rival_delay"):
		var lead := ""
		for hid in GameData.HOUSE_IDS:
			if hid != sim.pid() and not sim.house(hid)["bankrupt"]:
				if lead == "" or sim.house(hid)["lh"]["stage"] > sim.house(lead)["lh"]["stage"]:
					lead = hid
		if lead != "":
			var lh: Dictionary = sim.house(lead)["lh"]
			if lh["building"]:
				lh["end"] = int(lh["end"]) + int(fx["rival_delay"])
			else:
				sim.house(lead)["gold"] -= 3000.0
	if fx.has("festival") and not fl.is_empty() and sim.docked(fl):
		for g in ["fruit", "silk"]:
			var mk: Dictionary = sim.s["ports"][fl["port"]]["market"][g]
			mk["stock"] = maxf(1.0, mk["stock"] * 0.4)
	if fx.has("story"):
		sim.s["story"] = int(fx["story"])
	if ev.has("cid") and sim.s["crew"].has(ev["cid"]):
		var m: Dictionary = sim.s["crew"][ev["cid"]]
		m["chapter"] = maxi(int(m["chapter"]), int(ev["chapter"]) + 1)
		if fx.has("aff"):
			sim.add_affinity(ev["cid"], int(fx["aff"]))
		if fx.has("spec_up"):
			m["spec_lvl"] = 2
			msgs.append("%s的专长「%s」更上一层。" % [Characters.name_of(ev["cid"]), Characters.CHARS[ev["cid"]]["spec_name"]])
	if fx.has("rep"):
		if int(fx["rep"]) > 0:
			sim.add_rep(sim.pid(), int(fx["rep"]))
		else:
			h["rep"] = maxi(0, int(h["rep"]) + int(fx["rep"]))
	if ev.has("trio"):
		for who in Characters.TRIOS[int(ev["trio"])]["who"]:
			sim.add_affinity(who, int(fx.get("aff_all", 0)))
		if not sim.s.has("trios_done"):
			sim.s["trios_done"] = {}
		sim.s["trios_done"][str(int(ev["trio"]))] = true
	if fx.has("quest_accept"):
		var qa: String = fx["quest_accept"]
		sim.quests()[qa] = {"state": "active", "end": int(sim.s["day"]) + int(Characters.QUESTS[qa]["days"])}
		msgs.append("%s记下了这件事。" % Characters.name_of(qa))
	if fx.has("quest_decline"):
		var qd: String = fx["quest_decline"]
		sim.quests()[qd] = {"state": "declined", "end": 0}
		sim.add_affinity(qd, -3)
		msgs.append("%s点点头，没有再提。" % Characters.name_of(qd))
	if ev.has("pair"):
		var pr: Dictionary = Characters.PAIRS[int(ev["pair"])]
		sim.add_affinity(pr["a"], int(fx.get("aff_a", 0)))
		sim.add_affinity(pr["b"], int(fx.get("aff_b", 0)))
		if not sim.s.has("pairs_done"):
			sim.s["pairs_done"] = {}
		sim.s["pairs_done"][str(int(ev["pair"]))] = true
	if fx.has("race"):
		var rc: Dictionary = fx["race"]
		var rival := sim.house(rc["hid"])
		var stake := float(rc["stake"])
		var p := clampf(0.3 + 0.05 * float(sim.hero_abil("sail")) + 0.03 * float(sim.post_level("nav")) + (sim.speed_mult(fl) - 1.0) * 1.5, 0.2, 0.85)
		if sim.rng.randf() < p:
			h["gold"] += stake
			h["month_in"] += stake
			rival["gold"] -= stake
			sim.add_rep(sim.pid(), 40)
			sim.s["stats"]["races"] = int(sim.s["stats"].get("races", 0)) + 1
			msgs.append("你的旗舰先一个船身越过了灯标。韦朔隔着云雾骂了一句，把 %s 金赌金扔了过来。名声 +40。" % UiKit.money(stake))
		else:
			h["gold"] -= stake
			h["month_out"] += stake
			rival["gold"] += stake
			msgs.append("韦朔的船像一道铁箭。他收起 %s 金赌金，笑得很大声。" % UiKit.money(stake))
	if fx.has("debate"):
		var rival_lvl := sim.rep_level(fx["debate"]["hid"])
		var p2 := clampf(0.3 + 0.06 * float(sim.hero_abil("charm")) + 0.05 * float(sim.rep_level() - rival_lvl), 0.2, 0.85)
		if sim.rng.randf() < p2:
			sim.add_rep(sim.pid(), 80)
			msgs.append("殷望舒合上扇子：「受教了。」码头上的人记住了你的名字。名声 +80。")
		else:
			h["rep"] = maxi(0, int(h["rep"]) - 30)
			msgs.append("你被她的数字绕得说不出话，围观的人散得很快。名声 −30。")
	if fx.has("buy_bp"):
		var bb: Dictionary = fx["buy_bp"]
		if h["gold"] >= float(bb["cost"]):
			h["gold"] -= float(bb["cost"])
			h["month_out"] += float(bb["cost"])
			sim.house(bb["hid"])["gold"] += float(bb["cost"])
			h["bp"][bb["good"]] = true
			msgs.append("%s的%s到手了。" % [GameData.good_name(bb["good"]), "地契" if GameData.tier(bb["good"]) == 1 else "图纸"])
		else:
			msgs.append("金币不足，买卖没成。")
	if fx.has("delay_rival"):
		var dr: Dictionary = fx["delay_rival"]
		if h["gold"] >= float(GameData.RIVAL_DELAY_COST):
			h["gold"] -= float(GameData.RIVAL_DELAY_COST)
			h["month_out"] += float(GameData.RIVAL_DELAY_COST)
			if sim.rng.randf() < 0.25:
				h["rep"] = maxi(0, int(h["rep"]) - 40)
				var f: Dictionary = sim.s["ports"][dr["port"]]["friend"]
				f[sim.pid()] = maxi(0, int(f.get(sim.pid(), 0)) - 60)
				msgs.append("港务官收了钱又告了密，全城都知道你干了什么。名声 −40，本城友好度大跌。")
			else:
				for sh in sim._ships_of(dr["hid"]):
					if sh["port"] == dr["port"]:
						sh["idle_until"] = int(sim.s["day"]) + GameData.RIVAL_DELAY_DAYS
				msgs.append("港务官收了钱，%s的船被拦在泊位里查了 %d 天的货单。" % [GameData.HOUSES[dr["hid"]]["name"], GameData.RIVAL_DELAY_DAYS])
		else:
			msgs.append("金币不足，港务官没理你。")
	if fx.has("say"):
		msgs.append(fx["say"])
	sim.s["event"] = null
	var text := " ".join(msgs)
	if text != "":
		sim._say(text, "info")
	return {"ok": true, "msg": text}
