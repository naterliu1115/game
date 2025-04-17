/// @description 註冊戰鬥管理器所有事件 callback function
/// @author AI
function battle_callbacks() {
    on_unit_died = function(data) {
        if (!variable_struct_exists(data, "unit_instance")) {
            show_debug_message("[on_unit_died] 錯誤：事件數據缺少 'unit_instance'！"); return;
        }
        var _unit_instance = data.unit_instance;
        if (!instance_exists(_unit_instance)) {
            show_debug_message("[on_unit_died] 警告：傳入的 unit_instance (ID: " + string(_unit_instance) + ") 已不存在。"); return;
        }
        if (!variable_instance_exists(_unit_instance, "team") || _unit_instance.team != 1) {
            show_debug_message("[on_unit_died] 死亡單位非敵方 (Team: " + (variable_instance_exists(_unit_instance, "team") ? string(_unit_instance.team) : "未知") + ")，忽略掉落計算。"); return;
        }
        enemies_defeated_this_battle += 1;
        show_debug_message("[Battle Manager] 擊敗敵人數 +1，目前: " + string(enemies_defeated_this_battle));
        var _template_id = variable_instance_exists(_unit_instance, "template_id") ? _unit_instance.template_id : undefined;
        if (!is_undefined(_template_id)) {
            array_push(defeated_enemy_ids_this_battle, _template_id);
            show_debug_message("[Battle Manager] 記錄被擊敗敵人的 Template ID: " + string(_template_id));
        } else {
            show_debug_message("[Battle Manager] 警告：死亡單位缺少 template_id，無法記錄。");
        }
        if (!is_undefined(_template_id) && instance_exists(obj_enemy_factory)) {
            var _template = obj_enemy_factory.get_enemy_template(_template_id);
            if (is_struct(_template) && variable_struct_exists(_template, "exp_reward") && is_real(_template.exp_reward)) {
                record_defeated_enemy_exp(_template.exp_reward);
            } else { show_debug_message("[on_unit_died] 無法從模板 ID " + string(_template_id) + " 獲取有效的 exp_reward 來記錄。"); }
        } else { show_debug_message("[on_unit_died] 無法獲取 template_id 或 obj_enemy_factory 不存在，無法記錄經驗。"); }
        if (is_undefined(_template_id) || !instance_exists(obj_enemy_factory)) return;
        var template = obj_enemy_factory.get_enemy_template(_template_id);
        if (!is_struct(template) || !variable_struct_exists(template, "loot_table") || !is_string(template.loot_table) || template.loot_table == "") {
            show_debug_message("[Unit Died Drop Calc] 模板 ID " + string(_template_id) + " 沒有有效的 loot_table，不掉落物品。"); return;
        }
        var loot_table_string = template.loot_table;
        var drop_entries = string_split(loot_table_string, ";");
        var _item_manager_exists = instance_exists(obj_item_manager);
        var is_last_enemy = false;
        if (battle_state == BATTLE_STATE.ACTIVE && instance_exists(obj_unit_manager)) {
            var living_enemy_count = 0;
            for (var i = 0; i < ds_list_size(obj_unit_manager.enemy_units); i++) {
                var enemy_id = obj_unit_manager.enemy_units[| i];
                if (instance_exists(enemy_id) && enemy_id != _unit_instance && !enemy_id.dead) {
                    living_enemy_count++; break;
                }
            }
            if (living_enemy_count == 0) {
                is_last_enemy = true;
                show_debug_message("[Battle Manager] 偵測到最後一個敵人死亡，將標記其掉落物。");
            }
        }
        for (var j = 0; j < array_length(drop_entries); j++) {
            var entry = drop_entries[j];
            if (entry == "") continue;
            var details = string_split(entry, ":");
            if (array_length(details) == 3) {
                var item_id_str = details[0], chance_str = details[1], range_str = details[2];
                var item_id, chance, min_qty, max_qty, quantity_dropped;
                if (!is_numeric_safe(item_id_str)) { show_debug_message("[Unit Died Drop Calc] ! 無效的物品ID格式: '" + item_id_str + "'"); continue; }
                item_id = real(item_id_str);
                if (!is_numeric_safe(chance_str)) { show_debug_message("[Unit Died Drop Calc] ! 無效的機率格式: '" + chance_str + "'"); continue; }
                chance = real(chance_str);
                var range_parts = string_split(range_str, "-");
                if (array_length(range_parts) == 2 && is_numeric_safe(range_parts[0]) && is_numeric_safe(range_parts[1])) {
                    min_qty = real(range_parts[0]); max_qty = real(range_parts[1]);
                    if (min_qty > max_qty) { var temp = min_qty; min_qty = max_qty; max_qty = temp; }
                } else { show_debug_message("[Unit Died Drop Calc] ! 無效的數量範圍格式: '" + range_str + "'"); continue; }
                if (random(1) <= chance) {
                    quantity_dropped = (min_qty == max_qty) ? min_qty : irandom_range(min_qty, max_qty);
                    array_push(current_battle_drops, { item_id: item_id, quantity: quantity_dropped });
                    var item_data = undefined;
                    if (_item_manager_exists) item_data = obj_item_manager.get_item(item_id); else continue;
                    if (is_undefined(item_data)) continue;
                    var _sprite_index = -1;
                    if (_item_manager_exists) _sprite_index = obj_item_manager.get_item_sprite(item_id); else continue;
                    if (sprite_exists(_sprite_index)) {
                        var flying_item_info = { item_id: item_id, quantity: quantity_dropped, sprite_index: _sprite_index,
                                                 start_world_x: _unit_instance.x, start_world_y: _unit_instance.y, source_type: "monster" };
                        array_push(pending_flying_items, flying_item_info);
                    }
                }
            } else { show_debug_message("[Unit Died Drop Calc] ! 格式錯誤: '" + entry + "'"); }
        }
        if (array_length(pending_flying_items) > 0) {
            if (is_last_enemy) {
                processing_last_enemy_drops = true;
                show_debug_message("[Battle Manager] 設置 processing_last_enemy_drops = true");
            }
            alarm[1] = 5;
            show_debug_message("[Drop Anim Trigger] 飛行道具佇列中有 " + string(array_length(pending_flying_items)) + " 個物品，觸發 Alarm[1]。");
        }
    };
    on_unit_stats_updated = function(data) {
        show_debug_message("[on_unit_stats_updated] Received data: " + json_stringify(data));
        if (!is_struct(data)) { show_debug_message("錯誤：單位統計更新事件數據無效 (非 struct)"); return; }
        if (!variable_struct_exists(data, "player_units") || !variable_struct_exists(data, "enemy_units")) {
             show_debug_message("錯誤：單位統計更新事件數據缺少 player_units 或 enemy_units"); return;
        }
        if (battle_state == BATTLE_STATE.ACTIVE) {
            show_debug_message("===== 單位統計更新 =====");
            show_debug_message("玩家單位: " + string(data.player_units));
            show_debug_message("敵方單位: " + string(data.enemy_units));
        }
        if (variable_struct_exists(data, "reason")) { show_debug_message("統計更新原因 (額外欄位): " + string(data.reason)); }
    };
    on_battle_ending = function(data) {
        show_debug_message("===== 收到戰鬥結束事件 =====");
        var _reason = "unknown", _victory = false, _source = "system";
        if (is_struct(data)) {
            if (variable_struct_exists(data, "reason")) _reason = data.reason;
            if (variable_struct_exists(data, "victory")) _victory = data.victory;
            if (variable_struct_exists(data, "source")) _source = data.source;
        } else { show_debug_message("警告: on_battle_ending 收到非 struct 數據"); }
        show_debug_message("勝利: " + string(_victory) + ", 原因: " + string(_reason) + ", 來源: " + string(_source));
        show_debug_message("當前戰鬥狀態: " + string(battle_state));
        battle_state = BATTLE_STATE.ENDING;
        add_battle_log("戰鬥即將結束! 原因: " + string(_reason));
        if (instance_exists(obj_battle_ui)) { obj_battle_ui.show_info(_victory ? "戰鬥勝利!" : "戰鬥失敗!"); }
    };
    on_battle_result_confirmed = function(data) {
        show_debug_message("===== 戰鬥結果已確認 (on_battle_result_confirmed - 可能已棄用) =====");
        // end_battle(); // 不應在此調用 end_battle，改由 on_battle_result_closed 處理
    };
    on_rewards_calculated = function(data) {
        if (is_struct(data)) {
            if (variable_struct_exists(data, "exp_gained")) rewards.exp = data.exp_gained;
            if (variable_struct_exists(data, "gold_gained")) rewards.gold = data.gold_gained;
            if (variable_struct_exists(data, "item_drops")) rewards.items_list = data.item_drops;
            if (variable_struct_exists(data, "defeated_enemies")) enemies_defeated_this_battle = data.defeated_enemies;
            var _victory = variable_struct_exists(data, "victory") ? variable_struct_get(data, "victory") : false;
            var _duration = variable_struct_exists(data, "duration") ? variable_struct_get(data, "duration") : 0;
            _local_broadcast_event("show_battle_result", {
                victory: _victory, battle_duration: _duration, defeated_enemies: enemies_defeated_this_battle,
                exp_gained: rewards.exp, gold_gained: rewards.gold, item_drops: rewards.items_list,
                reason: "rewards_calculated", source: "reward_system"
            });
        } else { show_debug_message("警告: on_rewards_calculated 收到非 struct 數據"); }
    };
    on_all_enemies_defeated = function(data) {
        show_debug_message("===== 收到所有敵人被擊敗事件 =====");
        var _reason = "unknown", _source = "system";
        if (is_struct(data)) {
            if (variable_struct_exists(data, "reason")) _reason = data.reason;
            if (variable_struct_exists(data, "source")) _source = data.source;
        } else { show_debug_message("警告: on_all_enemies_defeated 收到非 struct 數據"); }
        show_debug_message("原因: " + string(_reason) + ", 來源: " + string(_source) + ", 當前狀態: " + string(battle_state));
        if (battle_state == BATTLE_STATE.ACTIVE) {
            final_battle_duration_seconds = battle_timer / game_get_speed(gamespeed_fps);
            battle_state = BATTLE_STATE.ENDING;
            if (instance_exists(obj_battle_ui)) obj_battle_ui.show_info("戰鬥勝利!");
            add_battle_log("所有敵人被擊敗，戰鬥勝利!");
            distribute_battle_exp();
            _local_broadcast_event("battle_ending", { victory: true, reason: "all_enemies_defeated", source: _source });
        } else { show_debug_message("警告：收到敵人被擊敗事件，但戰鬥狀態不是 ACTIVE"); }
        show_debug_message("===== 敵人被擊敗事件處理完成 =====");
    };
    on_all_player_units_defeated = function(data) {
        show_debug_message("===== 收到所有玩家單位被擊敗事件 =====");
        var _reason = "unknown", _source = "system";
        if (is_struct(data)) {
            if (variable_struct_exists(data, "reason")) _reason = data.reason;
            if (variable_struct_exists(data, "source")) _source = data.source;
        } else { show_debug_message("警告: on_all_player_units_defeated 收到非 struct 數據"); }
        show_debug_message("原因: " + string(_reason) + ", 來源: " + string(_source) + ", 當前狀態: " + string(battle_state));
        if (battle_state == BATTLE_STATE.ACTIVE) {
            final_battle_duration_seconds = battle_timer / game_get_speed(gamespeed_fps);
            battle_state = BATTLE_STATE.ENDING;
            if (instance_exists(obj_battle_ui)) obj_battle_ui.show_info("戰鬥失敗!");
            add_battle_log("所有玩家單位被擊敗，戰鬥失敗!");
            _local_broadcast_event("battle_ending", { victory: false, reason: "all_player_units_defeated", source: _source });
        } else { show_debug_message("警告：收到玩家單位被擊敗事件，但戰鬥狀態不是 ACTIVE"); }
        show_debug_message("===== 玩家單位被擊敗事件處理完成 =====");
    };
    on_battle_defeat_handled = function(data) {
        show_debug_message("===== 處理戰鬥失敗 on_battle_defeat_handled =====");
        show_debug_message("Received data: " + json_stringify(data));
        var _victory = false, _gold_loss = 0;
        if (is_struct(data)) {
            if (variable_struct_exists(data, "victory")) _victory = data.victory;
            if (variable_struct_exists(data, "gold_loss")) _gold_loss = data.gold_loss;
        } else { show_debug_message("警告: on_battle_defeat_handled 收到非 struct 數據"); }
        add_battle_log("戰鬥失敗處理完成，勝利: " + string(_victory) + ", 金幣損失: " + string(_gold_loss));
        rewards.visible = true;
        if (instance_exists(obj_battle_ui)) obj_battle_ui.update_rewards_display();
    };
    on_battle_result_closed = function(data) {
        show_debug_message("[Battle Manager] 收到 battle_result_closed 事件");
        if (battle_state == BATTLE_STATE.RESULT) {
             _execute_end_battle_core();
        } else { show_debug_message("警告：收到 battle_result_closed 事件，但狀態不是 RESULT（當前：" + string(battle_state) + "），已忽略。"); }
    };
    on_unit_captured = function(data) {
        if (!variable_struct_exists(data, "unit_instance")) {
            show_debug_message("[on_unit_captured] 錯誤：事件數據缺少 'unit_instance'！"); return;
        }
        var _unit_instance = data.unit_instance;
        if (!instance_exists(_unit_instance)) {
            show_debug_message("[on_unit_captured] 警告：傳入的 unit_instance (ID: " + string(_unit_instance) + ") 已不存在。"); return;
        }

        show_debug_message("[Battle Manager] 收到 unit_captured 事件，處理單位: " + object_get_name(_unit_instance.object_index));

        // 檢查是否為敵方單位 (理論上捕獲的總是敵方，但加個保險)
        if (!variable_instance_exists(_unit_instance, "team") || _unit_instance.team != 1) {
            show_debug_message("[on_unit_captured] 被捕獲單位非敵方 (Team: " + (variable_instance_exists(_unit_instance, "team") ? string(_unit_instance.team) : "未知") + ")，異常情況！");
            instance_destroy(_unit_instance); // 銷毀異常單位
            return;
        }

        // --- 複製 on_unit_died 的核心邏輯 ---
        enemies_defeated_this_battle += 1;
        show_debug_message("[Battle Manager] (Captured) 擊敗敵人數 +1，目前: " + string(enemies_defeated_this_battle));

        var _template_id = variable_instance_exists(_unit_instance, "template_id") ? _unit_instance.template_id : undefined;
        if (!is_undefined(_template_id)) {
            array_push(defeated_enemy_ids_this_battle, _template_id);
            show_debug_message("[Battle Manager] (Captured) 記錄被捕獲敵人的 Template ID: " + string(_template_id));
            
            // 假設捕獲也給經驗 (與 on_unit_died 邏輯保持一致)
            var _exp_value = variable_instance_exists(_unit_instance, "exp_value") ? _unit_instance.exp_value : 0; 
            if (_exp_value > 0) {
                 record_defeated_enemy_exp(_exp_value);
            }
            
            // 注意：捕獲通常不觸發掉落物，所以這裡不複製掉落邏輯
            
        } else {
            show_debug_message("[Battle Manager] (Captured) 警告：被捕獲單位缺少 template_id，無法記錄。" );
        }
        // --- 複製結束 ---

        // 銷毀被捕獲的敵人實例
        show_debug_message("[on_unit_captured] 銷毀被捕獲的實例: " + string(_unit_instance));
        instance_destroy(_unit_instance);
        
        // 檢查是否所有敵人都被擊敗了
        var all_defeated = check_all_enemies_defeated();
        
        // 如果 check_all_enemies_defeated 沒有觸發事件 (返回 false)，但確實沒有敵人了，則手動觸發
        if (!all_defeated && instance_exists(obj_unit_manager)) {
            var enemy_count = ds_list_size(obj_unit_manager.enemy_units);
            show_debug_message("[on_unit_captured] 檢查是否需要手動觸發勝利：敵人數量 = " + string(enemy_count));
            
            if (enemy_count <= 0 && battle_state == BATTLE_STATE.ACTIVE) {
                show_debug_message("[on_unit_captured] 手動觸發 all_enemies_defeated 事件（捕獲後無敵人）");
                _local_broadcast_event("all_enemies_defeated", {
                    reason: "manual_check",
                    source: "capture_system"
                });
            }
        }
    };
} 