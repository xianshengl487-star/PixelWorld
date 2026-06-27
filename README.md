# PixelWorld

PixelWorld is a Godot 4 top-down pixel RPG prototype. The current version is **v0.3.0**, focused on a codebase audit, safe generated-art fallback, and a data-driven world progression system.

## Current Version

- Version: `v0.3.0`
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
- HUD with HP/stamina bars, inventory text, logs, save/load buttons, free-action input, and progression summary
- Program-generated placeholder pixel assets
- v0.3.0 world progression templates for xianxia, magic, apocalypse, cyberpunk, wuxia, urban ability, strange tale, and star sci worlds

## v0.3.0 Progression System

PixelWorld now treats growth as a world-specific system rather than a generic level number.

- Xianxia uses realms, minor stages, cultivation progress, bottlenecks, breakthrough attempts, heart-demon risks, and tribulation records.
- Magic uses mage ranks, spell research, elemental trials, forbidden-spell backlash, and academy attention.
- Apocalypse uses awakening ranks, crystal cores, infection resistance, gene stability, and monster aggression.
- Cyberpunk uses cybernetic synchronization, surgery risks, corporate attention, and cyber-psychosis pressure.
- Wuxia uses inner power, meridian breakthroughs, qi deviation, and jianghu fame.
- Urban ability uses official ratings, mental stability, exposure risk, and ability rampage consequences.
- Strange tale uses rule understanding, pollution adaptation, sanity pressure, and entity attention.
- Star sci uses technology points, ship modules, civilization recognition, faction attention, and trade-route access.

The progression data is stored in JSON under `data/progression_templates/`, loaded by `ProgressionTemplateLoader`, and persisted by `SaveManager`.

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

- v0.3.x: connect progression rewards to real combat/exploration loops and tune breakthrough costs.
- v0.4.x: replace more ColorRect map placeholders with generated tiles and item icons.
- v0.5.x: add editor-verified manual gameplay checks for player movement, NPC interaction, collision blocking, and HUD layout.
- Later: revisit TileMapLayer/TileSet migration after core gameplay is stable.
- Later: real AI provider integration only after local/mock gameplay remains deterministic and safe.

## Test Status

Latest recorded result for v0.3.0:

- CLI compile validation: PASS
- SmokeTestRunner: `96/97 PASS`
- New v0.3.0 tests `T081-T115`: `35/35 PASS`
- Remaining known failure: `T025`
- `T028` result in this run: PASS

`T025` is retained as a CLI headless SceneTree/initialization verification issue. It needs Godot editor F5 manual validation before being marked fixed.

Run smoke tests:

```powershell
Godot_v4.7-stable_win64_console.exe --headless --path . --script res://scripts/tests/SmokeTestRunner.gd
```

## Important Development Rules

- Do not connect real MiMo / NVIDIA APIs in this version.
- Do not migrate TileMapLayer yet.
- Do not download third-party art.
- Keep generated assets reproducible through script.
- Keep progression templates data-driven JSON, not hardcoded into Player or GameWorld.
- Update `DEV_LOG.md` for project changes.
- Update `TEST_REPORT.md` after tests.
