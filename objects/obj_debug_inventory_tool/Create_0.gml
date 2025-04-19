// obj_debug_inventory_tool - Create_0.gml

event_inherited(); // <<-- 新增：執行父類的 Create 事件

// is_visible = false; // <<-- 移除：由 parent_ui 初始化 visible 和 active

// 輸入框變數
input_item_id_str = "";
input_quantity_str = "";
input_item_type_str = "";

// 結果信息
result_message = "Ready.";
result_message_timer = 0; // 用於讓信息顯示一段時間

// 活動輸入框標識 (0: item_id, 1: quantity, 2: item_type, noone: 無)
active_input = noone;

// UI 佈局變數 (座標和尺寸)
ui_x = 20;
ui_y = 50;
ui_width = 400;
ui_height = 300;
ui_padding = 10;
input_height = 25;
button_width = 120;
button_height = 30;

// 計算元素位置
input_id_x = ui_x + ui_padding;
input_id_y = ui_y + ui_padding + 30; // 留出標題空間

input_qty_x = input_id_x;
input_qty_y = input_id_y + input_height + ui_padding;

input_type_x = input_id_x;
input_type_y = input_qty_y + input_height + ui_padding;

button_add_x = ui_x + ui_padding;
button_add_y = input_type_y + input_height + ui_padding * 2;

button_remove_x = button_add_x + button_width + ui_padding;
button_remove_y = button_add_y;

button_get_count_x = button_add_x;
button_get_count_y = button_add_y + button_height + ui_padding;

button_get_type_x = button_remove_x;
button_get_type_y = button_get_count_y;

result_x = ui_x + ui_padding;
result_y = button_get_count_y + button_height + ui_padding * 2;
result_max_width = ui_width - ui_padding * 2;

// 最大輸入長度
max_input_length = 30;
keyboard_string = ""; // 初始化 keyboard_string


show_debug_message("Debug Inventory Tool created.");

// --- 定義輔助繪製函數為方法 ---

// 繪製輸入框方法
custom_draw_input_box = function(x, y, width, height, text, label, is_active) {
    draw_set_color(c_dkgray);
    draw_rectangle(x, y, x + width, y + height, false);
    
    draw_set_color(c_white);
    // 假設 global.font_dialogue 已設置
    draw_set_font(global.font_dialogue);
    draw_set_halign(fa_right); // 標籤右對齊
    draw_set_valign(fa_middle);
    draw_text(x - ui_padding, y + height / 2, label + ":"); // 標籤放在左邊，有間距
    
    var display_text = text;
    if (is_active) {
        // 添加閃爍的光標
        display_text += (current_time div 500 mod 2 == 0) ? "|" : "";
        draw_set_color(c_lime); // 高亮活動邊框
        draw_rectangle(x, y, x + width, y + height, true);
    } else {
        draw_set_color(c_gray); // 非活動邊框
        draw_rectangle(x, y, x + width, y + height, true);
    }
    
    draw_set_color(c_white);
    draw_set_halign(fa_left);
    draw_set_valign(fa_middle);
    draw_text(x + 5, y + height / 2, display_text);
}

// 繪製按鈕方法
custom_draw_button = function(x, y, width, height, text) {
    // 這些變數需要在 Draw GUI 事件中計算並儲存為實例變數，或傳遞進來
    // 為了簡化，假設 Draw GUI 事件已經計算好 mouse_gui_x, mouse_gui_y
    // 並設置了 clicked_this_frame = mouse_check_button_pressed(mb_left);
    
    // 直接訪問在 Draw GUI 中計算的 mouse_gui_x/y
    // 注意：這裡假設 mouse_gui_x 和 mouse_gui_y 存在於實例範圍內
    // Draw GUI 事件需要在開頭計算它們：
    // self.mouse_gui_x = device_mouse_x_to_gui(0);
    // self.mouse_gui_y = device_mouse_y_to_gui(0);
    // self.clicked_this_frame = mouse_check_button_pressed(mb_left);

    var mouse_over = point_in_rectangle(self.mouse_gui_x, self.mouse_gui_y, x, y, x + width, y + height);
    var button_clicked_result = false;
    
    var base_color = c_gray;
    var text_color = c_white;
    
    if (mouse_over) {
        base_color = c_ltgray;
        text_color = c_black;
        // 使用 self.clicked_this_frame
        if (self.clicked_this_frame) {
            button_clicked_result = true;
            base_color = c_white;
        }
    }
    
    draw_set_color(base_color);
    draw_rectangle(x, y, x + width, y + height, false);
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(text_color);
    // 假設 global.font_dialogue 已設置
    draw_set_font(global.font_dialogue); 
    draw_text(x + width / 2, y + height / 2, text);
    
    return button_clicked_result;
} 