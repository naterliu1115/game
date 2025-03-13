// obj_monster_manager_ui 的 Draw_64.gml
if (!active) return;

// 更新開啟動畫
if (open_animation < 1) {
    open_animation += open_speed;
    if (open_animation > 1) open_animation = 1;
    
    // 重新計算UI位置和尺寸（動畫效果）
    var target_width = display_get_gui_width() * 0.9;
    var target_height = display_get_gui_height() * 0.9;
    
    ui_width = target_width * open_animation;
    ui_height = target_height * open_animation;
    ui_x = (display_get_gui_width() - ui_width) / 2;
    ui_y = (display_get_gui_height() - ui_height) / 2;
    
    // 更新詳情區域位置
    details_x = ui_x + ui_width * 0.6;
    details_y = ui_y + 60;
    details_width = ui_width * 0.38;
    details_height = ui_height - 70;
    
    surface_needs_update = true;
    details_needs_update = true;
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
    draw_text(ui_width / 2, 20, "怪物管理");
    draw_set_halign(fa_left);
    
    // 分頁標籤背景
    draw_set_color(make_color_rgb(0, 50, 80));
    draw_rectangle(1, 41, ui_width - 1, 60, false);
    
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

// 繪製分頁標籤
var tab_names = ["所有怪物", "戰鬥隊伍", "數據分析", "圖鑑信息"];
for (var i = 0; i < 4; i++) {
    var tab_x = ui_x + i * tab_width;
    var tab_y = ui_y + 41;
    var is_active = (i == current_tab);
    
    // 標籤背景
    if (is_active) {
        draw_set_color(make_color_rgb(0, 120, 180));
    } else {
        draw_set_color(make_color_rgb(0, 70, 100));
    }
    
    draw_rectangle(tab_x, tab_y, tab_x + tab_width, tab_y + tab_height, false);
    
    // 標籤文字
    draw_set_color(is_active ? c_white : c_ltgray);
    draw_set_halign(fa_center);
    draw_text(tab_x + tab_width / 2, tab_y + tab_height / 2, tab_names[i]);
}

// 重置文本對齊
draw_set_halign(fa_left);

// 繪製關閉按鈕
draw_set_color(c_red);
draw_rectangle(close_btn_x, close_btn_y, close_btn_x + close_btn_size, close_btn_y + close_btn_size, false);
draw_set_color(c_white);
draw_set_halign(fa_center);
draw_set_valign(fa_middle);
draw_text(close_btn_x + close_btn_size / 2, close_btn_y + close_btn_size / 2, "X");
draw_set_halign(fa_left);
draw_set_valign(fa_top);

// 處理不同分頁的內容
switch(current_tab) {
    case MONSTER_TABS.ALL:
    case MONSTER_TABS.TEAM:
        // 繪製搜索框
        var search_x = ui_x + 20;
        var search_y = ui_y + 85;
        var search_width = ui_width * 0.5 - 40;
        var search_height = 30;
        
        draw_set_color(search_active ? c_white : c_dkgray);
        draw_rectangle(search_x, search_y, search_x + search_width, search_y + search_height, false);
        draw_set_color(c_black);
        
        // 搜索提示文字
        if (search_text == "") {
            draw_set_color(c_gray);
            draw_text(search_x + 10, search_y + 7, "搜索怪物...");
        } else {
            draw_text(search_x + 10, search_y + 7, search_text);
        }
        
        // 繪製排序選項
        var sort_x = ui_x + 20;
        var sort_y = ui_y + 125;
        
        draw_set_color(c_white);
        draw_text(sort_x, sort_y, "排序:");
        
        // 排序按鈕
        var sort_options = [
            {name: "等級", key: "level"},
            {name: "名稱", key: "name"},
            {name: "生命", key: "hp"},
            {name: "攻擊", key: "attack"}
        ];
        
        for (var i = 0; i < array_length(sort_options); i++) {
            var opt_x = sort_x + 50 + i * 100;
            var opt_y = sort_y;
            var is_active = (sort_by == sort_options[i].key);
            
            draw_set_color(is_active ? c_yellow : c_ltgray);
            draw_text(opt_x, opt_y, sort_options[i].name);
            
            // 顯示升序/降序
            if (is_active) {
                draw_text(opt_x + 40, opt_y, sort_ascending ? "↑" : "↓");
            }
        }
        
        // 繪製怪物列表
        var list_count = ds_list_size(filtered_list);
        if (list_count > 0) {
            // 可見怪物範圍（支持滾動）
            var start_index = clamp(scroll_offset, 0, max(0, list_count - max_visible_monsters));
            var end_index = min(start_index + max_visible_monsters, list_count);
            
            // 繪製可見的怪物卡片
            for (var i = start_index; i < end_index; i++) {
                var monster_data = filtered_list[| i];
                var card_y = ui_y + 160 + (i - start_index) * 110;
                
                draw_monster_card(ui_x + 20, card_y, monster_data, i == selected_monster);
            }
            
            // 如果有超過最大可見數量的怪物，繪製滾動指示器
            if (list_count > max_visible_monsters) {
                // 上滾動箭頭
                if (start_index > 0) {
                    draw_set_color(c_aqua);
                    draw_triangle(
                        ui_x + ui_width * 0.58, ui_y + 160,
                        ui_x + ui_width * 0.59, ui_y + 145,
                        ui_x + ui_width * 0.6, ui_y + 160,
                        false
                    );
                }
                
                // 下滾動箭頭
                if (end_index < list_count) {
                    draw_set_color(c_aqua);
                    draw_triangle(
                        ui_x + ui_width * 0.58, ui_y + ui_height - 30,
                        ui_x + ui_width * 0.59, ui_y + ui_height - 15,
                        ui_x + ui_width * 0.6, ui_y + ui_height - 30,
                        false
                    );
                }
                
                // 滾動條背景
                draw_set_color(c_dkgray);
                draw_rectangle(
                    ui_x + ui_width * 0.59 - 5, ui_y + 165,
                    ui_x + ui_width * 0.59 + 5, ui_y + ui_height - 35,
                    false
                );
                
                // 滾動條把手
                var scroll_height = ui_height - 200;
                var handle_height = (max_visible_monsters / list_count) * scroll_height;
                var handle_y = ui_y + 165 + (start_index / (list_count - max_visible_monsters)) * (scroll_height - handle_height);
                
                draw_set_color(c_gray);
                draw_rectangle(
                    ui_x + ui_width * 0.59 - 5, handle_y,
                    ui_x + ui_width * 0.59 + 5, handle_y + handle_height,
                    false
                );
            }
            
            // 繪製選中怪物的詳細信息
            if (selected_monster >= 0 && selected_monster < list_count) {
                var selected_data = filtered_list[| selected_monster];
                draw_monster_details(selected_data);
            }
        } else {
            // 無可用怪物時顯示提示
            draw_set_color(c_white);
            draw_set_halign(fa_center);
            draw_text(
                ui_x + ui_width * 0.3,
                ui_y + ui_height / 2,
                "沒有符合條件的怪物！"
            );
            draw_set_halign(fa_left);
        }
        break;
        
    case MONSTER_TABS.STATS:
        // 繪製數據分析內容
        draw_set_color(c_white);
        draw_text(ui_x + 20, ui_y + 80, "怪物數據分析");
        
        // 繪製數據統計
        var total_monsters = ds_list_size(monster_list);
        var avg_level = 0;
        var avg_hp = 0;
        var avg_attack = 0;
        var avg_defense = 0;
        var avg_speed = 0;
        
        for (var i = 0; i < total_monsters; i++) {
            var m = monster_list[| i];
            avg_level += m.level;
            avg_hp += m.hp;
            avg_attack += m.attack;
            avg_defense += m.defense;
            avg_speed += m.spd;
        }
        
        if (total_monsters > 0) {
            avg_level /= total_monsters;
            avg_hp /= total_monsters;
            avg_attack /= total_monsters;
            avg_defense /= total_monsters;
            avg_speed /= total_monsters;
        }
        
        var stats_y = ui_y + 120;
        draw_text(ui_x + 20, stats_y, "怪物總數: " + string(total_monsters));
        stats_y += 30;
        draw_text(ui_x + 20, stats_y, "平均等級: " + string_format(avg_level, 1, 1));
        stats_y += 30;
        draw_text(ui_x + 20, stats_y, "平均生命: " + string_format(avg_hp, 1, 1));
        stats_y += 30;
        draw_text(ui_x + 20, stats_y, "平均攻擊: " + string_format(avg_attack, 1, 1));
        stats_y += 30;
        draw_text(ui_x + 20, stats_y, "平均防禦: " + string_format(avg_defense, 1, 1));
        stats_y += 30;
        draw_text(ui_x + 20, stats_y, "平均速度: " + string_format(avg_speed, 1, 1));
        
        // 繪製簡單的數據圖表（條形圖）
        var graph_x = ui_x + ui_width * 0.4;
        var graph_y = ui_y + 120;
        var graph_width = ui_width * 0.5;
        var graph_height = 300;
        var bar_width = 60;
        var max_stat = max(avg_hp / 10, avg_attack, avg_defense, avg_speed);
        
        // 圖表背景
        draw_set_color(c_dkgray);
        draw_rectangle(graph_x, graph_y, graph_x + graph_width, graph_y + graph_height, false);
        
        // 繪製條形
        var bar_x = graph_x + 50;
        
        // HP條
        var bar_height = (avg_hp / 10 / max_stat) * (graph_height - 40);
        draw_set_color(c_red);
        draw_rectangle(bar_x, graph_y + graph_height - bar_height, bar_x + bar_width, graph_y + graph_height, false);
        draw_set_color(c_white);
        draw_set_halign(fa_center);
        draw_text(bar_x + bar_width / 2, graph_y + graph_height + 10, "HP/10");
        draw_text(bar_x + bar_width / 2, graph_y + graph_height - bar_height - 15, string_format(avg_hp, 1, 0));
        
        // 攻擊條
        bar_x += 100;
        bar_height = (avg_attack / max_stat) * (graph_height - 40);
        draw_set_color(c_orange);
        draw_rectangle(bar_x, graph_y + graph_height - bar_height, bar_x + bar_width, graph_y + graph_height, false);
        draw_set_color(c_white);
        draw_text(bar_x + bar_width / 2, graph_y + graph_height + 10, "攻擊");
        draw_text(bar_x + bar_width / 2, graph_y + graph_height - bar_height - 15, string_format(avg_attack, 1, 0));
        
        // 防禦條
        bar_x += 100;
        bar_height = (avg_defense / max_stat) * (graph_height - 40);
        draw_set_color(c_blue);
        draw_rectangle(bar_x, graph_y + graph_height - bar_height, bar_x + bar_width, graph_y + graph_height, false);
        draw_set_color(c_white);
        draw_text(bar_x + bar_width / 2, graph_y + graph_height + 10, "防禦");
        draw_text(bar_x + bar_width / 2, graph_y + graph_height - bar_height - 15, string_format(avg_defense, 1, 0));
        
        // 速度條
        bar_x += 100;
        bar_height = (avg_speed / max_stat) * (graph_height - 40);
        draw_set_color(c_lime);
        draw_rectangle(bar_x, graph_y + graph_height - bar_height, bar_x + bar_width, graph_y + graph_height, false);
        draw_set_color(c_white);
        draw_text(bar_x + bar_width / 2, graph_y + graph_height + 10, "速度");
        draw_text(bar_x + bar_width / 2, graph_y + graph_height - bar_height - 15, string_format(avg_speed, 1, 0));
        
        draw_set_halign(fa_left);
        break;
        
    case MONSTER_TABS.INFO:
        // 繪製圖鑑信息
        draw_set_color(c_white);
        draw_text(ui_x + 20, ui_y + 80, "怪物圖鑑");
        
        draw_text(ui_x + 20, ui_y + 120, "尚未實現。敬請期待更多內容！");
        break;
}

// 重置繪圖設置
draw_set_color(c_white);
draw_set_alpha(1.0);