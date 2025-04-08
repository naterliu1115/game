/// @description 處理挖掘邏輯

if (!instance_exists(Player)) exit;

// 如果已經被破壞，處理銷毀延遲
if (is_destroyed) {
    destroy_timer++;

    // 計算淡出效果
    if (destroy_timer > fade_start_delay) {
        var fade_progress = (destroy_timer - fade_start_delay) / fade_duration;
        fade_progress = clamp(fade_progress, 0, 1);

        // 使用更平滑的淡出曲線
        var smooth_fade = 1 - power(fade_progress, 1.5);
        image_alpha = smooth_fade;

        // 添加輕微的縮放效果
        scale_multiplier = 1 + (fade_progress * 0.2);
        image_xscale = scale_multiplier;
        image_yscale = scale_multiplier;
    }

    // 在完全淡出之前不要消失
    if (destroy_timer >= destroy_delay && image_alpha <= 0.05) {
        cleanup();
        instance_destroy();
    }
    exit;
}

var dist = point_distance(x, y, Player.x, Player.y);
var has_pickaxe = (Player.equipped_tool_id == 5001); // 直接檢查玩家是否裝備了礦鎬（ID 5001）

// --- 修改後的挖掘條件判斷 ---
var can_start_mining = false;
if (dist <= interaction_radius && mouse_check_button(mb_left) && has_pickaxe) {
    // 基礎條件滿足，檢查滑鼠或朝向

    // 條件 A: 滑鼠在石頭上
    var is_mouse_over = position_meeting(mouse_x, mouse_y, id);

    // 條件 B: 角色面向石頭 (容許 +/- 45 度誤差)
    var is_facing_stone = false;
    if (instance_exists(Player)) { // 確保玩家存在
        var angle_to_stone = point_direction(Player.x, Player.y, x, y);
        var facing_angle = Player.facing_direction; // 從 Player 物件獲取朝向
        var angle_diff = angle_difference(facing_angle, angle_to_stone);
        if (abs(angle_diff) <= 45) {
            is_facing_stone = true;
        }
    }

    // 如果滿足條件 A 或 B，則允許開始挖掘
    if (is_mouse_over || is_facing_stone) {
        can_start_mining = true;
    }
}

// --- 根據挖掘條件執行動作 ---
if (can_start_mining) {
    is_being_mined = true;

    // 增加挖掘進度
    mining_progress += 1/60; // 每秒增加一次

    // 持續產生挖掘粒子
    if (mining_progress > 0) {
        particle_timer++;
        if (particle_timer >= particle_interval) {
            particle_timer = 0;
            repeat(1) {
                var particle_x = x + random_range(-sprite_width/4, sprite_width/4);
                var particle_y = y + random_range(-sprite_height/4, sprite_height/4);
                part_particles_create(particle_system, particle_x, particle_y, particle, 1);
            }
        }
    }

    // 當進度達到1時
    if (mining_progress >= 1) {
        mining_progress = 0;
        durability--;

        // 視覺效果
        shake_amount = 2;

        // 產生更多粒子效果
        repeat(4) {
            var angle = random(360);
            var dist = random_range(5, 20);
            var particle_x = x + lengthdir_x(dist, angle);
            var particle_y = y + lengthdir_y(dist, angle);
            part_particles_create(particle_system, particle_x, particle_y, particle, 1);
        }

        // 如果耐久度歸零
        if (durability <= 0) {
            // 添加礦石到玩家背包 (這一步是數據上的添加)
            with (obj_item_manager) {
                add_item_to_inventory(other.ore_item_id, 1);
            }

            // 切換到裂開的圖案
            image_index = 1;

            // 最後的粒子效果爆發
            repeat(100) {
                var angle = random(360);
                var dist = random_range(5, 25);
                var particle_x = x + lengthdir_x(dist, angle);
                var particle_y = y + lengthdir_y(dist, angle);
                part_particles_create(particle_system, particle_x, particle_y, particle, 1);
            }

            // --- 創建飛行道具圖標 (修改為延遲創建) ---
            var item_sprite_index = spr_gold; // 默認使用 spr_gold 作為最終備用
            if (instance_exists(obj_item_manager)) {
                item_sprite_index = obj_item_manager.get_item_sprite(ore_item_id);
            }
            if (!sprite_exists(item_sprite_index)) {
                 show_debug_message("嚴重警告：連備用精靈 spr_gold 都找不到！飛行道具創建將被跳過。");
                 item_sprite_index = -1; // 標記為無效
            }

            // 僅在獲得有效精靈索引時才準備創建
            if (item_sprite_index != -1) {
                // 不再需要背包位置作為目標，簡化創建信息

                // --- 準備延遲創建飛行道具 ---
                // 確保使用正確的世界座標
                var stone_world_x = x;
                var stone_world_y = y;

                // 確保座標不是震動後的位置
                if (abs(x - original_x) > 2 || abs(y - original_y) > 2) {
                    stone_world_x = original_x;
                    stone_world_y = original_y;
                    show_debug_message("使用原始座標而非震動後的座標");
                }

                global.create_flying_item_info = {
                    start_world_x : stone_world_x,
                    start_world_y : stone_world_y,
                    sprite_index : item_sprite_index
                    // 不再儲存目標位置，因為飛行道具只會飛向中心再淡出
                };
                alarm[0] = 1; // 觸發 Alarm 0 在下一幀執行創建
                show_debug_message("設置 Alarm 0 創建飛行物品。儲存的世界座標: (" + string(stone_world_x) + "," + string(stone_world_y) + ")");
            }
            // --- 延遲創建準備結束 ---

            // 設置為已破壞狀態，開始淡出
            is_destroyed = true;
            is_being_mined = false; // 確保停止挖掘狀態
            exit; // 退出 Step 事件
        }
    }
} else {
    // 如果不滿足開始挖掘的條件 (包括滑鼠/朝向 或 基礎條件)
    is_being_mined = false;
    mining_progress = max(0, mining_progress - 1/60); // 可以讓進度條稍微慢一點消失
}

// 如果被挖掘，更新位置
if (is_being_mined) {
    x = original_x + random_range(-1, 1);
    y = original_y + random_range(-1, 1);
} else {
    x = lerp(x, original_x, 0.2);
    y = lerp(y, original_y, 0.2);
}

// 改為：僅在 is_being_mined 為 false 時才緩慢恢復位置
/*
if (!is_being_mined) {
     x = lerp(x, original_x, 0.2);
     y = lerp(y, original_y, 0.2);
}
*/