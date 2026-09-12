# Game Design

`docs/design/` is the upstream game-design space for the project.

It answers questions such as:

- what kind of game this should become;
- what the player should understand, decide, feel, and repeatedly do;
- which gameplay systems, content structures, themes, references, and future directions are being explored or selected;
- how different gameplay layers relate at the design level.

Game Design is allowed to be broader than the current implementation Scope. It may contain future worlds, mechanics, content slots, alternatives, and ideas that are intentionally not scheduled yet.

## Relationship to Requirement

`docs/requirements.md` is not a summary of all Game Design. It is the current version Scope extracted from sufficiently settled Design.

A Design idea becomes implementation work only after Requirement selects it.

Do not remove a valid future Design idea merely because it is out of the current Requirement. Conversely, do not place an idea into Requirement only because the current code already happens to contain something similar.

## Relationship to System Design

Game Design describes gameplay intent and content structure. It does not own software architecture.

Questions such as module ownership, scene/script boundaries, data models, interfaces, lifecycle, dependency direction, persistence, and runtime integration belong in `docs/system-design/` once the relevant capability enters the current Requirement.

Do not constrain Game Design to match accidental legacy code structure. Implementation may inform feasibility, but it is not design authority.

## Working style

Game Design may move from open exploration toward settled decisions over time. Keep current conclusions readable and remove stale contradictions when a direction is replaced.

Do not force every brainstorming branch into a permanent document. Preserve ideas that remain useful to the project; discard noise.
