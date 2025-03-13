// obj_game_controller - CleanUp_0.gml
// 釋放全局資源
if (ds_exists(global.resource_map, ds_type_map)) {
    ds_map_destroy(global.resource_map);
}

// 如果UI管理器存在，執行清理
if (instance_exists(obj_ui_manager)) {
    with (obj_ui_manager) {
        cleanup();
    }
}