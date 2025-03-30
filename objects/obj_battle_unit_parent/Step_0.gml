// 檢測移動狀態並更新動畫
is_moving = (x != last_x || y != last_y);

// --- 遞減攻擊後冷卻計時器 ---
if (attack_cooldown_timer > 0) {
    attack_cooldown_timer--;
}
// --- 冷卻計時器結束 ---

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

// 更新ATB (非暫停且非滿格狀態)
if (!atb_ready && !is_acting && !atb_paused) {
    if (state_buffer_timer <= 0) {
        atb_current += atb_rate;
        if (atb_current >= atb_max) {
            atb_current = atb_max;
            atb_ready = true; // 標記 ATB 已就緒
            
            // --- 修改：僅選擇目標和技能，不直接設置狀態 ---
            choose_target_and_skill(); // 選擇目標和技能，供狀態機後續使用
            
            // --- 移除以下直接設置狀態的邏輯 ---
            /*
            if (target != noone && current_skill != noone) {
                var dist_to_target = point_distance(x, y, target.x, target.y);
                if (dist_to_target > current_skill.range) {
                    current_state = UNIT_STATE.MOVE_TO_TARGET;
                    atb_paused = true;
                } else {
                    current_state = UNIT_STATE.ATTACK;
                    atb_paused = false;
                }
            } else {
                current_state = UNIT_STATE.IDLE;
            }
            */
           // --- 移除結束 ---
        }
    }
}

// 更新技能冷卻
update_skill_cooldowns();

// 執行狀態機更新
update_state_machine();

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

// --- 移除舊的技能動畫更新調用 ---
// if (skill_animation_playing) {
//     update_skill_animation(); // 已移除此函數
// }

// --- 移除舊的基於移動方向更新動畫的邏輯 ---
// if (is_moving && !is_attacking && !skill_animation_playing) {
//     // ... (計算方向並設置 current_animation 的 switch) ...
// } else if (!is_attacking && !skill_animation_playing) {
//     current_animation = UNIT_ANIMATION.IDLE;
// }

// --- 移除舊的根據 current_animation 設置 image_speed 的邏輯 ---
// if (current_animation == UNIT_ANIMATION.IDLE) { ... } else if (...) { ... }

// --- 移除舊的根據 current_animation 設置 frame_range 的邏輯 ---
// var frame_range;
// switch(current_animation) { ... }

// --- 移除舊的動畫更新邏輯 ---
// if (is_array(frame_range)) {
//    // ... (檢測動畫變更並重置 image_index 和 image_speed) ...
//    // ... (確保幀在範圍內) ...
// }

