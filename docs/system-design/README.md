# System Design

`docs/system-design/` contains the technical/software design for capabilities that are actually entering implementation or refactoring.

System Design sits between the current version Requirement and Spec:

```text
Game Design
    ↓
Requirement (current version Scope)
    ↓
System Design
    ↓
Spec
    ↓
Task
    ↓
Implementation
```

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

It should contain enough technical structure that Spec projection does not need to make hidden architecture decisions.

## When to create one

Create or update a System Design only when:

- the capability is selected by the current Requirement; and
- implementation/refactoring requires a material technical decision that should remain authoritative beyond a single Task.

Do not create System Design documents merely to describe untouched legacy code.

Small changes that fit an already-settled technical structure do not need a new System Design document.

## Design constraints

System Design must satisfy the current Requirement and must not silently change Game Design.

Prefer, in order:

1. existing project mechanisms;
2. native Godot/GDScript mechanisms;
3. the smallest new boundary that the current Requirement actually needs.

Do not build generalized plugin systems, event frameworks, factories, interfaces, or extensibility layers solely because future Game Design may eventually contain multiple worlds or gameplay types.

Future replaceability is a design direction. A current abstraction requires a current implementation consumer and a concrete boundary worth preserving.

## Relationship to Spec

Spec projects the settled Requirement + System Design into a locally executable implementation contract.

If writing a Spec exposes an unresolved question about ownership, data architecture, dependency direction, lifecycle, interface, or another material technical choice, stop and resolve System Design first.

Spec should constrain implementation; it should not become the place where architecture is invented.

## Delta changes

When Requirement changes, first determine which System Designs are actually affected.

When System Design changes, re-project only the dependent Specs and rebuild only their affected Tasks. Preserve unaffected documents and behavior.
