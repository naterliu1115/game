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

// --- 修改：處理戰鬥結果物品點擊與 Popup (整合 UI Manager) --- 
if (reward_visible) { 
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    
    // --- 移除懸停相關邏輯 ---
    /* 
    var prev_hovered_index = hovered_reward_item_index; 
    hovered_reward_item_index = -1; 
    
    var list_size = ds_list_size(reward_items_list);
    
    for (var i = 0; i < list_size; i++) {
        // ... (計算 item_x, item_y) ...
        if (point_in_rectangle(mx, my, item_x, item_y, item_x + items_cell_width, item_y + items_cell_height)) {
            hovered_reward_item_index = i;
            break; 
        }
    }
    
    if (hovered_reward_item_index != -1) {
       // ... (之前基於懸停創建/更新彈窗的邏輯) ...
    } else {
        // ... (之前基於滑鼠移開銷毀彈窗的邏輯) ...
    }
    */
    // --- 結束移除懸停相關邏輯 ---

    // --- 新增：處理滑鼠左鍵點擊 ---
    if (mouse_check_button_pressed(mb_left)) {
        var clicked_on_item = false;
        var list_size = ds_list_size(reward_items_list);

        for (var i = 0; i < list_size; i++) {
            var col = i % items_cols;
            var row = floor(i / items_cols);
            
            // 修改：使用 slot 尺寸和 padding 計算格子位置
            var item_x = items_start_x + col * (item_slot_width + item_padding_x);
            var item_y = items_start_y + row * (item_slot_height + item_padding_y);
            
            // 修改：點擊檢測範圍是格子本身
            if (point_in_rectangle(mx, my, item_x, item_y, item_x + item_slot_width, item_y + item_slot_height)) {
                // 點擊到物品格子 i
                clicked_on_item = true;
                selected_reward_item_index = i; // 更新選中索引
                
                // 記錄被點擊格子的座標，用於彈窗定位
                var clicked_cell_x = item_x;
                var clicked_cell_y = item_y;
                
                var current_item_struct = reward_items_list[| i];
                var item_id = current_item_struct.item_id;
                
                if (instance_exists(obj_item_manager)) {
                    var item_data_struct = obj_item_manager.get_item(item_id);
                    
                    if (item_data_struct != undefined) {
                        // 關閉可能已存在的舊彈窗
                        if (instance_exists(item_popup_instance)) {
                            item_popup_instance.close(); // 調用彈窗的 close
                            item_popup_instance = noone;
                            show_debug_message("Existing Item Info Popup closed before opening new one.");
                        }
                        
                        // 創建新彈窗實例
                        item_popup_instance = instance_create_layer(mx + 15, my + 15, "UI", obj_item_info_popup); 
                        
                        if (instance_exists(item_popup_instance)) { 
                            // 設置數據和位置
                            item_popup_instance.setup_item_data(item_data_struct, -1); // 背包索引為 -1
                            
                            // --- 修改：根據格子位置計算彈窗位置，並進行完整的邊界檢測 --- 
                            var gui_width = display_get_gui_width();
                            var gui_height = display_get_gui_height();
                            
                            // 預設位置：格子右上角
                            var popup_target_x = clicked_cell_x + item_slot_width + 5;
                            var popup_target_y = clicked_cell_y - 5;
                            
                            var popup_width = item_popup_instance.width;
                            var popup_height = item_popup_instance.height;
                            
                            // 檢查右邊界
                            if (popup_target_x + popup_width > gui_width) {
                                // 如果右側放不下，嘗試放在格子左側
                                popup_target_x = clicked_cell_x - popup_width - 5;
                                
                                // 如果左側也放不下（超出左邊界），則貼齊左邊界
                                if (popup_target_x < 0) {
                                    popup_target_x = 0;
                                }
                            }
                            
                            // 檢查上邊界
                            if (popup_target_y < 0) {
                                // 如果超出上邊界，改為放在格子下方
                                popup_target_y = clicked_cell_y + item_slot_height + 5;
                                
                                // 如果下方也放不下，則貼齊上邊界
                                if (popup_target_y + popup_height > gui_height) {
                                    popup_target_y = 0;
                                }
                            }
                            
                            // 檢查下邊界
                            if (popup_target_y + popup_height > gui_height) {
                                // 如果超出下邊界，改為放在格子上方
                                popup_target_y = clicked_cell_y - popup_height - 5;
                                
                                // 如果上方也放不下，則貼齊下邊界
                                if (popup_target_y < 0) {
                                    popup_target_y = gui_height - popup_height;
                                }
                            }
                            
                            // 設置最終位置
                            item_popup_instance.x = popup_target_x;
                            item_popup_instance.y = popup_target_y;
                            item_popup_instance.ui_x = popup_target_x;
                            item_popup_instance.ui_y = popup_target_y;
                            // --- 結束彈窗位置計算 --- 
                            
                            // 使用 UI 管理器顯示
                            if (instance_exists(obj_ui_manager)) {
                                obj_ui_manager.show_ui(item_popup_instance, "popup"); // 註冊到 popup 邏輯層
                                show_debug_message("Item Info Popup shown via UI Manager for item ID: " + string(item_id));
                            } else {
                                 show_debug_message("警告：找不到 UI 管理器，彈窗可能無法正常顯示！");
                                 item_popup_instance.show(); // 備選方案
                            }
                        } else {
                           item_popup_instance = noone; 
                           show_debug_message("錯誤：創建 Item Info Popup 失敗");
                        }
                        
                    } else {
                        // get_item 失敗，確保關閉可能存在的彈窗並取消選擇
                        if (instance_exists(item_popup_instance)) {
                            item_popup_instance.close();
                            item_popup_instance = noone;
                        }
                        selected_reward_item_index = -1;
                        show_debug_message("Item Info Popup cannot be shown (get_item failed)");
                    }
                } else {
                     // 物品管理器不存在，確保關閉可能存在的彈窗並取消選擇
                     if (instance_exists(item_popup_instance)) {
                         item_popup_instance.close();
                         item_popup_instance = noone;
                     }
                     selected_reward_item_index = -1;
                     show_debug_message("Item Info Popup cannot be shown (item manager missing)");
                }
                
                surface_needs_update = true; // 標記需要重繪以顯示選擇高亮
                break; // 處理完點擊的格子後退出迴圈
            }
        } // end for loop

        // 如果點擊了但沒有點擊到任何物品格子
        if (!clicked_on_item) {
             selected_reward_item_index = -1; // 取消選擇
             // 關閉可能存在的彈窗
             if (instance_exists(item_popup_instance)) {
                 item_popup_instance.close();
                 item_popup_instance = noone;
                 show_debug_message("Item Info Popup closed (clicked outside items)");
             }
             surface_needs_update = true; // 標記需要重繪以移除高亮
        }
    } // end if mouse_check_button_pressed
    
    // --- 處理彈窗本身的關閉 (ESC 或點擊外部) ---
    if (!instance_exists(item_popup_instance) && item_popup_instance != noone) { // 彈窗被外部銷毀了
         item_popup_instance = noone; // 重置追蹤變數
         selected_reward_item_index = -1; // 新增：取消選擇狀態
         surface_needs_update = true; // 新增：標記重繪以移除高亮
         show_debug_message("Detected popup destroyed externally, resetting selection index.");
    }
    
} // end if reward_visible
// --- 結束修改 --- 

// 檢查surface是否丟失
if (active && !surface_exists(ui_surface)) {
    surface_needs_update = true;
}

// --- 其他原有的 Step 事件邏輯應該保留 ---