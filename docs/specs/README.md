# Specs

Specs exist only for capabilities that are being refactored or newly developed under the current SDD workflow.

Do not create retrospective Specs merely to describe untouched legacy code.

For an affected capability, project the current Requirement and relevant Design into a small executable contract covering:

1. observable behavior;
2. capability boundary;
3. owning scene/script/module;
4. interfaces, data/state contracts, and invariants;
5. allowed and prohibited change surface;
6. failure/invalid-state behavior;
7. the smallest verification evidence that protects the real impact surface.

A Spec must not invent a material architecture decision. If one is missing, update Design first.

Keep each Spec current-state only. When Requirement or Design changes, rewrite the affected obligations and remove stale contradictions instead of appending patch notes.
