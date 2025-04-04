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

// 檢查ESC鍵或滑鼠點擊
if (keyboard_check_pressed(vk_escape) || 
    (mouse_check_button_pressed(mb_left) && 
     !point_in_rectangle(mouse_gui_x, mouse_gui_y, x, y, x + width, y + height))) {
    
    if (global.game_debug_mode) {
        show_debug_message("物品資訊彈窗 - 準備關閉");
        show_debug_message("關閉觸發條件: " + 
            (keyboard_check_pressed(vk_escape) ? "ESC按下" : "點擊範圍外"));
    }
    
    close();
    
    if (global.game_debug_mode) {
        show_debug_message("物品資訊彈窗 - 關閉完成");
    }
    exit;
} 