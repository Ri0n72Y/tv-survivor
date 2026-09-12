# Content Model

> Status: current System Design for the existing content/build baseline.
>
> This document records the technical boundary that supports the currently owned weapon/passive build capability. It does not define future gameplay content or a universal effect framework.

## Scope

This design covers:

- static weapon/passive definitions;
- content discovery and validation;
- ownership of mutable build/runtime state;
- passive attribute aggregation;
- the boundary between reusable content definitions and runtime behavior.

Reward purchase/application is documented separately in `reward-flow.md`. Buff runtime is documented in `buff-runtime.md`.

## Static content definitions

Static content is represented by typed Godot `Resource` definitions under `res://content/`.

- `WeaponDefinition` owns weapon identity, presentation, ordering, maximum level, level descriptions, and the runtime factory reference needed to create the weapon behavior.
- `PassiveDefinition` owns passive identity, presentation, ordering, maximum level, level descriptions, and attribute contributions.
- `WeaponDefinitions` and `PassiveDefinitions` provide read-only catalog access to loaded definitions.
- `ResourceCatalog` discovers `.tres` and `.res` resources recursively and uses deterministic directory ordering before loading.

A normal weapon or passive should be added through content resources rather than by extending a central hard-coded content array.

Catalog validation is responsible for rejecting invalid static definitions such as duplicate IDs, malformed level data, missing required runtime implementations, or unknown attribute references.

## Runtime ownership

Static definitions are shared configuration and must be treated as immutable at runtime.

Mutable state is owned by runtime systems:

- `BuildState` owns weapon/passive levels, slots, gold, score, and build snapshots;
- `WeaponManager` owns instantiated weapon runtime nodes;
- gameplay scenes consume the build/runtime state but do not become the canonical owner of static content definitions.

Content catalogs must not own mutable per-run or per-instance state such as current levels, duration, stack count, cooldowns, source objects, or target objects.

## Build attributes

Numeric passive effects are aggregated through `BuildAttributes` rather than through passive-ID-specific branches in `BuildState`.

The current attribute set includes:

- `damage_multiplier`
- `cooldown_multiplier`
- `move_speed_multiplier`
- `pickup_radius_multiplier`
- `sync_max`
- `sync_regen_multiplier`
- `gold_multiplier`

A passive that only contributes to an existing attribute should normally require only a new `PassiveDefinition` resource.

Introducing a new build attribute is a technical change because it needs a defined base value, bounds/combination semantics, at least one runtime consumer, and presentation/verification appropriate to the affected gameplay. If that change introduces a material new ownership or data-flow decision, update this System Design before writing the implementation Spec.

## Runtime behavior primitives

Content data may select or configure runtime behavior that already exists, but ordinary content additions should not create a new script type merely because their numbers, labels, durations, targets, or combinations differ.

A new runtime implementation is justified when the content requires a genuinely new behavior primitive that cannot be expressed safely through the existing content model and runtime consumers.

This rule is a boundary against content-ID branching and speculative class proliferation; it is not a requirement to build a generic effect engine.

## Invariants

- Static content definitions remain immutable during a run.
- Mutable build state has a runtime owner and is not stored in catalogs.
- Normal content discovery is data-driven and deterministically ordered.
- Adding ordinary content that uses existing behavior/attributes does not require a new `BuildState` branch.
- The content model does not imply that Sync, any current weapon/passive set, or any future effect system is permanent Game Design.

## Relationship to future changes

When a new content capability changes ownership, state shape, catalog rules, or the definition/runtime boundary, update this document if those decisions are material and durable.

Do not revive the former speculative `EffectDefinition` / ECS / universal event-queue design merely because the old document contained it. Such architecture must be justified again by a current Requirement and concrete consumers.
