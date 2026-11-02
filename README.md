# 云海商盟 Yunhai Shangmeng

浮空群岛之上的飞艇贸易模拟经营游戏（Godot 4.3）。当前为**霞市篇垂直切片**：8 个港口、10 种货物、3 种飞艇、2 个对手商会、三层灯塔竞赛、陆青剧情线与 10 个随机事件。

**在线试玩**：https://leonadeellen.github.io/Yunhaishangmeng/

## 目录

| 路径 | 内容 |
|---|---|
| `godot/` | Godot 工程（`scripts/core` 纯逻辑，`scripts/ui` 界面） |
| `godot/tests/` | 无界面测试与平衡探针、截图驱动 |
| `docs/01-audit.md` | v4.0 原型体检与对标打分表 |
| `docs/02-design.md` | 设计文档 |
| `docs/03-art-style.md` | 美术规范与出图提示词 |
| `prototype/` | 原 HTML 原型 v4.0 |
| `tools/` | 原型模拟脚本、美术切图脚本 |

## 常用命令（在 `godot/` 下）

```bash
godot --headless --path . --import                       # 首次导入
godot --headless --path . -s res://tests/run_all.gd      # 回归测试（经济、存档、破产、结局、胜率）
godot --headless --path . -s res://tests/balance.gd      # 平衡探针：各商会每层灯塔的建成年份
YUNHAI_SHOTS=/tmp/shots xvfb-run godot --path . --rendering-driver opengl3   # 自动截图
godot --headless --path . --export-release Web ../build/web/index.html       # 导出网页版
```
