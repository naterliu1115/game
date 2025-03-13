// obj_summon_ui 的 Draw_64.gml
if (!active) return;

// 更新開啟動畫
if (open_animation < 1) {
    open_animation += open_speed;
    if (open_animation > 1) open_animation = 1;
    
    // 重新計算UI位置和尺寸（動畫效果）
    var target_width = display_get_gui_width() * 0.8;
    var target_height = display_get_gui_height() * 0.7;
    
    ui_width = target_width * open_animation;
    ui_height = target_height * open_animation;
    ui_x = (display_get_gui_width() - ui_width) / 2;
    ui_y = (display_get_gui_height() - ui_height) / 2;
    
    surface_needs_update = true;
}

// 如果動畫未完成，或者需要更新表面
if (!surface_exists(ui_surface) || surface_needs_update) {
    if (surface_exists(ui_surface)) {
        surface_free(ui_surface);
    }
    
    ui_surface = surface_create(ui_width, ui_height);
    surface_set_target(ui_surface);
    draw_clear_alpha(c_black, 0);
    
    // 繪製UI背景
    draw_set_alpha(0.9);
    draw_rectangle_color(0, 0, ui_width, ui_height, 
                      c_navy, c_navy, c_black, c_black, false);
    draw_set_alpha(1.0);
    
    // 繪製裝飾性邊框和標題欄
    draw_set_color(c_aqua);
    draw_rectangle(0, 0, ui_width, ui_height, true);
    
    // 標題欄背景
    draw_set_color(make_color_rgb(0, 80, 120));
    draw_rectangle(1, 1, ui_width - 1, 40, false);
    
    // 標題文字
    draw_set_color(c_white);
    draw_set_font(-1);
    draw_set_halign(fa_center);
    draw_text(ui_width / 2, 20, "選擇要召喚的怪物");
    draw_set_halign(fa_left);
    
    // 繪製底部按鈕區域
    draw_set_color(make_color_rgb(0, 60, 100));
    draw_rectangle(1, ui_height - 70, ui_width - 1, ui_height - 1, false);
    
    // 完成UI基本框架後重置目標
    surface_reset_target();
    surface_needs_update = false;
}

// 繪製半透明背景遮罩
draw_set_color(c_black);
draw_set_alpha(0.7);
draw_rectangle(0, 0, display_get_gui_width(), display_get_gui_height(), false);
draw_set_alpha(1.0);

// 繪製UI基本框架
draw_surface(ui_surface, ui_x, ui_y);

// 繪製怪物列表（這部分每幀都需要更新）
var list_count = ds_list_size(monster_list);
if (list_count > 0) {
    // 可見怪物範圍（支持滾動）
    var start_index = clamp(scroll_offset, 0, max(0, list_count - max_visible_monsters));
    var end_index = min(start_index + max_visible_monsters, list_count);
    
    // 繪製可見的怪物卡片
    for (var i = start_index; i < end_index; i++) {
        var monster_data = monster_list[| i];
        var card_y = ui_y + 50 + (i - start_index) * 130;
        
        draw_monster_card(ui_x + 20, card_y, monster_data, i == selected_monster);
    }
    
    // 如果有超過最大可見數量的怪物，繪製滾動指示器
    if (list_count > max_visible_monsters) {
        // 上滾動箭頭
        if (start_index > 0) {
            draw_set_color(c_aqua);
            draw_triangle(
                ui_x + ui_width - 30, ui_y + 60,
                ui_x + ui_width - 20, ui_y + 45,
                ui_x + ui_width - 10, ui_y + 60,
                false
            );
        }
        
        // 下滾動箭頭
        if (end_index < list_count) {
            draw_set_color(c_aqua);
            draw_triangle(
                ui_x + ui_width - 30, ui_y + ui_height - 90,
                ui_x + ui_width - 20, ui_y + ui_height - 75,
                ui_x + ui_width - 10, ui_y + ui_height - 90,
                false
            );
        }
        
        // 滾動條背景
        draw_set_color(c_dkgray);
        draw_rectangle(
            ui_x + ui_width - 25, ui_y + 65,
            ui_x + ui_width - 15, ui_y + ui_height - 95,
            false
        );
        
        // 滾動條把手
        var scroll_height = ui_height - 160;
        var handle_height = (max_visible_monsters / list_count) * scroll_height;
        var handle_y = ui_y + 65 + (start_index / (list_count - max_visible_monsters)) * (scroll_height - handle_height);
        
        draw_set_color(c_gray);
        draw_rectangle(
            ui_x + ui_width - 25, handle_y,
            ui_x + ui_width - 15, handle_y + handle_height,
            false
        );
    }
    
    // 繪製詳細資訊（如果有選中的怪物）
    if (selected_monster >= 0 && selected_monster < list_count) {
        var selected_data = monster_list[| selected_monster];
        
        // 底部資訊欄
        draw_set_color(c_white);
        
        // 技能列表標題
        draw_text(ui_x + 20, ui_y + ui_height - 65, "可用技能:");
        
        // 技能列表
        if (variable_struct_exists(selected_data, "abilities") && is_array(selected_data.abilities)) {
            var abilities = selected_data.abilities;
            var abilities_text = "";
            
            for (var j = 0; j < array_length(abilities); j++) {
                if (j > 0) abilities_text += ", ";
                abilities_text += abilities[j];
            }
            
            draw_text(ui_x + 100, ui_y + ui_height - 65, abilities_text);
        } else {
            draw_text(ui_x + 100, ui_y + ui_height - 65, "無特殊技能");
        }
    }
    
    // 繪製召喚按鈕
    var btn_enabled = (selected_monster >= 0);
    var summon_btn_color = btn_enabled ? c_green : c_dkgray;
    
    draw_set_color(summon_btn_color);
    draw_rectangle(
        summon_btn_x, summon_btn_y,
        summon_btn_x + summon_btn_width, summon_btn_y + summon_btn_height,
        false
    );
    
    // 按鈕文字
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(
        summon_btn_x + summon_btn_width / 2,
        summon_btn_y + summon_btn_height / 2,
        "召喚"
    );
    
    // 繪製取消按鈕
    draw_set_color(c_maroon);
    draw_rectangle(
        cancel_btn_x, cancel_btn_y,
        cancel_btn_x + cancel_btn_width, cancel_btn_y + cancel_btn_height,
        false
    );
    
    // 按鈕文字
    draw_set_color(c_white);
    draw_text(
        cancel_btn_x + cancel_btn_width / 2,
        cancel_btn_y + cancel_btn_height / 2,
        "取消"
    );
    
    // 重置文本對齊
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
} else {
    // 無可用怪物時顯示提示
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_text(
        ui_x + ui_width / 2,
        ui_y + ui_height / 2,
        "沒有可用的怪物！"
    );
    draw_set_halign(fa_left);
    
    // 只繪製取消按鈕
    draw_set_color(c_maroon);
    draw_rectangle(
        ui_x + ui_width / 2 - 60, ui_y + ui_height - 60,
        ui_x + ui_width / 2 + 60, ui_y + ui_height - 20,
        false
    );
    
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(
        ui_x + ui_width / 2,
        ui_y + ui_height - 40,
        "關閉"
    );
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// 重置繪圖顏色和混合模式
draw_set_color(c_white);
draw_set_alpha(1.0);