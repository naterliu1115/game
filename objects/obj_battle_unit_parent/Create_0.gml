// 基础属性
max_hp = 100;
hp = max_hp;
attack = 10;
defense = 5;
spd = 5;         // 影响移动速度和ATB充能速率
level = 1;

// ATB系统
atb_max = 100;     // ATB满值
atb_current = 0;   // 当前ATB值
atb_rate = 1 + (spd * 0.1); // ATB充能速率(基础+速度加成)
atb_ready = false; // ATB是否已满

// AI行为相关
enum AI_MODE {
    AGGRESSIVE, // 积极攻击
    DEFENSIVE,  // 防守反击
    PURSUIT     // 追击特定目标
}

ai_mode = AI_MODE.AGGRESSIVE; // 默认行为模式
target = noone;   // 当前目标
marked = false;   // 是否被玩家标记
team = 0;         // 0=玩家方, 1=敌方

// 技能系统
skills = ds_list_create(); // 技能列表
current_skill = noone;     // 当前准备释放的技能
skill_cooldowns = ds_map_create(); // 技能冷却时间映射

// 移动相关
move_speed = 2 + (spd * 0.2); // 移动速度，使用spd而不是speed
path = path_add();  // 创建路径用于寻路
path_pending = false; // 是否有待执行的路径

// 状态标志
is_acting = false;  // 是否正在执行行动
dead = false;       // 是否已死亡

// 初始化方法(子类可以覆盖此方法添加自己的初始化)
initialize = function() {
    // 这里可以添加通用初始化代码
    show_debug_message("战斗单位初始化: " + string(id));
}

// 准备行动
prepare_action = function() {
    show_debug_message(object_get_name(object_index) + " (ID: " + string(id) + ", team: " + string(team) + ") ATB已满，准备行动");
    // AI决定下一步行动
    choose_target_and_skill();
}

// 选择目标和技能
choose_target_and_skill = function() {
    // 根据AI模式选择目标
    if (target == noone || !instance_exists(target)) {
        find_new_target();
    }
    
    // 已有目标，选择合适的技能
    if (target != noone) {
        choose_skill();
    }
}

// 寻找新目标
find_new_target = function() {
    // 获取潜在目标列表(敌对阵营)
    show_debug_message(object_get_name(object_index) + " (ID: " + string(id) + ", team: " + string(team) + ") 正在寻找目标");
    var potential_targets = ds_list_create();
    
    with (obj_battle_manager) {
        var enemy_list = (other.team == 0) ? enemy_units : player_units;
        show_debug_message("  - 潜在目标数量: " + string(ds_list_size(enemy_list)));
        ds_list_copy(potential_targets, enemy_list);
    }
    
    // 确保不会选择自己作为目标
    var self_index = ds_list_find_index(potential_targets, id);
    if (self_index != -1) {
        ds_list_delete(potential_targets, self_index);
        show_debug_message("  - 已从目标列表中移除自己");
    }
    
    // 根据AI模式和标记来选择目标
    if (ds_list_size(potential_targets) > 0) {
        var marked_found = false;
        
        // 优先选择被标记的目标
        for (var i = 0; i < ds_list_size(potential_targets); i++) {
            var pot_target = potential_targets[| i];
            if (instance_exists(pot_target) && pot_target.marked) {
                target = pot_target;
                marked_found = true;
                show_debug_message("  - 找到被标记的目标: " + string(pot_target));
                break;
            }
        }
        
        // 如果没有找到被标记的目标，根据AI模式选择
        if (!marked_found) {
            switch (ai_mode) {
                case AI_MODE.AGGRESSIVE:
                    // 选择最近或最弱的目标
                    var closest_dist = 100000;
                    var closest_target = noone;
                    
                    for (var i = 0; i < ds_list_size(potential_targets); i++) {
                        var pot_target = potential_targets[| i];
                        if (instance_exists(pot_target)) {
                            var dist = point_distance(x, y, pot_target.x, pot_target.y);
                            if (dist < closest_dist) {
                                closest_dist = dist;
                                closest_target = pot_target;
                            }
                        }
                    }
                    
                    target = closest_target;
                    break;
                    
                case AI_MODE.DEFENSIVE:
                    // 优先选择攻击自己的目标
                    // 或者最接近的目标
                    // 这里可以添加更复杂的逻辑
                    if (ds_list_size(potential_targets) > 0) {
                        target = potential_targets[| 0];
                    }
                    break;
                    
                case AI_MODE.PURSUIT:
                    // 如果之前有目标但失效了，找最相似的目标
                    // 否则选择随机目标
                    if (ds_list_size(potential_targets) > 0) {
                        target = potential_targets[| irandom(ds_list_size(potential_targets) - 1)];
                    }
                    break;
            }
        }
        
        if (target != noone) {
            show_debug_message("  - 选择目标成功: " + object_get_name(target.object_index) + " (ID: " + string(target.id) + ")");
        } else {
            show_debug_message("  - 尽管有潜在目标，但选择失败!");
        }
    } else {
        show_debug_message("  - 没有找到任何有效目标!");
        target = noone;
    }
    
    ds_list_destroy(potential_targets);
}

