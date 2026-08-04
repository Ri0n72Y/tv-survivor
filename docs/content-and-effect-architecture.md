# Content and Effect Architecture

## Purpose

This document defines the engineering boundary required before large-scale content production. It applies to weapons, passives, rewards, future affixes, buffs, card-like effects, room effects, and cross-system outcomes.

The current project does not yet contain a general runtime buff system. This document deliberately separates the infrastructure already justified by existing gameplay from future runtime-effect infrastructure that must be introduced only with a real gameplay consumer.

## Current content pipeline

### Static definitions

Static content is represented by typed Godot `Resource` definitions under `res://content/`.

- `WeaponDefinition` describes weapon identity, ordering, presentation, maximum level, and runtime factory reference.
- `PassiveDefinition` describes passive identity, ordering, presentation, maximum level, and attribute contributions.
- `WeaponDefinitions` and `PassiveDefinitions` are read-only catalog facades.
- `ResourceCatalog` discovers `.tres` and `.res` files recursively and sorts directory entries before loading.

Adding a normal weapon or passive must not require editing a central static array. Duplicate IDs, invalid level descriptions, missing runtime implementations, and unknown attribute references are catalog validation errors.

### Runtime ownership

Static definitions are shared and must be treated as immutable. Runtime state is owned elsewhere:

- weapon/passive levels are owned by `BuildState`;
- weapon runtime nodes are owned by `WeaponManager`;
- reward choices are represented internally by `RewardOption`;
- battle transition results are represented by `BattleResult` and typed `BattleEffect` commands.

Catalogs must never own duration, stack count, source entity, target entity, cooldown state, or other per-instance mutable data.

### Attribute aggregation

Numeric passives contribute to named build attributes through `BuildAttributes`.

Current attributes are:

- `damage_multiplier`
- `cooldown_multiplier`
- `move_speed_multiplier`
- `pickup_radius_multiplier`
- `sync_max`
- `sync_regen_multiplier`
- `gold_multiplier`

A new passive that only contributes to existing attributes should require a new `PassiveDefinition` resource and no new `BuildState` branch. A new attribute still requires an explicit attribute definition, base value, bounds, runtime consumer, tests, and presentation rule.

### Reward boundary

`RewardOption` and `RewardResolution` are the typed reward model. `RewardService` performs validation and mutation using these types.

`BattleScene`, `GridScene`, and `RewardOverlay` still use Dictionary-shaped reward data through explicit compatibility adapters. This is a temporary migration boundary, not the target architecture. New reward kinds must be implemented in the typed model first and must not add more ad-hoc Dictionary keys to scene code.

## Future runtime-effect model

The first real timed, stacked, triggered, or entity-specific effect should introduce the following minimal model.

### EffectDefinition

A shared, immutable static definition resolved through an effect catalog.

It may describe:

- stable content ID and presentation;
- duration policy;
- stacking policy;
- tags;
- attribute modifiers;
- subscribed event phases;
- action or command definitions;
- optional specialized behavior primitive.

It must not contain mutable runtime duration, stack count, owner, source, or cooldown state.

### EffectInstance

A runtime value owned by one effect host or entity.

Minimum identity fields:

- stable instance ID;
- definition ID;
- source entity or source object ID;
- owner/target entity or host ID;
- stack count;
- remaining duration or turns;
- application sequence number;
- explicitly versioned runtime state when unavoidable.

An effect catalog may locate the static definition for an instance. It must not become the owner of the instance itself.

### EffectHost or ECS component

Each runtime owner stores its own effect instances.

In the current Godot project, the initial implementation should be a lightweight `EffectHost` Node or RefCounted component. Its external contract should be compatible with a future ECS dynamic buffer:

- add an instance;
- find by instance ID or definition ID;
- apply stacking policy;
- remove by instance/source/tag;
- expose read-only snapshots;
- enumerate listeners by event phase.

Do not create one ECS component type for every content effect. Separate structural states may become dedicated components only when multiple systems need to query them directly and frequently.

### EffectSystem

The system owns lifecycle rules, not content catalogs and not scene UI.

Responsibilities:

- validate application;
- create and attach instances;
- apply stack/refresh/replace rules;
- advance time or turn duration;
- remove expired instances;
- collect attribute modifiers;
- collect reactions for a gameplay event;
- emit typed gameplay commands;
- produce deterministic debug traces.

### Event phases

Trigger-heavy content must not use signal connection order or Dictionary iteration order as gameplay ordering.

Before card-like, relic-like, or reaction-heavy content is added, define explicit event phases. A combat damage flow may use phases such as:

1. request validation;
2. base value construction;
3. outgoing flat modifiers;
4. outgoing multipliers;
5. incoming modifiers;
6. mitigation or block;
7. state mutation;
8. after-damage reactions;
9. death resolution;
10. after-death reactions.

Pure calculation phases may transform a value but must not produce side effects. Reaction phases produce typed commands and derived events.

### Event queue and causality

Derived events must enter a deterministic queue instead of recursively invoking arbitrary handlers.

Every gameplay event should carry:

- event ID;
- root and parent event IDs;
- source and target IDs;
- originating effect instance ID when applicable;
- phase;
- priority;
- application or sequence order;
- causality depth.

The queue must define stable ordering and limits for recursion, repeated activation, and maximum causal depth.

### Typed commands

Cross-system effects should be represented as domain commands. Do not build one universal command enum containing every future behavior.

Expected domains may include:

- combat commands;
- build commands;
- reward commands;
- grid commands;
- presentation cues.

Presentation cues must not own authoritative gameplay mutation.

## Content-authoring rule

Normal content should be composed from existing definitions, attributes, conditions, triggers, actions, calculators, and commands.

A new script is justified when the content introduces a genuinely new behavior primitive that cannot be expressed safely through existing primitives. Adding a different number, duration, target filter, stack limit, trigger phase, or combination of existing actions is not sufficient reason for a new script class.

## Pre-content gate

Large-scale content production can begin when all applicable items below are true:

- content resources are automatically discovered and deterministically ordered;
- catalog validation runs in the headless smoke test;
- runtime factories no longer branch on concrete content IDs;
- common passive values use attribute aggregation rather than ID-specific formulas;
- reward selection and resolution have typed domain objects;
- scene compatibility adapters are isolated and scheduled for removal;
- existing gameplay passes editor, headless, and manual regression testing;
- the first triggered or timed effect is implemented through the EffectDefinition/EffectInstance/EffectHost boundary;
- explicit event phases exist before multiple effects can react to the same event;
- deterministic execution and causality guards exist before effects can generate recursive events.

## Deferred work

The following should not be implemented speculatively in this PR:

- a universal visual effect graph;
- a full ECS migration;
- a generic elemental-reaction engine;
- networking or rollback infrastructure;
- hot-reload support for arbitrary runtime effect definitions;
- a universal command bus.

These systems require concrete gameplay cases and acceptance tests. Their future implementations must preserve the boundaries defined above.
