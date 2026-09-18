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

## 7. Base Attribute Direction

The character attribute model continues to reference *Honkai: Star Rail* as its conceptual source, but the gameplay format is different, so attributes do not need to reproduce turn-based formulas one-to-one.

Relevant source-style concepts may include attributes such as:

- HP / survivability-related concepts, where applicable;
- ATK;
- DEF;
- CRIT Rate;
- CRIT DMG;
- damage-type / Physical-related modifiers;
- other character combat attributes when they remain meaningful in real-time play.

However, this project's first-world combat uses **Sync as the core survival resource rather than traditional HP**, so source-game survivability concepts must be adapted rather than copied literally.

## 8. Survivor-Specific Attributes

The real-time survivor-like format needs additional attributes that do not map cleanly to the source turn-based character sheet.

Current expected survivor-specific attributes include:

- **Movement Speed** — character movement speed;
- **Range Multiplier** — scales appropriate weapon/attack ranges or areas;
- **Pickup Range** — attraction/collection radius for experience and resources;
- **Experience Multiplier** — additional experience gain;
- **Resource Multiplier** — additional gain from relevant run resources.

Other likely real-time attributes should only be added when a concrete mechanic requires them.

Potential examples such as cooldown, projectile speed, duration, knockback, spawn-related modifiers, or reroll/economy parameters remain undecided until the related build systems are designed.

## 9. Attribute Design Principles

### 9.1 Preserve source identity, not source formulas

The project may use familiar *Honkai: Star Rail* attribute names and character identities, but their actual mechanics should serve the real-time game.

### 9.2 Character attributes and build attributes must coexist

Base character growth gives characters persistent identity.

Run weapons, passives, accessories, and temporary modifiers provide run-specific build variation.

Neither layer should erase the other.

### 9.3 Core weapon is character progression, not a normal weapon slot

The core weapon must not be diluted into the ordinary random weapon pool.

If the player receives an ordinary weapon upgrade choice, upgrading the Trailblazer's bat is not one of the competing slots unless a future design explicitly introduces a separate core-weapon choice mechanic.

### 9.4 Add survivor-only attributes only for real mechanics

Do not create a large generic stat sheet in advance.

A stat becomes part of the formal model when it has a clear gameplay consumer.

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
