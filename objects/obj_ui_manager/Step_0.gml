// =======================
// Step 事件代碼
// =======================

// obj_ui_manager - Step_0.gml

// 定期檢查surface狀態
surface_check_counter++;
if (surface_check_counter >= 30) { // 每30幀檢查一次
    check_lost_surfaces();
    surface_check_counter = 0;
}

// 更新消息計時器
var queue_size = ds_queue_size(message_queue);
if (queue_size > 0) {
    var temp_queue = ds_queue_create();
    
    // 遍歷並更新所有消息
    for (var i = 0; i < queue_size; i++) {
        var message = ds_queue_dequeue(message_queue);
        
        // 更新計時器
        message.timer++;
        
        // 計算淡出效果
        if (message.timer >= message.duration * 0.7) {
            var remaining = message.duration - message.timer;
            var fade_duration = message.duration * 0.3;
            message.alpha = remaining / fade_duration;
        }
        
        // 如果消息還未過期，放回隊列
        if (message.timer < message.duration) {
            ds_queue_enqueue(temp_queue, message);
        }
    }
    
    // 將更新後的消息放回原隊列
    while (!ds_queue_empty(temp_queue)) {
        ds_queue_enqueue(message_queue, ds_queue_dequeue(temp_queue));
    }
    
    // 清理臨時隊列
    ds_queue_destroy(temp_queue);
}

// --- 處理通用 UI 輸入 (例如關閉、確認按鈕) ---
var _input_handled_by_manager = false; // Renamed to be clearer
var _top_ui_instance = noone;

// 優先處理 Popup 層
var popup_list = active_ui[? "popup"];
if (ds_list_size(popup_list) > 0) {
    _top_ui_instance = popup_list[| ds_list_size(popup_list) - 1];
} else {
    var overlay_list = active_ui[? "overlay"];
    if (ds_list_size(overlay_list) > 0) {
        _top_ui_instance = overlay_list[| ds_list_size(overlay_list) - 1];
    } else {
        var main_list = active_ui[? "main"];
        if (ds_list_size(main_list) > 0) {
             _top_ui_instance = main_list[| ds_list_size(main_list) - 1];
        }
    }
}

// 如果找到了頂層 UI，檢查通用輸入
if (instance_exists(_top_ui_instance)) {
    // 標記允許處理內部輸入 (將在 Step 事件末尾設置)
    // Initialize the flag on the instance if it doesn't exist to avoid errors
    if (!variable_instance_exists(_top_ui_instance, "process_internal_input_flag")) {
        _top_ui_instance.process_internal_input_flag = false;
    }

    // 1. 檢查空格鍵 (通用確認 - 例如召喚, 或關閉戰鬥結果)
    if (keyboard_check_pressed(vk_space)) {
        // --- 修改：優先處理 obj_battle_ui 的關閉 --- 
        if (object_get_name(_top_ui_instance.object_index) == "obj_battle_ui" &&
            variable_instance_exists(_top_ui_instance, "handle_close_input") && 
            typeof(variable_instance_get(_top_ui_instance, "handle_close_input")) == "method")
        {
            show_debug_message("[UI Manager] Space pressed. Calling handle_close_input for obj_battle_ui.");
            _top_ui_instance.handle_close_input(); 
            _input_handled_by_manager = true;
        } 
        // --- 如果不是 obj_battle_ui 或沒有 handle_close_input，則檢查通用確認 --- 
        else if (variable_instance_exists(_top_ui_instance, "handle_confirm_input") && 
                 typeof(variable_instance_get(_top_ui_instance, "handle_confirm_input")) == "method") 
        {
            show_debug_message("[UI Manager] Space pressed. Calling handle_confirm_input for: " + object_get_name(_top_ui_instance.object_index));
            _top_ui_instance.handle_confirm_input(); 
            _input_handled_by_manager = true;
        } 
        // --- 如果兩者都沒有 --- 
        else {
            show_debug_message("[UI Manager] Space pressed, but top UI " + object_get_name(_top_ui_instance.object_index) + " has neither specific close logic nor handle_confirm_input method.");
        }
        // --- 結束修改 ---
    }
    // 2. 檢查 ESC 鍵 (通用關閉)
    else if (keyboard_check_pressed(vk_escape)) { 
         // 使用替代方案檢查 handle_close_input 方法
        if (variable_instance_exists(_top_ui_instance, "handle_close_input") && 
            typeof(variable_instance_get(_top_ui_instance, "handle_close_input")) == "method") 
        {
            show_debug_message("[UI Manager] Escape pressed. Calling handle_close_input for: " + object_get_name(_top_ui_instance.object_index));
            _top_ui_instance.handle_close_input(); 
            _input_handled_by_manager = true;
        } else {
            show_debug_message("[UI Manager] Escape pressed, but top UI " + object_get_name(_top_ui_instance.object_index) + " has no handle_close_input method or variable.");
        }
    }
    // 3. 檢查 Enter 鍵 (通用確認)
    else if (keyboard_check_pressed(vk_enter)) { 
        // 使用替代方案檢查 handle_confirm_input 方法
        if (variable_instance_exists(_top_ui_instance, "handle_confirm_input") && 
            typeof(variable_instance_get(_top_ui_instance, "handle_confirm_input")) == "method") 
        {
            show_debug_message("[UI Manager] Enter pressed. Calling handle_confirm_input for: " + object_get_name(_top_ui_instance.object_index));
            _top_ui_instance.handle_confirm_input(); 
            _input_handled_by_manager = true;
        } else {
             show_debug_message("[UI Manager] Enter pressed, but top UI " + object_get_name(_top_ui_instance.object_index) + " has no handle_confirm_input method or variable.");
        }
    }
    // 4. 檢查鼠標左鍵點擊
    else if (mouse_check_button_pressed(mb_left)) { 
        // 使用替代方案檢查 handle_mouse_click 方法
        if (variable_instance_exists(_top_ui_instance, "handle_mouse_click") && 
            typeof(variable_instance_get(_top_ui_instance, "handle_mouse_click")) == "method") 
        {
            var _mx = device_mouse_x_to_gui(0);
            var _my = device_mouse_y_to_gui(0);
            show_debug_message("[UI Manager] Left Click detected. Calling handle_mouse_click for: " + object_get_name(_top_ui_instance.object_index));
            // 直接調用，返回值賦給 _input_handled_by_manager
            _input_handled_by_manager = _top_ui_instance.handle_mouse_click(_mx, _my); 
        } else {
             show_debug_message("[UI Manager] Left Click detected, but top UI " + object_get_name(_top_ui_instance.object_index) + " has no handle_mouse_click method or variable.");
        }
    }

    // 如果通用輸入未處理，則允許 UI 處理內部輸入
    if (!_input_handled_by_manager) {
        _top_ui_instance.process_internal_input_flag = true;
        // show_debug_message("[UI Manager] Allowing internal input processing for: " + object_get_name(_top_ui_instance.object_index));
    }
}

// 如果沒有頂層 UI 或者輸入已被管理器處理，則考慮將輸入傳遞給遊戲世界 (例如玩家)
// 注意： obj_player 的輸入啟用/禁用邏輯也需要考慮
// if (!_input_handled_by_manager && !instance_exists(_top_ui_instance) && instance_exists(obj_player) && obj_player.can_move) {
//    // Pass input to player or handle world interaction
// }