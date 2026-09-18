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
- Resonant accessory: 迪斯科棒球 / Disco Baseball
- Legendary form: Morningstar Bat
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

## 4. Resonance / Legendary

When Rainbow Bat reaches Lv.8 and the corresponding resonant accessory is available, it can evolve into Morningstar Bat.

Recorded legendary behavior:

- keeps the same basic trigger;
- keeps random damage types;
- attacks 9 times;
- each hit deals 600% base DMG;
- keeps the +30% Elite/Boss damage bonus.

This is primarily an amplification evolution rather than a replacement of the core behavior.

## 5. Resonant Accessory

迪斯科棒球 / Disco Baseball rewards damage-type diversity.

Recorded base-version progression:

| Level | Effect |
|---:|---|
| Lv1 | For each different damage type appearing in the run, character and weapon damage +4% |
| Lv2 | +5% per type |
| Lv3 | +6% per type |
| Lv4 | +7% per type |

The accessory naturally synergizes with Rainbow Bat's random damage-type behavior.

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
- source weapon → resonant accessory → legendary evolution.

Do not confuse it with the Trailblazer's core weapon, which is a separate project-specific bat design.
