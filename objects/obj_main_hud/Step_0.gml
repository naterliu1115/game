// obj_main_hud - Step_0.gml

// --- 檢查滑鼠點擊 ---
if (mouse_check_button_pressed(mb_left)) {
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    
    // 檢查是否點擊背包圖示
    if (point_in_rectangle(mx, my, 
        bag_bbox[0], bag_bbox[1], 
        bag_bbox[2], bag_bbox[3])) {
        
        if (instance_exists(obj_game_controller)) {
            with (obj_game_controller) {
                toggle_inventory_ui();
            }
        }
    // 新增：檢查是否點擊怪物管理按鈕
    } else if (point_in_rectangle(mx, my, 
               monster_button_bbox[0], monster_button_bbox[1],
               monster_button_bbox[2], monster_button_bbox[3])) {
        
        if (instance_exists(obj_game_controller)) {
            with (obj_game_controller) {
                // 假設控制器中有 toggle_monster_manager_ui 函數
                if (variable_instance_exists(id, "toggle_monster_manager_ui")) {
                    toggle_monster_manager_ui();
                } else {
                    show_debug_message("錯誤：obj_game_controller 中缺少 toggle_monster_manager_ui 函數！");
                }
            }
        }
    }
}

// --- 處理快捷欄選擇 ---
// 數字鍵 1-0 選擇快捷欄
for (var i = 0; i < hotbar_slots; i++) {
    var key = ord(string((i + 1) % 10)); // 0 鍵對應最後一格
    if (keyboard_check_pressed(key)) {
        selected_hotbar_slot = i;
        
        // TODO: 如果需要，可以在這裡處理選中物品的使用邏輯
    }
}

// 滑鼠滾輪切換快捷欄
var wheel = mouse_wheel_up() - mouse_wheel_down();
if (wheel != 0) {
    selected_hotbar_slot += wheel;
    // 確保選中格子在有效範圍內
    if (selected_hotbar_slot < 0) selected_hotbar_slot = hotbar_slots - 1;
    if (selected_hotbar_slot >= hotbar_slots) selected_hotbar_slot = 0;
} 