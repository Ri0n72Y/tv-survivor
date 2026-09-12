# 开发简报索引

> **Legacy snapshot**：本目录记录 Game Design-first SDD 建立前的工程状态与架构讨论，仅用于理解历史代码。当前流程权威见仓库根目录 `AGENTS.md`：`docs/design/` → `docs/requirements.md` → `docs/system-design/` → `docs/specs/` → Task。普通开发不再更新本目录，也不据此给旧代码补写 System Design 或 Spec。

## 基线

| 项目 | 当前值 |
|---|---|
| 默认分支 | `main` |
| 合并提交 | `c02a0f21dcec2b7f91b9c94204ad6ceabe2bcd17` |
| Godot | `4.7.1` |
| 主场景 | `res://scenes/main/Main.tscn` |
| Autoload | `RunState` |
| 已合并工程 PR | PR #5 |

## 模块

1. [项目总览](01-overview/README.md)
2. [玩法系统](02-gameplay/README.md)
3. [工程架构](03-architecture/README.md)
4. [内容生产](04-content-authoring/README.md)
5. [测试与质量](05-testing-and-quality/README.md)
6. [开发工作流](06-development-workflow/README.md)
7. [路线图](07-roadmap/README.md)
8. [仓库参考](08-reference/README.md)

## 当前工程判断

### 已具备

- 树状/阵列地图、连接移动、镜头移动和小地图。
- 任务、搜索、精英、Boss 四类战斗房流程。
- 四把武器、六个被动的 Resource 内容定义和自动发现目录。
- `BuildState` 对构筑、金币和分数的集中所有权。
- Catalog 驱动的武器运行时工厂和被动属性聚合。
- `BattleContext → BattleScene → BattleResult/BattleEffect → BattleResultApplicator` 边界。
- 类型化奖励核心与旧 UI Dictionary 兼容层。
- 轻量 Buff 容器与同步状态结算。

### 尚未闭环

- 合并后的 `main@c02a0f2` 尚未重新运行 Godot import、烟测和完整玩法回归。
- 奖励 Dictionary 仍存在于场景/UI 边界。
- `GridScene` 和 `BattleScene` 仍承担较多编排职责。
- 当前 Buff 系统只覆盖同步相关案例，尚未成为通用 Effect 运行时。
- 多触发器顺序、事件队列、因果深度和递归保护尚未实现。
