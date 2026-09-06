# Reward Flow Spec

## Behavior

- Reward candidates are represented as `RewardOption` from generation through UI selection and application.
- Exploration chest selection performs one paid purchase; successful purchase opens the chest.
- Battle search chest opening spends its cost once; selected reward is then applied without another charge.
- Elite reward selection applies for free.
- Invalid reward options are rejected without unintended state mutation.

## Boundary and ownership

- `RewardService`: candidate generation, draw, validation, application, paid transaction.
- `RunState`: typed facade over the active `BuildState` and run RNG stream.
- `RewardOverlay`: presentation/selection only.
- `GridScene` and `BattleScene`: decide when a reward interaction starts and which payment semantic applies.

## Contracts

- `RewardOverlay.reward_selected` carries `RewardOption`.
- `RewardOverlay.show_choices` accepts `Array[RewardOption]`.
- `RunState.build_reward_options`, `draw_reward_options`, `purchase_reward_option`, and `apply_reward_option` are the reward facade.
- Reward outcomes are read from `RewardResolution` properties.
- No reward-domain Dictionary compatibility conversion remains.

## Allowed change surface

`RewardOption`, `RewardResolution`, `RewardService`, `RunState`, `RewardOverlay`, reward call sites in `GridScene`/`BattleScene`, and the existing content-foundation smoke check.

Do not introduce reward coordinators, interfaces, factories, event buses, or new content abstractions.

## Failure behavior

Unknown content, invalid target level, duplicate/downgrade, full slot acquisition, negative cost, or insufficient gold returns a failed `RewardResolution`. Existing chest/payment timing must remain unchanged.

## Verification

Keep one smoke path that checks typed paid success, duplicate rejection, oversized-level rejection, and scene loading. Remove checks whose only purpose is preserving the legacy Dictionary adapter.
