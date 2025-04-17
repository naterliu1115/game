# 重構 Player Monsters 數據管理計劃

此計劃旨在將所有對 `global.player_monsters` 的操作集中到 `scripts/monster_data_manager/monster_data_manager.gml` 中。

## 步驟

- [ ] **1. 檢查並分析 `monster_data_manager.gml`：**
    - [x] 讀取現有腳本內容。
    - [x] 分析現有函數和問題（直接操作全域變數、更新邏輯錯誤）。

- [ ] **2. 修復並完善 `monster_data_manager.gml`：**
    - [ ] 添加 `initialize_player_monsters()` 函數。
    - [ ] 添加 `get_player_monsters()` 函數。
    - [ ] 添加 `get_monster_by_uid(uid)` 函數。
    - [ ] 添加 `get_monster_index_by_uid(uid)` 輔助函數 (用於更新)。
    - [ ] 修正 `add_experience(uid, experience)` 中的更新邏輯。
    - [ ] 修正 `add_experience_batch(uids, experience_array)` 中的更新邏輯。
    - [ ] **(可選)** 添加 `update_monster_data(uid, updated_data)` 作為通用的更新函數。
    - [x] 確保所有函數內部操作 `global.player_monsters`，而不是返回讓外部修改。

- [ ] **3. 逐步替換 `obj_game_controller` 中的引用：**
    - [ ] 將 `Create_0.gml` 中的 `global.player_monsters = []` 替換為調用 `initialize_player_monsters()`。
    - [ ] 將 `Create_0.gml` 中的 `array_push(global.player_monsters, monster_data)` 替換為調用 `add_player_monster()` (或類似函數，可能需要調整 `add_monster_from_template` 或創建新函數)。
    - [ ] 將其他讀取操作替換為調用 `get_player_monsters()` 或 `get_monster_by_uid()`。

- [ ] **4. 逐步替換 `obj_capture_ui` 中的引用：**
    - [ ] 將 `Create_0.gml` 中的 `array_push(global.player_monsters, captured_monster_data)` 替換為調用 `add_player_monster()`。

- [ ] **5. 逐步替換 `obj_player_summon_parent` 中的引用：**
    - [ ] 將 `Create_0.gml` 中升級後直接修改 `global.player_monsters[i]` 的邏輯移除或重構，改為調用 `monster_data_manager` 的更新函數 (如 `add_experience` 或 `update_monster_data`)。

- [ ] **6. 逐步替換其他 UI 物件中的讀取引用：**
    - [ ] `obj_summon_ui/Create_0.gml`
    - [ ] `obj_monster_manager_ui/Create_0.gml`
    - 將讀取 `global.player_monsters` 的循環替換為先調用 `get_player_monsters()` 獲取列表，再進行處理。

- [ ] **7. 逐步替換其他邏輯物件中的引用：**
    - [ ] `obj_unit_manager/Create_0.gml` (讀取和寫入)
    - [ ] `obj_reward_system/Create_0.gml` (讀取)
    - [ ] `obj_battle_manager/Step_0.gml` (讀取)
    - 將直接操作替換為調用管理器的相應函數。

- [ ] **8. 測試：** 在每個主要替換步驟後進行充分測試，確保功能正常。

- [ ] **9. 清理：** 移除不再需要的舊邏輯或註解。

- [ ] **10. 更新記憶庫：** 更新相關記憶庫文件 (`activeContext.md`, `progress.md`, `systemPatterns.md`) 以反映重構完成狀態。 