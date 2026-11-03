# 云海商盟 美术需求表（第 10 轮 · 外包出图用）

给 Kimi / promptgather.io 出图的完整清单。每一项写明：文件名、尺寸、内容、英文提示词。
生成后把图放进仓库根目录的 `art-in/` 对应子目录（文件名照抄），我负责切图、导入和接进游戏。

## 0. 怎么用这份表

1. 每条提示词前面都要先贴**通用前缀**（见下），再接该条的内容句。前缀保证全部素材是同一套"纸艺国风"。
2. 图集类（atlas）要求**透明背景、固定行列、每格一个完整物体、互不重叠**。生成后如果行列对不上，重出一张，不要手裁。
3. 单幅插图统一 **16:9，至少 1536×864**；肖像统一 **1:1，1024×1024**。
4. 图里**不能出现文字、数字、标志、水印**。
5. 优先级：**P1** 立刻能接进游戏并明显变好看；**P2** 第二批；**P3** 有余力再做。

### 通用前缀（每条都贴）

```
Art direction for CLOUD SEA MERCHANT ALLIANCE: an exquisite handmade THREE-DIMENSIONAL PAPER DIORAMA,
layered cut watercolor cardstock, visible creamy cut edges and paper fibers, folded tabs, stacked relief,
soft physical contact shadows, subtle ink-wash color within matte colored paper. Elegant Chinese
steampunk sky-trading world: floating islands, airships with silk balloons and brass fittings, cloud seas.
Palette: jade teal #2F6F6A, warm parchment #F3E9D2, ink blue #1F3A48, muted brass #B08A3E, terracotta
#B5583C, cloud white #E7EEF0. Gentle upper-left light. NOT low-poly, NOT plastic, NOT photoreal, no glossy
CGI, no anime gloss. No writing, numbers, logos, watermarks.
```

### 图集后缀（atlas 类加在最后）

```
Sprite atlas, exactly {COLS} columns by {ROWS} rows, {N} separate whole objects, TRUE transparent
background, generous gutters, no overlap, same scale and same light direction for every cell.
Read left to right, top to bottom: {OBJECT LIST}.
```

---

## 1. 人物立绘 · P1（15 张，1024×1024，`art-in/portraits/<id>.png`）

四分之三正面胸像，视线略向观者，纸艺剪影感，背景是单色纸底加一点云纹。同一套光向和比例，方便并排放在招募卡和伙伴面板里。

通用句：`Three-quarter bust portrait of a paper-diorama character, layered cardstock face and clothes, plain parchment backdrop with a faint cloud pattern, consistent framing: head and shoulders fill 70% of the frame.`

### 三位商会少主（开局可选的主角）

| id | 人物 | 形象要点 | 提示词内容句 |
|---|---|---|---|
| `hero_lamp` | 霍照野 · 灯油行会 | 20 多岁青年，千旗市富商之子，赭红绸袍、腰间铜灯挂饰，自信温和的笑 | young merchant heir in terracotta silk robe with a small brass lantern charm at the belt, warm confident smile, short dark hair tied back |
| `hero_iron` | 韦朔 · 铁誓舰团 | 30 岁左右，船坞世家，深蓝短打、肩甲、手臂有缆绳老茧，眼神硬朗 | shipyard clan captain in deep blue short coat with one brass shoulder plate, weathered hands, steady hard gaze, cropped hair |
| `hero_tower` | 殷望舒 · 白塔议士 | 女性，30 岁，灰白议士长袍、玉簪，手执卷轴，冷静沉稳 | calm woman scholar-councillor in grey-white long robe with a jade hairpin, holding a rolled chart, composed expression |

### 十二位伙伴

