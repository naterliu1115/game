# activeContext.md

## 當前重點工作
- **(新)** 調試工具 (`obj_debug_inventory_tool`) 功能完善與確認 (處理"查詢類型"按鈕最終方案)。


## 近期決策與備忘
- **【庫存調試工具開發】**
    - **已創建** `obj_debug_inventory_tool` 對象，設為 Persistent。
    - **已實現** F1 鍵顯示/隱藏。
    - **已實現** 輸入框 (Item ID, Quantity, Item Type) 和結果顯示區域。
    - **已實現** 「添加」、「移除」、「查詢數量」按鈕功能，可調用 `obj_item_manager` 的對應函數。
    - **已實現** 輸入驗證：
        - 添加/移除：數量為空時默認為 1。
        - 添加/移除/查詢數量：Item ID 為空時提示錯誤。
    - **已修改** 「查詢類型」按鈕功能，改為根據輸入的 Item ID 查詢並顯示該道具的類型。
    - **已修復** 創建過程中的錯誤：
        - 修正了 `persistent` 屬性未正確設置的問題。
        - 將繪圖輔助函數 (`draw_input_box`, `draw_button`) 從 Draw GUI 事件移至 Create 事件定義為方法，解決了參數類型錯誤。
        - 重新命名了自定義繪圖輔助函數 (`custom_draw_input_box`, `custom_draw_button`)，避免與 GML 內建函數衝突。
- 【戰鬥結果流程優化】
    - 觸發結果顯示的時機改為：最後敵人掉落物完成 SCATTERING 動畫 + 3 秒延遲。
    - **(臨時措施)** 在 `obj_battle_manager` 的 `RESULT` 狀態直接添加了按 Space 鍵關閉結果畫面的邏輯。
    
- 【架構備忘】掉落工廠統一化
  - 目前怪物掉落已工廠化，採集/礦石掉落尚未統一。
  - 未來需設計共用掉落工廠，提升維護性與彈性。
  - 工廠化後可集中管理掉落規則、支援複數掉落、方便平衡與擴充。

- 【座標系統優化】
  - 飛行道具全程運作於世界層，避免 GUI/世界座標混用。
  - world_to_gui_coords 相關耦合待完全移除。
- **(已解決)** `trigger_event` 功能缺失/調用錯誤。
- **(已解決)** 重複隱藏 UI 的邏輯。
- **(已解決)** 戰鬥狀態初始化警告 (`戰鬥已經在進行中`)。
- 戰鬥結果關閉邏輯位置不當 (臨時在 `obj_battle_manager`)。
- 採集系統掉落尚未工廠化
- 飛行道具與 GUI 座標轉換耦合

## 當前工作焦點
- **調查並解決初始化戰鬥時 `戰鬥已經在進行中` 的警告。**


## 下一步行動
1.  **調查並解決初始化戰鬥時 `戰鬥已經在進行中` 的警告。**
2.  (後續) 恢復玩家移動能力。
3.  (後續) 將戰鬥結果 UI 關閉邏輯遷移到 UI 層。
4.  與用戶確認「查詢類型」按鈕的最終處理方案（維持現狀、移除、或新增功能）。
5.  根據決定，可能需要修改 `obj_debug_inventory_tool`。
6.  繼續原有的待辦事項 (採集工廠化等)。

## 活躍決策與考量
- 調試工具的輸入驗證邏輯已根據易用性進行調整（數量默認值，ID空值檢查）。
- 將輔助函數定義為 Create 事件中的方法，可以避免 Draw 事件中的潛在範圍或執行時機問題。
- 必須仔細檢查專案中所有可能添加初始/測試數據的地方，確保它們符合預期或已被移除/註釋。

## 已知技術債
- 戰鬥狀態重置/管理可能存在問題。
- 戰鬥結果關閉邏輯位置不當 (臨時在 `obj_battle_manager`)。
- 採集系統掉落尚未工廠化
- 飛行道具與 GUI 座標轉換耦合
- UI/UX 細節與部分動畫流程待優化

## 下一步
- (後續) 恢復玩家移動能力。
- (後續) 將戰鬥結果 UI 關閉邏輯遷移到 UI 層。

