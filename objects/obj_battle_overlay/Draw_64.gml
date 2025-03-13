// obj_battle_overlay - Draw_64.gml
if (instance_exists(obj_battle_manager) && obj_battle_manager.battle_state == BATTLE_STATE.PREPARING) {
    // 檢查其他UI是否開啟
    var summon_ui_visible = (instance_exists(obj_summon_ui) && obj_summon_ui.visible);
    var monster_ui_visible = (instance_exists(obj_monster_manager_ui) && obj_monster_manager_ui.visible);
    var any_ui_visible = summon_ui_visible || monster_ui_visible;
    
    // 只在沒有其他UI時繪製半透明背景
    if (!any_ui_visible) {
        draw_set_alpha(0.7);
        draw_rectangle_color(0, 0, display_get_gui_width(), display_get_gui_height(),
                         c_black, c_black, c_black, c_black, false);
        draw_set_alpha(1.0);
    }
    
    // 無論其他UI是否開啟，都顯示準備階段文字
    // 但調整位置，避免與其他UI重疊
    var text_y_offset = any_ui_visible ? -200 : 0; // 如果有UI開啟，則將文字上移
    
    draw_set_color(c_yellow);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    
    var pulse = 0.2 * sin(current_time / 250) + 1;
    
    // 繪製準備階段文字
    draw_text_transformed(display_get_gui_width() / 2, 
                 display_get_gui_height() / 2 - 50 + text_y_offset, 
                 "準備階段", 2 * pulse, 2 * pulse, 0);
    draw_text_transformed(display_get_gui_width() / 2, 
                 display_get_gui_height() / 2 + text_y_offset, 
                 "按空格鍵召喚單位!", 1.5, 1.5, 0);
    
    // 顯示倒數計時
    var time_left = 10 - floor(obj_battle_manager.battle_timer / game_get_speed(gamespeed_fps));
    if (time_left > 0) {
        draw_text_transformed(display_get_gui_width() / 2, 
                     display_get_gui_height() / 2 + 50 + text_y_offset, 
                     "倒計時: " + string(time_left) + "秒", 1.5, 1.5, 0);
    } else {
        draw_text_transformed(display_get_gui_width() / 2, 
                     display_get_gui_height() / 2 + 50 + text_y_offset, 
                     "即將自動召喚...", 1.5, 1.5, 0);
    }
    
    // 重置繪圖設置
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}