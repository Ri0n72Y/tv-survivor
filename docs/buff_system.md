# Buff 系统实现说明

> **状态：implementation reference / legacy technical note。**
>
> 本文件记录当前轻量 Buff 实现，便于理解现有代码与行为；它不是当前 System Design 权威，也不单独规定未来 Buff / Effect 系统应如何扩展。
>
> 当 Buff、状态效果或通用 Effect 能力进入新的开发/重构 Scope 时，应先检查当前代码与 Requirement；只有出现需要长期保留的材料技术决策时，才建立或更新对应的 `docs/system-design/`，随后再生成 Spec。

当前 Buff 系统是轻量战斗组件，不是完整 ECS。Godot 场景仍负责具体玩法表现，Buff 系统主要集中管理状态数据、tick 推进和结算事件。

## 当前组件

- `BuffDefinition`：静态定义，包含 `id`、显示名、图标路径、标签、最大层数、tick 间隔和持续时间。
- `BuffInstance`：运行时状态，包含层数、tick 计时、剩余时间、来源和扩展数据。
- `BuffContainer`：保存某个 owner 当前拥有的 Buff 实例。
- `BuffSystem`：统一推进已注册容器，并在实际 tick 发生时按 `before_tick`、`tick`、`after_tick` 产出事件。

这些描述用于解释当前实现，不意味着未来所有状态效果都必须继续使用相同对象模型。

## 当前结算边界

当前 Buff 对象本身不直接扣血、修改速度或操作场景节点。具体玩法效果由调用方消费 `BuffSystem.process()` 返回的事件后执行。

这一边界目前让状态计时/层数管理与 Godot 场景中的实际玩法表现保持分离。后续是否继续扩大这套边界，应由新的具体玩法需求和对应 System Design 决定，而不是由本文件预先承诺。

## 当前使用案例：同步状态

当前同步相关状态使用这套组件：

- `信号弱`：低信号区结算前叠层，按层数扣同步率，离开后在下一次结算前清零。
- `同步稳定`：不受伤且不处于信号弱或不稳定状态时生效，持续稳定 3 秒后恢复同步率。

这些案例说明当前 Buff 组件已经被真实玩法使用，但不代表 Sync 或现有 Buff 分类已经被 Game Design 确认为长期玩法规则。相关玩法地位以当前 Game Design / Requirement 为准。

## 非承诺事项

本文件不再为以下未来内容建立要求：

- Buff UI 必须直接绑定某个当前方法；
- 玩家、敌人或未来玩法对象必须统一采用同一种 Buff owner 模型；
- 当前 `before_tick → tick → after_tick` 必须扩展成通用事件系统；
- 当前 Buff 系统必须演化为完整 Effect 系统或 ECS。

如果未来确实需要这些能力，应从实际 Scope 重新进行 System Design，而不是把当前实现说明当作未来架构合同。
