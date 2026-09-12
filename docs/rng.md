# 确定性 RNG 实现说明

> **状态：implementation reference / legacy technical note。**
>
> 本文件记录当前 Run RNG 的实现约定，便于理解现有确定性随机代码。它不是独立的 System Design 权威，也不自动要求未来所有随机、存档或内容系统沿用这里的全部细节。
>
> 当随机、存档、地图生成、奖励池等能力进入新的开发/重构 Scope 时，应先检查当前代码与 Requirement；只有出现需要长期保留的材料技术决策时，才建立或更新对应的 `docs/system-design/`，随后生成 Spec。

## 当前实现原则

当前 gameplay 随机通过 `RunState.rng_stream(stream_name)` 或 `RunState.rng_manager` 获取，以保持同一 run seed 下的确定性行为。Gameplay 代码不应直接用独立 `RandomNumberGenerator.randomize()`、`Array.shuffle()` 或其他非确定随机替代现有命名流，否则会破坏当前复现能力。

同一局当前由 `RunState.grid_seed` 作为 run seed。`RunState.reset_run(seed)` 使用指定 seed 重置整局 RNG；未显式提供 seed 时，RunState 会从非 gameplay 随机源生成新 seed。`RunRngManager` 可以保存和恢复已经创建的命名随机流状态。

UI、动画、粒子、音效抖动等非 gameplay 表现不应消耗 gameplay RNG。当前代码提供 `RunRngManager.create_visual_rng()` 用于独立的非确定表现随机。

这些描述是对当前实现不变量的记录。若未来 Requirement 有意改变确定性、存档或复现策略，应通过新的 Scope / applicable System Design 更新，而不是把本文件视为不可改变的上游设计。

## 当前已注册的命名随机流

`RunRngManager` 当前注册以下默认流名：

- `map.route`
- `grid.node`
- `event.content`
- `battle.spawn`
- `battle.affix`
- `chest.type`
- `chest.reward`
- `reward.weapon`
- `reward.passive`
- `shop.refresh`
- `meta.unlock`

这些名称存在于当前实现中，但并不表示每个流都已经对应当前 Game Design 中的正式系统，也不保证所有未来系统必须继续使用这些名称。

当前 `RunRngManager` 会根据 run seed 与 stream name 派生独立流状态，因此不同命名流可以避免互相消耗随机序列。

新增或调整随机域时，应优先保持当前 gameplay 确定性行为，除非 Requirement / applicable System Design 明确改变这一约束。是否复用、删除或新增流名，应根据真实调用关系决定，而不是仅为了维持本列表的形式完整。

## 当前随机池工具

`scripts/core/RandomPool.gd` 提供当前代码使用的基础池抽取能力，包括：

- 权重抽取；
- 可选的不重复抽取；
- `required_tags` / `blocked_tags` 条件过滤；
- `unlocked_ids` 解锁过滤；
- `drawn_ids` 已抽取过滤。

调用方可使用不同命名 RNG 流隔离不同随机来源。

早期文档曾建议未来稀有度、标签、羁绊、职业、构筑方向等规则优先通过池数据和过滤参数表达。该内容现仅保留为历史实现思路，**不是未来内容系统的 Requirement 或 System Design**。

## RNG 状态保存能力

当前 `RunRngManager.save_state()` 保存：

- `run_seed`；
- 已创建命名流各自的保存状态。

每个 `RunRngStream` 的具体保存字段以当前代码为准。恢复时，`RunRngManager.restore_state()` 会重建这些流。

这说明当前 RNG 层本身具备保存/恢复能力，但项目当前并未因为本文件而承诺完整存档系统的最终数据结构或恢复顺序。

## 历史存档建议 — 非权威

旧文档曾提出完整 Run 存档至少还应包含：

- 当前 run seed；
- RNG 流状态；
- 奖励池、道具池、商店池等池状态；
- 地图、已开宝箱、已清理房间、已有武器/被动等 Run 进度；
- 恢复时先恢复 RNG，再恢复其他状态。

这些内容属于当时的架构建议，并不等于当前已经存在完整存档 Requirement。未来若正式开发存档/读档能力，应重新从 Game Design / Requirement 出发确定玩家可见行为，再由 applicable System Design 决定持久化数据、恢复顺序和兼容策略。
