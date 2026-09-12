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

- `ContentDefinition` provides common content identity, presentation, level, sort-order, tag, and basic validation fields.
- `WeaponDefinition` extends the content definition with weapon-specific level descriptions and the runtime factory reference needed to create weapon behavior.
- `PassiveDefinition` extends the content definition with passive-specific level descriptions and attribute contributions.
- `WeaponDefinitions` and `PassiveDefinitions` provide read-only catalog access to validated definitions.

A normal weapon or passive should be added through content resources rather than by extending a central hard-coded content array.

## Discovery and validation boundary

`ResourceCatalog` is the low-level loader. It recursively discovers `.tres` / `.res` files, sorts directory entries deterministically, loads resources, and reports load failures.

It does **not** own all content validation.

The typed catalog facades perform domain validation after loading:

- `WeaponDefinitions` rejects unexpected resource types, definition validation errors, and duplicate weapon IDs;
- `PassiveDefinitions` rejects unexpected resource types, definition validation errors, duplicate passive IDs, and unknown build-attribute references;
- definition classes validate their own local data constraints.

This separation should remain clear: resource discovery/loading belongs to `ResourceCatalog`; content-domain validity belongs to the relevant definition/catalog layer.

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
- Discovery/loading and domain validation remain separate responsibilities.
- Adding ordinary content that uses existing behavior/attributes does not require a new `BuildState` branch.
- The content model does not imply that Sync, any current weapon/passive set, or any future effect system is permanent Game Design.

## Discussion

> Non-authoritative. These points preserve future technical reasoning and must not be projected directly into Spec/Task.

### Scaling content production

If weapon/passive/content volume grows substantially, useful checks before large-scale authoring include:

- keeping automatic discovery and deterministic ordering;
- keeping catalog validation in headless verification;
- avoiding runtime factories that branch on concrete content IDs;
- expressing common passive values through reusable attributes rather than ID-specific formulas;
- keeping typed reward-domain objects between content and mutation;
- keeping compatibility adapters isolated rather than spreading legacy shapes through new code.

This is a scaling checklist, not a current release gate. Each item should be re-evaluated against the actual content workload when it becomes relevant.

### More expressive content primitives

Future content may require conditions, triggers, actions, calculators, tags, or other reusable behavior primitives beyond the current weapon/passive model.

A possible direction is to keep ordinary content data-driven while allowing a new script only for a genuinely new behavior primitive. The exact abstraction should be chosen from concrete content cases rather than by building a universal effect language in advance.

Generalized runtime effects, event phases, event queues, and ECS compatibility are discussed in `buff-runtime.md` because they concern runtime effect ownership and execution rather than static content discovery alone.

## Relationship to future changes

When a new content capability changes ownership, state shape, catalog rules, or the definition/runtime boundary, update this document if those decisions are material and durable.

Discussion may inform that work, but it does not become current architecture until the relevant Requirement selects the capability and the accepted conclusion is promoted into the normative sections above.
