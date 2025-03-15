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
battle_required_radius = 300; // 戰鬥所需半徑

// 初始化單位管理器
initialize = function() {
    show_debug_message("===== 初始化單位管理器 =====");
    
    // 清空單位列表
    ds_list_clear(player_units);
    ds_list_clear(enemy_units);
    
    // 重置冷卻和計數器
    global_summon_cooldown = 0;
    total_player_units_created = 0;
    total_enemy_units_created = 0;
    total_player_units_defeated = 0;
    total_enemy_units_defeated = 0;
    
    show_debug_message("檢查事件管理器...");
    // 訂閱相關事件
    var event_manager = instance_find(obj_event_manager, 0);
    if (event_manager != noone) {
        show_debug_message("事件管理器存在，開始訂閱事件");
        
        // 定義事件和回調的映射關係
        var callbacks = {
            battle_start: "on_battle_start",
            battle_end: "on_battle_end",
            unit_died: "handle_unit_death",
            battle_area_updated: "on_battle_area_updated"
        };
        
        // 驗證並訂閱每個事件
        var event_names = variable_struct_get_names(callbacks);
        for (var i = 0; i < array_length(event_names); i++) {
            var event_name = event_names[i];
            var callback_name = callbacks[$ event_name];
            
            if (variable_instance_exists(id, callback_name)) {
                with (event_manager) {
                    subscribe_to_event(event_name, other.id, callback_name);
                }
                show_debug_message("成功訂閱事件: " + event_name + " -> " + callback_name);
            } else {
                show_debug_message("警告：回調函數不存在: " + callback_name);
            }
        }
        
        show_debug_message("事件訂閱完成");
    } else {
        show_debug_message("錯誤：事件管理器不存在");
    }
    
    show_debug_message("===== 單位管理器初始化完成 =====");
}

// 添加battle_area_updated事件處理函數
on_battle_area_updated = function(data) {
    show_debug_message("收到戰鬥區域更新事件：");
    show_debug_message("- 中心點: (" + string(data.center_x) + ", " + string(data.center_y) + ")");
    show_debug_message("- 半徑: " + string(data.radius));
    
    // 更新本地戰鬥區域數據
    battle_center_x = data.center_x;
    battle_center_y = data.center_y;
    battle_boundary_radius = data.radius;
};

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
    show_debug_message("===== 開始召喚怪物 =====");
    
    // 檢查是否在戰鬥中
    if (!global.in_battle) {
        show_debug_message("無法召喚：不在戰鬥中");
        return false;
    }
    
    // 檢查是否達到最大單位數量
    if (ds_list_size(player_units) >= max_player_units) {
        show_debug_message("無法召喚：已達最大召喚數量 " + string(ds_list_size(player_units)) + "/" + string(max_player_units));
        broadcast_event("ui_message", {message: "已達最大召喚數量!"});
        return false;
    }
    
    // 檢查冷卻時間
    if (global_summon_cooldown > 0) {
        var cooldown_seconds = global_summon_cooldown / game_get_speed(gamespeed_fps);
        show_debug_message("無法召喚：冷卻中，剩餘 " + string_format(cooldown_seconds, 1, 1) + " 秒");
        broadcast_event("ui_message", {message: "召喚冷卻中! 剩餘: " + string_format(cooldown_seconds, 1, 1) + "秒"});
        return false;
    }
    
    show_debug_message("創建怪物實例：" + object_get_name(monster_type));
    
    // 創建單位
    var monster_inst = instance_create_layer(position_x, position_y, "Instances", monster_type);
    total_player_units_created++;
    
    show_debug_message("設置怪物屬性");
    
    // 設置單位屬性
    apply_monster_stats(monster_inst, monster_type);
    
    // 確認team值
    with (monster_inst) {
        show_debug_message("確認怪物team值：" + string(team));
        if (team != 0) {
            team = 0;
            show_debug_message("糾正team值為0（玩家方）");
        }
    }
    
    // 添加到單位列表
    ds_list_add(player_units, monster_inst);
    show_debug_message("已添加到玩家單位列表，當前數量：" + string(ds_list_size(player_units)));
    
    // 設置冷卻
    global_summon_cooldown = max_global_cooldown;
    
    // 創建召喚特效
    instance_create_layer(position_x, position_y, "Effects", obj_summon_effect);
    
    // 發送召喚完成事件
    broadcast_event("monster_summoned", {
        monster: monster_inst,
        type: monster_type,
        position: {x: position_x, y: position_y}
    });
    
    // 顯示提示訊息
    broadcast_event("ui_message", {message: object_get_name(monster_type) + " 已召喚!"});
    
    show_debug_message("===== 召喚完成 =====");
    return true;
}

