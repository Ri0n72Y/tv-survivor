# 关键决策记录

1. Godot 固定为 4.7.1。
2. 普通静态内容使用 Resource 自动发现，不维护中央数组。
3. 武器管理器不识别具体武器 ID。
4. 普通被动数值通过属性聚合，不在 BuildState 写 ID 分支。
5. Catalog 不拥有运行时 Effect/Buff 实例。
6. 战斗切换使用类型化 Context/Result/Effect。
7. 奖励校验、支付、应用和退款集中在 RewardService。
8. 树状地图改造保留，并让 BattleResult 揭示逻辑识别 connections。
9. 当前同步 Buff 系统保留，但需要与通用 Effect 方向统一。
10. 完整 ECS、元素反应引擎和 DSL 延后到具体案例出现后。
