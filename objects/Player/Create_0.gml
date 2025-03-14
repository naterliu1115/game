debug_message_printed = false;
global.player = id;
if (!variable_global_exists("player_gold")) {
    global.player_gold = 100; // 設定玩家初始金錢
}

// 精确移动所需的变量
xprevious_precise = x;
yprevious_precise = y;
x_remainder = 0;
y_remainder = 0;

// 战斗相关变量
// 注意：这些变量在Step事件中被引用，但根据代码逻辑，它们主要由obj_battle_manager管理
// 我们在这里初始化它们以避免警告
battle_state = 0; // 初始为非战斗状态
battle_center_x = x;
battle_center_y = y;
battle_boundary_radius = 0;

// UI相关变量
ui_cooldown = 0;
surface_needs_update = false;
selected_monster = noone;
open_animation = 0;
info_timer = 0;
info_text = "";
info_alpha = 0;
active = false;

// 其他在Step中使用但未声明的变量
// 注意：根据游戏逻辑，可能需要调整这些初始值
battle_info = "";