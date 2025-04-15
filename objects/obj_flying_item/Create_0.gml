/// @description 初始化飛行道具

// --- 狀態定義 ---
enum FLYING_STATE {
    SCATTERING,      // 拋灑/彈跳
    WAIT_ON_GROUND,  // 地面等待
    FLYING_UP,       // 向上飛行（保留給礦石/特殊掉落）
    PAUSING,         // 停頓
    FLYING_TO_PLAYER,// 飛向玩家
    FADING_OUT       // 淡出並消失
}

// --- 新增拋灑/彈跳參數 ---
hspeed = 0; // 水平速度
vspeed = 0; // 垂直速度
// gravity = 0.3; // 重力加速度 (註解掉，改用 Z 軸重力)
z = 0;             // Z 軸高度
zspeed = 0;        // Z 軸速度
gravity_z = 0.3;   // Z 軸重力加速度
tilemap_id = -1; // Tilemap ID，將在 Step 事件中獲取

scatter_speed = 0;
scatter_angle = 0;
scatter_speed_min = 1;
scatter_speed_max = 2;
scatter_angle_range = 360; // 全方向
scatter_radius_min = 16;
scatter_radius_max = 32;
bounce_count = 0;
bounce_count_max = 2;
ground_wait_timer = 0;
wait_duration = room_speed * 2; // 地面停留 2 秒

// === 新增：碰撞相關變數 ===
push_force = 0.2; // 推開力度，需要實驗調整
nearby_items_list = ds_list_create(); // 用於碰撞檢測的列表

// --- 粒子特效參數 ---
particle_effects_enabled = true;

// --- 基本設定 (狀態由創建者設置) ---
// flight_state 由創建者設置，不再強制預設

// --- 計時器與持續時間 ---
pause_timer = 0;
pause_duration = room_speed * 0.8; // 停頓 0.8 秒
fade_timer = 0;
fade_duration = room_speed * 0.5; // 淡出時間 0.5 秒

// --- 飛向玩家相關變數 ---
player_target_x = 0;  // 玩家目標 X 座標
player_target_y = 0;  // 玩家目標 Y 座標
to_player_speed = 6;  // 飛向玩家的速度

// --- 視覺參數 ---
move_speed = 4;        // 向上飛行速度 (像素/幀)
fly_up_distance = 10; // 預設飛行高度，可在創建時覆蓋
image_alpha = 1;       // 初始透明度
image_xscale = 0.8;    // 初始縮放
image_yscale = 0.8;
image_speed = 0;       // 停止精靈動畫
image_index = 0;       // 顯示第一幀
depth = -10000;        // 顯示在最上層

// --- 外框效果 (Draw 事件中使用) ---
outline_offset = 2;
outline_color = c_white;

// --- 基本除錯訊息 ---
show_debug_message("飛行道具已創建於世界座標: (" + string(x) + ", " + string(y) + ")");

// 預設狀態（可選，或完全由創建者設定）
flight_state = FLYING_STATE.FLYING_UP; // 保留一個預設值以防萬一
source_type = "unknown"; // 添加預設來源

// 目標設定將在創建者（如 obj_stone）with 區塊中完成

// === 粒子型態建立（可替換） ===
// 拋灑拖尾粒子
particle_trail = part_type_create();
part_type_shape(particle_trail, pt_shape_pixel);
part_type_size(particle_trail, 0.3, 0.6, 0, 0);
part_type_color1(particle_trail, c_yellow);
part_type_alpha2(particle_trail, 0.8, 0);
part_type_life(particle_trail, 10, 18);
part_type_speed(particle_trail, 0.5, 1, 0, 0);

// 落地衝擊粒子
particle_land = part_type_create();
part_type_shape(particle_land, pt_shape_cloud);
part_type_size(particle_land, 0.5, 1.2, 0, 0);
part_type_color1(particle_land, c_gray);
part_type_alpha2(particle_land, 0.7, 0);
part_type_life(particle_land, 12, 20);
part_type_speed(particle_land, 1, 2, -0.1, 0);

// 吸收閃光粒子
particle_absorb = part_type_create();
part_type_shape(particle_absorb, pt_shape_spark);
part_type_size(particle_absorb, 0.4, 0.8, 0, 0);
part_type_color1(particle_absorb, c_white);
part_type_alpha2(particle_absorb, 1, 0);
part_type_life(particle_absorb, 8, 14);
part_type_speed(particle_absorb, 1, 2, 0, 0);

// === 粒子系統 ===
particle_system = part_system_create();
part_system_depth(particle_system, depth - 1);

// === 飄浮效果變數 ===
ground_y_pos = -1; // 記錄落地時的Y座標
float_timer = 0;   // 用於計算sin函數
float_amplitude = 1; // 浮動幅度（像素）
float_frequency = 0.08; // 浮動頻率