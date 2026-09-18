# Character Design

> Status: active Game Design.
>
> This document defines the current character-selection, core-weapon, character-growth, and base-attribute direction. Concrete numerical balance remains open unless explicitly stated.

## 1. Character Selection

The game supports multiple playable characters.

Before each exploration, the player chooses **one character** to enter the current simulation/exploration run.

Current setting direction:

- the explored world-bubble structure is framed as a **Simulated Universe test**;
- the selected character enters the simulated universe for the run;
- different characters can have different base attributes, core weapons, and long-term growth identities;
- the shared survivor-like weapon/build system exists on top of the selected character rather than replacing character identity.

For the first implementation/design pass, only one character is considered:

> **开拓者 — 小浣熊**

Other playable characters remain future design space and should not force generalized content before they are actually selected for implementation.

## 2. Character Combat Identity

A character is not merely a sprite carrying a random build.

Each character owns at least:

- a base attribute profile;
- a **core weapon**;
- character-level growth;
- core-weapon proficiency / kill-count growth;
- character-specific presentation and combat identity.

The ordinary run weapon pool remains a separate layer.

Conceptually:

```text
Character
├─ Base Attributes
├─ Core Weapon
│  ├─ character-level growth
│  └─ kill-count / proficiency growth
│
└─ Run Build
   ├─ acquired weapons
   ├─ passives / accessories
   └─ temporary run modifiers
```

## 3. Core Weapon

Every playable character has their own **core weapon**.

A core weapon differs from ordinary run weapons in three important ways:

1. it belongs to the character by default;
2. it grows with the character rather than competing for ordinary weapon-upgrade choices;
3. it does **not occupy or consume the normal weapon upgrade slot/path**.

This means character identity remains present even when two runs obtain very different random builds.

Core-weapon progression currently has two sources:

### 3.1 Character Level

As character level rises, the core weapon can improve together with the character.

The exact relationship between character level and weapon parameters is not yet fixed.

### 3.2 Kill Count / Proficiency

Enemy kills contribute to the core weapon's **熟练度 / proficiency**.

Proficiency can improve the weapon independently of ordinary run weapon upgrades.

The exact progression curve, whether proficiency is per-run or persistent, thresholds, caps, and what properties it modifies remain open design questions.

## 4. First Character — 开拓者 / 小浣熊

The first playable character is:

- Character: 开拓者
- Project presentation / nickname: 小浣熊
- Core weapon: **球棒**

### 4.1 Naming Boundary

The Trailblazer's core weapon **球棒** is a project character weapon.

It is **not** the external-reference weapon **彩虹球棒 / Rainbow Bat** from *The Legend of Galactic Baseballer*.

Keep them separate in data, naming, design, and implementation.

Suggested conceptual distinction:

```text
Trailblazer Core Weapon
  球棒
  character-owned
  short-range side attack
  proficiency growth

Reference Weapon
  彩虹球棒 / Rainbow Bat
  Galactic Baseballer source material
  event-triggered multi-hit weapon
```

## 5. Trailblazer Core Weapon — 球棒

Current confirmed behavior:

- close-range weapon;
- attacks **sideways / laterally** relative to the character;
- covers a short-range area rather than a single point;
- deals **Physical damage**;
- knocks hit targets back;
- belongs permanently to the Trailblazer;
- grows through character level and kill-count/proficiency;
- does not compete for ordinary weapon upgrade slots.

Current behavior sketch:

```text
attack trigger
    ↓
create short lateral melee area
    ↓
find enemies in area
    ↓
deal Physical damage
    ↓
apply knockback
```

Open details:

- automatic attack or player-input relationship;
- left/right or broader lateral selection rule;
- exact attack arc / rectangle / swept shape;
- attack frequency;
- damage formula;
- knockback distance / force;
- whether knockback resistance exists;
- whether Elite/Boss enemies use reduced knockback;
- level/proficiency breakpoints;
- visual and audio presentation.

These remain Game Design questions until explicitly settled.

## 6. Character Level

Character level is separate from ordinary weapon upgrade choices.

Character level can increase the character's **base attributes** in addition to improving or unlocking core-weapon growth.

The exact XP source and progression curve remain open, but the intended separation is:

```text
Character Level
→ base character growth
→ may improve core weapon

Core Weapon Proficiency
→ weapon-specific mastery from kills

Run Weapon Upgrades
→ temporary/random build choices
→ do not consume core-weapon progression
```

## 7. 属性体系

本项目参考《崩坏：星穹铁道》的属性语言，但按照实时类幸存者玩法重新解释。统一使用中文名词。

原作名词、速度公式和击破机制参考见：

- `docs/reference/honkai-star-rail/character-attributes.md`

### 7.1 角色核心战斗属性

