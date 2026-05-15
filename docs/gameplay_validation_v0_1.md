# Gameplay Validation Toy v0.1

## Goal

Validate a minimal loop made entirely of geometric 2D shapes:

1. Explore a 6×6 fogged grid.
2. Open up to three chests to gain weapon levels.
3. Enter three task cells.
4. Survive circular signal-range battles with automatic weapons.
5. Return battle results to the grid.
6. Win after clearing three task cells.

## Implemented loop

- `Main` starts the run and routes between grid and battle scenes.
- `RunState` stores grid data, task progress, player grid position, current task, weapons, and next battle sync.
- The grid generator uses a seed, places start/tasks/chests/obstacles, validates reachability with BFS, and falls back to an obstacle-free layout if needed.
- Grid movement is click-based and restricted to revealed, adjacent, non-blocked cells.
- Chests increase one weapon level up to Lv.3.
- Unclear task cells enter battle.
- Battle success clears the current task and can reveal extra surrounding cells when final sync is high.
- Battle failure returns the player to the previous grid cell.
- Sync below 30 on a successful battle makes the next battle start at 70 sync; otherwise the next battle starts at 100 sync.

## Battle rules

- The signal area is a circle centered at 640×360 with radius 300.
- The player uses WASD or arrow keys.
- Sync replaces health.
- Staying in the stable zone after avoiding damage regenerates sync.
- The edge zone drains sync.
- Leaving the circle disconnects controls and pulls the avatar back toward the center.
- Small enemies spawn every second.
- One elite enemy appears after 45 seconds and has a visible health bar.
- Surviving for 30 seconds completes the battle.

## Weapons

- Aura: periodic circular damage around the player.
- Projectile: periodic shots toward nearby enemies.
- Shape: periodic rectangular hitboxes in cardinal directions, expanding to diagonals at Lv.3.

All visuals are drawn with Godot UI nodes or `Node2D._draw()` and use no imported art/audio assets.