## 活躍決策與考量
- 解決了重複隱藏 UI 的警告。
- **已解決 '戰鬥已經在進行中' 警告:**
    - **原因分析:** 發現 `Player/Step_0.gml` 在檢測到碰撞並觸發 `obj_battle_manager.start_factory_battle()` 後，**沒有**立即將自身的 `in_battle` 狀態變數設置為 `true`。
    - **問題後果:** 這導致 `Player` 可能在下一幀繼續檢測碰撞並重複觸發戰鬥啟動流程，使 `obj_battle_manager` 收到多個 `battle_start` 事件，從而觸發其內部狀態檢查警告。
    - **解決方案:** 在 `Player/Step_0.gml` 中，於 `with (obj_battle_manager)` 區塊成功執行後，立即添加了 `in_battle = true;` 來更新玩家狀態，阻止了重複觸發。

## 下一步行動
- 繼續優化戰鬥結束流程和 UI/UX。
- (後續) 恢復玩家移動能力。
- (後續) 將戰鬥結果 UI 關閉邏輯遷移到 UI 層。

## 活躍決策與考量
- 解決了重複隱藏 UI 的警告。
- **已解決 '戰鬥已經在進行中' 警告:**
    - **原因分析:** 發現 `Player/Step_0.gml` 在檢測到碰撞並觸發 `obj_battle_manager.start_factory_battle()` 後，**沒有**立即將自身的 `in_battle` 狀態變數設置為 `true`。
    - **問題後果:** 這導致 `Player` 可能在下一幀繼續檢測碰撞並重複觸發戰鬥啟動流程，使 `obj_battle_manager` 收到多個 `battle_start` 事件，從而觸發其內部狀態檢查警告。
    - **解決方案:** 在 `Player/Step_0.gml` 中，於 `with (obj_battle_manager)` 區塊成功執行後，立即添加了 `in_battle = true;` 來更新玩家狀態，阻止了重複觸發。

# 活動開發重點
    - 針對 obj_item_info_popup、obj_inventory_ui、obj_ui_manager 等 UI 物件進行 routine debug 訊息大幅註解，僅保留錯誤、異常、資源釋放失敗等關鍵訊息。
    - UI 彈窗（物品資訊）行為已完全符合需求：只允許單一彈窗、點擊外部自動關閉、ESC 關閉、UI 管理器與物品欄互動邏輯穩定。
    - 測試結果 log 乾淨，功能正常，debug 可隨時恢復。

# Active Context - Player Monster Refactoring & Summoning Bug

**Current Focus:** Resolving a persistent runtime error preventing the monster summoning functionality from working correctly after refactoring player monster data management.

**Recent Changes:**
*   Standardized the use of `template_id` as the key for monster template identifiers across `obj_enemy_factory`, `monster_data_manager`, `obj_enemy_placer`, and related data structures (`create_enemy_base_data`).
*   Fixed the `obj_game_controller` initialization logic to use `add_monster_from_template` from the `monster_data_manager`, ensuring initial monster data uses `template_id`.
*   Corrected the data retrieval logic in `obj_summon_ui` to pass the correct monster data struct (containing `template_id`) to the summoning function.
*   Corrected logic in `monster_data_manager` (`add_monster_from_template`) that incorrectly re-split arrays obtained from the template.

**Current Blocker:**
*   Despite the above fixes, a runtime error persists: `Variable <unknown_object>.array_clone(instance_id, -2147483648) not set before reading it.`
*   This error occurs within the `summon_monster_from_ui` global script (specifically at the `global.array_clone` call) when invoked from an anonymous function within `obj_summon_ui`.
*   The error context incorrectly points to the `obj_summon_ui` instance, suggesting a GML scope resolution issue where the `global.` prefix fails to resolve the built-in function correctly in this specific call chain.

**Next Steps (Proposed):**
*   Modify `scripts/scr_summon_logic/scr_summon_logic.gml`: Replace the problematic `global.array_clone` calls within `summon_monster_from_ui` with a local shallow-copy mechanism (e.g., using `array_copy`) to bypass the suspected scope resolution issue.
*   Test the summoning functionality thoroughly after applying the fix.
*   If successful, remove debug code from `obj_summon_ui`.
*   Continue with the player monster data refactoring plan (`memory-bank/refactor_plan_player_monsters.md`).

**Active Decisions:**
*   Use `template_id` consistently for monster template identification throughout the relevant codebase.

