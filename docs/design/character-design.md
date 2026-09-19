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

角色拥有基础属性，并可以通过角色等级与局内构筑获得属性修正。

属性的统一定义、用途、职责边界与当前清单见：

- `docs/design/attributes.md`

角色设计只负责决定：

- 不同角色的基础属性差异；
- 角色等级如何成长这些属性；
- 角色核心武器如何消费这些属性；
- 哪些角色拥有特殊的属性倾向。

不要在本文件重复维护完整属性定义。

## 8. 当前仍需设计的问题

- 角色等级经验来源与节奏；
- 角色等级是局内成长、局外成长还是混合；
- 核心武器熟练度是局内、永久还是混合；
- 核心武器熟练度阈值与成长内容；
- 开拓者球棒攻击频率、范围形状和具体击退规则；
- 开拓者的初始属性与等级成长；
- 后续角色之间的基础属性差异。