// 选择技能
choose_skill = function() {
    // 获取可用技能列表
    var available_skills = ds_list_create();
    
    for (var i = 0; i < ds_list_size(skills); i++) {
        var skill = skills[| i];
        var cooldown = ds_map_find_value(skill_cooldowns, skill.id);
        
        if (cooldown <= 0) {
            ds_list_add(available_skills, skill);
        }
    }
    
    // 如果有可用技能，选择一个
    if (ds_list_size(available_skills) > 0) {
        // 这里可以添加更复杂的技能选择逻辑
        current_skill = available_skills[| irandom(ds_list_size(available_skills) - 1)];
        show_debug_message(object_get_name(object_index) + " 选择技能: " + current_skill.name);
    } else {
        // 没有可用技能，使用默认攻击
        current_skill = {
            id: "basic_attack",
            name: "基础攻击",
            damage: attack,
            range: 50,
            cooldown: 30
        };
        show_debug_message(object_get_name(object_index) + " 无可用技能，使用默认攻击");
    }
    
    ds_list_destroy(available_skills);
}

// 执行AI行动
execute_ai_action = function() {
    show_debug_message(object_get_name(object_index) + " (ID: " + string(id) + ", team: " + string(team) + ") 正在执行AI行动");
    
    if (target == noone || !instance_exists(target)) {
        show_debug_message("  - 目标无效，重置ATB并寻找新目标");
        atb_current = 0;
        atb_ready = false;
        find_new_target();
        return;
    }
    
    // 检查与目标的距离
    var dist_to_target = point_distance(x, y, target.x, target.y);
    show_debug_message("  - 与目标距离: " + string(dist_to_target) + ", 技能范围: " + string(current_skill.range));
    
    if (dist_to_target <= current_skill.range) {
        show_debug_message("  - 在技能范围内，执行技能");
        is_acting = true;
        use_skill(current_skill, target);
    } else {
        show_debug_message("  - 不在范围内，移动接近目标");
        move_towards_target();
    }
}

// 使用技能
use_skill = function(skill, target) {
    // 这里实现实际的技能效果
    show_debug_message(object_get_name(object_index) + " (ID: " + string(id) + ") 使用技能 " + skill.name + " 攻击 " + object_get_name(target.object_index) + " (ID: " + string(target.id) + ")");
    
    // 造成伤害
    with (target) {
        take_damage(other.attack);
    }
    
    // 设置技能冷却
    ds_map_set(skill_cooldowns, skill.id, skill.cooldown);
    
    // 重置ATB
    atb_current = 0;
    atb_ready = false;
    is_acting = false;
}

// 移动向目标
move_towards_target = function() {
    if (instance_exists(target)) {
        // 使用简单直线移动
        var dir = point_direction(x, y, target.x, target.y);
        var move_x = lengthdir_x(move_speed, dir);
        var move_y = lengthdir_y(move_speed, dir);
        
        // 检查碰撞并移动
        if (!place_meeting(x + move_x, y, obj_battle_unit_parent)) {
            x += move_x;
        }
        
        if (!place_meeting(x, y + move_y, obj_battle_unit_parent)) {
            y += move_y;
        }
    }
}

// 受到伤害
take_damage = function(amount) {
    var actual_damage = max(1, amount - defense);
    hp -= actual_damage;
    
    show_debug_message(object_get_name(object_index) + " (ID: " + string(id) + ") 受到伤害: " + string(actual_damage) + ", 剩余HP: " + string(hp) + "/" + string(max_hp));
    
    // 显示伤害数字
    // 这里可以添加创建伤害数字对象的代码
    
    // 检查是否死亡
    if (hp <= 0) {
        hp = 0;
        die();
    }
}

// 死亡处理
die = function() {
    if (!dead) {
        dead = true;
        show_debug_message(object_get_name(object_index) + " (ID: " + string(id) + ") 已死亡");
        
        // 从战斗管理器的列表中移除
        with (obj_battle_manager) {
            var list_to_check = (other.team == 0) ? player_units : enemy_units;
            var index = ds_list_find_index(list_to_check, other.id);
            if (index != -1) {
                ds_list_delete(list_to_check, index);
            }
        }
        
        // 设置闹钟延迟销毁
        alarm[0] = 15;
    }
}

// 调用初始化
initialize();