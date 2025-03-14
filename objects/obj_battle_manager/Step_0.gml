// obj_battle_manager 的 Step_0.gml 完整版
// 更新全局召喚冷卻
if (global_summon_cooldown > 0) {
    global_summon_cooldown--;
}

// 根据战斗状态执行不同逻辑
switch (battle_state) {
    case BATTLE_STATE.INACTIVE:
        // 非战斗状态，检测是否需要开始战斗
        // 不需要处理边界
        break;
        
    case BATTLE_STATE.STARTING:
        // 战斗开始过渡 - 边界扩张阶段
        if (battle_boundary_radius < 300) {
            battle_boundary_radius += 10; // 逐渐扩大战斗边界
        } else {
            // 过渡完成，进入准备阶段
            battle_state = BATTLE_STATE.PREPARING;
            show_debug_message("战斗准备阶段开始!" + string(battle_state));
            
            // 初始化全局戰鬥計數器
            if (!variable_global_exists("defeated_enemies_count")) {
                global.defeated_enemies_count = 0;
            } else {
                global.defeated_enemies_count = 0; // 重置計數器
            }
            
            if (!variable_global_exists("defeated_player_units")) {
                global.defeated_player_units = 0;
            } else {
                global.defeated_player_units = 0; // 重置計數器
            }
            
            // 在UI中显示提示
            if (instance_exists(obj_battle_ui)) {
                obj_battle_ui.battle_info = "请召唤单位参战! (按空格键)";
                obj_battle_ui.surface_needs_update = true; // 確保UI更新
                obj_battle_ui.show_info("準備階段開始! 召喚你的怪物!");
            }
        }
        
        // 处理边界
        enforce_battle_boundary();
        break;
        
    case BATTLE_STATE.PREPARING:
        // 战斗准备阶段 - 等待玩家召唤单位
        battle_timer++;
        
        // 检查是否已经召唤了单位或者时间超过限制
        if (ds_list_size(player_units) > 0 || battle_timer > game_get_speed(gamespeed_fps) * 10) {
            // 關閉所有可能開啟的UI
            close_all_active_uis();
            
            // 如果10秒内没有召唤单位，自动召唤一个
            if (ds_list_size(player_units) == 0) {
                var init_summon_x = battle_center_x - 100;
                var init_summon_y = battle_center_y;
                
                // 檢查是否有可用的怪物
                var has_usable_monster = false;
                var monster_type_to_summon = obj_test_summon; // 預設值
                
                if (variable_global_exists("player_monsters") && array_length(global.player_monsters) > 0) {
                    for (var i = 0; i < array_length(global.player_monsters); i++) {
                        if (global.player_monsters[i].hp > 0) {
                            monster_type_to_summon = global.player_monsters[i].type;
                            has_usable_monster = true;
                            break;
                        }
                    }
                }
                
                // 如果有怪物則召喚，否則創建預設怪物
                if (has_usable_monster) {
                    summon_monster(monster_type_to_summon);
                } else {
                    var initial_summon = instance_create_layer(init_summon_x, init_summon_y, "Instances", obj_test_summon);
                    ds_list_add(player_units, initial_summon);
                }
                
                show_debug_message("自动召唤了初始单位!");
                add_battle_log("自動召喚了初始單位");
            }
            
            // 进入战斗阶段
            battle_state = BATTLE_STATE.ACTIVE;
            battle_timer = 0; // 重置战斗计时器
            show_debug_message("战斗正式开始!");
            
            // 更新UI提示
            if (instance_exists(obj_battle_ui)) {
                obj_battle_ui.battle_info = "战斗开始!";
                obj_battle_ui.show_info("戰鬥開始!");
            }
            
            // 通知所有單位
            for (var i = 0; i < ds_list_size(player_units); i++) {
                if (instance_exists(player_units[| i])) {
                    with (player_units[| i]) {
                        atb_current = 0; // 重置ATB
                    }
                }
            }
            
            for (var i = 0; i < ds_list_size(enemy_units); i++) {
                if (instance_exists(enemy_units[| i])) {
                    with (enemy_units[| i]) {
                        atb_current = 0; // 重置ATB
                    }
                }
            }
            
            // 寫入戰鬥日誌
            add_battle_log("戰鬥開始: 玩家單位=" + string(ds_list_size(player_units)) + 
                          ", 敵方單位=" + string(ds_list_size(enemy_units)));
        }
        
        // 处理边界
        enforce_battle_boundary();
        break;
        
    case BATTLE_STATE.ACTIVE:
        // 战斗进行中
        battle_timer++;
        
        // 检查战斗是否应该结束
        if (ds_list_size(player_units) <= 0 || ds_list_size(enemy_units) <= 0) {
            battle_state = BATTLE_STATE.ENDING;
            show_debug_message("战斗结束条件达成!");
            
            // 寫入戰鬥日誌
            if (ds_list_size(player_units) <= 0) {
                add_battle_log("戰鬥失敗: 所有玩家單位被擊敗");
            } else {
                add_battle_log("戰鬥勝利: 所有敵人被擊敗");
            }
        }
        
        // 处理边界
        enforce_battle_boundary();
        
        // 處理捕獲動畫進度
        if (capture_state == "animating") {
            capture_animation++;
            
            // 捕獲動畫結束
            if (capture_animation >= 120) { // 2秒動畫
                // 決定是否成功
                var roll = random(1);
                var capture_chance = 0.5; // 基本捕獲率
                
                // 如果目標存在且HP較低，提高捕獲率
                if (instance_exists(target_enemy)) {
                    capture_chance += (1 - (target_enemy.hp / target_enemy.max_hp)) * 0.4; // 最多額外 +40%
                }
                
                capture_chance = clamp(capture_chance, 0.1, 0.9); // 限制在10%-90%之間
                var success = (roll <= capture_chance);
                
                // 處理捕獲結果
                handle_capture_result(success);
            }
        }
        break;
        
    case BATTLE_STATE.ENDING:
        // 战斗结束过渡 - 缩小战斗边界
        if (battle_boundary_radius > 0) {
            battle_boundary_radius -= 10; // 逐渐缩小战斗边界
        } else {
            // 过渡完成，显示战斗结果
            battle_state = BATTLE_STATE.RESULT;
            show_debug_message("显示战斗结果!");
            
            // 更新戰鬥結果數據
            battle_result.duration = battle_timer / game_get_speed(gamespeed_fps);
            battle_result.defeated_enemies = global.defeated_enemies_count;
            battle_result.victory = (ds_list_size(enemy_units) <= 0);
            
            if (battle_result.victory) {
                // 如果勝利，計算經驗獎勵
                battle_result.exp_gained = battle_result.defeated_enemies * 50 + battle_result.duration;
            } else {
                // 失敗時減少獎勵
                battle_result.exp_gained = floor(battle_result.defeated_enemies * 20);
            }
            
            add_battle_log("戰鬥結束: 時間=" + string_format(battle_result.duration, 3, 1) + 
                          "秒, 擊敗敵人=" + string(battle_result.defeated_enemies));
        }
        
        // 在边界还存在时处理边界
        enforce_battle_boundary();
        break;
        
    case BATTLE_STATE.RESULT:
        // 確保只有這個階段會處理結果
        if (!battle_result_handled) {
            battle_result_handled = true; // 防止重複執行

            if (battle_result.victory) {
                // 戰鬥勝利
                if (instance_exists(obj_battle_ui)) {
                    obj_battle_ui.result_text = "戰鬥勝利!";
                }
                
                // 發放獎勵
                grant_rewards();
            } else {
                // 戰鬥失敗（當場上所有己方怪物死亡才算失敗）
                if (instance_exists(obj_battle_ui)) {
                    obj_battle_ui.result_text = "戰鬥失敗!";
                }
                
                // 處理失敗懲罰
                handle_defeat();
            }
        }

        // 玩家確認後，戰鬥正式結束
        if (keyboard_check_pressed(vk_space)) {
            end_battle();
        }
        break;
}

// 管理单位列表，移除不存在的单位
for (var i = ds_list_size(player_units) - 1; i >= 0; i--) {
    if (!instance_exists(player_units[| i])) {
        ds_list_delete(player_units, i);
    }
}

for (var i = ds_list_size(enemy_units) - 1; i >= 0; i--) {
    if (!instance_exists(enemy_units[| i])) {
        ds_list_delete(enemy_units, i);
    }
}

// 檢查死亡單位 (保險機制)
with (obj_battle_unit_parent) {
    if (hp <= 0 && !dead) {
        // 單位死亡但尚未處理
        dead = true;
        
        // 通知戰鬥管理器
        if (instance_exists(obj_battle_manager)) {
            with (obj_battle_manager) {
                handle_unit_death(other.id);
            }
        } else {
            // 如果找不到戰鬥管理器，直接銷毀
            instance_destroy();
        }
    }
}