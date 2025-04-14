// obj_battle_ui - Step_0.gml
// 更新信息提示計時器
if (info_alpha > 0) {
    info_timer--;
    if (info_timer <= 0) {
        // 淡出效果
        info_alpha -= 0.05;
        if (info_alpha < 0) info_alpha = 0;
    }
}

// 檢測鼠標點擊
if (mouse_check_button_pressed(mb_left)) {
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    
    // 檢測是否點擊了召喚按鈕
    if (point_in_rectangle(mx, my, summon_btn_x, summon_btn_y, summon_btn_x + summon_btn_width, summon_btn_y + summon_btn_height)) {
        // 模擬按下空格鍵召喚
        if (instance_exists(obj_battle_manager) && obj_battle_manager.global_summon_cooldown <= 0) {
            with (Player) {
                event_perform(ev_keypress, vk_space);
            }
            
            // 顯示召喚提示
            show_info("正在召喚怪物！");
            
            // 生成按鈕動畫效果
            surface_needs_update = true;
        } else {
            // 如果在冷卻中，顯示提示
            show_info("召喚冷卻中！");
        }
    }
    
    // 檢測是否點擊了戰術按鈕
    if (point_in_rectangle(mx, my, tactics_btn_x, tactics_btn_y, tactics_btn_x + tactics_btn_width, tactics_btn_y + tactics_btn_height)) {
        // 切換戰術模式
        var old_tactic = current_tactic;
        current_tactic = (current_tactic + 1) % 3;
        
        show_debug_message("===== 戰術切換 =====");
        show_debug_message("從 " + string(old_tactic) + " 切換到 " + string(current_tactic));
        
        // 顯示戰術切換提示
        var tactic_name = "";
        var tactic_desc = "";
        switch(current_tactic) {
            case 0: 
                tactic_name = "積極"; 
                tactic_desc = "主動攻擊附近敵人";
                break;
            case 1: 
                tactic_name = "跟隨"; 
                tactic_desc = "跟隨在您身邊，攻擊途中敵人";
                break;
            case 2: 
                tactic_name = "待命"; 
                tactic_desc = "不主動攻擊，只跟隨在您身邊";
                break;
        }
        show_info("戰術已切換至: " + tactic_name + "\n" + tactic_desc);
        
        // 通知所有玩家單位切換戰術
        if (instance_exists(obj_unit_manager)) {
            var units_updated = 0;
            for (var i = 0; i < ds_list_size(obj_unit_manager.player_units); i++) {
                var unit = obj_unit_manager.player_units[| i];
                if (instance_exists(unit)) {
                    var old_mode = unit.ai_mode;
                    switch(current_tactic) {
                        case 0: unit.set_ai_mode(AI_MODE.AGGRESSIVE); break;
                        case 1: unit.set_ai_mode(AI_MODE.FOLLOW); break;
                        case 2: unit.set_ai_mode(AI_MODE.PASSIVE); break;
                    }
                    if (unit.ai_mode != old_mode) {
                        units_updated++;
                        show_debug_message(object_get_name(unit.object_index) + " AI模式從 " + string(old_mode) + " 切換到 " + string(unit.ai_mode));
                    }
                }
            }
            show_debug_message("更新了 " + string(units_updated) + " 個單位的AI模式");
        } else {
            show_debug_message("錯誤：找不到單位管理器");
        }
        show_debug_message("===== 戰術切換完成 =====");
    }
}

// 更新戰鬥信息
/* // <--- 開始註解
if (instance_exists(obj_battle_manager)) {
    // 如果戰鬥狀態變為結果，更新戰鬥結果數據
    if (obj_battle_manager.battle_state == BATTLE_STATE.RESULT) {
        var player_units_left = ds_list_size(obj_battle_manager.player_units);
        var enemy_units_left = ds_list_size(obj_battle_manager.enemy_units);
        
        // 移除對已不存在的 battle_result 的讀寫
        // battle_result.victory = (enemy_units_left <= 0);
        // battle_result.duration = obj_battle_manager.battle_timer / game_get_speed(gamespeed_fps);
        
        // 移除對全局變量的依賴和計算邏輯
        // if (!variable_global_exists("defeated_enemies_count")) {
        //     global.defeated_enemies_count = 0;
        // }
        // battle_result.defeated_enemies = global.defeated_enemies_count;
        
        // 移除經驗值計算邏輯
        // if (battle_result.victory) {
        //     battle_result.exp_gained = battle_result.defeated_enemies * 50 + battle_result.duration;
        // } else {
        //     battle_result.exp_gained = floor(battle_result.defeated_enemies * 20);
        // }
    }
}
*/ // <--- 結束註解

