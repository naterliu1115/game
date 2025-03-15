// =======================
// Step 事件代碼
// =======================

// obj_ui_manager - Step_0.gml

// 定期檢查surface狀態
surface_check_counter++;
if (surface_check_counter >= 30) { // 每30幀檢查一次
    check_lost_surfaces();
    surface_check_counter = 0;
}

// 更新消息計時器
var queue_size = ds_queue_size(message_queue);
if (queue_size > 0) {
    var temp_queue = ds_queue_create();
    
    // 遍歷並更新所有消息
    for (var i = 0; i < queue_size; i++) {
        var message = ds_queue_dequeue(message_queue);
        
        // 更新計時器
        message.timer++;
        
        // 計算淡出效果
        if (message.timer >= message.duration * 0.7) {
            var remaining = message.duration - message.timer;
            var fade_duration = message.duration * 0.3;
            message.alpha = remaining / fade_duration;
        }
        
        // 如果消息還未過期，放回隊列
        if (message.timer < message.duration) {
            ds_queue_enqueue(temp_queue, message);
        }
    }
    
    // 將更新後的消息放回原隊列
    while (!ds_queue_empty(temp_queue)) {
        ds_queue_enqueue(message_queue, ds_queue_dequeue(temp_queue));
    }
    
    // 清理臨時隊列
    ds_queue_destroy(temp_queue);
}