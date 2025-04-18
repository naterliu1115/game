# Memory Bank: Progress (progress.md)

This document tracks the development progress, planned features, and known issues of the TurnBasedBattle project, primarily based on `README.md`.

## Completed Features

*   **Animation:** 8-direction animation system for Player and battle units.
*   **Event System:** Core event manager (`obj_event_manager`) for pub/sub communication.
*   **Battle System:** Basic state machine (`obj_battle_manager`), win/loss conditions, battle result event flow (refactored), floating text/hurt effects, damage calculation (refactored & verified).
*   **Unit System:** Parent classes (`obj_battle_unit_parent`, `obj_player_summon_parent`, `obj_enemy_parent`), basic states (Idle, Attack, Hurt, Die), Wander behavior (non-combat), ATB charging (only in `ACTIVE` state), animation control (manual `image_index`).
*   **Enemy Factory:** (`obj_enemy_factory`) loading from `enemies.csv`, template management (`global.enemy_templates`), instance creation (`obj_test_enemy`), and initialization delegation.
*   **Experience & Leveling:** Enemy XP rewards (`enemies.csv`), XP distribution (`obj_battle_manager`), level curve (`levels.csv`, `obj_level_manager`), unit leveling (`level_up` in `obj_player_summon_parent`), skill learning based on level, visual effects, and immediate data sync to `global.player_monsters`.
*   **Item System:** CSV loading (`items.csv`), basic inventory (`global.player_inventory`), item data management (`obj_item_manager`), multiple item types/rarity, sprite ID handling (refactored with default sprite), hotbar management (`global.player_hotbar`, assign/unassign logic in `obj_item_manager`).
*   **UI System:** Main HUD (`obj_main_hud` with hotbar display, selection, drag-and-drop, bag icon, interaction prompt), Inventory UI (`obj_inventory_ui` with tabs, grid display, scrolling, interaction), Item Info Popup (`obj_item_info_popup` with details, smart positioning, hotbar assignment button), Battle UI (`obj_battle_ui` reward display fixed), standardized monster sprite handling (`display_sprite` field).
*   **Gathering System:** Diggable ore (`obj_stone` with durability, interaction, feedback), flying item animation (`obj_flying_item` with state machine including Scatter/Bounce, world coordinates, outline, quantity display).
*   **Enemy Placer (`obj_enemy_placer`):** Fixed initialization timing issues via `managers_initialized` event.
*   **Data Handling:** Standardized `global.player_monsters` structure, initial monster creation (`obj_game_controller`), capture logic (`obj_capture_ui`), skill data structure (`skills` and `skill_cooldowns` arrays).
*   **Bug Fixes:** Numerous runtime errors resolved (CSV parsing, `ds_list` usage, event callbacks, loot table parsing, `unit_died` event data, duplicate logic removal, UI crashes, sprite display issues).
*   **Utilities:** Custom `is_numeric_safe`, `array_join` functions.

## In Progress / To-Do List

*   **(High Priority) Event Manager:** Implement/fix `trigger_event` function in `obj_event_manager`.
*   **Gathering System:** Further extensions (reserved).
*   **Persistence:** Save/load `global.player_hotbar` (part of broader save system).
*   **UX:** Consider moving interaction prompts closer to targets.
*   **Performance Optimization:** General performance improvements.
*   **Audio:** Add sound effects and music.
*   **Level Design:** Design game levels and overall flow.
*   **Enemy Death/Reward Flow:**
    *   Verify Battle Result UI correctly displays all queued drops.
    *   (Reserved) Refactor battle states to wait for animations (drops, leveling) before showing results UI.
*   **Visuals:** Change `obj_flying_item` outline color based on item rarity.
*   **Battle Log:** Add HUD button, UI panel (`obj_battle_log_ui`), improve log data structure, implement display/formatting.
*   **Battle System Depth:** (Reserved) More status effects, buffs/debuffs, elemental weaknesses, AoE skills, advanced AI, ATB/turn order refinements.
*   **Item/Equipment Expansion:** (Reserved) More consumables, equipment slots (armor, accessories), equipment effects.
*   **Monster Catching/Raising:** (Reserved) Refine capture mechanics, add evolution, skill management, potential/affinity systems.
*   **Crafting System:** (Reserved) Implement crafting using gathered materials.
*   **World Interaction:** (Reserved) More NPCs, quests, shops, exploration elements (chests, gather points, secrets), mini-games.
*   **UI/UX Optimization:** (Reserved) Improve battle info clarity, enhance management UIs (sort, filter, compare), consider non-combat hotbar usage.
*   **Code Structure:** Design `player_monster.gml` for centralized data management.
*   **Data Flow Optimization:** Ongoing review for consistency and synchronization.

