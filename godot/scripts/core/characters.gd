class_name Characters
## The twelve recruitable companions (大航海时代4 flavour): who they are, what they are good at,
## where you find them, and their three-chapter personal stories. Pure data.
##
## abil: 航海 sail / 交易 trade / 战斗 fight / 魅力 charm, 1-10.
## spec: a unique perk id read by Sim.spec_bonus(); after the third chapter it is 1.5× as strong.
## where: tavern / yard / guild / hall (the building tab) or "any" (every tavern); port "" = anywhere.
## cond keys: story (main story stage), rep (level), friend (level at the port), wins (battles won),
##            visited (ports seen), craft_bp (craft blueprints owned), workshops (owned), refits.

const PORTRAITS := {"luqing": 5, "qian": 2, "aman": 7, "shen": 3, "cen": 1, "xiaoman": 4, "moyu": 6, "ning": 2, "feng": 0, "sang": 1, "helan": 7, "ling": 5, "duoyin": 3, "lusheng": 4}

const POSTS := {
	"nav": {"name": "航海长", "abil": "sail", "desc": "每级航程 −1%、甩开云盗 +2%"},
	"acct": {"name": "账房", "abil": "trade", "desc": "每级买价 −0.4%、卖价 +0.4%"},
	"gunner": {"name": "炮术长", "abil": "fight", "desc": "每级炮击伤害 +2.5%"},
	"boarder": {"name": "接舷队长", "abil": "fight", "desc": "每级接舷战力 +3%"},
	"captain": {"name": "船长", "abil": "sail", "desc": "带一艘非旗舰的船：每级航速 +1.5%"},
}
const CREW_CAP := [3, 4, 5, 6, 8, 12]   # by reputation level
const GIFT_COST := 300
const GIFT_AFF := 10
const CHAPTER_AFF := [30, 60, 100]

