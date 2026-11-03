class_name GameData
## Static data tables (design doc v2). All quantities and prices are integers.

const DAYS_MONTH := 30
const DAYS_YEAR := 360
const MAX_SHIPS := 4
const PX_PER_DAY := 60.0      # map pixels a speed-1.0 ship covers per day
const CRISIS_DAYS := 30
const LOAN_RATE := 0.02       # per month
const SEASONS := ["春", "夏", "秋", "冬"]

# ------------------------------------------------------------------ goods
# tier 1 raw / 2 processed / 3 fine. icon = frame in assets/art/<atlas> (default "goods").
# home = the city that produces it naturally ("" = only players can make it).
# recipe = inputs per unit of output.
const GOODS := {
	# tier 1
	"wheat":   {"name": "云麦",   "tier": 1, "base": 24, "icon": 0,  "home": "muxia"},
	"fish":    {"name": "云鱼",   "tier": 1, "base": 28, "icon": 2,  "home": "muxia"},
	"fiber":   {"name": "云麻",   "tier": 1, "base": 30, "icon": 4,  "home": "hongxiao"},
	"fruit":   {"name": "甜霞果", "tier": 1, "base": 32, "icon": 1,  "home": "chishi"},
	"stone":   {"name": "霞纹石", "tier": 1, "base": 36, "icon": 11, "home": "chishi"},
	"timber":  {"name": "云杉木", "tier": 1, "base": 36, "icon": 4,  "atlas": "resources", "home": "tonghe"},
	"ore":     {"name": "玄铁矿", "tier": 1, "base": 40, "icon": 10, "home": "fengyue"},
	"cocoon":  {"name": "云蚕茧", "tier": 1, "base": 44, "icon": 6,  "home": "qianqi"},
	"copper":  {"name": "赤铜矿", "tier": 1, "base": 48, "icon": 12, "home": "tonghe"},
	"blubber": {"name": "鲸脂",   "tier": 1, "base": 60, "icon": 7,  "home": "xiajing"},
	"herb":    {"name": "灵参",   "tier": 1, "base": 80, "icon": 16, "home": "cuijing"},
	"incense": {"name": "香木",   "tier": 1, "base": 120, "icon": 14, "home": "cuijing"},
	"pearl":   {"name": "雾珍珠", "tier": 1, "base": 130, "icon": 13, "home": "xiajing"},
	# tier 2
	"canvas":  {"name": "风帆布", "tier": 2, "base": 84, "icon": 5,  "home": "hongxiao", "recipe": {"fiber": 2}},
	"silk":    {"name": "丝云绸", "tier": 2, "base": 120, "icon": 3,  "home": "qianqi",   "recipe": {"cocoon": 2}},
	"smoked":  {"name": "熏鱼",   "tier": 2, "base": 128, "icon": 2,  "home": "",         "recipe": {"fish": 2, "timber": 1}},
	"wine":    {"name": "霞果酒", "tier": 2, "base": 132, "icon": 6,  "atlas": "resources", "home": "", "recipe": {"fruit": 3}},
	"brass":   {"name": "铜件",   "tier": 2, "base": 132, "icon": 2,  "atlas": "resources", "home": "", "recipe": {"copper": 2}},
	"glass":   {"name": "琉璃",   "tier": 2, "base": 150, "icon": 15, "home": "",         "recipe": {"stone": 2, "timber": 1}},
	"steel":   {"name": "精钢",   "tier": 2, "base": 160, "icon": 9,  "home": "fengyue",  "recipe": {"ore": 2, "timber": 1}},
	"oil":     {"name": "灯油",   "tier": 2, "base": 164, "icon": 12, "home": "",         "recipe": {"blubber": 2}},
	# tier 3
	"rigging": {"name": "飞艇帆具", "tier": 3, "base": 330, "icon": 9,  "atlas": "resources", "home": "", "recipe": {"canvas": 3, "steel": 1}},
	"astro":   {"name": "星盘",     "tier": 3, "base": 330, "icon": 11, "atlas": "resources", "home": "", "recipe": {"brass": 2, "glass": 1}},
	"brocade": {"name": "云锦",     "tier": 3, "base": 340, "icon": 8,  "atlas": "resources", "home": "", "recipe": {"silk": 2, "pearl": 1}},
	"balm":    {"name": "香膏",     "tier": 3, "base": 350, "icon": 7,  "atlas": "resources", "home": "", "recipe": {"incense": 1, "oil": 1, "glass": 1}},
	"elixir":  {"name": "霞露",     "tier": 3, "base": 355, "icon": 17, "home": "",         "recipe": {"herb": 2, "wine": 1, "glass": 1}},
	"lamp":    {"name": "琉璃灯",   "tier": 3, "base": 360, "icon": 8,  "home": "",         "recipe": {"glass": 1, "brass": 1, "oil": 1}},
	"cannon":  {"name": "云炮",     "tier": 3, "base": 360, "icon": 3,  "atlas": "resources", "home": "", "recipe": {"steel": 2, "brass": 1}},
	"feast":   {"name": "珍馐宴盒", "tier": 3, "base": 370, "icon": 15, "atlas": "resources", "home": "", "recipe": {"smoked": 2, "wine": 1, "herb": 1}},
}
const GOOD_IDS := ["wheat", "fish", "fiber", "fruit", "stone", "timber", "ore", "cocoon", "copper", "blubber", "herb", "incense", "pearl",
	"canvas", "silk", "smoked", "wine", "brass", "glass", "steel", "oil",
	"rigging", "astro", "brocade", "balm", "elixir", "lamp", "cannon", "feast"]
