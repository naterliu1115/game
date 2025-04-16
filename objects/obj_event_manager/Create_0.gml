// obj_event_manager - Create_0.gml

// 主要數據結構 - 存儲事件訂閱者
event_subscribers = ds_map_create();

// 事件歷史記錄（用於調試）
event_history = ds_list_create();
max_history_size = 100; // 最多保存100個最近事件
event_debug_mode = true; // 是否記錄詳細事件信息，可以根據需要關閉

// 註冊事件處理函數 (修改以支持腳本索引)
function subscribe_to_event(event_name, instance_id, callback) {
    if (!instance_exists(instance_id)) {
        show_debug_message("警告: 嘗試訂閱事件的實例不存在，ID: " + string(instance_id));
        return;
    }
    
    if (!ds_map_exists(event_subscribers, event_name)) {
        ds_map_add(event_subscribers, event_name, ds_list_create());
    }
    
    var subscriber_list = event_subscribers[? event_name];
    
    // 避免重複訂閱 (檢查回調時要考慮類型)
    for (var i = 0; i < ds_list_size(subscriber_list); i++) {
        var subscriber = subscriber_list[| i];
        if (subscriber.instance == instance_id && subscriber.callback == callback) {
            show_debug_message("警告: 實例 " + string(instance_id) + " 已使用相同回調訂閱事件 " + event_name);
            return;
        }
    }
    
    // 檢查回調類型並驗證
    var callback_valid = false;
    var callback_type = "unknown";
    
    if (is_string(callback)) {
        // 驗證字符串方法名
        callback_type = "method name (string)";
        with (instance_id) {
            if (variable_instance_exists(id, callback)) {
                callback_valid = true;
            } else {
                 show_debug_message("警告: 實例 " + string(id) + " 沒有回調方法 (字符串) " + callback);
            }
        }
    } else if (is_real(callback)) {
        // 驗證腳本索引
        callback_type = "script index (real)";
        if (script_exists(callback)) {
            callback_valid = true;
        } else {
            show_debug_message("錯誤: 回調腳本索引 " + string(callback) + " 不存在");
        }
    } else {
        show_debug_message("錯誤: 回調必須是字符串 (方法名) 或數字 (腳本索引)，而不是 " + string(callback));
        return;
    }
    
    // 如果回調無效，則不添加訂閱
    if (!callback_valid) {
        return;
    }
    
    // 添加新訂閱者 (儲存原始回調值)
    ds_list_add(subscriber_list, {
        instance: instance_id,
        callback: callback // 儲存字符串名或腳本索引
    });
    
    if (event_debug_mode) {
        show_debug_message("事件系統: 實例 " + string(instance_id) + " 訂閱了事件 " + event_name + " (回調類型: " + callback_type + ")");
    }
}

// 取消特定事件的訂閱
function unsubscribe_from_event(event_name, instance_id) {
    if (!ds_map_exists(event_subscribers, event_name)) return;
    
    var subscriber_list = event_subscribers[? event_name];
    
    for (var i = ds_list_size(subscriber_list) - 1; i >= 0; i--) {
        var subscriber = subscriber_list[| i];
        if (subscriber.instance == instance_id) {
            ds_list_delete(subscriber_list, i);
            
            if (event_debug_mode) {
                show_debug_message("事件系統: 實例 " + string(instance_id) + " 取消訂閱事件 " + event_name);
            }
        }
    }
}

// 取消實例的所有事件訂閱
function unsubscribe_from_all_events(instance_id) {
    var keys = ds_map_keys_to_array(event_subscribers);
    
    for (var i = 0; i < array_length(keys); i++) {
        var event_name = keys[i];
        unsubscribe_from_event(event_name, instance_id);
    }
    
    if (event_debug_mode) {
        // show_debug_message("事件系統: 實例 " + string(instance_id) + " 取消了所有事件訂閱"); // <-- 註解掉
    }
}

