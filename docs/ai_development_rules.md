# AI Development Rules for Gameplay Validation v0.1

This repository is a Godot 4.x gameplay validation toy, not a production game.

## Scope limits

Do not add:

- story, dialogue, lore, or worldbuilding;
- partners, character selection, or multiple playable characters;
- meta progression, shops, equipment affixes, saves, or settings menus;
- experience gems, level-up choices, drops, or complex combat rewards;
- audio, music, images, textures, fonts, models, or particle effects;
- networking or formal UI skins.

## Implementation rules

- Build the playable loop first, then improve presentation only if needed.
- Keep visible objects geometric and replaceable.
- Put core rules in `.gd` scripts, not scene files.
- Keep fundamental numbers in `scripts/core/Constants.gd`.
- Keep run-level cross-scene state in the `RunState` autoload.
- Keep random grid generation seed-based and reproducible.
- Avoid expanding systems beyond the validation loop.