| id | 人物 | 形象要点 | 提示词内容句 |
|---|---|---|---|
| `xiaoman` | 小满 · 酒馆跑堂少年 | 14–15 岁，麻布围裙、肩上搭布巾，机灵大眼，咧嘴笑 | bright-eyed teenage tavern boy in a linen apron with a cloth over one shoulder, cheeky grin, messy hair |
| `luqing` | 陆青 · 霞鲸台采珠女 | 20 岁女性，深青采珠服、腰系珠袋，发间一颗雾珍珠，冷静寡言 | quiet young pearl-diver woman in dark teal diving garb with a pearl pouch at the waist, a single misty pearl in her hair, reserved expression |
| `qian` | 钱不让 · 账房先生 | 40 多岁瘦小男子，圆框眼镜、算盘、墨点的袖口，精明嘴碎 | thin middle-aged accountant with round brass spectacles, an abacus tucked under his arm, ink-stained cuffs, shrewd pursed lips |
| `aman` | 阿蛮 · 云盗出身的炮手 | 30 岁壮汉，光头、刀疤、裸臂、黑帆帮旧纹身，豪爽 | burly bald ex-pirate gunner with a scar across one brow, bare tattooed arms, a red sash, loud hearty expression |
| `shen` | 沈白鹭 · 落魄世家剑客 | 25 岁清瘦男子，洗旧的白衣、长剑、下巴微扬的骄傲 | lean proud swordsman in faded white robes with a long sword, chin slightly raised, aristocratic bearing |
| `cen` | 老岑 · 退役船匠 | 60 岁老人，木屑满身的皮围裙、墨斗、烟斗，古怪皱眉 | grumpy old shipwright with a sawdust-covered leather apron, a carpenter's ink line tool and a pipe, deep frown lines |
| `moyu` | 莫语 · 不说话的测绘师 | 20 岁女性，宽檐帽、画板与炭笔、袖口沾着颜料，安静的眼 | silent young woman cartographer in a wide-brimmed hat holding a sketchboard and charcoal, paint on her sleeves, gentle watchful eyes |
| `ning` | 宁朝雨 · 白塔出走的学者 | 28 岁男子，半旧学袍、怀抱手稿、眼里有理想 | idealistic young scholar in a worn academic robe clutching a bundle of manuscripts, earnest bright eyes |
| `feng` | 风九娘 · 走私女商人 | 35 岁女性，绛紫斗篷、金耳环、似笑非笑 | sly elegant smuggler woman in a plum-purple cloak with gold earrings, a knowing half smile |
| `sang` | 桑铁手 · 失去一只手的铸炮匠 | 45 岁男子，右手是黄铜机械手，炉火熏黑的脸，沉默 | silent cannon-founder with a brass mechanical right hand, soot-darkened face, heavy leather apron |
| `helan` | 赫兰 · 东云域来的异乡商人 | 30 岁男子，异域剪裁的铜扣长袍、缠头巾、带铜铃的项链 | foreign merchant from the east in a bronze-buttoned long robe of unfamiliar cut, a wrapped headcloth, a necklace of small bronze bells |
| `ling` | 灵 · 云鲸的使者少女 | 16 岁少女，云白轻纱、发间鲸骨饰、赤足、神秘微光 | ethereal girl in cloud-white gauze with a whalebone hair ornament, barefoot, faint glow at the edges, serene mysterious smile |

### 表情差分 · P2（15 张图集，每张 2×2，`art-in/portraits/<id>_faces.png`）

同一人物四个表情：平静 / 高兴 / 生气 / 伤心。内容句照上表，后面加：`Four expressions of the SAME character, identical costume and framing: calm, happy, angry, sad.` + 图集后缀（2 列 2 行，4 格）。

---

## 2. 行走图（城镇里走动的小人）

小人是 30° 俯视、头身比 1:2 的纸片人，4 方向 × 4 帧。图像 AI 很难保证逐帧对齐，所以先做 3 位主角试一张，能用再做其余。

| 文件 | 优先级 | 尺寸 | 内容 |
|---|---|---|---|
| `art-in/walk/hero_lamp.png` `hero_iron.png` `hero_tower.png` | P2 | 4 列 × 4 行，每格 128×192 | 行：面向下 / 左 / 右 / 上；列：站立、左脚、站立、右脚 |
| `art-in/walk/townsfolk.png` | P2 | 6 列 × 1 行，每格 128×192 | 6 种路人（面向下，站立）：挑担小贩、渔妇、工匠、绸商、孩童、老者 |
| `art-in/walk/<伙伴 id>.png` | P3 | 同主角 | 12 位伙伴 |

提示词内容句（主角举例）：`Tiny chibi paper-cutout figure of the young merchant heir in terracotta robe (same character as the portrait), top-down 30-degree view, 1:2 head-to-body, walking cycle.` + 图集后缀（4 列 4 行，16 格：`row 1 facing down: stand, left step, stand, right step; row 2 facing left …; row 3 facing right …; row 4 facing up …`）。

---

## 3. 城镇建筑 · P2（`art-in/buildings/`）

城镇画面是程序拼的街景，需要的是**建筑单件**，不是整幅城。