// --- 添加新的手動動畫更新邏輯 ---
if (instance_exists(self) && !dead) // 確保實例存在且未死亡
{
    // --- 修改：使用 switch 獲取幀範圍 ---
    var _frame_data = undefined;
    switch (current_animation) {
        case UNIT_ANIMATION.WALK_DOWN_RIGHT: _frame_data = animation_frames.WALK_DOWN_RIGHT; break;
        case UNIT_ANIMATION.WALK_UP_RIGHT:   _frame_data = animation_frames.WALK_UP_RIGHT; break;
        case UNIT_ANIMATION.WALK_UP_LEFT:    _frame_data = animation_frames.WALK_UP_LEFT; break;
        case UNIT_ANIMATION.WALK_DOWN_LEFT:  _frame_data = animation_frames.WALK_DOWN_LEFT; break;
        case UNIT_ANIMATION.WALK_DOWN:       _frame_data = animation_frames.WALK_DOWN; break;
        case UNIT_ANIMATION.WALK_RIGHT:      _frame_data = animation_frames.WALK_RIGHT; break;
        case UNIT_ANIMATION.WALK_UP:         _frame_data = animation_frames.WALK_UP; break;
        case UNIT_ANIMATION.WALK_LEFT:       _frame_data = animation_frames.WALK_LEFT; break;
        case UNIT_ANIMATION.IDLE:            _frame_data = animation_frames.IDLE; break;
        case UNIT_ANIMATION.ATTACK:          _frame_data = animation_frames.ATTACK; break;
        case UNIT_ANIMATION.HURT:            _frame_data = animation_frames.HURT; break;
        case UNIT_ANIMATION.DIE:             _frame_data = animation_frames.DIE; break;
        default:
             // 如果 current_animation 是未知的，保持 _frame_data 為 undefined
             break;
    }
    // --- 修改結束 ---

    if (is_array(_frame_data) && array_length(_frame_data) == 2)
    {
        var _start_frame = _frame_data[0];
        var _end_frame = _frame_data[1];
        var _frame_count = (_end_frame - _start_frame) + 1;

        // --- 將 is_non_looping_animation 定義移到這裡 ---
        var is_non_looping_animation = (current_animation == UNIT_ANIMATION.ATTACK || 
                                        current_animation == UNIT_ANIMATION.HURT || 
                                        current_animation == UNIT_ANIMATION.DIE);

        // 根據動畫類型選擇基礎速度
        var _base_speed = (current_animation == UNIT_ANIMATION.IDLE) ? idle_animation_speed : animation_speed;

        // 更新計時器
        animation_timer += _base_speed;

        // 計算應該前進多少幀
        var _frames_to_advance = floor(animation_timer);

        if (_frames_to_advance > 0)
        {
            animation_timer -= _frames_to_advance; // 減去已處理的時間

            // --- 特殊處理非循環動畫 (現在變數已在此範圍外定義) ---
            // var is_non_looping_animation = (...); // 從這裡移除定義

            // 如果是非循環動畫且已在最後一幀，則不再前進
            if (is_non_looping_animation && image_index >= _end_frame) {
                 _frames_to_advance = 0;
            }

            // 更新 image_index
            image_index += _frames_to_advance;
        }

        // --- 檢查傷害觸發和動畫結束 (僅在攻擊動畫播放時) ---
        if (current_animation == UNIT_ANIMATION.ATTACK && skill_animation_playing) 
        {
             // 檢查傷害觸發幀
             if (!skill_damage_triggered && current_skill != noone && variable_struct_exists(current_skill, "anim_damage_frames") && is_array(current_skill.anim_damage_frames))
             {
                 var _damage_frames = current_skill.anim_damage_frames;
                 for (var i = 0; i < array_length(_damage_frames); i++) {
                     // 使用 floor 比較，以防 image_index 是小數
                     if (floor(image_index) >= _damage_frames[i] && image_index < _damage_frames[i] + 1) { 
                         apply_skill_damage();
                         // skill_damage_triggered 會在 apply_skill_damage 中設置
                         break; // 觸發一次即可
                     }
                 }
             }
             
             // 檢查動畫是否結束
             if (image_index >= _end_frame) 
             {
                 end_skill_animation(); 
                 // end_skill_animation 會重置 skill_animation_playing, is_attacking 等
                 // 並將 current_animation 設為 IDLE，image_index 設為 IDLE 起始幀
                 // 所以這裡不需要再做其他處理，下一幀會自動開始播放 IDLE
             }
        }
        // --- 檢查 HURT 和 DIE 動畫結束 (如果需要特殊處理) ---
        else if (current_animation == UNIT_ANIMATION.HURT && image_index >= _end_frame) {
             // 受傷動畫結束後通常恢復 IDLE (可能由 Timer 控制，或在這裡直接處理)
             // 如果是由 Timer 控制 (如 set_timer(TIMER_TYPE.HURT_RECOVERY, ...))，則這裡可能不需要做什麼
             // 否則可以在這裡設置 current_animation = UNIT_ANIMATION.IDLE;
             // 並重置 image_index = animation_frames[UNIT_ANIMATION.IDLE][0];
             image_index = _end_frame; // 暫時停在最後一幀，等待 Timer 或其他邏輯切換
        } 
        else if (current_animation == UNIT_ANIMATION.DIE && image_index >= _end_frame) {
             // 死亡動畫結束後通常停留在最後一幀，等待實例銷毀 (由 Timer 控制)
             image_index = _end_frame; // 停留在死亡動畫的最後一幀
        }

        // --- 處理循環動畫和範圍限制 ---
        else if (!is_non_looping_animation || current_animation == UNIT_ANIMATION.IDLE) // IDLE 也循環
        { 
             // 如果 image_index 超過結束幀，則計算超出量並從起始幀開始
             if (image_index > _end_frame)
             {
                 if (_frame_count > 1) { 
                      image_index = _start_frame + ((image_index - _start_frame) mod _frame_count);
                 } else {
                      image_index = _start_frame; // 單幀動畫保持在起始幀
                 }
             }
             // 確保 image_index 不會小於起始幀
             else if (image_index < _start_frame)
             {
                  image_index = _start_frame;
             }
        }

        // 如果 image_index 意外地不在當前範圍內 (例如剛切換動畫)，強制設為起始幀
        // 這個檢查應該放在動畫推進之後
        if (image_index < _start_frame || (image_index > _end_frame && !is_non_looping_animation)) {
             image_index = _start_frame;
             animation_timer = 0; // 重置計時器以避免立即跳幀
        }
        // 對於非循環動畫，如果超過結束幀，將其限制在結束幀
        else if (is_non_looping_animation && image_index > _end_frame) {
             image_index = _end_frame;
        }

    } else {
         // 如果找不到幀範圍或格式錯誤，可以設置為默認幀或打印錯誤
         image_index = 0;
         if (current_animation != undefined) {
            show_debug_message("警告：動畫 " + string(current_animation) + " 的 frame_data 無效或未定義！");
         } else {
            show_debug_message("警告：current_animation 未定義！");
         }
         
    }
}
// --- 手動動畫更新結束 ---