const CHARS := {
	"xiaoman": {"name": "小满", "title": "酒馆跑堂少年", "style": "机灵，爱打听，会跟着你一起长大。",
		"abil": {"sail": 2, "trade": 3, "fight": 1, "charm": 4}, "spec": "rumours", "spec_name": "传闻",
		"spec_desc": "每月月初，你到过的港口行情自动更新。", "port": "muxia", "where": "tavern", "cond": {}, "fee": 600, "wage": 120,
		"story": [
			{"title": "第一桶金", "text": "小满攒了三年的赏钱想跟你入一股：「少主，我也想当东家。」",
			 "choices": [{"label": "收下他的 50 金，记在账上", "fx": {"aff": 15, "say": "小满把那张借据贴身收着。"}}, {"label": "笑着拒绝，让他好好跑堂", "fx": {"aff": 5}}]},
			{"title": "家书", "text": "小满的母亲托人捎信，说家里的渔船漏了。他不肯开口借钱。",
			 "choices": [{"label": "悄悄替他寄 800 金回去", "fx": {"gold": -800, "aff": 15, "say": "小满后来知道了，一个月没敢直视你。"}}, {"label": "装作不知道", "fx": {"aff": 3}}]},
			{"title": "长大了", "text": "小满把各港掌柜的脾气记成了一本小册子，交给你：「以后打听消息，不用再花钱了。」",
			 "choices": [{"label": "让他做商会的情报总管", "fx": {"aff": 15, "spec_up": true, "say": "小满的传闻网从此遍布云海。"}}, {"label": "收下册子，给他涨薪", "fx": {"aff": 10, "spec_up": true}}]},
		]},
	"luqing": {"name": "陆青", "title": "霞鲸台采珠女", "style": "冷静寡言，在找失踪的父亲。",
		"abil": {"sail": 6, "trade": 2, "fight": 3, "charm": 3}, "spec": "fog_nav", "spec_name": "雾中航行",
		"spec_desc": "航程 −3%，甩开云盗 +15%。", "port": "xiajing", "where": "tavern", "cond": {"story": 1}, "fee": 1500, "wage": 260,
		"story": [
			{"title": "父亲的航图", "text": "陆青摊开半张焦黑的航图：「父亲最后一次出航，走的是这条没人走的雾道。」",
			 "choices": [{"label": "陪她沿雾道走一趟", "fx": {"aff": 15, "say": "雾里什么也没找到，但她第一次对你笑了。"}}, {"label": "先把生意做完再说", "fx": {"aff": 3}}]},
			{"title": "债主", "text": "风月坞的债主又来要钱，说她父亲还欠着 2,000 金的船款。",
			 "choices": [{"label": "替她还清", "fx": {"gold": -2000, "aff": 15, "say": "「我会还你的。」她说得很认真。"}}, {"label": "让她自己处理", "fx": {"aff": 2}}]},
			{"title": "鲸歌", "text": "云鲸迁徙的夜里，陆青在雾中听见了父亲船上的铃声。她说，不找了，父亲已经成了云海的一部分。",
			 "choices": [{"label": "「以后我的船队就是你的家。」", "fx": {"aff": 20, "spec_up": true, "say": "陆青从此是云海上最好的雾中领航。"}}, {"label": "默默陪她站到天亮", "fx": {"aff": 12, "spec_up": true}}]},
		]},
	"qian": {"name": "钱不让", "title": "精打细算的账房先生", "style": "嘴碎，爱财如命，却从不做假账。",
		"abil": {"sail": 1, "trade": 8, "fight": 1, "charm": 3}, "spec": "haggle", "spec_name": "压价",
		"spec_desc": "买价再便宜 3%。", "port": "qianqi", "where": "tavern", "cond": {"rep": 2}, "fee": 2400, "wage": 320,
		"story": [
			{"title": "一文钱", "text": "钱不让为了一文钱的差额和掌柜吵了半个时辰，整条街都在看热闹。",
			 "choices": [{"label": "站在他这边，一文也不让", "fx": {"aff": 15, "say": "掌柜认了，钱不让哼着小曲回来。"}}, {"label": "替他补上那一文", "fx": {"aff": 5}}]},
			{"title": "假账", "text": "对手商会出 5,000 金请他做一本假账陷害你。他把信原封不动放在你桌上。",
			 "choices": [{"label": "给他同样的 5,000 金做奖赏", "fx": {"gold": -5000, "aff": 20, "say": "「我就知道跟对了人。」"}}, {"label": "口头嘉奖", "fx": {"aff": 8}}]},
			{"title": "老家的账本", "text": "钱不让说出了心事：他家原是千旗市的大商号，被一本假账搞垮。他想亲手把商号的旧匾挂回去。",
			 "choices": [{"label": "买下旧铺面送给他（3,000 金）", "fx": {"gold": -3000, "aff": 20, "spec_up": true, "say": "匾挂上的那天，钱不让哭得像个孩子。"}}, {"label": "答应将来帮他", "fx": {"aff": 10, "spec_up": true}}]},
		]},
	"aman": {"name": "阿蛮", "title": "云盗出身的炮手", "style": "豪爽粗犷，背叛了旧帮派。",
		"abil": {"sail": 4, "trade": 1, "fight": 8, "charm": 2}, "spec": "gunnery", "spec_name": "炮击",
		"spec_desc": "空战炮击伤害 +15%。", "port": "", "where": "any", "cond": {"wins": 1}, "fee": 2000, "wage": 400,
		"story": [
			{"title": "旧帮派", "text": "酒馆里有人认出了阿蛮，骂他叛徒。他攥紧了酒碗。",
			 "choices": [{"label": "替他把那人轰出去", "fx": {"aff": 15, "say": "阿蛮一拳砸在桌上：「够意思！」"}}, {"label": "劝他别惹事", "fx": {"aff": 4}}]},
			{"title": "黑帆", "text": "阿蛮说旧帮派的头目「黑帆」杀了他的兄弟，他想亲手报仇。",
			 "choices": [{"label": "答应陪他去", "fx": {"aff": 15, "say": "「等打赢了，我请你喝到天亮。」"}}, {"label": "劝他放下", "fx": {"aff": 3}}]},
			{"title": "最后一炮", "text": "黑帆的船沉进云海的那一刻，阿蛮没有欢呼。他把一面旧旗扔进了云里。",
			 "choices": [{"label": "「从今天起，你是我的炮术总管。」", "fx": {"aff": 20, "spec_up": true, "say": "阿蛮的炮从此指哪打哪。"}}, {"label": "拍拍他的肩", "fx": {"aff": 12, "spec_up": true}}]},
		]},
	"shen": {"name": "沈白鹭", "title": "落魄世家的剑客", "style": "骄傲，最看重名誉。",
		"abil": {"sail": 3, "trade": 2, "fight": 7, "charm": 5}, "spec": "boarding", "spec_name": "接舷",
		"spec_desc": "接舷战力 +20%。", "port": "fengyue", "where": "tavern", "cond": {"rep": 3}, "fee": 3000, "wage": 420,
		"story": [
			{"title": "家传剑", "text": "沈白鹭的家传剑被押在风月坞的当铺里，他说不起眼，却总往当铺那边看。",
			 "choices": [{"label": "赎回来（1,200 金）", "fx": {"gold": -1200, "aff": 15, "say": "他接剑的手在抖。"}}, {"label": "不管", "fx": {"aff": 2}}]},
			{"title": "挑战", "text": "铁誓舰团的武士在码头当众挑战沈白鹭，说世家的剑早就钝了。",
			 "choices": [{"label": "让他应战", "fx": {"aff": 15, "say": "三招，对方的刀飞进了云里。"}}, {"label": "拦下他，不值得", "fx": {"aff": 5}}]},
			{"title": "名誉", "text": "沈白鹭说，他家的名声不是靠剑，是靠守信。他要替祖上还清一笔三十年前的货款。",
			 "choices": [{"label": "商会替他还（4,000 金）", "fx": {"gold": -4000, "aff": 20, "spec_up": true, "say": "沈家的名字，重新挂回了风月坞的信义榜。"}}, {"label": "陪他亲自去道歉", "fx": {"aff": 12, "spec_up": true}}]},
		]},
	"cen": {"name": "老岑", "title": "退役船匠", "style": "脾气古怪，手艺一流。",
		"abil": {"sail": 5, "trade": 2, "fight": 2, "charm": 1}, "spec": "shipwright", "spec_name": "巧手",
		"spec_desc": "改造和修理的工费 −25%；入伙时带来星盘的秘传图纸。", "port": "tonghe", "where": "yard", "cond": {"friend": 1}, "fee": 1800, "wage": 300,
		"story": [
			{"title": "废船", "text": "老岑盯着船坞角落一艘废船看了一下午：「这船的龙骨比你们现在造的都好。」",
			 "choices": [{"label": "买下来给他拆着玩（600 金）", "fx": {"gold": -600, "aff": 15, "say": "老岑三天没出船坞。"}}, {"label": "随他看", "fx": {"aff": 4}}]},
			{"title": "徒弟", "text": "铜鹤矶船坞的年轻船匠想拜老岑为师，老岑嫌他手笨。",
			 "choices": [{"label": "劝老岑收下", "fx": {"aff": 12, "say": "「笨就多练。」老岑嘴硬，手上却教得仔细。"}}, {"label": "由他去", "fx": {"aff": 4}}]},
			{"title": "最后一艘船", "text": "老岑说，他这辈子想亲手造一艘不用云炮也能横行云海的快船，就缺一座像样的船坞。",
			 "choices": [{"label": "出资建一座（5,000 金）", "fx": {"gold": -5000, "aff": 20, "spec_up": true, "say": "老岑把新船坞的第一块木料刻上了你的旗号。"}}, {"label": "答应以后", "fx": {"aff": 10, "spec_up": true}}]},
		]},
	"moyu": {"name": "莫语", "title": "不说话的测绘师", "style": "用画和人交流。",
		"abil": {"sail": 7, "trade": 1, "fight": 2, "charm": 2}, "spec": "survey", "spec_name": "测绘",
		"spec_desc": "航程 −5%。", "port": "chishi", "where": "tavern", "cond": {"visited": 8}, "fee": 2000, "wage": 280,
		"story": [
			{"title": "一幅画", "text": "莫语递给你一幅画：你的旗舰穿过一道从没见过的峡谷。",
			 "choices": [{"label": "按画里的路试一次", "fx": {"aff": 15, "say": "峡谷真的在那里，省了两天路。"}}, {"label": "收下画", "fx": {"aff": 5}}]},
			{"title": "云海的尽头", "text": "莫语画了一幅没有边的海图，最东边画着一座陌生的城。她指着那里看你。",
			 "choices": [{"label": "「总有一天我们去看看。」", "fx": {"aff": 15, "explore": true, "say": "她笑了，在画角添上了你的船——还有一道通往东边的风隙。"}}, {"label": "摇头，太远了", "fx": {"aff": 2}}]},
			{"title": "声音", "text": "暴雨夜，莫语第一次开口，只说了三个字：「谢谢你。」",
			 "choices": [{"label": "「以后的海图都由你来画。」", "fx": {"aff": 20, "spec_up": true, "say": "莫语的海图成了商会最珍贵的财产。"}}, {"label": "笑着点头", "fx": {"aff": 12, "spec_up": true}}]},
		]},
	"ning": {"name": "宁朝雨", "title": "白塔出走的学者", "style": "理想主义。",
		"abil": {"sail": 2, "trade": 5, "fight": 1, "charm": 6}, "spec": "research", "spec_name": "研究",
		"spec_desc": "图纸价格 −25%，主角经验 +10%。", "port": "cuijing", "where": "guild", "cond": {"rep": 3, "craft_bp": 1}, "fee": 3500, "wage": 380,
		"story": [
			{"title": "禁书", "text": "宁朝雨从白塔带出来的手稿被人盯上了。他问你能不能把它藏在商馆里。",
			 "choices": [{"label": "藏下", "fx": {"aff": 15, "say": "手稿里记着一些失传的配方。"}}, {"label": "太危险，拒绝", "fx": {"aff": 2}}]},
			{"title": "学堂", "text": "宁朝雨想在翠鲸岛办一间不收钱的学堂，教孩子们算账和识图。",
			 "choices": [{"label": "出资（2,500 金）", "fx": {"gold": -2500, "aff": 15, "say": "第一批学生里有三个后来进了你的商会。"}}, {"label": "口头支持", "fx": {"aff": 5}}]},
			{"title": "白塔的信", "text": "白塔来信请他回去主持研究院。他把信给你看，没有说话。",
			 "choices": [{"label": "「留下来，这里也能做学问。」", "fx": {"aff": 20, "spec_up": true, "say": "宁朝雨把信烧了，开始写商会的第一本技艺总录。"}}, {"label": "让他自己决定", "fx": {"aff": 12, "spec_up": true}}]},
		]},
	"feng": {"name": "风九娘", "title": "走私女商人", "style": "八面玲珑，亦正亦邪。",
		"abil": {"sail": 4, "trade": 7, "fight": 3, "charm": 8}, "spec": "blackmarket", "spec_name": "黑市",
		"spec_desc": "在红绡渡卖价 +5%，云盗过路费减半。", "port": "hongxiao", "where": "tavern", "cond": {"friend": 2}, "fee": 4000, "wage": 450,
		"story": [
			{"title": "夜市", "text": "风九娘带你逛红绡渡的夜市，顺手把一包东西塞进你怀里：「别问。」",
			 "choices": [{"label": "收下", "fx": {"aff": 12, "good": ["pearl", 6], "say": "是六颗成色极好的雾珍珠。"}}, {"label": "还给她", "fx": {"aff": 6}}]},
			{"title": "两面", "text": "有人告诉你，风九娘同时也在给白塔议士带货。她听了只是笑：「我从不骗自己人。」",
			 "choices": [{"label": "选择相信", "fx": {"aff": 15, "say": "后来她把白塔的航线全告诉了你。"}}, {"label": "警告她", "fx": {"aff": 2}}]},
			{"title": "身世", "text": "风九娘说她本是云盗的女儿，母亲死后才上岸做生意。「你还要我吗？」",
			 "choices": [{"label": "「要。」", "fx": {"aff": 20, "spec_up": true, "say": "风九娘从此只替你一家做生意。"}}, {"label": "沉默了很久，点头", "fx": {"aff": 12, "spec_up": true}}]},
		]},
	"sang": {"name": "桑铁手", "title": "失去一只手的铸炮匠", "style": "沉默而执拗。",
		"abil": {"sail": 1, "trade": 3, "fight": 4, "charm": 1}, "spec": "forge", "spec_name": "锻炉",
		"spec_desc": "你的每座工坊产量 +15%。", "port": "fengyue", "where": "guild", "cond": {"workshops": 2}, "fee": 2800, "wage": 360,
		"story": [
			{"title": "铁手", "text": "桑铁手的铁手坏了，他一言不发地用左手干活。",
			 "choices": [{"label": "请最好的匠人替他修（900 金）", "fx": {"gold": -900, "aff": 15, "say": "新铁手比原来的更灵活。"}}, {"label": "让他歇几天", "fx": {"aff": 5}}]},
			{"title": "炸膛", "text": "一门新炮试射时炸了膛。桑铁手把自己关在炉房里三天。",
			 "choices": [{"label": "陪他重铸", "fx": {"aff": 15, "say": "第四天，新炮一发打穿了三层靶板。"}}, {"label": "等他出来", "fx": {"aff": 4}}]},
			{"title": "最后一门炮", "text": "桑铁手说，他的手是铸「初风暴」时的那门巨炮炸掉的。他想铸一门永远不会炸膛的炮。",
			 "choices": [{"label": "给他最好的精钢（3,000 金）", "fx": {"gold": -3000, "aff": 20, "spec_up": true, "say": "那门炮至今挂在你旗舰的船头。"}}, {"label": "答应以后", "fx": {"aff": 10, "spec_up": true}}]},
		]},
	"helan": {"name": "赫兰", "title": "从别的云域来的异乡商人", "style": "语言不通，手势比划。",
		"abil": {"sail": 5, "trade": 6, "fight": 3, "charm": 4}, "spec": "foreign", "spec_name": "远客",
		"spec_desc": "精品（三阶）卖价 +8%。", "port": "", "where": "roam", "cond": {}, "fee": 3000, "wage": 400,
		"story": [
			{"title": "手势", "text": "赫兰比划了半天，你终于明白：他的家乡在云海东边很远的地方，一场风暴把他吹到了这里。",
			 "choices": [{"label": "教他说云海话", "fx": {"aff": 15, "say": "他学会的第一句是「多少钱」。"}}, {"label": "点头", "fx": {"aff": 4}}]},
			{"title": "故乡的货", "text": "赫兰掏出一块从没见过的金属，上面刻着陌生的文字。他比划着说，那边有很多。",
			 "choices": [{"label": "小心收好", "fx": {"aff": 15, "say": "你把它锁进了商会的保险柜。"}}, {"label": "还给他", "fx": {"aff": 6}}]},
			{"title": "东方", "text": "赫兰已经能说简单的云海话了。他说：「总有一天，带你去我的家乡。」",
			 "choices": [{"label": "「一言为定。」", "fx": {"aff": 20, "spec_up": true, "explore": true, "say": "赫兰在海图东边画下一道风隙：「从这里过去。」"}}, {"label": "笑着举杯", "fx": {"aff": 12, "spec_up": true}}]},
		]},
	"ling": {"name": "灵", "title": "云鲸的使者少女", "style": "身世和初风暴有关。",
		"abil": {"sail": 8, "trade": 1, "fight": 5, "charm": 9}, "spec": "spirit", "spec_name": "鲸语",
		"spec_desc": "空战指挥点 +1，全军士气 +10。", "port": "xiajing", "where": "tavern", "cond": {"story": 3}, "fee": 0, "wage": 0,
		"story": [
			{"title": "鲸语", "text": "灵站在船头对云海说话，一群云鲸从船底掠过。",
			 "choices": [{"label": "听她讲鲸群的故事", "fx": {"aff": 15, "say": "她说，鲸记得四十年前那场风暴。"}}, {"label": "让船员别吵", "fx": {"aff": 6}}]},
			{"title": "初风暴", "text": "灵说，初风暴不是天灾，是有人在灯塔上点了不该点的灯。",
			 "choices": [{"label": "追问是谁", "fx": {"aff": 15, "say": "她摇头：「等你的灯塔亮了，你会知道。」"}}, {"label": "不再追问", "fx": {"aff": 6}}]},
			{"title": "灯", "text": "灵说她的使命是守着灯塔不再出事。「你的灯，我来守。」",
			 "choices": [{"label": "「那就一起守。」", "fx": {"aff": 20, "spec_up": true, "say": "从此你的船队出航时，总有云鲸相随。"}}, {"label": "郑重点头", "fx": {"aff": 12, "spec_up": true}}]},
		]},
	# ---- the eastern sea (round 12)
	"duoyin": {"name": "铎音", "title": "金铎城的铸钟女匠", "style": "声音洪亮，说话像敲钟，认死理。",
		"abil": {"sail": 6, "trade": 3, "fight": 4, "charm": 4}, "spec": "eastern", "spec_name": "东海领航",
		"spec_desc": "去东云域的航程 −10%，东边遇上云盗的概率减半。", "port": "jinduo", "where": "guild", "cond": {"friend": 1}, "fee": 2600, "wage": 340,
		"story": [
			{"title": "哑钟", "text": "铎音铸了一口钟，敲不响。她盯着它看了一整天，一句话不说。",
			 "choices": [{"label": "陪她把钟砸了重铸", "fx": {"aff": 15, "say": "第二口钟一响，半个城都抬起了头。"}}, {"label": "劝她算了", "fx": {"aff": 3}}]},
			{"title": "西边的铜", "text": "铎音想试试西边铜鹤矶的赤铜，说那边的铜声音更亮，只是贵。",
			 "choices": [{"label": "送她一船赤铜（1,500 金）", "fx": {"gold": -1500, "aff": 15, "say": "她用那批铜铸了一口送你的船钟。"}}, {"label": "让她自己攒", "fx": {"aff": 5}}]},
			{"title": "千钟齐鸣", "text": "整点钟响，铎音说城里一千口钟里有三十口是她铸的。「我想让西边也听见。」",
			 "choices": [{"label": "「我的船替你带过去。」", "fx": {"aff": 20, "spec_up": true, "say": "从此你的旗舰每到一港，先响一声金铎城的钟。"}}, {"label": "举杯", "fx": {"aff": 12, "spec_up": true}}]},
		]},
	"lusheng": {"name": "芦生", "title": "青芦港的酒坊少年", "style": "好奇心重，什么都想尝一口。",
		"abil": {"sail": 2, "trade": 5, "fight": 1, "charm": 5}, "spec": "brewer", "spec_name": "东货行家",
		"spec_desc": "东云域出产的加工品（霞果酒、铜件、琉璃、熏鱼、灯油）在西边卖价 +6%。", "port": "qinglu", "where": "tavern", "cond": {}, "fee": 800, "wage": 150,
		"story": [
			{"title": "第一口西酒", "text": "芦生尝了一口西边的酒，皱着眉说太甜。然后又喝了三碗。",
			 "choices": [{"label": "带他去千旗市见世面", "fx": {"aff": 15, "say": "他在千旗市的酒楼里喝到了天亮。"}}, {"label": "笑他", "fx": {"aff": 5}}]},
			{"title": "酒坊的债", "text": "芦生家的酒坊欠了焦岩堡的黑市一笔钱，对方说下个月不还就烧坊。",
			 "choices": [{"label": "替他还清（1,000 金）", "fx": {"gold": -1000, "aff": 15, "say": "酒坊保住了，芦生把最老的一坛酒开给你。"}}, {"label": "让他想办法", "fx": {"aff": 2}}]},
			{"title": "两边的味道", "text": "芦生说他想酿一种西边人也爱喝的酒：「东边的芦，西边的霞果。」",
			 "choices": [{"label": "出资办一间酒坊（2,000 金）", "fx": {"gold": -2000, "aff": 20, "spec_up": true, "say": "那酒后来成了千旗市最贵的一种。"}}, {"label": "答应以后", "fx": {"aff": 10, "spec_up": true}}]},
		]},
}
const IDS := ["xiaoman", "luqing", "qian", "aman", "shen", "cen", "moyu", "ning", "feng", "sang", "helan", "ling", "duoyin", "lusheng"]

