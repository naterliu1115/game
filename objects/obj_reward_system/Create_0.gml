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
            subscribe_to_event("battle_end", other.id, "on_battle_end");
            subscribe_to_event("all_enemies_defeated", other.id, "on_all_enemies_defeated");
            subscribe_to_event("all_player_units_defeated", other.id, "on_all_player_units_defeated");
        }
    }
    
    show_debug_message("獎勵系統已初始化");
}

// 處理戰鬥結束事件
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
    broadcast_event("rewards_calculated", battle_result);
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
    
    // 顯示獎勵日誌
    show_debug_message("獎勵計算完成: 經驗=" + string(total_exp) + 
                     ", 金幣=" + string(total_gold) + 
                     ", 物品=" + string(array_length(item_rewards)));
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
    
    show_debug_message("失敗懲罰計算完成: 部分經驗=" + string(partial_exp) + 
                     ", 金幣損失=" + string(gold_loss));
};

// 發放獎勵
grant_rewards = function() {
    if (!battle_result.victory) {
        handle_defeat_effects();
        return;
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
    broadcast_event("rewards_granted", battle_result);
    
    // 通知UI顯示獎勵
    if (instance_exists(obj_battle_ui)) {
        // 確保 item_drops 是一個數組
        if (!is_array(battle_result.item_drops)) {
            battle_result.item_drops = [];
        }
        
        obj_battle_ui.show_rewards(
            battle_result.exp_gained,
            battle_result.gold_gained,
            battle_result.item_drops
        );
        show_debug_message("獎勵系統: 通知UI顯示獎勵");
    }
};

// 處理失敗效果
handle_defeat_effects = function() {
    // 已經在calculate_defeat_penalties中處理了金幣損失
    
    // 降低怪物HP
    if (variable_global_exists("player_monsters")) {
        // 獲取參加戰鬥的怪物列表
        var battle_participants = [];
        
        if (instance_exists(obj_unit_manager)) {
            with (obj_unit_manager) {
                for (var i = 0; i < ds_list_size(player_units); i++) {
                    var unit = player_units[| i];
                    if (instance_exists(unit)) {
                        array_push(battle_participants, unit.object_index);
                    }
                }
            }
        }
        
        // 降低參戰怪物的HP
        for (var i = 0; i < array_length(global.player_monsters); i++) {
            var monster = global.player_monsters[i];
            
            // 檢查是否參加了戰鬥
            var participated = false;
            for (var j = 0; j < array_length(battle_participants); j++) {
                if (monster.type == battle_participants[j]) {
                    participated = true;
                    break;
                }
            }
            
            if (participated) {
                monster.hp = max(1, floor(monster.hp * 0.5)); // 降低到一半HP，但至少保留1點
            }
        }
        
        show_debug_message("獎勵系統: 已降低參戰怪物HP");
    }
    
    // 通知UI顯示失敗信息
    if (instance_exists(obj_battle_ui)) {
        obj_battle_ui.result_text = "戰鬥失敗!";
        obj_battle_ui.show_info("戰鬥失敗! 損失 " + string(abs(battle_result.gold_gained)) + " 金幣");
    }
    
    // 發送失敗事件
    broadcast_event("battle_defeat_handled", {gold_loss: abs(battle_result.gold_gained)});
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
    broadcast_event("monster_level_up", {
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
broadcast_event = function(event_name, data = {}) {
    if (instance_exists(obj_event_manager)) {
        with (obj_event_manager) {
            handle_event(event_name, data);
        }
    } else {
        show_debug_message("警告: 事件管理器不存在，無法廣播事件: " + event_name);
    }
}

// 初始化
initialize();