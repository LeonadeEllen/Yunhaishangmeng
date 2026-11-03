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
	# ---- the eastern cloud sea (region 2): hidden in fog until the player charts it (round 10).
	# Its cities naturally make the processed goods nobody in the west makes: long hauls pay.
	"qinglu":   {"name": "青芦港", "pos": Vector2(1900, 720), "island": 2, "make": ["wheat", "wine"],     "want": ["steel", "canvas", "incense", "cannon"], "region": 2,
		"plots": ["wheat", "wheat", "workshop", "wheat", "workshop", "workshop", "wheat"],
		"desc": "东云域的门户。芦荡连天，芦酒的香气顺着风飘出几十里。这里的人第一次见到西边的帆。"},
	"jinduo":   {"name": "金铎城", "pos": Vector2(2000, 300), "island": 8, "make": ["copper", "brass"],    "want": ["silk", "wine", "lamp", "feast"], "region": 2,
		"plots": ["copper", "workshop", "copper", "workshop", "workshop", "copper", "workshop"],
		"desc": "赫兰的故乡。千座铜钟挂满城墙，整点齐鸣。铜匠的手艺是西边比不了的。"},
	"baisha":   {"name": "白砂洲", "pos": Vector2(2350, 560), "island": 5, "make": ["stone", "glass"],     "want": ["fish", "oil", "canvas", "astro"], "region": 2,
		"plots": ["stone", "workshop", "stone", "workshop", "stone", "workshop", "workshop"],
		"desc": "白色的砂洲在云上发亮，窑火把砂烧成琉璃。工匠们不识字，却能吹出会唱歌的瓶子。"},
	"jiaoyan":  {"name": "焦岩堡", "pos": Vector2(2600, 820), "island": 0, "make": ["timber", "smoked"],   "want": ["brass", "silk", "glass", "balm"], "region": 2,
		"plots": ["timber", "timber", "workshop", "timber", "workshop", "workshop", "workshop"],
		"desc": "黑色的岩堡，云盗的老巢也是云盗的集市。熏鱼和黑木在这里成交，没人问来路。"},
	"wuyin":    {"name": "雾隐泊", "pos": Vector2(2750, 250), "island": 3, "make": ["pearl", "oil"],      "want": ["wheat", "steel", "elixir"], "region": 2,
		"plots": ["pearl", "workshop", "pearl", "workshop", "pearl", "workshop", "workshop"],
		"desc": "藏在最深的雾里。整座城靠灯油活着，白天也点灯。采珠人说雾里的珍珠比西边的大一圈。"},
}
const PORT_IDS := ["qianqi", "hongxiao", "muxia", "xiajing", "fengyue", "cuijing", "tonghe", "chishi",
	"qinglu", "jinduo", "baisha", "jiaoyan", "wuyin"]
const WEST_IDS := ["qianqi", "hongxiao", "muxia", "xiajing", "fengyue", "cuijing", "tonghe", "chishi"]
const EAST_IDS := ["qinglu", "jinduo", "baisha", "jiaoyan", "wuyin"]

