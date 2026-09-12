# Deterministic RNG

> Status: current cross-cutting System Design for gameplay randomness.
>
> This document records the technical boundary that keeps gameplay randomness reproducible and isolated from non-gameplay presentation randomness. It does not imply that every declared stream name corresponds to a permanent gameplay feature.

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

`RunRngManager` currently declares conventional/default names for these random domains:

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

These constants/default names are a technical namespace convention, not a closed registry: `get_stream(stream_name)` lazily derives a stream from the run seed and the supplied name.

The declared names are also not a Game Design roadmap. A name may support current code, legacy code, or a capability that is not presently selected into development Scope.

In particular, `map.route` does not make arbitrary random main-map topology a current Requirement; the current Game Design prefers authored main-map structure.

## Stream isolation

Gameplay systems should use a stream whose name represents that random domain rather than sharing one mutable global gameplay RNG.

A new independent gameplay-random domain should normally receive its own stable stream name so draws in one domain do not reorder the results of unrelated domains.

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

## Discussion

> Non-authoritative. These points preserve future technical reasoning and must not be projected directly into Spec/Task.

### Full save/load integration

If complete run persistence enters Requirement Scope, the RNG state will need to be coordinated with other persisted state rather than treated as a standalone save feature.

A plausible complete-run save may need to preserve at least:

- the current run seed;
- each created RNG stream state;
- pool state such as drawn/removed IDs where the pool itself has persistent semantics;
- current map/exploration state;
- opened or resolved reward state;
- build state and other run-owned gameplay state.

One candidate restore sequence is to restore the run seed/RNG streams before any system is allowed to perform new random draws, then restore the other authoritative run state before gameplay resumes.

The exact save schema, ownership, versioning, and restoration order are not settled here. They require a dedicated persistence System Design once save/load is selected into Scope.

### Replay and debugging

The current stream model supports reproducible domain-local random sequences, but the project does not yet define a complete replay contract.

If deterministic replay or detailed run debugging becomes important, open questions include:

- whether seed + stream state is sufficient for the desired replay boundary;
- whether external inputs/events must also be recorded;
- whether stream draw counts should be surfaced in debug traces;
- how version changes to stream derivation or content data should affect replay compatibility.

Do not add replay infrastructure until a concrete debugging, testing, or player-facing use case requires it.

### Pool evolution

Future reward/event pools may use richer metadata such as rarity, tags, synergies, classes, or build-direction hints. Prefer deterministic data/filtering rules over ad-hoc non-deterministic array manipulation.

Domain-specific eligibility still belongs with the owning gameplay/reward system; `RandomPool` should remain a small deterministic selection utility rather than becoming a universal content-rule engine.

## Relationship to future changes

When a new feature only needs an independent deterministic stream, extending the stream namespace does not by itself require a new architecture.

If a change alters seed ownership, stream derivation, replay semantics, persistence, or cross-system determinism, update this System Design before projecting the corresponding Spec.

Discussion may inform that work, but only promoted normative decisions are authoritative.
