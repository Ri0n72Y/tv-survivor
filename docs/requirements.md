# Game Requirements

This document is the current Requirement authority for the project. It describes intended outcomes and constraints, not the current code structure.

## Product direction

Build a small, replayable 2D survivor-like prototype in Godot 4.x + GDScript where an abstract exploration structure and real-time local battles form one continuous decision loop.

The structure layer must not become a travel menu. The player should read incomplete information, choose where to go, spend or preserve resources, accept risk, and see battle outcomes change later exploration.

The battle layer must not become an isolated minigame. Conditions chosen or accumulated in exploration must affect local battle, and meaningful battle results must return to the structure layer.

## Current playable loop to preserve during refactoring

Unless a later Requirement explicitly changes them, refactoring must preserve the currently accepted prototype capabilities:

- abstract/tree-like node exploration with hidden/revealed/cleared state and constrained connections;
- movement between valid connected nodes, camera follow/centering, and minimap feedback;
- resource/reward nodes and battle rooms;
- task, search, elite, and Boss battle flows;
- real-time automatic-weapon combat;
- synchronization/sync state as a meaningful battle resource;
- weapon and passive build progression with slot and level limits;
- paid and free reward paths with invalid reward rejection;
- battle results returning to the exploration/run state;
- extraction or room completion where the room design calls for it;
- Boss victory ending the run.

## Exploration requirements

Every meaningful structure-layer action should change at least one of:

- information;
- resources;
- risk;
- structure/path availability;
- state;
- narrative/context.

Unknown information should create judgment, not arbitrary punishment. Risk should support the question of whether to continue, redirect, or stop. Retreat, extraction, or abandoning optional value may be valid strategic choices rather than automatic failure.

Repeated or already-known structure content should be compressible or faster than first discovery; the system should not turn repeated exploration into low-value manual travel.

## Content and presentation constraints

- Core project logic remains text-based and diff-friendly.
- Prototype visuals may remain geometric/placeholders while mechanics are being validated.
- Ordinary content variation should prefer data/resources and existing behavior primitives over new script classes.
- New gameplay systems are not justified solely because they may be useful for future content.

## Refactoring constraints

- Refactoring must not silently redesign gameplay.
- Existing code is evidence of current implementation, not authority over this Requirement.
- If a refactor discovers that preserving the intended behavior requires a material design decision, that decision belongs in Design before implementation continues.
- Do not create compatibility layers, factories, event systems, generalized effect engines, or module boundaries without a current consumer that requires them.
- Untouched legacy code does not need a retroactive Spec.

## Verification direction

Verification follows the actual change surface. Protect user-observable behavior, non-trivial state transitions, important data/contracts, and reproduced regressions. Do not add tests only to increase counts, symmetry, or coverage percentage.
