// obj_unit_manager - Create_0.gml

// 單位列表
player_units = ds_list_create();   // 玩家方單位列表
enemy_units = ds_list_create();    // 敵方單位列表


target = noone;

// 單位生成相關
max_player_units = 2;              // 最大玩家單位數量
global_summon_cooldown = 0;        // 全局召喚冷卻
max_global_cooldown = 15 * game_get_speed(gamespeed_fps); // 冷卻時間常數

// 單位池（用於優化）
unit_pools = ds_map_create();      // 存儲不同類型單位的對象池

// 單位統計
total_player_units_created = 0;    // 總共創建的玩家單位
total_enemy_units_created = 0;     // 總共創建的敵方單位
total_player_units_defeated = 0;   // 總共被擊敗的玩家單位
total_enemy_units_defeated = 0;    // 總共被擊敗的敵方單位

// 戰鬥區域參數
battle_center_x = 0;        // 戰鬥中心X座標
battle_center_y = 0;        // 戰鬥中心Y座標
battle_boundary_radius = 0; // 戰鬥邊界半徑

// 初始化單位管理器
initialize = function() {
    // 清空單位列表
    ds_list_clear(player_units);
    ds_list_clear(enemy_units);
    
    // 重置冷卻和計數器
    global_summon_cooldown = 0;
    total_player_units_created = 0;
    total_enemy_units_created = 0;
    total_player_units_defeated = 0;
    total_enemy_units_defeated = 0;
    
    // 訂閱相關事件
    if (instance_exists(obj_event_manager)) {
        with (obj_event_manager) {
            subscribe_to_event("battle_start", other.id, other.on_battle_start);
            subscribe_to_event("battle_end", other.id, other.on_battle_end);
            subscribe_to_event("unit_died", other.id, other.handle_unit_death);
        }
    }
}


// 輔助函數：強制單位在戰鬥邊界內
enforce_battle_boundary = function() {
    // 計算不同單位類型的邊界比例 (避免互相重疊)
    var player_boundary_ratio = 0.95; // 玩家保持在邊界95%處
    var ally_boundary_ratio = 0.92;   // 己方單位保持在邊界92%處
    var enemy_boundary_ratio = 0.88;  // 敵方單位保持在邊界88%處
    
    // 限制玩家單位 (召喚物)
    for (var i = 0; i < ds_list_size(player_units); i++) {
        var unit = player_units[| i];
        if (instance_exists(unit)) {
            var dist = point_distance(unit.x, unit.y, battle_center_x, battle_center_y);
            
            // 檢查是否超出邊界
            if (dist > battle_boundary_radius * ally_boundary_ratio) {
                // 將單位推回邊界內
                var dir = point_direction(battle_center_x, battle_center_y, unit.x, unit.y);
                var target_x = battle_center_x + lengthdir_x(battle_boundary_radius * ally_boundary_ratio, dir);
                var target_y = battle_center_y + lengthdir_y(battle_boundary_radius * ally_boundary_ratio, dir);
                
                // 緩慢推回 (用於普通移動)
                unit.x = lerp(unit.x, target_x, 0.15);
                unit.y = lerp(unit.y, target_y, 0.15);
                
                // 特殊處理 - 如果單位具有追蹤AI，則重新設定目標
                if (variable_instance_exists(unit, "ai_mode") && unit.ai_mode == AI_MODE.PURSUIT) {
                    // 重新選擇目標
                    with (unit) {
                        if (variable_instance_exists(id, "find_new_target")) {
                            find_new_target();
                        }
                    }
                }
            }
        }
    }
    
    // 限制敵方單位
    for (var i = 0; i < ds_list_size(enemy_units); i++) {
        var unit = enemy_units[| i];
        if (instance_exists(unit)) {
            var dist = point_distance(unit.x, unit.y, battle_center_x, battle_center_y);
            
            // 檢查是否超出邊界
            if (dist > battle_boundary_radius * enemy_boundary_ratio) {
                // 將單位推回邊界內
                var dir = point_direction(battle_center_x, battle_center_y, unit.x, unit.y);
                var target_x = battle_center_x + lengthdir_x(battle_boundary_radius * enemy_boundary_ratio, dir);
                var target_y = battle_center_y + lengthdir_y(battle_boundary_radius * enemy_boundary_ratio, dir);
                
                // 依據單位類型調整移動方式
                if (variable_instance_exists(unit, "is_boss") && unit.is_boss) {
                    // Boss 單位特殊處理 - 更慢推回，避免打斷技能
                    unit.x = lerp(unit.x, target_x, 0.08);
                    unit.y = lerp(unit.y, target_y, 0.08);
                } else {
                    // 普通敵人 - 正常推回
                    unit.x = lerp(unit.x, target_x, 0.12);
                    unit.y = lerp(unit.y, target_y, 0.12);
                }
                
                // 敵人碰到邊界時的特殊行為
                if (variable_instance_exists(unit, "on_boundary_hit") && 
                    is_method(unit.on_boundary_hit)) {
                    unit.on_boundary_hit();
                } else {
                    // 預設行為 - 重新選擇目標
                    with (unit) {
                        if (variable_instance_exists(id, "find_new_target")) {
                            find_new_target();
                        }
                    }
                }
            }
        }
    }
};




