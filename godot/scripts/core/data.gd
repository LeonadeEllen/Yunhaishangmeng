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

# tier 0 raw / 1 intermediate / 2 finished. icon = frame in assets/art/<atlas> (default "goods").
const GOODS := {
	"wheat":   {"name": "云麦",   "base": 25,  "tier": 0, "icon": 0},
	"fruit":   {"name": "甜霞果", "base": 32,  "tier": 0, "icon": 1},
	"fish":    {"name": "云鱼",   "base": 28,  "tier": 0, "icon": 2},
	"fiber":   {"name": "云麻",   "base": 30,  "tier": 0, "icon": 4},
	"ore":     {"name": "玄铁矿", "base": 34,  "tier": 0, "icon": 10},
	"stone":   {"name": "霞纹石", "base": 32,  "tier": 0, "icon": 11},
	"crystal": {"name": "燃晶",   "base": 45,  "tier": 0, "icon": 12},
	"herb":    {"name": "灵参",   "base": 60,  "tier": 0, "icon": 16},
	"incense": {"name": "香木",   "base": 100, "tier": 0, "icon": 14},
	"pearl":   {"name": "雾珍珠", "base": 180, "tier": 0, "icon": 13},
	"canvas":  {"name": "风帆布", "base": 85,  "tier": 1, "icon": 5},
	"silk":    {"name": "丝云绸", "base": 130, "tier": 1, "icon": 3},
	"glass":   {"name": "琉璃",   "base": 145, "tier": 1, "icon": 15},
	"steel":   {"name": "精钢",   "base": 150, "tier": 1, "icon": 9},
	"elixir":  {"name": "霞露",   "base": 330, "tier": 2, "icon": 17},
	"lamp":    {"name": "琉璃灯", "base": 400, "tier": 2, "icon": 8},
	"cannon":  {"name": "云炮",   "base": 470, "tier": 2, "icon": 3, "atlas": "resources"},
}
const GOOD_IDS := ["wheat", "fruit", "fish", "fiber", "ore", "stone", "crystal", "herb", "incense", "pearl",
	"canvas", "silk", "glass", "steel", "elixir", "lamp", "cannon"]
const TIER_NAMES := ["原料", "半成品", "成品"]

# Plot terrain: decides which buildings a plot accepts.
const TERRAIN := {
	"field": "麦田地", "orchard": "果园地", "fishery": "渔场", "hemp": "麻田地", "mine": "铁矿脉",
	"quarry": "霞纹石场", "crystal": "燃晶矿脉", "pearlbed": "珠场", "forest": "香木林", "herbs": "参园地",
	"workshop": "工坊地",
}

