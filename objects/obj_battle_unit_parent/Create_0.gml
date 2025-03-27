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
    AGGRESSIVE, // 積極攻擊
    FOLLOW,     // 跟隨主人
    PASSIVE     // 不作為
}

ai_mode = AI_MODE.AGGRESSIVE; // 默认行为模式改為積極
target = noone;   // 当前目标
marked = false;   // 是否被玩家标记
team = 0;         // 0=玩家方, 1=敌方

// 跟隨相關屬性
follow_radius = 150;     // 跟隨範圍半徑
follow_target = noone;   // 跟隨目標（通常是玩家）

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

// 移動計時器
move_to_target_timer = 0;      // 追蹤單位在移動至目標狀態的時間
move_to_target_timeout = 3 * game_get_speed(gamespeed_fps); // 設置超時時間（3秒）

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
    // 如果已經初始化過，則不重複初始化
    if (ds_list_size(skill_ids) > 0) {
        show_debug_message(object_get_name(object_index) + " 技能已初始化，跳過重複初始化");
        return;
    }
    
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
    
    // 檢查技能是否已存在，避免重複添加
    for (var i = 0; i < ds_list_size(skill_ids); i++) {
        if (skill_ids[| i] == skill_id) {
            show_debug_message(object_get_name(object_index) + " 技能已存在，跳過添加: " + skill_id);
            return false;
        }
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
    // 如果是待命模式，直接清除目標並返回
    if (ai_mode == AI_MODE.PASSIVE) {
        target = noone;
        return;
    }
    
    // 跟隨模式下只有在跟隨範圍內才尋找目標
    if (ai_mode == AI_MODE.FOLLOW && instance_exists(follow_target)) {
        if (point_distance(x, y, follow_target.x, follow_target.y) > follow_radius) {
            target = noone;
            return;
        }
    }
    
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
                
            case AI_MODE.FOLLOW:
                // 選擇最近的目標，但必須在跟隨範圍內
                var nearest_dist = infinity;
                var nearest_target = noone;
                
                for (var i = 0; i < ds_list_size(potential_targets); i++) {
                    var potential_target = potential_targets[| i];
                    var dist = point_distance(x, y, potential_target.x, potential_target.y);
                    if (dist < nearest_dist && dist <= follow_radius) {
                        nearest_dist = dist;
                        nearest_target = potential_target;
                    }
                }
                
                target = nearest_target;
                break;
                
            case AI_MODE.PASSIVE:
                // 不會攻擊，不選擇目標
                target = noone;
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

// 單位狀態枚舉
enum UNIT_STATE {
    IDLE,           // 閒置狀態
    FOLLOW,         // 跟隨主人
    MOVE_TO_TARGET, // 移動至目標
    ATTACK,         // 攻擊目標
    DEAD            // 死亡狀態
}

// 當前狀態
current_state = UNIT_STATE.IDLE;

// 狀態機更新函數 - 根據AI模式決定狀態轉換
update_state_machine = function() {
    // 死亡檢查
    if (dead) {
        current_state = UNIT_STATE.DEAD;
        return;
    }
    
    // 根據AI模式和當前狀態決定下一個狀態
    switch(ai_mode) {
        case AI_MODE.AGGRESSIVE:
            update_aggressive_state();
            break;
            
        case AI_MODE.FOLLOW:
            update_follow_state();
            break;
            
        case AI_MODE.PASSIVE:
            update_passive_state();
            break;
    }
    
    // 執行當前狀態的行為
    execute_state_behavior();
}

// 新增一個設置AI模式的函數
set_ai_mode = function(new_mode) {
    ai_mode = new_mode;
    
    // 根據模式設置相應參數
    switch(ai_mode) {
        case AI_MODE.AGGRESSIVE:
            follow_target = noone; // 積極模式不跟隨
            break;
            
        case AI_MODE.FOLLOW:
            // 設置玩家為跟隨目標
            if (instance_exists(global.player)) {
                follow_target = global.player;
            }
            break;
            
        case AI_MODE.PASSIVE:
            // 設置玩家為跟隨目標，但保持距離
            if (instance_exists(global.player)) {
                follow_target = global.player;
            }
            // 保持ATB滿格
            atb_current = atb_max;
            atb_ready = true;
            atb_paused = true;
            target = noone;
            break;
    }
}

// 積極模式狀態更新
update_aggressive_state = function() {
    // 明確清除跟隨目標，確保不會跟隨玩家
    follow_target = noone;
    
    // 如果正在攻擊，僅更新關鍵狀態
    if (is_attacking) {
        // 允許清除目標或更新關鍵狀態，但不進行完整狀態更新
        if (ai_mode == AI_MODE.PASSIVE) {
            target = noone; // 待命模式立即清除目標
            atb_paused = true; // 暫停ATB充能
        }
        return;
    }
    
    // 如果ATB未滿，進入閒置狀態
    if (!atb_ready) {
        current_state = UNIT_STATE.IDLE;
        move_to_target_timer = 0; // 重置計時器
        return;
    }
    
    // 檢查目標
    if (target == noone || !instance_exists(target) || target.dead) {
        find_new_target();
        if (target == noone) {
            current_state = UNIT_STATE.IDLE;
            atb_paused = true; // 保持ATB滿格等待目標
            move_to_target_timer = 0; // 重置計時器
            return;
        }
    }
    
    // 確保有選擇技能
    if (current_skill == noone) {
        choose_skill();
    }
    
    // 檢查目標是否在攻擊範圍內
    var distance_to_target = point_distance(x, y, target.x, target.y);
    if (current_skill != noone && distance_to_target <= current_skill.range) {
        // 在範圍內，進入攻擊狀態
        current_state = UNIT_STATE.ATTACK;
        atb_paused = false;
        move_to_target_timer = 0; // 重置計時器
    } else {
        // 不在範圍內，移動接近
        current_state = UNIT_STATE.MOVE_TO_TARGET;
        atb_paused = true;
    }
}

// 跟隨模式狀態更新
update_follow_state = function() {
    // 如果正在攻擊，僅更新關鍵狀態
    if (is_attacking) {
        // 允許清除目標或更新關鍵狀態，但不進行完整狀態更新
        if (ai_mode == AI_MODE.PASSIVE) {
            target = noone; // 待命模式立即清除目標
            atb_paused = true; // 暫停ATB充能
        }
        return;
    }
    
    // 確保跟隨目標設置正確
    if (follow_target == noone && instance_exists(global.player)) {
        follow_target = global.player;
    }
    
    // 檢查與主人的距離
    if (instance_exists(follow_target)) {
        var dist_to_player = point_distance(x, y, follow_target.x, follow_target.y);
        
        // 如果離主人太遠，優先跟隨
        if (dist_to_player > follow_radius * 0.7) {
            current_state = UNIT_STATE.FOLLOW;
            move_to_target_timer = 0; // 重置計時器
            return;
        }
    }
    
    // 在跟隨範圍內，處理ATB邏輯
    if (!atb_ready) {
        current_state = UNIT_STATE.IDLE;
        move_to_target_timer = 0; // 重置計時器
        return;
    }
    
    // 檢查目標
    if (target == noone || !instance_exists(target) || target.dead) {
        find_new_target();
        if (target == noone) {
            current_state = UNIT_STATE.IDLE;
            atb_current = 0; // 重置ATB
            atb_ready = false;
            move_to_target_timer = 0; // 重置計時器
            return;
        }
    }
    
    // 確保有選擇技能
    if (current_skill == noone) {
        choose_skill();
    }
    
    // 檢查目標是否在攻擊範圍內且在跟隨範圍內
    var distance_to_target = point_distance(x, y, target.x, target.y);
    if (current_skill != noone && distance_to_target <= current_skill.range) {
        // 在範圍內，進入攻擊狀態
        current_state = UNIT_STATE.ATTACK;
        atb_paused = false;
        move_to_target_timer = 0; // 重置計時器
    } else if (distance_to_target <= follow_radius) {
        // 在跟隨範圍內但不在攻擊範圍內，移動接近
        current_state = UNIT_STATE.MOVE_TO_TARGET;
        atb_paused = true;
    } else {
        // 超出跟隨範圍，放棄目標
        target = noone;
        current_state = UNIT_STATE.IDLE;
        atb_current = 0;
        atb_ready = false;
        move_to_target_timer = 0; // 重置計時器
    }
}

// 待命模式狀態更新
update_passive_state = function() {
    // 待命模式只能是跟隨或閒置
    // 永遠不會進入攻擊或移動至目標狀態
    
    // 如果正在攻擊，立即停止攻擊
    if (is_attacking) {
        target = noone; // 立即清除目標
        atb_paused = true; // 暫停ATB充能
        current_state = UNIT_STATE.IDLE;
        return;
    }
    
    // 確保跟隨目標設置正確
    if (follow_target == noone && instance_exists(global.player)) {
        follow_target = global.player;
    }
    
    // 清除任何攻擊目標
    target = noone;
    
    // 檢查是否需要跟隨
    if (instance_exists(follow_target)) {
        var dist_to_player = point_distance(x, y, follow_target.x, follow_target.y);
        
        // 只判斷是否需要跟隨，閾值為更小的距離
        if (dist_to_player > follow_radius * 0.4) {
            current_state = UNIT_STATE.FOLLOW;
        } else {
            current_state = UNIT_STATE.IDLE;
        }
    } else {
        current_state = UNIT_STATE.IDLE;
    }
    
    // 保持ATB為滿格，但不設置為準備行動狀態
    atb_current = atb_max;  // 維持100%
    atb_ready = false;      // 關鍵修改：雖然滿格但不標記為"準備行動"
    atb_paused = true;
}

// 執行當前狀態行為
execute_state_behavior = function() {
    switch(current_state) {
        case UNIT_STATE.IDLE:
            // 閒置狀態：不移動，等待ATB填充
            if (!is_attacking && !skill_animation_playing) {
                current_animation = UNIT_ANIMATION.IDLE;
                is_moving = false;
            }
            break;
            
        case UNIT_STATE.FOLLOW:
            // 跟隨狀態：向主人移動
            // 積極模式不應該執行跟隨
            if (ai_mode == AI_MODE.AGGRESSIVE) {
                current_state = UNIT_STATE.IDLE;
                follow_target = noone; // 確保清除跟隨目標
                break;
            }
            
            if (instance_exists(follow_target)) {
                var move_dir = point_direction(x, y, follow_target.x, follow_target.y);
                
                // 根據AI模式調整跟隨速度
                var follow_speed = (ai_mode == AI_MODE.PASSIVE) ? 
                    move_speed * 1.8 : move_speed * 1.2;
                
                // 移動
                x += lengthdir_x(follow_speed, move_dir);
                y += lengthdir_y(follow_speed, move_dir);
                
                // 設置移動狀態以更新動畫
                is_moving = true;
            }
            break;
            
        case UNIT_STATE.MOVE_TO_TARGET:
            // 移動至目標狀態：向戰鬥目標移動
            // 待命模式不應執行移動至目標
            if (ai_mode == AI_MODE.PASSIVE) {
                current_state = UNIT_STATE.IDLE;
                move_to_target_timer = 0; // 重置計時器
                break;
            }
            
            if (target != noone && instance_exists(target) && !target.dead) {
                // 增加計時器
                move_to_target_timer++;
                
                // 檢查是否超時
                if (move_to_target_timer >= move_to_target_timeout && atb_ready) {
                    // 如果超時且ATB已滿，重置ATB狀態
                    atb_current = 0;
                    atb_ready = false;
                    move_to_target_timer = 0;
                    show_debug_message(object_get_name(object_index) + " 重置ATB：追蹤目標超時");
                    break;
                }
                
                // 使用已有的移動函數
                move_towards_target();
                is_moving = true;
            } else {
                // 目標無效，回到閒置狀態
                current_state = UNIT_STATE.IDLE;
                move_to_target_timer = 0; // 重置計時器
            }
            break;
            
        case UNIT_STATE.ATTACK:
            // 攻擊狀態：執行攻擊
            // 待命模式不應執行攻擊
            if (ai_mode == AI_MODE.PASSIVE) {
                current_state = UNIT_STATE.IDLE;
                move_to_target_timer = 0; // 重置計時器
                break;
            }
            
            if (!is_attacking && !skill_animation_playing) {
                // 開始技能動畫
                start_skill_animation();
            }
            break;
            
        case UNIT_STATE.DEAD:
            // 死亡狀態：不執行任何動作
            current_animation = UNIT_ANIMATION.DIE;
            break;
    }
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

// 更新技能冷卻
update_skill_cooldowns = function() {
    var _keys = ds_map_keys_to_array(skill_cooldowns);
    for (var i = 0; i < array_length(_keys); i++) {
        var _skill_id = _keys[i];
        var _cooldown = skill_cooldowns[? _skill_id];
        if (_cooldown > 0) {
            _cooldown--;
            ds_map_set(skill_cooldowns, _skill_id, _cooldown);
        }
    }
}

// 立即執行初始化
initialize();