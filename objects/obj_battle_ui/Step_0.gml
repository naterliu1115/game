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
        current_tactic = (current_tactic + 1) % 3;
        
        // 顯示戰術切換提示
        var tactic_name = "";
        switch(current_tactic) {
            case 0: tactic_name = "積極"; break;
            case 1: tactic_name = "防守"; break;
            case 2: tactic_name = "追擊"; break;
        }
        show_info("戰術已切換至: " + tactic_name);
        
        // 通知所有玩家單位切換戰術
        if (instance_exists(obj_battle_manager)) {
            for (var i = 0; i < ds_list_size(obj_battle_manager.player_units); i++) {
                var unit = obj_battle_manager.player_units[| i];
                if (instance_exists(unit)) {
                    switch(current_tactic) {
                        case 0: unit.ai_mode = AI_MODE.AGGRESSIVE; break;
                        case 1: unit.ai_mode = AI_MODE.DEFENSIVE; break;
                        case 2: unit.ai_mode = AI_MODE.PURSUIT; break;
                    }
                }
            }
        }
    }
}

// 更新戰鬥信息
if (instance_exists(obj_battle_manager)) {
    // 如果戰鬥狀態變為結果，更新戰鬥結果數據
    if (obj_battle_manager.battle_state == BATTLE_STATE.RESULT) {
        var player_units_left = ds_list_size(obj_battle_manager.player_units);
        var enemy_units_left = ds_list_size(obj_battle_manager.enemy_units);
        
        battle_result.victory = (enemy_units_left <= 0);
        battle_result.duration = obj_battle_manager.battle_timer / game_get_speed(gamespeed_fps);
        
        // 這裡假設有一個全局變量來追蹤擊敗的敵人數量
        if (!variable_global_exists("defeated_enemies_count")) {
            global.defeated_enemies_count = 0;
        }
        battle_result.defeated_enemies = global.defeated_enemies_count;
        
        // 計算經驗值獎勵 (這裡使用一個簡單的公式)
        if (battle_result.victory) {
            battle_result.exp_gained = battle_result.defeated_enemies * 50 + battle_result.duration;
        } else {
            battle_result.exp_gained = floor(battle_result.defeated_enemies * 20);
        }
    }
}

// 檢查surface是否丟失
if (active && !surface_exists(ui_surface)) {
    surface_needs_update = true;
}