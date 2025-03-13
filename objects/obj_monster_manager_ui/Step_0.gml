// obj_monster_manager_ui - Step_0.gml
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
    var target_width = display_get_gui_width() * 0.9;
    var target_height = display_get_gui_height() * 0.9;
    
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
    

    // 檢查是否點擊了關閉按鈕
    if (point_in_rectangle(
        mx, my,
        close_btn_x, close_btn_y,
        close_btn_x + close_btn_size, close_btn_y + close_btn_size
    )) {
        // 關閉UI
        hide();
        return;
    }
    
    // 檢查是否點擊了分頁標籤
    for (var i = 0; i < 4; i++) {
        var tab_x = ui_x + i * tab_width;
        var tab_y = ui_y + 41;
        
        if (point_in_rectangle(
            mx, my,
            tab_x, tab_y,
            tab_x + tab_width, tab_y + tab_height
        )) {
            switch_tab(i);
            return;
        }
    }
    
    // 根據當前標籤處理不同的點擊事件
    switch(current_tab) {
        case MONSTER_TABS.ALL:
        case MONSTER_TABS.TEAM:
            // 檢查是否點擊了搜索框
            var search_x = ui_x + 20;
            var search_y = ui_y + 85;
            var search_width = ui_width * 0.5 - 40;
            var search_height = 30;
            
            if (point_in_rectangle(
                mx, my,
                search_x, search_y,
                search_x + search_width, search_y + search_height
            )) {
                search_active = true;
                keyboard_string = search_text;
            } else {
                search_active = false;
            }
            
            // 檢查是否點擊了排序選項
            var sort_x = ui_x + 20;
            var sort_y = ui_y + 125;
            var sort_options = [
                {name: "等級", key: "level"},
                {name: "名稱", key: "name"},
                {name: "生命", key: "hp"},
                {name: "攻擊", key: "attack"}
            ];
            
            for (var i = 0; i < array_length(sort_options); i++) {
                var opt_x = sort_x + 50 + i * 100;
                var opt_y = sort_y;
                var opt_width = 70;
                var opt_height = 20;
                
                if (point_in_rectangle(
                    mx, my,
                    opt_x, opt_y,
                    opt_x + opt_width, opt_y + opt_height
                )) {
                    change_sort(sort_options[i].key);
                    return;
                }
            }
            
            // 檢查是否點擊了怪物卡片
            var list_count = ds_list_size(filtered_list);
            if (list_count > 0) {
                var start_index = clamp(scroll_offset, 0, max(0, list_count - max_visible_monsters));
                var end_index = min(start_index + max_visible_monsters, list_count);
                
                for (var i = start_index; i < end_index; i++) {
                    var card_y = ui_y + 160 + (i - start_index) * 110;
                    var card_width = ui_width * 0.55;
                    var card_height = 100;
                    
                    if (point_in_rectangle(
                        mx, my,
                        ui_x + 20, card_y,
                        ui_x + 20 + card_width, card_y + card_height
                    )) {
                        selected_monster = i;
                        details_needs_update = true;
                        return;
                    }
                }
            }
            
            // 檢查是否點擊了滾動箭頭
            if (list_count > max_visible_monsters) {
                // 上滾動箭頭
                if (scroll_offset > 0 && point_in_rectangle(
                    mx, my,
                    ui_x + ui_width * 0.58 - 10, ui_y + 145,
                    ui_x + ui_width * 0.6 + 10, ui_y + 165
                )) {
                    scroll_offset--;
                    return;
                }
                
                // 下滾動箭頭
                if (scroll_offset < list_count - max_visible_monsters && point_in_rectangle(
                    mx, my,
                    ui_x + ui_width * 0.58 - 10, ui_y + ui_height - 30,
                    ui_x + ui_width * 0.6 + 10, ui_y + ui_height - 10
                )) {
                    scroll_offset++;
                    return;
                }
                
                // 滾動條
                var scroll_height = ui_height - 200;
                var handle_height = (max_visible_monsters / list_count) * scroll_height;
                var handle_y = ui_y + 165 + (scroll_offset / (list_count - max_visible_monsters)) * (scroll_height - handle_height);
                
                if (point_in_rectangle(
                    mx, my,
                    ui_x + ui_width * 0.59 - 10, ui_y + 165,
                    ui_x + ui_width * 0.59 + 10, ui_y + ui_height - 35
                )) {
                    // 直接跳到點擊位置
                    var click_pos = (my - (ui_y + 165)) / scroll_height;
                    scroll_offset = round(click_pos * (list_count - max_visible_monsters));
                    scroll_offset = clamp(scroll_offset, 0, list_count - max_visible_monsters);
                    return;
                }
            }
            
            // 檢查是否點擊了詳細信息區域中的按鈕
            if (selected_monster >= 0 && selected_monster < ds_list_size(filtered_list)) {
                var monster_data = filtered_list[| selected_monster];
                
                // 使用按鈕（設為主力）
                var btn_x = details_x + details_width / 2 - 110;
                var btn_y = details_y + details_height - 80;
                var btn_width = 100;
                var btn_height = 30;
                
                if (point_in_rectangle(
                    mx, my,
                    btn_x, btn_y,
                    btn_x + btn_width, btn_y + btn_height
                )) {
                    // 設為主力的邏輯（根據遊戲設計實現）
                    // 例如，更新一個全局變量存儲主力怪物
                    // global.main_monster = monster_data;
                    if (instance_exists(obj_battle_ui)) {
                        obj_battle_ui.show_info(monster_data.name + " 已設為主力！");
                    }
                    return;
                }
                
                // 治療按鈕
                btn_x = details_x + details_width / 2 + 10;
                
                if (point_in_rectangle(
                    mx, my,
                    btn_x, btn_y,
                    btn_x + btn_width, btn_y + btn_height
                )) {
                    // 治療怪物（恢復HP）
                    monster_data.hp = monster_data.max_hp;
                    details_needs_update = true;
                    
                    if (instance_exists(obj_battle_ui)) {
                        obj_battle_ui.show_info(monster_data.name + " 已完全恢復！");
                    }
                    return;
                }
            }
            break;
    }
}

