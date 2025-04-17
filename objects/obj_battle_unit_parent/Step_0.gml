// 檢測移動狀態並更新動畫 (保持在最開頭)
is_moving = (x != last_x || y != last_y);

var _wander_warn = [];
if (!variable_instance_exists(self, "wander_timer")) { wander_timer = 0; array_push(_wander_warn, "wander_timer"); }
if (!variable_instance_exists(self, "wander_radius")) { wander_radius = 64; array_push(_wander_warn, "wander_radius"); }
if (!variable_instance_exists(self, "wander_target_x")) { wander_target_x = x; array_push(_wander_warn, "wander_target_x"); }
if (!variable_instance_exists(self, "wander_target_y")) { wander_target_y = y; array_push(_wander_warn, "wander_target_y"); }
if (!variable_instance_exists(self, "wander_state")) { wander_state = 0; array_push(_wander_warn, "wander_state"); }
if (!variable_instance_exists(self, "wander_pause_duration")) { wander_pause_duration = 1 * game_get_speed(gamespeed_fps); array_push(_wander_warn, "wander_pause_duration"); }
if (!variable_instance_exists(self, "spawn_x")) { spawn_x = x; array_push(_wander_warn, "spawn_x"); }
if (!variable_instance_exists(self, "spawn_y")) { spawn_y = y; array_push(_wander_warn, "spawn_y"); }
if (array_length(_wander_warn) > 0) {
    show_debug_message("[警告] 遊蕩參數未初始化: " + array_join(_wander_warn, ", ") + "。物件:" + object_get_name(object_index) + " id:" + string(id) + "，請檢查子類是否有正確呼叫 event_inherited()。");
}

// --- 修改：判斷是否處於任何戰鬥相關階段 (非 INACTIVE) ---
var _is_battle_initiated = (instance_exists(obj_battle_manager) && obj_battle_manager.battle_state != BATTLE_STATE.INACTIVE);

