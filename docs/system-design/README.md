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

## When to create one

Create or update a System Design only when:

- the capability is selected by the current Requirement; and
- implementation/refactoring requires a material technical decision that should remain authoritative beyond a single Task.

Do not create System Design documents merely to describe untouched legacy code.

Small changes that fit an already-settled technical structure do not need a new System Design document. In that case, the affected code path and any still-valid technical references provide implementation context, while Spec constrains the local change without inventing new architecture.

## Design constraints

System Design must satisfy the current Requirement and must not silently change Game Design.

Prefer, in order:

1. existing project mechanisms;
2. native Godot/GDScript mechanisms;
3. the smallest new boundary that the current Requirement actually needs.

Do not build generalized plugin systems, event frameworks, factories, interfaces, or extensibility layers solely because future Game Design may eventually contain multiple worlds or gameplay types.

Future replaceability is a design direction. A current abstraction requires a current implementation consumer and a concrete boundary worth preserving.

## Existing technical documents

The repository already contains pre-workflow technical notes such as `docs/content-and-effect-architecture.md`, `docs/buff_system.md`, and `docs/rng.md`.

Do not mass-migrate or rewrite them merely to fit the new directory structure. Treat them as historical or capability-specific context until the corresponding capability is actually changed.

When a capability enters the current Requirement:

1. inspect the relevant legacy document and implementation;
2. decide which technical decisions are still valid;
3. place only the current authoritative decisions needed for the change into `docs/system-design/<capability>.md` when a durable System Design is warranted;
4. do not preserve obsolete architecture merely for documentation continuity.

## Relationship to Spec

Spec projects the settled Requirement plus any applicable System Design into a locally executable implementation contract.

If no new System Design is warranted because the change fits an already-settled technical structure, Spec may rely on that existing structure after the affected code path has been inspected.

If writing a Spec exposes an unresolved question about ownership, data architecture, dependency direction, lifecycle, interface, or another material technical choice, stop and resolve System Design first.

Spec should constrain implementation; it should not become the place where architecture is invented.

## Delta changes

When Requirement changes, first determine which System Designs are actually affected.

When System Design changes, re-project only the dependent Specs and rebuild only their affected Tasks. Preserve unaffected documents and behavior.