// 檢查surface是否丟失
if (active && !surface_exists(ui_surface)) {
    surface_needs_update = true;
}

// --- 新增：處理戰鬥結果物品懸停與 Popup --- 
if (reward_visible) { // 只在結果畫面顯示時執行
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    
    var prev_hovered_index = hovered_reward_item_index; // 記錄之前的懸停狀態
    hovered_reward_item_index = -1; // 重置當前懸停索引
    
    var list_size = ds_list_size(reward_items_list);
    
    for (var i = 0; i < list_size; i++) {
        var col = i % items_cols;
        var row = floor(i / items_cols);
        
        var item_x = items_start_x + col * items_cell_width;
        var item_y = items_start_y + row * items_cell_height;
        
        // 檢查滑鼠是否在當前物品格子內
        if (point_in_rectangle(mx, my, item_x, item_y, item_x + items_cell_width, item_y + items_cell_height)) {
            hovered_reward_item_index = i;
            break; // 一次只懸停一個
        }
    }
    
    // 根據懸停狀態管理 Popup
    if (hovered_reward_item_index != -1) {
        // 從列表中獲取當前懸停物品的數據
        var current_item_struct = reward_items_list[| hovered_reward_item_index];
        var item_id = current_item_struct.item_id;
        
        // 檢查物品管理器是否存在
        if (instance_exists(obj_item_manager)) {
            // 獲取完整的物品數據
            var item_data_struct = obj_item_manager.get_item(item_id);
            
            if (item_data_struct != undefined) {
                 // --- 修改：使用 UI Manager 管理彈窗 ---
                if (!instance_exists(item_popup_instance)) { 
                    // 創建實例
                    item_popup_instance = instance_create_layer(mx + 15, my + 15, "UI", obj_item_info_popup); // 使用實際的 "UI" 圖層
                    if (instance_exists(item_popup_instance)) { 
                        // 設置數據和位置
                        item_popup_instance.setup_item_data(item_data_struct, -1); 
                        item_popup_instance.x = mx + 15;
                        item_popup_instance.y = my + 15;
                        
                        // 使用 UI 管理器顯示
                        if (instance_exists(obj_ui_manager)) {
                            obj_ui_manager.show_ui(item_popup_instance, "popup");
                            show_debug_message("Item Info Popup shown via UI Manager for item ID: " + string(item_id));
                        } else {
                             show_debug_message("警告：找不到 UI 管理器，彈窗可能無法正常顯示！");
                             item_popup_instance.show(); // 備選方案
                        }
                    } else {
                       item_popup_instance = noone; 
                       show_debug_message("錯誤：創建 Item Info Popup 失敗");
                    }
                } else { // 彈窗已存在，更新位置和數據
                    item_popup_instance.x = mx + 15;
                    item_popup_instance.y = my + 15;
                    
                    // 如果懸停到不同物品，更新數據
                    if (item_popup_instance.item_data == noone || item_popup_instance.item_data.ID != item_id) {
                         item_popup_instance.setup_item_data(item_data_struct, -1);
                         show_debug_message("Item Info Popup updated for item ID: " + string(item_id));
                    }
                }
                 // --- 結束修改 ---
            } else { 
                 // get_item 失敗，關閉彈窗
                 if (instance_exists(item_popup_instance)) {
                      item_popup_instance.close(); // 調用彈窗自己的關閉方法
                      item_popup_instance = noone; // 重置本地追蹤變數
                      show_debug_message("Item Info Popup closed (get_item failed)");
                 }
            }
        } else {
            // 物品管理器不存在，關閉彈窗
            if (instance_exists(item_popup_instance)) {
                 item_popup_instance.close(); // 調用彈窗自己的關閉方法
                 item_popup_instance = noone; // 重置本地追蹤變數
                 show_debug_message("Item Info Popup closed (item manager missing)");
            }
        }
    } else {
        // 滑鼠未懸停，關閉彈窗
        if (instance_exists(item_popup_instance)) {
            item_popup_instance.close(); // 調用彈窗自己的關閉方法
            item_popup_instance = noone; // 重置本地追蹤變數
            show_debug_message("Item Info Popup closed (mouse left items)");
        }
    }
}
// --- 結束新增 --- 

// --- 其他原有的 Step 事件邏輯應該保留 ---