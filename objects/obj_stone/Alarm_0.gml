/// @description 延遲創建飛行道具 (使用座標轉換函數)

// 檢查全局變數是否存在
if (!variable_global_exists("create_flying_item_info")) {
    show_debug_message("錯誤：Alarm 0 觸發，但 global.create_flying_item_info 不存在！");
    exit;
}

var info = global.create_flying_item_info;
var gui_layer_name = "GUI"; // 目標 GUI 圖層名稱

// 確保世界座標有效
if (info.start_world_x == 0 && info.start_world_y == 0) {
    show_debug_message("警告: 世界座標為 (0,0)，可能是無效值。使用備用座標。");
    // 如果座標無效，使用備用座標
    info.start_world_x = x;
    info.start_world_y = y;
}

// 使用座標轉換函數
var coords = world_to_gui_coords(info.start_world_x, info.start_world_y);
var start_gui_x = coords.x;
var start_gui_y = coords.y;

// 檢查轉換後的座標是否合理
if (start_gui_x < 0 || start_gui_x > display_get_gui_width() ||
    start_gui_y < 0 || start_gui_y > display_get_gui_height()) {
    show_debug_message("警告: 轉換後的 GUI 座標超出螢幕範圍。使用備用座標。");
    // 如果轉換後的座標超出螢幕範圍，使用備用座標
    start_gui_x = display_get_gui_width() / 2;
    start_gui_y = display_get_gui_height() / 2;
}

// 確保 GUI 圖層存在
if (!layer_exists(gui_layer_name)) {
    layer_create(-9700, gui_layer_name);
    show_debug_message("創建缺失的 GUI 圖層: '" + gui_layer_name + "'");
}
// --- 座標轉換結束 ---

// 檢查精靈索引是否有效
if (info.sprite_index != -1 && sprite_exists(info.sprite_index)) {
    // 在計算出的 GUI 座標和 GUI 圖層上創建飛行道具
    // 確保座標在螢幕範圍內
    var gui_width = display_get_gui_width();
    var gui_height = display_get_gui_height();
    start_gui_x = clamp(start_gui_x, 50, gui_width - 50);
    start_gui_y = clamp(start_gui_y, 50, gui_height - 50);

    with (instance_create_layer(start_gui_x, start_gui_y, gui_layer_name, obj_flying_item)) {
         // --- 設置基本屬性 ---
         sprite_index = info.sprite_index;
         quantity = 1;

         // --- 設置飛行狀態 ---
         flight_state = FLYING_STATE.FLYING_UP;

         // 注意：飛行高度已在 obj_flying_item 的 Create_0.gml 中設置為 100 像素
         // 如果需要特殊高度，可以取消下面的註釋並設置值
         // fly_up_distance = 150; // 設置特殊高度

         // --- 設置飛行目標 ---
         target_x = x;            // 水平位置保持不變
         target_y = y - fly_up_distance; // 目標是當前位置向上移動

         // 設置玩家目標座標（如果玩家存在）
         if (instance_exists(Player)) {
            player_target_x = Player.x;
            player_target_y = Player.y;
         } else {
            show_debug_message("警告: 玩家不存在，飛行物品將不會飛向玩家。");
         }
    }
} else {
    show_debug_message("警告: 無效的 sprite_index (" + string(info.sprite_index) + ") 或精靈不存在，無法創建飛行道具。");
}

// 清理臨時全局變數
variable_global_set("create_flying_item_info", undefined);