const TIER_NAMES := ["", "原料", "加工品", "精品"]
const TIER_OUTPUT := [0, 4, 2, 1]          # units per day for a level-1 workshop
const TIER_BUILD_COST := [0, 5000, 11000, 20000]
const TIER_UPKEEP := [0, 150, 280, 420]    # per month
const BUILD_LEVEL_MULT := 0.6              # upgrade cost = build cost × this, per level
const MAX_BUILD_LEVEL := 3
const SIGNATURE_BONUS := 1                 # +1 unit/day when a workshop makes the city's own signature good

# blueprints: tier 1 = land deed (bought at the producing city's hall, needs friendliness 2);
# tier 2 = craft blueprint (guild, needs reputation level 3 and 100 units of the main input handled);
# tier 3 = secret blueprint (one specific guild, needs reputation level 4). Prices below.
const DEED_COST := 3000
const CRAFT_BP_COST := 8000
const SECRET_BP_COST := 36000
const SECRET_BP_CITY := {"rigging": "hongxiao", "astro": "tonghe", "brocade": "qianqi", "balm": "cuijing",
	"elixir": "cuijing", "lamp": "chishi", "cannon": "fengyue", "feast": "muxia"}
const CRAFT_HANDLED := 100

# ------------------------------------------------------------------ cities
# make: the 2 goods produced here naturally (cheap, plentiful). want: standing demand (dear).
# plots: 7 per city; a raw good id = land for that good, "workshop" = any processed/fine good.
const PORTS := {
	"qianqi":   {"name": "千旗市", "pos": Vector2(820, 520),  "island": 2, "make": ["cocoon", "silk"],   "want": ["wheat", "fish", "wine", "lamp"],
		"plots": ["cocoon", "workshop", "workshop", "cocoon", "workshop", "workshop", "workshop"],
		"desc": "霞市的枢纽，绸棚与红灯笼连成一片。富商云集，什么好东西都吃得下。"},
	"hongxiao": {"name": "红绡渡", "pos": Vector2(900, 180),  "island": 4, "make": ["fiber", "canvas"],   "want": ["fish", "fruit", "oil"],
		"plots": ["fiber", "fiber", "workshop", "fiber", "workshop", "workshop", "fiber"],
		"desc": "织坊临风而建，帆布从崖边一路晾到云里。云麻田一直铺到云边。"},
	"muxia":    {"name": "暮霞港", "pos": Vector2(470, 470),  "island": 5, "make": ["fish", "wheat"],     "want": ["steel", "canvas", "silk"],
		"plots": ["fish", "wheat", "fish", "workshop", "wheat", "fish", "workshop"],
		"desc": "渔艇傍晚归港，整片云海被染成橘红。云鱼和云麦养活了半个霞市。"},
	"xiajing":  {"name": "霞鲸台", "pos": Vector2(420, 190),  "island": 3, "make": ["pearl", "blubber"],  "want": ["wheat", "canvas", "incense"],
		"plots": ["pearl", "blubber", "pearl", "workshop", "blubber", "workshop", "pearl"],
		"desc": "云鲸迁徙的必经之地，采珠人在雾里潜行，熬鲸脂的烟整日不散。"},
	"fengyue":  {"name": "风月坞", "pos": Vector2(660, 300),  "island": 1, "make": ["ore", "steel"],      "want": ["wheat", "fruit", "smoked", "timber"],
		"plots": ["ore", "workshop", "ore", "workshop", "ore", "workshop", "workshop"],
		"desc": "锻炉日夜不熄，玄铁矿从山腹里一车车拉出来。工匠只认现钱。"},
	"cuijing":  {"name": "翠鲸岛", "pos": Vector2(1250, 330), "island": 7, "make": ["incense", "herb"],   "want": ["steel", "wheat", "glass"],
		"plots": ["incense", "herb", "workshop", "incense", "herb", "workshop", "workshop"],
		"desc": "林木蔽天的岛屿，香木在树心里慢慢结成，参园藏在雾里。"},
	"tonghe":   {"name": "铜鹤矶", "pos": Vector2(1300, 720), "island": 6, "make": ["copper", "timber"],  "want": ["fish", "canvas", "steel", "wine"],
		"plots": ["copper", "timber", "workshop", "copper", "timber", "workshop", "workshop"],
		"desc": "铜鹤风车守着港口，赤铜矿脉在岩缝里发着红光。船坞的号子从不停歇。"},
	"chishi":   {"name": "赤石矶", "pos": Vector2(850, 830),  "island": 0, "make": ["stone", "fruit"],    "want": ["silk", "fiber", "brass"],
		"plots": ["stone", "fruit", "workshop", "stone", "fruit", "workshop", "workshop"],
		"desc": "赤色岩壁里藏着霞纹石，梯田上的霞果一到秋天就红透山崖。"},
}
const PORT_IDS := ["qianqi", "hongxiao", "muxia", "xiajing", "fengyue", "cuijing", "tonghe", "chishi"]

