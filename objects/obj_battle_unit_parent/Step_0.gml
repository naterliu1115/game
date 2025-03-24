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
    
    // 選擇對應的動畫（修正上下方向）
    switch(animation_index) {
        case 0: current_animation = UNIT_ANIMATION.WALK_RIGHT; break;
        case 1: current_animation = UNIT_ANIMATION.WALK_UP_RIGHT; break;  // 改為向上
        case 2: current_animation = UNIT_ANIMATION.WALK_UP; break;        // 改為向上
        case 3: current_animation = UNIT_ANIMATION.WALK_UP_LEFT; break;   // 改為向上
        case 4: current_animation = UNIT_ANIMATION.WALK_LEFT; break;
        case 5: current_animation = UNIT_ANIMATION.WALK_DOWN_LEFT; break; // 改為向下
        case 6: current_animation = UNIT_ANIMATION.WALK_DOWN; break;      // 改為向下
        case 7: current_animation = UNIT_ANIMATION.WALK_DOWN_RIGHT; break; // 改為向下
    }
} else {
    // 不移動時使用閒置動畫
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

// 動畫更新邏輯
if (is_array(frame_range)) {
    // 檢測動畫變更
    var animation_name = string(current_animation);
    if (animation_name != current_animation_name) {
        current_animation_name = animation_name;
        image_index = frame_range[0];
        image_speed = (current_animation == UNIT_ANIMATION.IDLE) ? 
            idle_animation_speed : animation_speed;
    }
    
    // 確保幀在正確範圍內
    if (image_index < frame_range[0] || image_index > frame_range[1]) {
        image_index = frame_range[0];
    }
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
