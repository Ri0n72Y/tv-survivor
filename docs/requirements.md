# Current Version Requirement

> 状态：待从新版 Game Design 中重新抽取。
>
> 本文件只描述 **当前版本实际承诺开发或验证的 Scope**。它不是完整 Game Design，也不是当前代码功能清单。

## 1. Role

Requirement 位于 Game Design 与 System Design 之间：

```text
Game Design
    ↓ select current version scope
Requirement
    ↓
System Design
    ↓
Spec
    ↓
Task
```

Game Design 可以包含未来玩法、内容方向、候选系统和暂未实现的设计。

只有被本文件明确选入 Scope 的内容，才进入当前版本的软件设计与实现流程。

## 2. Current status

PR #7 中建立的旧 Requirement 是根据历史实现与旧开发简报整理出的过渡基线。随着项目改为 **Game Design → Requirement Scope → System Design → Spec → Task** 的流程，该基线不再作为未来功能选择的权威来源。

当前正在重写 Game Design，因此本文件暂不声明新的功能 Scope。

在新的 Game Design 收敛并重新抽取 Requirement 前：

- 不因为旧代码已经存在就自动把某项能力认定为长期 Requirement；
- 不因为 Design 中讨论过某个未来玩法就自动进入实现；
- 若必须进行独立的修复或维护工作，应以明确的当前行为保护目标单独界定 Scope，而不是借此反向定义新的 Game Design。

## 3. Scope modes

Requirement 可以使用两种模式。

### Delivery Scope

用于已经足够收敛、计划保留在项目中的设计。

它回答：

- 这一版本确认交付什么；
- 玩家/系统最终可以观察到什么；
- 哪些内容明确不在这一版本实现；
- 若是重构，哪些用户可观察行为需要保留。

### Validation Scope

用于仍需通过可玩原型验证的 Game Design 问题。

它回答：

- 要验证的设计问题或假设是什么；
- 最小可玩/可观察实验是什么；
- 什么结果或证据足以回答这个问题；
- 哪些实现是临时、可丢弃、尚未承诺进入正式架构的。

Validation Scope 的代码是设计证据，不会因为“已经写出来”就自动成为长期 Requirement 或 System Design。

验证完成后，应先把结论写回 Game Design。若决定保留，再从更新后的 Design 中抽取 Delivery Scope。

## 4. Requirement extraction template

下一版 Requirement 应从已确认的 Game Design 中抽取，并至少说明：

### Scope mode

`Delivery` 或 `Validation`。

### Design sources

列出当前 Scope 所依据的 Game Design 文档或明确设计决策。

### In scope

只列出本版本确认要实现、重构或验证的能力与可观察结果。

### Acceptance direction

对于 Delivery Scope：说明怎样判断该能力已经达到当前版本承诺。

对于 Validation Scope：说明怎样判断原型已经足以回答目标设计问题，以及需要观察什么结果。

保持在产品/玩法结果层，不提前规定软件结构。

### Out of scope

仅在防止范围蔓延或误实现时列出本版本明确不做的设计内容。

### Preservation constraints

若本版本是在现有原型上重构，列出确实需要保持的用户可观察行为；不要把所有历史实现细节永久升级成 Requirement。

### Prototype status

仅 Validation Scope 使用。说明哪些内容是临时实现、哪些行为不应被视为长期合同，以及验证完成后计划保留、重做或删除的判断方式。

## 5. What does not belong here

以下内容不应写入 Requirement：

- 尚未收敛、且当前也没有明确验证目标的玩法脑暴；
- 模块、脚本、场景 ownership；
- 接口、数据模型、依赖方向和生命周期；
- 为未来玩法预留的抽象架构；
- Spec 级 failure/contract 细节；
- Task 级文件修改步骤；
- 仅因为当前代码已经存在而产生的功能清单。

这些内容分别属于 Game Design、System Design、Spec、Task 或实现证据。