## Two companions who both sail with you get a scene together once their affinity is high enough
## (round 13). fx keys: aff_a / aff_b (the pair), gold, rep, intel, say.
const PAIR_AFF := 40
const PAIRS := [
	{"a": "aman", "b": "shen", "title": "炮与剑", "text": "阿蛮说剑在飞艇上就是根烧火棍，沈白鹭说粗人才靠炮。两人在甲板上摆开了架势，全船都来看。",
	 "choices": [{"label": "让他们比一场", "fx": {"aff_a": 12, "aff_b": 12, "say": "三回合不分胜负。阿蛮把酒碗递过去，沈白鹭接了。"}}, {"label": "各罚一天饭", "fx": {"aff_a": 3, "aff_b": 3}}]},
	{"a": "qian", "b": "xiaoman", "title": "一本账", "text": "钱不让发现小满偷偷在学他记账，账本上密密麻麻全是错的。他骂了半天，又坐下来一行一行地教。",
	 "choices": [{"label": "让小满正式跟他学徒", "fx": {"aff_a": 10, "aff_b": 14, "say": "半年后，小满记的账钱不让挑不出一处错。"}}, {"label": "别耽误两人正事", "fx": {"aff_a": 4, "aff_b": 4}}]},
	{"a": "luqing", "b": "moyu", "title": "两张海图", "text": "陆青和莫语趴在同一张海图上，一个用铅笔，一个用手指，谁也不说话，却一笔一笔画得飞快。",
	 "choices": [{"label": "让她们合画一张新图", "fx": {"aff_a": 12, "aff_b": 12, "intel": true, "say": "新图把所有港口的气流都标了出来，各港行情也一并捎了回来。"}}, {"label": "各画各的", "fx": {"aff_a": 4, "aff_b": 4}}]},
	{"a": "feng", "b": "qian", "title": "两本账", "text": "风九娘提议做一本给港务看的账、一本自己看的账，能省一大笔税。钱不让把算盘一摔：「我不做假账。」",
	 "choices": [{"label": "站钱不让：账只有一本", "fx": {"aff_a": -6, "aff_b": 16, "rep": 40, "say": "港务官后来逢人就说你的商会账目最干净。"}}, {"label": "站风九娘：省下来的是真金", "fx": {"aff_a": 16, "aff_b": -6, "gold": 2500, "say": "钱不让一个月没跟你说话，但账还是他记。"}}]},
	{"a": "cen", "b": "sang", "title": "船头的炮", "text": "老岑说船头装重炮会压坏龙骨，桑铁手说他的炮不重。两个老匠人在船坞里吵到半夜。",
	 "choices": [{"label": "出钱让他们造个样子试试（1,500 金）", "fx": {"gold": -1500, "aff_a": 14, "aff_b": 14, "say": "新炮座轻了三成。两人谁也不承认对方有理，却一起喝到了天亮。"}}, {"label": "让他们各退一步", "fx": {"aff_a": 5, "aff_b": 5}}]},
	{"a": "ning", "b": "duoyin", "title": "钟的学问", "text": "宁朝雨想把铎音的铸钟术写进技艺总录，铎音说手艺写不进书里，除非他自己先砸三天炉。",
	 "choices": [{"label": "让宁朝雨去砸三天炉", "fx": {"aff_a": 12, "aff_b": 12, "say": "三天后宁朝雨满手是泡，总录里多了十二页。"}}, {"label": "劝铎音通融", "fx": {"aff_a": 6, "aff_b": 2}}]},
	{"a": "lusheng", "b": "xiaoman", "title": "半坛酒", "text": "芦生和小满偷开了货舱里一坛霞果酒，被水手长抓了个正着。两人互相推说是对方的主意。",
	 "choices": [{"label": "一笑了之，酒钱从工钱里扣", "fx": {"aff_a": 10, "aff_b": 10, "say": "两人从此成了死党，再偷酒时也更小心了。"}}, {"label": "罚他们刷一个月甲板", "fx": {"aff_a": 3, "aff_b": 3, "say": "甲板从没这么亮过。"}}]},
	{"a": "helan", "b": "lusheng", "title": "东边的味道", "text": "赫兰尝了芦生带的东边米酒，愣了很久，然后说了一句家乡话。芦生听不懂，却给他满上了。",
	 "choices": [{"label": "让芦生照赫兰说的方子酿一坛", "fx": {"aff_a": 14, "aff_b": 12, "say": "那坛酒酿成那天，赫兰一个人在船尾坐了一夜。"}}, {"label": "由他们去", "fx": {"aff_a": 5, "aff_b": 5}}]},
	{"a": "ling", "b": "luqing", "title": "鲸与雾", "text": "雾最浓的夜里，灵对着云海低声说话，陆青跟着她的声音校正航向。天亮时，船正好停在港外。",
	 "choices": [{"label": "「以后夜航就交给你们两个。」", "fx": {"aff_a": 12, "aff_b": 12, "say": "从此船上流传一句话：灵听鲸，陆青听灵。"}}, {"label": "点头致意", "fx": {"aff_a": 5, "aff_b": 5}}]},
	{"a": "aman", "b": "feng", "title": "旧旗", "text": "风九娘认出了阿蛮背上的刺青，那是她母亲帮派的旗。两人隔着桌子谁也没先开口。",
	 "choices": [{"label": "把话说开", "fx": {"aff_a": 12, "aff_b": 12, "say": "「黑帆是我杀的。」「我知道。谢谢。」"}}, {"label": "回避这件事", "fx": {"aff_a": 2, "aff_b": 2}}]},
]