# Buildings. One cycle consumes `in` and makes `out`; `rate` = cycles per day.
const BUILDINGS := {
	"farm":       {"name": "麦田",   "plot": "field",    "in": {},                                  "out": {"wheat": 1},   "rate": 4.0, "cost": 4000,  "upkeep": 120},
	"orchard":    {"name": "果园",   "plot": "orchard",  "in": {},                                  "out": {"fruit": 1},   "rate": 3.0, "cost": 4500,  "upkeep": 120},
	"fishery":    {"name": "渔场",   "plot": "fishery",  "in": {},                                  "out": {"fish": 1},    "rate": 4.0, "cost": 4500,  "upkeep": 140},
	"hemp":       {"name": "麻田",   "plot": "hemp",     "in": {},                                  "out": {"fiber": 1},   "rate": 4.0, "cost": 4000,  "upkeep": 120},
	"mine":       {"name": "铁矿",   "plot": "mine",     "in": {},                                  "out": {"ore": 1},     "rate": 4.0, "cost": 6000,  "upkeep": 200},
	"quarry":     {"name": "石场",   "plot": "quarry",   "in": {},                                  "out": {"stone": 1},   "rate": 4.0, "cost": 5500,  "upkeep": 180},
	"crystal":    {"name": "晶矿",   "plot": "crystal",  "in": {},                                  "out": {"crystal": 1}, "rate": 3.0, "cost": 7000,  "upkeep": 220},
	"herbs":      {"name": "参园",   "plot": "herbs",    "in": {},                                  "out": {"herb": 1},    "rate": 2.0, "cost": 6000,  "upkeep": 160},
	"grove":      {"name": "香林",   "plot": "forest",   "in": {},                                  "out": {"incense": 1}, "rate": 1.5, "cost": 8000,  "upkeep": 200},
	"pearlbed":   {"name": "珠场",   "plot": "pearlbed", "in": {},                                  "out": {"pearl": 1},   "rate": 1.0, "cost": 10000, "upkeep": 260},
	"loom":       {"name": "帆布坊", "plot": "workshop", "in": {"fiber": 2},                        "out": {"canvas": 1},  "rate": 2.0, "cost": 8000,  "upkeep": 220},
	"silkworks":  {"name": "绸坊",   "plot": "workshop", "in": {"fiber": 2, "fruit": 1},            "out": {"silk": 1},    "rate": 1.5, "cost": 10000, "upkeep": 260},
	"forge":      {"name": "锻炉",   "plot": "workshop", "in": {"ore": 2, "crystal": 1},            "out": {"steel": 1},   "rate": 2.0, "cost": 12000, "upkeep": 320},
	"kiln":       {"name": "琉璃窑", "plot": "workshop", "in": {"stone": 2, "crystal": 1},          "out": {"glass": 1},   "rate": 2.0, "cost": 12000, "upkeep": 320},
	"lampworks":  {"name": "灯坊",   "plot": "workshop", "in": {"glass": 1, "steel": 1},            "out": {"lamp": 1},    "rate": 1.0, "cost": 16000, "upkeep": 380},
	"distillery": {"name": "霞露坊", "plot": "workshop", "in": {"herb": 1, "fruit": 1, "glass": 1}, "out": {"elixir": 1},  "rate": 1.0, "cost": 16000, "upkeep": 380},
	"foundry":    {"name": "炮坊",   "plot": "workshop", "in": {"steel": 2, "crystal": 1},          "out": {"cannon": 1},  "rate": 0.6, "cost": 20000, "upkeep": 420},
}
const BUILDING_IDS := ["farm", "orchard", "fishery", "hemp", "mine", "quarry", "crystal", "herbs", "grove", "pearlbed",
	"loom", "silkworks", "forge", "kiln", "lampworks", "distillery", "foundry"]
const SIGNATURE_BONUS := 1.25   # output multiplier when a building makes the city's signature good
const WH_START := 200           # warehouse capacity when first opened
const WH_STEP := 200
const WH_MAX := 1000
const WH_RENT := 2000
const WH_UPGRADE := 3000
const PROSP_MAX := 5

