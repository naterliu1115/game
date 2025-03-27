// 檢測移動狀態並更新動畫
is_moving = (x != last_x || y != last_y);

// 更新全局戰鬥計時器
if (variable_global_exists("battle_timer")) {
    global.battle_timer++;
}

// 只有在戰鬥狀態下更新
if (!instance_exists(obj_battle_manager) || obj_battle_manager.battle_state != BATTLE_STATE.ACTIVE) {
    return;
}

// 死亡狀態處理
if (dead) {
    current_state = UNIT_STATE.DEAD;
    current_animation = UNIT_ANIMATION.DIE;
    return;
}

// 根據AI模式更新跟隨目標
if (ai_mode == AI_MODE.AGGRESSIVE) {
    follow_target = noone; // 積極模式不跟隨
} else if ((ai_mode == AI_MODE.FOLLOW || ai_mode == AI_MODE.PASSIVE) && 
           follow_target == noone && instance_exists(global.player)) {
    follow_target = global.player;
}

// 更新ATB (非暫停且非滿格狀態)
if (!atb_ready && !is_acting && !atb_paused && ai_mode != AI_MODE.PASSIVE) {
    atb_current += atb_rate;
    
    if (atb_current >= atb_max) {
        atb_current = atb_max;
        atb_ready = true;
        // 准備行動
        prepare_action();
    }
}

// 更新技能冷卻
update_skill_cooldowns();

// 執行狀態機更新
update_state_machine();

// 如果正在播放技能動畫，更新動畫
if (skill_animation_playing) {
    update_skill_animation();
}

// 根據移動方向更新動畫
if (is_moving && !is_attacking && !skill_animation_playing) {
    // 計算移動方向
    var move_dir = point_direction(last_x, last_y, x, y);
    
    // 將360度分成8個區域，每個區域45度
    var angle_segment = (move_dir + 22.5) mod 360;
    var animation_index = floor(angle_segment / 45);
    
    // 選擇對應的動畫
    switch(animation_index) {
        case 0: current_animation = UNIT_ANIMATION.WALK_RIGHT; break;
        case 1: current_animation = UNIT_ANIMATION.WALK_UP_RIGHT; break;
        case 2: current_animation = UNIT_ANIMATION.WALK_UP; break;
        case 3: current_animation = UNIT_ANIMATION.WALK_UP_LEFT; break;
        case 4: current_animation = UNIT_ANIMATION.WALK_LEFT; break;
        case 5: current_animation = UNIT_ANIMATION.WALK_DOWN_LEFT; break;
        case 6: current_animation = UNIT_ANIMATION.WALK_DOWN; break;
        case 7: current_animation = UNIT_ANIMATION.WALK_DOWN_RIGHT; break;
    }
} else if (!is_attacking && !skill_animation_playing) {
    // 不移動且非攻擊狀態時使用閒置動畫
    current_animation = UNIT_ANIMATION.IDLE;
}

// 根據當前動畫設置圖像速度
if (current_animation == UNIT_ANIMATION.IDLE) {
    image_speed = 0.5;
} else if (current_animation == UNIT_ANIMATION.WALK_DOWN || 
           current_animation == UNIT_ANIMATION.WALK_UP || 
           current_animation == UNIT_ANIMATION.WALK_LEFT || 
           current_animation == UNIT_ANIMATION.WALK_RIGHT ||
           current_animation == UNIT_ANIMATION.WALK_DOWN_RIGHT ||
           current_animation == UNIT_ANIMATION.WALK_DOWN_LEFT ||
           current_animation == UNIT_ANIMATION.WALK_UP_RIGHT ||
           current_animation == UNIT_ANIMATION.WALK_UP_LEFT) {
    image_speed = 0.8;
} else if (current_animation == UNIT_ANIMATION.ATTACK) {
    image_speed = 1.0;
} else if (current_animation == UNIT_ANIMATION.HURT) {
    image_speed = 1.0;
} else if (current_animation == UNIT_ANIMATION.DIE) {
    image_speed = 0.5;
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

// 確保速度為0
hspeed = 0;
vspeed = 0;
speed = 0;

// 追蹤上一幀的位置
last_x = x;
last_y = y;
