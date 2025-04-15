# activeContext.md

## 當前重點工作
- 戰鬥結束流程優化 (延遲顯示結果, 關閉邏輯)
- UI/UX 優化與戰鬥結果流程完善
- (次要) 根據物品稀有度改變飛行道具外框顏色
- (長遠) 採集系統掉落工廠化
- (長遠) 怪物/採集掉落工廠化規劃

## 近期決策與備忘
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

## 當前工作焦點
- 驗證戰鬥結束流程修改：
    - 確認延遲 3 秒是否符合預期。
    - 確認 Space 鍵能正常關閉結果畫面。
    - 監控掉落物和經驗值計算是否仍然正常。

## 近期變更
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

## 下一步行動
- **測試當前修改。**
- **(技術債)** 將戰鬥結果畫面的關閉邏輯從 `obj_battle_manager` 移至對應的 UI 物件 (需先整合結果畫面到 `obj_ui_manager`)。
- **(可選)** 根據測試結果微調 3 秒延遲。
- 繼續處理「根據物品稀有度改變飛行道具外框顏色」的功能。

## 已知技術債
- **戰鬥結果關閉邏輯位置不當:** 目前臨時放在 `obj_battle_manager`，應移至專門的 UI 物件。
- 採集系統掉落尚未工廠化
- 飛行道具與 GUI 座標轉換耦合
- UI/UX 細節與部分動畫流程待優化

## 活躍決策點
- 3 秒的戰鬥結束延遲是否合適？
- 何時將戰鬥結果 UI 整合到 `obj_ui_manager` 並遷移關閉邏輯？

- 如何實現基於稀有度的外框顏色變更？（涉及讀取物品數據、定義顏色映射、修改 Draw 事件）。 