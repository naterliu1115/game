// **戰鬥管理器的 Step 事件**
// 更新全局召唤冷却
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
            
            // 在UI中显示提示
            if (instance_exists(obj_battle_ui)) {
                obj_battle_ui.battle_info = "请召唤单位参战! (按空格键)";
				obj_battle_ui.surface_needs_update = true; // 確保UI更新
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
                var initial_summon = instance_create_layer(init_summon_x, init_summon_y, "Instances", obj_test_summon);
                ds_list_add(player_units, initial_summon);
                show_debug_message("自动召唤了初始单位!");
            }
            
            // 进入战斗阶段
            battle_state = BATTLE_STATE.ACTIVE;
            battle_timer = 0; // 重置战斗计时器
            show_debug_message("战斗正式开始!");
            
            // 更新UI提示
            if (instance_exists(obj_battle_ui)) {
                obj_battle_ui.battle_info = "战斗开始!";
            }
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
        }
        
        // 处理边界
        enforce_battle_boundary();
        break;
        
    case BATTLE_STATE.ENDING:
        // 战斗结束过渡 - 缩小战斗边界
        if (battle_boundary_radius > 0) {
            battle_boundary_radius -= 10; // 逐渐缩小战斗边界
        } else {
            // 过渡完成，显示战斗结果
            battle_state = BATTLE_STATE.RESULT;
            show_debug_message("显示战斗结果!");
        }
        
        // 在边界还存在时处理边界
        enforce_battle_boundary();
        break;
        
 case BATTLE_STATE.RESULT:
    // 確保只有這個階段會處理結果
    if (!battle_result_handled) {
        battle_result_handled = true; // 防止重複執行

        if (!instance_exists(obj_enemy_parent)) {
            // 戰鬥勝利
            if (instance_exists(obj_battle_ui)) {
                obj_battle_ui.result_text = "戰鬥勝利!";
            }
            grant_rewards(); // 呼叫發放獎勵的函數
        } else if (ds_list_size(player_units) == 0) {
            // 戰鬥失敗（修正條件，當場上**所有己方怪物死亡**才算失敗）
            if (instance_exists(obj_battle_ui)) {
                obj_battle_ui.result_text = "戰鬥失敗!";
            }
            handle_defeat(); // 處理失敗懲罰
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