// 設置戰鬥區域
set_battle_area = function(center_x, center_y, radius) {
    battle_center_x = center_x;
    battle_center_y = center_y;
    battle_boundary_radius = radius;
    
    broadcast_event("battle_area_updated", {
        center_x: center_x,
        center_y: center_y,
        radius: radius
    });
}

// 玩家召喚怪物方法
summon_monster = function(monster_type, position_x, position_y) {
    // 檢查是否在戰鬥中
    if (!global.in_battle) return false;
    
    // 檢查是否達到最大單位數量
    if (ds_list_size(player_units) >= max_player_units) {
        broadcast_event("ui_message", {message: "已達最大召喚數量!"});
        return false;
    }
    
    // 檢查冷卻時間
    if (global_summon_cooldown > 0) {
        var cooldown_seconds = global_summon_cooldown / game_get_speed(gamespeed_fps);
        broadcast_event("ui_message", {message: "召喚冷卻中! 剩餘: " + string_format(cooldown_seconds, 1, 1) + "秒"});
        return false;
    }
    
    // 創建單位
    var monster_inst = instance_create_layer(position_x, position_y, "Instances", monster_type);
    total_player_units_created++;
    
    // 設置單位屬性
    apply_monster_stats(monster_inst, monster_type);
    
    // 添加到單位列表
    ds_list_add(player_units, monster_inst);
    
    // 設置冷卻
    global_summon_cooldown = max_global_cooldown;
    
    // 創建召喚特效
    instance_create_layer(position_x, position_y, "Instances", obj_summon_effect);
    
    // 發送召喚完成事件
    broadcast_event("monster_summoned", {
        monster: monster_inst,
        type: monster_type,
        position: {x: position_x, y: position_y}
    });
    
    // 顯示提示訊息
    broadcast_event("ui_message", {message: object_get_name(monster_type) + " 已召喚!"});
    
    return true;
}

// 生成敵人單位
spawn_enemy = function(enemy_type, position_x, position_y) {
    var enemy_inst = instance_create_layer(position_x, position_y, "Instances", enemy_type);
    total_enemy_units_created++;
    
    // 設置敵人屬性
    with (enemy_inst) {
        team = 1; // 敵方隊伍
        initialize(); // 調用敵人自身的初始化方法
    }
    
    // 添加到敵人列表
    ds_list_add(enemy_units, enemy_inst);
    
    // 發送敵人生成事件
    broadcast_event("enemy_spawned", {
        enemy: enemy_inst,
        type: enemy_type,
        position: {x: position_x, y: position_y}
    });
    
    return enemy_inst;
}

