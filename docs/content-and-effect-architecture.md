# Content and Effect Implementation Notes

> **Status: implementation reference / legacy technical note.**
>
> This document records implementation patterns and earlier architecture thinking around content, rewards, buffs, and effects. It is **not current System Design authority** and must not be used by itself to introduce new architecture.
>
> When one of these capabilities enters a new Delivery or Validation Scope, inspect the current implementation first. If the change requires material technical decisions, establish or update `docs/system-design/<capability>.md`; then project the implementation contract into Spec. Existing details below may be reused only where they still match the code and current upstream authority.

## Purpose

This note preserves two kinds of information:

1. **current implementation context** that helps explain the existing content pipeline; and
2. **historical architecture proposals** that were considered before the current game-design-first SDD workflow existed.

These categories are intentionally separated below. Historical proposals are context, not commitments.

## Current implementation context

### Static definitions

The current content pipeline represents static weapon and passive content with typed Godot `Resource` definitions under `res://content/`.

- `WeaponDefinition` describes weapon identity, ordering, presentation, maximum level, and runtime factory reference.
- `PassiveDefinition` describes passive identity, ordering, presentation, maximum level, and attribute contributions.
- `WeaponDefinitions` and `PassiveDefinitions` act as read-only catalog facades.
- `ResourceCatalog` discovers `.tres` and `.res` files recursively and sorts directory entries before loading.

The current implementation allows a normal weapon or passive to be added without editing a central static array. Catalog validation covers duplicate IDs, invalid level descriptions, missing runtime implementations, and unknown attribute references.

### Runtime ownership

The current implementation keeps shared static definitions separate from mutable runtime state:

- weapon/passive levels are owned by `BuildState`;
- weapon runtime nodes are owned by `WeaponManager`;
- reward choices are represented internally by `RewardOption`;
- battle transition results are represented by `BattleResult` and typed `BattleEffect` commands.

Catalog definitions do not own per-instance duration, stack count, source entity, target entity, cooldown state, or equivalent mutable runtime data.

### Attribute aggregation

Numeric passives currently contribute to named build attributes through `BuildAttributes`.

Current attributes are:

- `damage_multiplier`
- `cooldown_multiplier`
- `move_speed_multiplier`
- `pickup_radius_multiplier`
- `sync_max`
- `sync_regen_multiplier`
- `gold_multiplier`

Within the existing implementation, a passive that only contributes to an existing attribute can be represented by a new `PassiveDefinition` resource without adding a `BuildState` branch. Introducing a genuinely new attribute has a wider impact surface and should be handled through the current Requirement / applicable System Design / Spec workflow rather than inferred from this note.

### Reward boundary

`RewardOption` and `RewardResolution` are the current typed reward model. `RewardService` performs validation and mutation using these types.

`BattleScene`, `GridScene`, and `RewardOverlay` also retain Dictionary-shaped reward data through compatibility adapters. Earlier architecture work treated this as a migration boundary. That historical intent is recorded here, but this document does not require a future migration or prescribe when it must occur.

### Buff/effect implementation has moved on

An earlier version of this document stated that the project did not yet contain a runtime buff system. That statement is now stale.

The repository currently contains a lightweight `BuffDefinition` / `BuffInstance` / `BuffContainer` / `BuffSystem` implementation used by synchronization-related battle states. See `docs/buff_system.md` and the current code under `scripts/battle/buffs/` for implementation context.

This existing buff implementation does **not** automatically validate the broader historical effect architecture described below.

## Historical runtime-effect proposal — non-authoritative

The following model was proposed before a concrete general effect capability entered the current SDD workflow. It is preserved as design history only.

**Do not implement or extend this model solely because it appears in this document.** If timed, stacked, triggered, card-like, relic-like, entity-specific, or cross-system effects enter current Scope, reassess the real gameplay case and current code first. Any material architecture that remains useful belongs in a new or updated System Design.

### EffectDefinition

