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

if (global.game_debug_mode) {
    if (keyboard_check_pressed(vk_escape)) {
        show_debug_message("物品資訊彈窗 - 檢測到ESC按下");
        show_debug_message("物品資訊彈窗狀態 - active: " + string(active) + ", visible: " + string(visible));
    }
    
    if (mouse_check_button_pressed(mb_left)) {
        show_debug_message("物品資訊彈窗 - 檢測到滑鼠點擊");
        show_debug_message("滑鼠位置: " + string(mouse_gui_x) + ", " + string(mouse_gui_y));
        show_debug_message("彈窗範圍: " + string(x) + ", " + string(y) + " 到 " + 
                         string(x + width) + ", " + string(y + height));
        show_debug_message("點擊是否在範圍外: " + 
            string(!point_in_rectangle(mouse_gui_x, mouse_gui_y, x, y, x + width, y + height)));
    }
}

// 檢查ESC鍵或滑鼠點擊範圍外以關閉
if (keyboard_check_pressed(vk_escape) || 
    (mouse_check_button_pressed(mb_left) && 
     !point_in_rectangle(mouse_gui_x, mouse_gui_y, x, y, x + width, y + height))) {
    
    // 檢查點擊是否在按鈕上，如果是，則不關閉
    var clicked_on_button = false;
    // 檢查 assign_button_x, assign_button_y 是否已在 Draw 事件中計算
    // 注意：Step 事件在 Draw 事件之前執行，這裡的 assign_button_x/y 可能是上一幀的值
    // 更好的做法是在 Create 中初始化按鈕位置，或傳遞 Draw 計算的值
    // 暫時使用當前值，但在複雜情況下可能有問題
    if (point_in_rectangle(mouse_gui_x, mouse_gui_y, 
                         assign_button_x, assign_button_y, 
                         assign_button_x + assign_button_width, assign_button_y + assign_button_height)) {
        clicked_on_button = true;
    }
    
    if (!clicked_on_button) {
        if (global.game_debug_mode) {
            show_debug_message("物品資訊彈窗 - 準備關閉 (非按鈕點擊)");
            show_debug_message("關閉觸發條件: " + 
                (keyboard_check_pressed(vk_escape) ? "ESC按下" : "點擊範圍外"));
        }
        close();
        exit;
    }
}

// --- 新增：檢查指派快捷按鈕點擊 ---
if (mouse_check_button_pressed(mb_left)) {
    // 再次檢查點擊位置是否在按鈕內
    if (point_in_rectangle(mouse_gui_x, mouse_gui_y, 
                         assign_button_x, assign_button_y, 
                         assign_button_x + assign_button_width, assign_button_y + assign_button_height)) {
        
        // 檢查物品是否可以指派 (例如，不是裝備)
        var can_assign = true;
        if (item_data != noone && item_data.Type == "EQUIPMENT") {
            can_assign = false;
        }
        
        if (can_assign && inventory_index != -1 && instance_exists(obj_game_controller)) {
            if (global.game_debug_mode) {
                show_debug_message("點擊指派快捷按鈕，物品索引：" + string(inventory_index));
            }
            // 呼叫控制器的指派函數
            with (obj_game_controller) {
                assign_item_to_hotbar(other.inventory_index);
            }
            // 點擊後關閉彈窗
            close();
            exit; 
        } else {
            if (global.game_debug_mode) {
                if (!can_assign) show_debug_message("此物品類型不可指派快捷");
                if (inventory_index == -1) show_debug_message("錯誤：物品索引無效");
                if (!instance_exists(obj_game_controller)) show_debug_message("錯誤：找不到遊戲控制器");
            }
        }
    }
} 