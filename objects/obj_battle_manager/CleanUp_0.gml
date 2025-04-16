// obj_battle_manager - CleanUp_0.gml

show_debug_message("===== 清理戰鬥管理器 (Clean Up Event) =====");

// 確保取消訂閱事件
if (instance_exists(obj_event_manager)) {
    with (obj_event_manager) {
        // 直接調用，無需檢查是否存在，因為它是 obj_event_manager 的一部分
        unsubscribe_from_all_events(other.id);
        show_debug_message("指示 obj_event_manager 取消訂閱 ID: " + string(other.id)); // 添加日誌確認
    }
} else {
    show_debug_message("警告：事件管理器實例不存在於 Clean Up 事件中。");
}

// 清理 ds_list 數據結構
if (ds_exists(player_units, ds_type_list)) ds_list_destroy(player_units);
if (ds_exists(enemy_units, ds_type_list)) ds_list_destroy(enemy_units);
if (ds_exists(battle_log, ds_type_list)) ds_list_destroy(battle_log);
if (ds_exists(defeated_enemies_exp, ds_type_list)) ds_list_destroy(defeated_enemies_exp);
if (ds_exists(last_enemy_flying_items, ds_type_list)) ds_list_destroy(last_enemy_flying_items);

show_debug_message("戰鬥管理器資源已清理 (Clean Up Event)"); 