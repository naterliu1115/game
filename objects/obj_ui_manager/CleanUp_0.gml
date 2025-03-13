// obj_ui_manager - Cleanup_0.gml
// 安全地釋放資源
try {
    // 釋放UI層級列表
    if (variable_instance_exists(id, "ui_layers") && ds_exists(ui_layers, ds_type_map)) {
        var layer_names = ["main", "overlay", "hud", "popup"];
        for (var i = 0; i < array_length(layer_names); i++) {
            var layer_name = layer_names[i];
            if (ds_map_exists(ui_layers, layer_name)) {
                var ui_list = ui_layers[? layer_name];
                if (ds_exists(ui_list, ds_type_list)) {
                    ds_list_destroy(ui_list);
                }
            }
        }
        ds_map_destroy(ui_layers);
    }
    
    // 釋放其他資源
    if (variable_instance_exists(id, "layer_depths") && ds_exists(layer_depths, ds_type_map)) {
        ds_map_destroy(layer_depths);
    }
    
    if (variable_instance_exists(id, "active_ui") && ds_exists(active_ui, ds_type_map)) {
        ds_map_destroy(active_ui);
    }
    
    if (variable_instance_exists(id, "ui_instances") && ds_exists(ui_instances, ds_type_map)) {
        ds_map_destroy(ui_instances);
    }
} catch (e) {
    // 在調試模式下記錄錯誤
    show_debug_message("UI管理器清理時發生錯誤: " + string(e));
}