const PATRON_FEE := 1.03      # non-patrons pay this much more when buying at a port
const BUYOUT_MULT := 1.6      # price of buying a rival's building, vs. its build cost
const MAX_CONTRACTS := 3

# friendliness (per city per house): points → level 0..5
const FRIEND_LEVELS := [0, 100, 300, 700, 1500, 3000]
const FRIEND_NAMES := ["陌生", "面熟", "相识", "信赖", "座上宾", "荣誉市民"]
const DONATION := 2000        # one donation at the city hall: +60 friend points
const DONATION_FRIEND := 60

# reputation (per house): points → level 1..6
const REP_LEVELS := [0, 150, 600, 1500, 3500, 7000]
const REP_NAMES := ["行商", "船东", "商董", "行首", "总商", "盟主候选"]
const REP_UNLOCK := [
	"最多 2 艘船",
	"可以开设商馆、建一阶工坊",
	"可以购买二阶工艺图纸",
	"船队上限 4 艘，可以获得三阶秘传图纸",
	"城主级委托，可以建灯塔灯廊",
	"可以建灯塔灯冠",
]
const REP_MAX_SHIPS := [2, 2, 3, 4, 4, 4]

# warehouses (商馆)
const WH_OPEN := 2000
const WH_START := 200
const WH_STEP := 200
const WH_MAX := 1000
const WH_UPGRADE := 3000
const WH_RENT_PER_100 := 50   # per month

