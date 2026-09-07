# Development workflow

This repository uses SDD for material changes and Ponytail `full` as the default implementation principle.

## Authority

1. `docs/requirements.md` — Requirement: intended behavior, constraints, acceptance direction.
2. `docs/design/` — Design: gameplay/world design and technical structure that has actually been decided.
3. `docs/specs/<capability>.md` — Spec: agent-executable projection for a capability being refactored or newly developed.
4. Task — executable work derived from Requirement + Design + Spec; keep it in the active issue/PR unless a durable task document is specifically useful.
5. Implementation — evidence of current behavior, not authority over Requirement or Design.

## SDD rules

- Read Requirement and relevant Design before changing code.
- Read the affected code path end to end before deciding the implementation.
- Do **not** backfill Specs for untouched legacy code.
- Create or update a Spec when a capability is actually being refactored or newly developed.
- If implementation exposes a missing material architecture decision, update Design first; do not hide the decision in Spec, Task, or code.
- Preserve unaffected Requirement, Design, Specs, and behavior.
- Remove stale contradictions instead of accumulating patch-note documentation.

A Spec should contain only what the implementation agent needs: behavior, boundary, ownership, contracts/invariants, allowed change surface, failure behavior, and proportionate verification.

## Ponytail `full`

Use the first solution that actually holds:

1. skip speculative work;
2. reuse what already exists;
3. prefer Godot/GDScript built-ins and native engine behavior;
4. prefer already-installed project mechanisms over new dependencies or abstractions;
5. use the smallest correct change.

No one-implementation interfaces, factories for one product, scaffolding for hypothetical future systems, or abstractions whose only consumer is speculative. Deletion is preferred to addition when both solve the problem.

Bug fixes must address the shared root cause after checking callers, not only the reported symptom.

Non-trivial logic must leave one smallest useful runnable check. Do not multiply tests for coverage symmetry or metrics.

Never simplify away trust-boundary validation, data-loss prevention, required error handling, security, or explicitly requested behavior.

## Legacy documentation

`docs/development-brief/` is a historical snapshot of the pre-SDD architecture discussion. It may help explain current code, but it is not current Requirement/Design/Spec authority. Do not update it as part of ordinary development.
