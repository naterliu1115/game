/// @description 初始化飛行道具

// --- 狀態定義 ---
enum FLYING_STATE {
    FLYING_UP,        // 向上飛行
    PAUSING,          // 停頓
    FLYING_TO_PLAYER, // 飛向玩家
    FADING_OUT        // 淡出並消失
}

// --- 基本設定 (狀態由創建者設置) ---
flight_state = FLYING_STATE.FLYING_UP; // 預設狀態

// --- 計時器與持續時間 ---
pause_timer = 0;
pause_duration = room_speed * 0.8; // 停頓 0.8 秒 (原為 1.5 秒，已縮短)
fade_timer = 0;
fade_duration = room_speed * 0.5; // 淡出時間 0.5 秒 (原為 0.8 秒，已縮短)

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
show_debug_message("飛行道具已創建於座標: (" + string(x) + ", " + string(y) + ")");

// --- 確保在螢幕範圍內 ---
var gui_width = display_get_gui_width();
var gui_height = display_get_gui_height();

// 如果座標超出螢幕範圍，調整到螢幕內
if (x < 0 || x > gui_width || y < 0 || y > gui_height) {
    show_debug_message("警告: 飛行道具座標超出螢幕範圍，調整到螢幕內");
    x = clamp(x, 50, gui_width - 50);
    y = clamp(y, 50, gui_height - 50);
    show_debug_message("調整後的座標: (" + string(x) + ", " + string(y) + ")");
}

// 目標設定將在 Alarm_0 中完成