The historical proposal described a shared, immutable static definition resolved through an effect catalog. Candidate fields included:

- stable content ID and presentation;
- duration policy;
- stacking policy;
- tags;
- attribute modifiers;
- subscribed event phases;
- action or command definitions;
- optional specialized behavior primitive.

The proposal kept mutable runtime duration, stack count, owner, source, and cooldown state outside the static definition.

### EffectInstance

The historical proposal described a runtime value owned by one effect host or entity, with candidate identity/state such as:

- stable instance ID;
- definition ID;
- source entity or source object ID;
- owner/target entity or host ID;
- stack count;
- remaining duration or turns;
- application sequence number;
- explicitly versioned runtime state when unavoidable.

### EffectHost or ECS component

The historical proposal considered a lightweight `EffectHost` Node or RefCounted component whose external operations could include:

- add an instance;
- find by instance ID or definition ID;
- apply stacking policy;
- remove by instance/source/tag;
- expose read-only snapshots;
- enumerate listeners by event phase.

It also considered future ECS compatibility. **No ECS compatibility requirement follows from this note.**

### EffectSystem

The historical proposal assigned lifecycle responsibilities such as:

- validate application;
- create and attach instances;
- apply stack/refresh/replace rules;
- advance time or turn duration;
- remove expired instances;
- collect attribute modifiers;
- collect reactions for a gameplay event;
- emit typed gameplay commands;
- produce deterministic debug traces.

These are candidate responsibilities from the old architecture discussion, not current module ownership.

### Event phases

The historical proposal considered explicit event phases for trigger-heavy gameplay rather than relying on signal connection order or Dictionary iteration order. One example damage flow was:

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

No current Requirement or System Design commits the project to this phase model.

### Event queue and causality

The historical proposal also considered deterministic queued derived events carrying information such as:

- event ID;
- root and parent event IDs;
- source and target IDs;
- originating effect instance ID when applicable;
- phase;
- priority;
- application or sequence order;
- causality depth.

Limits for recursion, repeated activation, and causal depth were part of that proposal. They remain unimplemented design context unless a future scoped capability justifies them.

### Typed commands

The historical proposal favored domain-specific cross-system commands over one universal command enum. Candidate domains included:

- combat commands;
- build commands;
- reward commands;
- grid commands;
- presentation cues.

The existing project already uses some typed result/effect objects, but this historical list does not require a universal command architecture.

## Historical content-authoring guidance

Earlier architecture work preferred normal content to reuse existing definitions, attributes, conditions, triggers, actions, calculators, and commands, with new script classes reserved for genuinely new behavior primitives.

This remains useful as a Ponytail-compatible heuristic, but it is not an independent architecture authority. New content should follow the current Game Design, Requirement, applicable System Design, Spec, and actual implementation constraints.

## Historical pre-content gate — non-authoritative

An earlier roadmap proposed waiting for the following conditions before large-scale content production:

- content resources automatically discovered and deterministically ordered;
- catalog validation in the headless smoke test;
- runtime factories no longer branching on concrete content IDs;
- common passive values using attribute aggregation rather than ID-specific formulas;
- typed reward selection and resolution;
- isolated scene compatibility adapters;
- editor, headless, and manual regression coverage for existing gameplay;
- a general EffectDefinition/EffectInstance/EffectHost boundary;
- explicit event phases for multiple reactions;
- deterministic execution and causality guards for recursive events.

This list is retained as historical planning context only. It is **not a current Requirement, acceptance checklist, or prerequisite for future content work**.

## Historical deferred-work list

Earlier work explicitly deferred:

- a universal visual effect graph;
- a full ECS migration;
- a generic elemental-reaction engine;
- networking or rollback infrastructure;
- hot-reload support for arbitrary runtime effect definitions;
- a universal command bus.

These items remain neither required nor prohibited by this note. If any becomes relevant, it must enter the current SDD flow from an actual Game Design / Requirement need rather than from this historical list.