// --- 根據是否處於戰鬥相關階段執行不同邏輯 ---
if (_is_battle_initiated) {
    // ##################################
    // ### 開始：包裹原始戰鬥邏輯 ###
    // ##################################

    // --- 遞減攻擊後冷卻計時器 --- (移入)
    if (attack_cooldown_timer > 0) {
        attack_cooldown_timer--;
    }
    // --- 冷卻計時器結束 --- (移入)

    // 更新全局戰鬥計時器 (移入)
    if (variable_global_exists("battle_timer")) {
        global.battle_timer++;
    }

    // 移除原來的戰鬥狀態檢查 (已被 _is_battle_initiated 取代)
    // if (!instance_exists(obj_battle_manager) || obj_battle_manager.battle_state != BATTLE_STATE.ACTIVE) {
    //     return;
    // }

    // 死亡狀態處理 (修改：移除 return)
    if (dead) {
        current_state = UNIT_STATE.DEAD;
        current_animation = UNIT_ANIMATION.DIE;
        // return; // <-- 移除 return，讓後面的動畫邏輯處理死亡動畫播放
    }

    // 更新ATB等邏輯 (只在非死亡時執行) (移入)
    // 將 !dead 檢查移到外面，保護 ATB 和狀態機
    if (!dead) {
        // 更新ATB (只在 ACTIVE 狀態且非暫停且非滿格狀態)
        if (!atb_ready && !is_acting && !atb_paused) {
            // 新增條件：只在 ACTIVE 狀態下充能 ATB
            if (instance_exists(obj_battle_manager) && obj_battle_manager.battle_state == BATTLE_STATE.ACTIVE) {
                if (state_buffer_timer <= 0) {
                    atb_current += atb_rate;
                    if (atb_current >= atb_max) {
                        atb_current = atb_max;
                        atb_ready = true; // 標記 ATB 已就緒
                        choose_target_and_skill(); // 選擇目標和技能，供狀態機後續使用
                    }
                }
            }
            // 注意：原始碼在 state_buffer_timer > 0 時沒有 else 處理，保持原樣
        }

        // 更新技能冷卻 (移入)
        update_skill_cooldowns();

        // 執行狀態機更新 (移入)
        update_state_machine();
    } // 結束 !dead 檢查

    // 根據移動方向更新動畫 (戰鬥中) (移入)
    // 只在非死亡狀態下根據移動設置動畫，避免覆蓋死亡動畫
    if (!dead) {
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
            // 不移動且非攻擊狀態時使用閒置動畫 (戰鬥中)
            // 僅當狀態機也認為是 IDLE 時才切換，確保安全
             if (current_state == UNIT_STATE.IDLE) {
                 current_animation = UNIT_ANIMATION.IDLE;
             }
        }
    } // 結束 !dead 檢查 (用於動畫設定)

    // --- 移除舊的、基於 image_speed 和 frame_range 的動畫處理 (約原始碼 66-122 行) ---
    // 這部分與後面基於 animation_timer 的邏輯衝突
    /*
    // 根據當前動畫設置圖像速度
    if (current_animation == UNIT_ANIMATION.IDLE) { ... }
    // 根據當前動畫設置sprite範圍
    var frame_range; switch(current_animation) { ... }
    // 動畫更新邏輯
    if (is_array(frame_range)) { ... }
    */

    // ##################################
    // ### 結束：包裹原始戰鬥邏輯 ###
    // ##################################

} else {
    // --- 非戰鬥狀態邏輯 ---
    if (dead) {
        // 非戰鬥時死亡
        current_state = UNIT_STATE.DEAD;
        current_animation = UNIT_ANIMATION.DIE;
        // speed = 0; // 由下方 is_moving 控制動畫即可
        is_moving = false;
    } else {
        // --- 開始：非戰鬥時的遊蕩邏輯 ---
        
        // 狀態機：控制 IDLE 和 WANDER 切換
        if (current_state != UNIT_STATE.WANDER && current_state != UNIT_STATE.IDLE) {
             // 如果從其他狀態(例如戰鬥剛結束)切換過來，先設為 IDLE
             current_state = UNIT_STATE.IDLE;
             wander_timer = wander_pause_duration; // 開始暫停計時
             wander_state = 1; // 設為暫停子狀態
             is_moving = false;
             current_animation = UNIT_ANIMATION.IDLE;
        }

        if (wander_timer > 0) { // 減少計時器
            wander_timer--;
        }

        if (current_state == UNIT_STATE.IDLE) {
            is_moving = false;
            current_animation = UNIT_ANIMATION.IDLE;
            if (wander_timer <= 0) {
                // 暫停結束，切換到遊蕩狀態，找新目標
                current_state = UNIT_STATE.WANDER;
                wander_state = 0; // 設為移動子狀態
                
                // 在 spawn 點周圍隨機選擇一個目標點
                var wander_angle = random(360);
                var wander_dist = random(wander_radius);
                wander_target_x = spawn_x + lengthdir_x(wander_dist, wander_angle);
                wander_target_y = spawn_y + lengthdir_y(wander_dist, wander_angle);
                
                // (可選) 限制目標點在可行走區域內 (如果需要更複雜的遊蕩)
            }
        } 
        else if (current_state == UNIT_STATE.WANDER) {
            // 計算到目標點的距離
            var dist_to_wander_target = point_distance(x, y, wander_target_x, wander_target_y);
            
            if (dist_to_wander_target > move_speed * 0.5) {
                // 還沒到達目標點，繼續移動
                var move_dir = point_direction(x, y, wander_target_x, wander_target_y);
                // 使用 move_speed 的一半進行遊蕩移動
                x += lengthdir_x(move_speed * 0.5, move_dir);
                y += lengthdir_y(move_speed * 0.5, move_dir);
                is_moving = true; // 正在移動

                // --- 更新移動動畫 (複製戰鬥邏輯中的方向判斷) ---
                 var angle_segment = (move_dir + 22.5) mod 360;
                 var animation_index = floor(angle_segment / 45);
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
                 // --- 動畫更新結束 ---

            } else {
                // 到達目標點，切換回 IDLE 狀態並開始暫停
                x = wander_target_x; // 校準位置
                y = wander_target_y;
                current_state = UNIT_STATE.IDLE;
                wander_timer = wander_pause_duration + random_range(-0.2, 0.2) * wander_pause_duration; // 加入少量隨機暫停時間
                wander_state = 1; // 設為暫停子狀態
                is_moving = false;
                current_animation = UNIT_ANIMATION.IDLE;
            }
        }

        // 重置戰鬥相關標誌 (保留原本的重置邏輯)
        atb_current = 0;
        atb_ready = false;
        atb_paused = false; // 非戰鬥時不應暫停ATB，但也不充能
        target = noone;
        current_skill = noone;
        is_acting = false;
        is_attacking = false;
        skill_animation_playing = false;
        attack_cooldown_timer = 0;
        state_buffer_timer = 0;
        // var _skill_keys = is_struct(skill_cooldowns) ? variable_struct_get_names(skill_cooldowns) : ds_map_keys_to_array(skill_cooldowns); // 型別安全取得 key
        // for (var i = 0; i < array_length(_skill_keys); i++) { ds_map_set(skill_cooldowns, _skill_keys[i], 0); }

        // --- 結束：非戰鬥時的遊蕩邏輯 ---
    }
    // --- 非戰鬥邏輯結束 ---
}

