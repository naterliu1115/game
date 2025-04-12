// obj_reward_system - Create_0.gml

// 獎勵設置
exp_base_value = 25;           // 每擊敗一個敵人的基礎經驗值
exp_variance = 0.2;            // 經驗值隨機變化範圍 (±20%)
gold_base_value = 10;          // 每擊敗一個敵人的基礎金幣
gold_variance = 0.3;           // 金幣隨機變化範圍 (±30%)
item_drop_chance = 0.1;        // 基礎物品掉落機率 (10%)
special_item_chance = 0.03;    // 稀有物品掉落機率 (3%)

// 戰鬥結果數據
battle_result = {
    victory: false,
    duration: 0,
    exp_gained: 0,
    gold_gained: 0,
    item_drops: [],
    defeated_enemies: 0,
    player_units_defeated: 0
};

// 初始化
function initialize() {
    // 重置戰鬥結果
    battle_result = {
        victory: false,
        duration: 0,
        exp_gained: 0,
        gold_gained: 0,
        item_drops: [],
        defeated_enemies: 0,
        player_units_defeated: 0
    };
    
    // 訂閱相關事件
    if (instance_exists(obj_event_manager)) {
        with (obj_event_manager) {
            // subscribe_to_event("battle_end", other.id, "on_battle_end"); // <-- 移除對 battle_end 的訂閱
            subscribe_to_event("all_enemies_defeated", other.id, "on_all_enemies_defeated");
            subscribe_to_event("all_player_units_defeated", other.id, "on_all_player_units_defeated");
            // 新增：訂閱 finalize_battle_results 事件
            subscribe_to_event("finalize_battle_results", other.id, "on_finalize_battle_results");
        }
    }
    
    show_debug_message("獎勵系統已初始化");
}

// 處理戰鬥結束事件 <-- 移除這個函數
/* // <-- 開始註解
on_battle_end = function(data) {
    // 更新持續時間
    if (variable_struct_exists(data, "duration")) {
        battle_result.duration = data.duration;
    }
    
    // 更新擊敗數量
    if (variable_global_exists("defeated_enemies_count")) {
        battle_result.defeated_enemies = global.defeated_enemies_count;
    }
    
    if (variable_global_exists("defeated_player_units")) {
        battle_result.player_units_defeated = global.defeated_player_units;
    }
    
    // 根據勝負計算獎勵
    if (battle_result.victory) {
        calculate_victory_rewards();
    } else {
        calculate_defeat_penalties();
    }
    
    // 發送獎勵已計算事件
    _event_broadcaster("rewards_calculated", battle_result);
    show_debug_message("[Reward System] Broadcasted rewards_calculated event with data: " + json_stringify(battle_result));
};
*/ // <-- 結束註解

// 新增：處理最終計算獎勵事件
on_finalize_battle_results = function(event_data) {
    show_debug_message("===== 收到 finalize_battle_results 事件 ======"); // 增加調試信息
    show_debug_message("Received data: " + json_stringify(event_data)); // 增加調試信息
    
    // --- 從事件數據中獲取必要數據 ---
    var _defeated_count = variable_struct_get(event_data, "defeated_enemies");
    var _battle_duration = variable_struct_get(event_data, "duration");
    var _defeated_ids = variable_struct_get(event_data, "defeated_enemy_ids"); // <-- 獲取 ID 列表

    // --- 檢查並更新 battle_result 結構體 --- 
    if (!is_undefined(_defeated_count)) {
        battle_result.defeated_enemies = _defeated_count;
    } else {
        battle_result.defeated_enemies = 0;
        show_debug_message("警告 (finalize_battle_results): 未收到 defeated_enemies，battle_result.defeated_enemies 設為 0。");
    }
    
    if (!is_undefined(_battle_duration)) { 
        battle_result.duration = _battle_duration;
    } else {
        battle_result.duration = 0;
        show_debug_message("警告 (finalize_battle_results): 未收到 duration，battle_result.duration 設為 0。");
    }
    
    // 檢查 ID 列表是否有效
    if (!is_array(_defeated_ids)) {
        show_debug_message("警告 (finalize_battle_results): 未收到有效的 defeated_enemy_ids 列表。將使用空列表計算獎勵。");
        _defeated_ids = []; // 使用空列表避免錯誤
    }

    // 根據戰鬥結果（儲存在 reward_system 內部）計算獎勵或懲罰
    if (battle_result.victory) {
        calculate_victory_rewards(_defeated_ids); // <-- 傳遞 ID 列表
    } else {
        calculate_defeat_penalties(); // 失敗邏輯保持不變
    }

    // 發送獎勵已計算事件 (現在 battle_result 應該是正確的)
    _event_broadcaster("rewards_calculated", battle_result);
    show_debug_message("[Reward System] Broadcasted rewards_calculated event with data: " + json_stringify(battle_result)); // 保留關鍵信息
};

