// obj_game_controller - CleanUp_0.gml
// 釋放全局資源
if (variable_global_exists("resource_map") && ds_exists(global.resource_map, ds_type_map)) {
    ds_map_destroy(global.resource_map);
}