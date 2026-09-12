# Deterministic RNG

> Status: current cross-cutting System Design for gameplay randomness.
>
> This document records the technical boundary that keeps gameplay randomness reproducible and isolated from non-gameplay presentation randomness. It does not imply that every registered stream corresponds to a permanent gameplay feature.

## Scope

This design covers:

- run-level deterministic RNG ownership;
- named gameplay streams;
- separation of gameplay and visual randomness;
- RNG state save/restore;
- deterministic pool drawing through `RandomPool`.

It does not define the complete game save format or make legacy random-map behavior part of current Game Design.

## Ownership

`RunState` owns the run seed exposed as `grid_seed` and the active `RunRngManager`.

Gameplay code requests deterministic streams through:

- `RunState.rng_stream(stream_name)`; or
- the owned `RunRngManager` when the lower-level API is appropriate.

`RunRngManager` lazily creates `RunRngStream` instances from the run seed plus stream name and keeps their mutable stream state for the current run.

A run reset starts the manager from the selected run seed. `RunState.rng_state()` and `restore_rng_state()` expose the current RNG state boundary.

## Named streams

`RunRngManager` currently registers these stream names:

- `map.route`
- `grid.node`
- `event.content`
- `battle.spawn`
- `battle.affix`
- `chest.type`
- `chest.reward`
- `reward.weapon`
- `reward.passive`
- `shop.refresh`
- `meta.unlock`

The stream registry is a technical namespace, not a Game Design roadmap. A registered stream may support current code, legacy code, or a capability that is not presently selected into development Scope.

In particular, `map.route` does not make arbitrary random main-map topology a current Requirement; the current Game Design prefers authored main-map structure.

## Stream isolation

Gameplay systems should use a stream whose name represents that random domain rather than sharing one mutable global gameplay RNG.

A new independent gameplay-random domain should normally receive its own stream name so draws in one domain do not reorder the results of unrelated domains.

Existing stream names should not be casually repurposed for unrelated random behavior because that changes replay/debug determinism for existing consumers.

## Visual randomness

UI, animation, particles, audio jitter, and other non-authoritative presentation must not consume gameplay RNG state.

`RunRngManager.create_visual_rng()` or an equivalent local non-deterministic RNG may be used for presentation as long as its draws cannot affect authoritative map, battle, reward, economy, or other gameplay results.

## Save and restore boundary

`RunRngManager.save_state()` stores:

- the run seed;
- the state of every created named stream.

Each stream state includes the data needed by `RunRngStream` to continue its deterministic sequence.

`restore_state()` reconstructs the manager from that RNG state, and `RunState.restore_rng_state()` synchronizes `grid_seed` with the restored manager.

This is only the RNG-state contract. It is not a complete save-game design. Map state, build state, opened rewards, encounter state, and other gameplay persistence belong to their own owners and require separate current System Design when full save/load enters Scope.

## RandomPool

`scripts/core/RandomPool.gd` provides deterministic pool selection when supplied with a `RunRngStream`.

Current supported concerns include:

- weighted entries through `weight`;
- non-repeating draws through `allow_repeats = false`;
- tag filtering through `required_tags` / `blocked_tags`;
- unlock filtering through `unlocked_ids`;
- previously drawn filtering through `drawn_ids`.

Callers choose the appropriate named stream. `RandomPool` does not own the run seed or select a global stream by itself.

## Invariants

- Authoritative gameplay randomness comes from run-owned deterministic streams.
- Presentation randomness cannot advance gameplay RNG state.
- Independent random domains should not accidentally consume each other's sequence.
- RNG state can be serialized/restored independently of the rest of run persistence.
- A stream name is a technical namespace, not a permanent gameplay/content commitment.
- Gameplay code should not call `randomize()`, `Array.shuffle()`, or equivalent system randomness when the result affects authoritative gameplay.

## Relationship to future changes

When a new feature only needs an independent deterministic stream, extending the registered stream namespace does not by itself require a new architecture.

If a change alters seed ownership, stream derivation, replay semantics, persistence, or cross-system determinism, update this System Design before projecting the corresponding Spec.
