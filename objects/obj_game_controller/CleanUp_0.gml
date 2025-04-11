// obj_game_controller - CleanUp_0.gml
// 釋放全局資源
if (ds_exists(global.resource_map, ds_type_map)) {
    ds_map_destroy(global.resource_map);
}

/// @description 清理遊戲控制器資源，包括粒子系統

show_debug_message("===== obj_game_controller 清理開始 =====");

// --- 銷毀粒子類型 ---
if (variable_global_exists("pt_level_up_sparkle")) {
    // 檢查 global.pt_level_up_sparkle 是否已定義且粒子類型存在
    if (!is_undefined(global.pt_level_up_sparkle) && part_type_exists(global.pt_level_up_sparkle)) {
        show_debug_message("  銷毀粒子類型: pt_level_up_sparkle");
        part_type_destroy(global.pt_level_up_sparkle);
    }
    global.pt_level_up_sparkle = undefined; // 清除全局變數引用
}
// --- 在此處添加銷毀其他粒子類型的代碼 ---

// --- 銷毀粒子系統 ---
if (variable_global_exists("particle_system")) {
    // 檢查 global.particle_system 是否已定義且粒子系統存在
    if (!is_undefined(global.particle_system) && part_system_exists(global.particle_system)) {
        show_debug_message("  銷毀全局粒子系統");
        part_system_destroy(global.particle_system);
    }
    global.particle_system = undefined; // 清除全局變數引用
}

// --- 其他清理代碼... ---
// 例如：
// if (variable_global_exists("level_exp_map") && !is_undefined(global.level_exp_map) && ds_exists(global.level_exp_map, ds_type_map)) { 
//     show_debug_message("  銷毀等級經驗表");
//     ds_map_destroy(global.level_exp_map); 
//     global.level_exp_map = undefined; 
// }
// save_game();
// ...

show_debug_message("===== obj_game_controller 清理完成 =====");
