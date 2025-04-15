/// @description 根據狀態處理飛行邏輯

// Step 事件最開頭：加入 Y 座標異常檢查
if (y > room_height * 5 || y < -room_height * 4) { // 大幅放寬邊界，避免誤殺
    show_debug_message("[FlyingItem WARN] ID: " + string(id) + " has abnormal Y coordinate: " + string(y) + ". State: " + string(flight_state) + ". Destroying.");
    instance_destroy();
    exit; // 立即退出 Step 事件
}

// 在 Step 事件開頭獲取 Tilemap ID (只需獲取一次或在需要時更新)
if (tilemap_id == -1) {
    var layer_id = layer_get_id("scene");
    if (layer_exists(layer_id)) {
        tilemap_id = layer_tilemap_get_id(layer_id);
    }
}

// 根據當前狀態處理飛行道具的行為
// 除錯：打印當前狀態和座標
show_debug_message("[FlyingItem Step] ID: " + string(id) + ", State: " + string(flight_state) + 
                   ", World Pos: (" + string(x) + ", " + string(y) + ")" + 
                   ", HS: " + string(hspeed) + ", VS: " + string(vspeed));

switch (flight_state) {

    case FLYING_STATE.FLYING_UP:
        // --- 向上飛行 ---
        show_debug_message("  [FLYING_UP] Target: (" + string(target_x) + "," + string(target_y) + "), Current: (" + string(x) + "," + string(y) + ")"); // 加入 Target/Current 除錯
        var dist_to_target = point_distance(x, y, target_x, target_y);
        show_debug_message("  [FLYING_UP] Dist to target: " + string(dist_to_target) + ", Required: < " + string(move_speed)); // 加入距離除錯

        // 如果接近目標位置，切換到停頓狀態
        if (dist_to_target < move_speed) {
            // 確保精確到達目標位置
            x = target_x;
            y = target_y;
            flight_state = FLYING_STATE.PAUSING;
            pause_timer = 0; // 開始計時
            show_debug_message("  [FLYING_UP] Reached target! Changing state to PAUSING."); // 加入狀態切換除錯
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
            } else {
                // 更新玩家目標座標
                player_target_x = Player.x;
                player_target_y = Player.y;
            }
        }
        break;

    case FLYING_STATE.FLYING_TO_PLAYER:
        // 確保玩家存在，否則直接淡出
        if (!instance_exists(Player)) {
            flight_state = FLYING_STATE.FADING_OUT;
            fade_timer = 0;
            break;
        }

        // 加入 to_player_speed 的一次性除錯
        if (!variable_instance_exists(id, "debug_speed_printed")) {
             show_debug_message("  [FLYING_TO_PLAYER] Initial check - to_player_speed: " + string(to_player_speed));
             debug_speed_printed = true;
        }

        // 持續更新玩家目標座標（世界座標）
        player_target_x = Player.x;
        player_target_y = Player.y;

        // 計算到玩家的距離
        var dist_to_player = point_distance(x, y, player_target_x, player_target_y);

        // 除錯：打印目標和距離
        show_debug_message("  [FLYING_TO_PLAYER] Target: (" + string(player_target_x) + ", " + string(player_target_y) + ")" +
                           ", Current: (" + string(x) + ", " + string(y) + ")" + 
                           ", Dist: " + string(dist_to_player));

        // 如果已經到達玩家附近，切換到淡出狀態
        if (dist_to_player < to_player_speed) {
            flight_state = FLYING_STATE.FADING_OUT;
            fade_timer = 0;
            show_debug_message("  [FLYING_TO_PLAYER] Reached player! Changing state to FADING_OUT.");
        } else {
            // 向玩家方向移動
            var dir = point_direction(x, y, player_target_x, player_target_y);
            var move_x = lengthdir_x(to_player_speed, dir);
            var move_y = lengthdir_y(to_player_speed, dir);
            x += move_x;
            y += move_y;

            image_xscale = max(0.5, image_xscale * 0.995);
            image_yscale = image_xscale;
        }
        break;

    case FLYING_STATE.SCATTERING:
        // --- 拋灑/彈跳 (使用偽 Z 軸物理模擬) ---
        
        // --- 碰撞檢測與反應 (新增) ---
        ds_list_clear(nearby_items_list); // 清空上次的列表
        var check_radius = sprite_get_width(sprite_index) * 0.6; // 碰撞檢查半徑
        var hit_count = collision_circle_list(x, y, check_radius, obj_flying_item, false, true, nearby_items_list, false);

        if (hit_count > 1) { // 至少要包含自己和另一個才需要處理
            for (var i = 0; i < hit_count; i++) {
                var other_item_id = nearby_items_list[| i];
                if (other_item_id != id && instance_exists(other_item_id)) { // 排除自己並確保對方存在
                    var distance = point_distance(x, y, other_item_id.x, other_item_id.y);
                    var min_separation_distance = (sprite_get_width(sprite_index) + sprite_get_width(other_item_id.sprite_index)) * 0.4; // 最小分離距離

                    if (distance < min_separation_distance && distance > 0) { // 避免除以零
                        var overlap = min_separation_distance - distance;
                        var dir_to_self = point_direction(other_item_id.x, other_item_id.y, x, y);
                        var push_magnitude = overlap * push_force; // 使用 Create 中定義的 push_force
                        var push_vx = lengthdir_x(push_magnitude, dir_to_self);
                        var push_vy = lengthdir_y(push_magnitude, dir_to_self);

                        // 直接修改位置來推開
                        x += push_vx;
                        y += push_vy;
                        show_debug_message("  [SCATTERING Collision] Pushed away from " + string(other_item_id) + " by (" + string(push_vx) + ", " + string(push_vy) + ")");
                    }
                }
            }
        }
        // --- 碰撞檢測結束 ---

        // 更新水平位置 (現在已包含碰撞推力)
        x += hspeed;
        // y += vspeed; // 移除舊的 Y 軸速度更新
        
        // 應用 Z 軸重力
        zspeed -= gravity_z;
        
        // 更新 Z 軸高度
        z += zspeed;
        
        // 拋灑拖尾粒子 (注意 Y 座標使用 y-z)
        if (particle_effects_enabled) {
            part_particles_create(particle_system, x, y - z, particle_trail, 1);
        }
        
        // 簡單空氣阻力
        hspeed *= 0.99;
        
        // 檢查是否「落地」(z <= 0 且向下運動)
        if (z <= 0 && zspeed < 0) {
            z = 0; // 精確設定高度為 0

            // 除錯：打印落地信息
            show_debug_message("  [SCATTERING] Ground Collision (Z=0)! Bounce: " + string(bounce_count) + 
                               ", Z Speed: " + string(zspeed));

            if (bounce_count < bounce_count_max && abs(zspeed) > 1.0) { // 根據 Z 速度判斷反彈
                zspeed = -zspeed * 0.5; // 反彈 Z 速度並衰減
                hspeed *= 0.8; // 地面摩擦力 (影響水平速度)
                bounce_count++;
                // 落地粒子
                if (particle_effects_enabled) {
                    part_particles_create(particle_system, x, y - z, particle_land, 6); // 注意粒子 Y 座標
                }
            } else { // 停止彈跳 / 停止運動
                zspeed = 0;
                hspeed = 0; // 停止水平移動
                vspeed = 0; // <--- 新增：確保垂直速度也歸零
                flight_state = FLYING_STATE.WAIT_ON_GROUND;
                ground_wait_timer = 0;
                ground_y_pos = y; // 記錄原始 Y 座標用於浮動
                float_timer = 0;
                show_debug_message("  [SCATTERING] Stopped bouncing. Changing state to WAIT_ON_GROUND.");
            }
        }
        
        // ------------------- 移除舊的 Tilemap 檢測邏輯 START -------------------
        /*
        // 檢查是否獲取到有效的 tilemap_id
        if (tilemap_id != -1) {
            // 檢查下方是否有 Tile (檢查點在 sprite 底部中心)
            var check_x = x;
            var check_y = y + sprite_get_bbox_bottom(sprite_index) - y; // 相對 sprite 原點的底部 Y
            var tile_data = tilemap_get_at_pixel(tilemap_id, check_x, check_y + 1); // 檢查下方 1 像素
            var is_on_ground = (tile_data != 0);

            // 除錯：打印落地檢測信息
            show_debug_message("  [SCATTERING] Check Y: " + string(check_y + 1) + 
                               ", Tile Data: " + string(tile_data) + ", IsOnGround: " + string(is_on_ground));

            if (is_on_ground) {
                // 獲取 Tile 的 Y 座標頂部
                var tile_y_top = tilemap_get_y(tile_data) * tilemap_get_tile_height(tilemap_id);
                y = tile_y_top - (sprite_get_bbox_bottom(sprite_index) - y); // 對齊 Y 座標

                if (bounce_count < bounce_count_max && abs(vspeed) > 1.5) { // 加入速度閾值判斷
                    vspeed = -vspeed * 0.5; // 反彈並衰減速度
                    hspeed *= 0.8; // 地面摩擦力
                    bounce_count++;
                    // 落地粒子
                    if (particle_effects_enabled) {
                        part_particles_create(particle_system, x, y, particle_land, 6);
                    }
                    show_debug_message("  [SCATTERING] Ground Collision! Bounce: " + string(bounce_count) + 
                                       ", VS: " + string(vspeed));
                } else { // 停止彈跳
                    hspeed = 0;
                    vspeed = 0;
                    flight_state = FLYING_STATE.WAIT_ON_GROUND;
                    ground_wait_timer = 0;
                    ground_y_pos = y; // 記錄最終落地 Y
                    float_timer = 0;
                }
            }
        }
        */
        // ------------------- 移除舊的 Tilemap 檢測邏輯 END ---------------------
        break;

    case FLYING_STATE.WAIT_ON_GROUND:
        ground_wait_timer++;
        // float_timer++; // 浮動計時器移至 Draw 事件
        // // 計算浮動效果 (移至 Draw 事件)
        // var float_offset = sin(float_timer * float_frequency) * float_amplitude;
        // y = ground_y_pos + float_offset; // 移除 Y 座標修改
        
        // 除錯：打印等待計時器
        show_debug_message("  [WAIT_ON_GROUND] Wait Timer: " + string(ground_wait_timer) + 
                           " / " + string(wait_duration));
            
        if (ground_wait_timer >= wait_duration) {
            show_debug_message("  [WAIT_ON_GROUND] Wait complete! Changing state to FLYING_TO_PLAYER.");
            hspeed = 0; // 明確重置速度
            vspeed = 0; // 明確重置速度
            flight_state = FLYING_STATE.FLYING_TO_PLAYER;
            // 可於此觸發閃光粒子
            if (particle_effects_enabled) {
                part_particles_create(particle_system, x, y, particle_absorb, 8);
            }
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

        // 除錯：打印淡出計時器和 Alpha
        show_debug_message("  [FADING_OUT] Fade Timer: " + string(fade_timer) + 
                           " / " + string(fade_duration) + ", Alpha: " + string(image_alpha));

        // 淡出完成後銷毀
        if (fade_timer >= fade_duration) {
            instance_destroy();
            exit;
        }
        // 淡出時可再觸發閃光粒子
        if (fade_timer == 1 && particle_effects_enabled) {
            part_particles_create(particle_system, x, y, particle_absorb, 6);
        }
        break;
}