// 處理所有敵人被擊敗事件
on_all_enemies_defeated = function(data) {
    battle_result.victory = true;
    show_debug_message("獎勵系統: 檢測到勝利條件");
};

// 處理所有玩家單位被擊敗事件
on_all_player_units_defeated = function(data) {
    battle_result.victory = false;
    show_debug_message("獎勵系統: 檢測到失敗條件");
};

// 計算勝利獎勵 (重構)
calculate_victory_rewards = function(defeated_enemy_ids) { // <-- 接收 ID 列表
    show_debug_message("[Reward Calc] 開始計算勝利獎勵，基於 ID 列表: " + json_stringify(defeated_enemy_ids));

    // 初始化獎勵
    battle_result.exp_gained = 0;
    battle_result.gold_gained = 0;
    battle_result.item_drops = []; // 重置物品掉落列表

    // 檢查敵人工廠是否存在
    if (!instance_exists(obj_enemy_factory)) {
        show_debug_message("錯誤：無法計算獎勵，obj_enemy_factory 不存在！");
        return;
    }
    
    // 檢查物品管理器是否存在 (用於驗證物品ID，可選)
    var _item_manager_exists = instance_exists(obj_item_manager);

    // 遍歷被擊敗的敵人ID
    for (var i = 0; i < array_length(defeated_enemy_ids); i++) {
        var enemy_id = defeated_enemy_ids[i];
        // show_debug_message("[Reward Calc] Processing enemy ID: " + string(enemy_id)); // <-- 可以註解掉

        // 從工廠獲取敵人模板
        var template = obj_enemy_factory.get_enemy_template(enemy_id);
        // === 新增除錯：打印在 Reward System 中實際收到的模板 ===
        // show_debug_message("  [Reward Calc IN FUNCTION] Template received for ID " + string(enemy_id) + ": " + json_stringify(template)); // <-- 註解掉
        // === 除錯結束 ===

        if (is_struct(template)) {
            // show_debug_message("[Reward Calc] Fetched template for ID: " + string(enemy_id)); // <-- 可以註解掉

            // --- 恢復簡潔檢查，使用 is_real --- 
            // 累加經驗值 (確保是數字)
            if (variable_struct_exists(template, "exp_reward") && is_real(template.exp_reward)) {
                battle_result.exp_gained += template.exp_reward; // 直接使用，因為它已經是數字
                // show_debug_message("  - EXP Reward Added: " + string(template.exp_reward)); // <-- 可以註解掉
            } else {
                 // show_debug_message("  - 警告: 模板 exp_reward 無效、不存在或不是數字"); // <-- 保留警告
            }

            // 累加金幣 (確保是數字)
            if (variable_struct_exists(template, "gold_reward") && is_real(template.gold_reward)) {
                battle_result.gold_gained += template.gold_reward; // 直接使用
                // show_debug_message("  - Gold Reward Added: " + string(template.gold_reward)); // <-- 可以註解掉
            } else {
                 // show_debug_message("  - 警告: 模板 gold_reward 無效、不存在或不是數字"); // <-- 保留警告
            }
            // --- 檢查結束 ---

            // 處理物品掉落 (loot_table)
            if (variable_struct_exists(template, "loot_table") && is_string(template.loot_table) && template.loot_table != "") {
                var loot_table_string = template.loot_table;
                // show_debug_message("  - Loot Table: " + loot_table_string); // <-- 可以註解掉
                
                // 按分號分割掉落項
                var drop_entries = string_split(loot_table_string, ";"); 
                
                for (var j = 0; j < array_length(drop_entries); j++) {
                    var entry = drop_entries[j];
                    if (entry == "") continue; // 跳過空條目
                    
                    // 按冒號分割掉落項的細節
                    var details = string_split(entry, ":");
                    
                    if (array_length(details) == 3) {
                        var item_id_str = details[0];
                        var chance_str = details[1];
                        var range_str = details[2];
                        
                        // 解析 Item ID
                        if (!is_numeric_safe(item_id_str)) {
                            show_debug_message("    - 警告: Loot table entry '" + entry + "' - 無效的 item_id: " + item_id_str);
                            continue;
                        }
                        var item_id = real(item_id_str);
                        
                        // (可選) 驗證 Item ID
                        if (_item_manager_exists && !obj_item_manager.item_exists(item_id)) {
                             show_debug_message("    - 警告: Loot table entry '" + entry + "' - 物品 ID " + string(item_id) + " 在 obj_item_manager 中不存在");
                             // 根據遊戲設計決定是否 continue 或允許掉落不存在的物品
                             // continue; 
                        }

                        // 解析 Chance (機率)
                        if (!is_numeric_safe(chance_str)) {
                            show_debug_message("    - 警告: Loot table entry '" + entry + "' - 無效的 chance: " + chance_str);
                            continue;
                        }
                        var chance = clamp(real(chance_str), 0, 1); // 確保機率在 0 到 1 之間

                        // 解析 Min-Max Range (數量範圍)
                        var min_qty = 1;
                        var max_qty = 1;
                        var range_parts = string_split(range_str, "-");
                        
                        if (array_length(range_parts) == 1) {
                            if (is_numeric_safe(range_parts[0])) {
                                min_qty = max(1, real(range_parts[0])); // 確保至少為 1
                                max_qty = min_qty;
                            } else {
                                show_debug_message("    - 警告: Loot table entry '" + entry + "' - 無效的 quantity: " + range_parts[0]);
                                continue;
                            }
                        } else if (array_length(range_parts) == 2) {
                            if (is_numeric_safe(range_parts[0]) && is_numeric_safe(range_parts[1])) {
                                min_qty = max(1, real(range_parts[0]));
                                max_qty = max(min_qty, real(range_parts[1])); // 確保 max >= min >= 1
                            } else {
                                show_debug_message("    - 警告: Loot table entry '" + entry + "' - 無效的 range: " + range_str);
                                continue;
                            }
                        } else {
                            show_debug_message("    - 警告: Loot table entry '" + entry + "' - 無效的 range 格式: " + range_str);
                            continue;
                        }

                        // show_debug_message("    - Parsed Entry: ItemID=" + string(item_id) + ", Chance=" + string(chance) + ", MinQty=" + string(min_qty) + ", MaxQty=" + string(max_qty)); // <-- 可以註解掉

                        // 進行掉落判定
                        if (random(1) < chance) {
                            var quantity_dropped = irandom_range(min_qty, max_qty);
                            // show_debug_message("      * Drop Success! Quantity: " + string(quantity_dropped)); // <-- 可以註解掉
                            
                            array_push(battle_result.item_drops, { item_id: item_id, quantity: quantity_dropped });

                        } else {
                             // show_debug_message("      * Drop Failed (Chance: " + string(chance) + ")"); // <-- 可以註解掉
                        }
                        
                    } else {
                        show_debug_message("    - 警告: Loot table entry '" + entry + "' 格式錯誤 (需要3個部分，用':'分割)"); // <-- 保留警告
                    }
                }
            } else {
                 // show_debug_message("  - 該敵人沒有 loot_table 或為空"); // 可以移除
            }

        } else {
            show_debug_message("警告: 未找到 ID 為 " + string(enemy_id) + " 的敵人模板，無法計算其獎勵"); // <-- 保留警告
        }
        
        // show_debug_message("[Reward Calc] Total after enemy " + string(enemy_id) + ": EXP=" + string(battle_result.exp_gained) + ", Gold=" + string(battle_result.gold_gained) + ", Items=" + json_stringify(battle_result.item_drops)); // <-- 可以註解掉
    }
    
    show_debug_message("獎勵計算完成: 經驗=" + string(battle_result.exp_gained) + ", 金幣=" + string(battle_result.gold_gained) + ", 物品=" + string(array_length(battle_result.item_drops)) + " 種"); // <-- 保留最終結果
};

