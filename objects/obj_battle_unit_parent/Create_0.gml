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
animation_speed = 0.3;        // 一般動畫速度
idle_animation_speed = 0.1;   // IDLE動畫速度
animation_timer = 0;          // 手動動畫計時器

// 初始化動畫
// image_index = animation_frames.IDLE[0]; // 由 Step 事件的動畫邏輯處理
// image_speed = idle_; // 由 Step 事件的動畫邏輯處理

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
skill_ids = [];     // 技能ID列表
skills = [];         // 技能資料列表 (從技能管理器載入)
current_skill = noone;            // 當前準備釋放的技能
skill_cooldowns = []; // 技能冷卻時間陣列（與 skills 完全一一對應）

// 技能動畫與傷害控制
skill_damage_triggered = false;   // 是否已觸發傷害
skill_animation_playing = false;  // 是否正在播放技能動畫

// 移动相关
move_speed = 3; // 移动速度，使用spd而不是speed
path = path_add();  // 创建路径用于寻路
path_pending = false; // 是否有待执行的路径
is_moving_command = false; // 是否正在執行移動指令
movement_lock_timer = 0;   // 移動鎖定計時器
MOVEMENT_LOCK_TIME = 10;   // 移動鎖定時間（幀數）

// 移動計時器
move_to_target_timer = 0;      // 追蹤單位在移動至目標狀態的時間
move_to_target_timeout = 3 * game_get_speed(gamespeed_fps); // 設置超時時間（3秒）

// 状态标志
is_acting = false;  // 是否正在执行行動
is_attacking = false; // 是否正在攻擊
dead = false;       // 是否已死亡
attack_cooldown_timer = 0; // 攻擊後短暫冷卻計時器

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
    if (array_length(skill_ids) > 0) {
        show_debug_message(object_get_name(object_index) + " 技能已初始化，跳過重複初始化");
        return;
    }
    // 清空舊技能資料
    skill_ids = [];
    skills = [];
    skill_cooldowns = [];
    // 子類可以添加更多技能
}

// 添加技能
add_skill = function(skill_id) {
    skill_id = real(skill_id); // 強制轉為數字
    if (!instance_exists(obj_skill_manager)) {
        show_debug_message("錯誤：無法添加技能 - 技能管理器不存在");
        return false;
    }
    for (var i = 0; i < array_length(skill_ids); i++) {
        if (skill_ids[i] == skill_id) {
            show_debug_message(object_get_name(object_index) + " 技能已存在，跳過添加: " + skill_id);
            return false;
        }
    }
    var skill_data = obj_skill_manager.copy_skill(skill_id, id);
    if (skill_data == undefined) {
        show_debug_message("錯誤：無法添加技能 - 找不到技能 " + skill_id);
        return false;
    }
    array_push(skill_ids, skill_id);
    array_push(skills, skill_data);
    array_push(skill_cooldowns, 0); // 新增技能時冷卻同步新增
    show_debug_message("添加技能: " + string(skill_id) + " (數據已複製)");
    return true;
}

// 檢查是否擁有指定技能 (基於 skill_ids 列表)
has_skill = function(skill_id) {
    // 首先檢查 skill_ids 列表是否存在且為 ds_list
    if (!ds_exists(skill_ids, ds_type_list)) {
        // 如果列表不存在，顯然不包含任何技能
        // 可以選擇性地顯示一條警告信息，因為這通常不應該發生
        // show_debug_message("警告: 在 " + object_get_name(object_index) + " 中檢查技能時 skill_ids 列表不存在!");
        return false;
    }

    // 遍歷 skill_ids 列表查找匹配的 ID
    for (var i = 0; i < ds_list_size(skill_ids); i++) {
        if (skill_ids[| i] == skill_id) {
            // 找到了匹配的 ID
            return true;
        }
    }

    // 遍歷完成後仍未找到
    return false;
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

    // --- 新增：初始化戰鬥冷卻變數 ---
    battle_cooldown = 0;
    battle_cooldown_max = 0;
    // --- 新增結束 ---
}

// 准备行动
prepare_action = function() {
    // 待命模式不進行任何行動
    if (ai_mode == AI_MODE.PASSIVE) {
        atb_current = atb_max;
        atb_ready = false;
        atb_paused = true;
        return;
    }
    
    // AI决定下一步行动
    choose_target_and_skill();
}

