// obj_debug_inventory_tool - Draw_64.gml (Draw GUI)

// 如果不可見，則不繪製
if (!is_visible) exit;

// --- 計算當前幀的滑鼠狀態 (供 draw_button 方法使用) ---
self.mouse_gui_x = device_mouse_x_to_gui(0);
self.mouse_gui_y = device_mouse_y_to_gui(0);
self.clicked_this_frame = mouse_check_button_pressed(mb_left);

// --- 繪製背景 ---
draw_set_color(c_black);
draw_set_alpha(0.8);
draw_rectangle(ui_x, ui_y, ui_x + ui_width, ui_y + ui_height, false);
draw_set_alpha(1.0);

// --- 繪製標題 ---
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_font(global.font_dialogue); // 使用全局字體
draw_set_color(c_white);
draw_text(ui_x + ui_padding, ui_y + ui_padding, "庫存調試工具 (F1 開關)");

// --- 繪製輸入框 (使用在 Create 事件中定義的方法) ---
var input_box_width = ui_width - ui_padding * 10 - 100; // 減去標籤寬度
custom_draw_input_box(input_id_x + 100, input_id_y, input_box_width, input_height, input_item_id_str, "Item ID", active_input == 0);
custom_draw_input_box(input_qty_x + 100, input_qty_y, input_box_width, input_height, input_quantity_str, "Quantity", active_input == 1);
custom_draw_input_box(input_type_x + 100, input_type_y, input_box_width, input_height, input_item_type_str, "Item Type", active_input == 2);

// --- 繪製按鈕並處理點擊 (使用在 Create 事件中定義的方法) ---

// 添加按鈕
if (custom_draw_button(button_add_x, button_add_y, button_width, button_height, "添加道具")) {
    if (input_item_id_str == "") { // 檢查 Item ID 是否為空
        result_message = "錯誤：請輸入道具 ID.";
        result_message_timer = room_speed * 3;
    } else {
        var item_id = real(input_item_id_str); // 嘗試轉換為數字
        var quantity = 1; // 預設為 1
        if (input_quantity_str != "") { // 如果輸入不是空的
            quantity = real(input_quantity_str); // 才進行轉換
        } else {
            quantity = 1; // 確保空字串時為 1
        }
        
        // 檢查 item_id 是否有效，quantity 是否為正數
        if (is_real(item_id) && item_id > 0 && is_real(quantity) && quantity > 0) { 
            if (instance_exists(obj_item_manager)) {
                obj_item_manager.add_item_to_inventory(item_id, quantity);
                result_message = "添加成功: ID=" + string(item_id) + ", 數量=" + string(quantity);
            } else {
                result_message = "錯誤: obj_item_manager 不存在!";
            }
        } else {
            // 區分錯誤原因
            if (!is_real(item_id) || item_id <= 0) {
                 result_message = "錯誤: 請輸入有效的 Item ID (正數).";
            } else {
                 result_message = "錯誤: 請輸入有效的 Quantity (正數)，或留空表示 1.";
            }
        }
        result_message_timer = room_speed * 3; // 顯示3秒
    }
}

// 移除按鈕
if (custom_draw_button(button_remove_x, button_remove_y, button_width, button_height, "移除道具")) {
    if (input_item_id_str == "") { // 檢查 Item ID 是否為空
        result_message = "錯誤：請輸入道具 ID.";
        result_message_timer = room_speed * 3;
    } else {
        var item_id = real(input_item_id_str);
        var quantity = 1; // 預設為 1
        if (input_quantity_str != "") { // 如果輸入不是空的
            quantity = real(input_quantity_str); // 才進行轉換
        } else {
            quantity = 1; // 確保空字串時為 1
        }
        
        // 檢查 item_id 是否有效，quantity 是否為正數
        if (is_real(item_id) && item_id > 0 && is_real(quantity) && quantity > 0) { 
            if (instance_exists(obj_item_manager)) {
                var success = obj_item_manager.remove_item_from_inventory(item_id, quantity);
                if (success) {
                    result_message = "移除成功: ID=" + string(item_id) + ", 數量=" + string(quantity);
                } else {
                    result_message = "移除失敗: 可能是數量不足.";
                }
            } else {
                result_message = "錯誤: obj_item_manager 不存在!";
            }
        } else {
            // 區分錯誤原因
            if (!is_real(item_id) || item_id <= 0) {
                 result_message = "錯誤: 請輸入有效的 Item ID (正數).";
            } else {
                 result_message = "錯誤: 請輸入有效的 Quantity (正數)，或留空表示 1.";
            }
        }
        result_message_timer = room_speed * 3;
    }
}

// 查詢數量按鈕
if (custom_draw_button(button_get_count_x, button_get_count_y, button_width, button_height, "查詢數量")) {
    if (input_item_id_str == "") { // 檢查 Item ID 是否為空
        result_message = "錯誤：請輸入道具 ID.";
        result_message_timer = room_speed * 3;
    } else {
        var item_id = real(input_item_id_str);
        if (is_real(item_id) && item_id > 0) {
            if (instance_exists(obj_item_manager)) {
                var count = obj_item_manager.get_item_count_in_inventory(item_id);
                result_message = "道具 ID=" + string(item_id) + " 的數量: " + string(count);
            } else {
                result_message = "錯誤: obj_item_manager 不存在!";
            }
        } else {
            result_message = "錯誤: 請輸入有效的 Item ID (正數).";
        }
        result_message_timer = room_speed * 5; // 顯示長一點
    }
}

// 查詢類型按鈕 (功能已修改：根據 ID 查詢類型)
if (custom_draw_button(button_get_type_x, button_get_type_y, button_width, button_height, "查詢類型")) {
    if (input_item_id_str == "") { // 檢查 Item ID 是否為空
        result_message = "錯誤：請輸入道具 ID.";
        result_message_timer = room_speed * 3;
    } else {
        var item_id = real(input_item_id_str);
        if (is_real(item_id) && item_id > 0) {
            if (instance_exists(obj_item_manager)) {
                var item_type_result = obj_item_manager.get_item_type_by_id(item_id);
                
                if (item_type_result != undefined) {
                    result_message = "道具 ID " + string(item_id) + " 的類型是: " + string(item_type_result);
                } else {
                    result_message = "錯誤：在物品資料庫中找不到 ID " + string(item_id) + ".";
                }
            } else {
                result_message = "錯誤: obj_item_manager 不存在!";
            }
        } else {
            result_message = "錯誤: 請輸入有效的 Item ID (正數).";
        }
        result_message_timer = room_speed * 5; // 顯示長一點
    }
}

// --- 繪製結果區域 ---
draw_set_color(c_gray);
draw_rectangle(result_x, result_y, result_x + result_max_width, result_y + ui_height - (result_y - ui_y) - ui_padding, true); // 繪製邊框

draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
// 使用 draw_text_ext 自動換行
draw_text_ext(result_x + 5, result_y + 5, result_message, 18, result_max_width - 10);

// 重置繪圖設置
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_color(c_white);
draw_set_alpha(1.0); 