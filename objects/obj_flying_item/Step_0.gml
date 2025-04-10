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
            // 停頓結束，切換到飛向玩家狀態
            flight_state = FLYING_STATE.FLYING_TO_PLAYER;

            // 確保玩家存在，否則直接淡出
            if (!instance_exists(Player)) {
                flight_state = FLYING_STATE.FADING_OUT;
                fade_timer = 0;
                show_debug_message("飛行道具停頓結束，玩家不存在，直接淡出");
            } else {
                // 更新玩家目標座標
                player_target_x = Player.x;
                player_target_y = Player.y;
                show_debug_message("飛行道具停頓結束，開始飛向玩家 ("+string(player_target_x)+","+string(player_target_y)+")");
            }
        }
        break;

    case FLYING_STATE.FLYING_TO_PLAYER:
        // --- 飛向玩家 ---

        // 確保玩家仍然存在，否則直接淡出
        if (!instance_exists(Player)) {
            flight_state = FLYING_STATE.FADING_OUT;
            fade_timer = 0;
            show_debug_message("飛向玩家過程中玩家消失，切換到淡出");
            break;
        }

        // 更新玩家目標座標（玩家可能在移動）
        player_target_x = Player.x;
        player_target_y = Player.y;

        // 計算到玩家的距離
        var dist_to_player = point_distance(x, y, player_target_x, player_target_y);

        // 如果已經到達玩家附近，切換到淡出狀態
        if (dist_to_player < to_player_speed) {
            flight_state = FLYING_STATE.FADING_OUT;
            fade_timer = 0;
            show_debug_message("飛行道具已到達玩家附近，開始淡出");
        } else {
            // 向玩家方向移動
            var dir = point_direction(x, y, player_target_x, player_target_y);
            var move_x = lengthdir_x(to_player_speed, dir);
            var move_y = lengthdir_y(to_player_speed, dir);
            x += move_x;
            y += move_y;

            // 飛行過程中的視覺效果（保持原有縮放邏輯）
            image_xscale = max(0.5, image_xscale * 0.995);
            image_yscale = image_xscale;
        }
        break;

    case FLYING_STATE.FADING_OUT:
        // --- 淡出並消失 ---
        fade_timer++;

        // 計算淡出的透明度 (使用平方曲線使淡出更快)
        image_alpha = 1 - power(fade_timer / fade_duration, 1.5);

        // 同時更快縮小 (原為 0.97，已改為 0.93)
        image_xscale = max(0.2, image_xscale * 0.93);
        image_yscale = image_xscale;

        // 淡出完成後銷毀
        if (fade_timer >= fade_duration) {
            show_debug_message("飛行道具已完全淡出，銷毀");
            instance_destroy();
            exit;
        }
        break;
}

