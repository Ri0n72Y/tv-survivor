# Honkai: Star Rail — Character Attribute Reference

> Source type: external reference data.
>
> Purpose: preserve the source game's attribute vocabulary so the project can selectively adapt it for real-time survivor gameplay. This file is not project design authority.

## 1. Source Base Stats

Honkai: Star Rail character comparison data exposes four character base stats:

- HP
- ATK
- DEF
- SPD

Source reference:
- https://honkai-star-rail.fandom.com/wiki/Character/Comparison

## 2. Source Combat / Derived Stats

Common combat stats exposed through character/relic systems include:

- CRIT Rate
- CRIT DMG
- Effect Hit Rate
- Effect RES
- Break Effect
- Energy Regeneration Rate
- Outgoing Healing Boost
- Physical DMG Boost
- Fire DMG Boost
- Ice DMG Boost
- Wind DMG Boost
- Lightning DMG Boost
- Quantum DMG Boost
- Imaginary DMG Boost

Source references:
- https://honkai-star-rail.fandom.com/wiki/Relic/Stats
- https://honkai-star-rail.fandom.com/wiki/CRIT_Rate
- https://honkai-star-rail.fandom.com/wiki/CRIT_DMG
- https://honkai-star-rail.fandom.com/wiki/Effect_Hit_Rate
- https://honkai-star-rail.fandom.com/wiki/Speed
- https://honkai-star-rail.fandom.com/wiki/Energy

## 3. Important Semantic Differences

Source-game SPD controls turn frequency / Action Value. It is not equivalent to movement speed.

Source-game HP is a conventional health resource. The current project uses Sync as the primary survival resource instead.

Effect Hit Rate / Effect RES only become useful if the project adopts probabilistic status/debuff application.

Break Effect only becomes useful if the project adopts a toughness / weakness-break system.

Energy Regeneration Rate only becomes useful if the project adopts an Energy-driven active/ultimate system.

Outgoing Healing Boost only becomes useful if a meaningful healing system exists.

Elemental DMG Boost stats only become useful if the corresponding damage-type system remains a meaningful build axis.

These semantic differences are why the project should reference the source vocabulary without copying the source stat sheet wholesale.
