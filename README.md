
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
- 物品數據載入: `load_items_data()` (已重構，整合精靈ID查找)
- 物品驗證: `validate_item_data(item_data)` (現在驗證包含精靈ID的結構)
- 獲取物品: `get_item(item_id)`
- 物品圖示獲取: `get_item_sprite(item_id)` (現在直接返回存儲的精靈ID)
- 物品完整精靈獲取: `get_item_sprite_full(item_id)` (現在直接返回存儲的精靈ID)
- 物品類型獲取: `get_item_type(item_id)` (現在基於物品的 Category 數值)
- 背包操作: `add_item_to_inventory(item_id, quantity)` (改進了堆疊上限處理邏輯)
- 物品使用: `use_item(item_id)`
- 物品效果執行: `execute_item_effect(item_data)` (改進了對不同 UseEffect 的處理，例如非消耗品返回 false)

**物品數據結構 (存儲在 `items_data` ds_map 中):**
```gml
{
    ID: number,           // 物品ID (1000-9999)
    Name: string,         // 物品名稱
    Type: string,         // 物品類型 (來自CSV，主要供參考)
    Description: string,  // 物品描述
    Rarity: string,      // 稀有度 (來自CSV)
    IconSprite: number,   // 圖示精靈 ID (重要：載入時查找並直接存儲ID)
    Sprite: number,       // 完整精靈 ID (重要：載入時查找並直接存儲ID)
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
- 物品載入失敗處理。
- 無效物品ID處理。
- 物品驗證失敗處理 (基於更新後的數據結構)。
- CSV 讀取時增加了對空行或不完整行的跳過處理。

### 7. UI 管理系統

UI 系統管理遊戲中的各種用戶界面元素。

**主要組件:**
- `obj_ui_manager`: 全局 UI 管理器
- `parent_ui`: UI 元素的父類
- `obj_battle_ui`: 戰鬥界面
- `obj_inventory_ui`: 物品欄界面 (詳細描述見下)
- `obj_item_info_popup`: 物品資訊彈出視窗 (詳細描述見下)
- `obj_monster_manager_ui`: 怪物管理界面
- `obj_summon_ui`: 召喚界面
- `obj_capture_ui`: 捕獲界面

**主要功能:**
- UI 元素顯示與隱藏
- UI 交互處理
- UI 狀態同步
- **物品欄管理 (`obj_inventory_ui`):**
    - **分類篩選**: 負責管理頂部的分類標籤頁 (Tabs)，並根據當前選中的分類（如消耗品、裝備、工具等）從 `global.player_inventory` 中嚴格篩選物品。
    - **物品展示**: 在網格佈局中繪製篩選後物品的圖示 (使用 `get_item_sprite` 返回的 ID) 和堆疊數量。
    - **滾動支持**: 實現物品列表的垂直滾動功能。
    - **交互處理**: 精確檢測滑鼠在物品圖標上的懸停和點擊事件（點擊範圍已校準）。
    - **信息彈窗觸發**: 滑鼠懸停時，創建或更新 `obj_item_info_popup` 實例以顯示物品詳情，並傳遞物品 ID。
    - **物品使用交互**: 可能處理雙擊或右鍵點擊事件，以啟動物品使用 (`use_item`) 或其他操作。
- **物品資訊彈窗 (`obj_item_info_popup`):**
    - **詳細信息展示**: 從 `obj_item_manager` 獲取指定物品 ID 的完整數據，並在彈窗中清晰地展示名稱、描述、類型、稀有度、效果、數值、標籤、售價等信息。
    - **智能定位與邊界檢測**: 根據觸發源（如滑鼠位置）智能定位，並確保彈窗始終完整顯示在屏幕範圍內。
    - **單例管理與清理**: 確保同一時間最多只有一個資訊彈窗可見，舊的彈窗會被自動清理。
    - **自動銷毀**: 當滑鼠移開對應物品或物品欄關閉時，彈窗會自動銷毀。
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

### 8. 浮動文字系統 (Floating Text System)

該系統用於在遊戲畫面上顯示短暫的浮動文字，例如傷害數字、狀態效果提示等。

**主要組件:**
- `obj_floating_text`: 負責單個浮動文字的顯示、動畫（上浮、淡出）和自我銷毀。

**主要功能:**
- 在指定位置創建浮動文字實例。
- 可自訂顯示文字、顏色、浮動速度、淡出速度。

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

(您可以在這裡添加專案的具體進度、已知問題和未來的開發計劃)

- **已完成**:
    - 基礎八方向動畫系統
    - 事件驅動框架 (`obj_event_manager`)
    - 基礎戰鬥流程狀態機 (`obj_battle_manager`)
    - 單位父類和基礎行為 (`obj_battle_unit_parent`)
    - 浮動文字和受傷特效
    - 非戰鬥狀態下的單位遊蕩行為
    - **道具系統重構**:
        - 使用 CSV 載入數據 (`obj_item_manager`)
        - 支持消耗品、裝備、捕捉、材料、工具類型
        - 在載入時直接查找並存儲精靈 ID
        - 使用預設精靈處理未找到的資源
        - 實現物品添加、使用和效果執行
    - **UI 系統**:
        - 物品欄界面 (`obj_inventory_ui`) 支持分類篩選、滾動、精確交互
        - 物品信息彈窗 (`obj_item_info_popup`) 支持智能定位和單例管理

- **進行中/待辦**:
    - 完善具體的單位 AI
    - 實現裝備系統的效果
    - 實現捕捉系統的邏輯
    - 設計更多種類的敵人、物品和技能
    - 優化性能
    - 添加音效和音樂
    - 設計遊戲關卡和流程

- **已知問題**:
    - (列出當前遇到的主要問題或 Bug)
