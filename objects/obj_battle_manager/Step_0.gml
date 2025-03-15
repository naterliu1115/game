// =======================
// Step 事件代碼
// =======================

// obj_battle_manager (重構) - Step_0.gml

// 根據戰鬥狀態執行不同邏輯
switch (battle_state) {
    case BATTLE_STATE.INACTIVE:
        // 非戰鬥狀態，不需要處理
        break;
        
    case BATTLE_STATE.STARTING:
        // 戰鬥開始過渡 - 邊界擴張階段
        battle_timer++;
        
        // 通知單位管理器更新邊界 (逐漸擴大)
        if (instance_exists(obj_unit_manager)) {
            // 獲取所需半徑
            var required_radius = obj_unit_manager.battle_required_radius;
            
            // 逐漸擴大到所需半徑
            var current_radius = min(battle_timer * 10, required_radius);
            
            // 更新結構化變量
            battle_area.boundary_radius = current_radius;
            battle_boundary_radius = current_radius;
            
            obj_unit_manager.set_battle_area(
                battle_area.center_x,
                battle_area.center_y,
                current_radius
            );
            
            // 邊界擴張完成，進入準備階段
            if (current_radius >= required_radius) {
                battle_state = BATTLE_STATE.PREPARING;
                battle_timer = 0;
                
                add_battle_log("戰鬥準備階段開始!");
                
                // 在UI中顯示提示
                if (instance_exists(obj_battle_ui)) {
                    obj_battle_ui.battle_info = "請召喚單位參戰! (按空格鍵)";
                    obj_battle_ui.show_info("準備階段開始! 召喚你的怪物!");
                }
                
                // 發送進入準備階段事件
                broadcast_event("battle_preparing", {});
            }
        }
        break;
        
    case BATTLE_STATE.PREPARING:
        // 戰鬥準備階段 - 等待玩家召喚單位
        battle_timer++;
        
        // 檢查是否已經召喚了單位或者時間超過限制 (10秒)
        var has_units = false;
        if (instance_exists(obj_unit_manager)) {
            has_units = (ds_list_size(obj_unit_manager.player_units) > 0);
        }
        
        if (has_units || battle_timer > game_get_speed(gamespeed_fps) * 10) {
            // 關閉所有可能開啟的UI
            broadcast_event("close_all_ui", {});
            
            // 如果10秒內沒有召喚單位，自動召喚一個
            if (!has_units && instance_exists(obj_unit_manager)) {
                add_battle_log("自動召喚初始單位");
                
                // 讓單位管理器處理自動召喚邏輯
                with (obj_unit_manager) {
                    // 取得戰鬥中心位置
                    var summon_x = battle_center_x - 100;
                    var summon_y = battle_center_y;
                    
                    // 檢查是否有可用的怪物
                    var monster_type = obj_test_summon; // 預設值
                    var found_usable = false;
                    
                    if (variable_global_exists("player_monsters") && array_length(global.player_monsters) > 0) {
                        for (var i = 0; i < array_length(global.player_monsters); i++) {
                            if (global.player_monsters[i].hp > 0) {
                                monster_type = global.player_monsters[i].type;
                                found_usable = true;
                                break;
                            }
                        }
                    }
                    
                    // 召喚怪物或創建預設怪物
                    if (found_usable) {
                        summon_monster(monster_type, summon_x, summon_y);
                    } else {
                        var initial_summon = instance_create_layer(summon_x, summon_y, "Instances", obj_test_summon);
                        ds_list_add(player_units, initial_summon);
                    }
                }
            }
            
            // 進入戰鬥階段
            battle_state = BATTLE_STATE.ACTIVE;
            battle_timer = 0;
            
            add_battle_log("戰鬥正式開始!");
            
            // 更新UI提示
            if (instance_exists(obj_battle_ui)) {
                obj_battle_ui.battle_info = "戰鬥開始!";
                obj_battle_ui.show_info("戰鬥開始!");
            }
            
            // 發送戰鬥開始事件
            broadcast_event("battle_active", {});
        }
        break;
        
    case BATTLE_STATE.ACTIVE:
        // 戰鬥進行中
        battle_timer++;
        
        // 檢查戰鬥結束條件由事件處理 (on_all_enemies_defeated, on_all_player_units_defeated)
        break;
        
    case BATTLE_STATE.ENDING:
        // 戰鬥結束過渡 - 縮小戰鬥邊界
        battle_timer++;
        
        // 通知單位管理器更新邊界 (逐漸縮小)
        if (instance_exists(obj_unit_manager)) {
            // 計算應該的邊界半徑
            var shrink_speed = 10;
            var radius = max(0, 300 - (shrink_speed * (battle_timer / game_get_speed(gamespeed_fps)) * 60));
            
            obj_unit_manager.set_battle_area(
                obj_unit_manager.battle_center_x,
                obj_unit_manager.battle_center_y,
                radius
            );
            
            // 邊界縮小完成，顯示戰鬥結果
            if (radius <= 0) {
                battle_state = BATTLE_STATE.RESULT;
                add_battle_log("顯示戰鬥結果!");
                
                // 發送顯示結果事件
                broadcast_event("show_battle_result", {});
            }
        }
        break;
        
    case BATTLE_STATE.RESULT:
        // 確保只有這個階段會處理結果
        if (!battle_result_handled) {
            battle_result_handled = true;
            
            // 檢查勝負
            var victory = false;
            if (instance_exists(obj_unit_manager)) {
                victory = (ds_list_size(obj_unit_manager.enemy_units) <= 0);
            }
            
            // 發送計算獎勵事件
            if (instance_exists(obj_reward_system)) {
                with (obj_reward_system) {
                    // 發放獎勵
                    grant_rewards();
                }
            }
            
            add_battle_log("戰鬥結果處理完成，勝利: " + string(victory));
        }

        // 玩家確認後，戰鬥正式結束
        if (keyboard_check_pressed(vk_space)) {
            end_battle();
        }
        break;
}

battle_center_x = battle_area.center_x;
battle_center_y = battle_area.center_y;
battle_boundary_radius = battle_area.boundary_radius;