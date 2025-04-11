event_inherited(); // 继承父类的Step行为

/* --- 移除舊的、衝突的遊蕩邏輯 --- 
// 非战斗状态下的行为
if (!global.in_battle) {
    // 如果沒有定義基礎遊蕩變數，初始化它們
    if (!variable_instance_exists(id, "wander_direction")) {
        wander_direction = irandom(359);
        wander_speed = 0.5;
        wander_timer = 0;
        wander_pause = false;
        wander_pause_time = room_speed * 2; // 2秒的暫停時間
        wander_move_time = room_speed * 3;  // 3秒的移動時間
        wander_home_x = x;
        wander_home_y = y;
        wander_range = 100; // 遊蕩範圍
    }
    
    // 計時器更新
    wander_timer++;
    
    // 處理遊蕩狀態
    if (wander_pause) {
        // 暫停狀態
        if (wander_timer >= wander_pause_time) {
            wander_pause = false;
            wander_timer = 0;
            wander_direction = irandom(359);
        }
    } else {
        // 移動狀態
        if (wander_timer >= wander_move_time) {
            wander_pause = true;
            wander_timer = 0;
        } else {
            // 檢查是否超出範圍
            var dist_to_home = point_distance(x, y, wander_home_x, wander_home_y);
            if (dist_to_home > wander_range) {
                // 如果超出範圍，往回走
                wander_direction = point_direction(x, y, wander_home_x, wander_home_y);
            } else if (random(100) < 2) { // 2%機率改變方向
                wander_direction = irandom(359);
            }
            
            // 計算新位置
            var new_x = x + lengthdir_x(wander_speed, wander_direction);
            var new_y = y + lengthdir_y(wander_speed, wander_direction);
            
            // 檢查碰撞
            if (!place_meeting(new_x, new_y, obj_wall)) {
                x = new_x;
                y = new_y;
            } else {
                // 碰牆改變方向
                wander_direction = (wander_direction + 180) mod 360;
            }
            
            // 根據方向設置面向
            var dir = wander_direction;
            
            // 更新精靈方向
            if (dir >= 45 && dir < 135) {
                // 向下
                if (variable_instance_exists(id, "animation_frames") && is_struct(animation_frames)) {
                    if (variable_struct_exists(animation_frames, "WALK_DOWN")) {
                        var frames = animation_frames.WALK_DOWN;
                        image_index = frames[0] + (current_time / 200) mod (frames[1] - frames[0] + 1);
                    }
                }
            } else if (dir >= 135 && dir < 225) {
                // 向左
                if (variable_instance_exists(id, "animation_frames") && is_struct(animation_frames)) {
                    if (variable_struct_exists(animation_frames, "WALK_LEFT")) {
                        var frames = animation_frames.WALK_LEFT;
                        image_index = frames[0] + (current_time / 200) mod (frames[1] - frames[0] + 1);
                    }
                }
            } else if (dir >= 225 && dir < 315) {
                // 向上
                if (variable_instance_exists(id, "animation_frames") && is_struct(animation_frames)) {
                    if (variable_struct_exists(animation_frames, "WALK_UP")) {
                        var frames = animation_frames.WALK_UP;
                        image_index = frames[0] + (current_time / 200) mod (frames[1] - frames[0] + 1);
                    }
                }
            } else {
                // 向右
                if (variable_instance_exists(id, "animation_frames") && is_struct(animation_frames)) {
                    if (variable_struct_exists(animation_frames, "WALK_RIGHT")) {
                        var frames = animation_frames.WALK_RIGHT;
                        image_index = frames[0] + (current_time / 200) mod (frames[1] - frames[0] + 1);
                    }
                }
            }
        }
    }
}
*/