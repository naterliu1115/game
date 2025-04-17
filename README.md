## 全域資料與多存檔設計原則

本專案所有遊戲資料（如背包、金錢、怪物等）統一以 `global` 變數管理，例如：
- `global.player_inventory`：玩家背包（唯一資料來源）
- `global.player_gold`：玩家金錢
- `global.player_monsters`：玩家怪物列表

### 設計原則
- **全專案只在一個地方（global 變數）實作與紀錄這些資訊，所有函數、物件、UI 都直接取用 global 變數。**
- **reward system 及所有物品相關腳本，統一只操作 `global.player_inventory`，不再使用 `player_items` 或其他變數。**
- 嚴格檢查所有初始化、重設、清空的地方，避免重複建立或覆蓋 global 變數。

### 多存檔支援建議
- 遊戲運行時，所有資料都放在 global 變數，方便各系統直接存取。
- 存檔時，將所有 global 變數（如 `global.player_inventory`、`global.player_gold`、`global.player_monsters` 等）序列化成一個 struct 或 JSON，存到檔案或雲端。
- 讀檔時，先清空現有 global 內容，再把存檔資料還原到 global 變數。
- 切換存檔時，先存下現有 global 狀態（如有需要），再載入新存檔內容到 global。

此設計可兼顧開發便利性與未來多存檔擴充需求。

---

## 核心系統

### 1. 角色動畫系統 (Animation System)

角色動畫系統提供了一個統一且高度可定制的動畫播放機制，確保動畫幀循環順暢且不會跳幀。

**主要組件:**
- `Player`: 玩家角色，使用八方向動畫系統
- `obj_battle_unit_parent`: 戰鬥單位的父類，也使用相同的動畫系統

**控制系統更新:**
- 移動控制：使用 WASD 鍵進行移動
- 方向控制：使用滑鼠位置決定角色面向
- 挖礦系統：
  - 左鍵點擊進行挖礦動作
  - 根據面向方向自動選擇左/右挖礦動畫
  - 挖礦動作在最後一幀有短暫停頓
  - 挖礦時無法移動
  - 支持單次點擊和持續挖礦

**動畫參數:**
- `animation_speed`: 基礎動畫速度（1=正常速度，2=兩倍速，0.5=半速）
- `animation_update_rate`: 更新間隔（步數，越小越快，越大越慢）
- `idle_animation_speed`: IDLE動畫專用速度（允許IDLE使用不同的速度）
- `idle_update_rate`: IDLE動畫更新間隔（允許更精確的IDLE動畫控制）
- `MINING_ANIMATION_SPEED`: 挖礦動畫速度
- `MINING_LAST_FRAME_DELAY`: 挖礦最後一幀停留時間

**主要功能:**
- 八方向動畫實現：基於滑鼠方向自動選擇相應的動畫
- 幀序列管理：使用固定的幀序列系統確保每幀都完整播放
- 動畫狀態檢測：自動檢測動畫變更並重設序列
- 差異化動畫速度：可以為不同動畫類型設置不同速度
- 動畫調試：內建詳細的調試輸出機制
- 挖礦動畫：支持左右方向的挖礦動作，具有完整的動畫循環

**使用示例:**
```gml
// 在Create_0.gml中設置基本動畫參數
animation_speed = 1.0;
animation_update_rate = 5;
idle_animation_speed = 0.5;
idle_update_rate = 8;

// 在Step_0.gml中會自動基於這些參數更新動畫
```

**新增怪物時的動畫配置:**
```gml
// 設置新的動畫配置
animation_frames = {
    WALK_DOWN_RIGHT: [0, 4],   // 0-4是右下角移動
    WALK_UP_RIGHT: [5, 9],     // 5-9是右上角移動
    WALK_UP_LEFT: [10, 14],    // 10-14是左上角移動
    WALK_DOWN_LEFT: [15, 19],  // 15-19是左下角移動
    WALK_DOWN: [20, 24],       // 20-24是正下方移動
    WALK_RIGHT: [25, 29],      // 25-29是右邊移動
    WALK_UP: [30, 34],         // 30-34是上面移動
    WALK_LEFT: [35, 39],       // 35-39是左邊移動
    IDLE: [40, 44],            // 待機動畫
    ATTACK: [45, 49],          // 攻擊動畫
    HURT: [50, 54],            // 受傷動畫
    DIE: [55, 59]              // 死亡動畫
}

// 調整動畫速度（可選）
animation_speed = 0.8;
animation_update_rate = 5;
idle_animation_speed = 0.4;
idle_update_rate = 9;
```

### 2. 事件系統 (Event System)

事件系統採用發布-訂閱模式，允許遊戲對象之間進行鬆耦合的通信。

**主要組件:**
- `obj_event_manager`: 負責事件的註冊、廣播和管理
- `scr_event_system`: 提供事件廣播功能 (如果有的話，或者直接使用 obj_event_manager 的方法)

**主要功能:**
- 事件訂閱: `subscribe_to_event(event_name, instance_id, callback)` (通過 `obj_event_manager`)
- 事件廣播: `trigger_event(event_name, data = {})` (通過 `obj_event_manager`)
- 事件取消訂閱: `unsubscribe_from_event(event_name, instance_id)` (通過 `obj_event_manager`)
- **更新**: `obj_game_controller` 現在使用 Alarm[0] 延遲廣播 `managers_initialized` 事件，以確保所有實例（如 `obj_enemy_placer`）有足夠時間完成創建和訂閱。
- **回調機制註記**: 經驗證，使用已定義的實例方法名（字串）作為 `callback` 參數比使用腳本索引或動態函數更穩定，能避免 GML 中潛在的作用域/上下文問題。

**使用示例:**
```gml
// 訂閱事件 (假設在某對象的 Create 事件中)
if (instance_exists(obj_event_manager)) {
    with (obj_event_manager) {
        subscribe_to_event("player_damaged", other.id, "on_player_damaged"); // other.id 是訂閱者id, "on_player_damaged" 是訂閱者的方法名
    }
}

// 廣播事件 (例如，在子彈擊中玩家時)
if (instance_exists(obj_event_manager)) {
    with (obj_event_manager) {
        trigger_event("player_damaged", { damage: 10 }); 
    }
}
```
**已知問題**:
- **(已解決)** `trigger_event` 功能缺失。

### 3. 戰鬥系統 (Battle System)

戰鬥系統管理整個戰鬥流程，包括單位的行動、回合控制和戰鬥結果處理。

**主要組件:**
- `obj_battle_manager`: 控制整個戰鬥流程
- `obj_battle_unit_parent`: 戰鬥單位的父類

**戰鬥狀態:**
- `INACTIVE`: 非戰鬥狀態
- `STARTING`: 戰鬥開始過渡（邊界擴張）
- `PREPARING`: 戰鬥準備階段（玩家召喚單位）
- `ACTIVE`: 戰鬥進行中
- `ENDING`: 戰鬥結束過渡 (邊界縮小)
- `RESULT`: 顯示戰鬥結果

