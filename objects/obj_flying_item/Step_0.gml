/// @description 根據狀態處理飛行邏輯

// --- Step 除錯訊息 (每 30 幀打印一次，避免洗版) ---
if ((current_time mod 30) == 0) { 
    show_debug_message("obj_flying_item Step:");
    show_debug_message("- State: " + string(flight_state));
    show_debug_message("- Current Pos: (" + string(x) + ", " + string(y) + ")");
    show_debug_message("- Target: (" + string(target_x) + ", " + string(target_y) + ")");
    if (flight_state == FLYING_STATE.FLYING_UP) {
        var dist = point_distance(x, y, target_x, target_y);
        show_debug_message("- Distance to target: " + string(dist) + ", Threshold: " + string(move_speed));
    }
}

// 根據當前狀態處理飛行道具的行為
switch (flight_state) {
    
    case FLYING_STATE.FLYING_UP:
        // --- 向上飛行 ---
        var dist_to_target = point_distance(x, y, target_x, target_y);
        
        // 如果接近目標位置，切換到停頓狀態
        if (dist_to_target < move_speed) {
            // 確保精確到達目標位置
            x = target_x;
            y = target_y;
            flight_state = FLYING_STATE.PAUSING;
            pause_timer = 0; // 開始計時
            show_debug_message("飛行道具已到達目標高度 (" + string(x) + ", " + string(y) + ")，開始停頓");
        } else {
            // 正常向上飛行
            var dir = point_direction(x, y, target_x, target_y);
            var move_x = lengthdir_x(move_speed, dir);
            var move_y = lengthdir_y(move_speed, dir);
            x += move_x;
            y += move_y;
            
            // 飛行過程效果
            image_xscale = max(0.5, image_xscale * 0.995);
            image_yscale = image_xscale;
        }
        break;
        
    case FLYING_STATE.PAUSING:
        // --- 在目標位置停頓 ---
        pause_timer++;
        if (pause_timer >= pause_duration) {
            // 停頓結束，切換到淡出狀態
            flight_state = FLYING_STATE.FADING_OUT;
            fade_timer = 0;
            show_debug_message("飛行道具停頓結束，開始淡出");
        }
        break;
        
    case FLYING_STATE.FADING_OUT:
        // --- 淡出並消失 ---
        fade_timer++;
        
        // 計算淡出的透明度
        image_alpha = 1 - (fade_timer / fade_duration);
        
        // 同時輕微縮小
        image_xscale = max(0.2, image_xscale * 0.97);
        image_yscale = image_xscale;
        
        // 淡出完成後銷毀
        if (fade_timer >= fade_duration) {
            show_debug_message("飛行道具已完全淡出，銷毀");
            instance_destroy();
            exit;
        }
        break;
}

