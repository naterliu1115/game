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
                _event_broadcaster("battle_preparing", {});
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
            _event_broadcaster("close_all_ui", {});
            
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
            _event_broadcaster("battle_active", {});
        }
        break;
        
    case BATTLE_STATE.ACTIVE:
        // 戰鬥進行中
        battle_timer++;
        
        // 檢查勝利條件：所有敵人都已死亡
        var all_enemies_defeated = true;
        if (ds_list_size(obj_unit_manager.enemy_units) > 0) { // 確保有敵人
            for (var i = 0; i < ds_list_size(obj_unit_manager.enemy_units); i++) {
                var enemy_id = obj_unit_manager.enemy_units[| i];
                if (instance_exists(enemy_id) && !enemy_id.dead) {
                    all_enemies_defeated = false;
                    break; // 只要有一個敵人活著就不是勝利
                }
            }
        } else {
            all_enemies_defeated = false; // 如果沒有敵人單位列表，不算勝利
        }
        
        if (all_enemies_defeated) {
            show_debug_message("[Battle Manager] 勝利條件達成！");
            battle_result = "VICTORY";
            battle_timer_end = battle_timer; // 記錄結束時間
            // 分配經驗值
            distribute_battle_exp(); 
            // 切換到結束狀態
            battle_state = BATTLE_STATE.ENDING;
            show_debug_message("戰鬥狀態變更：-> ENDING (勝利)");
            // 在這裡觸發勝利相關的事件或UI
            break; // 狀態已改變，跳出 switch
        }
        
        // 檢查失敗條件：所有玩家單位都已死亡
        var all_player_units_defeated = true;
        if (ds_list_size(obj_unit_manager.player_units) > 0) { // 確保有我方單位
            for (var i = 0; i < ds_list_size(obj_unit_manager.player_units); i++) {
                var player_unit_id = obj_unit_manager.player_units[| i];
                if (instance_exists(player_unit_id) && !player_unit_id.dead) {
                    all_player_units_defeated = false;
                    break; // 只要有一個活著就不是失敗
                }
            }
        } else {
             // 如果沒有玩家單位列表，是否算失敗？(根據遊戲設計決定)
             // all_player_units_defeated = true;
             all_player_units_defeated = false; // 暫定不算失敗
        }
        
        if (all_player_units_defeated) {
            show_debug_message("[Battle Manager] 失敗條件達成！");
            battle_result = "DEFEAT";
            battle_timer_end = battle_timer; // 記錄結束時間
            // 失敗通常不分配經驗
             ds_list_clear(defeated_enemies_exp); // 清理可能已記錄的經驗
            // 切換到結束狀態
            battle_state = BATTLE_STATE.ENDING;
            show_debug_message("戰鬥狀態變更：-> ENDING (失敗)");
            // 在這裡觸發失敗相關的事件或UI
            break; // 狀態已改變，跳出 switch
        }
        
        // 安全網檢查 - 每秒檢查一次
        if (battle_timer mod game_get_speed(gamespeed_fps) == 0) {
            if (instance_exists(obj_unit_manager)) {
                var enemy_count = ds_list_size(obj_unit_manager.enemy_units);
                var player_count = ds_list_size(obj_unit_manager.player_units);
                
                show_debug_message("安全網檢查 - 敵人數量: " + string(enemy_count) + ", 玩家單位數量: " + string(player_count));
                
                // 只在戰鬥狀態為 ACTIVE 且超過3秒後才進行安全網檢查
                if (battle_state == BATTLE_STATE.ACTIVE && battle_timer >= game_get_speed(gamespeed_fps) * 3) {
                    // 如果敵人數量為0但沒有觸發結束事件
                    if (enemy_count <= 0) {
                        show_debug_message("警告：安全網檢測到敵人數量為0但戰鬥仍在進行，觸發all_enemies_defeated事件");
                        _event_broadcaster("all_enemies_defeated", {
                            reason: "safety_check_delayed"
                        });
                    }
                    // 如果玩家單位數量為0但沒有觸發結束事件
                    else if (player_count <= 0) {
                        show_debug_message("警告：安全網檢測到玩家單位數量為0但戰鬥仍在進行，觸發all_player_units_defeated事件");
                        _event_broadcaster("all_player_units_defeated", {
                            reason: "safety_check_delayed"
                        });
                    }
                }
            }
        }
        break;
        
    case BATTLE_STATE.ENDING:
        // 戰鬥結束過渡 - 縮小戰鬥邊界
        battle_timer++;
        
        show_debug_message("處理 ENDING 狀態（計時器：" + string(battle_timer) + "）");
        
        // 通知單位管理器更新邊界 (逐漸縮小)
        if (instance_exists(obj_unit_manager)) {
            // 計算應該的邊界半徑
            var shrink_speed = 10;
            var radius = max(0, 300 - (shrink_speed * (battle_timer / game_get_speed(gamespeed_fps)) * 60));
            
            show_debug_message("更新戰鬥邊界 - 當前半徑: " + string(radius));
            
            obj_unit_manager.set_battle_area(
                obj_unit_manager.battle_center_x,
                obj_unit_manager.battle_center_y,
                radius
            );
            
            // 邊界縮小完成，顯示戰鬥結果
            if (radius <= 0) {
                show_debug_message("邊界收縮完成，轉換到 RESULT 狀態");
                battle_state = BATTLE_STATE.RESULT;
                battle_timer = 0;  // 重置計時器
                add_battle_log("顯示戰鬥結果!");
                
                // 發送顯示結果事件
                _event_broadcaster("show_battle_result", {});
            }
        } else {
            show_debug_message("警告：單位管理器不存在，直接轉換到 RESULT 狀態");
            battle_state = BATTLE_STATE.RESULT;
            battle_timer = 0;
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

// 測試用：按F3顯示當前戰鬥狀態
if (keyboard_check_pressed(vk_f3)) {
    var state_names = ["INACTIVE", "STARTING", "PREPARING", "ACTIVE", "ENDING", "RESULT"];
    show_debug_message("===== 當前戰鬥狀態 =====");
    show_debug_message("狀態: " + state_names[battle_state]);
    show_debug_message("計時器: " + string(battle_timer));
    show_debug_message("結果是否已處理: " + string(battle_result_handled));
    if (instance_exists(obj_unit_manager)) {
        show_debug_message("玩家單位數量: " + string(ds_list_size(obj_unit_manager.player_units)));
        show_debug_message("敵方單位數量: " + string(ds_list_size(obj_unit_manager.enemy_units)));
    }
    show_debug_message("========================");
}