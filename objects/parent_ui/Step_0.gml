// parent_ui Step Event

// 添加檢查：在讀取 active 之前確認它是否存在
if (!variable_instance_exists(id, "active")) {
    show_debug_message("!!! 嚴重錯誤：實例 " + string(id) + " (" + object_get_name(object_index) + ") 的 Step 事件正在運行，但 'active' 變數不存在！");
    // 添加默認值
    active = false; // 確保 active 存在
    exit; // 添加 exit 確保不繼續執行
}

// 若是戰鬥UI則不自動關閉
if (object_index == obj_battle_ui) {
    exit;
}

// --- 通用輸入處理 (只在 active 時) ---
if (active) {
    var mouse_gui_x = device_mouse_x_to_gui(0);
    var mouse_gui_y = device_mouse_y_to_gui(0);

    // 檢查滑鼠左鍵點擊
    if (mouse_check_button_pressed(mb_left)) {
        var clicked_consumed_by_parent = false; // 標記點擊是否已被父類的關閉邏輯消耗

        // 確保 ui_x, ui_y, ui_width, ui_height 存在
        if (variable_instance_exists(id, "ui_x") && variable_instance_exists(id, "ui_y") &&
            variable_instance_exists(id, "ui_width") && variable_instance_exists(id, "ui_height")) {
            var rel_x = mouse_gui_x - ui_x;
            var rel_y = mouse_gui_y - ui_y;
            // 1. 檢查是否點擊了標準關閉按鈕 (使用相對座標)
            //    子類需要在 Create 中定義 close_button_rect = [rel_x1, rel_y1, rel_x2, rel_y2]
            if (variable_instance_exists(id, "close_button_rect")) {
                var rect = close_button_rect;
                if (point_in_rectangle(rel_x, rel_y, rect[0], rect[1], rect[2], rect[3])) {
                    if (instance_exists(obj_ui_manager)) {
                        show_debug_message("[DEBUG] parent_ui: 點擊內部關閉按鈕，呼叫 hide_ui，id=" + string(id) + ", 物件=" + object_get_name(object_index));
                        obj_ui_manager.hide_ui(id);
                        clicked_consumed_by_parent = true;
                    }
                }
            }
        }
        // 3. 如果點擊被任何一種父類關閉方式消耗，清除滑鼠按鍵
        if (clicked_consumed_by_parent) {
            mouse_clear(mb_left);
        }
        // 注意：子類如果需要處理 UI 內部的其他點擊（非關閉按鈕），
        // 應該在自己的 Step 事件中，在 event_inherited() 之後，
        // 再次檢查 mouse_check_button_pressed(mb_left)，
        // 如果點擊在內部元素上，處理完後也要呼叫 mouse_clear(mb_left)
        // 以防止事件繼續傳遞。
    }
}

// --- 修改：UI 不活躍時的處理 ---
if (!active) {
    if (visible && variable_instance_exists(id, "open_animation") && open_animation > 0) { 
        open_animation -= open_speed;
        if (open_animation <= 0) {
            open_animation = 0;
            visible = false; 
        }
        surface_needs_update = true; 
    }
    exit; // <<-- 新增：確保非活躍時事件退出
} 