## Known Issues

*   **Event Manager:** `trigger_event` function is missing or incorrectly called, causing warnings (e.g., in reward system).
*   **Flying Item (`obj_flying_item`):**
    *   Initial coordinates (`world_to_gui_coords`) might be inaccurate with camera movement/zoom (legacy issue, currently uses world coords).
    *   Targeting `Player.x`, `Player.y` directly in `FLYING_TO_PLAYER` state might cause visual lag with fast camera movement.
*   **UI:** Warnings about hiding `obj_battle_ui` multiple times.

## 已完成/運作中

- **戰鬥結果 UI (`obj_battle_ui`) 事件接收與基礎顯示：**
    - 已修復事件回調機制，`show_rewards` 方法現在能正確被 `show_battle_result` 事件觸發。
    - UI 能接收事件數據並執行顯示邏輯，解決了先前卡住的問題。
- 核心戰鬥循環（召喚、攻擊、技能使用、回合制邏輯）。
- 敵人 AI 基本行為模式。
- 基本單位屬性與統計。
- 戰鬥 UI 框架（顯示單位資訊、技能按鈕）。
- 經驗值與金幣獎勵計算。
- 物品掉落機制基礎（從敵人模板讀取掉落表）。
- CSV 數據導入（敵人、物品、技能）。
- 事件管理器系統。
- 基本粒子效果。
- Tilemap 地形交互基礎。
- 飛行道具創建流程（怪物掉落 + 採集）。
- 飛行道具的 `SCATTERING` 和 `WAIT_ON_GROUND` 狀態基礎物理模擬（使用 Tilemap 檢測地面）。
- **已解決**：飛行道具創建和 Step 事件中的 `string_format` 除錯函數錯誤。
- **已解決**：**事件管理器 `trigger_event` 功能實現：** 在 `obj_event_manager` 中添加了標準的 `trigger_event` 函數，解決了獎勵系統等處觸發事件的警告。
- **已解決**：**重複隱藏 UI 警告修復：** 移除了 `obj_battle_ui` 中 `handle_close_input` 的直接隱藏請求，統一由 `obj_ui_manager` 響應 `battle_end` 事件關閉 UI，解決了重複隱藏警告。
- 技能系統重構進度：尚未完成，目前仍有大量 struct/array 型別錯誤與 bug，尚未達到 array 索引一一對應的目標。主要卡點：技能冷卻初始化、技能新增、技能查找等流程型別不一致，導致崩潰。每次 build 幾乎都會遇到技能冷卻相關錯誤，需持續修正。

## 待辦/已知問題

- **核心問題 - 高優先級:**
    - **事件管理器缺少 `trigger_event` 功能**: 在獎勵系統等處觀察到警告，影響系統間通信。(**當前調查中**)
- **核心問題 - 中優先級:**
    - **戰鬥狀態警告**: 初始化戰鬥時提示 `戰鬥已經在進行中`。
- **功能待完善:**
    - 戰鬥結果 UI 的關閉邏輯需要從 `obj_battle_manager` 遷移到 UI 層。
    - 恢復玩家移動能力。
    - 玩家等級與屬性成長系統。
    - 更豐富的技能類型與效果（狀態異常、Buff/Debuff、範圍效果）。
    - 捕獲怪物機制實現。
    - 物品系統完善（使用、裝備？）。
    - 完整的遊戲流程（地圖移動、觸發戰鬥等）。
    - UI/UX 細節打磨（動畫、反饋）。
- **低優先級問題:**
    - 資源缺失警告 (`spr_...`)。
    - 技能管理器缺少 `on_game_save`/`on_game_load` 回調。
    - `add_battle_log` 缺少 `max_log_lines` 定義。
    - `on_battle_start` 數據缺少 `initial_enemy`。
    - UI 管理器日誌過於頻繁。
