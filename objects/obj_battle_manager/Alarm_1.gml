/// @description 處理飛行道具創建佇列 (已修正為世界座標)
// show_debug_message("===== [Alarm 1 Triggered] ====="); // 移除觸發標記

// 檢查佇列是否存在且有內容
if (!variable_instance_exists(id, "pending_flying_items") || array_length(pending_flying_items) == 0) {
    // show_debug_message("[Alarm 1] 佇列為空或不存在，停止處理。"); // 可以保留這個，因為它是正常流程的結束
    exit;
}

// 從佇列頭部取出一個物品信息
var info = array_shift(pending_flying_items);

// show_debug_message("[Alarm 1] 處理佇列中的物品: ID=" + string(info.item_id) + ", Qty=" + string(info.quantity) + ", Sprite=" + string(info.sprite_index)); // 移除

// 世界層名稱
var world_layer_name = "Instances";

// 直接使用 info 中的世界座標
var start_world_x = info.start_world_x;
var start_world_y = info.start_world_y;

// 除錯：打印創建信息
show_debug_message("[Alarm 1] Preparing to create flying item ID: " + string(info.item_id) + 
                   " at World Coords: (" + string(start_world_x) + ", " + string(start_world_y) + ")" + 
                   " on Layer: " + world_layer_name);

// 確保世界圖層存在 (可選，通常 Instances 層都存在)
/*
if (!layer_exists(world_layer_name)) {
    layer_create(-9700, world_layer_name);
}
*/

// 再次檢查精靈索引是否有效 (理論上在 on_unit_died 已檢查，雙重保險)
if (info.sprite_index != -1 && sprite_exists(info.sprite_index)) {
    // 在世界層、世界座標創建飛行道具
    with (instance_create_layer(start_world_x, start_world_y, world_layer_name, obj_flying_item)) { 
        // 除錯：打印實例創建成功信息
        show_debug_message("[Alarm 1] Instance Create SUCCESS! ID: " + string(id) + 
                           ", World Pos: (" + string(x) + ", " + string(y) + ")");

        // === 由創建者直接設定 ===
        source_type = "monster"; // 明確設定來源
        sprite_index = info.sprite_index; // 從 info 獲取
        quantity = info.quantity; // 從 info 獲取
        item_id = info.item_id; // 從 info 獲取
        image_xscale = 0.8;
        image_yscale = 0.8;
        
        flight_state = FLYING_STATE.SCATTERING; // 明確設定初始狀態
        
        // 初始化拋灑速度 (不再進行初始位置偏移)
        var angle = random(scatter_angle_range);
        var scatter_init_speed = random_range(scatter_speed_min, scatter_speed_max);
        hspeed = lengthdir_x(scatter_init_speed, angle);
        vspeed = lengthdir_y(scatter_init_speed, angle);
        zspeed = random_range(3, 5);
        bounce_count = 0;
        
        // 除錯：打印初始速度和狀態
        show_debug_message("  [FlyingItem Init] State: " + string(flight_state) + 
                           ", Angle: " + string(angle) + ", Speed: " + string(scatter_init_speed) + 
                           ", HS: " + string(hspeed) + ", VS: " + string(vspeed));

        // 初始化 player_target (FLYING_TO_PLAYER 會更新)
        player_target_x = x; 
        player_target_y = y;
    }
} else {
    show_debug_message("[Alarm 1] Warning: Invalid sprite_index (" + string(info.sprite_index) + ")" + 
                       " or sprite does not exist for item ID " + string(info.item_id) + ". Cannot create flying item.");
}
// --- 創建邏輯結束 ---

// 檢查佇列中是否還有剩餘物品
if (array_length(pending_flying_items) > 0) {
    alarm[1] = 1; // 將延遲從 5 改為 1
} else {
    // show_debug_message("[Alarm 1] Queue processed."); // 可選
} 