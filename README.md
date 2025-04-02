# 回合制戰鬥遊戲 (TurnBasedBattle)

這是一個使用 GameMaker 開發的回合制戰鬥遊戲，採用事件驅動的架構設計。遊戲允許玩家召喚單位參與戰鬥，擊敗敵人並獲得獎勵。

## 專案架構

### 整體結構

專案遵循 GameMaker 的標準目錄結構:

```
TurnBasedBattle/
├── objects/        # 遊戲對象
├── scripts/        # 腳本函數
├── sprites/        # 圖像資源
├── rooms/          # 遊戲場景
├── fonts/          # 字體資源
├── tilesets/       # 圖塊集
├── datafiles/      # 數據文件
└── options/        # 專案設置
```

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
- `scr_event_system`: 提供事件廣播功能

**主要功能:**
- 事件訂閱: `subscribe_to_event(event_name, instance_id, callback)`
- 事件廣播: `broadcast_event(event_name, data = {})`
- 事件取消訂閱: `unsubscribe_from_event(event_name, instance_id)`

**使用示例:**
```gml
// 訂閱事件
with (obj_event_manager) {
    subscribe_to_event("player_damaged", id, "on_player_damaged");
}

// 廣播事件
broadcast_event("player_damaged", { damage: 10 });
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
- 使用對象池系統優化單位創建和回收
- 追蹤單位統計信息以便進行遊戲平衡

### 5. 對話系統 (Dialogue System)

對話系統管理遊戲中的對話流程，支持 NPC 交互。

**主要組件:**
- `obj_dialogue_manager`: 管理對話狀態和流程
- `obj_dialogue_box`: 顯示對話文本
- `dialogue_functions`: 提供對話相關功能

**主要功能:**
- 開始對話: `start_dialogue(npc)`
- 結束對話: `end_dialogue()`
- 進行對話: `advance_dialogue()`

**使用示例:**
```gml
// 開始與 NPC 對話
start_dialogue(npc_instance);

// 進行對話
if (keyboard_check_pressed(vk_space)) {
    advance_dialogue();
}
```

### 6. 道具系統 (Item System)

道具系統管理遊戲中的所有物品，包括消耗品、裝備、捕捉道具和材料。

**主要組件:**
- `obj_item_manager`: 管理物品數據和操作
- `items_data.csv`: 物品數據配置文件

**物品類型:**
```gml
enum ITEM_TYPE {
    CONSUMABLE,  // 消耗品
    EQUIPMENT,   // 裝備
    CAPTURE,     // 捕捉道具
    MATERIAL     // 材料
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
- 物品完整精靈獲取: `get_item_sprite_full(item_id)`
- 背包操作: `add_item_to_inventory(item_id, quantity)`
- 物品使用: `use_item(item_id)`
- 物品效果執行: `execute_item_effect(item_data)`

**物品數據結構:**
```gml
{
    ID: number,           // 物品ID (1000-9999)
    Name: string,         // 物品名稱
    Type: string,         // 物品類型
    Description: string,  // 物品描述
    Rarity: string,      // 稀有度
    IconSprite: string,   // 圖示精靈名稱
    Sprite: string,       // 完整精靈名稱
    UseEffect: string,    // 使用效果
    EffectValue: number,  // 效果值
    StackMax: number,     // 最大堆疊數量
    SellPrice: number,    // 售價
    Tags: array          // 標籤列表
}
```

**事件整合:**
- 物品添加事件: `item_added`
- 物品使用事件: `item_used`

**錯誤處理:**
- 物品載入失敗處理
- 無效物品ID處理
- 精靈資源缺失處理（使用預設精靈 `spr_gold`）
- 物品驗證失敗處理

### 7. UI 管理系統

UI 系統管理遊戲中的各種用戶界面元素。

**主要組件:**
- `obj_ui_manager`: 全局 UI 管理器
- `parent_ui`: UI 元素的父類
- `obj_battle_ui`: 戰鬥界面
- `obj_inventory_ui`: 物品欄界面
- `obj_monster_manager_ui`: 怪物管理界面
- `obj_summon_ui`: 召喚界面
- `obj_capture_ui`: 捕獲界面

**主要功能:**
- UI 元素顯示與隱藏
- UI 交互處理
- UI 狀態同步
- 物品欄管理：
  - 物品展示與排序
  - 物品使用介面
  - 物品詳細信息顯示
  - 物品堆疊顯示
- 拖放操作處理
- UI 動畫效果
- 彈出提示管理

**事件處理:**
- 物品添加/移除時更新顯示
- 物品使用時的動畫效果
- 物品數量變化的即時更新
- 錯誤提示的顯示

**優化處理:**
- UI 元素對象池
- 動態加載和卸載
- 視圖裁剪優化
- 事件節流和防抖

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
2. 在 Create 事件中設置單位屬性
3. 在 `obj_unit_manager` 中註冊新單位類型
4. 設置單位的動畫幀範圍和速度參數

### 自定義角色動畫
1. 修改角色的 `animation_frames` 結構體來定義各種動畫的幀範圍
2. 調整 `animation_speed` 和 `animation_update_rate` 變數控制動畫速度
3. 可以為特定動畫類型(如IDLE)設置專用速度參數
4. 在 `Create_0.gml` 中集中定義動畫參數，便於統一管理

### 添加新事件
1. 在需要監聽事件的對象中添加對應的回調方法
2. 使用 `subscribe_to_event` 訂閱事件
3. 使用 `broadcast_event` 在適當的時機廣播事件

### 擴展戰鬥系統
1. 在 `obj_battle_manager` 中添加新的戰鬥邏輯
2. 創建新的戰鬥狀態或修改現有狀態
3. 通過事件系統與其他系統協調

## 開發注意事項

- 使用事件系統進行對象間通信，避免直接引用
- 遵循命名規範: `obj_` 前綴用於對象，`scr_` 前綴用於腳本
- 使用適當的注釋說明代碼目的和功能
- 優先使用父類定義共用行為，避免代碼重複
- 保持每個對象的職責單一，遵循單一職責原則

## 程式碼風格

- 使用駝峰命名法 (camelCase) 命名變量和函數
- 使用下劃線命名法 (snake_case) 命名對象和資源
- 對複雜邏輯添加詳細注釋
- 重要函數添加 JSDoc 風格的函數文檔
- 相關功能分組並用註釋分隔

## 調試技巧

- 使用 `show_debug_message()` 輸出調試信息
- 啟用事件系統的 `event_debug_mode` 跟踪事件流
- 使用 `obj_battle_manager` 中的調試繪制功能可視化戰鬥區域和單位狀態
- 利用動畫系統的調試輸出監控角色動畫狀態變化 

## 專案進度與未來展望

// ... existing content ... 