当前正式纳入设计的角色战斗属性：

| 属性 | 当前含义 |
|---|---|
| **同步值上限** | 玩家核心生存资源上限，取代传统角色生命值 |
| **攻击力** | 参与角色核心武器、普通武器及其他适用伤害公式的基础攻击属性 |
| **防御力** | 降低适用的同步值损伤；具体公式待定 |
| **速度** | 决定武器与其他适用攻击行为的基础攻击间隔 |
| **暴击率** | 适用伤害触发暴击的概率 |
| **暴击伤害** | 暴击时的额外伤害倍率 |
| **效果命中** | 提高具有基础概率的负面效果施加成功率 |
| **击破特攻** | 强化击破后产生的伤害或对应异常效果 |
| **回能效率** | 提高适用来源恢复战技点和终结技能量的效率 |

当前不设置玩家的 **效果抵抗** 属性。类幸存者战斗优先强调移动、回避和主动处理威胁，而不是通过效果抵抗堆叠降低受控概率。

### 7.2 速度与攻击间隔

《崩坏：星穹铁道》的基础行动值满足：

```text
基础行动值 = 10000 / 速度
```

本项目保留同样的反比关系，但把“下一次行动”映射为实时武器的“下一次攻击”。

采用 100 速度作为基准：

```text
攻击间隔倍率 = 100 / 速度
实际攻击间隔 = 武器基准攻击间隔 × 100 / 速度
```

对于基准攻击间隔为 1 秒的武器：

| 速度 | 实际攻击间隔 |
|---:|---:|
| 100 | 1.000 秒 |
| 125 | 0.800 秒 |
| 150 | 0.667 秒 |
| 200 | 0.500 秒 |

因此装备直接提供若干点 **速度** 时，其收益可以沿用星铁玩家熟悉的数值尺度，同时自然映射到实时攻击频率。

武器仍可以拥有自己的基准攻击间隔，因此速度不会把所有武器强行变成相同攻击节奏。

### 7.3 移动速度

**移动速度** 是独立于速度的实时空间属性。

两者存在体感联系：

- 速度更高的角色，其基础移动表现也应略快；
- 但速度对实际移动速度的影响应当 **边际递减**；
- 专门的 **移动速度加成** 是提升实战移动能力的主要途径。

当前只固定这一关系，不提前锁定具体换算公式。

概念上：

```text
实际移动速度
= 角色基础移动速度
× 速度带来的弱关联修正
× 移动速度加成

其中：
速度带来的修正单调增加，但边际递减；
移动速度加成承担主要构筑收益。
```

### 7.4 实时类幸存者专属属性

当前正式纳入：

| 属性 | 当前含义 |
|---|---|
| **移动速度** | 实时空间移动速度 |
| **攻击范围倍率** | 放大声明为可受范围影响的攻击距离、索敌范围或攻击区域 |
| **投射物飞行速度倍率** | 提高声明为可受投射物速度影响的弹体飞行速度 |
| **拾取范围** | 经验与可拾取资源的吸附 / 收集范围 |
| **经验获取倍率** | 提高适用来源获得的经验 |
| **资源获取倍率** | 提高适用的局内资源获得量 |

这些属性不是对原作名词的重命名，而是类幸存者玩法自己的属性。

### 7.5 负面效果与效果命中

当前玩法会存在可施加给敌人的负面效果，例如：

- 防御力降低；
- 虚弱；
- 风化；
- 触电；
- 灼烧；
- 裂伤；
- 其他由角色、武器或事件产生的负面状态。

其中具有 **基础施加概率** 的效果，可以受到效果命中影响。

效果命中与具体负面效果之间的概率公式暂不固定；是否让击破必然产生的属性异常经过效果命中判定也暂不在这里决定。

### 7.6 敌人生命值与韧性值

敌人采用双资源条：

```text
红条：生命值
白条：韧性值
```

- **生命值** 归零：敌人被击杀；
- **韧性值** 归零：敌人被击破，并产生对应属性的击破结果；
- 不同攻击 / 武器可以拥有不同的 **削韧值**；
- 某些角色、武器和构筑可以专门围绕削韧与击破形成玩法。

**削韧值** 当前视为一次攻击或武器行为的属性，而不是必须放在角色基础面板上的独立角色属性。

**击破特攻** 则是角色 / 构筑属性，用于强化击破收益。

当前计划的七属性击破异常参考星铁：

| 属性 | 击破异常 |
|---|---|
| 物理 | 裂伤 |
| 火 | 灼烧 |
| 冰 | 冻结 |
| 雷 | 触电 |
| 风 | 风化 |
| 量子 | 纠缠 |
| 虚数 | 禁锢 |

具体异常伤害、持续时间、控制方式和 Boss / 精英抗性后续分别设计，不在属性模型阶段预先确定。

