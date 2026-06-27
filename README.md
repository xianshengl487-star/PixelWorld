# PixelWorld

PixelWorld is a Godot 4 top-down pixel RPG prototype. The current pushed version is **v0.2.1**, focused on a playable v0.2.0 foundation plus a repeatable placeholder pixel-art asset expansion pack.

## Current Version

- Version: `v0.2.1`
- Engine: Godot `4.7.stable`
- AI mode: Mock/local only
- Real MiMo / NVIDIA API integration: paused
- TileMapLayer migration: paused
- Multiplayer: not included

## What Is Included

- Main menu to create or continue a world
- Mock world blueprint generation
- 64x64 generated map with validation and repair
- Player movement, HP, stamina, attack, damage, death, and respawn
- NPC spawning and dialogue flow
- Enemy spawning, simple pursuit AI, damage, death, and loot
- Basic interaction system for herbs, chests, signs, and cave prompts
- Simple inventory
- JSON save/load through `SaveManager`
- HUD with HP/stamina bars, log, inventory text, save/load buttons, and free-action input
- Program-generated placeholder pixel assets

## Asset Pack

All generated PNG assets are project-made placeholder art. No third-party assets are downloaded or embedded.

- Generator: `tools/generate_pixel_assets.py`
- Output: `art/generated/`
- Manifest: `ASSET_MANIFEST.md`
- Placeholder notice: `PLACEHOLDER_ART.md`
- Total generated PNG assets: `186`
- Preview sheets: `art/generated/previews/`

Run the generator:

```powershell
python tools\generate_pixel_assets.py
```

## Test Status

Latest recorded result:

- CLI compile validation: PASS
- SmokeTestRunner: `60/62 PASS`
- v0.2.1 asset tests `T051-T062`: `12/12 PASS`
- Remaining known failures: `T025`, `T028`

`T025` and `T028` are retained as CLI headless SceneTree/initialization or collision-count verification issues. They need Godot editor F5 manual validation before being marked fixed.

Run smoke tests:

```powershell
Godot_v4.7-stable_win64_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
```

## Important Development Rules

- Do not connect real MiMo / NVIDIA APIs in this version.
- Do not migrate TileMapLayer yet.
- Do not download third-party art.
- Keep generated assets reproducible through script.
- Update `DEV_LOG.md` for project changes.
- Update `TEST_REPORT.md` after tests.
