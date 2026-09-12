# Buff Runtime

> Status: current System Design for the existing lightweight battle-buff implementation.
>
> This document records the technical boundary currently used by Sync-related status effects. It does not make Sync a permanent gameplay requirement and does not define a universal Effect/ECS architecture.

## Scope

This design covers the current lightweight runtime used to store and advance timed/stacked battle status.

The current implementation exists to support concrete gameplay consumers. It should remain small unless a new Requirement introduces behavior that the existing boundary cannot express safely.

## Components

### `BuffDefinition`

Static buff definition data, including identity/presentation and the configuration needed by the current runtime such as maximum stacks, tick interval, and duration.

Definitions are configuration. They do not own mutable per-instance timing or stack state.

### `BuffInstance`

Mutable runtime state for one active buff, including current stacks, tick timing, remaining duration, source identity, and extension data used by the current consumer.

### `BuffContainer`

Owns the active buff collection for one runtime owner identified by `owner_id`.

The container is responsible for storage and buff add/remove/display access. It is not the authoritative gameplay scene itself.

### `BuffSystem`

Registers active containers and advances their buff instances.

`process(delta)` emits three event collections for each actual tick:

1. `before_tick`
2. `tick`
3. `after_tick`

Expired instances are removed after advancement.

The emitted events currently contain the owner ID, buff ID, stack count, source ID, and extension data needed by the gameplay consumer.

## Mutation boundary

The buff runtime does not directly perform arbitrary scene mutation such as dealing damage, moving nodes, or changing presentation.

Gameplay code consumes the events emitted by `BuffSystem` and applies the concrete effect in the appropriate gameplay owner.

This keeps status storage/timing separate from scene-specific behavior without introducing a generic command bus or ECS.

## Current consumer

Sync-related battle state currently uses this runtime, including states such as `信号弱` and `同步稳定`.

That usage is implementation evidence for the buff boundary only. The Requirement classifies Sync as provisional prototype content, so this System Design must not be read as a commitment that Sync itself remains in the final first world bubble or in future world bubbles.

## Invariants

- Static buff definition data is separate from mutable `BuffInstance` state.
- Each runtime owner stores its active status through a `BuffContainer` rather than through the static catalog.
- `BuffSystem` owns timing/expiration traversal for registered containers.
- Concrete gameplay mutation remains with gameplay consumers of emitted events.
- The current three tick phases describe the implemented protocol; they are not a general-purpose event-phase framework for every future effect.
- No ECS, universal effect graph, recursive event queue, or generic command bus is implied by the current normative design.

## Discussion

> Non-authoritative. These points preserve future technical reasoning and must not be projected directly into Spec/Task.

### Display boundary

`BuffContainer.get_display_buffs()` already exposes presentation-oriented snapshots of active buffs. If a future buff/status UI is added, reading that snapshot is a plausible default direction because it avoids making UI the owner of runtime status.

The exact UI contract is not decided here; it should be revisited when a status display enters Requirement Scope.

### Generalized runtime-effect model

If future in-scope content grows beyond the current lightweight buff runtime into richer timed, stacked, triggered, or cross-system effects, one candidate model is:

- **EffectDefinition** — shared immutable static definition for identity, presentation, duration/stack policy, tags, modifiers, trigger subscriptions, and reusable actions;
- **EffectInstance** — mutable runtime value carrying definition identity, source/owner identity, stack count, remaining duration/turns, application sequence, and only the runtime state that cannot remain static;
- **EffectHost** — runtime owner/container for active effect instances, exposing add/find/stack/remove/snapshot/listener operations;
- **EffectSystem** — lifecycle and execution service responsible for validation, application, stacking/refresh/replace behavior, expiration, modifier collection, reaction collection, and execution tracing.

A catalog could resolve static `EffectDefinition` data for an instance, but it should not own mutable `EffectInstance` state.

This model is a candidate direction, not a commitment to rename or replace the current Buff classes. The smallest migration path should be chosen only when concrete consumers prove the existing boundary insufficient.

### ECS compatibility

A future `EffectHost` could be represented by a lightweight Node/RefCounted component in the current Godot architecture while keeping an external contract that could later map to an ECS dynamic buffer if the project actually adopts ECS.

Do not create one ECS component type per content effect. Dedicated structural components would only make sense when multiple systems need frequent direct queries of that state.

ECS compatibility is a possible long-term property, not a current migration target.

### Explicit event phases

Trigger-heavy content may eventually need deterministic execution phases instead of relying on signal connection order or Dictionary iteration order.

A damage flow, for example, could distinguish phases such as:

1. request validation;
2. base value construction;
3. outgoing flat modifiers;
4. outgoing multipliers;
5. incoming modifiers;
6. mitigation/block;
7. authoritative state mutation;
8. after-damage reactions;
9. death resolution;
10. after-death reactions.

Pure calculation phases could transform values without side effects, while reaction phases could emit explicit follow-up work.

These phase names and ordering are illustrative. They must be redesigned around the concrete combat/events that actually enter Scope.

### Event queue and causality

If effects begin generating derived events recursively, direct nested handler calls may become difficult to order and debug.

A possible future solution is a deterministic event queue carrying data such as:

- event ID;
- root/parent event IDs;
- source/target IDs;
- originating effect instance ID where applicable;
- phase and priority;
- application/sequence order;
- causality depth.

Such a queue could define stable ordering plus limits for recursion, repeated activation, and causal depth. It should not be introduced until actual recursive/trigger interactions require those guarantees.

### Typed domain commands

Cross-system effects may eventually need explicit domain commands rather than arbitrary scene mutation. Candidate domains include combat, build, reward, grid, and presentation cues.

If this becomes necessary, prefer small domain-specific command contracts over one universal command enum containing every imaginable behavior. Presentation cues should remain non-authoritative for gameplay mutation.

### Deferred alternatives

The following remain discussion-only until concrete Requirements justify them:

- a universal visual effect graph;
- full ECS migration;
- a generic elemental/reaction engine;
- networking or rollback infrastructure;
- hot reload for arbitrary runtime effect definitions;
- a universal command bus.

## Relationship to future changes

If a new in-scope mechanic needs materially different trigger ordering, cross-system reactions, recursive derived events, or a different effect ownership model, revisit the Discussion above and the current implementation together.

Promote only the selected, revalidated conclusions into the normative sections of this System Design before projecting the corresponding Spec. Reuse the current lightweight runtime when it remains sufficient.