// 處理事件 (修改以支持腳本執行)
function handle_event(event_name, data) {
    try {
        // 記錄事件歷史
        if (event_debug_mode) {
            var event_info = {
                name: event_name,
                data: data,
                time: current_time
            };
            
            ds_list_add(event_history, event_info);
            
            // 限制歷史記錄大小
            if (ds_list_size(event_history) > max_history_size) {
                ds_list_delete(event_history, 0);
            }
            
            // show_debug_message("事件觸發: " + event_name); // <-- 註解掉
        }
        
        // 如果沒有訂閱者，直接返回
        if (!ds_map_exists(event_subscribers, event_name)) {
            if (event_debug_mode) {
                // show_debug_message("事件 " + event_name + " 沒有訂閱者"); // <-- 註解掉
            }
            return;
        }
        
        var subscriber_list = event_subscribers[? event_name];
        
        // 複製一份訂閱者列表
        var temp_list = ds_list_create();
        for (var i = 0; i < ds_list_size(subscriber_list); i++) {
            ds_list_add(temp_list, subscriber_list[| i]);
        }
        
        // 遍歷訂閱者列表並調用回調函數
        for (var i = 0; i < ds_list_size(temp_list); i++) {
            var subscriber = temp_list[| i];
            
            if (!is_struct(subscriber)) {
                show_debug_message("錯誤: 訂閱者不是有效的結構體");
                continue;
            }
            
            if (!variable_struct_exists(subscriber, "instance") || !variable_struct_exists(subscriber, "callback")) {
                show_debug_message("錯誤: 訂閱者結構體缺少必要的字段");
                continue;
            }
            
            if (!instance_exists(subscriber.instance)) {
                show_debug_message("警告: 訂閱者實例不存在，ID: " + string(subscriber.instance));
                // 從原始列表中移除
                for (var j = 0; j < ds_list_size(subscriber_list); j++) {
                    var original_subscriber = subscriber_list[| j];
                    if (original_subscriber.instance == subscriber.instance) {
                        ds_list_delete(subscriber_list, j);
                        break;
                    }
                }
                continue;
            }
            
            var _callback = subscriber.callback;
            var _instance_id = subscriber.instance;
            
            // --- 新增日誌：檢查回調類型和值 ---
            // show_debug_message("[EventManager HandleEvent] Checking callback for instance " + string(_instance_id) + ". Callback Value: " + string(_callback) + ", Type: " + typeof(_callback)); // <-- 註解掉
            
            // 執行回調
            try {
                if (is_string(_callback)) {
                    // --- 處理字符串方法名 --- 
                    // show_debug_message("[EventManager HandleEvent] Callback is STRING."); // <-- 註解掉
                    with (_instance_id) {
                        if (!variable_instance_exists(id, _callback)) {
                            show_debug_message("警告: 回調方法(字符串) " + string(_callback) + " 在實例 " + string(id) + " 中不存在 (執行時)");
                            continue; // 跳過這個訂閱者
                        }
                        var callback_method = variable_instance_get(id, _callback);
                        if (!is_method(callback_method)) {
                            show_debug_message("警告: " + string(_callback) + " 在實例 " + string(id) + " 中不是一個有效的方法");
                            continue; // 跳過
                        }
                        // 執行方法
                        // show_debug_message("[EventManager] Executing METHOD: " + _callback + " on instance " + string(id)); // <-- 註解掉
                        callback_method(data);
                    }
                } else if (is_real(_callback)) {
                    // --- 處理腳本索引 --- 
                    // show_debug_message("[EventManager HandleEvent] Callback is REAL (Script Index?). Entering script handling block."); // <-- 註解掉
                    if (!script_exists(_callback)) {
                        show_debug_message("錯誤: 回調腳本索引 " + string(_callback) + " 在執行時不存在");
                        continue; // 跳過
                    }
                    // show_debug_message("[EventManager HandleEvent] Script " + script_get_name(_callback) + " exists. Preparing to execute."); // <-- 註解掉
                    // 執行腳本，傳遞數據和實例ID
                    // show_debug_message("[EventManager] Executing SCRIPT: " + script_get_name(_callback) + " for instance " + string(_instance_id)); // <-- 註解掉
                    script_execute(_callback, data, _instance_id);
                    // show_debug_message("[EventManager HandleEvent] script_execute for " + script_get_name(_callback) + " called. Script execution *may* have started."); // <-- 註解掉
                } else {
                     show_debug_message("錯誤: 未知的回調類型: " + string(_callback));
                 }
                 
            } catch (e) {
                show_debug_message("錯誤: 執行回調 (" + string(_callback) + ") 時發生異常: " + string(e.message));
            }
        }
        
        // 清理臨時列表
        ds_list_destroy(temp_list);
        
    } catch (e) {
        show_debug_message("錯誤: 處理事件 (" + event_name + ") 時發生異常: " + string(e.message));
    }
}

// 觸發事件 (公開接口)
function trigger_event(event_name, data) {
    // 這裡可以根據需要添加一些基本的檢查，例如 event_name 是否為空字串等

    if (event_debug_mode) {
        show_debug_message("[EventManager] Triggering event: " + event_name);
    }

    // 調用內部處理函數
    handle_event(event_name, data);
}

// 清理資源
// 在Destroy事件中調用
function cleanup_event_system() {
    // 釋放所有訂閱者列表
    var keys = ds_map_keys_to_array(event_subscribers);
    for (var i = 0; i < array_length(keys); i++) {
        var key = keys[i];
        var list = event_subscribers[? key];
        if (ds_exists(list, ds_type_list)) {
            ds_list_destroy(list);
        }
    }
    
    // 釋放映射和歷史記錄
    ds_map_destroy(event_subscribers);
    ds_list_destroy(event_history);
    
    if (event_debug_mode) {
        show_debug_message("事件系統: 資源已清理");
    }
}

// 獲取事件訂閱者數量（用於調試）
function get_subscribers_count(event_name = "") {
    if (event_name != "") {
        if (ds_map_exists(event_subscribers, event_name)) {
            return ds_list_size(event_subscribers[? event_name]);
        }
        return 0;
    } else {
        // 返回所有訂閱者總數
        var total = 0;
        var keys = ds_map_keys_to_array(event_subscribers);
        for (var i = 0; i < array_length(keys); i++) {
            var key = keys[i];
            total += ds_list_size(event_subscribers[? key]);
        }
        return total;
    }
}

// 獲取事件歷史
function get_event_history(count = 10) {
    count = min(count, ds_list_size(event_history));
    var history = array_create(count);
    
    for (var i = 0; i < count; i++) {
        var index = ds_list_size(event_history) - count + i;
        history[i] = event_history[| index];
    }
    
    return history;
}

// 將事件系統全局化（可選）
global.event_manager = id;

if (event_debug_mode) {
    show_debug_message("事件管理器已初始化 (支持腳本回調)");
}