# Specs

Specs exist only for capabilities that are being refactored or newly developed under the current SDD workflow.

Do not create retrospective Specs merely to describe untouched legacy code.

## Upstream authority

A Spec is projected from:

1. the current Requirement, which defines whether the capability is in Scope, what accepted baseline must be preserved, and what outcome must be delivered; and
2. any applicable System Design, when the change requires material technical ownership, boundary, dependency, state/data, lifecycle, or integration decisions to be settled.

Game Design is upstream of Requirement. A Spec may consult it for context, but it must not pull an unscoped Design idea directly into implementation.

A System Design document is not mandatory merely to complete the chain. If the change fits an already-settled technical structure and introduces no material architecture decision, the Spec may rely on that existing structure after the affected code path has been inspected.

## Spec contents

For an affected capability, project the smallest executable contract covering:

1. **Behavior** — what must be observable when complete;
2. **Boundary** — which capability is being implemented;
3. **Ownership** — existing ownership, or ownership settled by applicable System Design;
4. **Contracts** — interfaces, data/state contracts, lifecycle rules, and invariants;
5. **Change surface** — what may change and what must remain stable;
6. **Failure behavior** — invalid, unavailable, conflicting, or unsupported states;
7. **Verification** — the smallest evidence that protects the real impact surface.

## Projection rules

A Spec must not invent:

- new gameplay or content decisions;
- version Scope;
- a new capability boundary;
- module ownership or dependency direction;
- a new interface/data architecture;
- speculative support for future systems.

If projection requires one of those decisions, return to the earliest missing upstream layer:

- gameplay/content question → Game Design;
- current-version inclusion/exclusion question → Requirement;
- material technical architecture/ownership question → System Design.

If no System Design exists because the technical structure is already settled, describe only the existing boundary needed for the change. Do not create architecture inside Spec and do not create a System Design solely for document symmetry.

Keep each Spec current-state only. When upstream authority changes, rewrite only the affected obligations and remove stale contradictions instead of appending patch notes.

## Verification

Verification follows the actual impact surface, not coverage symmetry or test count. Prefer the smallest runnable evidence that protects independently meaningful user behavior, state transitions, data/contracts, integration boundaries, or reproduced regressions.