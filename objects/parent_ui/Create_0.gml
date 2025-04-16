// 建立 parent_ui 物件，所有 UI 物件繼承自它
// parent_ui - Create_0.gml
visible = false;
active = false;
depth = -100;

// 明確設置字體 - 與obj_dialogue_box相同
draw_set_font(fnt_dialogue);

// 尺寸和位置
ui_width = 0;
ui_height = 0;
ui_x = 0;
ui_y = 0;

// 表面管理
ui_surface = -1;
surface_needs_update = true;

// 動畫相關
open_animation = 0;
open_speed = 0.1;
close_animation = 0;
alpha = 1;
is_closing = false;
close_callback = undefined;

// 提示信息
info_text = "";
info_alpha = 1.0;
info_timer = 0;

// 控制設置
allow_player_movement = false; // 是否允許玩家移動
allow_game_controls = false;   // 是否允許遊戲控制（如互動、召喚等）

// 狀態追蹤
last_active_state = false;     // 用於追蹤狀態變化

// 統一的介面方法
show = function() {
    if (!active) {  // 只在狀態改變時輸出
        show_debug_message("UI顯示: " + object_get_name(object_index));
        show_debug_message("允許移動: " + string(allow_player_movement));
        show_debug_message("允許遊戲控制: " + string(allow_game_controls));
    }
    
    visible = true;
    active = true;
    surface_needs_update = true;
    last_active_state = true;
    // 子類應覆蓋此方法
};

hide = function() {
    if (active) {  // 只在狀態改變時輸出
        show_debug_message("UI隱藏: " + object_get_name(object_index) + " (ID: " + string(id) + ")");
    }
    
    visible = false;
    active = false;
    last_active_state = false;
    
    // 釋放表面資源
    if (surface_exists(ui_surface)) {
        surface_free(ui_surface);
        ui_surface = -1;
    }
    
    // 子類應覆蓋此方法
};

// 共用的表面檢查方法
check_surface = function() {
    if (active && !surface_exists(ui_surface)) {
        surface_needs_update = true;
        return true;
    }
    return false;
};

// 添加調試信息，打印實例ID和物件名稱
show_debug_message("創建 parent_ui 子類實例：" + string(id) + " - " + object_get_name(object_index));