// 計算失敗懲罰
calculate_defeat_penalties = function() {
    // 經驗值減少
    var partial_exp = 0;
    
    if (battle_result.defeated_enemies > 0) {
        // 即使失敗，也給予部分經驗（但比勝利少）
        var exp_base = exp_base_value * 0.5; // 基礎經驗減半
        for (var i = 0; i < battle_result.defeated_enemies; i++) {
            partial_exp += round(exp_base + random_range(-exp_base * 0.1, exp_base * 0.1));
        }
    }
    
    // 金幣損失
    var gold_loss = 0;
    if (variable_global_exists("player_gold") && global.player_gold > 0) {
        gold_loss = round(global.player_gold * 0.1); // 損失10%金幣
        global.player_gold = max(0, global.player_gold - gold_loss);
    }
    
    // 更新結果
    battle_result.exp_gained = partial_exp;
    battle_result.gold_gained = -gold_loss; // 負數表示損失
    battle_result.item_drops = []; // 失敗不掉落物品
    
    // show_debug_message("[Reward Calc] Calculating defeat penalties."); // 移除
    // show_debug_message("失敗懲罰計算完成: 部分經驗=" + string(exp_penalty) + ", 金幣損失=" + string(gold_penalty)); // 可以移除
    
    // **確保即使計算完成也廣播帶有 victory: false 的事件**
    // （移動廣播點到 grant_rewards 或 handle_defeat_effects 末尾可能更合適，但暫時在此添加）
    // _event_broadcaster("battle_defeat_handled", { 
    //     gold_loss: gold_loss, 
    //     victory: false 
    // }); 
};

