# Reward Flow Design

## Purpose

Rewards are one gameplay transaction shared by exploration chests, battle chests, and free elite rewards. The game should have one domain representation from generation through selection and application.

## Domain model

- `RewardOption` is the immutable selectable reward value.
- `RewardResolution` is the result of validation/application.
- `RewardService` owns reward generation, validation, application, and paid purchase transactions.
- `RunState` exposes the current run/build state to reward operations.
- `RewardOverlay` only displays `RewardOption` values and returns the selected option. It does not translate gameplay data.

Dictionary-shaped reward objects are not part of the reward domain.

## Payment semantics

Existing player-visible timing is preserved:

- exploration chest: gold is spent when the selected option is successfully purchased;
- battle search chest: gold is spent when the chest is opened, before selection;
- elite reward: no gold cost.

Rejected reward application must not create a second charge. A paid purchase performed by `RewardService` refunds the charge if application fails after payment.

## Content rules

Normal weapon/passive reward choices come from the registered content definitions and current `BuildState`. Unknown content, invalid levels, duplicate/downgrade choices, and illegal slot acquisition are rejected.

Reward presentation text lives on `RewardOption`; UI must not reconstruct reward identity from ad-hoc keys.
