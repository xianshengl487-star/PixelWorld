# PixelWorld v0.4.2 Code Health Report

Date: 2026-06-28

## Version Consistency

- Target version: `v0.4.2`
- Godot engine: `4.7.stable.official.5b4e0cb0f`
- Repository branch at audit start: `main`
- Latest released tag before this work: `v0.4.1`
- Project config: `project.godot` updated to `0.4.2`
- Main menu version label: updated to `v0.4.2`
- README, DEV_LOG, TEST_REPORT, gameplay architecture notes, and quest notes include the v0.4.2 scope.

## Audit Scope

- Reviewed code paths touched by map switching, map state persistence, old save migration, building services, quest tracking, HUD debug display, and CLI regression coverage.
- Confirmed this version keeps AI provider behavior mock/local only.
- Confirmed no TileMapLayer migration, multiplayer, infinite map streaming, real MiMo/NVIDIA/OpenAI API calls, or third-party art ingestion were added.

## Main Risks Found And Fixed

- Cross-map state pollution: current map saves no longer copy every global defeated enemy or collected item into the active `MapState`.
- Unscoped object ids: new `ScopedId` helper creates stable `map_id::local_id` ids for enemies, resources, chests, and interactables.
- Map switch safety: `switch_map()` preserves the current map id on failed target maps, and `load_map()` can skip duplicate save calls during a switch.
- Old save compatibility: `SaveManager.migrate_save_data()` now fills `save_version`, `current_map_id`, `visited_maps`, `map_states`, `building_states`, `quest_state`, `equipment_state`, `training_used_today`, `world_graph`, and per-map player position fields.
- Quest preload safety: quest and interactable scripts use runtime Autoload lookup where needed so CLI preload contexts do not fail on direct `WorldState` identifiers.

## Known Non-Failing Warnings

- Missing `.env` warning is expected and keeps Mock mode active.
- T114 intentionally requests a missing texture to test fallback behavior.
- T198/T222 intentionally request missing transitions/maps to test defensive handling.
- Godot headless exit can report RID/ObjectDB cleanup warnings after SceneTree smoke tests; these did not fail the CLI assertions.

## Validation Status

- JSON configuration parse: PASS
- CLI compile validation: PASS
- SmokeTestRunner pre-documentation run: `247/252 PASS`; remaining failures were documentation gates only.
- Final v0.4.2 smoke run: `252/252 PASS`, recorded in `TEST_REPORT.md`.
