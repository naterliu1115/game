// =======================
// Draw GUI 事件代碼
// =======================

// obj_ui_manager - Draw_64.gml

// 繪製消息
var message_y = 100; // 從頂部開始
var queue_size = ds_queue_size(message_queue);

if (queue_size > 0) {
    var temp_queue = ds_queue_create();
    
    // 遍歷所有消息並繪製
    for (var i = 0; i < queue_size; i++) {
        var message = ds_queue_dequeue(message_queue);
        
        // 設置通用繪製屬性
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        
        // 為背景和邊框設置較低的透明度
        var background_alpha = 0; // 設定背景/邊框的基礎透明度 (可調整)
        draw_set_alpha(background_alpha * message.alpha); // 讓背景也跟著淡出
        
        // 繪製消息背景
        var text_width = string_width(message.text) + 40;
        var text_height = 30;
        var text_x = display_get_gui_width() / 2;
        
        draw_set_color(c_black);
        draw_rectangle(
            text_x - text_width/2, message_y - text_height/2,
            text_x + text_width/2, message_y + text_height/2,
            false
        );
        
        // 邊框
        draw_set_color(c_aqua);
        draw_rectangle(
            text_x - text_width/2, message_y - text_height/2,
            text_x + text_width/2, message_y + text_height/2,
            true
        );
        
        // 恢復文字應有的透明度 (用於淡出)
        draw_set_alpha(message.alpha);
        
        // 繪製文字
        draw_set_color(message.color);
        draw_text(text_x, message_y, message.text);
        
        // 移到下一條消息的位置
        message_y += message_spacing;
        
        // 將消息放回隊列
        ds_queue_enqueue(temp_queue, message);
    }
    
    // 還原繪製屬性
    draw_set_alpha(1.0);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    
    // 將消息放回原隊列
    while (!ds_queue_empty(temp_queue)) {
        ds_queue_enqueue(message_queue, ds_queue_dequeue(temp_queue));
    }
    
    // 清理臨時隊列
    ds_queue_destroy(temp_queue);
}