// --- 通用動畫更新邏輯 (來自原始碼約 153 行開始，現在在 if/else 之外) ---
// 這段邏輯現在無論是否戰鬥都會執行，根據上面設置的 current_animation 來播放
if (instance_exists(self)) // 移除 !dead 檢查，死亡動畫也需要更新
{
    // --- 使用 switch 獲取幀範圍 --- (保留原邏輯)
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
             // 如果 current_animation 是未知的，嘗試設為 IDLE
             // show_debug_message("警告: 通用動畫更新中未知的 current_animation: " + string(current_animation));
             current_animation = UNIT_ANIMATION.IDLE;
             // 假設 IDLE 幀數據總是存在
             if (variable_struct_exists(animation_frames,"IDLE")) {
                _frame_data = animation_frames.IDLE;
             } else if (variable_struct_exists(animation_frames,"WALK_DOWN_RIGHT")) {
                 // Fallback to first animation if IDLE missing
                 _frame_data = animation_frames.WALK_DOWN_RIGHT;
             }
             break;
    }
    // --- switch 結束 ---

    if (is_array(_frame_data) && array_length(_frame_data) == 2)
    {
        var _start_frame = _frame_data[0];
        var _end_frame = _frame_data[1];
        var _frame_count = (_end_frame - _start_frame) + 1;

        // --- is_non_looping_animation 定義 --- (保留原邏輯)
        var is_non_looping_animation = (current_animation == UNIT_ANIMATION.ATTACK ||
                                        current_animation == UNIT_ANIMATION.HURT ||
                                        current_animation == UNIT_ANIMATION.DIE);

        // --- _base_speed 計算 --- (保留原邏輯)
        // 注意：原碼這裡的 animation_speed 和 idle_animation_speed 是 Create 事件變數
        var _base_speed = (current_animation == UNIT_ANIMATION.IDLE) ? idle_animation_speed : animation_speed;

        // --- 動畫計時器更新 --- (保留原邏輯)
        var animation_name = string(current_animation);
        if (animation_name != current_animation_name) {
            current_animation_name = animation_name;
            image_index = _start_frame; // 切換動畫時，從起始幀開始
            animation_timer = 0; // 重置計時器
        } else {
            // 正常推進計時器
            animation_timer += _base_speed;
        }

        // --- 計算並更新 image_index --- (保留原邏輯)
        var _frames_to_advance = floor(animation_timer);
        if (_frames_to_advance > 0)
        {
            animation_timer -= _frames_to_advance; // 減去已處理的時間

            // 如果是非循環動畫且已在最後一幀，則不再前進 (防止越過)
            if (is_non_looping_animation && image_index >= _end_frame) {
                 _frames_to_advance = 0;
            }
            // 更新 image_index (只在需要推進時更新)
            if (_frames_to_advance > 0) {
                // 再次檢查，確保不會超過結束幀
                if (is_non_looping_animation && image_index + _frames_to_advance > _end_frame) {
                     _frames_to_advance = _end_frame - image_index;
                }
                if (_frames_to_advance > 0) { // 處理可能變為 0 的情況
                    image_index += _frames_to_advance;
                }
            }
        }

        // --- 檢查傷害觸發和動畫結束 (修改：添加 _is_battle_initiated 條件) ---
        // 這個檢查必須在 image_index 更新之後
        if (current_animation == UNIT_ANIMATION.ATTACK) {
            // 只有在戰鬥中才檢查傷害和結束
            if (_is_battle_initiated && skill_animation_playing) {
                 // 檢查傷害觸發幀 (保留原邏輯)
                 if (!skill_damage_triggered && current_skill != noone && variable_struct_exists(current_skill, "anim_damage_frames") && is_array(current_skill.anim_damage_frames))
                 {
                     var _damage_frames = current_skill.anim_damage_frames;
                     for (var i = 0; i < array_length(_damage_frames); i++) {
                         // 使用 floor 比較，以防 image_index 是小數
                         // 檢查是否正好到達或越過觸發幀
                          var current_frame_floor = floor(image_index);
                          var previous_frame_floor = floor(image_index - _frames_to_advance); // 估計上一幀
                          if (current_frame_floor >= _damage_frames[i] && previous_frame_floor < _damage_frames[i]) {
                             apply_skill_damage();
                             break; // 觸發一次即可
                         }
                     }
                 }
                 // 檢查動畫是否結束 (保留原邏輯)
                 if (image_index >= _end_frame) {
                     end_skill_animation(); // 只有戰鬥中攻擊動畫結束才呼叫
                 }
            }
            // 如果不在戰鬥中，攻擊動畫播完就停在最後一幀 (由下面的範圍檢查處理)
        }
        // --- 檢查 HURT 和 DIE 動畫結束 (保留原邏輯) ---
        // 死亡動畫結束後停留在最後一幀，等待 Timer 控制銷毀實例
        // 受傷動畫結束後停留在最後一幀，等待 Timer 或狀態機恢復
        else if (current_animation == UNIT_ANIMATION.HURT && image_index >= _end_frame) {
             image_index = _end_frame; // 停在最後一幀
        }
        else if (current_animation == UNIT_ANIMATION.DIE && image_index >= _end_frame) {
             image_index = _end_frame; // 停在最後一幀
        }
        // --- 處理循環動畫和範圍限制 --- (保留原邏輯)
        else if (!is_non_looping_animation || current_animation == UNIT_ANIMATION.IDLE) // IDLE 也循環
        {
             // 如果 image_index 超過結束幀，則計算超出量並從起始幀開始
             if (image_index > _end_frame)
             {
                 // 修正：原碼 _frame_count > 1 不正確，應為 > 0 且避免除零
                 if (_frame_count > 0) {
                      // 確保 image_index - _start_frame 不為負
                      var frame_diff = max(0, image_index - _start_frame);
                      image_index = _start_frame + (frame_diff mod _frame_count);
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

        // --- 範圍最終檢查 (保留原邏輯) ---
        // 這個檢查必須在所有更新之後
        if (image_index < _start_frame) {
             image_index = _start_frame;
        } else if (image_index > _end_frame) {
             // 如果是循環動畫，上面已經處理了，這裡主要是處理非循環動畫
             if (is_non_looping_animation) {
                 image_index = _end_frame; // 確保非循環動畫停在最後
             } else if (_frame_count > 0) {
                 // 再次處理循環，以防萬一
                 image_index = _start_frame + ((max(0, image_index - _start_frame)) mod _frame_count);
             } else {
                  image_index = _start_frame;
             }
        }

    } else {
         // 如果找不到幀範圍或格式錯誤 (保留原邏輯)
         image_index = 0;
         // 可以考慮在這裡設置 image_speed = 0 避免 GMS 自動播放
         // image_speed = 0; // Step開頭已經設置了
         if (current_animation != undefined) {
            // show_debug_message("警告：動畫 " + string(current_animation) + " 的 frame_data 無效或未定義！");
         } else {
            // show_debug_message("警告：current_animation 未定義！");
         }
    }
} else {
     // 實例不存在時，可能需要記錄錯誤或無操作
     // show_debug_message("警告：嘗試更新不存在的實例動畫！");
}
// --- 手動動畫更新結束 ---

// --- 移除 Step 事件末尾的 speed = 0 區塊 ---
// hspeed = 0;
// vspeed = 0;
// speed = 0;

// 追蹤上一幀的位置 (保持在最後)
last_x = x;
last_y = y;
