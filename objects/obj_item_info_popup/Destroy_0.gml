/// @description 清理資源

// 從UI管理器中移除
if (instance_exists(obj_ui_manager)) {
    obj_ui_manager.hide_ui(id);
}

// 清理數據結構
ds_map_destroy(rarity_colors);
ds_map_destroy(effect_descriptions); 