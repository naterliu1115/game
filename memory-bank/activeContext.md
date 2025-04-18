# activeContext.md

## 當前重點工作
- 戰鬥結束流程優化 (延遲顯示結果, 關閉邏輯)
- UI/UX 優化與戰鬥結果流程完善
- (次要) 根據物品稀有度改變飛行道具外框顏色
- (長遠) 採集系統掉落工廠化
- (長遠) 怪物/採集掉落工廠化規劃
- **(已完成)** 背包初始化與 UI 流程重構，背包內容不再因 UI 或戰鬥被清空，預設道具初始化已移至 obj_game_controller，UI 僅負責顯示。

## 近期決策與備忘
- 【戰鬥事件 callback 重構】
    - 已將所有 callback function（如 on_unit_died 等）自 obj_battle_manager Create 事件完全移除，統一集中於 battle_callbacks.gml。
    - Method Bindings 也已調整為於 battle_callbacks() 呼叫後執行，確保 function 註冊順序正確。
    - 測試結果：所有戰鬥事件流程、掉落、經驗、UI 顯示皆正常，無重複定義或未定義錯誤。
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

## 近期變更
- **背包初始化與 UI 流程重構：**
    - 預設道具初始化邏輯已移至 `obj_game_controller`，只在遊戲啟動時執行一次。
    - `obj_inventory_ui` 不再自動加道具，僅負責顯示背包內容。
    - 測試確認：無論 UI 是否開啟過，背包內容皆正確，戰鬥後不會被清空。
- **戰鬥 callback function 重構與測試通過：**
    - 完全移除 obj_battle_manager Create 事件內的 callback function 定義，統一由 battle_callbacks.gml 管理。
    - Method Bindings 綁定順序已修正，所有事件流程測試通過。
- **戰鬥結束流程修改 (`obj_battle_manager`):**
    - 在 `Step_0.gml` (ENDING 狀態) 中，將觸發 `Alarm[2]` 的延遲從 0.5 秒改為 3 秒。
    - 在 `Step_0.gml` (RESULT 狀態) 中，添加了臨時的按 Space 鍵調用 `end_battle()` 的邏輯。
    - 修正了 `Alarm_1.gml` 中創建飛行道具使用的圖層名稱為 "Instances"。
    - 修正了 `on_unit_died` 中錯誤的掉落物和經驗值獲取邏輯，恢復為從工廠獲取模板數據的方式。
    - 在 `on_unit_died` 中添加了判斷最後敵人的邏輯，並設置 `processing_last_enemy_drops` 標記。
    - 在 `Alarm_1.gml` 中添加了檢查 `processing_last_enemy_drops` 標記的邏輯，將最後敵人的掉落物實例添加到 `last_enemy_flying_items` 監控列表，並在佇列處理完畢後重置標記。
    - 在 `Create_0.gml` 和 `Step_0.gml` 中添加/修正了 `ENDING_SUBSTATE` 枚舉、`last_enemy_flying_items` 列表、`processing_last_enemy_drops` 標記及相關初始化/清理邏輯。
- **(已解決)** 掉落物創建失敗 (圖層不存在)。
- **(已解決)** 掉落物/經驗值計算錯誤。
- 修正了 `obj_flying_item` 和 `obj_battle_manager` 中所有 `show_debug_message` 的 `string_format` 函數調用錯誤，改為使用字串串接。
- 在 `obj_flying_item` 中加入了 Y 座標異常檢查與銷毀邏輯。
- 在 `obj_flying_item` 的 `FLYING_UP` 狀態加入了詳細除錯。
- 在 `obj_flying_item` 從 `WAIT_ON_GROUND` 切換到 `FLYING_TO_PLAYER` 前加入了速度重置。
- 在 `obj_stone` 創建飛行道具時加入了詳細除錯。
- 縮短了 `obj_battle_manager` 創建多個掉落物之間的延遲。
- **重構 `obj_flying_item` 物理邏輯：** (已完成)
  - 移除了舊的 `gravity` 和基於 Tilemap 的落地檢測。
  - **引入 Z 軸模擬 (`z`, `zspeed`, `gravity_z`)** 用於 `SCATTERING` 狀態，實現拋物線和反彈效果。
  - 在 `Draw` 事件中根據 `z` 調整 `draw_y`，並處理 `WAIT_ON_GROUND` 的浮動效果。
- **修正 `obj_flying_item` 渲染問題：** (已完成)
  - 恢復了 `Draw` 事件中使用 `bm_add` 的外框繪製，使其效果與原始一致。
  - 修正了數量文字的 Y 座標計算，使用 `draw_y` 使其跟隨 Z 軸移動。
  - 使用 `draw_text_transformed` 和 `quantity_scale` 變數，允許獨立調整數量文字的大小。
