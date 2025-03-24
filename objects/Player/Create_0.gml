debug_message_printed = false;
battle_result_handled = false;
battle_timer = 0;

// 初始化全局戰鬥計時器
if (!variable_global_exists("battle_timer")) {
    global.battle_timer = 0;
}

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

// 動畫相關變數
enum PLAYER_ANIMATION {
    IDLE = 0,
    WALK_DOWN = 1,
    WALK_DOWN_RIGHT = 2,
    WALK_RIGHT = 3,
    WALK_UP_RIGHT = 4,
    WALK_UP = 5,
    WALK_UP_LEFT = 6,
    WALK_LEFT = 7,
    WALK_DOWN_LEFT = 8
}

// 動畫幀範圍
ANIMATION_FRAMES = {
    IDLE: [0, 4],           
    WALK_DOWN: [5, 9],      
    WALK_DOWN_RIGHT: [10, 14],
    WALK_RIGHT: [15, 19],    
    WALK_UP_RIGHT: [20, 24],
    WALK_UP: [25, 29],      
    WALK_UP_LEFT: [30, 34],  
    WALK_LEFT: [35, 39],     
    WALK_DOWN_LEFT: [40, 44]
}

// 動畫系統變數
current_animation = PLAYER_ANIMATION.IDLE;
current_animation_name = "";
animation_speed = 1;        // 一般動畫速度
idle_animation_speed = 0.7;   // IDLE動畫速度

// 初始化動畫
image_index = ANIMATION_FRAMES.IDLE[0];
image_speed = idle_animation_speed;

// 位置追蹤
last_x = x;
last_y = y;

// 移動相關變數
move_speed = 4;