// 處理單位死亡
handle_unit_death = function(data) {
    var unit_id = data.unit_id;
    var unit_team = data.team;
    
    // 判斷單位類型並從相應列表中移除
    if (unit_team == 0) { // 玩家單位
        var index = ds_list_find_index(player_units, unit_id);
        if (index != -1) {
            ds_list_delete(player_units, index);
            total_player_units_defeated++;
            
            // 檢查是否所有玩家單位都被擊敗
            if (ds_list_size(player_units) <= 0) {
                broadcast_event("all_player_units_defeated", {});
            }
        }
    } else { // 敵方單位
        var index = ds_list_find_index(enemy_units, unit_id);
        if (index != -1) {
            ds_list_delete(enemy_units, index);
            total_enemy_units_defeated++;
            
            // 檢查是否所有敵人都被擊敗
            if (ds_list_size(enemy_units) <= 0) {
                broadcast_event("all_enemies_defeated", {});
            }
        }
    }
    
    // 發送單位統計更新事件
    broadcast_event("unit_stats_updated", {
        player_units: ds_list_size(player_units),
        enemy_units: ds_list_size(enemy_units),
        player_defeated: total_player_units_defeated,
        enemy_defeated: total_enemy_units_defeated
    });
}

// 更新單位屬性（例如從怪物數據）
apply_monster_stats = function(monster_inst, monster_type) {
    // 查找怪物在玩家怪物列表中的數據
    if (variable_global_exists("player_monsters")) {
        for (var i = 0; i < array_length(global.player_monsters); i++) {
            var monster_data = global.player_monsters[i];
            if (monster_data.type == monster_type) {
                // 設置屬性
                monster_inst.level = monster_data.level;
                monster_inst.hp = monster_data.hp;
                monster_inst.max_hp = monster_data.max_hp;
                monster_inst.attack = monster_data.attack;
                monster_inst.defense = monster_data.defense;
                monster_inst.spd = monster_data.spd;
                monster_inst.team = 0; // 玩家隊伍
                
                // 其他初始化
                monster_inst.atb_current = 0;
                monster_inst.atb_ready = false;
                
                // 如果有技能數據，也可以複製
                if (variable_struct_exists(monster_data, "skills") && is_array(monster_data.skills)) {
                    // 這裡可以添加技能設置邏輯
                }
                
                break;
            }
        }
    }
}

// 清理所有單位
clear_all_units = function() {
    // 銷毀玩家單位
    for (var i = 0; i < ds_list_size(player_units); i++) {
        if (instance_exists(player_units[| i])) {
            instance_destroy(player_units[| i]);
        }
    }
    ds_list_clear(player_units);
    
    // 銷毀敵方單位
    for (var i = 0; i < ds_list_size(enemy_units); i++) {
        if (instance_exists(enemy_units[| i])) {
            instance_destroy(enemy_units[| i]);
        }
    }
    ds_list_clear(enemy_units);
}

// 戰鬥開始響應
on_battle_start = function(data) {
    // 初始化戰鬥區域
    if (variable_struct_exists(data, "center_x") && variable_struct_exists(data, "center_y")) {
        set_battle_area(data.center_x, data.center_y, 0); // 初始半徑為0，會逐漸擴大
    }
    
    // 初始化單位統計
    total_player_units_created = 0;
    total_enemy_units_defeated = 0;
    
    // 確保列表是空的
    clear_all_units();
    
    // 如果有初始敵人，添加到敵人列表
    if (variable_struct_exists(data, "initial_enemy")) {
        ds_list_add(enemy_units, data.initial_enemy);
        
        // 通知敵人進入戰鬥模式
        with (data.initial_enemy) {
            if (variable_instance_exists(id, "enter_battle_mode")) {
                enter_battle_mode();
            }
        }
    }
}

// 戰鬥結束響應
on_battle_end = function(data) {
    // 保存單位狀態到玩家怪物數據
    save_player_units_state();
    
    // 清理單位和戰鬥區域
    clear_all_units();
    battle_boundary_radius = 0;
}

// 保存玩家單位狀態
save_player_units_state = function() {
    if (!variable_global_exists("player_monsters")) return;
    
    for (var i = 0; i < ds_list_size(player_units); i++) {
        var unit = player_units[| i];
        if (instance_exists(unit)) {
            // 更新玩家怪物數據
            for (var j = 0; j < array_length(global.player_monsters); j++) {
                var monster_data = global.player_monsters[j];
                if (monster_data.type == unit.object_index) {
                    // 更新怪物數據
                    monster_data.hp = unit.hp;
                    monster_data.max_hp = unit.max_hp;
                    monster_data.attack = unit.attack;
                    monster_data.defense = unit.defense;
                    monster_data.spd = unit.spd;
                    break;
                }
            }
        }
    }
}

