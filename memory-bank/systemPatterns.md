# Memory Bank: systemPatterns.md

This file describes the system architecture, key technical decisions, design patterns, and component relationships for the TurnBasedBattle project.

## Architecture Overview

*   **Layered Design:** Separation of game logic, rendering, and resource management. Manager objects orchestrate subsystems.
*   **Event-Driven:** Utilizes `obj_event_manager` for decoupling components and managing communication (e.g., `managers_initialized`, battle events). Provides standard interfaces (`subscribe_to_event`, `unsubscribe_from_event`, `trigger_event`).
*   **Manager Objects:** Centralized managers for core systems (Items, Enemies, Units, Skills, Battle, UI, Level, etc.).
*   **Data Loading:** Initial data (enemies, items, skills, levels, drops) loaded from CSV files, primarily handled by relevant manager objects or factories.
*   **Factory Pattern:** Used for generating enemies (`obj_enemy_factory`) and potentially drops.
*   **State Machines:** Explicit state machines manage complex behaviors (battle system, flying items, unit actions).
*   **Data Storage:** Global variables (`global.enemy_templates`, `global.player_monsters`, `global.level_exp_map`) and manager-internal data structures (ds_maps, ds_grids, arrays) are used.
*   **Core Goal (In Progress):** Refactor to ensure all player monster data (`global.player_monsters`) is accessed and modified *only* through the `monster_data_manager` API.

## Key Technical Decisions

*   **Skill Storage:** Use of GML arrays for `skills` (list of skill IDs or structs) and `skill_cooldowns` within unit instances. Access via numerical index.
*   **Enemy Template Storage:** Enemy templates are loaded by `obj_enemy_factory` and stored in `global.enemy_templates` (ds_map).
*   **Enemy Placement:** `obj_enemy_placer` acts as a blueprint in the room editor, converting to an actual `obj_test_enemy` instance at runtime based on its `template_id`.
*   **Data-Driven Approach:** Items, enemies, skills, and drop tables are managed via CSV files.
*   **Queue/Alarm Driven Flows:** Used for drop animations and battle result sequences.

## Design Patterns & Principles

*   **State Machine Pattern**
*   **Factory Pattern**
*   **Event-Driven Architecture (Pub/Sub)**
*   **Manager Pattern**
*   **Parent-Child Inheritance**
*   **Data-Driven Design**
*   **(From game-rule.mdc) Architecture Adherence:** Always consider the project architecture when adjusting code. Design choices should align with the established architecture.
*   **(From game-rule.mdc) Precise Corrections:** Focus on targeted corrections; avoid unnecessary optimizations.
*   **(From game-rule.mdc & no-assumptions.mdc) Verification Before Action:** 
    *   Strictly avoid making unverified assumptions about code elements (variables, functions, resources, logic, paths).
    *   Always verify code elements using tools (`codebase_search`, `grep_search`, `read_file`), Memory Bank, or by asking the user before referencing or modifying them.
    *   Verification takes priority over proposing solutions quickly.
    *   Briefly cite sources for judgments or proposals when possible.

## Core Component Relationships

*   `obj_game_controller`: Orchestrates overall game flow and manager initialization.
*   `obj_event_manager`: Central hub for event broadcasting and subscriptions.
*   `obj_enemy_factory`: Loads enemy templates from `enemies.csv` into `global.enemy_templates`.
*   `monster_data_manager`: Sole manager for `global.player_monsters` data and operations.
*   `obj_enemy_placer`: Uses `global.enemy_templates` to create `obj_test_enemy` instances.
*   `obj_battle_manager`: Manages battle flow, drops, experience, and related events. Stores `last_battle_result`.
*   `obj_item_manager`: Manages item data, inventory, and hotbar.
*   `Player`: Player character object, target for item collection.
*   `obj_flying_item`: Handles drop animations and collection.
*   **UI Objects:**
    *   `obj_ui_manager`: Manages display, hiding, and layering of all major UI elements.
    *   `obj_main_hud`: Displays persistent HUD elements (hotbar, interaction prompts). **In battle:** Shows alternate buttons (Summon, Capture, Tactic) and battle-specific info (time, unit counts, tactic mode, cooldowns).
    *   `obj_battle_ui`: **Simplified role.** Primarily used for displaying temporary info text in the center of the screen via `show_info()`. Triggers the display of the result popup.
    *   `obj_inventory_ui`, `obj_monster_manager_ui`, `obj_summon_ui`, `obj_capture_ui`, `obj_item_info_popup`: Handle specific UI tasks (inventory management, monster management, summoning selection, capture interface, item details).
    *   `obj_battle_result_popup`: **Dedicated popup** displayed via `obj_ui_manager` to show battle outcome (victory/defeat, stats, item drops) with animations.

# System Patterns Update

## Data Management
*   **Player Monster Data:** Centralized management of `global.player_monsters` (Array) is enforced through `scripts/monster_data_manager/monster_data_manager.gml`. All modifications (add, remove, update) MUST go through functions provided by this manager script. Direct access/modification of `global.player_monsters` is being actively refactored out.
*   **Monster Template Identification:** The standard key for identifying monster templates across data structures (factory templates, player monster data) is `template_id`. (Previously inconsistent usage of `id` caused errors and has been corrected).

## Potential Challenges / Anti-Patterns Observed
*   **GML Scope Resolution with Callbacks:** Observed difficulties with scope resolution when calling global built-in functions (like `global.array_clone`) from within global scripts, especially if the initial call originates from an anonymous function defined within an object instance (`obj_summon_ui`). The `global.` prefix may not reliably force global scope lookup in such nested/indirect call chains. Consider workarounds like local function implementations or passing necessary functions/data explicitly. 

## GameMaker 防禦性設計原則
- 任何 GameMaker 物件的成員變數（ds_map、ds_list、計數器等）必須在 Create 事件最前面初始化。
- Step/Draw/Alarm 事件不得假設變數已存在，必須有明確初始化流程。
- 常見錯誤：只在用到變數前才初始化，導致重構或流程分支後產生未初始化錯誤。 

## 怪物資料流規範

- 所有玩家怪物資料初始化、升級、同步、顯示，必須經由 monster_data_manager。
- 嚴禁直接操作 global.player_monsters。
- 資料來源唯一，確保一致性與防禦性。 

## [2024/06/XX] 架構進度與挑戰
- 玩家怪物資料流已完全模組化，所有資料存取經由 monster_data_manager API，禁止直接操作 global 變數。
- 事件系統採用集中式事件管理（obj_event_manager），所有事件註冊/廣播/取消皆統一接口。
- 目前挑戰：
  - 子類（如 obj_test_summon）遺留直接呼叫 subscribe_to_event，導致 scope 錯誤。
  - 需確保所有事件註冊皆經由 obj_event_manager，並清理錯誤寫法。
- 架構優化方向：進一步抽象事件註冊流程，減少重複與人為錯誤。 

# 系統設計模式

- UI routine log 採「註解保留」策略，遇到 bug 可快速恢復。
- UI 管理器、物品欄、彈窗等物件間的互動模式已標準化，所有 UI 關閉/切換均透過 UI 管理器協調。 