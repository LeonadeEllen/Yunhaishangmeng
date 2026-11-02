class_name GameData
## Static data tables for the 霞市 vertical slice.

const DAYS_MONTH := 30
const DAYS_YEAR := 360
const END_YEAR := 10          # storm arrives at the end of year 10
const END_DAY := END_YEAR * DAYS_YEAR
const MAX_SHIPS := 4
const PX_PER_DAY := 60.0      # map pixels a speed-1.0 ship covers per day
const CRISIS_DAYS := 30
const LOAN_RATE := 0.02       # per month
const SEASONS := ["春", "夏", "秋", "冬"]

# icon = frame index in assets/art/goods (18-frame atlas)
const GOODS := {
	"wheat":   {"name": "云麦",     "base": 40,  "icon": 0},
	"fruit":   {"name": "甜霞果",   "base": 55,  "icon": 1},
	"fish":    {"name": "熏鱼干",   "base": 38,  "icon": 2},
	"silk":    {"name": "丝云绸",   "base": 140, "icon": 3},
	"canvas":  {"name": "风帆布",   "base": 70,  "icon": 5},
	"fiber":   {"name": "云麻",     "base": 48,  "icon": 4},
	"lamp":    {"name": "琉璃灯",   "base": 120, "icon": 8},
	"steel":   {"name": "精钢件",   "base": 110, "icon": 9},
	"incense": {"name": "香木",     "base": 200, "icon": 14},
	"pearl":   {"name": "雾珍珠",   "base": 320, "icon": 13},
}
const GOOD_IDS := ["wheat", "fruit", "fish", "fiber", "canvas", "steel", "lamp", "silk", "incense", "pearl"]

# island = frame index in assets/art/map_islands; pos in map pixels (map is 1600 x 1000)
const PORTS := {
	"qianqi":   {"name": "千旗市", "pos": Vector2(820, 520), "island": 2, "make": ["silk", "lamp"],     "want": ["wheat", "pearl"],   "desc": "霞市的枢纽，绸棚与红灯笼连成一片。"},
	"hongxiao": {"name": "红绡渡", "pos": Vector2(900, 180), "island": 4, "make": ["canvas", "fiber"],  "want": ["lamp", "fish"],     "desc": "织坊临风而建，帆布从崖边一路晾到云里。"},
	"muxia":    {"name": "暮霞港", "pos": Vector2(470, 470), "island": 5, "make": ["fish", "wheat"],    "want": ["steel", "silk"],    "desc": "渔艇傍晚归港，整片云海被染成橘红。"},
	"xiajing":  {"name": "霞鲸台", "pos": Vector2(420, 190), "island": 3, "make": ["pearl", "fruit"],   "want": ["canvas", "lamp"],   "desc": "云鲸迁徙的必经之地，采珠人在雾里潜行。"},
	"fengyue":  {"name": "风月坞", "pos": Vector2(660, 300), "island": 1, "make": ["steel", "fiber"],   "want": ["fruit", "incense"], "desc": "锻炉日夜不熄，工匠只认现钱。"},
	"cuijing":  {"name": "翠鲸岛", "pos": Vector2(1250, 330), "island": 7, "make": ["incense", "fruit"], "want": ["steel", "wheat"],   "desc": "林木蔽天的岛屿，香木在树心里慢慢结成。"},
	"tonghe":   {"name": "铜鹤矶", "pos": Vector2(1300, 720), "island": 6, "make": ["steel", "canvas"],  "want": ["fish", "pearl"],    "desc": "铜鹤风车守着港口，船坞的号子从不停歇。"},
	"chishi":   {"name": "赤石矶", "pos": Vector2(850, 830), "island": 0, "make": ["wheat", "incense"], "want": ["silk", "fiber"],    "desc": "赤色岩壁下藏着梯田，收成全靠风向。"},
}
const PORT_IDS := ["qianqi", "hongxiao", "muxia", "xiajing", "fengyue", "cuijing", "tonghe", "chishi"]

# sprite = frame index in assets/art/ships
const SHIPS := {
	"survey":    {"name": "测绘艇",   "price": 6000,  "cargo": 30,  "speed": 1.35, "fuel_day": 6,  "wage": 300,  "sprite": 0},
	"freighter": {"name": "货艇",     "price": 12000, "cargo": 80,  "speed": 1.0,  "fuel_day": 9,  "wage": 600,  "sprite": 2},
	"galleon":   {"name": "盖伦飞艇", "price": 26000, "cargo": 160, "speed": 0.85, "fuel_day": 14, "wage": 1100, "sprite": 3},
}
const FUEL_PRICE := 12

const HOUSES := {
	"lamp":  {"name": "灯油行会", "leader": "霍照野", "home": "qianqi",  "gold": 12000, "emblem": 0, "portrait": 0, "color": Color("b08a3e"),
		"perk": "sell", "perk_text": "卖出价格 +5%", "pitch": "千旗市的老牌商行，靠一手好买卖起家。最适合专心跑商。"},
	"iron":  {"name": "铁誓舰团", "leader": "韦朔",   "home": "tonghe",  "gold": 12000, "emblem": 1, "portrait": 1, "color": Color("5b7186"),
		"perk": "ships", "perk_text": "购买飞艇便宜 20%", "pitch": "铜鹤矶的船坞世家。船多路广，靠规模取胜。"},
	"tower": {"name": "白塔议士", "leader": "殷望舒", "home": "xiajing", "gold": 12000, "emblem": 2, "portrait": 2, "color": Color("8e8a7a"),
		"perk": "industry", "perk_text": "工坊便宜 25%，分红 +25%", "pitch": "霞鲸台的议士们擅长投资产业，慢热但后劲足。"},
}
const HOUSE_IDS := ["lamp", "iron", "tower"]
const PLAYER := "lamp"

const LIGHTHOUSE := [
	{"name": "基座", "gold": 40000,  "mats": {"steel": 80, "fiber": 120}, "days": 90, "sprite": 1},
	{"name": "灯廊", "gold": 100000, "mats": {"lamp": 100, "canvas": 80}, "days": 120, "sprite": 3},
	{"name": "灯冠", "gold": 220000, "mats": {"pearl": 50, "silk": 80, "incense": 60}, "days": 180, "sprite": 6},
]

const WORKSHOP_COST := [8000, 16000, 30000]   # level 1..3
const WORKSHOP_PROD := [3, 6, 10]             # extra units per day at that level
const WORKSHOP_DIVIDEND := [250, 600, 1200]   # gold per month at that level


static func good_name(g: String) -> String:
	return GOODS[g]["name"]


static func port_name(p: String) -> String:
	return PORTS[p]["name"]


static func distance(a: String, b: String) -> float:
	return (PORTS[a]["pos"] as Vector2).distance_to(PORTS[b]["pos"])


static func travel_days(a: String, b: String, ship_type: String) -> int:
	return maxi(1, int(ceil(distance(a, b) / (PX_PER_DAY * float(SHIPS[ship_type]["speed"])))))


static func date_text(day: int) -> String:
	var y := day / DAYS_YEAR + 1
	var s := (day % DAYS_YEAR) / 90
	var d := day % 90 + 1
	return "第 %d 年 %s · 第 %d 天" % [y, SEASONS[s], d]