// 發放獎勵
grant_rewards = function() {
    if (!battle_result.victory) {
        handle_defeat_effects(); // 失敗時調用失敗處理
        return; // 失敗不執行後續的獎勵發放
    }
    
    // 增加玩家金錢
    if (variable_global_exists("player_gold")) {
        global.player_gold += battle_result.gold_gained;
        show_debug_message("獎勵系統: 添加 " + string(battle_result.gold_gained) + " 金幣，總計: " + string(global.player_gold));
    } else {
        global.player_gold = battle_result.gold_gained;
    }
    
    // 分配經驗值
    distribute_experience();
    
    // 添加物品到庫存 (需要修改以處理新的 item_drops 格式)
    if (variable_global_exists("player_items")) {
        for (var i = 0; i < array_length(battle_result.item_drops); i++) {
            var drop = battle_result.item_drops[i];
            if (is_struct(drop) && variable_struct_exists(drop, "item_id") && variable_struct_exists(drop, "quantity")) {
                 var _item_id = drop.item_id;
                 var _quantity = drop.quantity;
                 
                 // 調用物品管理器添加物品 (假設有 add_item_to_inventory 函數)
                 obj_item_manager.add_item_to_inventory(_item_id, _quantity); 
                 show_debug_message("獎勵系統: 添加 " + string(_quantity) + " 個物品 ID: " + string(_item_id) + " 到庫存");
            } else {
                 show_debug_message("獎勵系統: 警告: item_drops 中發現無效的條目: " + json_stringify(drop));
            }
        }
    } else {
        global.player_items = [];
        for (var i = 0; i < array_length(battle_result.item_drops); i++) {
            var drop = battle_result.item_drops[i];
            if (is_struct(drop) && variable_struct_exists(drop, "item_id") && variable_struct_exists(drop, "quantity")) {
                 var _item_id = drop.item_id;
                 var _quantity = drop.quantity;
                 
                 // 調用物品管理器添加物品 (假設有 add_item_to_inventory 函數)
                 obj_item_manager.add_item_to_inventory(_item_id, _quantity); 
                 show_debug_message("獎勵系統: 創建物品庫存並添加 " + string(_quantity) + " 個物品 ID: " + string(_item_id));
            } else {
                 show_debug_message("獎勵系統: 警告: item_drops 中發現無效的條目: " + json_stringify(drop));
            }
        }
    }
    
    // 發送獎勵已分發事件
    _event_broadcaster("rewards_granted", battle_result);
    
    // 通知UI顯示獎勵
    /*
    if (instance_exists(obj_battle_ui)) {
        // 確保 item_drops 是一個數組
        if (!is_array(battle_result.item_drops)) {
            battle_result.item_drops = [];
        }
        
        obj_battle_ui.show_rewards(
            battle_result.victory, 
            battle_result.duration, 
            battle_result.defeated_enemies, 
            battle_result.exp_gained,
            battle_result.gold_gained,
            battle_result.item_drops
        );
        show_debug_message("獎勵系統: 通知UI顯示獎勵");
    }
    */
};