# ------------------------------------------------------------------ ships
# hull = battle hit points, crew = boarding strength (and gunnery), guns = cannon count.
# pirate = true: never sold at a yard, only met in the clouds (and captured there).
const SHIPS := {
	"survey":    {"name": "测绘艇",   "price": 6000,  "cargo": 30,  "speed": 1.35, "fuel_day": 6,  "wage": 300,  "sprite": 0, "hull": 40,  "crew": 8,  "guns": 0},
	"freighter": {"name": "货艇",     "price": 12000, "cargo": 80,  "speed": 1.0,  "fuel_day": 9,  "wage": 600,  "sprite": 2, "hull": 70,  "crew": 14, "guns": 2},
	"gunboat":   {"name": "炮舰",     "price": 20000, "cargo": 50,  "speed": 1.1,  "fuel_day": 10, "wage": 800,  "sprite": 4, "hull": 90,  "crew": 20, "guns": 4},
	"galleon":   {"name": "盖伦飞艇", "price": 26000, "cargo": 160, "speed": 0.85, "fuel_day": 14, "wage": 1100, "sprite": 3, "hull": 110, "crew": 24, "guns": 3},
	"ironclad":  {"name": "铁甲舰",   "price": 48000, "cargo": 100, "speed": 0.8,  "fuel_day": 16, "wage": 1500, "sprite": 5, "hull": 160, "crew": 30, "guns": 6},
	"p_sloop":   {"name": "云盗快船", "price": 9000,  "cargo": 40,  "speed": 1.3,  "fuel_day": 7,  "wage": 350,  "sprite": 7, "hull": 50,  "crew": 12, "guns": 2, "pirate": true},
	"p_raider":  {"name": "云盗掠船", "price": 16000, "cargo": 70,  "speed": 1.0,  "fuel_day": 10, "wage": 650,  "sprite": 1, "hull": 85,  "crew": 22, "guns": 4, "pirate": true},
	"p_lord":    {"name": "云盗主舰", "price": 40000, "cargo": 120, "speed": 0.8,  "fuel_day": 15, "wage": 1100, "sprite": 8, "hull": 150, "crew": 36, "guns": 7, "pirate": true},
}