- **潛在風險**：
    - 隨著系統複雜度增加，狀態管理和事件交互可能變得困難。
    - 性能優化（尤其是在大量單位或粒子效果時）。

## 未來規劃

- 加入更多敵人種類與技能。
- 設計不同的遊戲區域和關卡。
- 開發劇情或任務系統。
- 建立存檔/讀檔系統。
- 優化使用者介面與體驗。

## 已知問題
- 採集系統掉落尚未工廠化，維護需多處同步
- 飛行道具與 GUI 座標轉換耦合仍有殘留
- 掉落工廠尚未設計，日後需統一管理

## What works

- 核心移動與八方向動畫系統
- 事件系統基本框架 (`obj_event_manager`)
- 戰鬥系統基礎狀態機 (`obj_battle_manager`)
- 敵人系統工廠化 (`obj_enemy_factory` 從 CSV 載入)
- 經驗與升級系統 (基於 CSV, `obj_level_manager`, 單位 `level_up` 邏輯)
- 戰鬥結果事件流 (`finalize_battle_results` 等) 與獎勵計算 (金幣, 掉落物)
- 單位基礎 (`obj_battle_unit_parent`), 包括非戰鬥遊蕩、受傷特效、浮動文字
- 物品系統 (`obj_item_manager` 從 CSV 載入, 背包操作)
- 基礎 UI (HUD, 物品欄, 彈窗, 快捷欄數據與基礎交互)
- 採集系統 (`obj_stone` 挖掘邏輯)
- **飛行道具 (`obj_flying_item`)**: 
    - 狀態機 (`FLYING_UP`, `PAUSING`, `FLYING_TO_PLAYER`, `FADING_OUT`) 基本正常。
    - **`SCATTERING` 狀態**: 已重構為使用 Z 軸物理模擬，實現拋物線、落地、反彈效果。
    - **渲染**: 外框 (`bm_add`) 和數量文字 (跟隨 Z 軸，大小可調) 顯示正常。
    - **狀態**: 等待時 (`WAIT_ON_GROUND`) 不再垂直漂移。
    - **參數**: 水平散開範圍已調整。
- 冗餘代碼清理：移除了 `obj_battle_manager` 中衝突的 `Alarm 0` 和 `scr_coordinate_utils` 中無用的 `world_to_gui_coords`。

## What's left to build

- **核心功能修復**: 實現或修復 `obj_event_manager` 的 `trigger_event` 功能。
- **邏輯遷移**: 將戰鬥結果關閉邏輯移至 UI 層。
- **功能恢復**: 恢復玩家移動。
- **完善快捷欄**: 快捷欄物品使用、與其他 UI (如製作) 的交互。
- **戰鬥結果 UI**: 確認是否正確顯示所有掉落物品；實現更完善的結果展示流程 (等待動畫等)。
- **新增**: **根據物品稀有度改變飛行道具 (`obj_flying_item`) 的外框顏色。**
- **Battle Log**: 實現 UI 面板和詳細日誌記錄。
- **深化戰鬥**: 更多技能、狀態、AI、行動順序機制。
- **豐富物品**: 更多消耗品、裝備、材料。
- **捕捉與養成**: 細化捕捉、技能學習/遺忘、進化等。

## Known Issues

- **(已解決)** 事件管理器 `trigger_event` 功能缺失或調用錯誤。
- **(已解決)** 重複隱藏 UI 的警告。
- 戰鬥狀態初始化警告。
- 飛行道具 (`obj_flying_item`) 在 `FLYING_TO_PLAYER` 狀態下直接使用 `Player.x`, `Player.y` 作為目標，可能在鏡頭快速移動時產生視覺追趕延遲（待觀察）。
- 採集系統掉落尚未工廠化，維護需多處同步
- 掉落工廠尚未設計，日後需統一管理

## 已完成事項
- [x] 戰鬥事件 callback function 完全重構，移除 obj_battle_manager Create 事件內所有 callback function，統一集中於 battle_callbacks.gml。
- [x] Method Bindings 綁定順序修正，確保 battle_callbacks() 執行後再進行事件註冊。
- [x] 測試所有戰鬥事件流程、掉落、經驗、UI 顯示，皆正常無誤。
- [x] 戰鬥結束流程優化，延遲顯示結果，並修正掉落物動畫與狀態切換。
- [x] 掉落工廠化（怪物），採集掉落工廠化規劃中。
- [x] 飛行道具圖層與座標系統優化。