// 處理失敗效果
handle_defeat_effects = function() {
    // 已經在calculate_defeat_penalties中處理了金幣損失
    show_debug_message("獎勵系統: 正在處理失敗效果...");
    
    // 降低怪物HP (保留現有邏輯)
    if (variable_global_exists("player_monsters")) {
        var battle_participants = [];
        if (instance_exists(obj_unit_manager)) {
            with (obj_unit_manager) {
                for (var i = 0; i < ds_list_size(player_units); i++) {
                    var unit = player_units[| i];
                    if (instance_exists(unit)) {
                        // 獲取怪物的基礎 ID 或某種標識符，而不是 object_index
                        if (variable_instance_exists(unit, "monster_id")) { // 假設怪物有 monster_id
                             array_push(battle_participants, unit.monster_id);
                        } else {
                             // 如果沒有 monster_id，使用 object_index 作為後備（可能不準確）
                             array_push(battle_participants, unit.object_index);
                             show_debug_message("警告: 單位 " + string(unit) + " 缺少 monster_id，使用 object_index 作為標識符。");
                        }
                    }
                }
            }
        }

        // 遍歷全局怪物列表
        for (var i = 0; i < array_length(global.player_monsters); i++) {
            var monster_data = global.player_monsters[i];
            // 檢查怪物是否參與了戰鬥
            var participated = false;
            var identifier_to_check = (variable_struct_exists(monster_data, "id")) ? monster_data.id : monster_data.object_index; // 優先使用 id
            for (var j = 0; j < array_length(battle_participants); j++) {
                if (battle_participants[j] == identifier_to_check) {
                    participated = true;
                    break;
                }
            }

            if (participated) {
                // 如果怪物參與了戰鬥並且失敗，降低其當前HP (例如降為1，或按比例)
                if (variable_struct_exists(monster_data, "current_hp")) {
                    var original_hp = monster_data.current_hp;
                    monster_data.current_hp = 1; // 直接設為 1 HP
                    show_debug_message("獎勵系統: 怪物 " + string(identifier_to_check) + " HP 從 " + string(original_hp) + " 降至 1");
                } else {
                     show_debug_message("警告: 怪物數據 " + string(identifier_to_check) + " 缺少 current_hp 欄位。");
                }
            }
        }
        show_debug_message("獎勵系統: 已降低參戰怪物HP");
    }
    
    // **在處理完所有失敗效果後，廣播事件**
    _event_broadcaster("battle_defeat_handled", { 
        gold_loss: abs(battle_result.gold_gained), // 從 battle_result 獲取金幣損失值
        victory: false 
    });
    show_debug_message("獎勵系統: 已廣播 battle_defeat_handled 事件 (victory=false)");
};

