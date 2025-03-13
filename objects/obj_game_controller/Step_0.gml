// obj_game_controller 的 Step_0.gml



// 更新UI冷卻
if (ui_cooldown > 0) ui_cooldown--;

// 直接在控制器中檢測按鍵
if (keyboard_check_pressed(ord("1"))) {
    toggle_summon_ui();
}

if (keyboard_check_pressed(ord("2"))) {
    toggle_capture_ui();
}

if (keyboard_check_pressed(ord("3"))) {
    toggle_monster_manager_ui();
}


// 檢查UI管理器是否存在，如果不存在則創建
if (!instance_exists(obj_ui_manager)) {
    instance_create_layer(0, 0, "Instances", obj_ui_manager);
}

// 其他全局更新邏輯
// 例如更新全局計時器、檢查遊戲狀態等
if (variable_global_exists("global_game_timer")) {
    global.global_game_timer++;
}