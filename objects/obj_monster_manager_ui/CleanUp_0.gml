

// 確保在清理時允許玩家移動
allow_player_movement = true;

// 清理表面資源
if (surface_exists(ui_surface)) {
    surface_free(ui_surface);
}

if (surface_exists(ui_details_surface)) {
    surface_free(ui_details_surface);
}

show_debug_message("怪物管理UI已清理，允許玩家移動");

// 其他本地資源清理...