// 動畫相關變數
enum UNIT_ANIMATION {
    WALK_DOWN_RIGHT = 0,
    WALK_UP_RIGHT = 1,
    WALK_UP_LEFT = 2,
    WALK_DOWN_LEFT = 3,
    WALK_DOWN = 4,
    WALK_RIGHT = 5,
    WALK_UP = 6,
    WALK_LEFT = 7,
    IDLE = 8,
    ATTACK = 9,
    HURT = 10,
    DIE = 11
}

// 動畫幀範圍
animation_frames = {
    WALK_DOWN_RIGHT: [0, 4],
    WALK_UP_RIGHT: [5, 9],
    WALK_UP_LEFT: [10, 14],
    WALK_DOWN_LEFT: [15, 19],
    WALK_DOWN: [20, 24],
    WALK_RIGHT: [25, 29],
    WALK_UP: [30, 34],
    WALK_LEFT: [35, 39],
    IDLE: [0, 4],        // 臨時用右下角移動替代
    ATTACK: [40, 44],      // 修改為 40-44 幀
    HURT: [0, 4],        // 臨時用右下角移動替代
    DIE: [0, 4]          // 臨時用右下角移動替代
}

// 動畫控制變數
current_animation = UNIT_ANIMATION.IDLE;
current_animation_name = "";
animation_speed = 1;        // 一般動畫速度
idle_animation_speed = 0.7;   // IDLE動畫速度

// 初始化動畫
image_index = animation_frames.IDLE[0];
image_speed = idle_animation_speed;

// 位置追蹤
last_x = x;
last_y = y;
is_moving = false;

// 停用GameMaker的自動動畫系統
image_speed = 0;

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
atb_paused = false; // 是否暂停ATB充能（等待目标进入范围）

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

// 技能系统 (重構)
skill_ids = ds_list_create();     // 技能ID列表
skills = ds_list_create();         // 技能資料列表 (從技能管理器載入)
current_skill = noone;            // 當前準備釋放的技能
skill_cooldowns = ds_map_create(); // 技能冷卻時間映射

// 技能動畫與傷害控制
skill_animation_frame = 0;        // 當前技能動畫幀
skill_animation_total_frames = 0; // 技能動畫總幀數
skill_damage_triggered = false;   // 是否已觸發傷害
skill_animation_playing = false;  // 是否正在播放技能動畫

// 移动相关
move_speed = 2 + (spd * 0.2); // 移动速度，使用spd而不是speed
path = path_add();  // 创建路径用于寻路
path_pending = false; // 是否有待执行的路径

// 状态标志
is_acting = false;  // 是否正在执行行動
is_attacking = false; // 是否正在攻擊
dead = false;       // 是否已死亡

// 計時器類型枚舉
enum TIMER_TYPE {
    NONE = 0,
    DEATH = 1,        // 死亡後自我銷毀
    HURT_RECOVERY = 2 // 受傷後恢復動畫
}

// 計時器變數
timer_type = TIMER_TYPE.NONE;
timer_count = 0;

// 設置計時器函數
set_timer = function(type, duration) {
    timer_type = type;
    timer_count = duration;
    alarm[0] = 1; // 啟動統一的計時器
}

// 初始化技能系統
initialize_skills = function() {
    // 清空舊技能資料
    ds_list_clear(skill_ids);
    ds_list_clear(skills);
    ds_map_clear(skill_cooldowns);
    
    // 所有單位都有基本攻擊
    add_skill("basic_attack");
    
    // 子類可以添加更多技能
}

// 添加技能
add_skill = function(skill_id) {
    // 檢查技能管理器
    if (!instance_exists(obj_skill_manager)) {
        show_debug_message("錯誤：無法添加技能 - 技能管理器不存在");
        return false;
    }
    
    // 從技能管理器獲取技能資料
    var skill_data = obj_skill_manager.copy_skill(skill_id, id);
    
    if (skill_data == undefined) {
        show_debug_message("錯誤：無法添加技能 - 找不到技能 " + skill_id);
        return false;
    }
    
    // 添加到技能列表
    ds_list_add(skill_ids, skill_id);
    ds_list_add(skills, skill_data);
    
    // 初始化冷卻時間
    ds_map_add(skill_cooldowns, skill_id, 0);
    
    show_debug_message(object_get_name(object_index) + " 添加技能: " + skill_id);
    return true;
}

// 初始化方法(子类可以覆盖此方法添加自己的初始化)
initialize = function() {
    // 初始化戰鬥計時器（如果尚未定義）
    if (!variable_global_exists("battle_timer")) {
        global.battle_timer = 0;
    }
    
    // 初始化技能系統
    initialize_skills();
    
    // 这里可以添加通用初始化代码
    // show_debug_message("战斗单位初始化: " + string(id));
}

