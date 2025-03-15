// 新建腳本: scr_event_system.gml
function broadcast_event(event_name, data = {}) {
    // 廣播事件給所有訂閱者
    with (obj_event_manager) {
        handle_event(event_name, data);
    }
}

// 會在obj_event_manager中實現handle_event函數