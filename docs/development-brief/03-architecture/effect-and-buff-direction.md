# Buff / Effect 演进方向

## 推荐目标模型

```text
EffectDefinition（静态 Resource）
→ EffectInstance（运行时值）
→ EffectHost / ECS Component（实体所有权）
→ EffectSystem（生命周期与阶段）
→ Typed Commands（跨域变化）
→ 领域执行器
```

## 分层原则

1. Catalog 负责 `ID → 静态定义`。
2. 实体或宿主拥有运行时实例。
3. 生命周期系统处理叠层、刷新、过期和事件订阅。
4. 数值修改进入属性聚合器。
5. 副作用通过类型化命令提交。
6. 派生事件进入稳定队列，不同步递归调用任意处理器。

## 第一个通用案例的验收要求

应至少包含：来源、目标、层数、持续时间、叠层策略、事件阶段、稳定顺序、移除路径、UI 快照、保存策略和测试。

## 暂不建设

- 完整 ECS 迁移；
- 通用视觉效果图；
- 元素反应引擎；
- 万能 Command Bus；
- 无实际内容消费者的 DSL。
