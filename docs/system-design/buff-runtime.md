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
- No ECS, universal effect graph, recursive event queue, or generic command bus is implied by this design.

## Relationship to future changes

If a new in-scope mechanic needs materially different trigger ordering, cross-system reactions, recursive derived events, or a different effect ownership model, that is a new architecture decision. Update or replace this System Design before projecting the corresponding Spec.

Do not automatically revive the former speculative EffectDefinition/EffectHost/ECS/event-queue proposal. Reuse the current lightweight runtime when it is sufficient; introduce a larger boundary only for concrete current consumers.