// 准备行动
prepare_action = function() {
    // show_debug_message(object_get_name(object_index) + " (ID: " + string(id) + ", team: " + string(team) + ") ATB已满，准备行动");
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
    // show_debug_message("===== 開始尋找目標 =====");
    // show_debug_message(object_get_name(object_index) + " (ID: " + string(id) + ")");
    // show_debug_message("- 當前隊伍: " + string(team));
    
    var potential_targets = ds_list_create();
    
    if (instance_exists(obj_unit_manager)) {
        var enemy_list = (team == 0) ? obj_unit_manager.enemy_units : obj_unit_manager.player_units;
        // show_debug_message("- 查找列表: " + (team == 0 ? "enemy_units" : "player_units"));
        // show_debug_message("- 潛在目標數量: " + string(ds_list_size(enemy_list)));
        
        // 列出所有潛在目標的信息
        for (var i = 0; i < ds_list_size(enemy_list); i++) {
            var check_target = enemy_list[| i];
            // show_debug_message("  目標 " + string(i) + ":");
            // show_debug_message("  - ID: " + string(check_target));
            // show_debug_message("  - 類型: " + object_get_name(check_target.object_index));
            // show_debug_message("  - Team: " + string(check_target.team));
            // show_debug_message("  - 是否存活: " + (!check_target.dead ? "是" : "否"));
            
            if (instance_exists(check_target) && 
                !check_target.dead && 
                check_target.id != id) {
                ds_list_add(potential_targets, check_target);
            }
        }
    } else {
        // show_debug_message("- 警告：單位管理器不存在！");
    }
    
    // show_debug_message("- 有效目標數量: " + string(ds_list_size(potential_targets)));
    
    // 如果有標記的目標，優先選擇
    var marked_target = noone;
    for (var i = 0; i < ds_list_size(potential_targets); i++) {
        var potential_target = potential_targets[| i];
        if (potential_target.marked) {
            marked_target = potential_target;
            // show_debug_message("- 找到被標記的目標: " + string(marked_target));
            break;
        }
    }
    
    if (marked_target != noone) {
        target = marked_target;
        // show_debug_message("- 選擇了被標記的目標: " + string(target));
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
                // show_debug_message("- 選擇了最近的目標: " + string(target) + "，距離: " + string(nearest_dist));
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
                // show_debug_message("- 選擇了最弱的目標: " + string(target) + "，HP比例: " + string(lowest_hp_ratio));
                break;
                
            case AI_MODE.PURSUIT:
                // 如果已有目標且目標仍然有效，保持追蹤
                if (target != noone && instance_exists(target) && !target.dead) {
                    // show_debug_message("- 繼續追蹤現有目標: " + string(target));
                } else {
                    // 否則選擇隨機目標
                    target = potential_targets[| irandom(ds_list_size(potential_targets) - 1)];
                    // show_debug_message("- 選擇了隨機目標: " + string(target));
                }
                break;
        }
    } else {
        target = noone;
        // show_debug_message("- 沒有找到任何有效目標!");
    }
    
    // show_debug_message("===== 目標搜索結束 =====");
    
    // 清理臨時列表
    ds_list_destroy(potential_targets);
}

// 选择技能 (修改為使用新的技能系統)
choose_skill = function() {
    // 获取可用技能列表
    var available_skills = ds_list_create();
    
    for (var i = 0; i < ds_list_size(skill_ids); i++) {
        var skill_id = skill_ids[| i];
        var cooldown = ds_map_find_value(skill_cooldowns, skill_id);
        
        if (cooldown <= 0) {
            // 從技能列表獲取技能資料
            var skill = skills[| i];
            ds_list_add(available_skills, i);  // 添加技能索引
        }
    }
    
    // 如果有可用技能，选择一个
    if (ds_list_size(available_skills) > 0) {
        // 選擇技能索引
        var selected_index = available_skills[| irandom(ds_list_size(available_skills) - 1)];
        
        // 設置當前技能
        current_skill = skills[| selected_index];
        show_debug_message(object_get_name(object_index) + " 選擇技能: " + current_skill.name);
    } else {
        // 如果沒有可用技能，使用基本攻擊
        if (ds_list_size(skills) > 0) {
            current_skill = skills[| 0]; // 基本攻擊通常是第一個技能
            show_debug_message(object_get_name(object_index) + " 無可用技能，使用基本攻擊");
        } else {
            current_skill = noone;
            show_debug_message(object_get_name(object_index) + " 警告：無可用技能!");
        }
    }
    
    // 清理臨時列表
    ds_list_destroy(available_skills);
}

// 執行AI行動 (判斷目標是否在範圍內)
execute_ai_action = function() {
    if (!atb_ready || is_acting || current_skill == noone) {
        return;
    }
    
    // 檢查目標是否存在
    if (target == noone || !instance_exists(target) || target.dead) {
        find_new_target();
        if (target == noone) {
            // 沒有目標，保持ATB滿但不行動
            atb_paused = true;
            return;
        }
    }
    
    // 檢查目標是否在技能範圍內
    var distance_to_target = point_distance(x, y, target.x, target.y);
    if (distance_to_target > current_skill.range) {
        // 目標不在範圍內，移動接近
        move_towards_target();
        // 暫停ATB在100%
        atb_paused = true;
        return;
    }
    
    // 目標在範圍內，取消ATB暫停
    atb_paused = false;
    
    // 開始執行技能
    start_skill_animation();
}

