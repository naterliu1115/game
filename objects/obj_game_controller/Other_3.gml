// obj_game_controller - Game End 事件
// 僅處理全局資源，不干預物件自己的清理
if (variable_global_exists("resource_map") && ds_exists(global.resource_map, ds_type_map)) {
    ds_map_destroy(global.resource_map);
}

// 其他必要的全局資源清理...