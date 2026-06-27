# PixelWorld v0.4.0 Gameplay Map Architecture

This document records the v0.4.0 map architecture. The goal is to move PixelWorld from one generated 64x64 map into a Pokemon/Stardew-style collection of discrete maps connected by exits, doors, caves, paths, and future story gates.

## Scope

v0.4.0 adds the architecture and MVP runtime path. It does not add real AI calls, TileMapLayer migration, seamless infinite maps, multiplayer, or a full visual interior editor.

The old single-map generation path is intentionally retained for compatibility with older tests and fallback behavior.

## Core Model

`WorldGraph` is the world topology. It owns:

- world id, name, world type, seed
- start map id and current map id
- map list
- directed connections
- main path, side paths, hidden paths, and locked paths

`WorldInstance` is the runtime wrapper around one graph. It is prepared for world-level runtime state without forcing every system to talk directly to `GameWorld`.

`MapInstance` describes one playable map:

- map id, display name, map type, size, seed, danger level
- spawn points
- generated tile and walkable arrays
- buildings
- NPCs
- enemies
- resources
- points of interest
- transitions
- metadata

`MapTransition` describes a directed route from one map to another:

- source map and target map
- source spawn and target spawn
- transition type
- optional source rectangle for runtime markers
- optional requirements such as `required_realm_order`
- locked message for blocked transitions

`MapState` stores changes made inside a map:

- visited flag
- opened chests
- collected resources
- defeated enemies
- local flags
- local variables
- last player position

`MapStateSerializer` converts all map states into save-friendly dictionaries and restores them on load.

## Runtime Flow

1. `MockProvider` returns a world blueprint with `maps`, `connections`, `start_map_id`, `main_path`, and `side_paths`.
2. `WorldState.set_world_blueprint()` creates graph data and records the starting map.
3. `GameWorld.setup_from_world_state()` detects the multi-map blueprint and builds a `WorldGraph`.
4. `GameWorld.load_map(map_id)` asks `MapInstanceGenerator` to create the target `MapInstance`.
5. `GameWorld` renders the map layers, builds collisions, spawns buildings, transition markers, player, NPCs, enemies, and interactables.
6. `GameWorld.switch_map(target_map_id, spawn_id)` saves the current `MapState`, unloads the old runtime nodes, loads the target map, and places the player at the target spawn.
7. `SaveManager` persists current map id, visited maps, map states, world graph data, last spawn id, and per-map player positions.

## Default Map Set

The mock xianxia-style world currently contains four maps:

| Map id | Type | Purpose |
|---|---|---|
| `village_001` | `village` | Safe starting hub with buildings, NPCs, resources, and the road to the forest |
| `forest_001` | `forest` | First combat/exploration field and junction to cave/sect routes |
| `cave_001` | `cave` | Dungeon-style side map |
| `sect_gate_001` | `sect_gate` | Faction entrance template |

The default main path is:

```text
village_001 -> forest_001 -> sect_gate_001
```

The cave is currently a side path:

```text
forest_001 <-> cave_001
```

## Data Files

`data/map_generation/map_type_rules.json` defines basic generation rules:

- default size
- danger level
- terrain weights
- resource budgets
- POI budgets
- NPC/building/enemy budgets where relevant

`data/buildings/building_templates.json` defines building templates:

- type and display name
- size and door offset
- services
- interior template id
- default NPCs
- faction role
- access rules

## Building Layer

v0.4.0 adds data-level building support:

- `BuildingTemplate` loads template-style data.
- `BuildingInstance` stores a placed building in a map.
- `BuildingPlacementValidator` checks footprint bounds and overlap.
- `GameWorld` renders buildings as MVP runtime markers on `BuildingLayer`.

This is not yet a full house editor. Interiors are represented as templates and can become separate `interior` maps later.

## State And Save Boundaries

World-level fields live in `WorldState`:

- current world graph data
- current map id
- visited maps
- map states
- global flags
- player positions by map
- last spawn id

Save data now includes these map fields while preserving older progression, inventory, NPC memory, action history, and world blueprint fields.

## Validation

v0.4.0 adds SmokeTest coverage `T116-T155` for:

- graph creation and validation
- map instance creation
- transition rules
- per-map state serialization
- rule loading
- map generation by type
- mock blueprint maps and connections
- `GameWorld` map loading and switching
- save/load map fields
- building templates and placement validation
- new runtime layers
- map architecture documentation

## Known Limits

- Runtime rendering still uses MVP `ColorRect` tiles and markers in many places.
- TileMapLayer and TileSet migration is intentionally postponed.
- `T025` remains a retained CLI headless initialization verification item and still needs editor F5 validation.
- Real AI provider integration remains paused.
- Cross-map transition UX is functional at data/runtime level but still needs richer player-facing interaction prompts.
