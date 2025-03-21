// obj_ui_manager - Create_0.gml

// 建立UI層級結構
ui_layers = ds_map_create();
ds_map_add(ui_layers, "background", ds_list_create());  // 最底層
ds_map_add(ui_layers, "main", ds_list_create());        // 主要UI層
ds_map_add(ui_layers, "overlay", ds_list_create());     // 浮層UI
ds_map_add(ui_layers, "popup", ds_list_create());       // 彈窗層（最高層級）

// 層級深度設置
layer_depths = ds_map_create();
ds_map_add(layer_depths, "background", -50);
ds_map_add(layer_depths, "main", -100);
ds_map_add(layer_depths, "overlay", -150);
ds_map_add(layer_depths, "popup", -200);

// 追蹤當前活躍的UI
active_ui = ds_map_create();
ds_map_add(active_ui, "background", ds_list_create());
ds_map_add(active_ui, "main", ds_list_create());
ds_map_add(active_ui, "overlay", ds_list_create());
ds_map_add(active_ui, "popup", ds_list_create());

// Surface管理
ui_surfaces = ds_map_create(); // 存儲UI surface的映射表
surface_check_counter = 0; // 用於定期檢查surface是否丟失

// UI消息顯示
message_queue = ds_queue_create(); // 消息隊列
max_messages = 5; // 最多同時顯示的消息數
message_duration = 3 * game_get_speed(gamespeed_fps); // 3秒顯示時間
message_spacing = 30; // 消息間距

// 初始化
function initialize() {
    show_debug_message("===== 初始化UI管理器 =====");
    
    // 訂閱相關事件
    if (instance_exists(obj_event_manager)) {
        show_debug_message("事件管理器存在，開始訂閱事件...");
        
        with (obj_event_manager) {
            // 使用字符串而不是函數引用
            subscribe_to_event("ui_message", other.id, "on_ui_message");
            subscribe_to_event("close_all_ui", other.id, "close_all_ui");
            subscribe_to_event("battle_end", other.id, "on_battle_end");
        }
        
        show_debug_message("事件訂閱完成");
    } else {
        show_debug_message("錯誤：找不到事件管理器");
    }
    
    show_debug_message("===== UI管理器初始化完成 =====");
}

// 註冊UI到指定層級
function register_ui(ui_instance, layer_name) {
    if (!ds_map_exists(ui_layers, layer_name)) {
        show_debug_message("錯誤: 嘗試註冊UI到不存在的層級 " + layer_name);
        return;
    }
    
    var ui_list = ui_layers[? layer_name];
    
    // 檢查是否已註冊
    for (var i = 0; i < ds_list_size(ui_list); i++) {
        if (ui_list[| i] == ui_instance) {
            show_debug_message("警告: UI " + object_get_name(ui_instance.object_index) + " 已註冊到層級 " + layer_name);
            return;
        }
    }
    
    // 註冊UI並設置其深度
    ds_list_add(ui_list, ui_instance);
    ui_instance.depth = layer_depths[? layer_name];
    
    show_debug_message("UI註冊: " + object_get_name(ui_instance.object_index) + " 到層級 " + layer_name + "，深度 = " + string(ui_instance.depth));
}

// 顯示UI
function show_ui(ui_instance, layer_name) {
    if (!instance_exists(ui_instance)) {
        show_debug_message("錯誤: 嘗試顯示不存在的UI實例");
        return;
    }
    
    if (!ds_map_exists(ui_layers, layer_name)) {
        show_debug_message("錯誤: 嘗試在不存在的層級顯示UI: " + layer_name);
        return;
    }
    
    // 確保UI已註冊
    var ui_list = ui_layers[? layer_name];
    var registered = false;
    
    for (var i = 0; i < ds_list_size(ui_list); i++) {
        if (ui_list[| i] == ui_instance) {
            registered = true;
            break;
        }
    }
    
    if (!registered) {
        register_ui(ui_instance, layer_name);
    }
    
    // 處理互斥層
    if (layer_name == "main" || layer_name == "popup") {
        hide_layer(layer_name);
    }
    
    // 顯示UI
    with (ui_instance) {
        visible = true;
        active = true;
        if (variable_instance_exists(id, "show") && is_method(variable_instance_get(id, "show"))) {
            var show_method = variable_instance_get(id, "show");
            show_method();
        }
    }
    
    // 添加到活躍UI列表
    var active_list = active_ui[? layer_name];
    ds_list_add(active_list, ui_instance);
    
    show_debug_message("UI顯示: " + object_get_name(ui_instance.object_index) + " 在層級 " + layer_name);
}