# ------------------------------------------------------------------ sailing & battle
# Seasonal wind as a unit vector in map space (y grows downward). Sailing with it is faster.
const WIND := [Vector2(-1, 0), Vector2(0, -1), Vector2(1, 0), Vector2(0, 1)]   # 东风 blows west, 南风 north, 西风 east, 北风 south
const WIND_NAMES := ["东风", "南风", "西风", "北风"]
const WIND_EFFECT := 0.15          # ±15% travel days between full head- and tail-wind
const ENCOUNTER_CHANCE := 0.06     # per voyage of a laden flagship after day 60
const TOLL_RATE := 0.06            # pirates' price for leaving you alone (of your gold, min TOLL_MIN)
const TOLL_MIN := 300
const REPAIR_RATE := 0.3           # yard repair = price × damage share × this
const DOCK_REPAIR := 4             # damage points a docked ship mends per day for free
const BOUNTY_REP := 100
const HEX_W := 11
const HEX_H := 7
const TERRAIN := {
	"storm":   {"name": "雷云",     "desc": "回合结束时停在里面的船掉 6 点耐久"},
	"fog":     {"name": "浓雾",     "desc": "里面的船受到的炮击伤害 −35%"},
	"updraft": {"name": "上升气流", "desc": "进入不耗移动力"},
	"rock":    {"name": "浮岩",     "desc": "挡路，也挡住炮火"},
}
# Protagonist's commands, one command point each, each once per round; unlocked by hero level.
const TACTICS := {
	"focus":   {"name": "集火", "lvl": 1,  "desc": "选一艘敌船：本回合我方对它的炮击伤害 +50%", "target": "enemy"},
	"rally":   {"name": "鼓舞", "lvl": 2,  "desc": "全体我方士气 +25", "target": ""},
	"wind":    {"name": "顺风", "lvl": 4,  "desc": "本回合全体我方移动力 +2", "target": ""},
	"smoke":   {"name": "烟幕", "lvl": 6,  "desc": "在一艘我方船所在格放两回合浓雾", "target": "ally"},
	"fire":    {"name": "火攻", "lvl": 8,  "desc": "旗舰 3 格内的一艘敌船和它周围的敌船各掉 12 点耐久", "target": "enemy"},
	"lure":    {"name": "诱敌", "lvl": 10, "desc": "把一艘敌船拉向旗舰 2 格，它的士气 −10", "target": "enemy"},
}
# Refits done at any shipyard, 0-3 levels each. Gold is a share of the hull's price; goods are
# taken from the ship's hold, then your warehouse here, then bought at the market.
const REFITS := {
	"hull": {"name": "船体加固", "gold": 0.15, "mats": {"steel": 8},  "desc": "每级耐久 +20%（空战用）"},
	"sail": {"name": "换帆",     "gold": 0.20, "mats": {"canvas": 12}, "desc": "每级航速 +10%，补给随之减少"},
	"hold": {"name": "扩舱",     "gold": 0.25, "mats": {"steel": 5, "canvas": 5}, "desc": "每级货舱 +15%；第 1 级航速 −8%"},
	"guns": {"name": "加炮",     "gold": 0.10, "mats": {"cannon": 2}, "desc": "每级炮位 +2（空战用）"},
}
const REFIT_MAX := 3
const FLEET_MAX := 5
const SLOTS := {"van": "先锋", "main": "主力", "rear": "后卫"}
const ROUTE_MAX_STOPS := 4
const ROUTE_MAX_BUYS := 3
const FUEL_PRICE := 12   # supplies cost per fuel_day unit

const HOUSES := {
	"lamp":  {"name": "灯油行会", "leader": "霍照野", "home": "qianqi",  "gold": 12000, "emblem": 0, "portrait": 0, "color": Color("b08a3e"),
		"perk": "sell", "perk_text": "卖出价格 +5%", "pitch": "千旗市的老牌商行，靠一手好买卖起家。最适合专心跑商。"},
	"iron":  {"name": "铁誓舰团", "leader": "韦朔",   "home": "tonghe",  "gold": 12000, "emblem": 1, "portrait": 1, "color": Color("5b7186"),
		"perk": "ships", "perk_text": "购买飞艇便宜 20%", "pitch": "铜鹤矶的船坞世家。船多路广，靠规模取胜。"},
	"tower": {"name": "白塔议士", "leader": "殷望舒", "home": "xiajing", "gold": 12000, "emblem": 2, "portrait": 2, "color": Color("8e8a7a"),
		"perk": "industry", "perk_text": "工坊便宜 25%，每天多产 1 件", "pitch": "霞鲸台的议士们擅长投资产业，慢热但后劲足。"},
}
const HOUSE_IDS := ["lamp", "iron", "tower"]
const PLAYER := "lamp"

# ------------------------------------------------------------------ protagonist
const HERO_ABIL := ["sail", "trade", "fight", "charm"]
const HERO_ABIL_NAMES := {"sail": "航海", "trade": "交易", "fight": "战斗", "charm": "魅力"}
const HERO_ABIL_DESC := {
	"sail": "每级航程缩短 3%，补给随之减少。",
	"trade": "每级买价便宜 1%，卖价高 1%。",
	"fight": "空战：每级炮击 +8%、接舷 +10%；每 4 级多 1 指挥点。",
	"charm": "每级在各城积累友好度快 10%。",
}
const HERO_MAX_ABIL := 10
const HERO_MAX_LVL := 20