### 7.7 七属性伤害提高

设计层预留以下七项属性：

- 物理属性伤害提高；
- 火属性伤害提高；
- 冰属性伤害提高；
- 雷属性伤害提高；
- 风属性伤害提高；
- 量子属性伤害提高；
- 虚数属性伤害提高。

它们为未来属性克制、属性构筑和对应角色 / 武器提供稳定名词。

**当前版本暂不实现属性克制，因此这些属性只进入 Game Design，不进入当前开发 Scope。**

### 7.8 战技点、终结技能量与回能效率

角色拥有：

- **战技**；
- **终结技**；
- **战技点**；
- **终结技能量**。

**回能效率** 是本项目的统一恢复效率属性，用于提高适用来源产生的：

- 战技点恢复；
- 终结技能量恢复。

击杀敌人是计划中的回能来源之一，因此回能效率会影响击杀带来的战斗资源恢复。

当前只固定这一语义，不提前确定：

- 每次击杀恢复多少战技点；
- 每次击杀恢复多少终结技能量；
- 普通 / 精英 / Boss 的回能差异；
- 哪些其他行为可以恢复战技点或终结技能量；
- 回能效率的具体计算公式与上限。

## 8. 当前属性清单

### 8.1 角色 / 构筑属性

当前正式属性：

- 同步值上限
- 攻击力
- 防御力
- 速度
- 暴击率
- 暴击伤害
- 效果命中
- 击破特攻
- 回能效率
- 移动速度
- 攻击范围倍率
- 投射物飞行速度倍率
- 拾取范围
- 经验获取倍率
- 资源获取倍率

设计预留、当前版本暂不实现：

- 物理属性伤害提高
- 火属性伤害提高
- 冰属性伤害提高
- 雷属性伤害提高
- 风属性伤害提高
- 量子属性伤害提高
- 虚数属性伤害提高

### 8.2 战斗资源 / 状态，不作为普通属性

- 当前同步值
- 战技点
- 当前终结技能量
- 敌人生命值
- 敌人韧性值
- 武器 / 攻击削韧值
- 各类负面效果及其层数 / 持续时间

### 8.3 当前明确不加入

- 玩家生命值：由同步值承担核心生存职责；
- 效果抵抗：当前玩法强调主动回避，不建立玩家效果抵抗构筑；
- 单独的通用冷却倍率作为角色基础属性：普通攻击频率优先由速度统一表达。

某些武器、技能或特殊效果仍可以直接改变自身攻击间隔，但不因此增加一个与速度并列的角色基础冷却属性。

## 9. 属性设计原则

### 9.1 保留原作认知，不照搬回合公式

攻击力、防御力、速度、暴击、效果命中、击破特攻等名称继续利用星铁已有认知，但具体公式服从实时玩法。

### 9.2 同步值取代玩家生命值

首个世界泡的玩家生存只围绕同步值建立，不额外维护一套传统生命值条。

### 9.3 速度统一承担攻击频率

速度是角色与构筑影响攻击节奏的主要通用属性。

不要同时预建“攻击速度”“通用冷却缩减”“行动速度”等多个重叠基础属性。

### 9.4 移动速度与速度相关但不等价

速度对移动表现只有较弱且边际递减的影响；移动速度加成才是实时走位构筑的主要控制项。

### 9.5 削韧属于攻击，击破特攻属于构筑

不要为了破韧系统同时创建多个意义重叠的角色属性。

攻击声明削韧值；角色 / 构筑通过击破特攻强化击破收益。

### 9.6 空间战斗倍率保持职责单一

- 速度决定攻击频率；
- 移动速度决定角色实时位移能力；
- 攻击范围倍率决定适用武器的攻击覆盖范围；
- 投射物飞行速度倍率决定适用弹体的飞行速度。

不把这些实时行为压进一个万能“速度”或“范围”属性。

### 9.7 属性只有出现明确消费者时才进入实现

七属性伤害提高已经作为未来设计名词保留，但在属性克制没有进入 Requirement 前不实现。

同理，不因为未来可能存在某个机制就提前增加新的通用属性字段。

## 10. 当前仍需设计的问题

- 角色等级经验来源与节奏；
- 角色等级是局内成长、局外成长还是混合；
- 核心武器熟练度是局内、永久还是混合；
- 核心武器熟练度阈值与成长内容；
- 开拓者球棒攻击频率、范围形状和具体击退规则；
- 防御力对同步值损伤的公式；
- 速度对移动速度的边际递减函数；
- 效果命中的实际概率公式；
- 击破异常在实时玩法中的持续方式；
- 回能效率的计算公式；
- 战技点与终结技能量的基础恢复规则；
- 七属性克制何时进入实际开发 Scope。
