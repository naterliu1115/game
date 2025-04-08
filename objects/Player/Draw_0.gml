/// @description 繪製玩家和裝備的工具

// 繪製玩家本身
draw_self();

// 只在挖礦時繪製礦錘（如果有裝備）
if (is_mining && equipped_tool_id == 5001) { // ID 檢查仍然需要

    // 使用新函數獲取動作 Sprite
    var sprite_to_draw = obj_item_manager.get_item_action_sprite(equipped_tool_id);

    // 檢查獲取的 Sprite 是否有效
    if (sprite_to_draw != -1 && sprite_exists(sprite_to_draw)) {

        // --- 之前的繪圖邏輯 (使用 sprite_to_draw) ---
        var current_frame = floor(mining_animation_frame);
        var frame_index = min(current_frame, 4);

        // 根據挖礦方向選擇正確的手部座標數組 和 角度數組
        var hand_positions;
        var tool_angles;
	    // 定義左右手揮動的角度 (使用您調整後的值)
	    var tool_angles_right = [0, 90, -20, -45, -60]; // 右手揮動動畫
	    var tool_angles_left  = [0, -90, 20, 45, 60]; // 左手揮動動畫

        if (mining_direction == PLAYER_ANIMATION.MINING_LEFT) {
            hand_positions = tool_attach_points_left;
		    tool_angles = tool_angles_left;
        } else { // PLAYER_ANIMATION.MINING_RIGHT
            hand_positions = tool_attach_points_right;
		    tool_angles = tool_angles_right;
        }

        // 取得當前幀的手部座標 (相對於玩家原點[16,16])
        var hand_x = hand_positions[frame_index][0];
        var hand_y = hand_positions[frame_index][1];

	    // 取得當前幀的工具角度
	    var tool_angle = tool_angles[frame_index];

        // 根據挖礦方向調整縮放
        var xscale = (mining_direction == PLAYER_ANIMATION.MINING_LEFT) ? -0.7 : 0.7;
	    var yscale = 0.7;

        // 計算玩家手部的目標世界座標
        var target_x = x + hand_x;
        var target_y = y + hand_y;
        // --- 結束之前的繪圖邏輯計算 --- 

        // --- 直接使用 draw_sprite_ext 繪製獲取的 sprite --- 
        draw_sprite_ext(sprite_to_draw, 0, // 使用正確的 sprite
                       target_x, target_y,       // 將 sprite 的原點畫在目標手部位置
                       xscale, yscale,           // 縮放
                       tool_angle,               // 旋轉 (會繞著 sprite 原點進行)
                       c_white, 1);              // 顏色和透明度

        // --- 除錯繪製 (保留判斷，刪除內容) --- 
        if (global.game_debug_mode) {
             // // 獲取實際繪製的 sprite 的原點並打印 (驗證是否為 6, 24)
             // var actual_origin_x = sprite_get_xoffset(sprite_to_draw);
             // var actual_origin_y = sprite_get_yoffset(sprite_to_draw);
             // show_debug_message("Drawing Action Sprite - Origin X: " + string(actual_origin_x) + ", Y: " + string(actual_origin_y));
             // 
             // draw_set_color(c_yellow); // 手部目標
             // draw_circle(target_x, target_y, 3, false);
             // draw_set_color(c_blue); // Sprite 原點 (應該與黃點重合)
             // draw_circle(target_x, target_y, 1, false);
             // 
             // // 顯示文字信息
             // draw_set_color(c_lime);
             // draw_text(x, y - 60, "幀數: " + string(frame_index) + "/4");
             // draw_text(x, y - 80, "角度: " + string(tool_angle));
             // draw_text(x, y - 100, "模式: Held Sprite via Manager");
             // draw_text(x, y - 120, "手部/原點: X=" + string(target_x) + ", Y=" + string(target_y));
        }
        // --- 結束除錯 --- 
    } else {
        // 如果 get_item_action_sprite 返回無效值，可以在這裡加一個警告
        show_debug_message("警告: 無法獲取 ID " + string(equipped_tool_id) + " 的有效動作 Sprite。");
    }
}