// 移動接近目標
move_towards_target = function() {
    if (target == noone || !instance_exists(target)) {
        return;
    }
    
    // 計算朝向目標的方向
    var dir = point_direction(x, y, target.x, target.y);
    var move_distance = move_speed;
    
    // 計算新位置
    var new_x = x + lengthdir_x(move_distance, dir);
    var new_y = y + lengthdir_y(move_distance, dir);
    
    // 移動
    x = new_x;
    y = new_y;
}

// 開始技能動畫
start_skill_animation = function() {
    // 設置狀態標記
    is_acting = true;
    is_attacking = true;
    skill_animation_playing = true;
    skill_damage_triggered = false;
    
    // 設置動畫參數
    current_animation = UNIT_ANIMATION.ATTACK;
    skill_animation_frame = 0;
    
    // 獲取動畫總幀數
    skill_animation_total_frames = current_skill.anim_frames;
    
    show_debug_message(object_get_name(object_index) + " 開始使用技能: " + current_skill.name);
}

// 更新技能動畫並觸發傷害
update_skill_animation = function() {
    if (!skill_animation_playing) return;
    
    // 增加動畫幀
    skill_animation_frame++;
    
    // 檢查是否需要觸發傷害
    if (!skill_damage_triggered && is_array(current_skill.anim_damage_frames)) {
        // 檢查當前幀是否是傷害觸發幀
        for (var i = 0; i < array_length(current_skill.anim_damage_frames); i++) {
            if (skill_animation_frame == current_skill.anim_damage_frames[i]) {
                // 觸發傷害
                apply_skill_damage();
                break;
            }
        }
    }
    
    // 檢查動畫是否結束
    if (skill_animation_frame >= skill_animation_total_frames) {
        end_skill_animation();
    }
}

// 應用技能傷害
apply_skill_damage = function() {
    if (target == noone || !instance_exists(target) || target.dead) {
        return;
    }
    
    // 標記傷害已觸發
    skill_damage_triggered = true;
    
    // 計算傷害
    var damage = current_skill.damage;
    
    // 考慮目標防禦
    damage = max(1, damage - target.defense);
    
    // 應用傷害
    with (target) {
        take_damage(damage, other.id, other.current_skill.id);
    }
    
    // 創建特效 (如果特效系統已存在)
    if (variable_global_exists("particle_system") && current_skill.particle_effect != "") {
        // 這裡將來添加粒子特效創建代碼
    }
    
    show_debug_message(object_get_name(object_index) + " 對 " + object_get_name(target.object_index) + 
                      " 造成 " + string(damage) + " 點傷害 (技能: " + current_skill.name + ")");
}

// 結束技能動畫
end_skill_animation = function() {
    // 重置動畫狀態
    skill_animation_playing = false;
    is_attacking = false;
    is_acting = false;
    
    // 設置技能冷卻
    if (current_skill != noone) {
        ds_map_set(skill_cooldowns, current_skill.id, current_skill.cooldown);
    }
    
    // 重置ATB
    atb_current = 0;
    atb_ready = false;
    
    // 恢復閒置動畫
    current_animation = UNIT_ANIMATION.IDLE;
    
    show_debug_message(object_get_name(object_index) + " 完成技能: " + 
                      (current_skill != noone ? current_skill.name : "未知"));
    
    // 清除當前技能
    current_skill = noone;
}

// 受到傷害處理
take_damage = function(damage_amount, source_id, skill_id) {
    hp -= damage_amount;
    
    // 檢查是否死亡
    if (hp <= 0) {
        hp = 0;
        die();
    } else {
        // 播放受傷動畫
        current_animation = UNIT_ANIMATION.HURT;
        
        // 創建受傷特效
        instance_create_layer(x, y, "Effects", obj_hurt_effect);
        
        // 在短時間後恢復正常動畫 (使用新的計時器系統)
        set_timer(TIMER_TYPE.HURT_RECOVERY, 15);
    }
}

// 死亡處理
die = function() {
    if (!dead) {
        dead = true;
        
        // 设置死亡动画
        current_animation = UNIT_ANIMATION.DIE;
        
        // 發送死亡事件
        broadcast_event("unit_died", {
            unit_id: id,
            team: team,
            position: {x: x, y: y},
            unit_type: object_index
        });
        
        // 創建死亡特效
        instance_create_layer(x, y, "Instances", obj_death_effect);
        
        // 設置自我銷毀延遲 (使用新的計時器系統)
        set_timer(TIMER_TYPE.DEATH, 15);
    }
}

// 立即執行初始化
initialize();