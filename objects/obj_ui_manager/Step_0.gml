// =======================
// Step 事件代碼
// =======================

// obj_ui_manager - Step_0.gml

// --- 更新全局輸入阻斷旗標 (重構後) ---
var should_block = false;
if (variable_instance_exists(id, "active_ui")) { // 確保 active_ui 已初始化
    // 檢查是否有任何活躍的 popup 或 main 層級 UI
    // 這些層級的 UI 應該繼承 parent_ui 並透過管理器顯示/隱藏
    if (ds_list_size(active_ui[? "popup"]) > 0 || ds_list_size(active_ui[? "main"]) > 0) {
        should_block = true;
    }
    // 可以根據需要考慮是否檢查 overlay 層級
    // else if (ds_list_size(active_ui[? "overlay"]) > 0) {
    //     // 如果 overlay 層也需要阻斷，取消註解
    //     should_block = true; 
    // }
}

// // 檢查獨立的 Debug 工具是否可見 <<-- 移除：Debug 工具現在應繼承 parent_ui 並由管理器控制
// if (instance_exists(obj_debug_inventory_tool) && obj_debug_inventory_tool.is_visible) {
//      should_block = true;
// }

global.ui_input_block = should_block;
// --- 旗標更新結束 ---


// 防禦性檢查，確保 active_ui_instances 已初始化
if (!variable_instance_exists(id, "active_ui_instances")) {
    active_ui_instances = ds_map_create();
    show_debug_message("警告：active_ui_instances 在 Step 事件中未初始化，已自動建立。");
}

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

// --- 處理UI輸入 (優先處理 Popup 層) ---
var _input_handled = false; // 標記輸入是否已被處理

// 檢查 Popup 層
var popup_ui_list = active_ui[? "popup"];
if (ds_list_size(popup_ui_list) > 0) {
    var _ui_inst = popup_ui_list[| ds_list_size(popup_ui_list) - 1]; // 取最上層 Popup UI
    if (instance_exists(_ui_inst)) {
        
        // 滑鼠左鍵點擊
        if (mouse_check_button_pressed(mb_left)) {
            var mx = device_mouse_x_to_gui(0);
            var my = device_mouse_y_to_gui(0);
            if (variable_instance_exists(_ui_inst, "handle_mouse_click") && is_method(_ui_inst.handle_mouse_click)) {
                if (_ui_inst.handle_mouse_click(mx, my)) {
                    _input_handled = true;
                    mouse_clear(mb_left);
                    show_debug_message("UI管理器: 滑鼠左鍵點擊被 Popup UI 處理並消耗");
                }
            }
            // 注意：Popup 層通常需要處理點擊外部關閉，這應該在 Popup 物件自身 Step 處理
        }

        // Escape鍵（關閉）
        if (!_input_handled && keyboard_check_pressed(vk_escape)) {
             if (variable_instance_exists(_ui_inst, "handle_close_input") && is_method(_ui_inst.handle_close_input)) {
                 if (_ui_inst.handle_close_input()) {
                     _input_handled = true;
                     keyboard_clear(vk_escape);
                     show_debug_message("UI管理器: Escape鍵關閉輸入被 Popup UI 處理並消耗 (自訂方法)");
                 }
             } else {
                 // 如果 Popup 沒有自訂關閉方法，管理器預設幫它關閉
                 hide_ui(_ui_inst);
                 _input_handled = true;
                 keyboard_clear(vk_escape);
                 show_debug_message("UI管理器: Escape鍵關閉輸入，由管理器關閉 Popup UI");
             }
        }
        
        // Enter/Space 鍵 (確認) - Popup 通常不直接處理確認，除非有特殊按鈕
        if (!_input_handled && (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space))) {
            var _key = keyboard_check_pressed(vk_enter) ? vk_enter : vk_space;
            var _key_name = (_key == vk_enter) ? "Enter" : "Space";
            if (variable_instance_exists(_ui_inst, "handle_confirm_input") && is_method(_ui_inst.handle_confirm_input)) {
                if (_ui_inst.handle_confirm_input()) {
                    _input_handled = true;
                    keyboard_clear(_key);
                    show_debug_message("UI管理器: " + _key_name + "鍵確認輸入被 Popup UI 處理並消耗");
                }
            }
             // Popup 通常點擊按鈕，不直接響應 Enter/Space，除非有設計
        }
    }
}

// === reward_visible 狀態下禁止 main 層滑鼠左鍵全域關閉 ===
var reward_ui_found = false;
var main_ui_list = active_ui[? "main"];
for (var i = 0; i < ds_list_size(main_ui_list); i++) {
    var _ui_inst = main_ui_list[| i];
    if (instance_exists(_ui_inst) && variable_instance_exists(_ui_inst, "reward_visible") && _ui_inst.reward_visible) {
        reward_ui_found = true;
        break;
    }
}

// [DEBUG] 追蹤 reward_ui_found 狀態
if (reward_ui_found) {
    show_debug_message("[DEBUG] Step_0.gml: 偵測到 reward_visible=true 的 UI，id=" + string(_ui_inst) + ", 物件=" + object_get_name(_ui_inst.object_index));
}