// 嘗試捕捉敵人
try_capture_enemy = function(target) {
    if (!instance_exists(target) || ds_list_find_index(enemy_units, target) == -1) {
        broadcast_event("ui_message", {message: "無效的捕捉目標!"});
        return false;
    }
    
    // 計算捕捉成功率
    var hp_percent = target.hp / target.max_hp;
    var base_chance = 0.8; // 80% 基礎捕捉率
    var chance_modifier = 1 - hp_percent; // HP越低，成功率越高
    
    var final_chance = base_chance + (chance_modifier * 0.3); // 最高額外 +30%
    final_chance = clamp(final_chance, 0.1, 0.95); // 限制在 10% - 95% 之間
    
    // 這裡可以添加捕捉相關事件，讓UI系統處理顯示捕捉動畫等
    broadcast_event("capture_attempt", {
        target: target,
        chance: final_chance,
        hp_percent: hp_percent
    });
    
    return true;
}

// 處理捕捉結果（成功或失敗）
handle_capture_result = function(target, success) {
    if (!instance_exists(target)) return false;
    
    if (success) {
        // 捕捉成功
        var monster_name = object_get_name(target.object_index);
        
        // 將敵人添加到玩家的怪物集合中
        var monster_data = {
            type: target.object_index,
            name: monster_name,
            level: target.level || 1,
            hp: target.hp,
            max_hp: target.max_hp,
            attack: target.attack,
            defense: target.defense,
            spd: target.spd,
            exp: 0,
            skills: [] // 初始化技能為空數組
        };
        
        // 如果敵人有技能，複製技能
        if (variable_instance_exists(target, "skills") && ds_exists(target.skills, ds_type_list)) {
            for (var i = 0; i < ds_list_size(target.skills); i++) {
                array_push(monster_data.skills, target.skills[| i]);
            }
        }
        
        // 將怪物加入到玩家擁有的怪物列表中
        array_push(global.player_monsters, monster_data);
        
        // 顯示成功訊息
        broadcast_event("ui_message", {message: monster_name + " 被成功捕獲!"});
        
        // 從敵人列表中移除
        var index = ds_list_find_index(enemy_units, target);
        if (index != -1) {
            ds_list_delete(enemy_units, index);
        }
        
        // 銷毀敵人實例
        instance_destroy(target);
        
        // 檢查戰鬥結束條件
        if (ds_list_size(enemy_units) <= 0) {
            broadcast_event("all_enemies_defeated", {});
        }
        
        // 發送捕獲成功事件
        broadcast_event("capture_success", {
            target_type: target.object_index,
            monster_name: monster_name
        });
        
        return true;
    } else {
        // 捕捉失敗
        broadcast_event("ui_message", {message: object_get_name(target.object_index) + " 掙脫了!"});
        
        // 敵人可能有反應（例如憤怒狀態）
        with (target) {
            if (variable_instance_exists(id, "on_capture_fail")) {
                on_capture_fail();
            }
        }
        
        // 發送捕獲失敗事件
        broadcast_event("capture_fail", {target: target});
        
        return false;
    }
}

// 查找最近的敵人
find_nearest_enemy = function(source_x, source_y, max_distance = -1) {
    var nearest = noone;
    var min_dist = (max_distance < 0) ? 100000 : max_distance;
    
    for (var i = 0; i < ds_list_size(enemy_units); i++) {
        var enemy = enemy_units[| i];
        if (instance_exists(enemy)) {
            var dist = point_distance(source_x, source_y, enemy.x, enemy.y);
            if (dist < min_dist) {
                min_dist = dist;
                nearest = enemy;
            }
        }
    }
    
    return nearest;
}

// 查找最近的玩家單位
find_nearest_player_unit = function(source_x, source_y, max_distance = -1) {
    var nearest = noone;
    var min_dist = (max_distance < 0) ? 100000 : max_distance;
    
    for (var i = 0; i < ds_list_size(player_units); i++) {
        var unit = player_units[| i];
        if (instance_exists(unit)) {
            var dist = point_distance(source_x, source_y, unit.x, unit.y);
            if (dist < min_dist) {
                min_dist = dist;
                nearest = unit;
            }
        }
    }
    
    return nearest;
}

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