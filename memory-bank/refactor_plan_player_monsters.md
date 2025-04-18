# 重構 Player Monsters 數據管理計劃

> **技能資料結構重構已完成，所有技能資料已統一為 array，並移除 struct/ds_map 混用。未來如有異動請重新檢查。**
> ** 召喚流程 scope bug 已解決，callback 內 array 複製已統一用 array_copy 或手動複製，未來如有異動請重新檢查。**
> **事件註冊已全面統一，經驗分配/升級流程補強中。**

此計劃旨在將所有對 `global.player_monsters` 的操作集中到 `scripts/monster_data_manager/monster_data_manager.gml` 中。

## 進度說明（2024/06/XX 更新）
- [x] 玩家怪物資料流重構已完成大部分，monster_data_manager 已統一資料流。
- [x] 召喚流程 scope bug 已解決，callback 內 array 複製已統一用 array_copy 或手動複製。
- [x] 事件系統已統一，所有事件註冊必須透過 obj_event_manager，禁止直接呼叫 subscribe_to_event，部分子類遺留錯誤寫法需清理。
- [x] 測試阻塞於召喚事件註冊錯誤，需先修正子類註冊。
- [ ] 需檢查全專案有無直接呼叫 subscribe_to_event 的殘留。
- [x] 其他資料流、UI、捕獲、經驗分配等流程已完成大部分重構，剩餘步驟見 checklist。
- [ ] 經驗分配/升級流程補強中，需加強 LOG 追蹤與驗證。

## 步驟

- [x] **1. 檢查並分析 `monster_data_manager.gml`：**
    - [x] 讀取現有腳本內容。
    - [x] 分析現有函數和問題（直接操作全域變數、更新邏輯錯誤）。

- [x] **2. 修復並完善 `monster_data_manager.gml`：**
    - [x] 添加 `initialize_player_monsters()` 函數。
    - [x] 添加 `get_player_monsters()` 函數。
    - [x] 添加 `get_monster_by_uid(uid)` 函數。
    - [x] 添加 `get_monster_index_by_uid(uid)` 輔助函數 (用於更新)。
    - [x] 修正 `add_experience(uid, experience)` 中的更新邏輯 (使用 `template_id`)。
    - [x] 修正 `add_experience_batch(uids, experience_array)` 中的更新邏輯。
    - [x] **(已修正)** `add_monster_from_template` 現在創建包含 `template_id` 的結構體。
    - [x] **(已修正)** `add_monster_from_template` 中處理技能解鎖的邏輯已修正。
    - [x] **(已完成)** 技能資料結構已統一為 array，移除 struct/ds_map 混用。
    - [x] **(已完成)** 召喚流程 scope bug 已解決，callback 內 array 複製已統一用 array_copy 或手動複製。
    - [x] **(已完成)** 事件註冊已全面統一。
    - [ ] **(進行中)** 經驗分配/升級流程補強中，需加強 LOG 追蹤與驗證。

- [x] **3. 逐步替換 `obj_game_controller` 中的引用：**
    - [x] 將 `Create_0.gml` 中的 `global.player_monsters = []` 替換為調用 `initialize_player_monsters()`。
    - [x] **(已修正)** 將 `Create_0.gml` 中手動創建和添加初始怪物的邏輯，替換為調用 `add_monster_from_template()`。
    - [x] 將其他讀取操作替換為調用 `get_player_monsters()`。

- [x] **4. 逐步替換 `obj_capture_ui` 中的引用：**
    - [x] 將 `Create_0.gml` 中的 `array_push(global.player_monsters, captured_monster_data)` 替換為調用 `add_player_monster()`。
    - [ ] 修復 `Draw_64.gml` 中的動畫顯示問題，確保捕獲、成功和失敗狀態正確顯示。(待辦)

- [ ] **5. 逐步替換 `obj_player_summon_parent` 中的引用：**
    - [ ] 將 `Create_0.gml` 中升級後直接修改 `global.player_monsters[i]` 的邏輯移除或重構，改為調用 `monster_data_manager` 的更新函數 (如 `add_experience` 或 `update_monster_data`)。(待辦)

- [ ] **6. 逐步替換其他 UI 物件中的讀取引用：**
    - [x] `obj_summon_ui/Create_0.gml`:
        - [x] 讀取 `global.player_monsters` 的循環已通過 `refresh_monster_list` 間接實現。
        - [x] 調用召喚邏輯的部分已修正為傳遞正確的結構體 (包含 `template_id`)。
        - [x] **(阻塞)** 召喚功能本身因 `global.array_clone` 作用域問題而失敗。
    - [ ] `obj_monster_manager_ui/Create_0.gml` (待辦)

- [ ] **7. 逐步替換其他邏輯物件中的引用：**
    - [x] `obj_enemy_placer/Create_0.gml`: 已更新為使用 `template_id`。
    - [ ] `obj_unit_manager/Create_0.gml` (讀取和寫入) (待辦)
    - [ ] `obj_reward_system/Create_0.gml` (讀取) (待辦)
    - [ ] `obj_battle_manager/Step_0.gml` (讀取) (待辦)
    - [ ] 將直接操作替換為調用管理器的相應函數。

- [ ] **8. 測試：** 在每個主要替換步驟後進行充分測試，確保功能正常。(當前阻塞於召喚事件註冊錯誤)

- [ ] **9. 清理：** 移除不再需要的舊邏輯或註解。(待辦, 包括 obj_summon_ui 中的調試代碼)

- [x] **10. 更新記憶庫：** 更新相關記憶庫文件 (`activeContext.md`, `progress.md`, `systemPatterns.md`, `techContext.md`) 以反映重構狀態。(已完成)