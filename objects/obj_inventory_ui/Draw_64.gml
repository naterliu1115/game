// 如果UI不可見，直接返回
if (!visible) exit;

// 確保表面存在
if (!surface_exists(ui_surface)) {
    ui_surface = surface_create(ui_width, ui_height);
    surface_needs_update = true;
}

// 更新表面內容
if (surface_needs_update) {
    surface_set_target(ui_surface);
    draw_clear_alpha(c_black, 0);
    
    // 繪製主背景和標題
    draw_ui_panel(0, 0, ui_width, ui_height, "道具欄", true);
    
    // 繪製關閉按鈕
    var close_btn_size = 30;
    var close_btn_x = ui_width - close_btn_size - 10;
    var close_btn_y = 10;
    draw_ui_button(
        close_btn_x, close_btn_y,
        close_btn_size, close_btn_size,
        "X",
        false
    );
    
    // 繪製分類按鈕
    var button_width = 100;
    var button_height = 30;
    var button_spacing = 10;
    var total_buttons_width = array_length(category_buttons) * (button_width + button_spacing) - button_spacing;
    var start_x = (ui_width - total_buttons_width) / 2;
    var buttons_y = 60;
    
    /*
    // 顯示調試信息
    if (global.game_debug_mode) {
        show_debug_message("Draw - 按鈕區域：");
        show_debug_message("起始X: " + string(start_x));
        show_debug_message("按鈕Y: " + string(buttons_y));
        show_debug_message("總寬度: " + string(total_buttons_width));
    }
    */
    
    for (var i = 0; i < array_length(category_buttons); i++) {
        var btn_x = start_x + i * (button_width + button_spacing);
        var is_selected = (current_category == category_buttons[i].category);
        
        /*
        // 顯示調試信息
        if (global.game_debug_mode) {
            show_debug_message("Draw - 按鈕 " + string(i) + " (" + category_buttons[i].name + "):");
            show_debug_message("X: " + string(btn_x));
            show_debug_message("Y: " + string(buttons_y));
        }
        */
        
        draw_ui_button(
            btn_x, buttons_y,
            button_width, button_height,
            category_buttons[i].name,
            is_selected
        );
    }
    
    // 設置物品槽區域
    var slots_area_y = buttons_y + button_height + 10;
    var slots_area_height = ui_height - slots_area_y - 10;
    
    // 繪製物品槽區域背景
    draw_ui_panel(
        10, slots_area_y,
        ui_width - 10, ui_height - 10,
        "", false
    );
    
    // 繪製物品槽
    var inventory_y = slots_area_y - scroll_offset;
    
    if (ds_exists(global.player_inventory, ds_type_list)) {
        var items_drawn = 0;
        var inventory_size = ds_list_size(global.player_inventory);
        
        for (var i = 0; i < inventory_size; i++) {
            var item = global.player_inventory[| i];
            if (item == undefined) continue;
            
            var item_data = obj_item_manager.get_item(item.item_id);
            if (item_data == undefined) continue;
            
            // 檢查是否匹配當前分類
            if (item_data.Category != current_category) continue;
            
            var slot_x = 20 + (items_drawn mod slots_per_row) * (slot_size + slot_padding);
            var slot_y = inventory_y + floor(items_drawn / slots_per_row) * (slot_size + slot_padding);
            
            // 只繪製可見的槽位
            if (slot_y + slot_size >= slots_area_y && slot_y <= ui_height - 10) {
                // 繪製物品槽
                draw_ui_item_slot(
                    slot_x, slot_y,
                    slot_size, slot_size,
                    item_data,
                    item.quantity,
                    i == selected_item
                );
            }
            
            items_drawn++;
        }
    }
    
    surface_reset_target();
    surface_needs_update = false;
}

// 繪製表面
draw_surface(ui_surface, ui_x, ui_y);

// 繪製拖動的物品
if (drag_item != noone) {
    var item = global.player_inventory[| drag_item];
    if (item != undefined) {
        var item_data = obj_item_manager.get_item(item.item_id);
        if (item_data != undefined) {
            draw_ui_dragged_item(
                mouse_x - drag_offset_x,
                mouse_y - drag_offset_y,
                slot_size,
                item_data
            );
        }
    }
} 