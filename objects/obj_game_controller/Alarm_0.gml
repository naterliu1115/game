// obj_game_controller - Alarm_0.gml
// 延遲廣播 managers_initialized 事件，確保其他實例已完成創建和訂閱

show_debug_message("[GameController Alarm 0] 觸發，準備廣播 managers_initialized 事件...");

if (instance_exists(obj_event_manager)) {
    with (obj_event_manager) {
        broadcast_event("managers_initialized");
    }
    show_debug_message("已廣播 managers_initialized 事件 (來自 Alarm 0)");
} else {
    show_debug_message("[GameController Alarm 0] 錯誤：廣播時事件管理器不存在！");
} 