| 文件 | 规格 | 内容 |
|---|---|---|
| `west_buildings.png` | 4 列 × 3 行，每格 512×512，透明 | 霞市（西边）风格 12 件：交易所（大屋顶市场）、船坞（吊着飞艇骨架）、酒馆（挂红灯笼）、工匠行会（齿轮招牌）、城主府（高台楼阁）、商馆仓库（堆货的货栈）、灯塔工地（脚手架）、工坊（冒烟的作坊）、民居甲、民居乙、码头栈桥、市集摊棚 |
| `east_buildings.png` | 同上 | 东云域风格 12 件：同样 12 种功能，但建筑语言不同——铜钟塔楼、白砂窑、黑岩堡墙、芦苇屋顶、常明灯笼柱 |
| `west_props.png` | 6 列 × 2 行，每格 256×256 | 街道小物 12 件：货箱堆、水缸、灯柱、旗杆、晾布架、石狮、花坛、木桥、井、鱼摊、炭炉、告示牌 |

内容句（西）：`Isometric 30-degree elevated view, twelve separate paper-diorama buildings of a Chinese sky-port town, each on its own small paper base, roofs of jade-teal tile and terracotta, brass details.`
内容句（东）：`…twelve buildings of a distant eastern cloud-sea culture: bronze bell towers, white sand kilns, black volcanic stone walls, reed-thatched roofs, ever-burning lantern pillars.`

---

## 4. 内景 · P2（6 张，1536×864，`art-in/interiors/<kind>.png`）

进门后的背景图，画面下方 1/3 留空给界面。统一斜 30° 俯视、暖灯光。

| 文件 | 内容句 |
|---|---|
| `trade.png` | interior of a bustling sky-port exchange hall: long counters with goods samples, hanging price boards without writing, brass scales, merchants in paper-cut silhouettes |
| `yard.png` | interior of an airship yard: a half-built airship hull on scaffolds, silk balloon being sewn, brass gears, shipwrights |
| `tavern.png` | interior of a warm tavern: red lanterns, long tables, a storyteller, a wall of pinned bounty notes (blank), steaming bowls |
| `guild.png` | interior of a craftsmen's guild: drafting tables with blueprint scrolls (no text), models of workshops, a great brass orrery |
| `hall.png` | interior of a city lord's hall: high dais, jade screens, banners, petitioners waiting |
| `post.png` | interior of a merchant house warehouse: tall shelves of crates and jars, ledgers (blank), a courtyard with an airship mooring |

---

## 5. 空战 · P1（`art-in/battle/`）

回合制六角格战场。六角格是**尖顶朝上**的正六边形（pointy-top）。

| 文件 | 规格 | 内容 |
|---|---|---|
| `hex_tiles.png` | 3 列 × 2 行，每格 256×256，透明 | 6 块六角地形（pointy-top hexagon，边缘精确）：晴空云面、雷云（紫灰闪电）、浓雾（半透明白）、上升气流（旋转的淡金气流）、浮岩（褐色悬浮岩块）、备用（薄云） |
| `board_bg.png` | 1536×864 | 俯视的云海战场背景，淡色、低对比，上面要能铺六角格 |
| `units_top.png` | 3 列 × 3 行，每格 256×256，透明 | 9 艘飞艇的**正俯视**图（船头朝上）：测绘艇、货艇、炮舰、盖伦飞艇、铁甲舰、云盗快船、云盗掠船、云盗主舰、拾遗号残舰 |
| `fx.png` | 4 列 × 2 行，每格 256×256，透明 | 8 个特效：炮火闪光、炮弹命中的纸屑爆开、接舷的绳索与跳板、修补的木板与锤、防御的盾形云、士气崩溃的碎旗、烟幕、火攻的火舌 |

内容句（units）：`Nine airships seen directly from above, bows pointing up, silk balloons seen from the top with brass frames, hulls as layered paper; pirate ships have black sails and ragged edges.`

---

## 6. 海图与东云域 · P1（`art-in/map/`）

| 文件 | 规格 | 内容 |
|---|---|---|
| `east_islands.png` | 5 列 × 1 行，每格 512×512，透明 | 东云域 5 座浮岛（30° 俯视，每座带城）：青芦港（芦荡、矮屋、酒坊）、金铎城（铜钟塔林立、城墙）、白砂洲（白色砂洲、圆窑、玻璃塔）、焦岩堡（黑色岩堡、黑帆船桅）、雾隐泊（半藏在雾里、无数灯笼） |
| `markers.png` | 4 列 × 1 行，每格 128×128，透明 | 海图记号：风隙（两道云崖的缝）、遗迹（青铜钟楼顶）、漂流物（倾斜的小船）、问号纸牌 |
| `paper_sea_east.png` | 1536×864，可无缝平铺更好 | 东云域的海图纸底：比西边更冷的青灰色纸、淡淡的异文边饰（不要真文字） |
| `decor.png` | 4 列 × 1 行，每格 256×256，透明 | 海图装饰：云鲸、浮空的断桥、风车浮岛、海图罗盘花 |

