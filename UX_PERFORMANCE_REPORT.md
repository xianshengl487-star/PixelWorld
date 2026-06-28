# PixelWorld v0.4.3 UX Performance Report

Date: 2026-06-28

## Scope

v0.4.3 targets map transition performance, player operation feel, interaction guidance, and scene readability. It keeps the MVP ColorRect fallback, avoids third-party assets, and does not migrate the project to TileMapLayer yet.

## Lag Root Causes

- Ground rendering used one `ColorRect` per tile. A 96x96 village could create 9,216 ground nodes, and a 128x128 forest could create 16,384 ground nodes before buildings, actors, resources, and UI.
- Collision generation used one `StaticBody2D` per blocking tile, so forest/cave edges and water/tree bands could create many physics nodes.
- `switch_map()` previously did save, unload, generate, render, collide, spawn, HUD update, and player placement in one synchronous burst with no loading veil.
- Interaction targets were visually present, but doors, exits, resources, chests, NPCs, and services did not all expose a consistent prompt.

## Implemented Optimizations

- `ChunkedMapRenderer` row-merges consecutive equal tile types into wider `ColorRect` runs. The fallback remains ColorRect-based, but node count now scales by visible runs instead of raw tile count.
- `OptimizedCollisionBuilder` row-merges consecutive blocking tiles into wider rectangle collision runs.
- `MapRuntimeCache` caches generated `MapInstance` data so repeated visits do not regenerate map content unnecessarily.
- `GameWorld.get_performance_summary()` records load, switch, render, collision, spawn, unload, node, tile, collision, decoration, and cache metrics.
- `switch_map_async()` breaks visible travel across frames, locks player input while switching, shows `LoadingOverlay`, then unlocks the player after completion.

## UX Additions

- `LoadingOverlay` displays the target map and a compact control tip during async travel.
- `InteractionPrompt` centralizes contextual text such as `[E] Open: Old Chest` and `[E] Enter: apothecary_001`.
- `ControlHintPanel` exposes WASD/arrow movement, E interact, attack, quest, inventory, debug, save, load, and help controls.
- `InteractionTargetTracker` chooses the nearest interactable target within range and updates HUD prompts.
- `FloatingLabel` adds lightweight readability labels for doors, exits, and selected decorative markers.
- `SceneDecorator` deepens village, forest, cave, and sect gate maps without removing existing map content.

## Known Lag Positions To Check Manually

- First load into `village_001` after creating a new world.
- First switch from `village_001` to `forest_001`.
- Return from an interior map to a busy village door area.
- Forest routes near dense tree/water bands.
- Cave entrances and exit markers when several interactables are close together.

## Verification

- CLI compile validation: PASS.
- UTF-8 JSON configuration parse validation: PASS.
- SmokeTestRunner: 312/312 PASS for the 312 defined tests across T001-T330.
- T271-T330 covers renderer merging, collision merging, cache behavior, UX widgets, prompt text, async switching hooks, performance summary fields, docs, and InputMap actions.
- Representative final smoke metrics: village visual nodes were reduced to 978 merged runs for 9,216 tiles in T307; village collision runs were 472 for 790 blocking tiles in T308.
- Manual F5 checks M051-M080 remain human-only. Codex may launch Godot, but must not mark feel, stutter, readability, or visual layout as PASS without human confirmation.
