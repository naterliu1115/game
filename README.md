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
- 事件廣播: `broadcast_event(event_name, data = {})` (通過 `obj_event_manager`)
- 事件取消訂閱: `unsubscribe_from_event(event_name, instance_id)` (通過 `obj_event_manager`)
- **更新**: `obj_game_controller` 現在使用 Alarm[0] 延遲廣播 `managers_initialized` 事件，以確保所有實例（如 `obj_enemy_placer`）有足夠時間完成創建和訂閱。

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
        broadcast_event("player_damaged", { damage: 10 });
    }
}
```

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
- `ENDING`: 戰鬥結束過渡
- `RESULT`: 顯示戰鬥結果

**主要功能:**
- 戰鬥初始化
- 回合管理
- 勝負判定
- 獎勵分配
- 經驗系統
- 新增：實現了浮動傷害文字系統 (`obj_floating_text`)，用於即時顯示傷害數值。
- 新增：實現了通用的受傷視覺特效 (`obj_hurt_effect`)，獨立於單位動畫。
- **更新**: 技能傷害計算已從單位初始化階段（可能讀取不完整數據）轉移到實際應用傷害時 (`obj_battle_unit_parent` 的 `apply_skill_damage` 函數中)。現在會根據攻擊者**當前**的攻擊力和技能的傷害倍率 (`damage_multiplier`) 動態計算。
- **傷害驗證**: 已建立自動化測試 (`rm_damage_test`, `obj_damage_test_controller`, `obj_test_attacker`, `obj_test_target`) 並驗證 `apply_skill_damage` 中動態計算的傷害值符合預期。
- **運行時錯誤修復**:
    - 解決了因內建函數 `string_is_numeric` 行為異常導致的 CSV 加載崩潰問題（影響 `obj_skill_manager`, `obj_level_manager` 等）。通過創建並使用自定義輔助函數 `is_numeric_safe` 替代了有問題的內建函數。
    - 修復了 `obj_battle_manager` 中 `add_battle_log` 函數因錯誤地對 `ds_list` 使用 `array_*` 函數而導致的崩潰問題，已改用正確的 `ds_list_*` 函數。

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
        *   戰利品與獎勵 (loot_table, exp_reward, gold_reward)
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
- `scr_coordinate_utils`: 座標轉換工具函數，用於世界座標和 GUI 座標的轉換

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
  - 創建 `obj_flying_item` 顯示獲得物品的視覺效果

**飛行物品 (`obj_flying_item`) 特性:**
- **狀態機設計**: 具有四個狀態：向上飛行 (`FLYING_UP`)、停頓 (`PAUSING`)、飛向玩家 (`FLYING_TO_PLAYER`)、淡出 (`FADING_OUT`)
- **飛行參數**:
  - `fly_up_distance`: 向上飛行的距離，預設為 100 像素
  - `move_speed`: 向上飛行的速度，預設為 5 像素/幀
  - `to_player_speed`: 飛向玩家的速度，預設為 8 像素/幀
  - `pause_duration`: 停頓時間，預設為 0.5 秒
  - `fade_duration`: 淡出時間，預設為 0.5 秒
- **視覺效果**:
  - 使用 `bm_add` 混合模式創建外框發光效果
  - 在飛行過程中會縮小，淡出過程中會進一步縮小並降低透明度
- **座標轉換**:
  - 使用 `world_to_gui_coords` 函數將世界座標轉換為 GUI 座標
  - 確保飛行物品在正確的 GUI 位置顯示

**粒子系統:**
- 使用 GameMaker 的粒子系統創建挖掘效果
- 在 `Create_0` 事件中初始化粒子系統和粒子類型
- 在 `CleanUp_0` 事件中清理粒子系統資源

**座標轉換工具 (`scr_coordinate_utils`):**
- `world_to_gui_coords`: 將世界座標轉換為 GUI 座標
- `gui_to_world_coords`: 將 GUI 座標轉換為世界座標
- 確保座標在螢幕範圍內，避免物品在螢幕外創建

**使用示例:**
```gml
// 創建一個礦石實例
var stone = instance_create_layer(x, y, "Instances", obj_stone);
with (stone) {
    ore_item_id = 4001;  // 設置產出的礦石ID (銅礦石)
    durability = 3;      // 設置需要挖掘的次數
    max_durability = 3;  // 設置最大耐久度
}

// 座標轉換示例
var world_pos = { x: obj_stone.x, y: obj_stone.y };
var gui_coords = world_to_gui_coords(world_pos.x, world_pos.y);

// 手動創建飛行物品
with (instance_create_layer(gui_coords.x, gui_coords.y, "GUI", obj_flying_item)) {
    sprite_index = spr_item;       // 設置物品精靈
    fly_up_distance = 150;        // 自訂飛行高度
    to_player_speed = 10;         // 自訂飛向玩家的速度
    pause_duration = room_speed * 0.3; // 自訂停頓時間
}
```

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
3. 在需要觸發事件的地方，使用 `obj_event_manager` 的 `broadcast_event` 廣播事件

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
    - **放置器修復**: 解決了 `obj_enemy_placer` 因事件廣播時序問題無法轉換的 Bug。
    - **UI 錯誤修復**: 解決了 `obj_monster_manager_ui` 關閉時崩潰、技能不顯示的問題；解決了 UI 繼承導致的初始化變數錯誤。
    - **技能傷害計算**: 將傷害計算邏輯從初始化階段移至實際造成傷害時，避免因依賴未完全初始化的屬性導致計算錯誤。
    - **工具函數**: 添加了自定義的 `array_join` 函數。
    - **UI 顯示修復**: 解決了召喚 UI 和怪物管理 UI 因錯誤獲取 Sprite 方式而無法顯示動態怪物圖片的問題，統一了數據結構 (`display_sprite`) 和 UI 讀取邏輯。
    - **傷害驗證**: 已建立自動化測試 (`rm_damage_test`, `obj_damage_test_controller`, `obj_test_attacker`, `obj_test_target`) 並驗證 `apply_skill_damage` 中動態計算的傷害值符合預期。
    - **運行時錯誤修復**:
        - 解決了因內建函數 `string_is_numeric` 行為異常導致的 CSV 加載崩潰問題（影響 `obj_skill_manager`, `obj_level_manager` 等）。通過創建並使用自定義輔助函數 `is_numeric_safe` 替代了有問題的內建函數。
        - 修復了 `obj_battle_manager` 中 `add_battle_log` 函數因錯誤地對 `ds_list` 使用 `array_*` 函數而導致的崩潰問題，已改用正確的 `ds_list_*` 函數。

- **進行中/待辦**:
    - **快捷欄功能完善**: (保留)
    - **採集系統擴展**: (保留)
    - 完善具體的單位 AI
    - 實現裝備系統的效果
    - 實現捕捉系統的邏輯
    - 設計更多種類的敵人、物品和技能
    - **快捷欄持久化**: 在實現存檔系統時，需要保存和加載 `global.player_hotbar`。
    - **互動提示位置 (UX)**: 根據測試反饋，考慮是否將互動提示移到遊戲世界中的互動目標附近。
    - 優化性能
    - 添加音效和音樂
    - 設計遊戲關卡和流程

- **已知問題**:
    - (清空或更新已知問題列表)
