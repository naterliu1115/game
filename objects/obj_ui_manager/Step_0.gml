// =======================
// Step 事件代碼
// =======================

// obj_ui_manager - Step_0.gml

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

// 處理UI輸入
var main_ui_list = active_ui[? "main"];
if (ds_list_size(main_ui_list) > 0) {
    var _ui_inst = main_ui_list[| ds_list_size(main_ui_list) - 1]; // 取最上層UI
    if (instance_exists(_ui_inst)) {
        // Space鍵（確認）
        if (keyboard_check_pressed(vk_space)) {
            var _handled = false;
            if (variable_instance_exists(_ui_inst, "handle_confirm_input") && is_method(_ui_inst.handle_confirm_input)) {
                _handled = _ui_inst.handle_confirm_input();
            }
            if (_handled) {
                keyboard_clear(vk_space);
                show_debug_message("UI管理器: Space鍵確認輸入被UI處理並消耗");
            }
        }
        // Escape鍵（關閉）
        if (keyboard_check_pressed(vk_escape)) {
            var _handled = false;
            if (variable_instance_exists(_ui_inst, "handle_close_input") && is_method(_ui_inst.handle_close_input)) {
                _handled = _ui_inst.handle_close_input();
            } else {
                hide_ui(_ui_inst);
                _handled = true;
            }
            if (_handled) {
                keyboard_clear(vk_escape);
                show_debug_message("UI管理器: Escape鍵關閉輸入被UI處理並消耗");
            }
        }
        // Enter鍵（確認，作為Space的替代）
        if (keyboard_check_pressed(vk_enter)) {
            var _handled = false;
            if (variable_instance_exists(_ui_inst, "handle_confirm_input") && is_method(_ui_inst.handle_confirm_input)) {
                _handled = _ui_inst.handle_confirm_input();
            }
            if (_handled) {
                keyboard_clear(vk_enter);
                show_debug_message("UI管理器: Enter鍵確認輸入被UI處理並消耗");
            }
        }
        // 滑鼠左鍵點擊
        if (mouse_check_button_pressed(mb_left)) {
            var mx = device_mouse_x_to_gui(0);
            var my = device_mouse_y_to_gui(0);
            var _handled = false;
            if (variable_instance_exists(_ui_inst, "handle_mouse_click") && is_method(_ui_inst.handle_mouse_click)) {
                _handled = _ui_inst.handle_mouse_click(mx, my);
            }
            if (_handled) {
                mouse_clear(mb_left);
                show_debug_message("UI管理器: 滑鼠左鍵點擊被UI處理並消耗");
            }
        }
    }
}

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