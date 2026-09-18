# 彩虹球棒 / Rainbow Bat

> Source type: external reference data.
>
> Source version: **《银河球棒侠传说》基础版 / Honkai: Star Rail 2.2 (2024)**.
>
> This document records the source weapon for design research. It is **not** the protagonist Trailblazer's core bat and is not automatically a project weapon.

## 1. Identity

- Name: 彩虹球棒 / Rainbow Bat
- Reference ID: `rainbow_bat`
- Source category: Random Type
- Source tag: Focus
- Max level: Lv.8
- 超武进化所需被动（原活动称“共鸣配饰”）：迪斯科棒球 / Disco Baseball
- 进化条件：彩虹球棒 Lv.8 + 迪斯科棒球 Lv.1+
- 传说形态：Morningstar Bat
- Source edition: original/base Galactic Baseballer, not Demon King edition

## 2. Core Behavior

Source behavior:

- triggers after an allied character attacks enemies;
- chooses one eligible target from enemies hit by that attack;
- performs multiple additional hits against that target;
- each hit deals a random damage type;
- has an additional damage bonus against Elite/Boss targets;
- it is an event-triggered weapon, not an independent cooldown/turn weapon.

Behavior model:

```text
character attack resolves
        ↓
collect targets hit by that attack
        ↓
choose one eligible target
        ↓
Rainbow Bat triggers
        ↓
perform N random-type hits
```

## 3. Level Progression

| Level | Hits | Damage per hit | Elite/Boss bonus | Change |
|---:|---:|---:|---:|---|
| Lv1 | 4 | 100% base DMG | +30% | Base behavior |
| Lv2 | 4 | 120% | +30% | Damage increase |
| Lv3 | 4 | 150% | +30% | Damage increase |
| Lv4 | 6 | 150% | +30% | Hit count 4 → 6 |
| Lv5 | 6 | 180% | +30% | Damage increase |
| Lv6 | 6 | 210% | +30% | Damage increase |
| Lv7 | 6 | 240% | +30% | Damage increase |
| Lv8 | 6 | 300% | +30% | Damage increase |

The important progression breakpoint is Lv4: it changes attack structure instead of only scaling a number.

## 4. 超武进化

基础版《银河球棒侠传说》的通用进化规则是：**Lv.8 武器 + Lv.1 以上对应共鸣配饰 → 传说武器**。

彩虹球棒对应：

```text
彩虹球棒 Lv.8
+
迪斯科棒球 Lv.1+
↓
Morningstar Bat
```

在我们后续整理武器时，将“共鸣配饰”统一记录为 **超武进化所需被动**，同时保留原活动术语用于溯源。

Recorded legendary behavior:

- keeps the same basic trigger;
- keeps random damage types;
- attacks 9 times;
- each hit deals 600% base DMG;
- keeps the +30% Elite/Boss damage bonus.

This is primarily an amplification evolution rather than a replacement of the core behavior.

## 5. 超武进化被动：迪斯科棒球

**迪斯科棒球 / Disco Baseball** 是彩虹球棒对应的超武进化被动，在原活动中属于“配饰 / 共鸣配饰”。

基础版效果：本局中，我方角色与武器每造成过一种不同属性的伤害，就提高我方角色与武器造成的伤害。

| 等级 | 每种已出现伤害属性提供的增伤 |
|---:|---:|
| Lv1 | +4% |
| Lv2 | +5% |
| Lv3 | +6% |
| Lv4 | +7% |

因此它同时承担两种职责：

1. **进化钥匙**：至少 Lv.1 时允许 Lv.8 彩虹球棒进化为传说武器；
2. **独立构筑被动**：即使不考虑进化，它本身也奖励多属性伤害构筑。

它与彩虹球棒的“随机属性伤害”天然协同，但不是只对彩虹球棒生效。

## 6. Implementation Primitive Observed

The useful implementation lesson for this project is not the exact source weapon, but the behavior primitive:

**combat-event-triggered weapon**

Unlike the current prototype weapons that mostly act from their own timers, this source weapon requires an attack-resolution event carrying information about:

- event source;
- event type;
- targets hit;
- whether the event is allowed to trigger weapon effects.

Potential event categories may later need to distinguish character attacks from weapon damage, enemy damage, and environmental damage so weapon effects do not recurse unintentionally.

This is an implementation observation only; the exact combat-event architecture belongs to System Design when a current project weapon actually requires it.

## 7. Unknown / Not Yet Captured

The current text dataset does not reliably capture:

- exact hit-to-hit visual timing;
- exact animation;
- sound effects;
- detailed impact VFX;
- exact presentation of random damage types.

These should be filled from base-version gameplay footage if presentation fidelity becomes relevant.

## 8. Project Use

This weapon is currently a **reference sample** for:

- trigger-based weapons;
- multi-hit single-target weapons;
- non-linear level progression;
- Elite/Boss specialization;
- 普通武器 → 超武进化被动（共鸣配饰）→ 传说武器的进化配方；
- 进化被动自身仍具有独立构筑价值，而不是纯粹钥匙。

Do not confuse it with the Trailblazer's core weapon, which is a separate project-specific bat design.
