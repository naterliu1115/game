// obj_battle_manager - Destroy_0.gml
// 清理邏輯已移至 Clean Up 事件。

// 釋放資源
if (ds_exists(battle_log, ds_type_list)) {
    ds_list_destroy(battle_log);
}

// 取消事件訂閱
if (instance_exists(obj_event_manager)) {
    with (obj_event_manager) {
        unsubscribe_from_all_events(other.id);
    }
}