## Experience needed to go from level lvl to lvl + 1.
static func hero_exp_needed(lvl: int) -> int:
	return 100 + 60 * (lvl - 1) * (lvl - 1)


const LIGHTHOUSE := [
	{"name": "基座", "gold": 40000,  "mats": {"stone": 120, "steel": 60}, "days": 120, "sprite": 1, "rep": 1},
	{"name": "灯廊", "gold": 300000, "mats": {"glass": 160, "canvas": 120}, "days": 240, "sprite": 3, "rep": 5},
	{"name": "灯冠", "gold": 1500000, "mats": {"lamp": 100, "elixir": 80, "pearl": 120}, "days": 360, "sprite": 6, "rep": 6},
]


static func good_name(g: String) -> String:
	return GOODS[g]["name"]


static func port_name(p: String) -> String:
	if not PORTS.has(p):
		push_warning("port_name: unknown port '%s'" % p)
		return "云海"
	return PORTS[p]["name"]


static func tier(g: String) -> int:
	return GOODS[g]["tier"]


static func icon_of(g: String) -> Texture2D:
	return UiKit.sprite(GOODS[g].get("atlas", "goods"), GOODS[g]["icon"])


static func trades(_p: String, _g: String) -> bool:
	return true   # every exchange trades every good (v2); kept for call sites


static func traded_goods(_p: String) -> Array:
	return GOOD_IDS


static func build_cost(g: String) -> int:
	return TIER_BUILD_COST[tier(g)]


static func upkeep_of(g: String) -> int:
	return TIER_UPKEEP[tier(g)]


static func plot_fits(p: String, i: int, g: String) -> bool:
	var t: String = PORTS[p]["plots"][i]
	return t == g if tier(g) == 1 else t == "workshop"


static func main_input(g: String) -> String:
	var r: Dictionary = GOODS[g].get("recipe", {})
	var best := ""
	for k in r:
		if best == "" or int(r[k]) > int(r[best]):
			best = k
	return best


static func rep_level(points: int) -> int:
	var lvl := 1
	for i in REP_LEVELS.size():
		if points >= REP_LEVELS[i]:
			lvl = i + 1
	return lvl


static func friend_level(points: int) -> int:
	var lvl := 0
	for i in FRIEND_LEVELS.size():
		if points >= FRIEND_LEVELS[i]:
			lvl = i
	return lvl


static func distance(a: String, b: String) -> float:
	return (PORTS[a]["pos"] as Vector2).distance_to(PORTS[b]["pos"])


static func travel_days(a: String, b: String, ship_type: String) -> int:
	return maxi(1, int(ceil(distance(a, b) / (PX_PER_DAY * float(SHIPS[ship_type]["speed"])))))


## Wind multiplier on travel time for a voyage a → b on the given day (1.0 ± WIND_EFFECT).
static func wind_factor(a: String, b: String, day: int) -> float:
	var w: Vector2 = WIND[(day % DAYS_YEAR) / 90]
	var heading: Vector2 = ((PORTS[b]["pos"] as Vector2) - (PORTS[a]["pos"] as Vector2)).normalized()
	return 1.0 - WIND_EFFECT * heading.dot(w)


static func wind_name(day: int) -> String:
	return WIND_NAMES[(day % DAYS_YEAR) / 90]


## Ship types a yard sells.
static func yard_types() -> Array:
	return SHIPS.keys().filter(func(t): return not SHIPS[t].get("pirate", false))


static func date_text(day: int) -> String:
	var y := day / DAYS_YEAR + 1
	var s := (day % DAYS_YEAR) / 90
	var d := day % 90 + 1
	return "第 %d 年 %s · 第 %d 天" % [y, SEASONS[s], d]
