/// @description 延遲創建飛行道具 (使用 obj_screen_marker 獲取座標)

// 檢查全局變數是否存在
if (!variable_global_exists("create_flying_item_info")) {
    show_debug_message("錯誤：Alarm 0 觸發，但 global.create_flying_item_info 不存在！");
    exit;
}

var info = global.create_flying_item_info;
var gui_layer_name = "GUI"; // 目標 GUI 圖層名稱
var start_gui_x = display_get_gui_width() / 2; // 預設值：畫面中心 X
var start_gui_y = display_get_gui_height() / 2; // 預設值：畫面中心 Y

show_debug_message("Alarm 0 executing. World Pos: (" + string(info.start_world_x) + "," + string(info.start_world_y) + ")");

// --- 使用臨時標記物件獲取螢幕座標 ---
var marker_instance = noone; // 初始化標記實例變數

// 確保 obj_screen_marker 物件存在
if (!object_exists(obj_screen_marker)) {
     show_debug_message("嚴重錯誤：物件 obj_screen_marker 不存在！無法使用標記方法。");
} else {
    // 嘗試在 GUI 圖層上使用世界座標創建標記
    show_debug_message("Attempting to create obj_screen_marker on layer '" + gui_layer_name + "' at World Pos: (" + string(info.start_world_x) + "," + string(info.start_world_y) + ")");
    marker_instance = instance_create_layer(info.start_world_x, info.start_world_y, gui_layer_name, obj_screen_marker);

    // 檢查標記是否成功創建
    if (instance_exists(marker_instance)) {
        // 成功！讀取標記的 x, y (這就是螢幕座標)
        start_gui_x = marker_instance.x;
        start_gui_y = marker_instance.y;
        show_debug_message("Marker created successfully. Read Screen Pos: (" + string(start_gui_x) + "," + string(start_gui_y) + ")");
        
        // 立刻銷毀標記
        instance_destroy(marker_instance);
        show_debug_message("Marker destroyed.");
    } else {
        // 創建失敗 (可能是圖層不存在或無效)
        show_debug_message("警告：創建 obj_screen_marker 失敗！可能圖層 '" + gui_layer_name + "' 不存在或無效。將使用預設螢幕座標。");
        
        // 嘗試再次確保圖層存在 (如果它不存在)
        if (!layer_exists(gui_layer_name)) {
            layer_create(-9700, gui_layer_name);
            show_debug_message("Attempted to create missing layer '" + gui_layer_name + "'.");
        }
    }
}
// --- 座標獲取結束 ---

// 檢查精靈索引是否有效
if (info.sprite_index != -1 && sprite_exists(info.sprite_index)) {
    show_debug_message("Creating obj_flying_item at calculated/default GUI Pos: (" + string(start_gui_x) + "," + string(start_gui_y) + ") on Layer: " + gui_layer_name);
    
    // 在計算出的 GUI 座標和 GUI 圖層上創建飛行道具
    with (instance_create_layer(start_gui_x, start_gui_y, gui_layer_name, obj_flying_item)) {
         // --- 設置基本屬性 ---
         sprite_index = info.sprite_index;
         
         // --- 設置飛行狀態 ---
         flight_state = FLYING_STATE.FLYING_UP;
         
         // --- 設置飛行目標 ---
         var fly_up_distance = 10; // 向上飛行的距離（像素）
         target_x = x;            // 水平位置保持不變
         target_y = y - fly_up_distance; // 目標是當前位置向上移動
         
         show_debug_message("Flying item initialized, will fly up " + string(fly_up_distance) + " pixels to (" + string(target_x) + ", " + string(target_y) + ")");
    }
} else {
    show_debug_message("警告: 無效的 sprite_index (" + string(info.sprite_index) + ") 或精靈不存在，無法創建飛行道具。");
}

// 清理臨時全局變數
variable_global_set("create_flying_item_info", undefined); 
show_debug_message("Cleaned up global.create_flying_item_info.");
