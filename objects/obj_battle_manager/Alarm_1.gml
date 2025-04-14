/// @description 處理飛行道具創建佇列
show_debug_message("===== [Alarm 1 Triggered] ====="); // 添加觸發標記

// 檢查佇列是否存在且有內容
if (!variable_instance_exists(id, "pending_flying_items") || array_length(pending_flying_items) == 0) {
    show_debug_message("[Alarm 1] 佇列為空或不存在，停止處理。");
    exit; // 佇列為空，結束 Alarm
}

// 從佇列頭部取出一個物品信息
var info = array_shift(pending_flying_items);

show_debug_message("[Alarm 1] 處理佇列中的物品: ID=" + string(info.item_id) + ", Qty=" + string(info.quantity) + ", Sprite=" + string(info.sprite_index));

// --- 與原 Alarm[0] 類似的創建邏輯 ---
var gui_layer_name = "GUI"; // 使用 GUI 圖層

// 使用座標轉換函數
var coords = world_to_gui_coords(info.start_world_x, info.start_world_y);
var start_gui_x = coords.x;
var start_gui_y = coords.y;

// 檢查轉換後的座標是否合理
if (start_gui_x < 0 || start_gui_x > display_get_gui_width() ||
    start_gui_y < 0 || start_gui_y > display_get_gui_height()) {
    show_debug_message("[Alarm 1] 警告: 轉換後的 GUI 座標 (" + string(start_gui_x) + "," + string(start_gui_y) + ") 超出螢幕範圍。使用備用座標。");
    start_gui_x = display_get_gui_width() / 2;
    start_gui_y = display_get_gui_height() / 2;
}

// 確保 GUI 圖層存在
if (!layer_exists(gui_layer_name)) {
    layer_create(-9700, gui_layer_name); // 確保在較高深度
    show_debug_message("[Alarm 1] 創建缺失的 GUI 圖層: '" + gui_layer_name + "'");
}

// 再次檢查精靈索引是否有效 (理論上在 on_unit_died 已檢查，雙重保險)
if (info.sprite_index != -1 && sprite_exists(info.sprite_index)) {
    // 確保座標在螢幕範圍內 (給予一些邊距)
    var gui_width = display_get_gui_width();
    var gui_height = display_get_gui_height();
    start_gui_x = clamp(start_gui_x, 32, gui_width - 32); // 增加邊距
    start_gui_y = clamp(start_gui_y, 32, gui_height - 32); // 增加邊距

    show_debug_message("[Alarm 1] 準備在座標 (" + string(start_gui_x) + ", " + string(start_gui_y) + ") 創建飛行物品實例。");

    with (instance_create_layer(start_gui_x, start_gui_y, gui_layer_name, obj_flying_item)) {
        // *** 新增調試信息：實例創建成功 ***
        show_debug_message("[Alarm 1] Instance Create SUCCESS! ID: " + string(id) + " for item ID: " + string(info.item_id));

        // 設置基本屬性
        sprite_index = info.sprite_index;
        quantity = info.quantity;
        image_xscale = 0.8;
        image_yscale = 0.8;

        // 設置飛行狀態
        flight_state = FLYING_STATE.FLYING_UP; // 假設有定義 FLYING_STATE.FLYING_UP
        fly_up_distance = 30; // 設置上升高度

        // 設置玩家目標座標（如果玩家存在）
        if (instance_exists(Player)) {
            target_x = Player.x;
            target_y = Player.y;
            show_debug_message("[Alarm 1 Flying Item] 設置飛向玩家位置：(" + string(target_x) + ", " + string(target_y) + ")");
        } else {
            // 如果找不到玩家，就飛向原地
            target_x = x;
            target_y = y;
            show_debug_message("[Alarm 1 Flying Item] 警告：找不到玩家，物品將原地淡出");
        }

        show_debug_message("[Alarm 1 Flying Item] 飛行物品 (ID: " + string(info.item_id) + ") 初始化完成。");
    }
} else {
    show_debug_message("[Alarm 1] 警告: 無效的 sprite_index (" + string(info.sprite_index) + ") 或精靈不存在，無法創建飛行道具 ID: " + string(info.item_id));
}
// --- 創建邏輯結束 ---

// 檢查佇列中是否還有剩餘物品
if (array_length(pending_flying_items) > 0) {
    show_debug_message("[Alarm 1] 佇列中還有 " + string(array_length(pending_flying_items)) + " 個物品，再次觸發 Alarm[1]。");
    alarm[1] = 5; // 設置處理下一個物品的延遲 (可調整此值控制間隔)
} else {
     show_debug_message("[Alarm 1] 佇列已處理完畢。");
     // 可選：清空數組變數
     // pending_flying_items = [];
} 