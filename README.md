# PixelWorld

PixelWorld is a Godot 4.7 top-down pixel RPG prototype. The current version is **v0.4.1**, focused on building interiors, deeper village content, runtime map switching, and stronger per-map save state on top of the Pokemon/Stardew-style multi-map architecture introduced in v0.4.0.

## Current Version

- Version: `v0.4.1`
- Engine: Godot `4.7.stable`
- AI mode: Mock/local only
- Real MiMo / NVIDIA API integration: paused
- TileMapLayer migration: paused
- Multiplayer: not included
- Infinite/seamless world streaming: not included

## What Is Included

- Main menu to create or continue a world
- Mock world blueprint generation
- Legacy 64x64 generated map path retained for old tests and fallback
- New `WorldGraph` with multiple connected maps, including building interior map nodes
- New `MapInstance` data model for village, forest, cave, sect gate, interiors, and secret realms
- New `MapTransition` / `TransitionArea` support for map exits and target spawn points
- New per-map `MapState` persistence for opened chests, collected resources, defeated enemies, triggered events, solved puzzles, NPC states, building states, dynamic objects, last player position, and visited state
- New `MapInstanceGenerator` and `MapTypeRuleLoader` using `data/map_generation/map_type_rules.json`
- Building template and service pipeline using `BuildingTemplate`, `BuildingInstance`, `BuildingPlacementValidator`, `BuildingRegistry`, `BuildingService`, `InteriorMapGenerator`, `DoorInteraction`, and `data/buildings/building_templates.json`
- Village generation now places chief house, apothecary, blacksmith, inn, and general store buildings with doors, services, interior map ids, and road-connected entrances
- Building interiors are generated as separate `interior` maps with default/exit spawns, service POIs, NPC placeholders, and return transitions
- Runtime `GameWorld` loading/unloading maps through `load_map()` and `switch_map()`
- JSON save/load through `SaveManager`, now including map id, visited maps, map states, world graph data, per-map player positions, last spawn id, and building states
- Player movement, HP, stamina, attack, damage, death, respawn, NPCs, enemies, interactions, inventory, HUD, and progression summary
- Program-generated placeholder pixel assets
- v0.3.0 world progression templates retained for xianxia, magic, apocalypse, cyberpunk, wuxia, urban ability, strange tale, and star sci worlds

## v0.4.1 Building Interiors And Runtime Transitions

v0.4.1 turns village buildings into actual world graph destinations instead of simple outdoor markers.

- `BuildingRegistry` loads `data/buildings/building_templates.json` and creates placed building dictionaries with stable ids, doors, services, access rules, and `interior_map_id`.
- `InteriorMapGenerator` creates MVP interior maps for chief house, apothecary, blacksmith, inn, and general store.
- `BuildingService` provides deterministic local services such as healer, inn rest, shop placeholder, blacksmith placeholder, quest board, training, and storage.
- `DoorInteraction` and `TransitionArea` connect runtime triggers to `GameWorld.request_map_transition()` and `GameWorld.switch_map()`.
- `MockProvider` now inserts building interior maps into the default blueprint and adds village <-> interior connections.
- `GameWorld` now keeps one player node across map loads, creates runtime layers on demand, renders building/transition layers, updates HUD map/building text, logs building entry/return, and saves the current map state before switching.

Default village interiors currently include:

- `chief_house_001_interior`
- `apothecary_001_interior`
- `blacksmith_001_interior`
- `inn_001_interior`
- `general_store_001_interior`

## v0.4.0 Map Architecture

The core gameplay layout is now split into these layers:

- `WorldGraph`: the topology of one generated world. It stores maps, connections, main path, side paths, hidden paths, start map, and current map.
- `WorldInstance`: runtime wrapper for the graph and world-level state.
- `MapInstance`: one playable map definition with size, type, spawn points, generated tiles, buildings, NPCs, enemies, resources, POIs, and transitions.
- `MapTransition`: one directed exit from a source map to a target map and spawn point. It can hold simple unlock rules such as `required_realm_order`.
- `MapState`: per-map persistence for things the player changed inside that map.
- `GameWorld`: the runtime scene that unloads the current map, loads the next `MapInstance`, renders layers, spawns actors/interactables, and restores local state.

