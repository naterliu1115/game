// obj_debug_inventory_tool - Step_0.gml

event_inherited(); // <<-- 新增：執行父類的 Step 事件

// --- 切換可見性 (使用 UI 管理器) ---
if (keyboard_check_pressed(vk_f1)) {
    if (instance_exists(obj_ui_manager)) {
        if (!active) { // 如果當前非活動，則顯示
            obj_ui_manager.show_ui(id, "main"); // 改為 main 層級，與主 UI 一致
        } else { // 如果當前活動，則隱藏
            obj_ui_manager.hide_ui(id);
        }
        keyboard_string = ""; // 無論顯示或隱藏，清空緩衝
        active_input = noone; // 無論顯示或隱藏，取消輸入框焦點
    }
}

// 如果 UI 非活動 (由 parent_ui 控制)，則不處理後續邏輯
if (!active) {
    exit;
}

// --- 輸入框激活處理 ---
var mouse_gui_x = device_mouse_x_to_gui(0);
var mouse_gui_y = device_mouse_y_to_gui(0);

if (mouse_check_button_pressed(mb_left)) {
    var clicked_on_input = false;
    // 檢查是否點擊了 Item ID 輸入框
    if (point_in_rectangle(mouse_gui_x, mouse_gui_y, input_id_x, input_id_y, input_id_x + ui_width - ui_padding * 2, input_id_y + input_height)) {
        if (active_input != 0) {
            active_input = 0;
            keyboard_string = input_item_id_str; // 加載當前內容到緩衝
        }
        clicked_on_input = true;
    } 
    // 檢查是否點擊了 Quantity 輸入框
    else if (point_in_rectangle(mouse_gui_x, mouse_gui_y, input_qty_x, input_qty_y, input_qty_x + ui_width - ui_padding * 2, input_qty_y + input_height)) {
        if (active_input != 1) {
            active_input = 1;
            keyboard_string = input_quantity_str;
        }
        clicked_on_input = true;
    } 
    // 檢查是否點擊了 Item Type 輸入框
    else if (point_in_rectangle(mouse_gui_x, mouse_gui_y, input_type_x, input_type_y, input_type_x + ui_width - ui_padding * 2, input_type_y + input_height)) {
        if (active_input != 2) {
            active_input = 2;
            keyboard_string = input_item_type_str;
        }
        clicked_on_input = true;
    } 
    
    // 新增：如果點擊在輸入框內部，則消耗點擊事件，防止觸發 parent_ui 的外部點擊關閉
    if (clicked_on_input) {
        mouse_clear(mb_left);
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
        // Escape 由 obj_ui_manager 處理關閉，這裡只取消輸入焦點
        active_input = noone;
        keyboard_string = ""; // 清空緩衝
        keyboard_clear(vk_enter); // 消耗 Enter
        // 不 clear Escape，讓管理器處理
    }
}

// --- 結果信息計時器 ---
if (result_message_timer > 0) {
    result_message_timer--;
    if (result_message_timer <= 0) {
        result_message = "Ready."; // 超時後恢復默認信息
    }
} 