// 分配經驗值給參戰單位
distribute_experience = function() {
    if (!instance_exists(obj_unit_manager)) return;
    
    var player_units_count = 0;
    with (obj_unit_manager) {
        player_units_count = ds_list_size(player_units);
    }
    
    if (player_units_count <= 0) return;
    
    var exp_per_unit = battle_result.exp_gained / player_units_count;
    
    with (obj_unit_manager) {
        for (var i = 0; i < ds_list_size(player_units); i++) {
            var unit = player_units[| i];
            if (instance_exists(unit) && variable_instance_exists(unit, "gain_exp")) {
                unit.gain_exp(exp_per_unit);
                
                // 更新玩家怪物數據
                if (variable_global_exists("player_monsters")) {
                    for (var j = 0; j < array_length(global.player_monsters); j++) {
                        var monster_data = global.player_monsters[j];
                        if (monster_data.type == unit.object_index) {
                            // 更新經驗值（游戲可能有自己的升級邏輯）
                            if (!variable_struct_exists(monster_data, "exp")) {
                                monster_data.exp = 0;
                            }
                            monster_data.exp += exp_per_unit;
                            
                            // 檢查是否達到升級條件
                            var next_level_exp = monster_data.level * 100;
                            if (monster_data.exp >= next_level_exp) {
                                level_up_monster(monster_data, unit);
                            }
                            
                            break;
                        }
                    }
                }
            }
        }
    }
    
    show_debug_message("獎勵系統: 每單位分配 " + string(exp_per_unit) + " 經驗值");
};

// 升級怪物
level_up_monster = function(monster_data, unit) {
    monster_data.level++;
    monster_data.exp -= monster_data.level * 100; // 減去升級所需經驗
    
    // 提升屬性
    var hp_increase = irandom_range(5, 15);
    var atk_increase = irandom_range(1, 3);
    var def_increase = irandom_range(1, 2);
    var spd_increase = random(1) < 0.7 ? 1 : 0; // 70%機率增加速度
    
    monster_data.max_hp += hp_increase;
    monster_data.hp = monster_data.max_hp; // 升級時恢復全部HP
    monster_data.attack += atk_increase;
    monster_data.defense += def_increase;
    monster_data.spd += spd_increase;
    
    // 如果單位實例還存在，也更新它的屬性
    if (instance_exists(unit)) {
        unit.max_hp += hp_increase;
        unit.hp = unit.max_hp;
        unit.attack += atk_increase;
        unit.defense += def_increase;
        unit.spd += spd_increase;
    }
    
    // 發送升級事件
    _event_broadcaster("monster_level_up", {
        monster: monster_data,
        new_level: monster_data.level,
        hp_increase: hp_increase,
        atk_increase: atk_increase,
        def_increase: def_increase,
        spd_increase: spd_increase
    });
    
    show_debug_message("獎勵系統: 怪物 " + monster_data.name + " 升到等級 " + string(monster_data.level));
    
    // 檢查是否有連續升級
    if (monster_data.exp >= monster_data.level * 100) {
        level_up_monster(monster_data, unit);
    }
};

// 輔助函數：發送事件消息
_local_broadcast_event = function(event_name, data = {}) {
    if (instance_exists(obj_event_manager)) {
        with (obj_event_manager) {
            handle_event(event_name, data);
        }
    } else {
        show_debug_message("警告: 事件管理器不存在，無法廣播事件: " + event_name);
    }
}

// 將事件廣播方法綁定到實例變數
#region BIND_METHODS
// ... 其他綁定 ...
_event_broadcaster = method(self, _local_broadcast_event); // <-- 修改賦值
// ... 其他綁定 ...
#endregion

// 初始化
initialize();