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
    // show_debug_message("===== 收到 finalize_battle_results 事件 ====="); // 移除
    // show_debug_message("Received data: " + json_stringify(event_data)); // 移除
    
    // --- 從事件數據中獲取持續時間和擊敗數 ---
    var _defeated_count = variable_struct_get(event_data, "defeated_enemies");
    var _battle_duration = variable_struct_get(event_data, "duration");

    // --- 檢查並更新 battle_result 結構體 --- 
    if (!is_undefined(_defeated_count)) {
        battle_result.defeated_enemies = _defeated_count; // 直接更新結構體
        // show_debug_message("[Reward System] Updated battle_result.defeated_enemies: " + string(battle_result.defeated_enemies)); // 移除
    } else {
        battle_result.defeated_enemies = 0; // 如果未定義，設為0
        show_debug_message("警告 (finalize_battle_results): 未收到 defeated_enemies，battle_result.defeated_enemies 設為 0。");
    }
    
    if (!is_undefined(_battle_duration)) { 
        battle_result.duration = _battle_duration; // 直接更新結構體
        // show_debug_message("[Reward System] Updated battle_result.duration: " + string(battle_result.duration)); // 移除
    } else {
        battle_result.duration = 0; // 如果未定義，設為0
        show_debug_message("警告 (finalize_battle_results): 未收到 duration，battle_result.duration 設為 0。");
    }

    // 根據戰鬥結果（儲存在 reward_system 內部）計算獎勵或懲罰
    if (battle_result.victory) {
        calculate_victory_rewards();
    } else {
        calculate_defeat_penalties();
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

// 計算勝利獎勵
calculate_victory_rewards = function() {
    // 計算經驗值獎勵
    var total_exp = 0;
    
    for (var i = 0; i < battle_result.defeated_enemies; i++) {
        var exp_base = exp_base_value + (5 * battle_result.defeated_enemies); // 每多擊敗一個敵人多加5點基礎經驗
        var exp_variance_amount = exp_base * exp_variance; // 變異範圍
        var exp_gained = exp_base + random_range(-exp_variance_amount, exp_variance_amount);
        
        total_exp += round(exp_gained);
    }
    
    // 額外時間獎勵
    total_exp += battle_result.duration;
    
    // 計算金幣獎勵
    var total_gold = 0;
    
    for (var i = 0; i < battle_result.defeated_enemies; i++) {
        var gold_base = gold_base_value + (2 * battle_result.defeated_enemies); // 每多擊敗一個敵人多加2金幣
        var gold_variance_amount = gold_base * gold_variance; // 變異範圍
        var gold_gained = gold_base + random_range(-gold_variance_amount, gold_variance_amount);
        
        total_gold += round(gold_gained);
    }
    
    // 物品掉落計算
    var item_rewards = [];
    
    for (var i = 0; i < battle_result.defeated_enemies; i++) {
        // 嘗試普通物品掉落
        if (random(1) < item_drop_chance) {
            // 這裡可以根據物品表決定掉落什麼
            // 目前簡化為0-9的ID
            var item_id = irandom(9);
            array_push(item_rewards, {
                id: item_id,
                name: "物品_" + string(item_id),
                rarity: "普通"
            });
        }
        
        // 嘗試稀有物品掉落
        if (random(1) < special_item_chance) {
            var special_item_id = 100 + irandom(9); // 特殊物品ID從100開始
            array_push(item_rewards, {
                id: special_item_id,
                name: "稀有物品_" + string(special_item_id - 100),
                rarity: "稀有"
            });
        }
    }
    
    // 更新獎勵結果
    battle_result.exp_gained = total_exp;
    battle_result.gold_gained = total_gold;
    battle_result.item_drops = item_rewards;
    
    // show_debug_message("[Reward Calc] Processing enemy ID: " + string(enemy_id)); // 可以在循環內移除
    // show_debug_message("[Reward Calc] Fetched template for ID: " + string(enemy_id)); // 移除
    // show_debug_message("[Reward Calc] Template EXP: " + string(template.exp_reward) + ", Gold: " + string(template.gold_reward)); // 移除
    // show_debug_message("[Reward Calc] Total after enemy " + string(enemy_id) + ": EXP=" + string(total_exp) + ", Gold=" + string(total_gold)); // 移除
    // show_debug_message("警告: 未找到 ID 為 " + string(enemy_id) + " 的敵人模板"); // 保留警告
    // show_debug_message("獎勵計算完成: 經驗=" + string(total_exp) + ", 金幣=" + string(total_gold) + ", 物品=" + string(item_drops_count)); // 可以移除，因為會在廣播前顯示最終數據
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
    
    // 添加物品到庫存
    if (variable_global_exists("player_items")) {
        for (var i = 0; i < array_length(battle_result.item_drops); i++) {
            array_push(global.player_items, battle_result.item_drops[i]);
        }
        show_debug_message("獎勵系統: 添加 " + string(array_length(battle_result.item_drops)) + " 個物品到庫存");
    } else {
        global.player_items = [];
        for (var i = 0; i < array_length(battle_result.item_drops); i++) {
            array_push(global.player_items, battle_result.item_drops[i]);
        }
        show_debug_message("獎勵系統: 創建物品庫存並添加 " + string(array_length(battle_result.item_drops)) + " 個物品");
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