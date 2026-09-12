# Reward Flow

> Status: current System Design for the existing reward/build baseline.
>
> This document records the technical boundary for reward generation, validation, purchase, and application. It does not fix the future reward catalog, UI presentation, or economy values.

## Scope

This design covers the owned baseline where array/local gameplay can produce free or paid build rewards, invalid rewards are rejected, and failed application must not consume resources incorrectly.

It covers the typed reward model and its current compatibility boundary with scene/UI Dictionary data.

## Core model

`RewardOption` is the typed reward choice value. It identifies the reward kind, content ID, target level, weight/tags, and presentation text needed by current callers.

`RewardResolution` is the typed result of validation/application. It communicates success or rejection and the resolved reward result.

`RewardService` owns reward-domain validation and mutation. Scenes and UI should request reward work through this domain boundary rather than duplicating content validation or build mutation rules.

`BuildState` remains the owner of mutable build resources and levels.

## Reward generation

`RewardService.build_options()` derives currently valid weapon/passive candidates from the static content catalogs and the current `BuildState`.

`RewardService.draw_options()` accepts a caller-provided `RunRngStream` and delegates weighted/non-repeating selection to `RandomPool`.

The reward domain does not choose its own global RNG source. The caller supplies the stream appropriate to the reward source.

## Validation and application

Reward mutation follows this order:

1. validate the typed option against the current build state;
2. for paid rewards, validate the cost and spend the resource only after reward validation succeeds;
3. apply the reward to `BuildState`;
4. if paid application fails after spending, refund the spent resource;
5. return a `RewardResolution` describing the outcome.

Current validation includes rejecting cases such as:

- null/unknown reward options;
- unknown weapon or passive IDs;
- invalid target levels;
- level regression or duplicate/non-progressing upgrades;
- adding new content when the relevant slot limit is full, unless the caller explicitly permits slot bypass;
- negative cost;
- insufficient gold.

This ordering protects the owned Requirement that rejected or failed rewards do not incorrectly consume resources.

## Compatibility boundary

The typed reward model is the domain boundary. Some current scene/UI callers still use Dictionary-shaped reward values.

`RewardOption.to_legacy_dictionary()` / `from_legacy_dictionary()` and the Dictionary wrappers in `RewardService` are explicit compatibility adapters around the typed core.

New reward behavior should be added to the typed model first. Do not add new ad-hoc Dictionary keys directly in scene code as a substitute for extending the domain contract.

This does not create a requirement to remove all compatibility adapters immediately. Their removal becomes implementation Scope only when the affected callers are actually refactored.

## Ownership and dependency direction

```text
static content catalogs
        ↓
RewardService ← caller-provided RunRngStream
        ↓
RewardOption / RewardResolution
        ↓
BuildState

scene / UI
   ↕ compatibility adapters where still needed
RewardService
```

Scenes may coordinate when a reward is offered or displayed, but reward validity and authoritative build mutation stay below that presentation boundary.

## Invariants

- `BuildState` is the authoritative mutable owner of build resources/levels.
- Reward validation precedes paid mutation.
- A failed paid application restores the spent resource.
- Reward selection uses the RNG stream supplied by its caller.
- Typed reward objects are the domain model; Dictionary values are compatibility representations.
- Current weapon/passive identities, counts, prices, and reward pools are content choices, not System Design commitments.

## Relationship to future changes

A new reward kind or economy rule may require Requirement/Game Design work before this document changes. If it only reuses the existing technical boundary, its Spec should rely on this System Design rather than inventing a new reward architecture.
