# PixelWorld v0.4.2 Quest System

v0.4.2 adds a small deterministic quest layer for building services and map events. It is intentionally local/mock friendly and does not call real AI providers.

## Goals

- Let village buildings provide gameplay hooks, starting with the notice board.
- Track active, completed, and turned-in quests in save data.
- Update quest objectives from simple events: enemy defeats, item collection, map visits, object interaction, chest opening, and NPC talk.
- Keep the first version data-driven through `data/quests/basic_quests.json`.

## QuestData

Each quest stores:

- `quest_id`, `title`, `description`
- `source_type`, `source_id`
- `status`: `available`, `active`, `completed`, `turned_in`, or `failed`
- `objectives`
- `rewards`
- `required_flags`
- `required_realm_order`
- `repeatable`
- `map_scope`

## Objective Types

- `defeat_enemy`
- `collect_item`
- `visit_map`
- `interact_object`
- `open_chest`
- `talk_to_npc`

## Building Notice Board

`BuildingService` handles `quest_board` by loading `QuestSystem`, reading `basic_quests.json`, and returning the available quest list. Accepting quests is handled by `QuestSystem.accept_quest(quest_id)`.

## Event Updates

- Enemy death sends `defeat_enemy`.
- Interactable collection sends `collect_item`.
- `GameWorld.load_map()` sends `visit_map`.
- Interactables send `interact_object` or `open_chest`.

The first version keeps these events simple and deterministic.

## Rewards

Supported reward keys are:

- `coin`
- `items`
- `progression_points`
- `faction_attitude`
- `unlock_flags`

## Save Data

`WorldState.quest_state` is persisted by `SaveManager` under `quest_state`. v0.4.2 saves also include `save_version`.

## Future UI

The HUD now exposes a compact quest text method. A later version can add a dedicated quest panel with accept/turn-in buttons, richer descriptions, and map markers.
