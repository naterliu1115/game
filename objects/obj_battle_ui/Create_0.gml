// obj_battle_ui - Create_0.gml
event_inherited();

show = function() {
    visible = true;
    active = true;
    depth = -100; // 確保UI在最上層 (會被UI管理器覆蓋)
};

// UI位置和尺寸
ui_width = display_get_gui_width();
ui_height = 120; // 稍微增加高度
ui_y = display_get_gui_height() - ui_height;
global.info_timer = 0;  // UI 信息顯示相關變數

// 創建UI表面
ui_surface = -1;
surface_needs_update = true;

// 單位信息顯示
unit_info_x = 20;
unit_info_y = ui_y + 15;
unit_info_width = 300;
unit_info_height = 90;

// 召喚按鈕
summon_btn_x = ui_width - 340;
summon_btn_y = ui_y + 40;
summon_btn_width = 120;
summon_btn_height = 40;

// 戰術切換按鈕
tactics_btn_x = ui_width - 200;
tactics_btn_y = ui_y + 40;
tactics_btn_width = 120;
tactics_btn_height = 40;

// 當前戰術模式
current_tactic = 0; // 0=積極，1=跟隨，2=待命

// 戰鬥信息
battle_info = "";

// 卡片動畫參數
card_animation = 0;
card_animation_speed = 0.1;

// 戰鬥結果數據 (用於顯示)
battle_victory_status = -1; // 儲存戰鬥勝敗狀態 (-1: 未知, 0: 失敗, 1: 勝利)
battle_duration = 0;          // 儲存戰鬥持續時間 (秒)
defeated_enemies_count = 0; // 儲存本場戰鬥擊敗的敵人數量
reward_exp = 0;             // 儲存獲得或損失的經驗值
reward_gold = 0;            // 儲存獲得或損失的金幣 (失敗時為負數)
reward_items_list = ds_list_create(); // 儲存獲得的物品列表 (結構體數組)
reward_visible = false;       // 控制獎勵/結果面板是否可見的標誌
defeat_penalty_text = "";    // 儲存用於顯示失敗懲罰的特定文本 (例如 "損失金幣: XXX")
is_showing_results = false; // 新增：標誌是否正在顯示結果畫面

// --- 新增：物品網格顯示相關變數 ---
items_start_x = display_get_gui_width() / 2 - 150; // 大致居中，需要微調
items_start_y = display_get_gui_height() / 2 + 110; // 放置在統計數據下方
items_cols = 5;            // 每行顯示5個物品
item_slot_width = 64;      // 修改：格子本身的寬度
item_slot_height = 64;     // 修改：格子本身的高度
item_padding_x = 10;       // 新增：格子間水平間距
item_padding_y = 10;       // 新增：格子間垂直間距
items_icon_size = 48;      // 圖示繪製大小 (比格子小一點)
hovered_reward_item_index = -1; // 當前滑鼠懸停的物品索引 (-1 表示沒有)
selected_reward_item_index = -1; // 當前被點選的戰利品索引 (-1 表示沒有)
item_popup_instance = noone; // 用於追蹤物品信息彈窗的實例
// --- 結束新增/修改 ---

// 初始化UI信息變數
info_text = "";
info_alpha = 1.0;
info_timer = 0;
active = true; // 初始為活躍狀態

/// 顯示提示信息
/// @param {string} text 要顯示的文本
show_info = function(text) {
    info_text = text;
    info_alpha = 1;
    info_timer = 120; // 2秒顯示時間
};