**主要功能:**
- 戰鬥初始化
- 回合管理
- 勝負判定
- **獎勵與結果流程 (重構):**
  - **事件流程**:
    - 戰鬥結束時 (`ENDING` 狀態末尾)，`obj_battle_manager` 廣播 `finalize_battle_results` 事件。此事件數據包含**最終戰鬥持續時間(秒)**、**擊敗敵人模板ID列表 (`defeated_enemy_ids`)** 以及**本場戰鬥的實際物品掉落列表 (`item_drops`)**。
    - `obj_reward_system` 監聽 `finalize_battle_results` 事件。
    - `obj_reward_system` 的 `on_finalize_battle_results` 方法會處理收到的數據：
        - 它會直接使用傳入的 `defeated_enemy_ids` 列表，結合從 `obj_enemy_factory` 獲取的模板數據中的 `exp_reward` 和 `gold_reward`，來調用 `calculate_victory_rewards` 計算總經驗和金幣。
        - 它會直接使用傳入的 `item_drops` 列表（由 `obj_battle_manager` 預先計算好）。
        - `obj_reward_system` **不再負責解析 `loot_table` 字串**。
    - `obj_reward_system` 計算完成後，更新其內部的 `battle_result` 結構體，然後廣播 `rewards_calculated` 事件，包含完整的 `battle_result`。
    - `obj_battle_manager` 監聽 `rewards_calculated`，更新自身狀態後，最終廣播 `show_battle_result` 事件給 UI。
    - `obj_battle_ui` 監聽 `show_battle_result`，使用收到的完整數據更新結果畫面。
    - **(已更新)** `obj_battle_ui` 現在通過其內部的 `show_rewards` 方法響應此事件，該方法已整合了數據處理和界面更新邏輯。
    - **(已更新)** `obj_battle_ui` 的關閉現在統一由 `obj_ui_manager` 響應 `battle_end` 事件處理，避免了重複隱藏問題。
  - **物品掉落計算 (核心重構):**
    - 物品掉落的計算現在**完全由 `obj_battle_manager`** 在處理 `unit_died` 事件時執行（在其 `on_unit_died` 方法內部）。
    - `on_unit_died` 會從死去的敵人模板 (`template`) 中獲取 `loot_table` **原始字串** (例如 `"1001:1:1-1;1002:0.5:1"`）。
    - `on_unit_died` 會解析這個字串，根據每個條目的機率 (`chance`) 和數量範圍 (`min-max`) 進行判定。
    - 如果掉落成功，會創建一個包含 `{ item_id: ..., quantity: ... }` 的結構體，並添加到 `obj_battle_manager` 的 `current_battle_drops` 陣列變數中。這個變數在戰鬥開始時會被清空。
    - 這個 `current_battle_drops` 陣列最終會作為 `item_drops` 包含在 `finalize_battle_results` 事件中發送出去。
- **經驗與升級系統 (重構):**
  - **經驗獲取**: 敵人經驗值 (`exp_reward`) 由 `enemies.csv` 定義。
  - **經驗記錄**: `obj_battle_manager` 在單位死亡時 (`on_unit_died` 事件處理中) 記錄被擊敗敵人的經驗值。
  - **經驗分配**: 戰鬥勝利後 (`ACTIVE` 狀態檢測到勝利時)，`obj_battle_manager` 調用 `distribute_battle_exp()` 將累計的經驗值分配給所有存活的我方單位 (調用其 `gain_exp` 方法)。
  - **升級曲線**: 升級所需經驗由 `levels.csv` 定義，由 `obj_level_manager` 載入和管理 (`global.level_exp_map`)。
  - **升級處理與資料同步**: `obj_player_summon_parent` 的 `gain_exp` 方法會檢查是否達到升級所需經驗，如果達到則調用 `level_up`。`level_up` 執行時，會即時將 instance 的 `level`、`exp`、`hp`、`max_hp`、`attack`、`defense`、`spd` 等欄位同步回 `global.player_monsters`，以 id 或 type+name 作為唯一 key。若 struct 缺少 `exp` 欄位則補上，確保 UI 讀取時資料即時正確。
  - **屬性成長與技能學習**: `level_up` 方法負責提升單位等級、根據模板數據 (`hp_growth` 等) 重新計算屬性、檢查並學習達到新等級要求的新技能 (從模板數據獲取技能 ID)。
  - **視覺效果**: 升級時觸發浮動文字提示和粒子效果。
- 新增：實現了浮動傷害文字系統 (`obj_floating_text`)，用於即時顯示傷害數值。
- 新增：實現了通用的受傷視覺特效 (`obj_hurt_effect`)，獨立於單位動畫。
- **更新**: 技能傷害計算已從單位初始化階段（可能讀取不完整數據）轉移到實際應用傷害時 (`obj_battle_unit_parent` 的 `apply_skill_damage` 函數中)。現在會根據攻擊者**當前**的攻擊力和技能的傷害倍率 (`damage_multiplier`) 動態計算。
- **傷害驗證**: 已建立自動化測試 (`rm_damage_test`, `obj_damage_test_controller`, `obj_test_attacker`, `obj_test_target`) 並驗證 `apply_skill_damage` 中動態計算的傷害值符合預期。
- **運行時錯誤修復**:
    - 解決了因內建函數 `string_is_numeric` 行為異常導致的 CSV 加載崩潰問題（影響 `obj_skill_manager`, `obj_level_manager` 等）。通過創建並使用自定義輔助函數 `is_numeric_safe` 替代了有問題的內建函數。
    - 修復了 `obj_battle_manager` 中 `add_battle_log` 函數因錯誤地對 `ds_list` 使用 `array_*` 函數而導致的崩潰問題，已改用正確的 `ds_list_*` 函數。
    - 修復了 `obj_reward_system` 錯誤判斷戰鬥結果的問題（通過修正事件處理邏輯和數據流）。
    - 修復了 `obj_event_manager` 回調機制與函數變數不兼容導致的多個事件訂閱失敗問題（通過將回調改為方法）。
    - 修復了因 `loot_table` 數據格式在 `obj_enemy_factory` 和 `obj_battle_manager` 之間不一致導致的掉落失敗問題（統一由 `obj_battle_manager` 解析原始字串）。
    - 修復了因 `unit_died` 事件數據鍵名不一致導致的 `obj_unit_manager` 錯誤。
    - 移除了 `obj_battle_unit_parent` 中重複的經驗記錄邏輯。
    - 移除了 `obj_test_enemy` 中冗餘的 `loot_table` 處理邏輯。
- **獎勵系統重構 (金幣與掉落物)**:
    - `obj_battle_manager` 現在會記錄並在 `finalize_battle_results` 事件中傳遞被擊敗敵人的模板 ID 列表 (`defeated_enemy_ids`)。
    - `obj_reward_system` 的 `calculate_victory_rewards` 函數已重構，現在會根據傳入的 `defeated_enemy_ids` 列表和 `enemies.csv` 中對應的 `gold_reward`（金幣）欄位計算總金幣獎勵。
    - `calculate_victory_rewards` 現在也會解析 `enemies.csv` 中的 `loot_table` 欄位（格式：`item_id:chance:min-max;...`），根據機率和數量範圍計算實際掉落的物品，並將結果存儲在 `battle_result.item_drops` 中。
    - 修復了 `is_numeric_safe` 函數未能正確處理從模板中讀取的數字（而非字符串）的問題。

### 4. 單位系統 (Unit System)

單位系統管理所有戰鬥單位的創建、銷毀和行為。

**主要組件:**
- `obj_unit_manager`: 管理單位的創建和銷毀
- `obj_player_summon_parent`: 玩家召喚單位的父類
- `obj_enemy_parent`: 敵方單位的父類

**主要功能:**
- 單位創建與銷毀
- 單位行動控制 (ATB, AI 模式, 狀態機)
- 單位狀態管理
- 單位數據統計
- 更新：重構了 `obj_battle_unit_parent` 的動畫邏輯，採用手動控制 `image_index`，確保攻擊動畫完整播放，並修復了相關狀態機交互問題。
- 更新：移除了受傷狀態 (`HURT`) 對攻擊動畫的干擾。
- 新增與調整：為單位 (`obj_battle_unit_parent`) 增加了非戰鬥狀態下的「遊蕩」(`WANDER`) 行為：
    - 單位在非戰鬥狀態 (`INACTIVE`) 時，會在初始生成點附近隨機移動和暫停。
    - 遊蕩速度目前設定為 `move_speed` 的一半，可在 `Step_0.gml` 中調整。
    - 單位會在戰鬥管理器狀態不再是 `INACTIVE` 時（即 `STARTING` 階段開始）立即停止遊蕩。
    - 同步調整了單位 UI：生命條 (`Draw_0.gml`) 現在只在戰鬥管理器狀態不再是 `INACTIVE` 時顯示。
    - 調整了 ATB 充能機制 (`Step_0.gml`)：所有單位的 ATB 現在只在戰鬥管理器狀態進入 `ACTIVE` 後才開始充能，確保敵我雙方起始條件更公平。
- **升級資料同步**: 玩家召喚單位升級時，會即時將所有關鍵欄位（level、exp、hp、max_hp、attack、defense、spd）同步回 `global.player_monsters`，以確保資料一致性與 UI 即時更新。

**單位優化:**
- 使用對象池系統優化單位創建和回收 (若已實現)
- 追蹤單位統計信息以便進行遊戲平衡

#### 4.1 敵人系統工廠化 (Enemy System Factory)

為了集中管理敵人數據、簡化敵人創建流程並方便平衡調整，敵人系統採用了工廠模式進行重構。此設計將敵人數據與其實例化邏輯分離。

**主要組件與數據流:**

1.  **數據源 (`datafiles/enemies.csv`)**: 
    *   核心數據存儲在 CSV 文件中，定義了每個敵人的所有屬性，包括：
        *   基礎信息 (id, name, category, family, variant, rank)
        *   基礎屬性與成長率 (level, hp_base, attack_base, ..., hp_growth, ...)
        *   視覺資源 (sprite_idle, sprite_move, sprite_attack)
        *   群組行為 (is_pack_leader, pack_min/max, pack_pattern, companions)
        *   戰利品與獎勵 (**`loot_table`**, `exp_reward`, `gold_reward`)
        *   戰鬥 AI (ai_type, attack_range, aggro_range, attack_interval)
        *   捕獲相關 (capturable, capture_rate_base)
        *   技能 (skills, skill_unlock_levels)
    *   **複雜欄位格式**: 部分欄位如 `companions` (`id:weight;...`), `loot_table` (`item_id:chance:min-max;...`), `skills` (`id;...`), `skill_unlock_levels` (`lvl;...`) 使用特定格式存儲列表或結構化數據。

2.  **CSV 解析器 (`scripts/scr_csv_parser`)**: 
    *   提供通用的 CSV 文件處理函數：
        *   `load_csv(filename)`: 讀取 CSV 文件並返回一個 `ds_grid`。
        *   `string_split(str, delimiter)`: 更健壯的字符串分割，能處理帶引號的字段。
        *   `string_trim(str)`: 移除前後空白和引號。
        *   `csv_grid_get(grid, col_name, row)`: 根據列名安全地從網格獲取值。
        *   `bool(value)`: 將字符串或數字轉換為布爾值。

3.  **敵人數據/枚舉腳本 (`scripts/scr_enemy_data`, `scripts/scr_enemy_enums`)**:
    *   `scr_enemy_data`: 包含 `create_enemy_base_data()` 函數，定義了一個與 CSV 列對應的完整敵人數據結構，可用於參考或創建模板。
    *   `scr_enemy_enums`: 定義了敵人相關的枚舉 (`ENEMY_CATEGORY`, `ENEMY_RANK`, `ENEMY_AI`, `SPAWN_PATTERN`)，提高程式碼可讀性和維護性。

4.  **敵人工廠 (`obj_enemy_factory`)**: 
    *   **核心職責**: 作為敵人數據的中央樞紐和實例創建者。
    *   **初始化 (`initialize`)**: 在遊戲啟動時（由 `obj_game_controller` 保證創建），調用 `load_enemies_from_csv()`。**更新**: 移除了加載 CSV 失敗時回退到 `register_test_enemies` 的邏輯，現在會直接調用 `show_error()` 中止遊戲。
    *   **數據載入 (`load_enemies_from_csv`)**: 使用 `scr_csv_parser` 讀取 `enemies.csv`，解析每一行數據，進行類型轉換（數字、布爾），解析複雜欄位（如 `companions`, `loot_table`, `skills`），查找精靈資源 ID，最終將每行數據轉換為一個結構化的**敵人模板 (struct)**，並以敵人 ID 為鍵存儲在 `enemy_templates` (ds_map) 中。
    *   **模板獲取 (`get_enemy_template(enemy_id)`)**: 提供給外部系統（如 `obj_test_enemy`, `obj_game_controller`, `obj_capture_ui`）根據 ID 獲取唯讀的敵人模板數據。
    *   **實例創建 (`create_enemy_instance(id, x, y, [level])`)**: 
        *   接收敵人 ID、位置和可選的等級覆蓋參數。
        *   獲取對應的模板。
        *   創建一個 **`obj_test_enemy`** 實例（目前固定使用此物件類型）。
        *   **更新**: 在 `with (instance)` 上下文中，**僅設置** 該實例的 `template_id` 和最終的 `level` (如果提供了有效的 `_level_param`)。
        *   **呼叫實例自身的 `initialize()` 方法**，將後續的屬性計算和設置（包括基於等級的技能確定）**完全委託**給實例自己完成。
    *   **群組生成 (`generate_enemy_group(leader_id, x, y, [level])`)**: 根據首領模板信息，使用 `create_enemy_instance` 創建首領和可能的同伴，並使用 `calculate_spawn_position` 計算陣型位置。
    *   **技能數據複製 (`copy_skill`)**: **更新**: 此函數現在只複製技能模板數據（包括 `damage_multiplier`），不再在初始化時根據傳入的單位計算 `damage` 值，以避免使用不完整的單位屬性。

5.  **敵人基類 (`obj_enemy_parent`)**: 
    *   定義敵人通用的屬性（如 `is_capturable`）和從工廠獲取數據所需的變數 (`template_id`, `level`, `name` 等，帶有初始預設值）。
    *   其 `initialize` 方法主要負責基礎設定（如 `team=1`）和呼叫更上層父類 (`obj_battle_unit_parent`) 的初始化。**它不再直接與工廠交互或設置大量屬性。**

6.  **敵人實作 (`obj_test_enemy`)**: 
    *   繼承自 `obj_enemy_parent`。
    *   **核心初始化發生在此**: 其 `initialize` 方法被 `obj_enemy_factory` 在創建實例後調用。
    *   **主要邏輯**: 
        *   （可選地）呼叫 `event_inherited()` 執行父類初始化。
        *   使用自身的 `template_id` 向 `obj_enemy_factory.get_enemy_template()` 獲取模板數據。
        *   **更新**: **根據獲取的模板數據和自身的 `level`，計算並設置所有詳細屬性** (HP, 攻防速，基於基礎值和成長率；AI 模式；掉落物；視覺效果等)。
        *   **更新**: 在此階段，會調用 `add_skill` 將達到當前等級的技能（從模板獲取 ID，通過 `copy_skill` 獲取數據）添加到自身的技能列表中。
        *   處理模板獲取失敗的情況。
        *   **更新**: **不再**處理模板中的 `loot_table` 數據或維護 `drop_items` 變數，相關邏輯已移除。

7.  **編輯器放置器 (`obj_enemy_placer`)**: 
    *   用於在房間編輯器中方便地放置敵人。
    *   創建時從工廠或 CSV 加載可用模板列表供編輯器選擇。
    *   **更新**: 遊戲運行開始時，通過訂閱 `managers_initialized` 事件（現在由 `obj_game_controller` 的 Alarm 延遲觸發）來調用 `obj_enemy_factory.create_enemy_instance()` 生成對應的 `obj_test_enemy` 實例（並傳遞在編輯器中設置的 `enemyLevel`），然後自我銷毀。修復了之前的時序問題。

8.  **遊戲控制器 (`obj_game_controller`)**: 
    *   確保 `obj_enemy_factory` 在遊戲開始時被創建。
    *   **更新**: 負責**初始化玩家的初始怪物列表 (`global.player_monsters`)**: 
        *   從工廠獲取指定初始怪物的模板。
        *   根據模板和指定等級計算標準屬性。
        *   創建一個**標準化的數據結構** (包含 `id`, `level`, `name`, `type`, **`display_sprite` (來自模板的基礎 Sprite ID)**, 屬性等)。
        *   **新增**: 會根據模板技能和解鎖等級，將達到初始等級的**技能 ID** 填充到 `monster_data.skills` 陣列中。
        *   添加到 `global.player_monsters`。
    *   **更新**: 使用自定義的 `array_join` 腳本函數替換了之前錯誤的內建函數調用。

9.  **捕獲 UI (`obj_capture_ui`)**: 
    *   在 `finalize_capture` 時，使用被捕獲敵人的 `template_id` 從工廠獲取其原始模板。
    *   根據模板數據和捕獲時的等級，計算標準屬性，創建與 `obj_game_controller` 生成的初始怪物**結構相同**的數據 (同樣包含 `display_sprite`)，並添加到 `global.player_monsters`。

**主要優點回顧:**
- **數據驅動**: 敵人行為和屬性主要由 `enemies.csv` 文件控制。
- **易於擴展與修改**: 新增或調整敵人主要通過修改 CSV 和相關資源完成。
- **代碼解耦**: 數據載入、模板管理、實例創建和實例初始化邏輯分離。
- **維護性提高**: 集中管理數據和枚舉，減少硬編碼和魔法數字。
- **初始化標準化**: 確保所有敵人（包括玩家的初始/捕獲怪物）的屬性計算遵循統一規則。

### 5. 對話系統 (Dialogue System)

對話系統管理遊戲中的對話流程，支持 NPC 交互。

**主要組件:**
- `obj_dialogue_manager`: 管理對話狀態和流程
- `obj_dialogue_box`: 顯示對話文本
- `dialogue_functions`: 提供對話相關功能 (腳本或 obj_dialogue_manager 的方法)

**主要功能:**
- 開始對話: `start_dialogue(npc_instance_or_dialogue_id)`
- 結束對話: `end_dialogue()`
- 進行對話: `advance_dialogue()`

**使用示例:**
```gml
// 開始與 NPC 對話 (假設玩家與 NPC 碰撞)
if (instance_exists(obj_dialogue_manager)) {
    with (obj_dialogue_manager) {
        start_dialogue(other.id); // other.id 是 NPC 的實例 ID
    }
}

// 進行對話 (假設在玩家的 Step 事件中)
if (instance_exists(obj_dialogue_manager) && obj_dialogue_manager.is_active) { // 檢查對話是否正在進行
    if (keyboard_check_pressed(vk_space)) { // 或其他確認鍵
        with (obj_dialogue_manager) {
            advance_dialogue();
        }
    }
}
```

### 6. 道具系統 (Item System)

**背包初始化與 UI 流程重構說明：**  
- 玩家背包（`global.player_inventory`）的初始化與預設道具，現已統一由 `obj_game_controller` 在遊戲啟動時負責，只執行一次。  
- 物品欄 UI（`obj_inventory_ui`）僅負責顯示背包內容，不再自動新增任何道具。  
- 這樣設計可確保背包內容不會因 UI 開啟或戰鬥流程被清空，資料初始化與 UI 顯示完全分離，架構更穩定。

道具系統管理遊戲中的所有物品，包括消耗品、裝備、捕捉道具、材料和工具。

**主要組件:**
- `obj_item_manager`: 管理物品數據和操作
- `items_data.csv`: 物品數據配置文件
- `global.player_inventory`: 全局玩家背包列表 (ds_list)

**物品類型:**
```gml
enum ITEM_TYPE {
    CONSUMABLE,  // 消耗品
    EQUIPMENT,   // 裝備
    CAPTURE,     // 捕捉道具
    MATERIAL,    // 材料
    TOOL         // 工具 (新增)
}
```

**物品稀有度:**
```gml
enum ITEM_RARITY {
    COMMON = 0,    // 普通
    UNCOMMON,      // 非普通
    RARE,         // 稀有
    EPIC,         // 史詩
    LEGENDARY     // 傳說
}
```

**主要功能:**
- 物品數據載入: `load_items_data()`
- 物品驗證: `validate_item_data(item_data)`
- 獲取物品: `get_item(item_id)`
- 物品圖示獲取: `get_item_sprite(item_id)`
- 物品類型獲取: `get_item_type(item_id)`
- **快捷欄管理 (於 `obj_item_manager` 中定義)**:
  - `assign_item_to_hotbar(inventory_index)`: 將指定背包索引的物品分配到第一個空的快捷欄位。
  - `unassign_item_from_hotbar(inventory_index)`: 取消指定背包索引物品的快捷欄指派。
  - `get_hotbar_slot_for_item(inventory_index)`: 查詢物品被指派到哪個快捷欄位 (-1 表示未指派)。
  - `get_item_in_hotbar_slot(hotbar_slot)`: 獲取指定快捷欄位的物品背包索引 (`noone` 表示空)。
- 物品使用: `use_item(item_id)` (注意：尚未與快捷欄選擇掛鉤，僅限背包內使用)
- 物品效果執行: `execute_item_effect(item_data)` (目前僅實現治療效果)

**物品數據結構 (存儲在 `items_data` ds_map 中):**
```gml
{
    ID: number,           // 物品ID (1000-9999)
    Name: string,         // 物品名稱
    Type: string,         // 物品類型 (來自CSV，主要供參考)
    Description: string,  // 物品描述
    Rarity: string,      // 稀有度 (來自CSV)
    IconSprite: number,   // 圖示精靈 ID (重要：載入時查找並直接存儲ID)
    UseEffect: string,    // 使用效果標識
    EffectValue: number,  // 效果值
    StackMax: number,     // 最大堆疊數量
    SellPrice: number,    // 售價
    Tags: array,          // 標籤列表 (來自CSV)
    Category: number      // 物品分類 (0-4，對應 ITEM_TYPE 枚舉)
}
```

**事件整合:**
- 物品添加事件: `item_added` (觸發時機: `add_item_to_inventory`)
- 物品使用事件: `item_used` (觸發時機: `use_item` 成功後)

**錯誤處理與改進:**
- **精靈處理重構**:
    - 移除了 `preload_item_sprites` 和 `item_sprites`。
    - `load_items_data` 現在負責讀取 CSV、清理精靈名稱字符串 (`string_trim`)、查找精靈資源 (`asset_get_index`, `sprite_exists`)，並將獲取到的**精靈 ID** 直接存儲在物品數據結構中。
    - 如果 CSV 中指定的精靈找不到，則使用全局變數 `global.DEFAULT_SPRITE_ID` (預設為 `spr_gold` 的 ID) 作為後備。
    - **圖示處理優化**: 移除了佔位符繪製代碼，所有無效的道具圖示都統一使用 `spr_gold` 作為預設圖示。
    - **移除 `scr_sprite_diagnostics` 腳本**: 由於精靈處理邏輯簡化，不再需要複雜的診斷和修復機制，已移除此腳本。
- 物品載入失敗處理。
- 無效物品ID處理。
- 物品驗證失敗處理 (基於更新後的數據結構)。
- CSV 讀取時增加了對空行或不完整行的跳過處理。

### 7. UI 管理系統

UI 系統管理遊戲中的各種用戶界面元素。

**主要組件:**
- `obj_ui_manager`: 全局 UI 管理器
- `parent_ui`: UI 元素的父類
- `obj_main_hud`: **(新增)** 主界面 HUD，常駐顯示
- `obj_battle_ui`: 戰鬥界面
    - **(已更新)** 響應 `show_battle_result` 事件，通過自身的 `show_rewards` 方法處理數據並更新顯示。修復了之前的回調執行錯誤。
- `obj_inventory_ui`: 物品欄界面
- `obj_item_info_popup`: 物品資訊彈出視窗
- `obj_monster_manager_ui`: 怪物管理界面
- `obj_summon_ui`: 召喚界面
- `obj_capture_ui`: 捕獲界面

**主要功能:**
- UI 元素顯示與隱藏
- UI 交互處理
- UI 狀態同步
- **主界面 HUD (`obj_main_hud`)**:
    - **常駐顯示**: 作為遊戲主要界面的一部分持續顯示。
    - **快捷欄 (Hotbar)**:
        - 在畫面底部顯示固定數量的快捷欄格子 (`hotbar_slots`)。
        - **獨立數據**: 使用獨立的全局數組 `global.player_hotbar` 儲存快捷欄物品的背包索引 (不再直接映射背包前幾項)。
        - **視覺顯示**: 根據 `global.player_hotbar` 繪製對應物品的圖示和數量，空位則顯示空格子。
        - **圖示縮放與定位**: 正確處理不同尺寸的道具圖示精靈，將其縮放至目標尺寸 (如 80x80) 並在格子 (如 96x96) 內居中顯示。外框 (`spr_itemframe`) 也會被縮放以匹配格子尺寸。
        - **選擇指示**: 使用高亮框 (黃色半透明矩形) 標示當前選中的快捷欄格子 (`selected_hotbar_slot`)。
        - **選擇切換**: 支持數字鍵 1-0 和滑鼠滾輪切換 `selected_hotbar_slot`。初始無選中 (`-1`)，按數字鍵選中，再按同一個數字鍵取消選中。滾輪在首尾滾動可取消選中。
        - **拖放重排**: 支持按住滑鼠左鍵拖曳快捷欄中的物品，釋放到其他欄位進行交換或移動。
    - **背包圖示**: 在右下角顯示背包圖示 (`spr_bag`)，點擊可觸發 `obj_game_controller.toggle_inventory_ui()` 打開/關閉物品欄。圖示位置會根據螢幕尺寸和邊距自動調整。
    - **互動提示**: 在背包圖示旁顯示互動提示圖示 (`spr_touch`)，其可見性由 `Player` 物件根據是否靠近可互動目標來控制 (`show_interaction_prompt` 變數)。圖示位置會相對背包圖示自動調整。
- **物品欄管理 (`obj_inventory_ui`)**:
    - **分類篩選**: 負責管理頂部的分類標籤頁 (Tabs)，並根據當前選中的分類（如消耗品、裝備、工具等）從 `global.player_inventory` 中嚴格篩選物品。
    - **物品展示**: 在網格佈局中繪製篩選後物品的圖示 (使用 `get_item_sprite` 返回的 ID) 和堆疊數量。
    - **滾動支持**: 實現物品列表的垂直滾動功能。
    - **交互處理**: 精確檢測滑鼠在物品圖標上的懸停和點擊事件（點擊範圍已校準）。
    - **信息彈窗觸發**: 滑鼠懸停時，創建或更新 `obj_item_info_popup` 實例以顯示物品詳情，並傳遞物品 ID。
    - **物品使用交互**: 可能處理雙擊或右鍵點擊事件，以啟動物品使用 (`use_item`) 或其他操作。
    - **快捷欄指派入口**: 在點擊物品彈出的 `obj_item_info_popup` 中提供"指派快捷"按鈕。
- **物品資訊彈窗 (`obj_item_info_popup`):**
    - **詳細信息展示**: 從 `obj_item_manager` 獲取指定物品 ID 的完整數據，並在彈窗中清晰地展示名稱、描述、類型、稀有度、效果、數值、標籤、售價等信息。
    - **智能定位與邊界檢測**: 根據觸發源（如滑鼠位置）智能定位，並確保彈窗始終完整顯示在屏幕範圍內。
    - **單例管理與清理**: 確保同一時間最多只有一個資訊彈窗可見，舊的彈窗會被自動清理。
    - **自動銷毀**: 當滑鼠移開對應物品或物品欄關閉時，彈窗會自動銷毀。
    - **快捷欄指派/取消**:
      - 提供一個按鈕，根據物品是否已指派顯示不同文字 ("指派快捷" / "取消指派") 和顏色 (綠/紅)。
      - 點擊按鈕後，會調用 `obj_item_manager` 中的 `assign_item_to_hotbar()` 或 `unassign_item_from_hotbar()` 函數。
      - 會檢查物品類型是否允許指派 (例如裝備不可指派)。
- 拖放操作處理 (若有)
- UI 動畫效果
- 彈出提示管理

**事件處理:**
- 物品添加/移除時更新顯示 (UI 訂閱 `item_added` 等事件)
- 物品使用時的動畫效果
- 物品數量變化的即時更新
- 錯誤提示的顯示

**優化處理:**
- UI 元素對象池 (若有)
- 動態加載和卸載 (若有)
- 視圖裁剪優化 (適用於滾動列表)
- 事件節流和防抖 (適用於頻繁觸發的 UI 事件)

**處理怪物 Sprite**: 由於怪物的 Sprite 是根據配置表動態加載到實例的 `sprite_index`，而非在 IDE 中靜態設置給物件資源，因此：
    -   顯示**場景中活動怪物實例**的預覽圖時 (如捕獲 UI)，應直接讀取該實例的 `sprite_index`。
    -   顯示**基於儲存數據**（如 `global.player_monsters`）的怪物預覽圖時 (如召喚 UI、怪物管理 UI)，應讀取數據結構中儲存的 `display_sprite` 欄位（該欄位儲存了從模板獲取的基礎 Sprite ID）。
    -   **不應**使用 `object_get_sprite(物件索引)` 來獲取動態怪物的 Sprite。

### 8. 浮動文字系統 (Floating Text System)

該系統用於在遊戲畫面上顯示短暫的浮動文字，例如傷害數字、狀態效果提示等。

**主要組件:**
- `obj_floating_text`: 負責單個浮動文字的顯示、動畫（上浮、淡出）和自我銷毀。

**主要功能:**
- 在指定位置創建浮動文字實例。
- 可自訂顯示文字、顏色、浮動速度、淡出速度。

### 9. 採集系統 (Gathering System)

採集系統允許玩家與世界中的資源互動，例如挖掘礦石、採集植物等，獲取遊戲中的材料和資源。

**主要組件:**
- `obj_stone`: 可挖掘的礦石物件，玩家可以使用礦鎬挖掘獲取礦石資源
- `obj_flying_item`: 顯示獲得物品的飛行動畫效果

**礦石物件 (`obj_stone`) 特性:**
- **耐久度系統**: 每個礦石有 `durability` 屬性，每次挖掘進度完成會減少1點，歸零時礦石被破壞並產生獎勵
- **交互機制**:
  - 玩家需要在交互範圍內 (`interaction_radius`)
  - 玩家需要裝備礦鎬 (檢查物品ID 5001)
  - 玩家需要按住左鍵
  - 玩家需要滑鼠懸停在礦石上或面向礦石
- **視覺反饋**:
  - 挖掘時礦石會輕微震動
  - 顯示挖掘進度條
  - 使用粒子系統顯示挖掘效果
  - 礦石被破壞時有粒子爆發效果
- **獎勵系統**:
  - 礦石被破壞時，將指定的物品 (`ore_item_id`) 添加到玩家背包
  - **(更新)** 通過 `Alarm 0` 觸發，在世界層 ("Instances") 創建 `obj_flying_item` 顯示獲得物品的視覺效果。

**飛行物品 (`obj_flying_item`) 特性 (更新):**
- **狀態機設計**: 具有多個狀態，包括：
    - `FLYING_UP`: 向上飛行 (用於採集等)
    - `PAUSING`: 短暫停頓
    - `FLYING_TO_PLAYER`: 飛向玩家
    - `FADING_OUT`: 淡出消失
    - `SCATTERING`: **(已重構)** 拋灑/彈跳 (用於怪物掉落等)
        - **360度拋射**: 現在同時使用初始的 `hspeed` 和 `vspeed` (在 `obj_battle_manager` 的 `Alarm 1` 中基於隨機角度和速度計算) 來實現 X 和 Y 軸方向的移動，確保掉落物能向四周分散，而不僅僅是水平移動。
        - **拋射範圍控制**: 初始拋射速度的大小範圍由 `scatter_speed_min` 和 `scatter_speed_max` 變數控制，這兩個變數定義在 `obj_flying_item` 的 `Create_0.gml` 事件中。調整這些值可以改變掉落物的擴散距離 (近期已調整)。
        - **Z 軸物理模擬**: 使用 `z` (高度) 和 `zspeed` (垂直速度) 變數，以及 `gravity_z` 來模擬拋物線運動。
        - **落地檢測**: 當 `z <= 0` 且 `zspeed < 0` 時觸發落地。
        - **反彈**: 根據 `bounce_count_max` (在 Create 事件設定，目前為 2) 和落地時的 `zspeed` 決定是否反彈。反彈時 `hspeed` 和 `vspeed` 也會衰減。
        - **空氣阻力**: 在空中飛行時，`hspeed` 和 `vspeed` 會逐漸減小 (乘以 0.99)。
        - **已取代**舊的基於 `vspeed` 和 Tilemap 碰撞的邏輯。
    - `WAIT_ON_GROUND`: 落地後等待，執行上下浮動效果。**(已修正)** 確保此狀態下 `hspeed` 和 `vspeed` 都歸零，防止意外漂移。
- **飛行參數**:
  - 初始 XY 速度 (`hspeed`, `vspeed`) 在 `SCATTERING` 狀態下由創建者 (如 `obj_battle_manager`) 設定 (`scatter_speed_min/max`)。**(已調整)** 減小了速度範圍 (1-3) 以使掉落物更集中。
  - 初始 Z 速度 (`zspeed`) 在 `SCATTERING` 狀態下由創建者設定 (`random_range(3, 5)` in `obj_battle_manager`)，用於產生拋物線效果。
  - 其他狀態速度 (`move_speed`, `to_player_speed`) 和持續時間 (`pause_duration`, `fade_duration`, `wait_duration`) 在 Create 事件定義。
- **視覺效果**:
  - **外框效果**: 使用 `bm_add` 混合模式和 `outline_color` (Create事件定義) 創建發光外框。**(已恢復)**
  - **數量顯示**: 如果 `quantity > 1`，在物品右下角顯示數量。
      - **(已修正)** 文字 Y 座標現在使用 `draw_y` (考慮了 Z 軸高度和浮動)。
      - **(已修正)** 文字大小使用 `draw_text_transformed` 和 `quantity_scale` 變數進行獨立縮放 (可在 Draw 事件調整)。
  - 在飛行過程中會縮小，淡出過程中會進一步縮小並降低透明度。
- **粒子系統**: 在拋灑、落地、吸收時觸發粒子效果。
- **座標系統**: 完全在世界座標系 ("Instances" 層) 中創建、運行和繪製。不再依賴 GUI 座標轉換。

**粒子系統:**
- 使用 GameMaker 的粒子系統創建挖掘效果
- 在 `Create_0` 事件中初始化粒子系統和粒子類型
- 在 `CleanUp_0` 事件中清理粒子系統資源

- **已知問題**:
    - （新增或修改）飛行道具 (`obj_flying_item`) 在 `FLYING_TO_PLAYER` 狀態下直接使用 `Player.x`, `Player.y` 作為目標，可能在鏡頭快速移動時產生視覺追趕延遲（待觀察）。

## 設計模式與特點

### 分層架構
- 遊戲邏輯、渲染和資源管理分離
- 使用控制器模式，各種 manager 對象控制不同系統

### 事件驅動設計
- 使用發布-訂閱模式實現鬆耦合的組件通信
- 允許組件之間相互通信而不需要直接引用

### 狀態機設計
- 戰鬥系統使用明確的狀態機進行流程控制
- 通過枚舉定義各種狀態，清晰管理遊戲流程

### 父子類繼承關係
- 使用父對象實現共用行為
- 通過繼承減少代碼重複

## 使用指南

### 添加新單位
1. 創建一個繼承自 `obj_player_summon_parent` 或 `obj_enemy_parent` 的新對象
2. 在 Create 事件中設置單位屬性 (生命值、攻擊力、速度、精靈等)
3. 在 `obj_unit_manager` 中註冊新單位類型 (如果需要通過管理器生成)
4. 設置單位的動畫幀範圍 (`animation_frames`) 和速度參數

### 自定義角色動畫
1. 修改角色的 `animation_frames` 結構體來定義各種動畫的幀範圍
2. 調整 `animation_speed` 和 `animation_update_rate` 變數控制動畫速度
3. 可以為特定動畫類型(如IDLE)設置專用速度參數
4. 在 `Create_0.gml` 中集中定義動畫參數，便於統一管理

### 添加新事件
1. 在需要監聽事件的對象中添加對應的回調方法 (Script Function 或 Object Method)
2. 在 `Create` 或適當時機，使用 `obj_event_manager` 的 `subscribe_to_event` 訂閱事件
3. 在需要觸發事件的地方，使用 `obj_event_manager` 的 `broadcast_event` (或確認存在的廣播方法如 `trigger_event`) 廣播事件

### 擴展戰鬥系統
1. 在 `obj_battle_manager` 中添加新的戰鬥邏輯或修改狀態機行為
2. 創建新的戰鬥狀態或修改現有狀態的邏輯
3. 通過事件系統與其他系統協調 (例如，單位死亡時觸發戰利品掉落)

## 開發注意事項

- 使用事件系統進行對象間通信，避免直接引用，以保持低耦合
- 遵循命名規範:
    - `obj_` 前綴用於對象
    - `spr_` 前綴用於精靈
    - `scr_` 前綴用於獨立腳本 (如果有的話)
    - `rm_` 前綴用於房間
    - 使用駝峰命名法 (camelCase) 命名變量和函數
    - 使用宏 (Macros) 或枚舉 (Enums) 定義常量
- 使用適當的注釋說明代碼目的和功能
- 優先使用父類定義共用行為，避免代碼重複
- 保持每個對象的職責單一，遵循單一職責原則
- 定期備份專案

## 程式碼風格

- 使用駝峰命名法 (camelCase) 命名變量和函數
- 使用下劃線命名法 (snake_case) 或帕斯卡命名法 (PascalCase) 命名對象、資源、宏和枚舉（保持一致性）
- 對複雜邏輯添加詳細注釋
- 重要函數添加 JSDoc 風格的函數文檔 (使用 `/// @description`, `/// @param`, `/// @returns`)
- 相關功能分組並用註釋分隔 (例如 `#region` / `#endregion`)

## 調試技巧

- 使用 `show_debug_message()` 輸出調試信息到控制台
- 啟用事件系統的 `event_debug_mode` (如果有的話) 跟踪事件流
- 使用 `obj_battle_manager` 中的調試繪制功能可視化戰鬥區域和單位狀態 (如果有的話)
- 利用動畫系統的調試輸出監控角色動畫狀態變化 (如果有的話)
- 使用 GameMaker 的內建調試器 (Debugger) 設置斷點、檢查變量值和單步執行

## 專案進度與未來展望

- **已完成**:
    - 基礎八方向動畫系統
    - 事件驅動框架 (`obj_event_manager`)
    - 基礎戰鬥流程狀態機 (`obj_battle_manager`)
    - 單位父類和基礎行為 (`obj_battle_unit_parent`)
    - 浮動文字和受傷特效
    - 非戰鬥狀態下的單位遊蕩行為
    - **道具系統**:
      - CSV 載入, 多類型支持, 精靈 ID 處理, 基礎背包操作
      - **重構快捷欄管理邏輯至 `obj_item_manager`**
      - **圖示處理優化**: 簡化精靈加載邏輯，統一使用 `spr_gold` 作為預設圖示，移除了佔位符繪製代碼和複雜的診斷機制
    - **UI 系統**:
      - 物品欄界面 (`obj_inventory_ui`) 支持分類、滾動、交互
      - 物品信息彈窗 (`obj_item_info_popup`) 支持智能定位、單例管理
      - **主 HUD (`obj_main_hud`)**:
        - 實現了帶有快捷欄、背包圖示和互動提示的基礎 HUD。
        - **實現了快捷欄位的選擇與取消選擇邏輯 (數字鍵、滾輪)**。
        - 完成了快捷欄、背包、互動提示的位置調整和圖示/外框的縮放與對齊。
      - **獨立快捷欄系統**:
        - 實現了與主背包分離的快捷欄數據 (`global.player_hotbar`)。
        - **實現了通過物品彈窗指派和取消快捷欄物品的功能**。
        - **實現了快捷欄物品的拖放重排功能**。
      - **(新增)** 修復了 `obj_battle_ui` 無法響應 `show_battle_result` 事件並顯示結果的問題（通過修改回調機制）。
    - **採集系統**:
      - 實現了可挖掘的礦石物件 (`obj_stone`)
      - 實現了物品獲取的飛行動畫效果 (`obj_flying_item`)
      - 實現了挖掘進度條和粒子效果
      - 實現了世界座標到螢幕座標的轉換機制
    - **敵人系統**: 工廠模式重構完成，數據驅動加載，實例化與初始化流程分離。
    - **經驗與升級系統重構**:
        - 實現了基於 CSV (`enemies.csv`) 的敵人經驗獎勵 (`exp_reward`)。
        - `obj_battle_manager` 現在會記錄戰鬥中擊敗的敵人經驗，並在勝利後分配給存活的我方單位。
        - 創建了等級經驗表 (`levels.csv`) 和對應的管理員 (`obj_level_manager`)，用於定義和加載升級所需經驗。
        - 重構了 `obj_player_summon_parent` 的經驗獲取 (`gain_exp`) 和升級 (`level_up`) 邏輯，以使用等級表、處理連續升級，並根據模板學習新技能。
        - 實現了升級時的視覺特效（浮動文字 + 粒子效果）。
        - 升級時即時同步所有關鍵欄位到 global.player_monsters，確保 UI 讀取正確。
    - **戰鬥結果事件流修復**:
        - 重新設計了戰鬥結束到結果顯示的事件流程 (`finalize_battle_results`, `rewards_calculated`, `show_battle_result`)。
        - 修正了戰鬥持續時間 (`duration`) 在事件傳遞中丟失的問題。
        - 確保了擊敗敵人數、經驗、金幣等數據在系統間正確傳遞。
    - **放置器修復**: 解決了 `obj_enemy_placer` 因事件廣播時序問題無法轉換的 Bug。
    - **UI 錯誤修復**: 解決了 `obj_monster_manager_ui` 關閉時崩潰、技能不顯示的問題；解決了 UI 繼承導致的初始化變數錯誤。
    - **技能傷害計算**: 將傷害計算邏輯從初始化階段移至實際造成傷害時，避免因依賴未完全初始化的屬性導致計算錯誤。
    - **工具函數**: 添加了自定義的 `array_join` 函數。
    - **UI 顯示修復**: 解決了召喚 UI 和怪物管理 UI 因錯誤獲取 Sprite 方式而無法顯示動態怪物圖片的問題，統一了數據結構 (`display_sprite`) 和 UI 讀取邏輯。
    - **傷害驗證**: 已建立自動化測試 (`rm_damage_test`, `obj_damage_test_controller`, `obj_test_attacker`, `obj_test_target`) 並驗證 `apply_skill_damage` 中動態計算的傷害值符合預期。
    - **運行時錯誤修復**:
        - 解決了因內建函數 `string_is_numeric` 行為異常導致的 CSV 加載崩潰問題（影響 `obj_skill_manager`, `obj_level_manager` 等）。通過創建並使用自定義輔助函數 `is_numeric_safe` 替代了有問題的內建函數。
        - 修復了 `obj_battle_manager` 中 `add_battle_log` 函數因錯誤地對 `ds_list` 使用 `array_*` 函數而導致的崩潰問題，已改用正確的 `ds_list_*` 函數。
        - **獎勵系統重構 (金幣與掉落物)**:
            - `obj_battle_manager` 現在會記錄並在 `finalize_battle_results` 事件中傳遞被擊敗敵人的模板 ID 列表 (`defeated_enemy_ids`)。
            - `obj_reward_system` 的 `calculate_victory_rewards` 函數已重構，現在會根據傳入的 `defeated_enemy_ids` 列表和 `enemies.csv` 中對應的 `gold_reward`（金幣）欄位計算總金幣獎勵。
            - `calculate_victory_rewards` 現在也會解析 `enemies.csv` 中的 `loot_table` 欄位（格式：`item_id:chance:min-max;...`），根據機率和數量範圍計算實際掉落的物品，並將結果存儲在 `battle_result.item_drops` 中。
            - 修復了 `is_numeric_safe` 函數未能正確處理從模板中讀取的數字（而非字符串）的問題。

- **進行中/待辦**:
    - **(高優先級)** **解決 `obj_event_manager` 缺少 `trigger_event` 功能**: 調查獎勵系統等處觸發的警告，實現或修復事件廣播功能。
    - **採集系統擴展**: (保留)
    - **快捷欄持久化**: 在實現存檔系統時，需要保存和加載 `global.player_hotbar`。
    - **互動提示位置 (UX)**: 根據測試反饋，考慮是否將互動提示移到遊戲世界中的互動目標附近。
    - 優化性能
    - 添加音效和音樂
    - 設計遊戲關卡和流程
    - **敵人死亡演出與獎勵流程優化**:
        - **已實現**: 在敵人死亡時 (`on_unit_died`) 計算掉落物。
        - **已實現**: 使用佇列系統 (`obj_battle_manager` 的 `pending_flying_items` 和 `Alarm[1]`) 處理多個 `obj_flying_item` 的創建請求，解決了先前 Alarm 覆蓋導致只處理最後一個物品的問題。
        - **已實現**: 將實際掉落物品列表記錄在 `obj_battle_manager` 的 `current_battle_drops` 中，並通過 `finalize_battle_results` 事件傳遞。
        - **已確認**: `obj_reward_system` 現在能正確接收預先計算好的掉落列表。
        - **已解決**: `obj_flying_item` 的視覺動畫問題。
        - **戰鬥結果 UI**: 需要確認 `obj_battle_ui` 是否正確顯示佇列處理後的所有掉落物品圖示和數量。**(已部分完成顯示流程修復)**
        - **戰鬥結果分層**: (保留) 重構 `obj_battle_manager` 狀態機，加入等待掉落動畫和升級動畫完成的狀態，確保結果 UI 在演出結束後才顯示。
    - **新增**: **根據物品稀有度改變飛行道具 (`obj_flying_item`) 的外框顏色。**
    - **Battle Log 功能**:
        - 在主 HUD 添加按鈕。
        - 創建 `obj_battle_log_ui` 面板。
        - 改進 `obj_battle_manager` 的 `battle_log` 數據結構，記錄詳細事件 (傷害、掉落、經驗等)。
        - 實現日誌顯示、格式化和滾動。
    - **深化戰鬥系統**: (保留詳細點)
        - 設計更多狀態效果、增益/減益、屬性克制、範圍攻擊等技能。
        - 根據敵人 `ai_type` 強化 AI 行為模式。
        - 細化 ATB/回合制融合，考慮行動順序顯示與影響機制。
    - **豐富物品與裝備**: (保留詳細點)
        - 擴展消耗品種類 (MP恢復、狀態治療、復活等)。
        - 增加防具、飾品等裝備部位。
        - 為裝備設計特殊效果 (而不僅是屬性加成)。
    - **完善捕捉與養成**: (保留詳細點)
        - 細化捕捉機制 (受 HP、狀態影響)。
        - 增加怪物養成深度 (技能學習/遺忘、進化、親密度/潛力)。
    - **加入製作/合成系統**: (保留詳細點)
        - 利用現有材料設計製作系統，產出裝備、消耗品、道具等。
    - **擴展世界互動與內容**: (保留詳細點)
        - 設計更多 NPC、任務、商店。
        - 增加地圖探索元素 (寶箱、採集點、隱藏區域)。
        - 考慮加入小遊戲/活動。
    - **UI/UX 優化**: (保留詳細點)
        - 提升戰鬥信息顯示清晰度 (狀態、Buff/Debuff、行動順序)。
        - 優化物品/怪物管理界面 (排序、篩選、比較)。
        - 考慮快捷欄在非戰鬥狀態下的使用。
    - **集中式腳本管理**: 設計 `player_monster.gml` 腳本，統一管理 struct 欄位與同步，優化資料流。
    - **資料流優化**: 持續檢查所有流程，確保資料結構一致與同步正確。

- **已知問題**:
    - **事件管理器 `trigger_event` 功能缺失或調用錯誤。**
    - 飛行道具 (`obj_flying_item`) 的起始座標轉換和飛向玩家目標座標計算可能不準確，尤其在攝像機移動或縮放時，因混合使用世界座標和 GUI 層繪製導致。
    - （新增或修改）飛行道具 (`obj_flying_item`) 在 `FLYING_TO_PLAYER` 狀態下直接使用 `Player.x`, `Player.y` 作為目標，可能在鏡頭快速移動時產生視覺追趕延遲（待觀察）。
    - 重複隱藏 UI 的警告 (`obj_battle_ui`)。

## 玩家怪物資料結構統一方案

- `global.player_monsters` 內每一筆 struct 必須包含以下欄位：
  - id: 模板ID
  - name: 名稱
  - type: 召喚用物件類型
  - level: 等級
  - hp: 當前HP
  - max_hp: 最大HP
  - attack: 攻擊力
  - defense: 防禦力
  - spd: 速度
  - exp: 經驗值（必須有，預設為0）
  - skills: 技能陣列
  - display_sprite: 顯示用精靈（可選）

- 捕獲、初始化、經驗分配、升級等所有流程都必須補齊 exp 欄位，並即時同步所有關鍵欄位。
- 未來將設計 player_monster.gml 腳本，集中管理所有新增、查詢、更新邏輯，確保資料一致性。

## 升級資料同步規範
- 每次 instance 升級時，必須即時將 level、exp、hp、max_hp、attack、defense、spd 等欄位同步回 global.player_monsters。
- 建議以 id 或 type+name 作為唯一 key 進行對應。
- 若 struct 缺少 exp 欄位，則補上。
- UI 讀取 global.player_monsters 時，資料必須即時正確。

### 技能系統

- **技能資料（skills）**：array，每個元素為 struct，包含技能 id、名稱、冷卻等欄位。
- **技能冷卻（skill_cooldowns）**：array，與 skills 完全一一對應，所有操作都用數字索引。
- **技能查找**：如需根據技能 id 查找冷卻，需先在 skills array 找到對應 index，再用該 index 存取 skill_cooldowns。
- **不再使用 struct/ds_map 方式存取技能冷卻。**

**典型用法：**
```gml
// 新增技能
array_push(skills, skill_data);
array_push(skill_cooldowns, 0);

// 根據 id 查找冷卻
var idx = -1;
for (var i = 0; i < array_length(skills); i++) {
    if (skills[i].id == target_id) { idx = i; break; }
}
if (idx != -1) {
    var cd = skill_cooldowns[idx];
}
```

## 背包初始化與 UI 流程重構

- 預設道具初始化邏輯已移至 `obj_game_controller`，只在遊戲啟動時執行一次。
- `obj_inventory_ui` 不再自動加道具，僅負責顯示背包內容。
- 測試確認：無論 UI 是否開啟過，背包內容皆正確，戰鬥後不會被清空。
- 此設計確保遊戲資料初始化與 UI 顯示分離，架構更穩定。
