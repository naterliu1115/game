if (instance_exists(obj_battle_manager) && obj_battle_manager.battle_state == target_state) {
    // 檢查是否應該顯示遮罩
    var should_show = true;
    
    // 如果標記需要檢查，則更新其他 UI 的可見性狀態
    if (should_check_visibility) {
        summon_ui_visible = (instance_exists(obj_summon_ui) && obj_summon_ui.visible);
        monster_ui_visible = (instance_exists(obj_monster_manager_ui) && obj_monster_manager_ui.visible);
        should_check_visibility = false; // 重置標記
    }
    
    // 如果任何主要 UI 可見，則不顯示遮罩
    if (summon_ui_visible || monster_ui_visible) {
        should_show = false;
    }
    
    // 只在沒有其他 UI 時顯示遮罩
    if (should_show) {
        // 繪製遮罩和倒數計時
        draw_set_alpha(0.7);
        draw_rectangle_color(0, 0, display_get_gui_width(), display_get_gui_height(),
                         c_black, c_black, c_black, c_black, false);
        draw_set_alpha(1.0);
        
        // 繪製文字和倒數計時
        draw_set_color(c_yellow);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        
        var pulse = 0.2 * sin(current_time / 250) + 1;
        
        draw_text_transformed(display_get_gui_width() / 2, display_get_gui_height() / 2 - 50, 
                     "準備階段", 2 * pulse, 2 * pulse, 0);
        draw_text_transformed(display_get_gui_width() / 2, display_get_gui_height() / 2, 
                     "按空格鍵召喚單位!", 1.5, 1.5, 0);
        
        var time_left = 10 - floor(obj_battle_manager.battle_timer / game_get_speed(gamespeed_fps));
        if (time_left > 0) {
            draw_text_transformed(display_get_gui_width() / 2, display_get_gui_height() / 2 + 50, 
                         "倒計時: " + string(time_left) + "秒", 1.5, 1.5, 0);
        } else {
            draw_text_transformed(display_get_gui_width() / 2, display_get_gui_height() / 2 + 50, 
                         "即將自動召喚...", 1.5, 1.5, 0);
        }
        
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(c_white);
    }
}