/// @description 清理資源

// 執行清理函數
if (variable_instance_exists(id, "cleanup") && is_method(cleanup)) {
    cleanup();
}

// 釋放技能資料庫
if (ds_exists(skill_database, ds_type_map)) {
    ds_map_destroy(skill_database);
}

show_debug_message("技能管理器已清理資源"); 