// obj_game_controller 的 Step_0.gml

// --- 先檢查需要無視輸入阻斷的全局快捷鍵 ---
if (keyboard_check_pressed(ord("O"))) {
    toggle_monster_manager_ui();
}

if (keyboard_check_pressed(ord("I"))) {
    toggle_inventory_ui();
}

// --- 然後再檢查是否需要阻斷後續的遊戲內輸入 ---
if (global.ui_input_block) exit; // 如果 UI 開啟，阻斷後續的遊戲控制（召喚、捕捉等）

// --- 只有在輸入未被阻斷時，才檢查其他按鍵 ---
// 更新UI冷卻
if (ui_cooldown > 0) ui_cooldown--;

// 直接在控制器中檢測按鍵
if (keyboard_check_pressed(ord("1"))) {
    toggle_summon_ui();
}

if (keyboard_check_pressed(ord("C"))) {
    toggle_capture_ui();
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