# PixelWorld v0.4.1 Gameplay Map Architecture

This document records the v0.4.1 map architecture. PixelWorld now uses a Pokemon/Stardew-style collection of discrete maps connected by exits, doors, caves, paths, and future story gates. v0.4.1 extends the v0.4.0 graph foundation with Building Interior maps and runtime village <-> interior transitions.

## Scope

v0.4.1 adds the building interior runtime path, deeper default village content, stronger map state persistence, and regression coverage for T156-T210. It does not add real AI calls, TileMapLayer migration, seamless infinite maps, multiplayer, or a full visual interior editor.

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
- NPC states
- building states
- dynamic objects
- last player position

`MapStateSerializer` converts all map states into save-friendly dictionaries and restores them on load.

## Runtime Flow

1. `MockProvider` returns a world blueprint with `maps`, `connections`, `start_map_id`, `main_path`, and `side_paths`.
2. `WorldState.set_world_blueprint()` creates graph data and records the starting map.
3. `GameWorld.setup_from_world_state()` detects the multi-map blueprint and builds a `WorldGraph`.
4. `GameWorld.load_map(map_id)` asks `MapInstanceGenerator` to create the target `MapInstance`.
5. `GameWorld` renders the map layers, builds collisions, spawns buildings, transition markers, player, NPCs, enemies, and interactables.
6. `GameWorld.switch_map(target_map_id, spawn_id)` saves the current `MapState`, unloads the old runtime nodes, loads the target map, and places the player at the target spawn.
7. `GameWorld.request_map_transition(transition_id)` resolves graph/map transitions, validates unlock rules, and calls `switch_map()`.
8. `SaveManager` persists current map id, visited maps, map states, world graph data, last spawn id, per-map player positions, and building states.

## Default Map Set

The mock xianxia-style world currently contains the outdoor core maps plus village interiors:

| Map id | Type | Purpose |
|---|---|---|
| `village_001` | `village` | Safe starting hub with buildings, NPCs, resources, and the road to the forest |
| `forest_001` | `forest` | First combat/exploration field and junction to cave/sect routes |
| `cave_001` | `cave` | Dungeon-style side map |
| `sect_gate_001` | `sect_gate` | Faction entrance template |
| `chief_house_001_interior` | `interior` | Chief house interior with elder/service POI placeholder |
| `apothecary_001_interior` | `interior` | Apothecary interior with healer service POI |
| `blacksmith_001_interior` | `interior` | Blacksmith interior with forge service POI |
| `inn_001_interior` | `interior` | Inn interior with rest service POI |
| `general_store_001_interior` | `interior` | General store interior with shop service POI |

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

## Building Interior System

v0.4.1 turns core village buildings into enterable graph nodes:

- `BuildingTemplate` loads template-style data.
- `BuildingInstance` stores a placed building in a map.
- `BuildingPlacementValidator` checks footprint bounds and overlap.
- `BuildingRegistry` loads `data/buildings/building_templates.json` and creates stable building dictionaries.
- `BuildingService` creates deterministic local services such as healer, inn, shop placeholder, blacksmith placeholder, quest board, training, and storage.
- `InteriorMapGenerator` creates MVP room layouts with walls, floor, door tiles, service POIs, NPC placeholders, default spawns, exit spawns, and return transitions.
- `DoorInteraction` is a reusable Area2D trigger for building doors.
- `GameWorld` renders buildings as MVP runtime markers on `BuildingLayer`, creates `TransitionArea` nodes, and keeps a single player node across map switches.

The default village generation path places chief house, apothecary, blacksmith, inn, and general store. Each building has `building_id`, `building_type`, `position`, `size`, `door_position`, `interior_map_id`, and `services`. Door tiles are kept walkable and connected back to the village road.

This is not yet a full house editor. Interiors are generated from simple templates and rendered through the existing MVP tile/marker path.

## State And Save Boundaries

World-level fields live in `WorldState`:

- current world graph data
- current map id
- visited maps
- map states
- global flags
- building states
- player positions by map
- last spawn id

Save data now includes these map/building fields while preserving older progression, inventory, NPC memory, action history, and world blueprint fields. Old saves with missing map/building fields are treated as empty dictionaries and should not crash load.

## Validation

v0.4.0 added SmokeTest coverage `T116-T155` for:

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

v0.4.1 adds SmokeTest coverage `T156-T210` for:

- `BuildingRegistry` and template required keys
- `BuildingService` healer behavior
- `InteriorMapGenerator` interiors, spawns, service POIs, and return transitions
- `DoorInteraction` and `TransitionArea` setup
- village buildings, doors, interior map ids, and placement validation
- WorldGraph interior map nodes and village <-> interior connections
- `GameWorld` load/switch/return behavior and player node de-duplication
- `MapState`, `SaveManager`, HUD methods, runtime layers, transition requests, and GameLog entries
- `T025` player-node regression rerun
- README, TEST_REPORT, and architecture documentation updates

## Known Limits

- Runtime rendering still uses MVP `ColorRect` tiles and markers in many places.
- TileMapLayer and TileSet migration is intentionally postponed.
- Manual Godot editor F5 validation is still required for player feel, visual layout, collision feel, and real interaction prompts.
- Real AI provider integration remains paused.
- Cross-map transition UX is functional at data/runtime level but still needs richer player-facing interaction prompts.