// 滾輪控制滾動
var wheel = mouse_wheel_down() - mouse_wheel_up();
if (wheel != 0 && (current_tab == MONSTER_TABS.ALL || current_tab == MONSTER_TABS.TEAM)) {
    var list_count = ds_list_size(filtered_list);
    if (list_count > max_visible_monsters) {
        scroll_offset = clamp(
            scroll_offset + wheel,
            0,
            list_count - max_visible_monsters
        );
    }
}

// 鍵盤控制
if (keyboard_check_pressed(vk_escape)) {
    // ESC關閉UI
    hide();
}

// 搜索框輸入處理
if (search_active) {
    var new_search = keyboard_string;
    
    if (keyboard_check_pressed(vk_enter)) {
        search_active = false;
    } else if (new_search != search_text) {
        search_text = new_search;
        apply_filters(); // 實時更新過濾結果
    }
}

// 方向鍵控制
if (current_tab == MONSTER_TABS.ALL || current_tab == MONSTER_TABS.TEAM) {
    if (keyboard_check_pressed(vk_up)) {
        // 向上選擇
        if (selected_monster > 0) {
            selected_monster--;
            details_needs_update = true;
            // 如果需要滾動顯示
            if (selected_monster < scroll_offset) {
                scroll_offset = selected_monster;
            }
        }
    }

    if (keyboard_check_pressed(vk_down)) {
        // 向下選擇
        if (selected_monster < ds_list_size(filtered_list) - 1) {
            selected_monster++;
            details_needs_update = true;
            // 如果需要滾動顯示
            if (selected_monster >= scroll_offset + max_visible_monsters) {
                scroll_offset = selected_monster - max_visible_monsters + 1;
            }
        }
    }
}

// 檢查surface是否丟失
if (active && !surface_exists(ui_surface)) {
    surface_needs_update = true;
}

if (active && !surface_exists(ui_details_surface)) {
    details_needs_update = true;
}