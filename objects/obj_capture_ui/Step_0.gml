// obj_capture_ui - Step_0.gml
// 如果非活動狀態，檢查是否需要隱藏
if (!active) {
    if (visible && open_animation <= 0) {
        visible = false;
    }
    return;
}

// 如果正在關閉UI
if (active && !visible) {
    open_animation -= open_speed;
    
    if (open_animation <= 0) {
        open_animation = 0;
        active = false;
        visible = false;
        return;
    }
    
    // 更新 UI 尺寸（關閉動畫）
    var target_width = display_get_gui_width() * 0.7;
    var target_height = display_get_gui_height() * 0.5;
    
    ui_width = target_width * open_animation;
    ui_height = target_height * open_animation;
    ui_x = (display_get_gui_width() - ui_width) / 2;
    ui_y = (display_get_gui_height() - ui_height) / 2;
    
    surface_needs_update = true;
    return;
}

// 更新動畫
if (visible && open_animation < 1) {
    open_animation += open_speed;
    
    if (open_animation > 1) {
        open_animation = 1;
    }
    
    // 更新 UI 尺寸（開啟動畫）
    var target_width = display_get_gui_width() * 0.7;
    var target_height = display_get_gui_height() * 0.5;
    
    ui_width = target_width * open_animation;
    ui_height = target_height * open_animation;
    ui_x = (display_get_gui_width() - ui_width) / 2;
    ui_y = (display_get_gui_height() - ui_height) / 2;
    
    // 更新按鈕位置
    capture_btn_x = ui_x + ui_width / 4 - capture_btn_width / 2;
    capture_btn_y = ui_y + ui_height - 60;
    
    cancel_btn_x = ui_x + ui_width * 3/4 - cancel_btn_width / 2;
    cancel_btn_y = ui_y + ui_height - 60;
    
    surface_needs_update = true;
}

// 捕獲中狀態不處理輸入
if (capture_state == "capturing" || capture_state == "success" || capture_state == "failed") {
    return;
}

// 如果UI活躍且有目標，更新捕獲率
if (active && target_enemy != noone && instance_exists(target_enemy)) {
    calculate_capture_chance();
}

// 鼠標控制
if (mouse_check_button_pressed(mb_left)) {
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    
    if (capture_state == "ready") {
        // 檢查是否點擊了捕獲按鈕
        if (point_in_rectangle(
            mx, my,
            capture_btn_x, capture_btn_y,
            capture_btn_x + capture_btn_width, capture_btn_y + capture_btn_height
        )) {
            attempt_capture();
            return;
        }
        
        // 檢查是否點擊了取消按鈕
        if (point_in_rectangle(
            mx, my,
            cancel_btn_x, cancel_btn_y,
            cancel_btn_x + cancel_btn_width, cancel_btn_y + cancel_btn_height
        )) {
            hide();
            return;
        }
        
        // 檢查是否點擊了關閉按鈕（沒有目標時）
        if (target_enemy == noone || !instance_exists(target_enemy)) {
            var close_btn_x = ui_x + ui_width / 2 - 60;
            var close_btn_y = ui_y + ui_height - 60;
            
            if (point_in_rectangle(
                mx, my,
                close_btn_x, close_btn_y,
                close_btn_x + 120, close_btn_y + 40
            )) {
                hide();
                return;
            }
        }
        
        // 檢查是否選擇了不同的捕獲方法
        if (target_enemy != noone && instance_exists(target_enemy)) {
            var method_count = array_length(capture_methods);
            var method_x = ui_x + 180;
            var method_y = ui_y + 180;
            
            for (var i = 0; i < method_count; i++) {
                var option_y = method_y + 25 + (i * 30);
                
                if (point_in_rectangle(
                    mx, my,
                    method_x - 20, option_y - 10,
                    method_x + 300, option_y + 10
                )) {
                    selected_method = i;
                    calculate_capture_chance(); // 更新捕獲率
                    break;
                }
            }
        }
    }
}

// 鍵盤控制
if (keyboard_check_pressed(vk_escape)) {
    hide();
    return;
}

if (capture_state == "ready") {
    if (keyboard_check_pressed(vk_up)) {
        // 向上選擇捕獲方法
        if (selected_method > 0) {
            selected_method--;
            calculate_capture_chance(); // 更新捕獲率
        }
    }

    if (keyboard_check_pressed(vk_down)) {
        // 向下選擇捕獲方法
        if (selected_method < array_length(capture_methods) - 1) {
            selected_method++;
            calculate_capture_chance(); // 更新捕獲率
        }
    }

    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
        attempt_capture();
    }
}

// 檢查目標敵人是否仍然有效
if (target_enemy != noone && !instance_exists(target_enemy)) {
    target_enemy = noone;
    
    // 如果捕獲過程中目標消失，關閉UI
    if (capture_state == "capturing") {
        hide();
    }
}

// 檢查surface是否丟失
if (active && !surface_exists(ui_surface)) {
    surface_needs_update = true;
}