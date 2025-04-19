// obj_battle_result_popup - Create_0.gml
event_inherited(); // 繼承 parent_ui 的 Create 事件

// 繪圖相關變數 (可以根據需要調整)
popup_width = 600;
popup_height = 300;
popup_x = display_get_gui_width() / 2 - popup_width / 2;
popup_y = (display_get_gui_height() - popup_height) / 2;
victory_pulse = 0; // 呼吸動畫計時器

/// Create Event
current_alpha = 0;
current_scale = 0.9; // 初始縮小，配合彈入動畫使用


// --- 新增：滑入+淡入動畫變數 ---
start_y = -popup_height; // 從螢幕頂部外開始
target_y = popup_y;     // 使用計算好的最終位置
current_y = start_y;      // 初始化當前 Y
current_alpha = 0;        // 初始化透明度
open_speed = 0.15;        // 動畫速度 (可以調整)
// --- 結束新增 ---

// 關閉輸入處理函數
handle_close_input = function() {
    show_debug_message("[Battle Result Popup] handle_close_input called.");

    // 廣播關閉事件
    if (instance_exists(obj_event_manager)) {
        broadcast_event("battle_result_closed", {}); 
        show_debug_message("[Battle Result Popup] Broadcasted battle_result_closed event.");
    } else {
        show_debug_message("錯誤：[Battle Result Popup] 無法廣播 battle_result_closed，事件管理器不存在。");
    }

    // 透過 UI 管理器隱藏自己
    if (instance_exists(obj_ui_manager)) {
         with(obj_ui_manager) {
             hide_ui(other.id); // other.id 指向 obj_battle_result_popup 實例
             show_debug_message("[Battle Result Popup] Requested UI Manager to hide self (ID: " + string(other.id) + ").");
         }
    } else {
         show_debug_message("錯誤：[Battle Result Popup] 無法通過 UI 管理器隱藏，管理器不存在。");
         visible = false; // 備選方案
         active = false;
    }
}

// Step 事件中會檢查按鍵 