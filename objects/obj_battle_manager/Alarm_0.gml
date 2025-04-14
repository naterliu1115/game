/// @description 延遲創建飛行道具

// 檢查全局變數是否存在
if (!variable_global_exists("create_flying_item_info")) {
    show_debug_message("錯誤：Alarm 0 觸發，但 global.create_flying_item_info 不存在！");
    exit;
}

var info = global.create_flying_item_info;
var gui_layer_name = "GUI"; // 使用 GUI 圖層

show_debug_message("Alarm 0 executing. World Pos: (" + string(info.start_world_x) + "," + string(info.start_world_y) + ")");

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

show_debug_message("最終 GUI 座標: (" + string(start_gui_x) + "," + string(start_gui_y) + ")");

// 確保 GUI 圖層存在
if (!layer_exists(gui_layer_name)) {
    layer_create(-9700, gui_layer_name);
    show_debug_message("創建缺失的 GUI 圖層: '" + gui_layer_name + "'");
}

// 檢查精靈索引是否有效
if (info.sprite_index != -1 && sprite_exists(info.sprite_index)) {
    show_debug_message("Creating obj_flying_item at calculated/default GUI Pos: (" + string(start_gui_x) + "," + string(start_gui_y) + ") on Layer: " + gui_layer_name);

    // 在計算出的 GUI 座標和 GUI 圖層上創建飛行道具
    // 確保座標在螢幕範圍內
    var gui_width = display_get_gui_width();
    var gui_height = display_get_gui_height();
    start_gui_x = clamp(start_gui_x, 50, gui_width - 50);
    start_gui_y = clamp(start_gui_y, 50, gui_height - 50);

    show_debug_message("在座標 (" + string(start_gui_x) + ", " + string(start_gui_y) + ") 創建飛行物品");

    with (instance_create_layer(start_gui_x, start_gui_y, gui_layer_name, obj_flying_item)) {
        // 設置基本屬性
        sprite_index = info.sprite_index;
        quantity = info.quantity;
        image_xscale = 0.8;
        image_yscale = 0.8;
        
        // 設置飛行狀態
        flight_state = FLYING_STATE.FLYING_UP;
        fly_up_distance = 30; // 設置上升高度
        
        // 設置玩家目標座標（如果玩家存在）
        if (instance_exists(Player)) {
            target_x = Player.x;
            target_y = Player.y;
            show_debug_message("設置飛向玩家位置：(" + string(target_x) + ", " + string(target_y) + ")");
        } else {
            // 如果找不到玩家，就飛向原地
            target_x = x;
            target_y = y;
            show_debug_message("警告：找不到玩家，物品將原地淡出");
        }
        
        show_debug_message("飛行物品初始化完成，將先上升後飛向玩家");
    }
} else {
    show_debug_message("警告: 無效的 sprite_index (" + string(info.sprite_index) + ") 或精靈不存在，無法創建飛行道具。");
}

// 清理臨時全局變數
variable_global_set("create_flying_item_info", undefined);
show_debug_message("Cleaned up global.create_flying_item_info."); 