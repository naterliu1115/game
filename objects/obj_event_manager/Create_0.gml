// obj_event_manager - Create_0.gml

// 主要數據結構 - 存儲事件訂閱者
event_subscribers = ds_map_create();

// 事件歷史記錄（用於調試）
event_history = ds_list_create();
max_history_size = 100; // 最多保存100個最近事件
event_debug_mode = true; // 是否記錄詳細事件信息，可以根據需要關閉

// 註冊事件處理函數
function subscribe_to_event(event_name, instance_id, callback) {
    if (!ds_map_exists(event_subscribers, event_name)) {
        ds_map_add(event_subscribers, event_name, ds_list_create());
    }
    
    var subscriber_list = event_subscribers[? event_name];
    
    // 避免重複訂閱
    for (var i = 0; i < ds_list_size(subscriber_list); i++) {
        var subscriber = subscriber_list[| i];
        if (subscriber.instance == instance_id && subscriber.callback == callback) {
            show_debug_message("警告: 實例 " + string(instance_id) + " 已訂閱事件 " + event_name);
            return;
        }
    }
    
    // 添加新訂閱者
    ds_list_add(subscriber_list, {
        instance: instance_id,
        callback: callback
    });
    
    if (event_debug_mode) {
        show_debug_message("事件系統: 實例 " + string(instance_id) + " 訂閱了事件 " + event_name);
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
        show_debug_message("事件系統: 實例 " + string(instance_id) + " 取消了所有事件訂閱");
    }
}

// 處理事件
function handle_event(event_name, data) {
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
        
        show_debug_message("事件觸發: " + event_name);
    }
    
    // 如果沒有訂閱者，直接返回
    if (!ds_map_exists(event_subscribers, event_name)) return;
    
    var subscriber_list = event_subscribers[? event_name];
    
    // 複製一份訂閱者列表，避免在迭代過程中修改列表
    var temp_list = ds_list_create();
    for (var i = 0; i < ds_list_size(subscriber_list); i++) {
        ds_list_add(temp_list, subscriber_list[| i]);
    }
    
    // 遍歷訂閱者列表並調用回調函數
    for (var i = 0; i < ds_list_size(temp_list); i++) {
        var subscriber = temp_list[| i];
        
        if (instance_exists(subscriber.instance)) {
            with (subscriber.instance) {
                // 在實例上下文中調用回調函數
                if (variable_instance_exists(id, subscriber.callback) && is_method(variable_instance_get(id, subscriber.callback))) {
                    var callback_method = variable_instance_get(id, subscriber.callback);
                    callback_method(data);
                } else {
                    show_debug_message("警告: 回調 " + subscriber.callback + " 在實例 " + string(id) + " 中不存在或不是方法");
                }
            }
        } else {
            // 如果實例不存在，從訂閱者列表中移除
            for (var j = 0; j < ds_list_size(subscriber_list); j++) {
                var original_subscriber = subscriber_list[| j];
                if (original_subscriber.instance == subscriber.instance) {
                    ds_list_delete(subscriber_list, j);
                    if (event_debug_mode) {
                        show_debug_message("事件系統: 已移除不存在的實例 " + string(subscriber.instance) + " 的訂閱");
                    }
                    break;
                }
            }
        }
    }
    
    // 清理臨時列表
    ds_list_destroy(temp_list);
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
    show_debug_message("事件管理器已初始化");
}