// 生成敵人單位
spawn_enemy = function(enemy_type, position_x, position_y) {
    show_debug_message("===== 開始生成敵人 =====");
    show_debug_message("- 敵人類型: " + object_get_name(enemy_type));
    show_debug_message("- 位置: (" + string(position_x) + ", " + string(position_y) + ")");
    show_debug_message("- 當前敵人列表大小: " + string(ds_list_size(enemy_units)));
    
    // 檢查是否在戰鬥中
    if (!global.in_battle) {
        show_debug_message("警告：不在戰鬥狀態中，無法生成敵人");
        return noone;
    }
    
    var enemy_inst = instance_create_layer(position_x, position_y, "Instances", enemy_type);
    show_debug_message("- 敵人實例創建完成，ID: " + string(enemy_inst));
    
    if (!instance_exists(enemy_inst)) {
        show_debug_message("錯誤：敵人實例創建失敗");
        return noone;
    }
    
    total_enemy_units_created++;
    show_debug_message("- 總敵人創建數: " + string(total_enemy_units_created));
    
    // 設置敵人屬性
    with (enemy_inst) {
        show_debug_message("- 初始化前team值: " + string(team));
        initialize(); // 先調用敵人自身的初始化方法
        show_debug_message("- 初始化後team值: " + string(team));
        team = 1;    // 然後再設置team值，確保不會被初始化覆蓋
        show_debug_message("- 最終team值: " + string(team));
        
        // 確認其他重要屬性
        show_debug_message("- 確認敵人屬性：");
        show_debug_message("  * HP: " + string(hp) + "/" + string(max_hp));
        show_debug_message("  * 攻擊: " + string(attack));
        show_debug_message("  * 防禦: " + string(defense));
        show_debug_message("  * 速度: " + string(spd));
    }
    
    // 添加到敵人列表
    show_debug_message("- 添加到敵人列表前的列表大小: " + string(ds_list_size(enemy_units)));
    ds_list_add(enemy_units, enemy_inst);
    show_debug_message("- 添加到敵人列表後的列表大小: " + string(ds_list_size(enemy_units)));
    
    // 驗證是否成功添加到列表
    var index = ds_list_find_index(enemy_units, enemy_inst);
    if (index == -1) {
        show_debug_message("錯誤：敵人未能成功添加到列表中");
    } else {
        show_debug_message("- 敵人成功添加到列表，索引位置: " + string(index));
    }
    
    // 發送敵人生成事件
    broadcast_event("enemy_spawned", {
        enemy: enemy_inst,
        type: enemy_type,
        position: {x: position_x, y: position_y}
    });
    
    show_debug_message("===== 敵人生成完成 =====");
    return enemy_inst;
};

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
    show_debug_message("===== 開始設置怪物屬性 =====");
    
    // 首先調用初始化
    with (monster_inst) {
        initialize();
    }
    
    // 查找怪物在玩家怪物列表中的數據
    if (variable_global_exists("player_monsters")) {
        for (var i = 0; i < array_length(global.player_monsters); i++) {
            var monster_data = global.player_monsters[i];
            if (monster_data.type == monster_type) {
                show_debug_message("找到匹配的怪物數據：" + object_get_name(monster_type));
                
                // 設置屬性
                with (monster_inst) {
                    level = monster_data.level;
                    hp = monster_data.hp;
                    max_hp = monster_data.max_hp;
                    attack = monster_data.attack;
                    defense = monster_data.defense;
                    spd = monster_data.spd;
                    
                    // 確保team值正確設置
                    team = 0; // 玩家隊伍
                    show_debug_message("已設置team值為: " + string(team));
                    
                    // 其他初始化
                    atb_current = 0;
                    atb_ready = false;
                    
                    // 如果有技能數據，也可以複製
                    if (variable_struct_exists(monster_data, "skills") && is_array(monster_data.skills)) {
                        // 這裡可以添加技能設置邏輯
                    }
                }
                
                show_debug_message("怪物屬性設置完成");
                break;
            }
        }
    }
    
    show_debug_message("===== 怪物屬性設置結束 =====");
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

