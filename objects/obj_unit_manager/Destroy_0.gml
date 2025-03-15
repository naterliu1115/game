// obj_unit_manager - Destroy_0.gml

// 清理數據結構
ds_list_destroy(player_units);
ds_list_destroy(enemy_units);
ds_map_destroy(unit_pools);

// 取消事件訂閱
if (instance_exists(obj_event_manager)) {
    with (obj_event_manager) {
        unsubscribe_from_all_events(other.id);
    }
}