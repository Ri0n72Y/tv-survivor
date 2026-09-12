# System Design

`docs/system-design/` contains the technical/software design for capabilities that are actually entering implementation or refactoring and require material technical decisions to be settled.

The normal authority flow is:

```text
Game Design
    ↓
Requirement
    ↓
System Design (when applicable)
    ↓
Spec
    ↓
Task
    ↓
Implementation
```

System Design is an authority layer, not a mandatory document for every change.

## Purpose

System Design answers implementation-structural questions that should be settled before an agent-facing Spec is written, including:

- which scene/script/module/system owns a capability;
- dependency direction and integration points;
- state and data models;
- lifecycle and runtime behavior;
- interfaces, protocols, and boundaries;
- persistence or loading strategy when relevant;
- material technical invariants;
- whether an existing project mechanism is sufficient or a new boundary is truly required.

When such decisions are material to the change, System Design should contain enough technical structure that Spec projection does not need to make hidden architecture decisions.

## Current baseline designs

The following existing technical boundaries have been revalidated against the current implementation and are now part of the active System Design layer:

- `content-model.md` — static weapon/passive definitions, catalog discovery, mutable build ownership, and build-attribute aggregation;
- `reward-flow.md` — typed reward generation, validation, payment/application ordering, and the current Dictionary compatibility boundary;
- `buff-runtime.md` — the lightweight timed/stacked battle-status runtime currently used by Sync-related prototype content;
- `deterministic-rng.md` — run-owned deterministic gameplay RNG, named stream isolation, visual-random separation, and RNG state restoration.

These documents describe technical boundaries, not permanent gameplay content. For example, `buff-runtime.md` does not promote Sync from provisional prototype content to permanent Game Design, and `deterministic-rng.md` does not promote random main-map topology back into Requirement.

The former root-level notes `docs/content-and-effect-architecture.md`, `docs/buff_system.md`, and `docs/rng.md` were split into these current designs. Speculative future architecture from those notes was intentionally not migrated; Git history remains available if historical context is needed.

## When to create or update one

Create or update a System Design when:

- a capability is selected by the current Requirement; and
- implementation/refactoring requires a material technical decision that should remain authoritative beyond a single Task.

A current System Design may also describe an already accepted technical boundary that future changes are expected to preserve. This does not require retroactively creating Specs for the implementation that already exists.

Small changes that fit an already-settled technical structure do not need a new System Design document. In that case, use the applicable existing System Design plus the affected code path as context for Spec projection.

## Design constraints

System Design must satisfy the current Requirement and must not silently change Game Design.

Prefer, in order:

1. existing project mechanisms;
2. native Godot/GDScript mechanisms;
3. the smallest new boundary that the current Requirement actually needs.

Do not build generalized plugin systems, event frameworks, factories, interfaces, or extensibility layers solely because future Game Design may eventually contain multiple worlds or gameplay types.

Future replaceability is a design direction. A current abstraction requires a current implementation consumer and a concrete boundary worth preserving.

## Relationship to implementation evidence

System Design is authoritative for the technical boundary it records, but implementation remains evidence of what actually exists.

When a current System Design and implementation disagree during a new change:

1. determine whether the code drifted from an intended current boundary or the document became stale;
2. check the current Requirement and relevant Game Design;
3. correct the earliest wrong authoritative layer before writing the downstream Spec;
4. do not preserve an obsolete structure merely for documentation continuity.

## Relationship to Spec

Spec projects the settled Requirement plus any applicable System Design into a locally executable implementation contract.

If no new System Design is warranted because the change fits an already-settled technical structure, the Spec should rely on the applicable existing System Design after the affected code path has been inspected.

If writing a Spec exposes an unresolved question about ownership, data architecture, dependency direction, lifecycle, interface, or another material technical choice, stop and resolve System Design first.

Spec should constrain implementation; it should not become the place where architecture is invented.

## Delta changes

When Requirement changes, first determine which System Designs are actually affected.

When System Design changes, re-project only the dependent Specs and rebuild only their affected Tasks. Preserve unaffected documents and behavior.
