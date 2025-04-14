// obj_battle_ui - Create_0.gml
event_inherited();

show = function() {
    visible = true;
    active = true;
    depth = -100; // 確保UI在最上層 (會被UI管理器覆蓋)
};

hide = function() {
    visible = false;
    active = false;
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

// --- 新增：物品網格顯示相關變數 ---
items_start_x = display_get_gui_width() / 2 - 150; // 大致居中，需要微調
items_start_y = display_get_gui_height() / 2 + 100; // 放置在統計數據下方
items_cols = 5;            // 每行顯示5個物品
items_cell_width = 64;     // 每個格子寬度 (包含邊距)
items_cell_height = 64;    // 每個格子高度 (包含邊距)
items_icon_size = 48;      // 圖示繪製大小 (比格子小一點)
hovered_reward_item_index = -1; // 當前滑鼠懸停的物品索引 (-1 表示沒有)
item_popup_instance = noone; // 用於追蹤物品信息彈窗的實例
// --- 結束新增 ---

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

// 重寫獎勵顯示函數，接收更多參數
show_rewards = function(victory_flag, duration_val, enemies_defeated_val, exp_val, gold_val, items_val) {
    // show_debug_message("[DEBUG] show_rewards 被調用"); // 可以移除
    // show_debug_message("[DEBUG] 參數：Victory=" + string(victory_flag) + ", Duration=" + string(duration_val) + ", Defeated=" + string(enemies_defeated_val) + ", EXP=" + string(exp_val) + ", Gold=" + string(gold_val)); // 可以移除
    
    // 更新內部狀態
    battle_victory_status = victory_flag;
    battle_duration = duration_val;
    defeated_enemies_count = enemies_defeated_val;
    reward_exp = exp_val;
    reward_gold = gold_val;
    reward_visible = true;
    
    // 清理舊的物品獎勵顯示
    ds_list_clear(reward_items_list);
    
    // 處理新的物品獎勵
    // show_debug_message("[DEBUG] 處理物品獎勵，數量：" + string(array_length(item_drops))); // 可以移除
    if (is_array(items_val)) {
        // show_debug_message("[DEBUG] 處理物品獎勵，數量：" + string(array_length(items_val))); // 可以移除
        var i;
        var count = array_length(items_val);
        for (i = 0; i < count; i++) {
            // array_push(reward_items_list, items_val[i]); // <-- 註解掉舊的
            ds_list_add(reward_items_list, items_val[i]); // <-- 改用 ds_list_add
        }
    }
    
    surface_needs_update = true;
    // show_debug_message("[DEBUG] surface_needs_update 已設置為 true"); // 移除
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

// --- Define callback method using function syntax --- 
function on_show_battle_result(event_data) {
    // show_debug_message("[DEBUG] obj_battle_ui: Executing on_show_battle_result METHOD for instance " + string(id)); // 移除
    // show_debug_message("===== obj_battle_ui (via method) 收到 show_battle_result 事件 ====="); // 移除
    // show_debug_message("Received data: " + json_stringify(event_data)); // 移除
    
    // 從結構體中提取數據
    var _victory = variable_struct_get(event_data, "victory");
    var _duration = variable_struct_get(event_data, "battle_duration");
    var _defeated = variable_struct_get(event_data, "defeated_enemies");
    var _exp = variable_struct_get(event_data, "exp_gained");
    var _gold = variable_struct_get(event_data, "gold_gained");
    var _items = variable_struct_get(event_data, "item_drops");

    // 檢查數據是否存在
    if (is_undefined(_victory) || is_undefined(_duration) || is_undefined(_defeated) || is_undefined(_exp) || is_undefined(_gold) || is_undefined(_items)) {
        show_debug_message("警告 (on_show_battle_result method): 收到的 show_battle_result 事件數據不完整！"); // 保留警告
        return;
    }

    show_rewards(_victory, _duration, _defeated, _exp, _gold, _items);
    // show_debug_message("(via method) 已呼叫 show_rewards 函數。"); // 移除

    if (!_victory) {
        update_rewards_display(); 
        // show_debug_message("(via method) 檢測到失敗，已呼叫 update_rewards_display。"); // 移除
    }
}

// --- Subscribe immediately after definition, using string name --- 
if (instance_exists(obj_event_manager)) {
    show_debug_message("[DEBUG] obj_battle_ui Create: obj_event_manager FOUND. Attempting subscription with METHOD callback name.");
    obj_event_manager.subscribe_to_event("show_battle_result", id, "on_show_battle_result"); 
    show_debug_message("obj_battle_ui 已訂閱 show_battle_result 事件，回調方法: on_show_battle_result");
} else {
    show_debug_message("警告：無法訂閱事件，obj_event_manager NOT FOUND at subscription time!");
}

// 初始化時顯示戰鬥開始提示
show_info("戰鬥開始！");