// 戰鬥開始事件處理
on_battle_start = function(data) {
    show_debug_message("===== 戰鬥開始事件處理 =====");
    show_debug_message("檢查enemy_units列表是否存在: " + string(ds_exists(enemy_units, ds_type_list)));
    show_debug_message("enemy_units列表ID: " + string(enemy_units));
    show_debug_message("初始敵人列表大小: " + string(ds_list_size(enemy_units)));
    
    // 保存初始敵人引用（如果存在）
    var initial_enemy = noone;
    if (variable_struct_exists(data, "initial_enemy")) {
        initial_enemy = data.initial_enemy;
        show_debug_message("保存初始敵人引用：" + string(initial_enemy));
        show_debug_message("初始敵人是否存在：" + string(instance_exists(initial_enemy)));
        if (instance_exists(initial_enemy)) {
            show_debug_message("初始敵人類型：" + object_get_name(initial_enemy.object_index));
            show_debug_message("初始敵人team值：" + string(initial_enemy.team));
        }
    } else {
        show_debug_message("警告：data中沒有initial_enemy");
    }
    
    // 初始化戰鬥區域
    if (variable_struct_exists(data, "center_x") && variable_struct_exists(data, "center_y")) {
        battle_center_x = data.center_x;
        battle_center_y = data.center_y;
        battle_boundary_radius = 0;
        
        show_debug_message("設置戰鬥區域：");
        show_debug_message("- 中心點: (" + string(battle_center_x) + ", " + string(battle_center_y) + ")");
        
        if (variable_struct_exists(data, "required_radius")) {
            battle_required_radius = data.required_radius;
        }
        show_debug_message("- 所需半徑: " + string(battle_required_radius));
        
        set_battle_area(battle_center_x, battle_center_y, 0);
    }
    
    show_debug_message("清理單位列表：");
    show_debug_message("- 清理前玩家單位數量: " + string(ds_list_size(player_units)));
    show_debug_message("- 清理前敵方單位數量: " + string(ds_list_size(enemy_units)));
    
    // 只清空玩家單位列表
    ds_list_clear(player_units);
    
    // 檢查敵人列表中是否已有初始敵人
    var enemy_index = -1;
    if (initial_enemy != noone) {
        enemy_index = ds_list_find_index(enemy_units, initial_enemy);
        show_debug_message("初始敵人在列表中的索引: " + string(enemy_index));
    }
    
    // 確保初始敵人在列表中
    if (initial_enemy != noone && enemy_index == -1) {
        show_debug_message("初始敵人不在列表中，添加到列表");
        ds_list_add(enemy_units, initial_enemy);
        show_debug_message("添加後敵人列表大小: " + string(ds_list_size(enemy_units)));
        
        // 再次驗證
        enemy_index = ds_list_find_index(enemy_units, initial_enemy);
        show_debug_message("驗證：初始敵人現在的索引: " + string(enemy_index));
    }
    
    show_debug_message("- 清理後玩家單位數量: " + string(ds_list_size(player_units)));
    show_debug_message("- 清理後敵方單位數量: " + string(ds_list_size(enemy_units)));
    
    // 重置計數器
    total_player_units_created = 0;
    total_enemy_units_created = ds_list_size(enemy_units); // 設置為當前敵人數量
    total_player_units_defeated = 0;
    total_enemy_units_defeated = 0;
    
    // 確認敵人列表中的單位
    show_debug_message("敵人列表內容：");
    for (var i = 0; i < ds_list_size(enemy_units); i++) {
        var unit = enemy_units[| i];
        if (instance_exists(unit)) {
            show_debug_message(string(i) + ": ID=" + string(unit) + ", Type=" + object_get_name(unit.object_index) + ", Team=" + string(unit.team));
            
            // 確保敵人的team值正確
            with (unit) {
                if (team != 1) {
                    team = 1;
                    show_debug_message("- 糾正敵人team值為1");
                }
            }
        } else {
            show_debug_message(string(i) + ": <無效單位>");
            ds_list_delete(enemy_units, i--);
        }
    }
    
    show_debug_message("最終敵人數量: " + string(ds_list_size(enemy_units)));
    show_debug_message("===== 戰鬥開始事件處理完成 =====");
};

// 戰鬥結束事件處理
on_battle_end = function(data) {
    // 清理所有單位
    for (var i = ds_list_size(player_units) - 1; i >= 0; i--) {
        var unit = player_units[| i];
        if (instance_exists(unit)) {
            instance_destroy(unit);
        }
    }
    
    for (var i = ds_list_size(enemy_units) - 1; i >= 0; i--) {
        var enemy = enemy_units[| i];
        if (instance_exists(enemy)) {
            instance_destroy(enemy);
        }
    }
    
    // 清空列表
    ds_list_clear(player_units);
    ds_list_clear(enemy_units);
    
    // 重置戰鬥區域
    set_battle_area(0, 0, 0);
    
    show_debug_message("單位管理器: 戰鬥結束，已清理所有單位");
};

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