// 檢測移動狀態並更新動畫
is_moving = (x != last_x || y != last_y);

// 更新全局戰鬥計時器
if (variable_global_exists("battle_timer")) {
    global.battle_timer++;
}

// 如果正在移動，更新動畫方向
if (is_moving) {
    // 計算移動方向
    var move_dir = point_direction(last_x, last_y, x, y);
    
    // 將360度分成8個區域，每個區域45度
    var angle_segment = (move_dir + 22.5) mod 360;
    var animation_index = floor(angle_segment / 45);
    
    // 選擇對應的動畫，根據sprite佈局映射到正確的動畫枚舉
    switch(animation_index) {
        case 0: current_animation = UNIT_ANIMATION.WALK_RIGHT; break;
        case 1: current_animation = UNIT_ANIMATION.WALK_DOWN_RIGHT; break;
        case 2: current_animation = UNIT_ANIMATION.WALK_DOWN; break;
        case 3: current_animation = UNIT_ANIMATION.WALK_DOWN_LEFT; break;
        case 4: current_animation = UNIT_ANIMATION.WALK_LEFT; break;
        case 5: current_animation = UNIT_ANIMATION.WALK_UP_LEFT; break;
        case 6: current_animation = UNIT_ANIMATION.WALK_UP; break;
        case 7: current_animation = UNIT_ANIMATION.WALK_UP_RIGHT; break;
    }
} else {
    // 不移動時使用閒置動畫 (當前臨時用右下角移動代替)
    current_animation = UNIT_ANIMATION.IDLE;
}

// 根據當前動畫設置sprite範圍
var frame_range;
switch(current_animation) {
    case UNIT_ANIMATION.WALK_DOWN_RIGHT: frame_range = animation_frames.WALK_DOWN_RIGHT; break;
    case UNIT_ANIMATION.WALK_UP_RIGHT: frame_range = animation_frames.WALK_UP_RIGHT; break;
    case UNIT_ANIMATION.WALK_UP_LEFT: frame_range = animation_frames.WALK_UP_LEFT; break;
    case UNIT_ANIMATION.WALK_DOWN_LEFT: frame_range = animation_frames.WALK_DOWN_LEFT; break;
    case UNIT_ANIMATION.WALK_DOWN: frame_range = animation_frames.WALK_DOWN; break;
    case UNIT_ANIMATION.WALK_RIGHT: frame_range = animation_frames.WALK_RIGHT; break;
    case UNIT_ANIMATION.WALK_UP: frame_range = animation_frames.WALK_UP; break;
    case UNIT_ANIMATION.WALK_LEFT: frame_range = animation_frames.WALK_LEFT; break;
    case UNIT_ANIMATION.IDLE: frame_range = animation_frames.IDLE; break;
    case UNIT_ANIMATION.ATTACK: frame_range = animation_frames.ATTACK; break;
    case UNIT_ANIMATION.HURT: frame_range = animation_frames.HURT; break;
    case UNIT_ANIMATION.DIE: frame_range = animation_frames.DIE; break;
}

// 使用完全固定的動畫序列來確保顯示所有幀
if (is_array(frame_range)) {
    // 初始化動畫系統（只會在第一次執行時設定）
    if (!variable_instance_exists(id, "anim_timer")) {
        anim_timer = 0;
        frame_sequence = []; // 用於儲存完整的幀序列
        current_frame_index = 0; // 當前幀在序列中的索引
        current_animation_name = ""; // 用於檢測動畫變更
    }
    
    // 檢測動畫是否變更
    var animation_name = string(current_animation);
    if (animation_name != current_animation_name) {
        // 動畫變更，重新建立序列
        current_animation_name = animation_name;
        frame_sequence = [];
        
        // 對於IDLE和其他動畫，將所有幀添加到序列中
        var start_frame = frame_range[0];
        var end_frame = frame_range[1];
        
        // 強制添加所有幀到序列（確保包含end_frame）
        for (var i = start_frame; i <= end_frame; i++) {
            array_push(frame_sequence, i);
        }
        
        // 重置計數器
        current_frame_index = 0;
        anim_timer = 0;
        
        // 註釋掉調試幀序列創建
        /* 
        var seq_debug = "創建序列:[";
        for (var i = 0; i < array_length(frame_sequence); i++) {
            seq_debug += string(frame_sequence[i]);
            if (i < array_length(frame_sequence) - 1) seq_debug += ",";
        }
        seq_debug += "]";
        show_debug_message("[動畫初始化] " + object_get_name(object_index) + " " + seq_debug);
        */
    }
    
    // 更新計時器，使用動畫速度參數
    anim_timer += animation_speed;
    
    // 當計時器達到更新閾值時更新幀
    // 更新閾值由animation_update_rate控制，越小動畫越快
    if (anim_timer >= animation_update_rate) {
        anim_timer = 0;
        
        // 移動到序列中的下一幀
        current_frame_index = (current_frame_index + 1) % array_length(frame_sequence);
        
        // 設置當前幀
        image_index = frame_sequence[current_frame_index];
    }
    
    image_speed = 0; // 停用GameMaker的自動動畫
    
    // 註釋掉Debug輸出
    /*
    if (current_animation == UNIT_ANIMATION.IDLE && variable_global_exists("battle_timer") && global.battle_timer % 5 == 0) {
        var seq_info = "序列:[";
        for (var i = 0; i < array_length(frame_sequence); i++) {
            seq_info += string(frame_sequence[i]);
            if (i < array_length(frame_sequence) - 1) seq_info += ",";
        }
        seq_info += "]";
        
        show_debug_message("[動畫詳細] " + object_get_name(object_index) + " ID:" + string(id) + 
                          " 動畫:IDLE" + 
                          " 範圍:[" + string(frame_range[0]) + "," + string(frame_range[1]) + "]" + 
                          " 當前幀:" + string(image_index) + 
                          " 幀索引:" + string(current_frame_index) + "/" + string(array_length(frame_sequence)-1) + 
                          " " + seq_info + 
                          " 動畫速度:" + string(animation_speed));
    }
    */
}

// 保存當前位置用於下一幀檢測移動
last_x = x;
last_y = y;

// 确保速度为0
speed = 0;

// 只在战斗状态下更新
if (!instance_exists(obj_battle_manager) || obj_battle_manager.battle_state != BATTLE_STATE.ACTIVE || dead) {
    // 非战斗状态下不移动
    exit;
}

// 更新ATB
if (!atb_ready && !is_acting) {
    atb_current += atb_rate;
    
    // 註釋掉調試輸出
    /*
    if (variable_global_exists("battle_timer") && global.battle_timer % 60 == 0) {
        show_debug_message(object_get_name(object_index) + " (ID: " + string(id) + ", team: " + string(team) + ") ATB: " + string(atb_current) + "/" + string(atb_max) + " (率: " + string(atb_rate) + ")");
    }
    */
    
    if (atb_current >= atb_max) {
        atb_current = atb_max;
        atb_ready = true;
        // 准备行动
        prepare_action();
    }
}

// 更新技能冷却
var _keys = ds_map_keys_to_array(skill_cooldowns);
for (var i = 0; i < array_length(_keys); i++) {
    var _skill_id = _keys[i];
    var _cooldown = skill_cooldowns[? _skill_id];
    if (_cooldown > 0) {
        _cooldown--;
        ds_map_set(skill_cooldowns, _skill_id, _cooldown);
    }
}

// AI决策和行动
if (atb_ready && !is_acting) {
    execute_ai_action();
}
