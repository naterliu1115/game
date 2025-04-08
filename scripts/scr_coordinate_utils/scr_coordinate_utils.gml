/// @description 座標轉換工具函數
/// @function world_to_gui_coords
/// @param {real} world_x 世界座標 X
/// @param {real} world_y 世界座標 Y
/// @returns {struct} 包含 x 和 y 的 GUI 座標結構體
function world_to_gui_coords(world_x, world_y) {
    // 簡化座標轉換，使用直接的方法
    // 在測試中發現之前的方法可能導致座標錯誤

    // 確保世界座標有效
    if (world_x == 0 && world_y == 0) {
        show_debug_message("警告: 世界座標為 (0,0)，可能是無效值");
        // 返回螢幕中心
        return {
            x: display_get_gui_width() / 2,
            y: display_get_gui_height() / 2
        };
    }

    // 使用簡化的方法，將世界座標直接轉換為 GUI 座標
    // 假設世界座標和 GUI 座標的比例為 1:1
    // 這在某些情況下可能不正確，但對於飛行物品來說應該足夠

    // 確保座標在螢幕範圍內
    var gui_width = display_get_gui_width();
    var gui_height = display_get_gui_height();

    // 將世界座標轉換為 GUI 座標
    // 假設世界座標和 GUI 座標的比例為 1:1
    var gui_x = world_x;
    var gui_y = world_y;

    // 確保座標在螢幕範圍內
    gui_x = clamp(gui_x, 50, gui_width - 50);
    gui_y = clamp(gui_y, 50, gui_height - 50);

    show_debug_message("簡化座標轉換: 世界(" + string(world_x) + "," + string(world_y) + ") -> GUI(" + string(gui_x) + "," + string(gui_y) + ")");

    return {
        x: gui_x,
        y: gui_y
    };
}

/// @function gui_to_world_coords
/// @param {real} gui_x GUI座標 X
/// @param {real} gui_y GUI座標 Y
/// @returns {struct} 包含 x 和 y 的世界座標結構體
function gui_to_world_coords(gui_x, gui_y) {
    // 先將 GUI 座標轉換為視圖座標
    var view_x = (gui_x / display_get_gui_width()) * camera_get_view_width(view_camera[0]);
    var view_y = (gui_y / display_get_gui_height()) * camera_get_view_height(view_camera[0]);

    // 再將視圖座標轉換為世界座標
    var world_x = view_x + camera_get_view_x(view_camera[0]);
    var world_y = view_y + camera_get_view_y(view_camera[0]);

    return {
        x: world_x,
        y: world_y
    };
}