# ------------------------------------------------------------------ exploration (round 10)
# Points in the eastern fog. A hidden city is keyed by its port id; the rest are one-off finds.
# A point can be sailed to once it is "seen": within SIGHT of something already found.
# reward keys: gold, good [id, qty] ("random" = a random tier 1-2 good), bp (a blueprint), exp, rep,
#              ship (a derelict joins the fleet, with damage), ambush (chance of pirates waiting).
const SPOTS := {
	"fengxi":      {"name": "风隙",     "pos": Vector2(1620, 480), "kind": "passage", "icon": 0,
		"desc": "两道云崖之间的窄缝，季风在这里呼啸。探险队说，穿过去就是另一片云海。",
		"found": "风隙之后，云海豁然开朗。东边的雾里隐约有灯火。", "reward": {"exp": 120, "rep": 40}},
	"qinglu":      {"name": "青芦港",   "kind": "port"},
	"jinduo":      {"name": "金铎城",   "kind": "port"},
	"baisha":      {"name": "白砂洲",   "kind": "port"},
	"jiaoyan":     {"name": "焦岩堡",   "kind": "port"},
	"wuyin":       {"name": "雾隐泊",   "kind": "port"},
	"wreck_a":     {"name": "漂流货船", "pos": Vector2(1800, 150), "kind": "wreck", "icon": 1,
		"desc": "一艘没有旗号的货船在云里打转，甲板上没有人。",
		"found": "船舱里的货还好好的。船员把能搬的都搬了过来。", "reward": {"good": ["random", 40], "exp": 80}},
	"wreck_b":     {"name": "漂流货船", "pos": Vector2(2100, 520), "kind": "wreck", "icon": 1,
		"desc": "一艘倾斜的货船，船尾挂着半截断绳。",
		"found": "货舱里塞满了货——也塞满了等你的云盗。", "reward": {"good": ["random", 30], "exp": 80, "ambush": 0.5}},
	"wreck_c":     {"name": "搁浅的炮舰", "pos": Vector2(2750, 950), "kind": "wreck", "icon": 1,
		"desc": "一艘炮舰搁在浮岩上，船身千疮百孔，炮还在。",
		"found": "工匠们把它从浮岩上撬下来：修一修，还能飞。", "reward": {"ship": "gunboat", "exp": 150, "rep": 60}},
	"ruin_bell":   {"name": "沉钟遗迹", "pos": Vector2(2150, 150), "kind": "ruin", "icon": 2,
		"desc": "云里探出半座青铜钟楼，钟还会在风里自己响。",
		"found": "钟楼底下的密室里堆着前朝的金锭。", "reward": {"gold": 6000, "exp": 150, "rep": 80}},
	"ruin_garden": {"name": "悬园遗迹", "pos": Vector2(2500, 420), "kind": "ruin", "icon": 2,
		"desc": "一座悬在云上的废园，香木长成了林。",
		"found": "园中石碑上刻着香膏的古法。你的工匠一字一字抄了下来。", "reward": {"bp": "balm", "exp": 200, "rep": 80}},
	"ruin_fort":   {"name": "断崖残堡", "pos": Vector2(2850, 600), "kind": "ruin", "icon": 2,
		"desc": "崖壁上的堡垒塌了一半，炮口还朝着东方。",
		"found": "堡里的云炮完好无损，一共六门。", "reward": {"good": ["cannon", 6], "gold": 3000, "exp": 150, "rep": 60}},
	"ruin_temple": {"name": "鲸骨神庙", "pos": Vector2(2300, 900), "kind": "ruin", "icon": 2,
		"desc": "用整条云鲸的骨架搭成的神庙。雾里有歌声。",
		"found": "神庙里供着一瓮瓮霞露，守庙的老人把它们送给了你。", "reward": {"good": ["elixir", 10], "exp": 200, "rep": 80}},
}
const SPOT_IDS := ["fengxi", "qinglu", "jinduo", "baisha", "jiaoyan", "wuyin", "wreck_a", "wreck_b", "wreck_c",
	"ruin_bell", "ruin_garden", "ruin_fort", "ruin_temple"]
const SPOT_KIND_NAMES := {"passage": "航路", "port": "城市", "wreck": "漂流物", "ruin": "遗迹"}
const EXPEDITION_COST := 40000     # sponsor an expedition at any guild to chart the passage east
const EXPEDITION_REP := 3
const SIGHT := 440.0               # map pixels: how far a discovery lets you see into the fog
const EAST_ENCOUNTER := 2.0        # pirates are this much more common on voyages touching the east
const EAST_X := 1560.0             # map x where the western charts end

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
const RIVAL_ENCOUNTER := 0.05      # per laden voyage of a rival ship: pirates rob everyone
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
		"perk": "ships", "perk_text": "购买飞艇便宜 20%，航速 +10%，载货 +10%", "pitch": "铜鹤矶的船坞世家。船多路广，靠规模取胜。"},
	"tower": {"name": "白塔议士", "leader": "殷望舒", "home": "xiajing", "gold": 12000, "emblem": 2, "portrait": 2, "color": Color("8e8a7a"),
		"perk": "industry", "perk_text": "工坊便宜 15%，原料产地每天多产 1 件", "pitch": "霞鲸台的议士们擅长投资产业，慢热但后劲足。"},
}
const HOUSE_IDS := ["lamp", "iron", "tower"]

