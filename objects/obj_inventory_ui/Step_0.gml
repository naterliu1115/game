// obj_inventory_ui - Step_0.gml

// 如果UI不活躍，直接返回
if (!active) {
    exit;
}

// 獲取滑鼠在GUI中的位置
var mouse_gui_x = device_mouse_x_to_gui(0);
var mouse_gui_y = device_mouse_y_to_gui(0);

// 計算滑鼠相對於UI表面的位置
var mouse_rel_x = mouse_gui_x - ui_x;
var mouse_rel_y = mouse_gui_y - ui_y;

// 調試輸出使用 show_debug_message 而非直接繪製
/*if (global.game_debug_mode) {
    show_debug_message("道具UI狀態：活躍");
    show_debug_message("滑鼠GUI位置：" + string(mouse_gui_x) + ", " + string(mouse_gui_y));
    show_debug_message("滑鼠相對位置：" + string(mouse_rel_x) + ", " + string(mouse_rel_y));
}*/

// 檢查ESC鍵關閉
if (keyboard_check_pressed(vk_escape)) {
    if (global.game_debug_mode) show_debug_message("道具UI - ESC按下，關閉UI");
    hide();
    exit;
}

// 方向鍵切換分類
var category_changed = false;
var current_index = -1;

// 找到當前分類的索引
for (var i = 0; i < array_length(category_buttons); i++) {
    if (category_buttons[i].category == current_category) {
        current_index = i;
        break;
    }
}

// 左右方向鍵切換分類
if (keyboard_check_pressed(vk_left)) {
    if (current_index > 0) {
        current_index--;
        category_changed = true;
        if (global.game_debug_mode) {
            show_debug_message("道具UI - 向左切換分類: " + category_buttons[current_index].name);
        }
    } else {
        if (global.game_debug_mode) show_debug_message("已經是第一個分類");
    }
} else if (keyboard_check_pressed(vk_right)) {
    if (current_index < array_length(category_buttons) - 1) {
        current_index++;
        category_changed = true;
        if (global.game_debug_mode) {
            show_debug_message("道具UI - 向右切換分類: " + category_buttons[current_index].name);
        }
    } else {
        if (global.game_debug_mode) show_debug_message("已經是最後一個分類");
    }
}

// 如果分類改變，更新UI
if (category_changed && current_index >= 0 && current_index < array_length(category_buttons)) {
    current_category = category_buttons[current_index].category;
    surface_needs_update = true;
    selected_item = noone;
    scroll_offset = 0;
    update_max_scroll();
    if (global.game_debug_mode) show_debug_message("分類已更新為: " + category_buttons[current_index].name);
}

// 檢查關閉按鈕點擊 - 使用相對座標
var close_btn_size = 30;
var close_btn_x = ui_width - close_btn_size - 10; // 相對於表面的座標
var close_btn_y = 10; // 相對於表面的座標

// 檢查分類按鈕 - 使用相對座標
var button_width = 100;
var button_height = 30;
var button_spacing = 10;
var total_buttons_width = array_length(category_buttons) * (button_width + button_spacing) - button_spacing;
var start_x = (ui_width - total_buttons_width) / 2; // 相對於表面的座標
var buttons_y = 60; // 相對於表面的座標

/*if (global.game_debug_mode) {
    show_debug_message("關閉按鈕位置（相對）：" + string(close_btn_x) + ", " + string(close_btn_y));
    show_debug_message("分類按鈕起始位置（相對）：" + string(start_x) + ", " + string(buttons_y));
}*/

if (mouse_check_button_pressed(mb_left)) {
    if (global.game_debug_mode) show_debug_message("檢測到點擊");
    
    // 檢查關閉按鈕 - 使用相對座標
    if (point_in_rectangle(
        mouse_rel_x, mouse_rel_y,
        close_btn_x, close_btn_y,
        close_btn_x + close_btn_size, close_btn_y + close_btn_size
    )) {
        if (global.game_debug_mode) show_debug_message("道具UI - 點擊關閉按鈕");
        hide();
        exit;
    }
    
    // 檢查分類按鈕點擊 - 使用相對座標
    var button_clicked = false;
    for (var i = 0; i < array_length(category_buttons); i++) {
        var btn_x = start_x + i * (button_width + button_spacing);
        
        if (global.game_debug_mode) {
            show_debug_message("按鈕 " + string(i) + ": " + category_buttons[i].name + " 位置（相對）: " + string(btn_x) + ", " + string(buttons_y));
        }
        
        if (point_in_rectangle(
            mouse_rel_x, mouse_rel_y,
            btn_x, buttons_y,
            btn_x + button_width, buttons_y + button_height
        )) {
            if (global.game_debug_mode) {
                show_debug_message("檢測到按鈕點擊: " + category_buttons[i].name);
                show_debug_message("當前分類: " + string(current_category));
                show_debug_message("點擊位置（相對）: " + string(mouse_rel_x) + ", " + string(mouse_rel_y));
            }
            
            if (current_category != category_buttons[i].category) {
                current_category = category_buttons[i].category;
                surface_needs_update = true;
                selected_item = noone;
                scroll_offset = 0;
                update_max_scroll();
                if (global.game_debug_mode) {
                    show_debug_message("分類已切換到: " + category_buttons[i].name);
                }
            }
            button_clicked = true;
            break;
        }
    }

    // 只有在沒有點擊按鈕時才檢查物品槽
    if (!button_clicked) {
        // 處理物品槽選擇
        var slot_index = get_slot_at_position(mouse_gui_x, mouse_gui_y);
        if (slot_index != noone) {
            if (global.game_debug_mode) {
                var item = global.player_inventory[| slot_index];
                if (item != undefined) {
                    var item_data = obj_item_manager.get_item(item.id);
                    if (item_data != undefined) {
                        show_debug_message("道具UI - 選擇物品: " + item_data.Name);
                    }
                }
            }
            selected_item = slot_index;
            surface_needs_update = true;
        }
    }
}

// 右鍵使用物品
if (mouse_check_button_pressed(mb_right)) {
    var slot_index = get_slot_at_position(mouse_gui_x, mouse_gui_y);
    if (slot_index != noone) {
        if (global.game_debug_mode) {
            var item = global.player_inventory[| slot_index];
            if (item != undefined) {
                var item_data = obj_item_manager.get_item(item.id);
                if (item_data != undefined) {
                    show_debug_message("道具UI - 嘗試使用物品: " + item_data.Name);
                }
            }
        }
        selected_item = slot_index;
        use_selected_item();
    }
}

// 處理滾動
if (mouse_wheel_up()) {
    var old_offset = scroll_offset;
    scroll_offset = max(0, scroll_offset - (slot_size + slot_padding));
    if (scroll_offset != old_offset && global.game_debug_mode) {
        show_debug_message("道具UI - 向上滾動: " + string(scroll_offset));
    }
    surface_needs_update = true;
} else if (mouse_wheel_down()) {
    var old_offset = scroll_offset;
    scroll_offset = min(max_scroll, scroll_offset + (slot_size + slot_padding));
    if (scroll_offset != old_offset && global.game_debug_mode) {
        show_debug_message("道具UI - 向下滾動: " + string(scroll_offset));
    }
    surface_needs_update = true;
}