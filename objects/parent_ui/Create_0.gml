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

// 提示信息
info_text = "";
info_alpha = 1.0;
info_timer = 0;

// 統一的介面方法
show = function() {
    visible = true;
    active = true;
    surface_needs_update = true;
    // 子類應覆蓋此方法
	
};

hide = function() {
    visible = false;
    active = false;
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