## A personal errand each companion asks of you once their affinity is high enough (round 17):
## carry qty of good to port within days. Reward gold + rep + affinity; failing costs affinity.
const QUEST_AFF := 60
const QUEST_FAIL_AFF := 10
const QUEST_DONE_AFF := 20
const QUESTS := {
	"xiaoman": {"title": "家里的渔船", "good": "timber", "qty": 20, "port": "muxia", "days": 60, "gold": 1500, "rep": 20,
		"text": "小满红着脸说，家里的渔船要换龙骨，母亲托他找二十根云杉木。「我自己攒不齐……少主能顺路捎去暮霞港吗？」",
		"done": "小满的母亲在码头上等着，接过木头时抹了抹眼睛。", "fail": "小满说没关系，船先凑合用。他一整天没说话。"},
	"luqing": {"title": "父亲的旧债", "good": "steel", "qty": 30, "port": "fengyue", "days": 90, "gold": 3500, "rep": 40,
		"text": "陆青摊开一张旧单据：父亲当年欠风月坞锻炉三十件精钢没能交付。「我想替他把这笔货送到。」",
		"done": "锻炉的老掌柜把旧单据撕了，说这笔账清了。陆青对着炉火站了很久。", "fail": "陆青把单据收回怀里：「下次。」"},
	"qian": {"title": "旧匾", "good": "silk", "qty": 40, "port": "qianqi", "days": 90, "gold": 4500, "rep": 40,
		"text": "钱不让想把老家商号的旧匾挂回千旗市，可匾下得先有四十匹丝云绸撑门面。「我出钱，您出船。」",
		"done": "旧匾挂上的那天，千旗市半条街的掌柜都来贺。钱不让多付了一份运费。", "fail": "钱不让说匾不急，账先算清楚。"},
	"aman": {"title": "老兄弟的炮", "good": "brass", "qty": 20, "port": "chishi", "days": 90, "gold": 3000, "rep": 40,
		"text": "阿蛮的一个老兄弟在赤石矶开了铸炮铺，缺二十件铜件。「他当年替我挡过一刀。」",
		"done": "铸炮铺的老板把一门小炮当谢礼搬上了船。阿蛮笑得像个孩子。", "fail": "阿蛮说老兄弟不会怪他，只是从此不提这件事。"},
	"shen": {"title": "信义榜", "good": "canvas", "qty": 30, "port": "fengyue", "days": 90, "gold": 3000, "rep": 60,
		"text": "沈家三十年前欠风月坞三十匹风帆布。沈白鹭说，要把名字重新挂回信义榜，先得把这笔货送到。",
		"done": "信义榜上重新写上了沈家的名字。沈白鹭对着榜深深一揖。", "fail": "沈白鹭说名誉不急在一时，却擦了一夜的剑。"},
	"cen": {"title": "好木料", "good": "timber", "qty": 60, "port": "tonghe", "days": 90, "gold": 2500, "rep": 30,
		"text": "老岑看中了一批云杉木，要六十根运回铜鹤矶的船坞。「这辈子就想用一次好料。」",
		"done": "老岑把木料一根根敲过去，说有三根是真正的好料。他很满意。", "fail": "老岑哼了一声，继续用旧木头。"},
	"moyu": {"title": "画纸", "good": "fiber", "qty": 40, "port": "chishi", "days": 60, "gold": 2000, "rep": 30,
		"text": "莫语画了一张画：四十捆云麻送到赤石矶的纸坊，换一叠能画海图的好纸。",
		"done": "纸坊送来一叠雪白的纸。莫语当晚画了你的旗舰。", "fail": "莫语在旧纸背面继续画，什么也没说。"},
	"ning": {"title": "学堂的书", "good": "glass", "qty": 20, "port": "cuijing", "days": 90, "gold": 3000, "rep": 50,
		"text": "宁朝雨的学堂缺二十件琉璃做窗，孩子们冬天冷。「我知道这不是生意。」",
		"done": "学堂的窗亮了。宁朝雨说第一堂课讲的是云海的航线。", "fail": "宁朝雨用油纸糊了窗，没有再提。"},
	"feng": {"title": "夜市的货", "good": "pearl", "qty": 30, "port": "hongxiao", "days": 60, "gold": 5000, "rep": 20,
		"text": "风九娘压低声音：红绡渡的夜市要三十颗雾珍珠，价钱好得不像话。「别问买家是谁。」",
		"done": "珍珠在夜市里转了一圈，钱袋回来时沉了一倍。", "fail": "风九娘耸耸肩：「买家不等人。」"},
	"sang": {"title": "好钢", "good": "steel", "qty": 40, "port": "fengyue", "days": 90, "gold": 4000, "rep": 40,
		"text": "桑铁手要四十件精钢，送到风月坞的炉房。他只说了四个字：「铸那门炮。」",
		"done": "炉房里响了三天三夜。第四天，一门漆黑的炮抬了出来。", "fail": "桑铁手盯着空炉子看了一夜。"},
	"helan": {"title": "家乡的味道", "good": "wine", "qty": 20, "port": "qinglu", "days": 90, "gold": 3000, "rep": 30,
		"text": "赫兰比划着说，青芦港有个同乡，想喝一口西边的霞果酒。二十坛。",
		"done": "两个异乡人在码头上喝到天亮，用你听不懂的话唱歌。", "fail": "赫兰说同乡已经走了。"},
	"ling": {"title": "鲸群的药", "good": "herb", "qty": 40, "port": "xiajing", "days": 60, "gold": 2500, "rep": 60,
		"text": "灵说霞鲸台外海有一头病鲸，要四十捆灵参。「鲸记得谁帮过它们。」",
		"done": "病鲸随船游了一程，整支船队都看见了。", "fail": "灵望着海面说，鲸走了。"},
	"duoyin": {"title": "西边的铜", "good": "copper", "qty": 60, "port": "jinduo", "days": 90, "gold": 3500, "rep": 40,
		"text": "铎音要六十件西边的赤铜运回金铎城：「我要铸一口西边也听得见的钟。」",
		"done": "新钟敲响那天，金铎城的钟楼齐鸣了一刻钟。", "fail": "铎音说铜可以再等，钟不会跑。"},
	"lusheng": {"title": "霞果", "good": "fruit", "qty": 50, "port": "qinglu", "days": 60, "gold": 2000, "rep": 30,
		"text": "芦生想用西边的甜霞果酿一坛新酒，要五十筐送回青芦港的酒坊。「酿好了第一坛给少主。」",
		"done": "第一坛新酒开封，酒坊门口排了半条街。", "fail": "芦生说霞果烂在路上也常有，明年再酿。"},
}

