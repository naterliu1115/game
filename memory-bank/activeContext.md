# activeContext.md

## 當前重點工作
- 採集系統與礦石掉落流程優化
- 飛行道具座標與動畫同步修正
- 怪物/採集掉落工廠化規劃
- UI/UX 優化與戰鬥結果流程完善

## 近期決策與備忘
- 【架構備忘】掉落工廠統一化
  - 目前怪物掉落已工廠化，採集/礦石掉落尚未統一。
  - 未來需設計共用掉落工廠，提升維護性與彈性。
  - 工廠化後可集中管理掉落規則、支援複數掉落、方便平衡與擴充。
- 【座標系統優化】
  - 飛行道具全程運作於世界層，避免 GUI/世界座標混用。
  - world_to_gui_coords 相關耦合待完全移除。
- 【戰鬥結果流程】
  - 採用事件流與佇列，確保掉落動畫、升級動畫與 UI 顯示順序正確。

## 當前工作焦點

- **(已解決)** 調查 `obj_flying_item` 在多個狀態下出現的非預期物理行為（如 `vspeed` 異常增加）。
    - **根本原因已查明並修正**: 
        - `SCATTERING` 狀態缺乏 Z 軸高度模擬，導致基於 `vspeed` 和舊 Tilemap 檢測的物理行為不符合俯視角預期。
        - 從 `SCATTERING` 切換到 `WAIT_ON_GROUND` 時未重置 `vspeed`，導致等待時垂直漂移。
    - **最初懷疑**: 曾懷疑問題來自父物件繼承 `Step` 事件，但已確認 `obj_flying_item` **沒有父物件**，此猜測不成立。

## 近期變更

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

- **(當前主要任務)** **新增功能**: 規劃並實作根據物品稀有度改變飛行道具 (`obj_flying_item`) 外框顏色的功能。
- 優化戰鬥結果 UI 與掉落顯示 (確認是否正確顯示所有掉落物)

## 已知技術債
- 採集系統掉落尚未工廠化
- 飛行道具與 GUI 座標轉換耦合
- UI/UX 細節與部分動畫流程待優化

## 活躍決策點

- 如何實現基於稀有度的外框顏色變更？（涉及讀取物品數據、定義顏色映射、修改 Draw 事件）。 