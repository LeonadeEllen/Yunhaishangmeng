class_name EventBook
## Random voyage events and the 陆青 story line. Effects are small data dicts so they stay testable.
##
## effect keys: gold (int), good ([id, qty]) added to flagship, lose_cargo (fraction), intel (bool),
## story (int, sets story stage), stock ([port, good, delta]), say (String)


const STORY := [
	{"id": "story_1", "day": 20, "art": "story_rescue", "title": "雾中求救 · 第一章",
	 "text": "浓雾里传来断续的铃声。一艘小艇卡在乱流里，掌舵的少女叫陆青，她说父亲留下的航图被债主扣在了风月坞。",
	 "choices": [
		{"label": "拖她回港（燃晶 −300 金）", "effects": {"gold": -300, "story": 1, "say": "陆青记下了你的旗号。"}},
		{"label": "给她一些口粮就走", "effects": {"good": ["wheat", 0], "story": 1, "say": "陆青向你道谢，眼里有些失望。"}},
	 ]},
	{"id": "story_2", "day": 150, "art": "story_letter", "title": "未送达的信匣 · 第二章",
	 "text": "陆青托人送来一只信匣：她父亲曾为风月坞的锻炉运送精钢件，账本记着一条被人遗忘的近路。",
	 "choices": [
		{"label": "出 1,500 金替她赎回航图", "effects": {"gold": -1500, "story": 2, "intel": true, "say": "航图到手：你得知了全部港口的行情走向。"}},
		{"label": "只抄下账本里的行情", "effects": {"story": 2, "intel": true, "say": "账本上的价格虽旧，却足够你规划下一程。"}},
	 ]},
	{"id": "story_3", "day": 420, "art": "story_loyalty", "title": "重逢与航图 · 终章",
	 "text": "陆青带着自己的商会找到你：她愿意把父亲的老主顾全部介绍给灯油行会，只求灯塔点亮时，第一束光照向风月坞。",
	 "choices": [
		{"label": "立约：灯塔为风月坞而亮", "effects": {"gold": 6000, "story": 3, "stock": ["fengyue", "steel", 60], "say": "风月坞的工匠们为你开了库房。"}},
		{"label": "婉拒，各走各路", "effects": {"gold": 2000, "story": 3, "say": "陆青留下一笔谢礼，转身驶入云海。"}},
	 ]},
]

const RANDOM := [
	{"id": "whales", "title": "云鲸迁徙", "art": "events/03", "text": "一群云鲸横穿航道，带起的上升气流把飞艇托得老高。",
	 "choices": [{"label": "顺着气流滑翔", "effects": {"gold": 200, "say": "省下了一大笔燃晶。"}}]},
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
	{"id": "artisan", "title": "灯塔匠人", "art": "events/12", "text": "一位年迈的灯塔匠人愿意为你的工地出谋划策，只要一笔路费。",
	 "choices": [
		{"label": "资助他（−800 金）", "effects": {"gold": -800, "good": ["steel", 10], "say": "老匠人带来了十件精钢件作为见面礼。"}},
		{"label": "婉拒", "effects": {}},
	 ]},
]


static func maybe_trigger(sim: Sim) -> void:
	var s := sim.s
	if s["event"] != null or s["over"] != null:
		return
	var story: int = int(s["story"])
	if story < STORY.size() and int(s["day"]) >= int(STORY[story]["day"]):
		_open(sim, STORY[story])
		return
	if s.has("arrived"):
		s.erase("arrived")
		if sim.rng.randf() < 0.14:
			_open(sim, RANDOM[sim.rng.randi() % RANDOM.size()])


static func _open(sim: Sim, ev: Dictionary) -> void:
	sim.s["event"] = {"id": ev["id"], "title": ev["title"], "text": ev["text"], "art": ev.get("art", ""),
		"choices": ev["choices"].map(func(c): return {"label": c["label"]})}


static func _find(id: String) -> Dictionary:
	for e in STORY + RANDOM:
		if e["id"] == id:
			return e
	return {}


static func resolve(sim: Sim, choice: int) -> Dictionary:
	var cur = sim.s["event"]
	if cur == null:
		return {"ok": false, "msg": "没有待处理的事件。"}
	var ev := _find(cur["id"])
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
		for pid in GameData.PORT_IDS:
			sim._update_intel(pid)
	if fx.has("stock"):
		var m: Dictionary = sim.s["ports"][fx["stock"][0]]["market"][fx["stock"][1]]
		m["stock"] = maxf(1.0, m["stock"] + float(fx["stock"][2]))
	if fx.has("story"):
		sim.s["story"] = int(fx["story"])
	if fx.has("say"):
		msgs.append(fx["say"])
	sim.s["event"] = null
	var text := " ".join(msgs)
	if text != "":
		sim._say(text, "info")
	return {"ok": true, "msg": text}