# island = frame index in assets/art/map_islands; pos in map pixels (map is 1600 x 1000)
# make: cheap here (also what the city's own folk produce); want: dear here; extra: also traded.
# plots: in unlock order; a city opens 2 + prosperity of them.
const PORTS := {
	"qianqi":   {"name": "千旗市", "pos": Vector2(820, 520), "island": 2, "make": ["silk", "lamp"], "want": ["wheat", "pearl", "elixir", "fish"], "extra": ["glass", "steel"],
		"signature": "lamp", "prosp": 3, "plots": ["workshop", "workshop", "field", "workshop", "workshop", "workshop", "field"],
		"desc": "霞市的枢纽，绸棚与红灯笼连成一片。富商云集，什么好东西都吃得下。"},
	"hongxiao": {"name": "红绡渡", "pos": Vector2(900, 180), "island": 4, "make": ["fiber", "canvas"], "want": ["lamp", "fish", "fruit"], "extra": ["silk"],
		"signature": "canvas", "prosp": 2, "plots": ["hemp", "workshop", "hemp", "workshop", "hemp", "orchard", "workshop"],
		"desc": "织坊临风而建，帆布从崖边一路晾到云里。云麻田一直铺到云边。"},
	"muxia":    {"name": "暮霞港", "pos": Vector2(470, 470), "island": 5, "make": ["fish", "wheat"], "want": ["steel", "silk", "canvas"], "extra": ["fruit", "herb"],
		"signature": "fish", "prosp": 2, "plots": ["fishery", "field", "fishery", "workshop", "field", "fishery", "herbs"],
		"desc": "渔艇傍晚归港，整片云海被染成橘红。云鱼和云麦养活了半个霞市。"},
	"xiajing":  {"name": "霞鲸台", "pos": Vector2(420, 190), "island": 3, "make": ["pearl", "fruit"], "want": ["canvas", "lamp", "wheat"], "extra": ["elixir", "herb"],
		"signature": "pearl", "prosp": 2, "plots": ["orchard", "pearlbed", "orchard", "workshop", "pearlbed", "orchard", "workshop"],
		"desc": "云鲸迁徙的必经之地，采珠人在雾里潜行。霞果园沿着鲸骨台阶层层而上。"},
	"fengyue":  {"name": "风月坞", "pos": Vector2(660, 300), "island": 1, "make": ["ore", "steel"], "want": ["fruit", "incense", "wheat", "crystal"], "extra": ["cannon"],
		"signature": "steel", "prosp": 2, "plots": ["mine", "workshop", "mine", "workshop", "workshop", "mine", "quarry"],
		"desc": "锻炉日夜不熄，玄铁矿从山腹里一车车拉出来。工匠只认现钱。"},
	"cuijing":  {"name": "翠鲸岛", "pos": Vector2(1250, 330), "island": 7, "make": ["incense", "herb", "elixir"], "want": ["steel", "wheat", "glass"], "extra": ["fruit"],
		"signature": "elixir", "prosp": 2, "plots": ["forest", "herbs", "workshop", "forest", "herbs", "orchard", "workshop"],
		"desc": "林木蔽天的岛屿，香木在树心里慢慢结成。岛民用灵参酿出霞露。"},
	"tonghe":   {"name": "铜鹤矶", "pos": Vector2(1300, 720), "island": 6, "make": ["crystal", "cannon"], "want": ["fish", "pearl", "steel", "fiber"], "extra": ["ore", "canvas"],
		"signature": "cannon", "prosp": 2, "plots": ["crystal", "workshop", "crystal", "workshop", "mine", "crystal", "workshop"],
		"desc": "铜鹤风车守着港口，燃晶矿脉在岩缝里发着蓝光。船坞的号子从不停歇。"},
	"chishi":   {"name": "赤石矶", "pos": Vector2(850, 830), "island": 0, "make": ["stone", "glass", "wheat"], "want": ["silk", "fiber", "crystal"], "extra": ["lamp"],
		"signature": "glass", "prosp": 2, "plots": ["quarry", "workshop", "field", "quarry", "workshop", "quarry", "field"],
		"desc": "赤色岩壁里藏着霞纹石，琉璃窑的火光彻夜映红山崖。"},
}
const PORT_IDS := ["qianqi", "hongxiao", "muxia", "xiajing", "fengyue", "cuijing", "tonghe", "chishi"]

const PATRON_FEE := 1.03      # non-patrons pay this much more when buying at a port
const BUYOUT_MULT := 1.6      # price of buying a rival's building, vs. its build cost
const MAX_CONTRACTS := 3


static func good_name(g: String) -> String:
	return GOODS[g]["name"]


static func port_name(p: String) -> String:
	return PORTS[p]["name"]


static func trades(p: String, g: String) -> bool:
	var d: Dictionary = PORTS[p]
	return g in d["make"] or g in d["want"] or g in d["extra"]


static func traded_goods(p: String) -> Array:
	return GOOD_IDS.filter(func(g): return trades(p, g))


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
		"perk": "industry", "perk_text": "建筑便宜 25%，产量 +15%", "pitch": "霞鲸台的议士们擅长投资产业，慢热但后劲足。"},
}
const HOUSE_IDS := ["lamp", "iron", "tower"]
const PLAYER := "lamp"

const LIGHTHOUSE := [
	{"name": "基座", "gold": 40000,  "mats": {"stone": 120, "steel": 60}, "days": 90, "sprite": 1},
	{"name": "灯廊", "gold": 100000, "mats": {"glass": 100, "canvas": 80}, "days": 120, "sprite": 3},
	{"name": "灯冠", "gold": 220000, "mats": {"lamp": 50, "elixir": 40, "pearl": 40}, "days": 180, "sprite": 6},
]



static func distance(a: String, b: String) -> float:
	return (PORTS[a]["pos"] as Vector2).distance_to(PORTS[b]["pos"])


static func travel_days(a: String, b: String, ship_type: String) -> int:
	return maxi(1, int(ceil(distance(a, b) / (PX_PER_DAY * float(SHIPS[ship_type]["speed"])))))


static func date_text(day: int) -> String:
	var y := day / DAYS_YEAR + 1
	var s := (day % DAYS_YEAR) / 90
	var d := day % 90 + 1
	return "第 %d 年 %s · 第 %d 天" % [y, SEASONS[s], d]
