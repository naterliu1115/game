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

// --- 其他原有的 Step 事件邏輯應該保留 ---