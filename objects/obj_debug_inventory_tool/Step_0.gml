// obj_debug_inventory_tool - Step_0.gml

// --- 切換可見性 ---
if (keyboard_check_pressed(vk_f1)) {
    is_visible = !is_visible;
    active_input = noone; // 關閉時取消活動輸入框
    keyboard_string = ""; // 清空鍵盤緩衝
    if (is_visible) {
        show_debug_message("Debug Inventory Tool: Shown");
    } else {
        show_debug_message("Debug Inventory Tool: Hidden");
    }
}

// 如果不可見，則不處理後續邏輯
if (!is_visible) {
    exit;
}

// --- 輸入框激活處理 ---
var mouse_gui_x = device_mouse_x_to_gui(0);
var mouse_gui_y = device_mouse_y_to_gui(0);

if (mouse_check_button_pressed(mb_left)) {
    // 檢查是否點擊了 Item ID 輸入框
    if (point_in_rectangle(mouse_gui_x, mouse_gui_y, input_id_x, input_id_y, input_id_x + ui_width - ui_padding * 2, input_id_y + input_height)) {
        if (active_input != 0) {
            active_input = 0;
            keyboard_string = input_item_id_str; // 加載當前內容到緩衝
        }
    } 
    // 檢查是否點擊了 Quantity 輸入框
    else if (point_in_rectangle(mouse_gui_x, mouse_gui_y, input_qty_x, input_qty_y, input_qty_x + ui_width - ui_padding * 2, input_qty_y + input_height)) {
        if (active_input != 1) {
            active_input = 1;
            keyboard_string = input_quantity_str;
        }
    } 
    // 檢查是否點擊了 Item Type 輸入框
    else if (point_in_rectangle(mouse_gui_x, mouse_gui_y, input_type_x, input_type_y, input_type_x + ui_width - ui_padding * 2, input_type_y + input_height)) {
        if (active_input != 2) {
            active_input = 2;
            keyboard_string = input_item_type_str;
        }
    } 
    // 如果點擊了其他地方（非按鈕），則取消激活
    else if (
        !point_in_rectangle(mouse_gui_x, mouse_gui_y, button_add_x, button_add_y, button_add_x + button_width, button_add_y + button_height) &&
        !point_in_rectangle(mouse_gui_x, mouse_gui_y, button_remove_x, button_remove_y, button_remove_x + button_width, button_remove_y + button_height) &&
        !point_in_rectangle(mouse_gui_x, mouse_gui_y, button_get_count_x, button_get_count_y, button_get_count_x + button_width, button_get_count_y + button_height) &&
        !point_in_rectangle(mouse_gui_x, mouse_gui_y, button_get_type_x, button_get_type_y, button_get_type_x + button_width, button_get_type_y + button_height)
    ) {
        active_input = noone;
        keyboard_string = "";
    }
}

// --- 輸入處理 ---
if (active_input != noone) {
    // 限制鍵盤字符串長度
    if (string_length(keyboard_string) > max_input_length) {
        keyboard_string = string_copy(keyboard_string, 1, max_input_length);
    }

    // 更新對應的輸入框變數
    switch (active_input) {
        case 0: input_item_id_str = keyboard_string; break;
        case 1: input_quantity_str = keyboard_string; break;
        case 2: input_item_type_str = keyboard_string; break;
    }
    
    // 按下 Enter 或 Escape 取消激活
    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_escape)) {
        active_input = noone;
        keyboard_string = ""; // 清空緩衝
    }
}

// --- 結果信息計時器 ---
if (result_message_timer > 0) {
    result_message_timer--;
    if (result_message_timer <= 0) {
        result_message = "Ready."; // 超時後恢復默認信息
    }
} 