# the house's headquarters in its home city (round 13): a place to spend big and feel it
const HQ := [
	{"name": "商会小院", "cost": 0, "crew": 0, "rep": 0, "wage": 1.0, "ships": 0, "desc": "起家的小院子。"},
	{"name": "商会会馆", "cost": 20000, "crew": 1, "rep": 15, "wage": 1.0, "ships": 0, "desc": "伙伴上限 +1，每月名声 +15。"},
	{"name": "商会大厦", "cost": 60000, "crew": 2, "rep": 35, "wage": 0.9, "ships": 0, "desc": "伙伴上限 +2，每月名声 +35，伙伴月薪 −10%。"},
	{"name": "盟会总馆", "cost": 150000, "crew": 3, "rep": 60, "wage": 0.8, "ships": 1, "desc": "伙伴上限 +3，每月名声 +60，伙伴月薪 −20%，船队上限 +1。"},
]
const HQ_REP := [0, 2, 3, 4]        # reputation level needed to build each HQ level
const RIVAL_MEET := 0.45            # chance of a rival captain hailing you when you dock beside their ship
const RIVAL_MEET_GAP := 45          # days between such meetings
const RIVAL_DELAY_COST := 1200
const RIVAL_DELAY_DAYS := 6

# city works (round 14): any house may fund the next level; the biggest funder is the city's benefactor
const WORKS := {
	"dock": {"name": "码头", "desc": "从本城出航的补给每级 −10%，停泊的船每级修得快一倍"},
	"market": {"name": "集市", "desc": "本城行情每级恢复快 30%：能多卖些货而不把价压垮"},
	"school": {"name": "学堂", "desc": "本城所有工坊产量每级 +10%"},
}
const WORK_IDS := ["dock", "market", "school"]
const WORK_COST := [0, 10000, 25000, 60000]
const WORK_MAX := 3
const WORK_REP := 2                  # reputation level needed to fund city works
const BENEFACTOR_DISCOUNT := 0.97    # the benefactor buys cheaper here
const BENEFACTOR_REP := 10           # monthly reputation per city

# the lantern festival (round 15): opens every new year with awards and a year-end review
const FESTIVAL_DAYS := 12
const FESTIVAL_PRIZE := 6000
const FESTIVAL_REP := {"race": 150, "trade": 150, "works": 100}
const FESTIVAL_GOODS := ["fruit", "silk", "wine"]   # sell for more while the lanterns are up
const FESTIVAL_SELL := 1.15
const RIVAL_RACE := 0.08             # two rival ships in one port may race each other
const RIVAL_RACE_GAP := 30
const RIVAL_RACE_STAKE := 1500
## What each house leader says at the year review, by their situation (round 24).
const LEADER_LINES := {
	"lamp": {
		"award": "霍照野举着灯笼笑：「灯油行会的灯，今年照得最远。」",
		"lead": "霍照野把账本合上：「生意嘛，谁的灯亮谁说话。」",
		"behind": "霍照野摸着下巴：「今年让你们跑在前头，明年再说。」",
		"crown": "霍照野望着灯冠：「这盏灯，我点了半辈子。」",
		"crown_other": "霍照野看着别人的灯冠，半晌只说：「亮是真亮。」",
		"bankrupt": "霍照野的位子空着，桌上留了一盏没点的灯。",
	},
	"iron": {
		"award": "韦朔把奖杯往桌上一放：「船快，没什么好说的。」",
		"lead": "韦朔哈哈大笑：「追得上我的船再来谈生意。」",
		"behind": "韦朔盯着自己的酒碗：「风向不对。明年换条航线。」",
		"crown": "韦朔站在灯冠下，第一次没有大声说话。",
		"crown_other": "韦朔朝灯冠举了举碗：「算你赢。再赛一程？」",
		"bankrupt": "韦朔的位子空着，有人说他驾着最后一艘船往东去了。",
	},
	"tower": {
		"award": "殷望舒合上扇子：「数字不会说谎，今年它站在我这边。」",
		"lead": "殷望舒微微一笑：「各位的账，我都替你们算过了。」",
		"behind": "殷望舒的扇子停了一下：「有意思。我漏算了什么？」",
		"crown": "殷望舒望着灯冠，轻声说：「议士们，可以散会了。」",
		"crown_other": "殷望舒向灯冠的主人欠身：「这一局，你算得比我准。」",
		"bankrupt": "殷望舒的位子空着，扇子留在桌上，没人敢动。",
	},
}

