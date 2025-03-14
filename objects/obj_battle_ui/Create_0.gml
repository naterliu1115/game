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
current_tactic = 0; // 0=積極，1=防守，2=追击

// 戰鬥信息
battle_info = "";

// 卡片動畫參數
card_animation = 0;
card_animation_speed = 0.1;

// 戰鬥結果數據
battle_result = {
    victory: false,
    exp_gained: 0,
    defeated_enemies: 0,
    duration: 0
};

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

// 儲存戰鬥結算資訊
reward_exp = 0;
reward_gold = 0;
reward_items_list = [];
reward_visible = false;

// 重寫獎勵顯示函數，使用非常基本的語法
show_rewards = function(exp_val, gold_val, items_val) {
    reward_exp = exp_val;
    reward_gold = gold_val;
    reward_visible = true;
    
    // 清空現有物品列表
    reward_items_list = [];
    
    // 只有在輸入是陣列時才處理
    if (is_array(items_val)) {
        var i;
        var count = array_length(items_val);
        for (i = 0; i < count; i++) {
            array_push(reward_items_list, items_val[i]);
        }
    }
};

// 初始化時顯示戰鬥開始提示
show_info("戰鬥開始！");