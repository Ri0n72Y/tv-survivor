# Development workflow

This repository uses a game-design-first SDD workflow for material changes and Ponytail `full` as the default implementation principle.

## Authority

The project authority chain is:

1. `docs/design/` — **Game Design**: what the game is trying to be, how it should feel, which gameplay ideas and content directions are being explored or selected.
2. `docs/requirements.md` — **Requirement**: the current version Scope extracted from Game Design; which designed capabilities are actually committed for implementation or validation now, including acceptance direction and explicit out-of-scope items when relevant.
3. `docs/system-design/<capability>.md` — **System Design**: the software/technical structure chosen to implement an in-scope Requirement, including ownership, data flow, lifecycle, interfaces, dependency direction, and material technical decisions.
4. `docs/specs/<capability>.md` — **Spec**: the agent-executable projection of the current Requirement and System Design for a capability being refactored or newly developed.
5. Task — executable development work derived from Requirement + System Design + Spec; keep it in the active issue/PR unless a durable task document is specifically useful.
6. Implementation — evidence of current behavior and constraints, not authority to redefine upstream Game Design, Requirement, or System Design.

This order is an authority and projection relationship, not a requirement that every small discussion create every document.

## Game Design rules

- Game Design precedes version scoping. It may contain future ideas, alternatives, content space, and concepts that are not yet committed to implementation.
- Do not force open-ended design exploration into Requirement, Spec, or Task merely because it has been discussed.
- Game Design should describe gameplay intent and content structure without being constrained by the current implementation unless a technical limitation is itself an intentional design constraint.
- If a version decision intentionally changes the game direction, update Game Design first rather than hiding the change in Requirement or code.

## Requirement rules

- Requirement is a **version Scope**, not the complete game design and not a snapshot of everything the current code happens to support.
- Extract Requirement only from sufficiently settled Game Design, or from a clearly stated design question that needs a prototype to settle it.
- Requirement states what the current version must implement, preserve, or validate; the observable completion direction; and relevant exclusions.
- A Requirement may select only part of the available Game Design. Unselected future Design remains valid Design but is not implementation scope.
- Do not place module ownership, interfaces, scene structure, data models, factories, service boundaries, or other software architecture decisions in Requirement.

### Delivery Scope vs Validation Scope

A Requirement may be one of two modes:

- **Delivery Scope** — implement a sufficiently settled design as a capability intended to remain in the project.
- **Validation Scope** — build the smallest useful prototype needed to answer a concrete game-design question or test a hypothesis.

A Validation Scope must state:

- the design question or hypothesis;
- the minimum playable/observable experiment;
- what evidence or result would answer the question;
- which parts are intentionally disposable, provisional, or not yet production commitments.

Prototype code is evidence for Game Design. It does not become permanent architecture or Requirement merely because it exists.

For isolated disposable experiments, System Design and Spec may be minimal. If the experiment modifies shared production paths, persistent data, common runtime contracts, or other meaningful project boundaries, use the normal System Design → Spec protection even if the gameplay itself is experimental.

After a Validation Scope is evaluated, either:

1. update Game Design with the learned conclusion and discard/retire the experiment; or
2. update Game Design, then extract a Delivery Scope for the version that will keep and harden the capability.

Do not silently graduate prototype shortcuts into permanent architecture.

## System Design rules

- Create or update System Design only for capabilities that are entering implementation/refactoring and need material technical structure to be settled.
- Read the affected code path end to end before deciding placement or boundaries.
- Prefer existing Godot/project mechanisms and the smallest architecture that satisfies the current Requirement.
- System Design owns material technical decisions: capability ownership, dependency direction, state/data model, lifecycle, interfaces/protocols, persistence/runtime choices, and integration boundaries.
- If several technically plausible choices materially change architecture, surface the trade-off instead of silently choosing inside Spec or implementation.
- Do not create generalized architecture merely because future Game Design might use it. Future replaceability is a design direction; current abstractions require a current consumer.

## Spec rules

- Do **not** backfill Specs for untouched legacy code.
- Create or update a Spec only when a capability is actually being refactored or newly developed.
- Project the current Requirement + System Design into the smallest locally executable contract.
- A Spec should cover only what the implementation agent needs: observable behavior, capability boundary, ownership, contracts/invariants, allowed/prohibited change surface, failure behavior, and proportionate verification.
- Spec must not invent gameplay, Scope, or material architecture. If projection requires one, return to Game Design, Requirement, or System Design at the earliest missing layer.

## Task and implementation rules

- Build Tasks from Requirement + System Design + Spec together.
- Tasks may contain concrete files, implementation order, migration steps, and test commands, but must not create hidden feature requirements or architecture decisions.
- If implementation reveals that the change surface is larger than expected, update the earliest affected authoritative layer and revalidate only the descendants that actually depend on it.
- Preserve unaffected Game Design, Requirement, System Design, Specs, Tasks, and behavior.
- Remove stale contradictions instead of accumulating patch-note documentation in current-state artifacts.

## Verification

Verification follows the actual impact surface. Protect user-observable behavior, non-trivial state transitions, important data/contracts, and reproduced regressions. Do not add tests only to increase counts, symmetry, coverage percentage, or platform matrix size.

For Delivery Scope, verification establishes that the committed behavior and contracts hold.

For Validation Scope, verification should first establish that the prototype reliably exposes the intended design question; design evaluation evidence may be qualitative or playtest-based and should not be confused with software correctness tests.

Non-trivial logic should leave the smallest useful runnable check that protects an independently meaningful failure mode.

## Ponytail `full`

Use the first solution that actually holds:

1. skip speculative work;
2. reuse what already exists;
3. prefer Godot/GDScript built-ins and native engine behavior;
4. prefer already-installed project mechanisms over new dependencies or abstractions;
5. use the smallest correct change.

No one-implementation interfaces, factories for one product, scaffolding for hypothetical future systems, or abstractions whose only consumer is speculative. Deletion is preferred to addition when both solve the problem.

Bug fixes must address the shared root cause after checking callers, not only the reported symptom.

Never simplify away trust-boundary validation, data-loss prevention, required error handling, security, or explicitly requested behavior.

## Legacy documentation

`docs/development-brief/` is a historical snapshot of the pre-SDD architecture discussion. It may help explain current code, but it is not current Game Design / Requirement / System Design / Spec authority. Do not update it as part of ordinary development.