// 如果輸入未被 Popup 處理，再檢查 Main 層
if (!_input_handled) {
    var main_ui_list = active_ui[? "main"];
    if (ds_list_size(main_ui_list) > 0) {
        var _ui_inst = main_ui_list[| ds_list_size(main_ui_list) - 1]; // 取最上層 Main UI
        if (instance_exists(_ui_inst)) {
            // reward_visible 狀態下禁止滑鼠左鍵全域關閉
            // [註解] 暫時移除 reward_visible 條件，協助追蹤彈窗被自動隱藏問題
            // if (!reward_ui_found) {
            if (mouse_check_button_pressed(mb_left)) {
                var mx = device_mouse_x_to_gui(0);
                var my = device_mouse_y_to_gui(0);
                if (variable_instance_exists(_ui_inst, "handle_mouse_click") && is_method(_ui_inst.handle_mouse_click)) {
                    if (_ui_inst.handle_mouse_click(mx, my)) {
                        _input_handled = true; // 雖然是最後一層，還是標記一下
                        mouse_clear(mb_left);
                        show_debug_message("[DEBUG] UI管理器: 滑鼠左鍵點擊被 Main UI 處理並消耗，id=" + string(_ui_inst) + ", 物件=" + object_get_name(_ui_inst.object_index));
                    }
                }
                // [DEBUG] 若未被 handle_mouse_click 處理，記錄將進行什麼操作
                if (!_input_handled) {
                    show_debug_message("[DEBUG] UI管理器: 滑鼠左鍵點擊未被 Main UI 處理，id=" + string(_ui_inst) + ", 物件=" + object_get_name(_ui_inst.object_index));
                }
            }
            // }
            
            // Escape鍵（關閉）
            if (!_input_handled && keyboard_check_pressed(vk_escape)) {
                if (variable_instance_exists(_ui_inst, "handle_close_input") && is_method(_ui_inst.handle_close_input)) {
                     if (_ui_inst.handle_close_input()) {
                         _input_handled = true;
                         keyboard_clear(vk_escape);
                         show_debug_message("UI管理器: Escape鍵關閉輸入被 Main UI 處理並消耗 (自訂方法)");
                     }
                } else {
                     // 如果 Main UI 沒有自訂關閉方法，管理器預設幫它關閉
                     hide_ui(_ui_inst);
                     _input_handled = true;
                     keyboard_clear(vk_escape);
                     show_debug_message("UI管理器: Escape鍵關閉輸入，由管理器關閉 Main UI");
                }
            }

            // Enter/Space 鍵 (確認)
             if (!_input_handled && (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(vk_space))) {
                var _key = keyboard_check_pressed(vk_enter) ? vk_enter : vk_space;
                var _key_name = (_key == vk_enter) ? "Enter" : "Space";
                if (variable_instance_exists(_ui_inst, "handle_confirm_input") && is_method(_ui_inst.handle_confirm_input)) {
                    if (_ui_inst.handle_confirm_input()) {
                        _input_handled = true;
                        keyboard_clear(_key);
                        show_debug_message("UI管理器: " + _key_name + "鍵確認輸入被 Main UI 處理並消耗");
                    }
                }
             }
        }
    }
}
// --- 輸入處理結束 ---


// 更新UI管理器時鐘
ui_manager_clock += 1;

// 處理可見性過渡效果
for (var i = 0; i < ds_list_size(ui_transition_queue); i++) {
    var _transition_data = ui_transition_queue[| i];
    var _ui_inst = _transition_data[? "ui_instance"];
    var _target_alpha = _transition_data[? "target_alpha"];
    var _transition_speed = _transition_data[? "transition_speed"];
    var _on_complete = _transition_data[? "on_complete"];
    var _completed = false;
    
    if (instance_exists(_ui_inst)) {
        if (_ui_inst.ui_alpha < _target_alpha) {
            _ui_inst.ui_alpha = min(_ui_inst.ui_alpha + _transition_speed, _target_alpha);
            if (_ui_inst.ui_alpha >= _target_alpha) _completed = true;
        } else if (_ui_inst.ui_alpha > _target_alpha) {
            _ui_inst.ui_alpha = max(_ui_inst.ui_alpha - _transition_speed, _target_alpha);
            if (_ui_inst.ui_alpha <= _target_alpha) _completed = true;
        } else {
            _completed = true;
        }
        
        // 根據alpha值設置可見性
        _ui_inst.visible = (_ui_inst.ui_alpha > 0);
        
        // 如果過渡完成且有回調函數
        if (_completed && _on_complete != undefined && is_method(_on_complete)) {
            _on_complete(_ui_inst, _target_alpha);
        }
        
        // 如果過渡完成，從佇列中移除
        if (_completed) {
            ds_map_destroy(_transition_data);
            ds_list_delete(ui_transition_queue, i);
            i--;
        }
    } else {
        // 如果UI實例不存在，從佇列中移除
        ds_map_destroy(_transition_data);
        ds_list_delete(ui_transition_queue, i);
        i--;
    }
}