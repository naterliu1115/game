// obj_battle_ui - Destroy_0.gml

// 清理創建的 ds_list
if (ds_exists(reward_items_list, ds_type_list)) {
    ds_list_destroy(reward_items_list);
    show_debug_message("obj_battle_ui Destroyed: reward_items_list ds_list cleaned up."); // 可選的調試訊息
}

// 如果有繼承父類，可能需要調用 event_inherited()
event_inherited(); 