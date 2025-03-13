// obj_summon_ui - Step_0.gml
if (!active) {
    if (visible && open_animation <= 0) {
        hide();
    }
    return;
}

// 如果正在關閉UI
if (active && open_animation > 0 && !visible) {
    open_animation -= open_speed;
    if (open_animation <= 0) {
        open_animation = 0;
        active = false;
        visible = false;
    }
    
    // 重新計算UI位置和尺寸（動畫效果）
    var target_width = display_get_gui_width() * 0.8;
    var target_height = display_get_gui_height() * 0.7;
    
    ui_width = target_width * open_animation;
    ui_height = target_height * open_animation;
    ui_x = (display_get_gui_width() - ui_width) / 2;
    ui_y = (display_get_gui_height() - ui_height) / 2;
    
    return;
}

// 鼠標控制
if (mouse_check_button_pressed(mb_left)) {
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    
    // 檢查是否點擊了召喚按鈕
    if (selected_monster >= 0 && point_in_rectangle(
        mx, my,
        summon_btn_x, summon_btn_y,
        summon_btn_x + summon_btn_width, summon_btn_y + summon_btn_height
    )) {
        // 嘗試召喚所選怪物
        if (summon_selected_monster()) {
            // 召喚成功，關閉UI
            hide();
        }
    }
    
    // 檢查是否點擊了取消按鈕
    if (point_in_rectangle(
        mx, my,
        cancel_btn_x, cancel_btn_y,
        cancel_btn_x + cancel_btn_width, cancel_btn_y + cancel_btn_height
    )) {
        // 關閉UI
        hide();
    }
    
    // 檢查是否點擊了怪物卡片
    var list_count = ds_list_size(monster_list);
    if (list_count > 0) {
        var start_index = clamp(scroll_offset, 0, max(0, list_count - max_visible_monsters));
        var end_index = min(start_index + max_visible_monsters, list_count);
        
        for (var i = start_index; i < end_index; i++) {
            var card_y = ui_y + 50 + (i - start_index) * 130;
            
            if (point_in_rectangle(
                mx, my,
                ui_x + 20, card_y,
                ui_x + 20 + 220, card_y + 120
            )) {
                selected_monster = i;
                break;
            }
        }
    }
    
    // 檢查是否點擊了滾動箭頭
    if (ds_list_size(monster_list) > max_visible_monsters) {
        // 上滾動箭頭
        if (scroll_offset > 0 && point_in_rectangle(
            mx, my,
            ui_x + ui_width - 40, ui_y + 45,
            ui_x + ui_width - 5, ui_y + 65
        )) {
            scroll_offset--;
        }
        
        // 下滾動箭頭
        if (scroll_offset < ds_list_size(monster_list) - max_visible_monsters && point_in_rectangle(
            mx, my,
            ui_x + ui_width - 40, ui_y + ui_height - 90,
            ui_x + ui_width - 5, ui_y + ui_height - 70
        )) {
            scroll_offset++;
        }
    }
}

// 鍵盤控制
if (keyboard_check_pressed(vk_escape)) {
    // ESC關閉UI
    hide();
}

if (keyboard_check_pressed(vk_up)) {
    // 向上選擇
    if (selected_monster > 0) {
        selected_monster--;
        // 如果需要滾動顯示
        if (selected_monster < scroll_offset) {
            scroll_offset = selected_monster;
        }
    }
}

if (keyboard_check_pressed(vk_down)) {
    // 向下選擇
    if (selected_monster < ds_list_size(monster_list) - 1) {
        selected_monster++;
        // 如果需要滾動顯示
        if (selected_monster >= scroll_offset + max_visible_monsters) {
            scroll_offset = selected_monster - max_visible_monsters + 1;
        }
    }
}

if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
    // 確認選擇
    if (selected_monster >= 0) {
        if (summon_selected_monster()) {
            hide();
        }
    }
}

// 滾輪控制滾動
var wheel = mouse_wheel_down() - mouse_wheel_up();
if (wheel != 0 && ds_list_size(monster_list) > max_visible_monsters) {
    scroll_offset = clamp(
        scroll_offset + wheel,
        0,
        ds_list_size(monster_list) - max_visible_monsters
    );
}

// 檢查surface是否丟失
if (active && !surface_exists(ui_surface)) {
    surface_needs_update = true;
}