// 隱藏UI
function hide_ui(ui_instance) {
    if (!instance_exists(ui_instance)) return;
    
    // 隱藏UI
    with (ui_instance) {
        if (variable_instance_exists(id, "hide") && is_method(variable_instance_get(id, "hide"))) {
            var hide_method = variable_instance_get(id, "hide");
            hide_method();
        } else {
            visible = false;
            active = false;
        }
    }
    
    // 從活躍UI列表中移除
    var keys = ds_map_keys_to_array(active_ui);
    for (var i = 0; i < array_length(keys); i++) {
        var layer_name = keys[i];
        var active_list = active_ui[? layer_name];
        
        var index = ds_list_find_index(active_list, ui_instance);
        if (index != -1) {
            ds_list_delete(active_list, index);
            show_debug_message("UI隱藏: " + object_get_name(ui_instance.object_index) + " 從層級 " + layer_name);
        }
    }
}

// 隱藏指定層級的所有UI
function hide_layer(layer_name) {
    if (!ds_map_exists(active_ui, layer_name)) return;
    
    var active_list = active_ui[? layer_name];
    var count = ds_list_size(active_list);
    
    // 創建臨時列表以避免迭代過程中修改列表
    var temp_list = ds_list_create();
    for (var i = 0; i < count; i++) {
        ds_list_add(temp_list, active_list[| i]);
    }
    
    // 遍歷並隱藏所有UI
    for (var i = 0; i < ds_list_size(temp_list); i++) {
        var ui_inst = temp_list[| i];
        if (instance_exists(ui_inst)) {
            hide_ui(ui_inst);
        }
    }
    
    // 清理臨時列表
    ds_list_destroy(temp_list);
    
    show_debug_message("隱藏層級: " + layer_name + "，UI數量: " + string(count));
}

// 關閉所有UI
function close_all_ui(data = undefined) {
    var keys = ds_map_keys_to_array(active_ui);
    
    for (var i = 0; i < array_length(keys); i++) {
        hide_layer(keys[i]);
    }
    
    show_debug_message("已關閉所有UI");
}

// 獲取指定層級活躍的UI數量
function get_active_ui_count(layer_name = "") {
    if (layer_name != "") {
        if (ds_map_exists(active_ui, layer_name)) {
            return ds_list_size(active_ui[? layer_name]);
        }
        return 0;
    } else {
        // 返回所有層級的活躍UI總數
        var total = 0;
        var keys = ds_map_keys_to_array(active_ui);
        
        for (var i = 0; i < array_length(keys); i++) {
            var key = keys[i];
            total += ds_list_size(active_ui[? key]);
        }
        
        return total;
    }
}

// 檢查指定的UI是否活躍
function is_ui_active(ui_instance) {
    var keys = ds_map_keys_to_array(active_ui);
    
    for (var i = 0; i < array_length(keys); i++) {
        var layer_name = keys[i];
        var active_list = active_ui[? layer_name];
        
        if (ds_list_find_index(active_list, ui_instance) != -1) {
            return true;
        }
    }
    
    return false;
}

// 創建或獲取UI的Surface
function get_ui_surface(ui_instance, width, height) {
    var surface_id = -1;
    var ui_key = string(ui_instance);
    
    if (ds_map_exists(ui_surfaces, ui_key)) {
        surface_id = ui_surfaces[? ui_key];
        
        // 檢查surface是否存在，以及尺寸是否需要更新
        if (!surface_exists(surface_id) || 
            surface_get_width(surface_id) != width || 
            surface_get_height(surface_id) != height) {
                
            // 如果surface存在但尺寸不對，先釋放它
            if (surface_exists(surface_id)) {
                surface_free(surface_id);
            }
            
            // 創建新的surface
            surface_id = surface_create(width, height);
            ds_map_set(ui_surfaces, ui_key, surface_id);
        }
    } else {
        // 首次創建surface
        surface_id = surface_create(width, height);
        ds_map_add(ui_surfaces, ui_key, surface_id);
    }
    
    return surface_id;
}

// 釋放UI的Surface
function free_ui_surface(ui_instance) {
    var ui_key = string(ui_instance);
    
    if (ds_map_exists(ui_surfaces, ui_key)) {
        var surface_id = ui_surfaces[? ui_key];
        
        if (surface_exists(surface_id)) {
            surface_free(surface_id);
        }
        
        ds_map_delete(ui_surfaces, ui_key);
    }
}

// 檢查並恢復丟失的Surface
function check_lost_surfaces() {
    var keys = ds_map_keys_to_array(ui_surfaces);
    var key, surface_id, ui_inst;  // 在函數開頭一次性宣告所有變數
    
    for (var i = 0; i < array_length(keys); i++) {
        key = keys[i];  // 注意這裡沒有使用var
        surface_id = ui_surfaces[? key];
        ui_inst = noone;  // 為每次迭代重置變數
        
        if (!surface_exists(surface_id)) {
            // Surface丟失，標記對應的UI需要更新
            
            // 使用完整的if-else結構，避免try-catch
            if (is_string(key)) {
                ui_inst = asset_get_index(key);
                if (ui_inst == -1) ui_inst = noone;
            } else if (is_real(key)) {
                ui_inst = key;
            }
            // else ui_inst已經是noone了
            
            if (instance_exists(ui_inst)) {
                with (ui_inst) {
                    if (variable_instance_exists(id, "surface_needs_update")) {
                        surface_needs_update = true;
                    }
                }
            } else {
                // UI實例不存在，清理映射
                ds_map_delete(ui_surfaces, key);
            }
        }
    }
}