Default mock worlds currently include:

- `village_001` - starting village, buildings, NPCs, basic resources
- `forest_001` - exploration field, enemies, resources, cave/sect routes
- `cave_001` - dungeon-style side map
- `sect_gate_001` - faction entrance template
- building interiors linked from `village_001` doors

See `GAMEPLAY_MAP_ARCHITECTURE.md` for the fuller design notes.

## Progression System

PixelWorld still treats growth as a world-specific system rather than a generic level number.

- Xianxia uses realms, minor stages, cultivation progress, bottlenecks, breakthrough attempts, heart-demon risks, and tribulation records.
- Magic uses mage ranks, spell research, elemental trials, forbidden-spell backlash, and academy attention.
- Apocalypse uses awakening ranks, crystal cores, infection resistance, gene stability, and monster aggression.
- Cyberpunk uses cybernetic synchronization, surgery risks, corporate attention, and cyber-psychosis pressure.
- Wuxia uses inner power, meridian breakthroughs, qi deviation, and jianghu fame.
- Urban ability uses official ratings, mental stability, exposure risk, and ability rampage consequences.
- Strange tale uses rule understanding, pollution adaptation, sanity pressure, and entity attention.
- Star sci uses technology points, ship modules, civilization recognition, faction attention, and trade-route access.

Progression templates are stored in `data/progression_templates/`, loaded by `ProgressionTemplateLoader`, and persisted by `SaveManager`.

## Asset Pack

All generated PNG assets are project-made placeholder art. No third-party assets are downloaded or embedded.

- Generator: `tools/generate_pixel_assets.py`
- Output: `art/generated/`
- Manifest: `ASSET_MANIFEST.md`
- Placeholder notice: `PLACEHOLDER_ART.md`
- Total generated PNG assets: `186`
- Preview sheets: `art/generated/previews/`
- Runtime resolver: `scripts/assets/AssetResolver.gd`

Run the generator:

```powershell
python tools\generate_pixel_assets.py
```

## 玩法路线图

- v0.4.0: establish multi-map world graph, map switching, per-map state, and building templates.
- v0.4.1: add building interiors, village door transitions, map-state strengthening, T025 cleanup, and T156-T210 regression coverage.
- v0.4.x: add more authored map types, richer interior maps, and more transition unlock rules.
- v0.5.x: connect progression rewards to real combat/exploration loops and tune breakthrough costs.
- v0.6.x: replace more ColorRect placeholders with generated tile/item sprites.
- Later: add editor-verified manual checks for player feel, NPC interaction, collision blocking, HUD layout, and cross-map transitions.
- Later: revisit TileMapLayer/TileSet migration after core gameplay is stable.
- Later: real AI provider integration only after local/mock gameplay remains deterministic and safe.

## Test Status

Latest recorded result for v0.4.1:

- JSON parse validation: PASS
- CLI compile validation: PASS
- SmokeTestRunner: `192/192 PASS`
- New v0.4.0 tests `T116-T155`: `40/40 PASS`
- New v0.4.1 tests `T156-T210`: `55/55 PASS`
- `T025` result in this run: PASS
- `T028` result in this run: PASS

Manual Godot editor F5 validation was not executed in this CLI pass; manual checks remain marked as untested in `TEST_REPORT.md`.

Run smoke tests:

```powershell
Godot_v4.7-stable_win64_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
```

## Important Development Rules

- Do not connect real MiMo / NVIDIA APIs in this version.
- Do not migrate TileMapLayer yet.
- Do not download third-party art.
- Do not delete old tests such as `T025` and `T028`.
- Keep generated assets reproducible through script.
- Keep map type and building data in JSON where possible.
- Keep progression templates data-driven JSON, not hardcoded into Player or GameWorld.
- Update `DEV_LOG.md` for project changes.
- Update `TEST_REPORT.md` after tests.
