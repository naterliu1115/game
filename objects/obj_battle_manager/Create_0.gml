// 战斗状态枚举
enum BATTLE_STATE {
    INACTIVE,    // 非战斗状态
    STARTING,    // 战斗开始过渡（边界扩张）
    PREPARING,   // 战斗准备阶段（玩家召唤单位）
    ACTIVE,      // 战斗进行中
    ENDING,      // 战斗结束过渡
    RESULT       // 显示战斗结果
}

// 初始化战斗状态
battle_state = BATTLE_STATE.INACTIVE;
battle_timer = 0;           // 战斗持续时间计时器
battle_boundary_radius = 0; // 战斗边界半径
battle_center_x = 0;        // 战斗中心X坐标
battle_center_y = 0;        // 战斗中心Y坐标

// 战斗单位管理
player_units = ds_list_create();   // 玩家方单位
enemy_units = ds_list_create();    // 敌方单位
max_player_units = 2;              // 初始最大召唤数量
global_summon_cooldown = 0;        // 全局召唤冷却
max_global_cooldown = 15 * game_get_speed(gamespeed_fps); // 15秒冷却

// 初始化方法
initialize_battle = function() {
    // 清空单位列表
    ds_list_clear(player_units);
    ds_list_clear(enemy_units);
    
    // 重置计时器和冷却
    battle_timer = 0;
    global_summon_cooldown = 0;
    
    show_debug_message("战斗管理器初始化完成");
}

// 启动战斗函数
start_battle = function(initial_enemy) {
    if (battle_state != BATTLE_STATE.INACTIVE) return false;
    
    // 设置战斗状态
    battle_state = BATTLE_STATE.STARTING;
    battle_boundary_radius = 10; // 初始很小，会逐渐扩大
    
    // 记录战斗中心位置
    battle_center_x = initial_enemy.x;
    battle_center_y = initial_enemy.y;
    
    // 添加初始敌人到敌方单位列表
    ds_list_add(enemy_units, initial_enemy);
    
    // 将附近敌人也添加到战斗中
    var nearby_radius = 150;
    // 保存对当前实例的引用
    var battle_manager = id;
    
    with (obj_enemy_parent) {
        // 使用battle_manager引用来访问正确的变量
        if (id != initial_enemy && 
            point_distance(x, y, battle_manager.battle_center_x, battle_manager.battle_center_y) <= nearby_radius) {
            ds_list_add(battle_manager.enemy_units, id);
        }
    }
    
    // 通知所有敌人进入战斗状态
    for (var i = 0; i < ds_list_size(enemy_units); i++) {
        var enemy = enemy_units[| i];
        with (enemy) {
            if (variable_instance_exists(id, "enter_battle_mode")) {
                enter_battle_mode();
            }
        }
    }
    
    // 设置全局战斗标志
    global.in_battle = true;
    
    // 显示战斗UI
    if (!instance_exists(obj_battle_ui)) {
        instance_create_layer(0, 0, "Instances", obj_battle_ui);
    }
    
    show_debug_message("战斗开始准备! 敌人数量: " + string(ds_list_size(enemy_units)));
    return true;
}

// 结束战斗函数
end_battle = function() {
    // 恢复正常游戏状态
    battle_state = BATTLE_STATE.INACTIVE;
    battle_boundary_radius = 0;
    
    // 重置全局战斗标志
    global.in_battle = false;
    
    // 移除战斗UI
    if (instance_exists(obj_battle_ui)) {
        instance_destroy(obj_battle_ui);
    }
    
// 清理單位
for (var i = 0; i < ds_list_size(player_units); i++) {
    var unit = player_units[| i];
    if (instance_exists(unit)) {
        // 更新玩家的怪物數據（經驗值、狀態等）
        // 假設我們有一個全局陣列存儲玩家的怪物
        for (var j = 0; j < array_length(global.player_monsters); j++) {
            var monster_data = global.player_monsters[j];
            if (monster_data.type == unit.object_index) {
                // 更新怪物數據
                monster_data.level = unit.level;
                monster_data.hp = unit.hp;
                monster_data.max_hp = unit.max_hp;
                monster_data.attack = unit.attack;
                monster_data.defense = unit.defense;
                monster_data.spd = unit.spd;
                
                // 可以在這裡添加更多數據更新
                break;
            }
        }
        
        // 創建回收效果
        var recall_x = unit.x;
        var recall_y = unit.y;
        
        // 如果沒有特定的回收效果物件，可以創建一個簡單的視覺效果
        instance_create_layer(recall_x, recall_y, "Instances", obj_recall_effect);
        
        // 銷毀單位實例
        instance_destroy(unit);
    }
}

    
    // 清空单位列表
    ds_list_clear(player_units);
    ds_list_clear(enemy_units);
    
    show_debug_message("战斗完全结束!");
}


// 战斗边界管理
enforce_battle_boundary = function() {
    // 限制玩家角色
    if (instance_exists(global.player)) {
        var dist = point_distance(global.player.x, global.player.y, battle_center_x, battle_center_y);
        if (dist > battle_boundary_radius) {
            // 将玩家推回边界内
            var dir = point_direction(battle_center_x, battle_center_y, global.player.x, global.player.y);
            global.player.x = battle_center_x + lengthdir_x(battle_boundary_radius * 0.95, dir);
            global.player.y = battle_center_y + lengthdir_y(battle_boundary_radius * 0.95, dir);
        }
    }
    
    // 限制玩家单位
    for (var i = 0; i < ds_list_size(player_units); i++) {
        var unit = player_units[| i];
        if (instance_exists(unit)) {
            var dist = point_distance(unit.x, unit.y, battle_center_x, battle_center_y);
            if (dist > battle_boundary_radius) {
                // 将单位推回边界内
                var dir = point_direction(battle_center_x, battle_center_y, unit.x, unit.y);
                unit.x = battle_center_x + lengthdir_x(battle_boundary_radius * 0.95, dir);
                unit.y = battle_center_y + lengthdir_y(battle_boundary_radius * 0.95, dir);
            }
        }
    }
    
    // 限制敌方单位
    for (var i = 0; i < ds_list_size(enemy_units); i++) {
        var unit = enemy_units[| i];
        if (instance_exists(unit)) {
            var dist = point_distance(unit.x, unit.y, battle_center_x, battle_center_y);
            if (dist > battle_boundary_radius) {
                // 将单位推回边界内
                var dir = point_direction(battle_center_x, battle_center_y, unit.x, unit.y);
                unit.x = battle_center_x + lengthdir_x(battle_boundary_radius * 0.95, dir);
                unit.y = battle_center_y + lengthdir_y(battle_boundary_radius * 0.95, dir);
            }
        }
    }
};
// 在第一次创建时初始化
initialize_battle();