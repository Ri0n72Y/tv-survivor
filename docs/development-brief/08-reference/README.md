# 08｜仓库参考

## 顶层结构

```text
content/                 静态武器与被动 Resource
 data/maps/              地图数据
 docs/                   设计与工程文档
 scenes/                 Godot 场景和场景脚本
 scripts/battle/         战斗规则、结果与 Buff
 scripts/build/          构筑状态、属性和目录门面
 scripts/content/        Resource 定义与发现
 scripts/core/           RunState、常量、随机流
 scripts/grid/           地图生成与类型
 scripts/rewards/        类型化奖励核心
 tests/                  烟测与网格测试
```

## 关键入口

- `project.godot`
- `scenes/main/Main.tscn`
- `scripts/core/RunState.gd`
- `scenes/grid/GridScene.gd`
- `scenes/battle/BattleScene.gd`
- `tests/ContentFoundationSmoke.tscn`
- `tests/test_runner.tscn`
