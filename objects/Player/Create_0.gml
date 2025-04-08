debug_message_printed = false;
battle_result_handled = false;
battle_timer = 0;

// 滑鼠方向追蹤
mouse_direction = 0;        // 滑鼠方向角度
facing_direction = 0;       // 角色面向方向
is_moving = false;         // 是否正在移動

// 挖礦相關變數
is_mining = false;         // 是否正在挖礦
mining_animation_frame = 0; // 挖礦動畫幀
mining_animation_complete = true; // 單次挖礦動畫是否完成
mining_direction = 0;      // 挖礦方向（左/右）
MINING_ANIMATION_SPEED = 0.25; // 挖礦動畫速度
MINING_LAST_FRAME_DELAY = room_speed * 0.2; // 最後一幀停留時間（0.2秒）
mining_last_frame_timer = 0; // 最後一幀計時器

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
    WALK_DOWN_LEFT = 8,
	MINING_LEFT = 9,
	MINING_RIGHT = 10
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
    WALK_DOWN_LEFT: [40, 44],
    MINING_LEFT: [50, 54],
    MINING_RIGHT: [45, 49]
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
move_speed = 3;

// 工具裝備相關變數
equipped_tool = noone;       // 當前裝備的工具
equipped_tool_id = -1;      // 當前裝備的工具ID
equipped_tool_sprite = -1;  // 當前裝備的工具精靈
equipped_tool_name = "";    // 當前裝備的工具名稱
equipped_tool_value = 0;    // 當前裝備的工具效果值

// 玩家手部在不同挖礦動畫幀中的位置 (已修正為相對於中心原點[16,16])
// 右側挖礦動作的手部座標
tool_attach_points_right = [
    [5, 7],    // 第0幀 (原 [21, 23])
    [-8, -2],  // 第1幀 (原 [8, 14])
    [7, 4],    // 第2幀 (原 [23, 20])
    [7, 5],    // 第3幀 (原 [23, 21])
    [6, 9]     // 第4幀 (原 [22, 25])
];

// 左側挖礦動作的手部座標
tool_attach_points_left = [
    [-6, 6],   // 第0幀 (原 [10, 22])
    [7, -2],   // 第1幀 (原 [23, 14])
    [-7, 4],   // 第2幀 (原 [9, 20])
    [-7, 5],   // 第3幀 (原 [9, 21])
    [-8, 5]    // 第4幀 (原 [8, 21])
];

// 礦鎬手把在精靈中的位置
pickaxe_handle_offset = [6, 24]; // 手把在這裡