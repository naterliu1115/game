# Memory Bank: Project Brief (projectbrief.md)

## Project Goal

Develop a Turn-Based Battle RPG using GameMaker Studio 2 and GML. The project focuses on creating core systems like combat, unit management, item handling, UI, and potentially gathering/crafting, built upon a flexible event-driven architecture.

## Core Systems & Features

*   **Turn-Based Battle System:** Managed by `obj_battle_manager` with distinct states (Inactive, Starting, Preparing, Active, Ending, Result). Includes ATB elements, skill usage, win/loss conditions, experience distribution, and loot calculation.
*   **Unit System:** Manages player summons (`obj_player_summon_parent`) and enemies (`obj_enemy_parent`, `obj_test_enemy`). Includes AI control, state machines (Idle, Wander, Attack, Hurt, Die), animation handling, leveling, and skill acquisition.
*   **Enemy Factory (`obj_enemy_factory`):** Centralizes enemy creation based on data loaded from `enemies.csv`. Manages templates (`global.enemy_templates`) and handles instantiation/initialization.
*   **Player Monster Data Management:** Aims to centralize all operations on `global.player_monsters` through a dedicated manager (future goal), ensuring data consistency for initialization, capture, leveling, and UI display. Standardized data structure includes `id`, `name`, `type`, `level`, stats (`hp`, `max_hp`, etc.), `exp`, `skills`, and `display_sprite`.
*   **Item System (`obj_item_manager`):** Manages item data (`items.csv`), player inventory (`global.player_inventory`), and hotbar (`global.player_hotbar`). Supports various item types, rarity, usage effects, and stacking. Includes UI components like inventory (`obj_inventory_ui`), info popups (`obj_item_info_popup`), and the main HUD (`obj_main_hud`).
*   **Animation System:** Provides a shared, customizable 8-direction animation controller for player and battle units, managing frame sequences and speeds.
*   **Event System (`obj_event_manager`):** Enables decoupled communication between game objects via publish/subscribe pattern.
*   **UI System (`obj_ui_manager`):** Manages various UI elements (HUD, Battle, Inventory, Monster Management, Summon, Capture, Dialogue).
*   **Gathering System:** Allows interaction with world resources (e.g., `obj_stone`) using tools to gain materials, featuring visual feedback and flying item animations (`obj_flying_item`).
*   **Dialogue System:** Manages NPC interactions.
*   **Floating Text/Effects:** Displays damage numbers (`obj_floating_text`) and visual effects (e.g., `obj_hurt_effect`).

## Design Philosophy

*   **Global Data Management:** Key player data (`inventory`, `gold`, `monsters`) stored in `global` variables for easy access across systems. (Future goal: Access controlled via managers).
*   **Event-Driven Architecture:** Loose coupling between systems using `obj_event_manager`.
*   **Data-Driven:** Core game data (items, enemies, levels, skills) defined in CSV files.
*   **Layered & Managed:** Separation of concerns using Manager objects.
*   **Factory Pattern:** Used for enemies.
*   **State Machines:** Control complex flows (battle, units, flying items).
*   **Inheritance:** Parent objects define shared logic.

# 專案簡介

- 專案核心目標（回合制戰鬥、道具管理、彈窗互動）已落實，UI 維護性提升。
- 使用者體驗與 debug 便利性兼顧，log 管理策略明確。