## A leader's last words when their house goes under (round 24).
const LEADER_FAREWELL := {
	"lamp": "霍照野把最后一盏灯油交到你手里：「灯油行会没了，灯还得有人点。千旗市的老伙计们，拜托你照应。」",
	"iron": "韦朔站在最后一艘飞艇的船头，朝你喊：「铁誓舰团散了，船还在！下次在云海上碰见，别认错人。」",
	"tower": "殷望舒把一叠账本放在你桌上：「白塔议士散会了。这些是十年的行情，留给算得比我准的人。」",
}

## Milestones: the small satisfactions on the road to the crown (round 21). Checked daily; each gives reputation once.
const MILESTONE_REP := 20
const MILESTONES := [
	{"id": "first_trade", "name": "第一笔买卖", "desc": "在任何港口卖出一批货。"},
	{"id": "profit_10k", "name": "万金利润", "desc": "累计跑商利润达到 10,000 金。"},
	{"id": "second_ship", "name": "第二艘船", "desc": "船队有两艘船。"},
	{"id": "first_route", "name": "第一条航线", "desc": "给一艘船设好自动往返的航线。"},
	{"id": "first_contract", "name": "第一件委托", "desc": "完成一张求购单。"},
	{"id": "first_crew", "name": "第一位伙伴", "desc": "招募一位伙伴。"},
	{"id": "rep_owner", "name": "名声「船东」", "desc": "名声到 150，可以开商馆、建工坊。"},
	{"id": "first_workshop", "name": "第一座工坊", "desc": "在某座城建起自己的工坊。"},
	{"id": "first_win", "name": "第一场胜仗", "desc": "在空战里打赢云盗。"},
	{"id": "lh1", "name": "灯塔基座", "desc": "点亮灯塔第一层。"},
	{"id": "hq2", "name": "会馆扩建", "desc": "把母港的商会总部扩建一级。"},
	{"id": "benefactor", "name": "第一座恩主城", "desc": "成为一座城的恩主。"},
	{"id": "east", "name": "东云海", "desc": "旗舰到过东边的任何一座港。"},
	{"id": "award", "name": "灯节得奖", "desc": "在灯节上拿到任意一项奖。"},
	{"id": "first_ally", "name": "第一位盟友", "desc": "与一家对手商会结为盟友。"},
	{"id": "free_crew", "name": "第一位免薪伙伴", "desc": "办成一位伙伴的第二件托付。"},
	{"id": "worth_1m", "name": "身家百万", "desc": "净资产达到 1,000,000 金。"},
	{"id": "lh2", "name": "灯廊", "desc": "点亮灯塔第二层。"},
	{"id": "lh3", "name": "灯冠", "desc": "点亮灯塔第三层，成为云海盟主。"},
]

## At the lantern festival a rival may challenge the player (round 18).
const FESTIVAL_CHALLENGE := 0.6
const FESTIVAL_STAKE_MIN := 2000
const FESTIVAL_STAKE_MAX := 15000
const FESTIVAL_DUEL_REP := {"win": 120, "lose": 40}
const LEADER_HE := {"lamp": "他", "iron": "他", "tower": "她"}

