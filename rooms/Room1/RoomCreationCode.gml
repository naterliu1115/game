/// @description 確保關鍵管理器存在

// 確保技能管理器存在
if (!instance_exists(obj_skill_manager)) {
    show_debug_message("自動創建技能管理器");
    instance_create_layer(0, 0, "Controllers", obj_skill_manager);
} 