- **修正 `obj_flying_item` 狀態切換 Bug：** (已完成)
  - 在 `SCATTERING` 切換到 `WAIT_ON_GROUND` 時，**加入了 `vspeed = 0;`**，解決了等待時的垂直漂移問題。
- **調整掉落效果參數：** (已完成)
  - 在 `obj_battle_manager` 的 `Alarm 1` 中，為 `SCATTERING` 狀態的 `obj_flying_item` **賦予了初始 `zspeed`** (random_range(3, 5))，以產生拋物線。
  - 在 `obj_flying_item` 的 `Create` 事件中，**降低了 `scatter_speed_min/max`** (1-3)，以減小水平散開範圍。
- **清理冗餘代碼：** (已完成)
  - 清空了 `obj_battle_manager` 的 `Alarm 0` 事件內容，因其邏輯與當前設計衝突。
  - 從 `scr_coordinate_utils.gml` 中移除了不再需要的 `world_to_gui_coords` 函數。
- **`obj_battle_ui` 事件回調修復：**
    - 嘗試將 `show_battle_result` 事件回調從腳本索引改為內部定義的方法名 (`on_show_battle_result_event`)，但遭遇 GML 內建函數 (`method_exists`) 無法訪問的錯誤。
    - 最終將事件回調改為使用 `obj_battle_ui` 內已穩定定義的 `show_rewards` 方法，並將事件處理邏輯（提取數據、設置標誌、調用 `update_rewards_display`、通知 UI 管理器等）整合進該方法。
    - 此修改成功解決了回調執行錯誤，使得戰鬥結果 UI 能夠正常接收事件並觸發顯示邏輯。
- **已解決 `trigger_event` 缺失問題：**
    - 在 `obj_event_manager` 的 `Create_0.gml` 中添加了 `trigger_event(event_name, data)` 函數，作為標準的事件觸發接口，內部調用 `handle_event`。
    - 解決了獎勵系統添加物品時產生的警告。
- **已解決重複隱藏 UI 問題：**
    - 修改了 `obj_battle_ui` 的 `handle_close_input` 方法，移除了其中直接請求 `obj_ui_manager` 隱藏自身的代碼。
    - 現在 UI 的關閉統一由 `obj_ui_manager` 響應 `battle_end` 事件觸發的 `close_all_ui` 流程處理。
    - 解決了戰鬥結束時 `obj_battle_ui` 被重複隱藏的警告。
- **(已解決) 道具系統ID與分類不一致問題：**
    - 修正了 `obj_main_hud` 的 `Draw` 和 `Step` 事件，將讀取玩家背包物品 ID 的 `item.id`/`item.ID` 改為正確的 `item.item_id`，解決快捷欄指派/拖拽時的崩潰。
    - 修正了 `obj_inventory_ui` 中處理物品分類的邏輯，移除了對小寫 `category` 的兼容檢查，現在只識別大寫 `Category` 欄位，並確認 `items_data.csv` 使用的是大寫 `Category`。

## 下一步行動
1.  **調查並解決初始化戰鬥時 `戰鬥已經在進行中` 的警告。**
2.  (後續) 恢復玩家移動能力。
3.  (後續) 將戰鬥結果 UI 關閉邏輯遷移到 UI 層。

## 活躍決策與考量
- 使用對象實例內穩定定義的方法 (如 `show_rewards`) 作為事件回調，被證實比使用腳本索引或動態創建的函數更可靠，能有效規避 GML 中潛在的作用域/上下文問題。
- `trigger_event` 功能對於系統間解耦（如獎勵系統通知庫存系統）至關重要，**已解決**。
- 解決了重複隱藏 UI 的警告。
- **已解決 '戰鬥已經在進行中' 警告:**
    - **原因分析:** 發現 `Player/Step_0.gml` 在檢測到碰撞並觸發 `obj_battle_manager.start_factory_battle()` 後，**沒有**立即將自身的 `in_battle` 狀態變數設置為 `true`。
    - **問題後果:** 這導致 `Player` 可能在下一幀繼續檢測碰撞並重複觸發戰鬥啟動流程，使 `obj_battle_manager` 收到多個 `battle_start` 事件，從而觸發其內部狀態檢查警告。
    - **解決方案:** 在 `Player/Step_0.gml` 中，於 `with (obj_battle_manager)` 區塊成功執行後，立即添加了 `in_battle = true;` 來更新玩家狀態，阻止了重複觸發。