---

## 7. 事件与发现插图 · P1（16:9，1536×864，`art-in/events/`）

弹窗顶部的插图。画面留一点空白给纸张边缘。

| 文件 | 内容句 |
|---|---|
| `fengxi.png` | an airship squeezing through a narrow gap between two towering cloud cliffs, wind streaks, a brighter unknown sea beyond |
| `ruin_bell.png` | half of a bronze bell tower rising from the clouds, the great bell swinging in the wind, an airship anchored beside it |
| `ruin_garden.png` | a ruined hanging garden floating on clouds, incense trees grown wild, a stone stele without writing |
| `ruin_fort.png` | a half-collapsed cliff fortress with cannon ports still facing east, paper explorers with lanterns |
| `ruin_temple.png` | a temple built from the skeleton of a whole cloud whale, mist and faint light inside, an old keeper |
| `wreck_cargo.png` | a drifting cargo airship with no crew turning slowly in the clouds, a merchant ship approaching with grapples |
| `wreck_gunboat.png` | a gunboat stranded on a floating rock, hull full of holes, cannons intact, shipwrights prying it loose |
| `ambush.png` | pirates bursting out of a cargo hold, black sails unfurling behind a wreck |
| `city_qinglu.png` | first sight of a reed-marsh port at dawn, low houses, wine kilns smoking, people pointing at the strange western airship |
| `city_jinduo.png` | a walled city hung with a thousand bronze bells, all ringing at once, bronze light |
| `city_baisha.png` | white sand bars shining above the clouds, round kilns, glass towers catching light |
| `city_jiaoyan.png` | a black volcanic fortress port crowded with black-sailed ships, a lawless market |
| `city_wuyin.png` | a city hidden in deep fog lit by countless lanterns at noon, pearl divers' boats |
| `expedition.png` | an expedition of three small airships setting out east into a wall of fog, the guild master waving them off |

### 伙伴剧情插图 · P3（12 张，`art-in/events/char_<id>.png`）

每位伙伴一张关键场景（第 3 章）：小满翻小册子、陆青雾中听铃、钱不让挂旧匾、阿蛮扔旧旗、沈白鹭信义榜前、老岑刻船坞木料、莫语第一次开口（暴雨夜）、宁朝雨烧信、风九娘夜市、桑铁手铸炮、赫兰画风隙、灵与鲸群。

---

## 8. 货物图标 · P1（`art-in/goods/goods_v2.png`）

现在 29 种货物散在两套老图集里，比例和光向不统一。重出一张统一的：**6 列 × 5 行，每格 256×256，透明**，30 格（最后一格空）。顺序：

云麦、云鱼、云麻、甜霞果、霞纹石、云杉木、玄铁矿、云蚕茧、赤铜矿、鲸脂、灵参、香木、雾珍珠、风帆布、丝云绸、熏鱼、霞果酒、铜件、琉璃、精钢、灯油、飞艇帆具、星盘、云锦、香膏、霞露、琉璃灯、云炮、珍馐宴盒、（空）

内容句：`Thirty trade-good icons as small paper-diorama objects on tiny paper bases, thick readable silhouettes legible at 48px: wheat sheaf, cloud fish, hemp bundle, pink fruit, red patterned stone, timber logs, dark iron ore, silk cocoons, red copper ore, whale fat jar, ginseng root, incense wood, misty pearl, sail canvas bolt, silk cloth bolt, smoked fish, fruit wine jar, brass fittings, glass vessel, steel ingots, oil lamp jar, airship rigging, brass astrolabe, brocade roll, balm jar, elixir vial, glass lantern, small cloud cannon, feast box, empty.`

---

## 9. 交付清单（按优先级）

**P1（先做这些，约 45 张）**：15 立绘 · 货物图集 1 · 东云域岛屿 1 · 海图记号 1 · 东云域纸底 1 · 六角地形 1 · 战场背景 1 · 俯视飞艇 1 · 战斗特效 1 · 事件插图 14。

**P2**：表情差分 15 · 主角行走图 3 · 路人 1 · 建筑两套 2 · 街道小物 1 · 内景 6 · 海图装饰 1。

**P3**：伙伴行走图 12 · 伙伴剧情插图 12。

放进 `art-in/` 后告诉我一声，我来切图导入。先到的先接。
