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

本目录以下内容保持为历史快照，不因当前代码或设计变化而持续维护。需要重构某项能力时，应从当前 Game Design 与 Requirement 重新确认 Scope，再按 System Design → Spec → Task 建立该次变更的权威链。
