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

## 7. Attribute Model

The project references *Honkai: Star Rail* attribute vocabulary, but keeps only attributes with a concrete role in the current real-time game.

The source reference is recorded separately in `docs/reference/honkai-star-rail/character-attributes.md`.

### 7.1 Current Character / Combat Attributes

The current minimum formal set is:

| Attribute | Project meaning | Source relationship |
|---|---|---|
| **Sync Max** | Maximum synchronization / primary survival resource | Replaces the gameplay role of HP |
| **ATK** | Base offensive stat used by applicable character/core-weapon/weapon damage formulas | Retains ATK concept |
| **DEF** | Reduces or otherwise mitigates applicable incoming Sync damage | Retains DEF concept; exact formula TBD |
| **CRIT Rate** | Chance for eligible damage to critically hit | Retains CRIT Rate concept |
| **CRIT DMG** | Extra damage multiplier for eligible critical hits | Retains CRIT DMG concept |

This is intentionally smaller than the source game's full combat stat sheet.

### 7.2 Survivor-Specific Attributes

The real-time survivor format adds attributes with direct gameplay consumers:

| Attribute | Project meaning |
|---|---|
| **Movement Speed** | Character movement speed in real-time combat |
| **Range Multiplier** | Scales the range / area of attacks that declare themselves range-scalable |
| **Pickup Range** | Collection / attraction radius for experience and collectable run resources |
| **Experience Gain Multiplier** | Multiplies experience gained from eligible sources |
| **Resource Gain Multiplier** | Multiplies eligible run-resource gains |

These are project-native attributes rather than renamed source-game stats.

In particular, **Movement Speed is not the source game's SPD**. Source SPD controls turn frequency; the current game has no turn order to preserve.

### 7.3 Global Build Modifiers With Existing Gameplay Consumers

Some modifiers are useful to the build system but do not need to be treated as character identity/base stats:

- **Cooldown Multiplier** — modifies eligible weapon/ability intervals;
- **Sync Regeneration Multiplier** — modifies eligible Sync recovery;
- **Damage Multiplier / DMG Boost** — generic outgoing-damage modifier where a mechanic explicitly grants one.

They may have a base value on every character, but conceptually they are build/combat modifiers rather than defining character base stats.

This distinction prevents the character sheet from becoming a dumping ground for every possible modifier.

## 8. Source Attributes Not Currently Adopted

The following *Honkai: Star Rail* attributes are **not part of the current project attribute model yet**:

- **SPD** — source meaning is turn frequency / Action Value; no direct real-time equivalent is needed;
- **Effect Hit Rate** — requires probabilistic status/debuff application;
- **Effect RES** — requires the corresponding status-resistance system;
- **Break Effect** — requires a toughness / weakness-break system;
- **Energy Regeneration Rate** — requires an Energy-driven skill/ultimate system;
- **Outgoing Healing Boost** — requires a meaningful healing system;
- **Physical / Fire / Ice / Wind / Lightning / Quantum / Imaginary DMG Boost** — requires the final damage-type system to be settled.

Not adopting them now does not prohibit adding them later. They should enter the formal model only when a concrete mechanic needs them.

## 9. Attribute Design Principles

### 9.1 Preserve source identity, not source formulas

The project can retain recognizable concepts such as ATK, DEF, CRIT Rate and CRIT DMG without reproducing turn-based formulas.

### 9.2 Sync replaces HP as the survival resource

Do not maintain a second conventional HP bar beside Sync for the current first-world survivor combat.

A source-style HP growth concept maps to Sync survivability only when there is a concrete design reason.

### 9.3 Do not reinterpret SPD as several unrelated stats

Movement speed is a project-native real-time stat.

Weapon cooldown/attack cadence remains its own mechanic. Do not create a generic source-SPD conversion layer that simultaneously changes movement, cooldown, projectile speed, or other systems.

### 9.4 Character base stats and Run modifiers are different layers

Character identity currently centers on:

- Sync Max;
- ATK;
- DEF;
- CRIT Rate;
- CRIT DMG;
- character-specific core weapon.

Run/build systems can modify these and add survivor-specific modifiers without making every modifier a permanent character base stat.

### 9.5 Add attributes only when a mechanic consumes them

Do not pre-create Effect Hit Rate, Break Effect, Energy Regeneration, elemental bonuses, knockback stats, projectile speed stats, or other generic fields in anticipation of possible future content.

A new attribute enters the formal model when at least one selected gameplay system actually needs it.

## 10. Current Open Questions

- character-level XP source and pacing;
- whether character level resets per run or has persistent components;
- whether core-weapon proficiency is per run, persistent, or hybrid;
- proficiency thresholds and rewards;
- exact Trailblazer bat attack cadence and geometry;
- knockback rules for normal / Elite / Boss enemies;
- final base-attribute list;
- relationship between Sync and character defensive attributes;
- whether different characters use different core-weapon progression structures;
- how much of the source game's elemental / damage-type system is retained;
- which survivor-specific attributes are global versus weapon-specific.
