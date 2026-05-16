# 确定性 RNG 约定

## 总原则

所有 gameplay 随机必须通过 `RunState.rng_stream(stream_name)` 或 `RunState.rng_manager` 获取，禁止在 gameplay 代码里直接调用 `RandomNumberGenerator.new().randomize()`、`Array.shuffle()` 或其他系统随机。

同一局由 `RunState.grid_seed` 作为 run seed。`RunState.reset_run(seed)` 会使用指定 seed 重置整局 RNG；不传 seed 时会从非 gameplay RNG 生成一个新 seed。存档恢复时应调用 `RunState.restore_rng_state(saved_rng_state)`。

UI、动画、粒子、音效抖动等非玩法表现不能消耗 gameplay RNG。需要非确定表现时，使用 `RunRngManager.create_visual_rng()` 或局部非确定随机，并确保它不会影响地图、战斗、奖励和商店逻辑。

## 命名随机流

- `map.route`：大地图、路线、地图 fallback 生成。
- `grid.node`：阵列节点内容的未来扩展。
- `event.content`：事件内容、事件选项。
- `battle.spawn`：战斗刷怪、刷怪位置、刷怪变体。
- `battle.affix`：精英、Boss、房间词缀。
- `chest.type`：宝箱类型、阵列宝箱基础价格层级；阵列宝箱会在开启时按当前总等级难度追加固定加价。
- `chest.reward`：宝箱奖励抽取，按开启顺序消耗。
- `reward.weapon`：武器奖励、精英奖励等武器相关抽取。
- `reward.passive`：被动奖励相关抽取。
- `shop.refresh`：商店刷新、商店货架。
- `meta.unlock`：局外解锁或未来扩展。

新增系统时添加新的流名，不复用已有流。新增流只会从 run seed 和流名派生自己的状态，不会改变旧流结果。

## 奖励池接口

`scripts/core/RandomPool.gd` 提供基础池抽取：

- 权重抽取：字典项使用 `weight` 字段。
- 不重复抽取：`allow_repeats = false`。
- 条件过滤：`required_tags`、`blocked_tags`。
- 解锁过滤：`unlocked_ids`。
- 已抽取过滤：`drawn_ids`。
- 不同来源传入不同流，例如宝箱用 `chest.reward`，商店用 `shop.refresh`。

未来稀有度、标签、羁绊、职业、构筑方向等规则应优先落到池数据字段和过滤参数里，不要在业务代码里临时打乱数组。

## 存档内容

存档至少保存：

- 当前 run seed：`RunState.grid_seed`。
- RNG 状态：`RunState.rng_state()` 返回的 `run_seed`、各命名流的 `seed`、`state`、`draw_count`。
- 池状态：奖励池、道具池、商店池等已抽取 ID 或已移除项。
- 当前 run 进度：地图、已开宝箱、已清理房间、已有武器/被动等。

读档后先恢复 run seed 和 RNG 状态，再恢复地图/池/角色状态，之后继续抽取才能保持确定性。
