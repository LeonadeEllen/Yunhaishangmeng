# 云海商盟 美术规范

## 风格一句话

**手工纸艺立体模型**：层叠切割的水彩卡纸，看得见奶白色切边和纸纤维，柔和的接触阴影，东方蒸汽朋克的浮空商贸世界。

## 色板

| 用途 | 颜色 | 色值 |
|---|---|---|
| 主色 · 玉青 | 港口屋顶、强调按钮 | `#2F6F6A` |
| 纸底 · 暖羊皮 | 面板底色 | `#F3E9D2` |
| 墨蓝 | 顶栏、文字 | `#1F3A48` |
| 黄铜 | 金币、高亮、边框 | `#B08A3E` |
| 赭陶 | 警告、亏损 | `#B5583C` |
| 云白 | 云海、留白 | `#E7EEF0` |
| 涨 | 价格上涨 / 利润 | `#3E8E5A` |
| 跌 | 价格下跌 / 亏损 | `#B5583C` |

## 构图与光

- 30° 俯视的等距/正交视角（建筑、岛屿、飞艇）；肖像为四分之三正面胸像。
- 统一左上方柔光，阴影落在右下。
- 图标：厚实、轮廓清晰，缩到 48px 仍可辨认。

## 禁止

低多边形、塑料玩具感、写实金属或木头、高光 CGI、图中出现文字/数字/标志/水印、模仿任何现有作品的角色或标志。

## 出图提示词模板（给图像 AI）

```
Use case: game sprite atlas. Art direction for CLOUD SEA MERCHANT ALLIANCE: an exquisite handmade
THREE-DIMENSIONAL PAPER DIORAMA, layered cut watercolor cardstock, visible creamy cut edges and paper
fibers, folded tabs, stacked relief, soft physical contact shadows, subtle ink-wash color within matte
colored paper. Elegant Chinese steampunk sky-trading world, jade/teal, warm parchment, ink blue, muted
brass-ochre and terracotta. Orthographic/isometric 30-degree elevated view, gentle upper-left light.
NOT low-poly, NOT plastic, NOT photoreal, no glossy CGI. No writing, numbers, logos, watermarks.
Sprite atlas, exact {COLS} columns by {ROWS} rows, {N} separate whole objects, TRUE transparent
background, generous gutters, no overlap. Read left to right: {OBJECT LIST}.
```

## 资源管线

1. 原型图集由 `tools/extract_art.py` 切成单帧，放在 `godot/assets/art/<图集>/NN.webp`；整幅场景图在 `godot/assets/art/scenes/`。
2. 新素材按上面的模板生成，同一图集内统一比例和光向，再用同一脚本切图。
3. 界面元素（面板、按钮、边框）用 Godot 主题 + 九宫格实现，色值取自上表，不另画图。

## 现有素材对照（切片阶段使用）

| 图集 | 内容 | 用途 |
|---|---|---|
| `goods` | 18 种货物图标 | 交易界面 |
| `ships` | 9 种飞艇 | 地图上的船、船坞 |
| `map_islands` | 9 种岛屿 | 地图港口 |
| `leaders` / `emblems` | 商会首领与徽记 | 开局选择、对手栏 |
| `resources` | 16 个界面符号 | 顶栏图标 |
| `lighthouse` | 灯塔 7 阶 | 灯塔工地 |
| `city_buildings` | 9 种设施 | 港口城市界面 |
| `scenes/title`、`scenes/port_xia` | 整幅场景 | 标题页、港口背景 |
| `scenes/story_*` | 剧情插图 | 陆青剧情线 |
