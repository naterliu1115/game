// obj_ui_manager - Create_0.gml
// UI層級管理
ui_layers = ds_map_create();
ds_map_add(ui_layers, "main", ds_list_create());      // 主要UI層（互斥）
ds_map_add(ui_layers, "overlay", ds_list_create());   // 浮層UI層（可獨立顯示）
ds_map_add(ui_layers, "hud", ds_list_create());       // HUD層（常駐顯示）
ds_map_add(ui_layers, "popup", ds_list_create());     // 彈窗層（最高層級）

// 層級深度設定（數字越小越上層）
layer_depths = ds_map_create();
ds_map_add(layer_depths, "main", -100);
ds_map_add(layer_depths, "overlay", -150);
ds_map_add(layer_depths, "hud", -200);
ds_map_add(layer_depths, "popup", -250);

// 當前活躍的UI（按層級）
active_ui = ds_map_create();
ds_map_add(active_ui, "main", noone);
ds_map_add(active_ui, "overlay", noone);
ds_map_add(active_ui, "hud", noone);
ds_map_add(active_ui, "popup", noone);

// 註冊UI到對應層級 - 修正參數類型問題
register_ui = function(ui_inst, layer_name) {
    if (ds_map_exists(ui_layers, layer_name)) {
        var ui_list = ui_layers[? layer_name];
        // 確保不重複添加
        for (var i = 0; i < ds_list_size(ui_list); i++) {
            if (ui_list[| i] == ui_inst) return;
        }
        ds_list_add(ui_list, ui_inst);
        show_debug_message("UI註冊成功: " + object_get_name(ui_inst.object_index) + " 到 " + layer_name + " 層");
    } else {
        show_debug_message("UI註冊失敗: 找不到層級 " + layer_name);
    }
}

// 顯示指定UI，確保層級內互斥 - 修正參數類型問題
show_ui = function(layer_name, ui_inst) {
    if (!ds_map_exists(ui_layers, layer_name)) {
        show_debug_message("顯示UI失敗: 找不到層級 " + layer_name);
        return false;
    }
    
    // 檢查UI是否存在且已註冊
    var ui_exists = false;
    var ui_list = ui_layers[? layer_name];
    for (var i = 0; i < ds_list_size(ui_list); i++) {
        if (ui_list[| i] == ui_inst) {
            ui_exists = true;
            break;
        }
    }
    
    if (!ui_exists) {
        // 自動註冊UI
        register_ui(ui_inst, layer_name);
        show_debug_message("UI自動註冊: " + object_get_name(ui_inst.object_index) + " 到 " + layer_name + " 層");
    }
    
    // 如果層級要求互斥（main和popup層）
    if (layer_name == "main" || layer_name == "popup") {
        // 關閉同層所有UI
        for (var i = 0; i < ds_list_size(ui_list); i++) {
            var other_ui = ui_list[| i];
            if (instance_exists(other_ui) && other_ui != ui_inst) {
                if (variable_instance_exists(other_ui, "hide")) {
                    with (other_ui) {
                        hide();
                    }
                } else {
                    with (other_ui) {
                        visible = false;
                        active = false;
                    }
                }
            }
        }
    }
    
    // 顯示指定UI
    if (instance_exists(ui_inst)) {
        // 記錄當前活躍UI
        active_ui[? layer_name] = ui_inst;
        
        // 設置正確的深度
        var depth_value = layer_depths[? layer_name];
        ui_inst.depth = depth_value;
        
        // 調用UI的show方法
        if (variable_instance_exists(ui_inst, "show")) {
            with (ui_inst) {
                show();
            }
        } else {
            with (ui_inst) {
                visible = true;
                active = true;
            }
        }
        
        show_debug_message("顯示UI: " + object_get_name(ui_inst.object_index) + " 在 " + layer_name + " 層");
        return true;
    }
    
    show_debug_message("顯示UI失敗: UI物件不存在");
    return false;
}

// 隱藏指定UI
hide_ui = function(ui_inst) {
    if (instance_exists(ui_inst)) {
        if (variable_instance_exists(ui_inst, "hide")) {
            with (ui_inst) {
                hide();
            }
        } else {
            with (ui_inst) {
                visible = false;
                active = false;
            }
        }
        
        // 更新活躍UI記錄
        var layer_keys = ds_map_keys_to_array(active_ui);
        for (var i = 0; i < array_length(layer_keys); i++) {
            var layer_name = layer_keys[i];
            if (active_ui[? layer_name] == ui_inst) {
                active_ui[? layer_name] = noone;
            }
        }
        
        show_debug_message("隱藏UI: " + object_get_name(ui_inst.object_index));
        return true;
    }
    
    show_debug_message("隱藏UI失敗: UI物件不存在");
    return false;
}

// 隱藏指定層級的所有UI
hide_layer = function(layer_name) {
    if (!ds_map_exists(ui_layers, layer_name)) {
        show_debug_message("隱藏層級失敗: 找不到層級 " + layer_name);
        return false;
    }
    
    var ui_list = ui_layers[? layer_name];
    for (var i = 0; i < ds_list_size(ui_list); i++) {
        var ui_inst = ui_list[| i];
        if (instance_exists(ui_inst)) {
            if (variable_instance_exists(ui_inst, "hide")) {
                with (ui_inst) {
                    hide();
                }
            } else {
                with (ui_inst) {
                    visible = false;
                    active = false;
                }
            }
        }
    }
    
    active_ui[? layer_name] = noone;
    show_debug_message("隱藏層級: " + layer_name);
    return true;
}

// 清理函數 - 在Room結束時調用
cleanup = function() {
    var layers = ds_map_keys_to_array(ui_layers);
    for (var i = 0; i < array_length(layers); i++) {
        var layer_name = layers[i];
        var ui_list = ui_layers[? layer_name];
        if (ds_exists(ui_list, ds_type_list)) {
            ds_list_destroy(ui_list);
        }
    }
    
    if (ds_exists(ui_layers, ds_type_map)) {
        ds_map_destroy(ui_layers);
    }
    
    if (ds_exists(layer_depths, ds_type_map)) {
        ds_map_destroy(layer_depths);
    }
    
    if (ds_exists(active_ui, ds_type_map)) {
        ds_map_destroy(active_ui);
    }
}

// 初始註冊已知的UI物件 - 只有在實例存在時才註冊
if (instance_exists(obj_battle_ui)) register_ui(obj_battle_ui, "main");
if (instance_exists(obj_summon_ui)) register_ui(obj_summon_ui, "main");
if (instance_exists(obj_monster_manager_ui)) register_ui(obj_monster_manager_ui, "main");
if (instance_exists(obj_capture_ui)) register_ui(obj_capture_ui, "overlay");