// 處理UI消息事件
function on_ui_message(data) {
    if (!variable_struct_exists(data, "message")) return;
    
    // 添加到消息隊列
    var message = {
        text: data.message,
        duration: variable_struct_exists(data, "duration") ? data.duration : message_duration,
        alpha: 1.0,
        timer: 0
    };
    
    ds_queue_enqueue(message_queue, message);
    
    // 限制消息數量
    while (ds_queue_size(message_queue) > max_messages) {
        ds_queue_dequeue(message_queue);
    }
}

// 處理戰鬥結束事件
function on_battle_end(data) {
    // 清理所有UI
    close_all_ui();
    
    // 清空消息隊列
    ds_queue_clear(message_queue);
    
    show_debug_message("UI管理器: 戰鬥結束，清理所有UI");
}

// 清理函數
function cleanup() {
    // 釋放所有surface
    var keys = ds_map_keys_to_array(ui_surfaces);
    for (var i = 0; i < array_length(keys); i++) {
        var key = keys[i];
        var surface_id = ui_surfaces[? key];
        
        if (surface_exists(surface_id)) {
            surface_free(surface_id);
        }
    }
    
    // 釋放數據結構
    var layer_keys = ds_map_keys_to_array(ui_layers);
    for (var i = 0; i < array_length(layer_keys); i++) {
        var key = layer_keys[i];
        var list = ui_layers[? key];
        
        if (ds_exists(list, ds_type_list)) {
            ds_list_destroy(list);
        }
    }
    
    var active_keys = ds_map_keys_to_array(active_ui);
    for (var i = 0; i < array_length(active_keys); i++) {
        var key = active_keys[i];
        var list = active_ui[? key];
        
        if (ds_exists(list, ds_type_list)) {
            ds_list_destroy(list);
        }
    }
    
    ds_map_destroy(ui_layers);
    ds_map_destroy(active_ui);
    ds_map_destroy(layer_depths);
    ds_map_destroy(ui_surfaces);
    ds_queue_destroy(message_queue);
    
    // 取消事件訂閱
    if (instance_exists(obj_event_manager)) {
        with (obj_event_manager) {
            unsubscribe_from_all_events(other.id);
        }
    }
    
    show_debug_message("UI管理器資源已清理");
}

// 初始化
initialize();

// 新增：處理顯示戰鬥結果事件
on_show_battle_result = function(data) {
    show_debug_message("===== 顯示戰鬥結果 =====");
    
    // 更新獎勵數據
    rewards.exp = data.exp_gained;
    rewards.gold = data.gold_gained;
    rewards.items_list = data.items_gained;
    rewards.visible = true;
    
    // 更新UI顯示
    if (instance_exists(obj_battle_ui)) {
        obj_battle_ui.show_rewards(rewards.exp, rewards.gold, rewards.items_list);
    }
    
    add_battle_log("顯示戰鬥結果!");
};

// 從UI管理器中移除UI
function remove_ui(ui_instance) {
    if (!instance_exists(ui_instance)) {
        show_debug_message("警告：嘗試移除不存在的UI實例");
        return;
    }
    
    // 檢查數據結構是否有效
    if (!ds_exists(ui_layers, ds_type_map) || !ds_exists(active_ui, ds_type_map)) {
        show_debug_message("警告：UI管理器的數據結構已被銷毀");
        return;
    }
    
    // 從所有層級中移除
    var keys = ds_map_keys_to_array(ui_layers);
    for (var i = 0; i < array_length(keys); i++) {
        var layer_name = keys[i];
        if (ds_exists(ui_layers[? layer_name], ds_type_list)) {
            var ui_list = ui_layers[? layer_name];
            var index = ds_list_find_index(ui_list, ui_instance);
            if (index != -1) {
                ds_list_delete(ui_list, index);
                show_debug_message("UI已從層級 " + layer_name + " 移除");
            }
        }
    }
    
    // 從活躍UI列表中移除
    keys = ds_map_keys_to_array(active_ui);
    for (var i = 0; i < array_length(keys); i++) {
        var layer_name = keys[i];
        if (ds_exists(active_ui[? layer_name], ds_type_list)) {
            var active_list = active_ui[? layer_name];
            var index = ds_list_find_index(active_list, ui_instance);
            if (index != -1) {
                ds_list_delete(active_list, index);
                show_debug_message("UI已從活躍列表中移除");
            }
        }
    }
}