## 進行中事項
- 採集系統掉落工廠化設計與實作
- 掉落工廠統一化（怪物/採集/礦石）
- 飛行道具與 GUI 座標轉換耦合解耦
- UI/UX 優化與戰鬥結果流程完善

## 待辦事項
- 採集掉落工廠化
- 掉落工廠統一化
- world_to_gui_coords 相關耦合移除
- 戰鬥結果關閉邏輯優化
- 其他系統重構與優化
- 技能系統重構進度：尚未完成，目前仍有大量 struct/array 型別錯誤與 bug，尚未達到 array 索引一一對應的目標。主要卡點：技能冷卻初始化、技能新增、技能查找等流程型別不一致，導致崩潰。每次 build 幾乎都會遇到技能冷卻相關錯誤，需持續修正。

## Progress Update

**What Works:**
*   Game initialization sequence seems correct.
*   Enemy factory (`obj_enemy_factory`) loads templates using `template_id` without the previous `GM1008` error.
*   Monster data manager (`monster_data_manager`) appears to correctly create and manage player monster data internally using `template_id`.
*   Enemy placer (`obj_enemy_placer`) correctly reads `template_id` from templates when creating enemy instances.
*   Game controller (`obj_game_controller`) initializes the starting player monster using the manager (`add_monster_from_template`).
*   Summon UI (`obj_summon_ui`) correctly identifies the selected monster and retrieves its data structure (which now contains `template_id`).

**What's Left to Build / Fix:**
*   **Critical:** Fix the monster summoning functionality blocked by the `global.array_clone` scope error.
*   Complete the remaining steps of the player monster data refactoring plan (Steps 5, 7, 8, 9, 10 primarily, Step 6 partially done). This involves replacing direct `global.player_monsters` access in `obj_player_summon_parent`, `obj_unit_manager`, `obj_reward_system`, `obj_battle_manager`, etc., with calls to `monster_data_manager`.
*   Thorough testing of all features affected by the refactoring (summoning, capture, level up, battle rewards, etc.).
*   Remove temporary debug code added to `obj_summon_ui`.

**Current Status:**
*   Actively debugging the summoning runtime error. The core refactoring logic seems mostly in place, but this blocker prevents further progress and testing.

**Known Issues:**
*   **GML Scope Resolution Issue:** A persistent runtime error occurs when `global.array_clone` is called from the global script `summon_monster_from_ui`, specifically when this script is invoked via an anonymous function callback originating from `obj_summon_ui`. The engine incorrectly tries to find an `array_clone` variable within the `obj_summon_ui` instance scope, despite the `global.` prefix. This indicates a potential limitation or bug in GML's scope handling in this context. 

## 近期進度
- [x] UI 管理器 active_ui_instances、ui_manager_clock 已正確初始化。
- [ ] ui_transition_queue 未初始化，導致 Step 事件崩潰，需補上。
- [ ] 檢查所有 Step 事件會用到的變數，統一在 Create 事件最前面初始化。

## Progress

- [x] 怪物資料流統一（所有初始化、升級、同步、顯示皆經由 monster_data_manager，資料來源唯一）
- [x] 屬性計算公式修正（正確反映等級成長）
- [x] UI 顯示正確（資料來源唯一，顯示與資料同步）
- [進行中] 採集系統掉落工廠化
- [進行中] 技能系統 array 索引重構
- [待辦] 戰鬥結果 UI 關閉邏輯遷移到 UI 層 

## 進度追蹤

### 已完成
- monster_data_manager 重構，統一所有玩家怪物資料流。
- UI、捕獲、經驗分配等主要流程已完成重構。
- 事件系統統一，所有事件註冊改為經由 obj_event_manager。

### 進行中
- 測試召喚流程與事件註冊正確性。
- 清理子類（如 obj_test_summon）遺留的錯誤事件註冊。

### 阻塞/待辦
- 子類直接呼叫 subscribe_to_event 的殘留需全部清理。
- 全專案檢查是否還有錯誤事件註冊寫法。
- 召喚流程測試通過後，進行 UI/經驗分配等後續優化。 