// 重寫獎勵顯示函數，現在作為事件回調，接收 event_data 結構體
show_rewards = function(event_data) { // <-- 修改函數簽名
    show_debug_message("[obj_battle_ui show_rewards (Event Handler)] 收到事件數據。");
    show_debug_message("===== obj_battle_ui (show_rewards 作為處理器) 處理事件 =====");
    show_debug_message("Received data: " + json_stringify(event_data));

    // 檢查 event_data 是否為結構體
    if (!is_struct(event_data)) {
        show_debug_message("錯誤：[obj_battle_ui show_rewards] event_data 不是有效的結構體！");
        return;
    }

    // --- 新增：從 event_data 提取數據 ---
    var _victory = variable_struct_get(event_data, "victory");
    var _duration = variable_struct_get(event_data, "battle_duration");
    var _defeated = variable_struct_get(event_data, "defeated_enemies");
    var _exp = variable_struct_get(event_data, "exp_gained");
    var _gold = variable_struct_get(event_data, "gold_gained");
    var _items = variable_struct_get(event_data, "item_drops"); // 確保使用正確鍵名

    // 檢查數據是否有效
    if (is_undefined(_victory) || is_undefined(_duration) || is_undefined(_defeated) || is_undefined(_exp) || is_undefined(_gold) || is_undefined(_items)) {
        show_debug_message("警告：[obj_battle_ui show_rewards] 收到的事件數據不完整！");
        return;
    }
    // --- 結束新增提取數據 ---

    // --- 新增：整合 on_show_battle_result_event 的核心邏輯 ---
    // 設置標誌
    is_showing_results = true;
    reward_visible = true;
    show_debug_message("[obj_battle_ui show_rewards] 將 is_showing_results 和 reward_visible 設為 true。");

    // 更新內部狀態 (這些變數用於繪圖)
    battle_victory_status = _victory;
    battle_duration = _duration;
    defeated_enemies_count = _defeated;
    reward_exp = _exp;
    reward_gold = _gold; // 包含勝利/失敗的金幣值
    // --- 結束整合：設置標誌和內部狀態 ---

    // --- 保留：處理物品列表的邏輯 ---
    ds_list_clear(reward_items_list);
    if (is_array(_items)) {
        var i;
        var count = array_length(_items);
        for (i = 0; i < count; i++) {
            ds_list_add(reward_items_list, _items[i]);
        }
        show_debug_message("[obj_battle_ui show_rewards] 處理了 " + string(count) + " 個物品。");
    }
    // --- 結束保留：物品列表處理 ---

    // --- 新增：整合失敗處理和視覺更新 ---
    // 統一調用 update_rewards_display 來確保懲罰文本（如果失敗）和視覺更新
    update_rewards_display();
    show_debug_message("[obj_battle_ui show_rewards] 已呼叫 update_rewards_display (for penalty/visual update)。");
    // --- 結束整合：失敗處理和視覺更新 ---


    // --- 新增：整合通知 UI 管理器的邏輯 ---
    if (instance_exists(obj_ui_manager)) {
        obj_ui_manager.show_ui(id, "main");
        show_debug_message("[obj_battle_ui show_rewards] 已通知 UI 管理器顯示此 UI (ID: " + string(id) + ")");
    } else {
        show_debug_message("警告：[obj_battle_ui show_rewards] UI 管理器不存在，無法註冊！");
    }
    // --- 結束整合：通知 UI 管理器 ---

    // 標記表面需要更新 (原 show_rewards 和 update_rewards_display 都有此操作)
    surface_needs_update = true;
    show_debug_message("[obj_battle_ui show_rewards] 事件處理完成，surface_needs_update = true。");
};

// 更新戰敗獎勵/懲罰顯示的方法
update_rewards_display = function() {
    // show_debug_message("[DEBUG] update_rewards_display 被調用"); // 可以移除
    
    // 根據 reward_gold (應為負數) 準備懲罰文本
    if (reward_gold < 0) {
        defeat_penalty_text = "損失金幣: " + string(abs(reward_gold));
        // show_debug_message("[DEBUG] 設置失敗懲罰文本: " + defeat_penalty_text); // 移除
    } else {
        // 如果 gold 不是負數，可能表示沒有損失或數據有誤，清空文本
        defeat_penalty_text = ""; 
        // show_debug_message("[DEBUG] 未檢測到金幣損失 (reward_gold: " + string(reward_gold) + ")"); // 移除
    }
    
    // 強制刷新表面，確保 Draw 事件能讀取最新的 defeat_penalty_text
    surface_needs_update = true; 
};

// --- 修改：使用 "show_rewards" 作為回調 ---
if (instance_exists(obj_event_manager)) {
    // 移除舊的回調嘗試
    // var _callback_method_name = "on_show_battle_result_event";
    // obj_event_manager.subscribe_to_event("show_battle_result", id, _callback_method_name);
    // show_debug_message("...");

    // 使用現有的 "show_rewards" 方法名 (字串) 進行訂閱
    var _callback_method_name = "show_rewards"; // <-- 修改這裡
    obj_event_manager.subscribe_to_event("show_battle_result", id, _callback_method_name);
    show_debug_message("obj_battle_ui 已訂閱 show_battle_result 事件，回調方法名: " + _callback_method_name);

} else {
    show_debug_message("警告：無法訂閱事件，obj_event_manager NOT FOUND at subscription time!");
}

// --- 新增：處理關閉輸入的方法 ---
handle_close_input = function() {
    show_debug_message("[Battle UI] handle_close_input called.");
    
    // 確保只在顯示結果時響應
    if (!is_showing_results) {
        show_debug_message("[Battle UI] handle_close_input ignored: Not showing results.");
        return;
    }

    // 停止顯示結果
    is_showing_results = false;
    reward_visible = false; // 重置這個標誌

    // 廣播關閉事件
    if (instance_exists(obj_event_manager)) {
        broadcast_event("battle_result_closed", {}); 
        show_debug_message("[Battle UI] Broadcasted battle_result_closed event.");
    } else {
        show_debug_message("錯誤：[Battle UI] 無法廣播 battle_result_closed，事件管理器不存在。");
    }

    // 讓 UI 管理器隱藏自己 <--- 註解掉這部分
    /*
    if (instance_exists(obj_ui_manager)) {
         with(obj_ui_manager) {
             hide_ui(other.id); // other.id 指向 obj_battle_ui 實例
             show_debug_message("[Battle UI] Requested UI Manager to hide self (ID: " + string(other.id) + ").");
         }
    } else {
         show_debug_message("錯誤：[Battle UI] 無法通過 UI 管理器隱藏，管理器不存在。");
         hide(); // 備選方案
    }
    */
}

// 初始化時顯示戰鬥開始提示
show_info("戰鬥開始！");