## Three companions who sail together, once each likes you enough (round 17).
const TRIO_AFF := 50
const TRIOS := [
	{"who": ["aman", "shen", "sang"], "title": "三件兵器", "text": "阿蛮的炮、沈白鹭的剑、桑铁手的炉。三个人在甲板上争了一夜哪样才算兵器，最后一起把炮擦得发亮。",
	 "choices": [{"label": "「都是商会的兵器。」", "fx": {"aff_all": 10, "say": "三个人从此轮流值夜，船上再没丢过一件货。"}}, {"label": "让他们早点睡", "fx": {"aff_all": 4}}]},
	{"who": ["xiaoman", "lusheng", "qian"], "title": "两个少年一本账", "text": "小满和芦生合伙在港口卖酒，账记得乱七八糟。钱不让看了一眼，拿起算盘坐下了。",
	 "choices": [{"label": "让钱不让带他们俩", "fx": {"aff_all": 10, "gold": 800, "say": "三个人的小买卖月底居然赚了八百金，交到了商会账上。"}}, {"label": "叫他们别胡闹", "fx": {"aff_all": 3}}]},
	{"who": ["luqing", "moyu", "ling"], "title": "三张海图", "text": "陆青画气流，莫语画岛，灵在图上点出鲸群走的路。三张图叠在一起，云海第一次显得没那么大。",
	 "choices": [{"label": "把三张图合成商会的总图", "fx": {"aff_all": 10, "intel": true, "say": "总图挂在旗舰舱壁上，各港行情一目了然。"}}, {"label": "各自收好", "fx": {"aff_all": 4}}]},
	{"who": ["feng", "helan", "duoyin"], "title": "三种口音", "text": "风九娘的红绡渡话、赫兰的家乡话、铎音的金铎城腔，三个人用三种口音谈同一笔生意，码头上围了一圈人听。",
	 "choices": [{"label": "让他们三个去谈下一笔", "fx": {"aff_all": 10, "rep": 40, "say": "那笔生意成了，码头上的人记住了你的商会。"}}, {"label": "笑着听完", "fx": {"aff_all": 4}}]},
]

