# PixelWorld v0.4.3 Gameplay UX Guide

This guide records the v0.4.3 player-facing controls, prompts, and manual checks.

## Controls

- `WASD` or arrow keys: move
- `E`: interact with the nearest prompted target
- `Space` or mouse attack: attack
- `Q`: quest panel action placeholder
- `I`: inventory action placeholder
- `F3`: debug action placeholder
- `F6`: save action placeholder
- `F7`: load action placeholder
- `H`: toggle control hints

The `ControlHintPanel` text uses the compact form: `WASD/Arrows Move | E Interact | Space/Mouse Attack | Q Quests | I Bag | F3 Debug | F6 Save | F7 Load | H Help`.

Short loading tips may use the lower-case phrase `E interact` when space is tight.

## Interaction Prompts

`InteractionPrompt` should be the single short prompt near the player-facing action. Examples:

- `[E] Collect: Herb Patch`
- `[E] Open: Old Chest`
- `[E] Read: Village Sign`
- `[E] Travel: forest_001`
- `[E] Enter: apothecary_001`
- `[E] Talk: Village Chief`

`InteractionTargetTracker` picks the nearest target within interaction range and lets existing NPC dialogue fallback keep using the AI client path.

## Map Travel

Use `switch_map_async()` or `request_map_transition_async()` for player-facing transitions when possible. The expected sequence is:

1. Lock player input.
2. Show `LoadingOverlay` with the target map name.
3. Save the current map state.
4. Load and render the target map.
5. Place the player at the target spawn.
6. Hide the overlay and unlock input.

Direct `switch_map()` remains available for scripts and deterministic tests.

## Scene Readability

- Building doors should show a small `[E]` label or nearby building label.
- Exits should show a travel label.
- Resources, chests, NPCs, doors, cave entries, and signs should expose typed prompt text.
- `SceneDecorator` adds map-type detail markers while preserving existing generated map content.
- ColorRect fallback remains supported until a future TileMapLayer/TileSet migration is planned.

## Service And Quest Text

`ServiceMenu` text should include building name, action, cost, effect, and availability. `QuestPanel` text should include title, objective progress, reward, and status.

## Manual F5 Checks

M051-M080 in `TEST_REPORT.md` are manual checks. They cover editor launch, first load, movement feel, prompt readability, async travel, repeated map switching, service/quest text, save/load continuity, and known stutter positions. These must stay marked untested until a human visually confirms them in Godot.
