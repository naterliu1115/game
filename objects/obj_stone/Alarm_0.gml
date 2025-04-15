/// @description 世界層直接創建飛行道具

// 檢查全局變數是否存在
if (!variable_global_exists("create_flying_item_info")) {
    show_debug_message("錯誤：Alarm 0 觸發，但 global.create_flying_item_info 不存在！");
    exit;
}

var info = global.create_flying_item_info;
var world_layer_name = "Instances"; // 目標世界層

// 確保世界座標有效
if (info.start_world_x == 0 && info.start_world_y == 0) {
    show_debug_message("警告: 世界座標為 (0,0)，可能是無效值。使用備用座標。");
    info.start_world_x = x;
    info.start_world_y = y;
}

// 檢查精靈索引是否有效
if (info.sprite_index != -1 && sprite_exists(info.sprite_index)) {
    // 在世界層、世界座標創建飛行道具
    with (instance_create_layer(info.start_world_x, info.start_world_y, world_layer_name, obj_flying_item)) { 
        // === 由創建者直接設定 ===
        source_type = "gather"; // 明確設定來源
        sprite_index = info.sprite_index; // 從 info 獲取
        quantity = info.quantity != undefined ? info.quantity : 1; // 從 info 獲取
        item_id = info.item_id != undefined ? info.item_id : -1; // 從 info 獲取
        image_xscale = 0.8;
        image_yscale = 0.8;
        
        flight_state = FLYING_STATE.FLYING_UP; // 明確設定初始狀態
        fly_up_distance = 30; // 設置上升高度 (保留或移至Create)
        
        // --- 目標設定邏輯 ---
        // 設置向上飛行目標
        target_x = x;
        target_y = y - fly_up_distance; 
        // 設置玩家目標座標（世界座標）
        if (instance_exists(Player)) {
            player_target_x = Player.x;
            player_target_y = Player.y;
        } else {
            player_target_x = x;
            player_target_y = y;
        }

        // 除錯：打印創建信息
        show_debug_message("  [Stone Drop Init] Created ID: " + string(id) +
                           ", State: " + string(flight_state) +
                           ", Target: (" + string(target_x) + "," + string(target_y) + ")" +
                           ", Initial HS: " + string(hspeed) + ", VS: " + string(vspeed));
    }
} else {
    show_debug_message("警告: 無效的 sprite_index (" + string(info.sprite_index) + ") 或精靈不存在，無法創建飛行道具。");
}

// 清理臨時全局變數
variable_global_set("create_flying_item_info", undefined);
