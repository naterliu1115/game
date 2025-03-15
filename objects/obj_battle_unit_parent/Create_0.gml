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
    show_debug_message("===== 開始尋找目標 =====");
    show_debug_message(object_get_name(object_index) + " (ID: " + string(id) + ")");
    show_debug_message("- 當前隊伍: " + string(team));
    
    var potential_targets = ds_list_create();
    
    if (instance_exists(obj_unit_manager)) {
        var enemy_list = (team == 0) ? obj_unit_manager.enemy_units : obj_unit_manager.player_units;
        show_debug_message("- 查找列表: " + (team == 0 ? "enemy_units" : "player_units"));
        show_debug_message("- 潛在目標數量: " + string(ds_list_size(enemy_list)));
        
        // 列出所有潛在目標的信息
        for (var i = 0; i < ds_list_size(enemy_list); i++) {
            var check_target = enemy_list[| i];
            show_debug_message("  目標 " + string(i) + ":");
            show_debug_message("  - ID: " + string(check_target));
            show_debug_message("  - 類型: " + object_get_name(check_target.object_index));
            show_debug_message("  - Team: " + string(check_target.team));
            show_debug_message("  - 是否存活: " + (!check_target.dead ? "是" : "否"));
            
            if (instance_exists(check_target) && 
                !check_target.dead && 
                check_target.id != id) {
                ds_list_add(potential_targets, check_target);
            }
        }
    } else {
        show_debug_message("- 警告：單位管理器不存在！");
    }
    
    show_debug_message("- 有效目標數量: " + string(ds_list_size(potential_targets)));
    
    // 如果有標記的目標，優先選擇
    var marked_target = noone;
    for (var i = 0; i < ds_list_size(potential_targets); i++) {
        var potential_target = potential_targets[| i];
        if (potential_target.marked) {
            marked_target = potential_target;
            show_debug_message("- 找到被標記的目標: " + string(marked_target));
            break;
        }
    }
    
    if (marked_target != noone) {
        target = marked_target;
        show_debug_message("- 選擇了被標記的目標: " + string(target));
    }
    // 根據 AI 模式選擇目標
    else if (ds_list_size(potential_targets) > 0) {
        switch(ai_mode) {
            case AI_MODE.AGGRESSIVE:
                // 選擇最近的目標
                var nearest_dist = infinity;
                var nearest_target = noone;
                
                for (var i = 0; i < ds_list_size(potential_targets); i++) {
                    var potential_target = potential_targets[| i];
                    var dist = point_distance(x, y, potential_target.x, potential_target.y);
                    if (dist < nearest_dist) {
                        nearest_dist = dist;
                        nearest_target = potential_target;
                    }
                }
                
                target = nearest_target;
                show_debug_message("- 選擇了最近的目標: " + string(target) + "，距離: " + string(nearest_dist));
                break;
                
            case AI_MODE.DEFENSIVE:
                // 選擇最弱的目標
                var lowest_hp_ratio = infinity;
                var weakest_target = noone;
                
                for (var i = 0; i < ds_list_size(potential_targets); i++) {
                    var potential_target = potential_targets[| i];
                    var hp_ratio = potential_target.hp / potential_target.max_hp;
                    if (hp_ratio < lowest_hp_ratio) {
                        lowest_hp_ratio = hp_ratio;
                        weakest_target = potential_target;
                    }
                }
                
                target = weakest_target;
                show_debug_message("- 選擇了最弱的目標: " + string(target) + "，HP比例: " + string(lowest_hp_ratio));
                break;
                
            case AI_MODE.PURSUIT:
                // 如果已有目標且目標仍然有效，保持追蹤
                if (target != noone && instance_exists(target) && !target.dead) {
                    show_debug_message("- 繼續追蹤現有目標: " + string(target));
                } else {
                    // 否則選擇隨機目標
                    target = potential_targets[| irandom(ds_list_size(potential_targets) - 1)];
                    show_debug_message("- 選擇了隨機目標: " + string(target));
                }
                break;
        }
    } else {
        target = noone;
        show_debug_message("- 沒有找到任何有效目標!");
    }
    
    show_debug_message("===== 目標搜索結束 =====");
    
    // 清理臨時列表
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
        // 發送死亡事件
        broadcast_event("unit_died", {
            unit_id: id,
            team: team,
            position: {x: x, y: y},
            unit_type: object_index
        });
        
        // 創建死亡特效
        instance_create_layer(x, y, "Instances", obj_death_effect);
        
        // 設置自我銷毀延遲
        alarm[0] = 15;
    }
}

// 调用初始化
initialize();