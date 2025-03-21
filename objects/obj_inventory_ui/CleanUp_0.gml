// obj_inventory_ui - CleanUp_0.gml

// 釋放表面資源
if (surface_exists(ui_surface)) {
    surface_free(ui_surface);
}

// 取消訂閱事件
if (instance_exists(obj_event_manager)) {
    with (obj_event_manager) {
        unsubscribe_from_event("item_added", other.id);
        unsubscribe_from_event("item_removed", other.id);
        unsubscribe_from_event("item_used", other.id);
    }
}

// 從UI管理器中移除
if (instance_exists(obj_ui_manager)) {
    with (obj_ui_manager) {
        remove_ui(other.id);
    }
}

show_debug_message("道具UI資源已清理"); 