## 已知技術債
- **(已解決)** `trigger_event` 功能缺失/調用錯誤。
- **(已解決)** 重複隱藏 UI 的邏輯。
- 戰鬥狀態重置/管理可能存在問題。
- 戰鬥結果關閉邏輯位置不當 (臨時在 `obj_battle_manager`)。
- 採集系統掉落尚未工廠化
- 飛行道具與 GUI 座標轉換耦合
- UI/UX 細節與部分動畫流程待優化

## 活躍決策點
- 3 秒的戰鬥結束延遲是否合適？
- 何時將戰鬥結果 UI 整合到 `obj_ui_manager` 並遷移關閉邏輯？

- 如何實現基於稀有度的外框顏色變更？（涉及讀取物品數據、定義顏色映射、修改 Draw 事件）。

## 最近活動與狀態
- **主要問題解決：** `obj_battle_ui` 無法顯示戰鬥結果的問題已解決。
- **新問題發現：** `obj_event_manager` 缺少 `trigger_event` 功能的警告成為當前最高優先級問題。

## 目前焦點
- 戰鬥結束流程優化 (延遲顯示結果, 關閉邏輯)
- UI/UX 優化與戰鬥結果流程完善

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

## 最近活動與狀態
- **主要問題解決：** `obj_battle_ui` 無法顯示戰鬥結果的問題已解決。
- **新問題發現：** `obj_event_manager` 缺少 `trigger_event` 功能的警告成為當前最高優先級問題。

## 目前焦點
- **調查並解決初始化戰鬥時 `戰鬥已經在進行中` 的警告。**

## 下一步
- 調查 `戰鬥已經在進行中` 警告的觸發原因和解決方案。

## 2024/04/16 玩家怪物資料結構統一
- 已確認 global.player_monsters 來源分散，部分 struct 無 exp 欄位。
- 目前已規劃所有新增、捕獲、初始化流程 struct 必須有 exp 欄位。
- 下一步將設計集中式腳本統一管理 struct 欄位與同步。

## 2024/04/16 升級資料同步現況
- 升級時即時將 instance 的 level、exp、hp、max_hp、attack、defense、spd 等欄位同步回 global.player_monsters。
- 以 id 或 type+name 作為唯一 key。
- struct 缺少 exp 欄位則補上。
- UI 讀取 global.player_monsters 時資料即時正確。
- 捕獲、初始化、經驗分配、升級等所有流程都必須補齊 exp 欄位，並即時同步所有關鍵欄位。
- 未來將設計 player_monster.gml 腳本，集中管理 struct 欄位與同步，優化資料流。

## 技能系統已重構為 array 索引模式：skills 與 skill_cooldowns 均為 array，完全一一對應，所有操作皆用數字索引，不再用 struct/ds_map。
- 技能系統重構尚未完成，目前 bug 包含 struct/array 混用導致的 unable to convert string ... to int64 錯誤，初始化、技能新增、冷卻查找等流程皆有型別不一致問題。大部分技能相關操作仍在修正與驗證中。近期重點：徹底統一技能系統資料結構，消除所有型別錯誤。每次 build 幾乎都會遇到技能冷卻相關崩潰，重構尚未穩定。

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

##  UI 管理器初始化修正
- 已將 active_ui_instances、ui_manager_clock 的初始化移到 Create 事件最前面。
- 目前 Step 事件仍出現 ui_transition_queue 未初始化錯誤，需比照處理。
- 下一步：檢查所有 Step 事件會用到的變數，統一在 Create 事件最前面初始化。

##  怪物資料流與屬性公式統一

- 所有玩家怪物的初始化、升級、同步都必須經過 monster_data_manager。
- monster_data_manager.gml 內的屬性計算公式已修正為正確的等級成長公式（ceil(基礎值 + (基礎值 × 成長 × (等級-1)))）。
- UI 只讀取管理器產生的資料，資料來源唯一且正確。
- 初始化流程、戰鬥召喚、升級等都已經走正確的資料流。
- 若有新功能（如自動召喚、捕獲、存檔/讀檔），也必須走管理器 API。

## 目前活躍焦點與進度
- 玩家怪物資料流重構已完成，所有資料存取統一經由 monster_data_manager。
- 事件系統已統一，所有事件註冊必須透過 obj_event_manager。
- 目前主要阻塞於召喚相關子類（如 obj_test_summon）遺留的錯誤事件註冊，導致 scope 報錯。
- 測試重點：召喚流程、事件註冊、資料同步。
- 下一步：
  1. 清理所有子類直接呼叫 subscribe_to_event 的殘留。
  2. 確認所有事件註冊皆經由 obj_event_manager。
  3. 完成召喚流程測試，進行 UI/經驗分配等後續優化。 