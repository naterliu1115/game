// obj_summon_ui - Step_0.gml

// 首先重置內部輸入標誌
process_internal_input_flag = false;

// --- 移除：錯誤的非活躍檢查 --- 
// if (!active) {
//    if (visible && open_animation <= 0) {
//        hide(); // <-- 錯誤調用
//    }
//    return;
// }
// --- 結束移除 ---

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

// --- 移除：被註解掉的舊鼠標按鈕檢查 --- 
/*
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
    
    // ... (點擊卡片和滾動箭頭的邏輯保留，但移到下面) ...
}
*/

// --- 移除：被註解掉的舊鍵盤控制 --- 
/*
if (keyboard_check_pressed(vk_escape)) {
    // ESC關閉UI
    hide();
}

// ... (Up/Down key logic remains, but moved below) ...

if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space)) {
    // 確認選擇
    if (selected_monster >= 0) {
        if (summon_selected_monster()) {
            hide();
        }
    }
}
*/

// --- 修改：只保留需要 process_internal_input_flag 的邏輯 ---
if (process_internal_input_flag) {
    show_debug_message("[Summon UI] Processing internal input (keyboard/wheel scroll).");

    // 1. 移除鼠標點擊處理 (已移到 handle_mouse_click)
    /*
    if (mouse_check_button_pressed(mb_left)) {
        // ... (移除卡片選擇和滾動箭頭點擊邏輯) ...
    } 
    */

    // 2. 保留鍵盤上下選擇
    if (keyboard_check_pressed(vk_up)) {
        if (selected_monster > 0) {
            selected_monster--;
            if (selected_monster < scroll_offset) {
                scroll_offset = selected_monster;
            }
            show_debug_message("[Summon UI] Selected up: index " + string(selected_monster));
            surface_needs_update = true;
        }
    }
    else if (keyboard_check_pressed(vk_down)) {
        if (selected_monster < ds_list_size(monster_list) - 1) {
            selected_monster++;
            if (selected_monster >= scroll_offset + max_visible_monsters) {
                scroll_offset = selected_monster - max_visible_monsters + 1;
            }
            show_debug_message("[Summon UI] Selected down: index " + string(selected_monster));
            surface_needs_update = true;
        }
    }

    // 3. 保留鼠標滾輪滾動
    var wheel = mouse_wheel_down() - mouse_wheel_up();
    if (wheel != 0 && ds_list_size(monster_list) > max_visible_monsters) {
        var old_offset = scroll_offset;
        scroll_offset = clamp(
            scroll_offset + wheel,
            0,
            ds_list_size(monster_list) - max_visible_monsters
        );
        if (scroll_offset != old_offset) {
            show_debug_message("[Summon UI] Scrolled with wheel: offset " + string(scroll_offset));
            surface_needs_update = true;
        }
    }

} // End if (process_internal_input_flag)

// 檢查surface是否丟失 (保留在外部)
if (active && !surface_exists(ui_surface)) {
    surface_needs_update = true;
}