// 选择目标和技能
choose_target_and_skill = function() {
    // 檢查AI模式
    if (ai_mode == AI_MODE.PASSIVE) {
        target = noone;
        current_skill = noone;
        return;
    }
    
    // 跟隨模式下檢查距離
    if (ai_mode == AI_MODE.FOLLOW && instance_exists(follow_target)) {
        var dist_to_follow = point_distance(x, y, follow_target.x, follow_target.y);
        if (dist_to_follow > follow_radius * 0.7) {
            target = noone;
            current_skill = noone;
            return;
        }
    }
    
    // 根据AI模式选择目标
    if (target == noone || !instance_exists(target)) {
        find_new_target();
    }
    
    // 已有目标，选择合适的技能
    if (target != noone) {
        choose_skill();
    } else {
        current_skill = noone;
        atb_ready = false;
    }
}

// 尋找新目標
find_new_target = function() {
    // 如果是待命模式，直接清除目標並返回
    if (ai_mode == AI_MODE.PASSIVE) {
        target = noone;
        return;
    }
    
    // 跟隨模式下，只在跟隨範圍內且沒有跟隨目標時才尋找攻擊目標
if (ai_mode == AI_MODE.FOLLOW) {
    if (instance_exists(follow_target)) {
        var dist_to_follow = point_distance(x, y, follow_target.x, follow_target.y);
        
        // 如果距離跟隨目標太遠，優先跟隨，不索敵
        if (dist_to_follow > follow_radius * 0.7) {
            target = noone;
            return;
        }
        // 如果距離夠近，但ATB尚未滿足，則不進行索敵
        else if (!atb_ready) {
            target = noone;
            return;
        }
    } else {
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

// 选择技能
choose_skill = function() {
    var _obj_name = object_get_name(object_index);
    var _inst_id = string(id);
    current_skill = noone;
    if (target == noone || !instance_exists(target)) {
        return;
    }
    var available_indices = [];
    var basic_attack_index = -1;
    var dist_to_target = point_distance(x, y, target.x, target.y);
    for (var i = 0; i < array_length(skills); i++) {
        var skill = skills[i];
        var skill_id_val = -1;
        var skill_range = -1;
        if (is_struct(skill) && variable_struct_exists(skill, "id")) {
            skill_id_val = skill.id;
            if (variable_struct_exists(skill, "range") && is_real(skill.range)) {
                skill_range = skill.range;
            }
        } else {
            continue;
        }
        // 用 array 索引查冷卻
        if (skill_cooldowns[i] > 0) {
            continue;
        }
        if (skill_id_val == 1) { // 1 = basic_attack
            basic_attack_index = i;
        } else if (skill_range != -1 && dist_to_target <= skill_range) {
            array_push(available_indices, i);
        }
    }
    if (array_length(available_indices) > 0) {
        var selected_index = available_indices[irandom(array_length(available_indices) - 1)];
        current_skill = skills[selected_index];
        show_debug_message(object_get_name(object_index) + " 選擇技能: " + current_skill.name);
    } else if (basic_attack_index != -1) {
        current_skill = skills[basic_attack_index];
        if (dist_to_target <= current_skill.range) {
            // show_debug_message(object_get_name(object_index) + " 使用基本攻擊");
        }
    } else {
        current_skill = noone;
        show_debug_message(object_get_name(object_index) + " 無可用技能，等待下一次機會");
    }
}

// 單位狀態枚舉
enum UNIT_STATE {
    IDLE,           // 閒置狀態
    FOLLOW,         // 跟隨主人
    MOVE_TO_TARGET, // 移動至目標
    ATTACK,         // 攻擊目標
    DEAD,           // 死亡狀態
    WANDER          // <--- 新增：遊蕩狀態
}

// 當前狀態
current_state = UNIT_STATE.IDLE;

// 狀態緩衝相關
state_buffer_time = game_get_speed(gamespeed_fps) * 1.5; // 1.5秒緩衝
state_buffer_timer = 0;
last_state = UNIT_STATE.IDLE;

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

set_ai_mode = function(new_mode) {
    ai_mode = new_mode;

    // 清除行為與目標
    target = noone;
    current_skill = noone;
    is_attacking = false;
    is_acting = false;
    skill_animation_playing = false;

    // 狀態重置（強制重新評估）
    current_state = UNIT_STATE.IDLE;
    state_buffer_timer = 0;

    // 根據模式設置相應參數
    switch(ai_mode) {
        case AI_MODE.AGGRESSIVE:
            follow_target = noone;
            atb_paused = false;
            break;

        case AI_MODE.FOLLOW:
            if (instance_exists(global.player)) {
                follow_target = global.player;
            }
            atb_paused = false; // 可以戰鬥，不暫停ATB
            break;

        case AI_MODE.PASSIVE:
            if (instance_exists(global.player)) {
                follow_target = global.player;
            }
            atb_current = atb_max;
            atb_ready = false;
            atb_paused = true;
            break;
    }
};


// 積極模式狀態更新
update_aggressive_state = function() {
    // --- 狀態鎖定 (包含動畫播放和攻擊後冷卻) ---
    if (skill_animation_playing || attack_cooldown_timer > 0) {
        return; // 動畫播放中或剛攻擊完，不切換狀態
    }
    // --- 狀態鎖定結束 ---

    // 明確清除跟隨目標，確保不會跟隨玩家
    follow_target = noone;
    
    // 如果正在攻擊，僅更新關鍵狀態
    if (is_attacking) {
        return;
    }
    
    // 如果ATB未滿，進入閒置狀態
    if (!atb_ready) {
        current_state = UNIT_STATE.IDLE;
        move_to_target_timer = 0;
        return;
    }
    
    // 檢查目標
    if (target == noone || !instance_exists(target) || target.dead) {
        find_new_target();
        if (target == noone) {
            current_state = UNIT_STATE.IDLE;
            atb_paused = true;
            move_to_target_timer = 0;
            return;
        }
    }
    
    // 如果已經在移動狀態，先完成當前的移動
    if (current_state == UNIT_STATE.MOVE_TO_TARGET) {
        // 只在到達目標位置時才重新評估
        var distance_to_target = point_distance(x, y, target.x, target.y);
        if (current_skill != noone && distance_to_target <= current_skill.range) {
            current_state = UNIT_STATE.ATTACK;
            atb_paused = false;
            move_to_target_timer = 0;
        } else {
            // 繼續移動，更新移動計時器
            move_to_target_timer++;
            if (move_to_target_timer >= move_to_target_timeout) {
                current_state = UNIT_STATE.IDLE;
                target = noone;
                move_to_target_timer = 0;
                show_debug_message(object_get_name(object_index) + " 追逐超時，重置目標");
            }
        }
        return;
    }
    
    // 只有在非移動狀態下才重新評估攻擊選項
    if (current_state == UNIT_STATE.IDLE) {
        var distance_to_target = point_distance(x, y, target.x, target.y);
        choose_skill();
        
        if (current_skill != noone && distance_to_target <= current_skill.range) {
            current_state = UNIT_STATE.ATTACK;
            atb_paused = false;
            move_to_target_timer = 0;
        } else {
            current_state = UNIT_STATE.MOVE_TO_TARGET;
            atb_paused = true;
            move_to_target_timer = 0;
        }
    }
}

// 跟隨模式狀態更新
update_follow_state = function() {
    // --- 狀態鎖定 (包含動畫播放和攻擊後冷卻) ---
    if (skill_animation_playing || attack_cooldown_timer > 0) {
        return; // 動畫播放中或剛攻擊完，不切換狀態
    }
    // --- 狀態鎖定結束 ---

    // 確保跟隨目標設置正確
    if (follow_target == noone && instance_exists(global.player)) {
        follow_target = global.player;
    }
    
    // 檢查與主人的距離
    if (instance_exists(follow_target)) {
        var dist_to_player = point_distance(x, y, follow_target.x, follow_target.y);
        
        // 檢查玩家是否在移動
        var player_moving = (follow_target.x != follow_target.xprevious || 
                           follow_target.y != follow_target.yprevious);
        
        // 在跟隨範圍內的行為
        if (dist_to_player <= follow_radius * 0.6) {
            if (!player_moving && atb_ready && state_buffer_timer <= 0) {
                if (!is_moving) {  // 只有在自己不移動時才準備攻擊
                    prepare_action();
                }
            }
        } else {
            // 超出範圍時進入跟隨狀態
            current_state = UNIT_STATE.FOLLOW;
        }
    }
}

update_passive_state = function() {
    // --- 狀態鎖定 (包含動畫播放和攻擊後冷卻) ---
    if (skill_animation_playing || attack_cooldown_timer > 0) {
        return; // 動畫播放中或剛攻擊完，不切換狀態
    }
    // --- 狀態鎖定結束 ---

    // 如果正在攻擊，立即停止攻擊
    if (is_attacking) {
        target = noone;
        atb_paused = true;
        current_state = UNIT_STATE.IDLE;
        return;
    }

    // 確保跟隨目標設置正確
    if (follow_target == noone && instance_exists(global.player)) {
        follow_target = global.player;
    }

    // 清除任何攻擊目標
    target = noone;

    if (instance_exists(follow_target)) {
        var dist_to_player = point_distance(x, y, follow_target.x, follow_target.y);

        // 使用狀態緩衝避免來回切換
        if (current_state == UNIT_STATE.FOLLOW && dist_to_player <= follow_radius * 0.35) {
            current_state = UNIT_STATE.IDLE;
        } else if (current_state == UNIT_STATE.IDLE && dist_to_player > follow_radius * 0.45) {
            current_state = UNIT_STATE.FOLLOW;
        }

    } else {
        current_state = UNIT_STATE.IDLE;
    }

    // 維持 ATB 滿格，但不主動攻擊
    atb_current = atb_max;
    atb_ready = false;
    atb_paused = true;
}


// 修改 execute_state_behavior 函數
execute_state_behavior = function() {
    // 檢查玩家是否在移動
    var player_moving = false;
    var player_moved_distance = 0;
    if (instance_exists(follow_target)) {
        var dx = follow_target.x - follow_target.xprevious;
        var dy = follow_target.y - follow_target.yprevious;
        player_moved_distance = point_distance(0, 0, dx, dy);
        player_moving = (player_moved_distance > 2); // 加入移動閾值
    }

    switch(current_state) {
        case UNIT_STATE.IDLE:
            // 閒置狀態：根據AI模式和玩家狀態決定下一步行動
            if (ai_mode == AI_MODE.AGGRESSIVE) {
                // 積極模式：尋找目標
                if (target == noone || !instance_exists(target)) {
                    find_new_target();
                }
                if (target != noone) {
                    current_state = UNIT_STATE.MOVE_TO_TARGET;
                    move_to_target_timer = 0;
                }
            } else if (ai_mode == AI_MODE.FOLLOW) {
                // 跟隨模式：檢查是否需要跟隨或攻擊
             if (instance_exists(follow_target)) {
            var dist = point_distance(x, y, follow_target.x, follow_target.y);
            if (dist > follow_radius * 0.7) {
                current_state = UNIT_STATE.FOLLOW;
                move_to_target_timer = 0;
            } else if (atb_ready && current_skill != noone && instance_exists(target)) {
                current_state = UNIT_STATE.MOVE_TO_TARGET;
                move_to_target_timer = 0;
            } else {
                target = noone; // 清空target，避免進入錯誤狀態
            }
        }
    }
            break;
            
case UNIT_STATE.FOLLOW:
    // 如果正在攻擊或技能動畫播放中，則強制執行攻擊流程，不允許中斷
    if (is_attacking || skill_animation_playing) {
        break;
    }

    // 跟隨狀態：向主人移動
    if (ai_mode == AI_MODE.AGGRESSIVE) {
        current_state = UNIT_STATE.IDLE;
        move_to_target_timer = 0;
        follow_target = noone;
        break;
    }

    if (instance_exists(follow_target)) {
        var move_dir = point_direction(x, y, follow_target.x, follow_target.y);
        var follow_speed = move_speed;
        
        // 移動
        x += lengthdir_x(follow_speed, move_dir);
        y += lengthdir_y(follow_speed, move_dir);
        
        // 設置移動狀態以更新動畫
        is_moving = true;
        
        // 檢查是否到達跟隨範圍
        var dist = point_distance(x, y, follow_target.x, follow_target.y);
        if (dist <= follow_radius * 0.3) {
            current_state = UNIT_STATE.IDLE;
            move_to_target_timer = 0;
        }
    }
    break;

            
case UNIT_STATE.MOVE_TO_TARGET:
    // 新增的檢查條件，確保每次更新都有效
    if (!atb_ready || current_skill == noone || !instance_exists(target)) {
        current_state = UNIT_STATE.IDLE;
        move_to_target_timer = 0;
        target = noone; // 清除無效目標
        break;
    }

    // 【關鍵修改】：只有在未準備攻擊時才會因玩家移動切回跟隨
    if (player_moving && ai_mode == AI_MODE.FOLLOW && !atb_ready) {
        current_state = UNIT_STATE.FOLLOW;
        move_to_target_timer = 0;
        target = noone;
        break;
    }

    var dist = point_distance(x, y, target.x, target.y);
    
    // 檢查是否在攻擊範圍內
    if (dist <= current_skill.range) {
        current_state = UNIT_STATE.ATTACK;
        move_to_target_timer = 0;
    } else {
        // 移動接近目標
        move_towards_target();
        is_moving = true;

        // 更新移動計時器
        move_to_target_timer++;
        if (move_to_target_timer >= move_to_target_timeout) {
            // 超時回到IDLE
            current_state = UNIT_STATE.IDLE;
            target = noone;
            move_to_target_timer = 0;
        }
    }
    break;



            
        case UNIT_STATE.ATTACK:
            if (!is_attacking && !skill_animation_playing) {
                if (current_skill != noone && target != noone && instance_exists(target)) {
                    start_skill_animation();
                } else {
                    // 如果沒有有效的技能或目標，重置狀態
                    current_state = UNIT_STATE.IDLE;
                    is_attacking = false;
                    skill_animation_playing = false;
                    show_debug_message(object_get_name(object_index) + " 攻擊取消：無效的技能或目標");
                }
            }
            break;
            
        case UNIT_STATE.DEAD:
            current_animation = UNIT_ANIMATION.DIE;
            break;
    }
}

// 移動接近目標
move_towards_target = function() {
    if (target == noone || !instance_exists(target)) {
        return;
    }
    
    // 設置移動指令狀態
    is_moving_command = true;
    movement_lock_timer = MOVEMENT_LOCK_TIME;
    
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

    // --- 修改：直接使用 image_index ---
    var _frame_data = animation_frames[$ current_animation];
    if (is_array(_frame_data)) {
         image_index = _frame_data[0]; // 將 image_index 設為攻擊動畫的起始幀
         // animation_timer = 0; // 如果使用基於 timer 的手動更新，也重置 timer (如果 animation_timer 存在)
    }
    // --- 修改結束 ---

    show_debug_message(object_get_name(object_index) + " 開始使用技能: " + current_skill.name);
}

// 應用技能傷害
apply_skill_damage = function() {
    if (target == noone || !instance_exists(target) || target.dead || current_skill == noone) { // 添加 current_skill 檢查
        show_debug_message("應用傷害取消：無效的目標或技能。");
        // 可能需要重置某些狀態如果在這裡中止
        end_skill_animation(); // 提前結束防止卡住
        return;
    }
    
    skill_damage_triggered = true;
    
    // --- 動態計算傷害 ---
    // 獲取技能的傷害倍率，如果不存在則預設為 0
    var multiplier = variable_struct_exists(current_skill, "damage_multiplier") ? current_skill.damage_multiplier : 0;
    // 獲取攻擊者的當前攻擊力
    var attacker_attack = attack; // 直接讀取自身 attack 值
    // 計算基礎傷害
    var calculated_damage = attacker_attack * multiplier;
    show_debug_message("基礎傷害 (攻擊力×倍率)：" + string(calculated_damage));
    
    var target_defense = 0;
    if (variable_instance_exists(target, "defense") && is_real(target.defense)) {
        target_defense = target.defense;
        show_debug_message("目標防禦力：" + string(target_defense));
    } else {
        show_debug_message("警告：目標防禦力無效，使用預設值 0");
    }
    
    calculated_damage = max(1, calculated_damage - target_defense);
    show_debug_message("最終傷害 (考慮防禦後)：" + string(calculated_damage));
    show_debug_message("------------------------");
    
    // 應用傷害
    with (target) {
        take_damage(calculated_damage, other.id, other.current_skill.id);
    }
    
    // 特效處理
    var particle_effect_name = variable_struct_exists(current_skill, "particle_effect") ? current_skill.particle_effect : "";
    if (variable_global_exists("particle_system") && particle_effect_name != "") {
        show_debug_message("觸發特效：" + particle_effect_name);
    }
}

// 結束技能動畫
end_skill_animation = function() {
    // 重置動畫狀態
    skill_animation_playing = false;
    is_attacking = false;
    is_acting = false;

    // 設置攻擊後短暫冷卻
    attack_cooldown_timer = 5; // 例如 5 幀

    // 設置技能冷卻
    if (current_skill != noone) {
        // 以 array 索引設置冷卻
        var idx = -1;
        for (var i = 0; i < array_length(skills); i++) {
            if (skills[i].id == current_skill.id) { idx = i; break; }
        }
        if (idx != -1) {
            skill_cooldowns[idx] = current_skill.cooldown;
        }
    }

    // 重置ATB與暫停狀態
    atb_current = 0;
    atb_ready = false;
    atb_paused = false;

    // 恢復閒置動畫和狀態
    current_animation = UNIT_ANIMATION.IDLE;
    current_state = UNIT_STATE.IDLE; // <-- 直接設置狀態為 IDLE

    // --- 確保 image_index 也被重置 ---
    var _idle_frame_data = animation_frames[$ current_animation]; // 現在 current_animation 是 IDLE
    if (is_array(_idle_frame_data)) {
        image_index = _idle_frame_data[0];
         // animation_timer = 0; // 如果使用 timer
    }
    // --- 修改結束 ---

    show_debug_message(object_get_name(object_index) + " 完成技能: " +
                      (current_skill != noone ? current_skill.name : "未知"));

    // 清除當前技能
    current_skill = noone;
};


// 受到傷害處理
take_damage = function(damage_amount, source_id, skill_id) {
    hp -= damage_amount;
    show_debug_message(object_get_name(object_index) + " 受到 " + string(damage_amount) + " 點傷害。");

    // --- 創建跳血文字 --- 
    if (object_exists(obj_floating_text)) { // <-- 修改：使用 object_exists 檢查物件資源是否存在
        // show_debug_message("Attempting to create floating text at " + string(x) + "," + string(y-32) + " on layer 'Effects'"); // REMOVED LOG
        var _text_instance = instance_create_layer(x, y - 32, "Effects", obj_floating_text);
        if (instance_exists(_text_instance)) { // 這裡用 instance_exists 檢查創建是否成功是正確的
            _text_instance.display_text = string(damage_amount);
            _text_instance.text_color = c_red;
            _text_instance.x += random_range(-5, 5);
            // show_debug_message("Floating text instance ID: " + string(_text_instance.id) + ", Text: '" + _text_instance.display_text + "', Color: " + string(_text_instance.text_color) + ", Initial Alpha: " + string(_text_instance.image_alpha)); // REMOVED LOG
        } else {
            // show_debug_message("!!! Failed to create floating text instance on layer 'Effects'!"); // REMOVED LOG (或保留作為錯誤處理)
        }
    } else {
        // show_debug_message("!!! obj_floating_text object resource not found in project!"); // REMOVED LOG (或保留作為錯誤處理)
    }
    // --- 跳血文字結束 ---
    
    // 檢查是否死亡
    if (hp <= 0) {
        hp = 0;
        die();
    } else {
        // --- 受傷特效 (之前已添加) ---
        instance_create_layer(x, y, "Effects", obj_hurt_effect);
        // show_debug_message("Hurt effect instance created for " + object_get_name(object_index));
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
            unit_instance: id,
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
    // 直接遍歷 array
    for (var i = 0; i < array_length(skill_cooldowns); i++) {
        if (skill_cooldowns[i] > 0) {
            skill_cooldowns[i]--;
        }
    }
}

// 檢測移動狀態並更新動畫
is_moving = (x != last_x || y != last_y);

// 檢查玩家移動
var player_moving = false;
if (instance_exists(follow_target)) {
    var dx = follow_target.x - follow_target.xprevious;
    var dy = follow_target.y - follow_target.yprevious;
    player_moving = (point_distance(0, 0, dx, dy) > 4);
}

// 狀態緩衝處理
if (state_buffer_timer > 0) {
    state_buffer_timer--;
    // 在緩衝期間保持當前狀態
    if (current_state != last_state) {
        current_state = last_state;
    }
}



// 當狀態改變時設置緩衝
if (current_state != last_state) {
    if (last_state == UNIT_STATE.FOLLOW || last_state == UNIT_STATE.MOVE_TO_TARGET) {
        state_buffer_timer = state_buffer_time;
    }
    last_state = current_state;
}

// 更新技能冷卻
update_skill_cooldowns();



// 立即執行初始化
initialize();

// 遊蕩相關變數
wander_timer = 0;             // 計時器，決定何時改變遊蕩目標或暫停
wander_target_x = x;          // 當前遊蕩目標點 X
wander_target_y = y;          // 當前遊蕩目標點 Y
wander_state = 0;             // 遊蕩子狀態：0=選擇目標/移動, 1=暫停
wander_radius = 64;           // 遊蕩範圍半徑 (以初始位置為中心)
wander_pause_duration = 1 * game_get_speed(gamespeed_fps); // 每次遊蕩後暫停時間 (例如1秒)
spawn_x = x;                  // 記錄初始位置 X
spawn_y = y;                  // 記錄初始位置 Y