## Each companion's moment at the lantern festival (round 17).
const FESTIVAL := {
	"xiaoman": "小满在灯谜摊前连猜十个，赢回一盏兔子灯，非要挂在旗舰船头。",
	"luqing": "陆青在灯河边放了一盏灯，灯上写着父亲的名字。",
	"qian": "钱不让把灯节的开销一笔一笔记下来，然后悄悄多付了舞狮队的赏钱。",
	"aman": "阿蛮跟码头的力夫比赛喝酒，赢了，然后睡在了灯笼底下。",
	"shen": "沈白鹭在灯下舞了一套剑，围观的人安静得能听见灯芯响。",
	"cen": "老岑嫌花灯做得粗，自己扎了一盏飞艇灯，比谁的都亮。",
	"moyu": "莫语画了整条灯街，画里每一盏灯都有人在笑。",
	"ning": "宁朝雨在灯下给孩子们讲云海的来历，讲到灯都灭了。",
	"feng": "风九娘在灯市上只逛不买，回来时手里却多了三样东西。",
	"sang": "桑铁手用铁手托着一盏灯站了一夜，谁也没敢问为什么。",
	"helan": "赫兰第一次见灯节，站在街口半天没动，然后买了整条街的灯。",
	"ling": "灯亮起来的时候，有一群云鲸从城上空游过。灵说它们也来看灯。",
	"duoyin": "铎音敲响了灯节的第一声钟，半座城都抬头看她。",
	"lusheng": "芦生把新酿的酒摆在灯街口，一个时辰就卖光了。",
}

