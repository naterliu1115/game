// 安全釋放 surface
if (instance_exists(obj_ui_manager) && 
    variable_instance_exists(obj_ui_manager, "ui_surfaces") && 
    ds_exists(obj_ui_manager.ui_surfaces, ds_type_map)) {
    
    obj_ui_manager.free_ui_surface(id);
}

// 其他通用清理代碼... 