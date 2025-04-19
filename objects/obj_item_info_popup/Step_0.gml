/// @description 處理彈窗關閉

// 繼承父類事件
event_inherited();

// 如果UI不活躍，直接返回
if (!active) {
    if (global.game_debug_mode) show_debug_message("物品資訊彈窗 - UI不活躍，跳過處理");
    exit;
}

// 獲取滑鼠在GUI中的位置
var mouse_gui_x = device_mouse_x_to_gui(0);
var mouse_gui_y = device_mouse_y_to_gui(0);

// 更新位置（確保與ui_x/ui_y同步）
x = ui_x;
y = ui_y;

// [彈窗Step] active=...、[彈窗Step] 觸發關閉判斷、[彈窗Step] close() 準備被呼叫 (非按鈕點擊)
// 物品資訊彈窗 - 檢測到ESC按下、物品資訊彈窗狀態 - active: ...、物品資訊彈窗 - 檢測到滑鼠點擊
// routine debug 訊息全部註解

// Step 事件開頭加強 log
/*if (global.game_debug_mode) {
    show_debug_message("[彈窗Step] active=" + string(active) + ", visible=" + string(visible));
}*/

// 檢查ESC鍵或滑鼠點擊範圍外以關閉
if (keyboard_check_pressed(vk_escape) || 
    (mouse_check_button_pressed(mb_left) && 
     !point_in_rectangle(mouse_gui_x, mouse_gui_y, x, y, x + width, y + height))) {
    if (global.game_debug_mode) {
        show_debug_message("[彈窗Step] 觸發關閉判斷");
        show_debug_message("  滑鼠座標: " + string(mouse_gui_x) + ", " + string(mouse_gui_y));
        show_debug_message("  彈窗範圍: x=" + string(x) + ", y=" + string(y) + ", w=" + string(width) + ", h=" + string(height));
        show_debug_message("  point_in_rectangle 結果: " + string(point_in_rectangle(mouse_gui_x, mouse_gui_y, x, y, x + width, y + height)));
        show_debug_message("  assign_button_x=" + string(assign_button_x) + ", assign_button_y=" + string(assign_button_y) + ", w=" + string(assign_button_width) + ", h=" + string(assign_button_height));
    }
    // 檢查點擊是否在按鈕上，如果是，則不關閉
    var clicked_on_button = false;
    if (point_in_rectangle(mouse_gui_x, mouse_gui_y, 
                         assign_button_x, assign_button_y, 
                         assign_button_x + assign_button_width, assign_button_y + assign_button_height)) {
        clicked_on_button = true;
    }
    if (global.game_debug_mode) {
        show_debug_message("  clicked_on_button: " + string(clicked_on_button));
    }
    if (!clicked_on_button) {
        if (global.game_debug_mode) {
            show_debug_message("[彈窗Step] close() 準備被呼叫 (非按鈕點擊)");
        }
        close();
        exit;
    }
}

// --- 修改：檢查指派/取消快捷按鈕點擊 ---
if (mouse_check_button_pressed(mb_left)) {
    // (注意：這裡依賴 Draw 事件計算的 assign_button_x/y，理想情況下應在 Create 或 Step 計算)
    if (point_in_rectangle(mouse_gui_x, mouse_gui_y, 
                         assign_button_x, assign_button_y, 
                         assign_button_x + assign_button_width, assign_button_y + assign_button_height)) {
        
        // 檢查物品是否可以指派 (例如，不是裝備)
        var can_assign = true;
        if (item_data != noone && item_data.Type == "EQUIPMENT") {
            can_assign = false;
        }
        
        if (can_assign && inventory_index != -1) { // 移除 instance_exists 檢查，下面會獲取實例

            // <-- 新增：獲取 Item Manager 實例 -->
            var item_manager_inst = instance_find(obj_item_manager, 0);
            if (item_manager_inst == noone) {
                 show_debug_message("錯誤：點擊按鈕時找不到 obj_item_manager 實例！");
                 close();
                 exit;
            }
            // <-- 結束獲取實例 -->

            if (global.game_debug_mode) {
                 show_debug_message("點擊指派/取消按鈕，物品索引：" + string(inventory_index) + "，當前狀態：" + (is_assigned_to_hotbar ? "已指派" : "未指派"));
            }
            
            // <-- 修改：根據狀態呼叫不同函數 (使用實例 ID) -->
            var success = false;
            if (is_assigned_to_hotbar) {
                // 如果已指派，則取消指派
                if (variable_instance_exists(item_manager_inst, "unassign_item_from_hotbar")) { // 檢查函數是否存在
                    success = item_manager_inst.unassign_item_from_hotbar(inventory_index);
                    if (success && global.game_debug_mode) show_debug_message("取消指派成功");
                } else {
                     show_debug_message("錯誤：實例 " + string(item_manager_inst) + " 上找不到 unassign_item_from_hotbar 函數！");
                }
            } else {
                // 如果未指派，則指派 (到第一個空位)
                if (variable_instance_exists(item_manager_inst, "assign_item_to_hotbar")) { // 檢查函數是否存在
                    success = item_manager_inst.assign_item_to_hotbar(inventory_index);
                    if (success && global.game_debug_mode) show_debug_message("指派成功");
                 } else {
                      show_debug_message("錯誤：實例 " + string(item_manager_inst) + " 上找不到 assign_item_to_hotbar 函數！");
                 }
            }
            // <-- 結束修改 -->
            
            // 點擊後關閉彈窗
            close();
            exit; 
        } else {
            if (global.game_debug_mode) {
                if (!can_assign) show_debug_message("此物品類型不可指派快捷");
                if (inventory_index == -1) show_debug_message("錯誤：物品索引無效");
                 // 不再檢查管理器是否存在，因為上面已經獲取了
            }
        }
    }
} 