## What companions say when you bump into them in town.
const BANTER := {
	"xiaoman": ["少主！这城的掌柜今天心情好，能多磨一点价。", "我把这城的消息都打听过了，没大事。"],
	"luqing": ["这里的雾比霞鲸台薄。", "父亲的航图上也标过这座港。"],
	"qian": ["这城的税比上个月又涨了半成。", "别乱花钱，我都记着呢。"],
	"aman": ["这里的酒不行，太淡。", "刚才有个人盯着咱们的船看，我盯回去了。"],
	"shen": ["这城的信义榜上没有一家商会的名字。", "剑该磨了。"],
	"cen": ["这里的船坞用的木头不行。", "我看了咱们的船，龙骨还结实。"],
	"moyu": ["（她递给你一张刚画好的街景速写。）", "（她指了指天边的云，比了个「风」的手势。）"],
	"ning": ["这城的学堂空着。", "行会的墙上有几张图纸很有意思。"],
	"feng": ["这里的黑市在码头第三条巷子，别去。", "有人想找我带货，我回了。"],
	"sang": ["这城的铁不好。", "……（他点了点头。）"],
	"helan": ["这里……像我家乡的港。", "多少钱？（他指着一家铺子笑。）"],
	"ling": ["鲸群从这座岛底下过。", "灯塔的方向在那边。"],
	"duoyin": ["这城的钟敲得不准。", "我想在这里也铸一口钟。"],
	"lusheng": ["这里的酒楼我去尝过了，还行。", "少主，那边卖的是什么？我想尝一口。"],
}


static func name_of(cid: String) -> String:
	return CHARS[cid]["name"]


static func cond_text(cid: String) -> String:
	var c: Dictionary = CHARS[cid]["cond"]
	var parts := []
	if c.has("story"):
		parts.append("主线第 %d 章之后" % int(c["story"]))
	if c.has("rep"):
		parts.append("名声「%s」" % GameData.REP_NAMES[int(c["rep"]) - 1])
	if c.has("friend"):
		parts.append("本城友好度「%s」" % GameData.FRIEND_NAMES[int(c["friend"])])
	if c.has("wins"):
		parts.append("打赢过云盗")
	if c.has("visited"):
		parts.append("到过全部 %d 座港" % int(c["visited"]))
	if c.has("craft_bp"):
		parts.append("持有工艺图纸")
	if c.has("workshops"):
		parts.append("拥有 %d 座工坊" % int(c["workshops"]))
	return "、".join(parts) if not parts.is_empty() else "无条件"
