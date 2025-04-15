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

- **核心問題**: 調查 `obj_flying_item` 在多個狀態下 (包括 `FLYING_UP`, `WAIT_ON_GROUND`, `FLYING_TO_PLAYER`) 出現的非預期物理行為。主要現象是 `vspeed` 持續異常增加，導致道具無法正常執行預期動作（如飛向玩家、正常向上飛行）。
- **主要懷疑**: 問題根源很可能來自 `obj_flying_item` 的父物件繼承了其 `Step` 事件中的通用物理程式碼，干擾了子物件特定狀態的運動邏輯。
- **已排除**: 之前遇到的 `string_format` 函數參數錯誤問題已經通過改用字串串接的方式解決。
- **已執行**: 在 `obj_flying_item` 和其創建者 (`obj_stone`, `obj_battle_manager`) 中添加了大量除錯訊息以追蹤狀態和變數。

## 近期變更

- 修正了 `obj_flying_item` 和 `obj_battle_manager` 中所有 `show_debug_message` 的 `string_format` 函數調用錯誤，改為使用字串串接。
- 在 `obj_flying_item` 中加入了 Y 座標異常檢查與銷毀邏輯。
- 在 `obj_flying_item` 的 `FLYING_UP` 狀態加入了詳細除錯。
- 在 `obj_flying_item` 從 `WAIT_ON_GROUND` 切換到 `FLYING_TO_PLAYER` 前加入了速度重置。
- 在 `obj_stone` 創建飛行道具時加入了詳細除錯。
- 縮短了 `obj_battle_manager` 創建多個掉落物之間的延遲。
- **重構 `obj_flying_item` 物理邏輯：**
  - 移除了舊的 `gravity` 和基於 Tilemap 的落地檢測。
  - **引入 Z 軸模擬 (`z`, `zspeed`, `gravity_z`)** 用於 `SCATTERING` 狀態，實現拋物線和反彈效果。
  - 在 `Draw` 事件中根據 `z` 調整 `draw_y`，並處理 `WAIT_ON_GROUND` 的浮動效果。
- **修正 `obj_flying_item` 渲染問題：**
  - 恢復了 `Draw` 事件中使用 `bm_add` 的外框繪製，使其效果與原始一致。
  - 修正了數量文字的 Y 座標計算，使用 `draw_y` 使其跟隨 Z 軸移動。
  - 使用 `draw_text_transformed` 和 `quantity_scale` 變數，允許獨立調整數量文字的大小。
- **修正 `obj_flying_item` 狀態切換 Bug：**
  - 在 `SCATTERING` 切換到 `WAIT_ON_GROUND` 時，**加入了 `vspeed = 0;`**，解決了等待時的垂直漂移問題。
- **調整掉落效果參數：**
  - 在 `obj_battle_manager` 的 `Alarm 1` 中，為 `SCATTERING` 狀態的 `obj_flying_item` **賦予了初始 `zspeed`** (random_range(3, 5))，以產生拋物線。
- **清理冗餘代碼：**
  - 清空了 `obj_battle_manager` 的 `Alarm 0` 事件內容，因其邏輯與當前設計衝突。
  - 從 `scr_coordinate_utils.gml` 中移除了不再需要的 `world_to_gui_coords` 函數。

## 下一步行動
- ~~完成礦石掉落 quantity 傳遞修正~~ (似乎已包含在飛行道具重構中)
- ~~記錄所有掉落來源，規劃掉落工廠設計~~ (掉落已由 `obj_battle_manager` 在 `on_unit_died` 中計算)
- 優化戰鬥結果 UI 與掉落顯示 (確認是否正確顯示所有掉落物)
- **新增功能**: 規劃並實作根據物品稀有度改變飛行道具 (`obj_flying_item`) 外框顏色的功能。

## 已知技術債
- 採集系統掉落尚未工廠化
- 飛行道具與 GUI 座標轉換耦合
- UI/UX 細節與部分動畫流程待優化

## 下一步計劃 (移交至新聊天室)

1.  確認 `obj_flying_item` 是否有父物件。
2.  如果存在父物件，檢查父物件的 `Step` 事件內容。
3.  優先考慮在 `obj_flying_item` 的 `Step_0.gml` 中，針對**不需要**物理效果的狀態 (`FLYING_UP`, `PAUSING`, `FLYING_TO_PLAYER`, `WAIT_ON_GROUND`, `FADING_OUT`) 明確設置 `gravity = 0;` 來覆蓋父物件的影響。
4.  重新測試飛行道具（採集和怪物掉落）的運動行為。
5.  （次要）如果需要，調整 `obj_flying_item` 的 `scatter_speed_min/max` 以改善噴射視覺效果。

## 活躍決策點

- 需要確定如何處理父物件繼承事件對 `obj_flying_item` 物理狀態的干擾。 