# relationships between the three houses (round 26): −100 宿敌 … 100 盟友, one value per pair
const TIE_ALLY := 40                 # at or above: 盟友
const TIE_FEUD := -40                # at or below: 宿敌
const TIE_DECAY := 1                 # per month, toward 0
const TIE_LEADER_DRIFT := 4          # per month: the two houses trailing the richest warm to each other
const TIE_ENVY := 2                  # per month: the richest house is resented by the other two
const TIE_DRIFT_CAP := 35            # drift alone never allies or feuds a pair that includes the player
const TIE_GIFT_COST := 3000
const TIE_GIFT := 12
const TIE_GIFT_GAP := 30             # days between gifts to the same house
const TIE_ASK_MIN := 20              # relationship needed before proposing an alliance
const TIE_ASK_GAP := 60              # days before asking the same house again
const TIE_RACE := 8                  # a lost race sours the pair by this much
const TIE_DUEL := 6                  # a lost debate or festival duel
const TIE_DRINK := 6                 # a drink together
const TIE_BUYOUT := 20               # buying a house's workshop out from under them
const TIE_DELAY := 25                # a bribed harbour master, once it comes out
const TIE_NAMES := ["宿敌", "不睦", "平常", "友善", "盟友"]
const ALLY_LH_SHARE := 0.1           # an ally pays this share of a lighthouse stage when the other starts it
const ALLY_GIFT := 0.05              # festival gift from an allied house: this share of their gold…
const ALLY_GIFT_MIN := 1000          # …clamped to this range
const ALLY_GIFT_MAX := 8000
const FEUD_INCIDENT := 0.12          # per month, between two feuding houses
const FEUD_DELAY_DAYS := 10
const FEUD_BUYOUT := 0.75            # a 宿敌's workshop sells for this fraction of the usual buyout price
const FEUD_REP_MULT := 1.5           # beating a 宿敌 in a race or debate pays this much more reputation
const FEUD_RACE_MULT := 3.0          # feuding houses race each other this much more often
# what an ally is good for (round 27)
const LOAN_DAYS := 60                # a borrowed ally ship sails with the fleet this long
const LOAN_RENT := 0.06              # rent, as a share of the ship's price
const LOAN_LOST := 0.5               # compensation for a borrowed ship lost in battle, share of its price
const LOAN_LOST_TIE := 30
const ALLY_BUYOUT_SHARE := 0.3       # an ally pays this share of a buyout against a third house
const BAIL_TIE := 15                 # bailing an ally out of a debt crisis
const BAIL_REFUSE_TIE := 20
const BAIL_MAX := 0.3                # the player is asked only when the need is within this share of their gold
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
	if PORTS.has(p):
		return PORTS[p]["name"]
	if SPOTS.has(p):
		return SPOTS[p]["name"]
	push_warning("port_name: unknown port '%s'" % p)
	return "云海"


## Map position of a port or an exploration point.
static func pos_of(id: String) -> Vector2:
	if PORTS.has(id):
		return PORTS[id]["pos"]
	if SPOTS.has(id):
		return SPOTS[id]["pos"]
	return Vector2(800, 500)


static func region_of(id: String) -> int:
	if PORTS.has(id):
		return int(PORTS[id].get("region", 1))
	return 2 if pos_of(id).x >= EAST_X else 1


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
	return pos_of(a).distance_to(pos_of(b))


static func travel_days(a: String, b: String, ship_type: String) -> int:
	return maxi(1, int(ceil(distance(a, b) / (PX_PER_DAY * float(SHIPS[ship_type]["speed"])))))


## Wind multiplier on travel time for a voyage a → b on the given day (1.0 ± WIND_EFFECT).
static func wind_factor(a: String, b: String, day: int) -> float:
	var w: Vector2 = WIND[(day % DAYS_YEAR) / 90]
	var heading: Vector2 = (pos_of(b) - pos_of(a)).normalized()
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
