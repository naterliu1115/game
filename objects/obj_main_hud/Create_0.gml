// obj_main_hud - Create_0.gml

// --- 狀態變數 ---
active = true; // <-- 新增：初始化 active 狀態
visible = true; // <-- 新增：同時初始化 visible 狀態 (通常 HUD 也是可見的)
show_interaction_prompt = false; // 是否顯示互動提示圖示 (由 Player 物件控制)
allow_player_movement = true;    // HUD 預設不阻止玩家移動

// --- 快捷欄設定 ---
hotbar_slots = 8;          // 快捷欄數量
// 先定義格子尺寸和間距
hotbar_slot_width = 96;  // <-- 定義格子寬度
hotbar_slot_height = 96; // <-- 定義格子高度
hotbar_spacing = 4;        // <-- 定義框格間距

// 再計算位置
hotbar_x = display_get_gui_width() / 2; // <-- 恢復計算中心 X
var hotbar_bottom_padding = 30; 
hotbar_y = display_get_gui_height() - hotbar_slot_height - hotbar_bottom_padding; 

// 重新計算快捷欄總寬度 (基於邏輯格子尺寸和間距)
var total_hotbar_width = hotbar_slots * hotbar_slot_width + (hotbar_slots - 1) * hotbar_spacing;
// 恢復基於置中的計算
hotbar_start_x = hotbar_x - (total_hotbar_width / 2);

// --- 圖示設定 (右下角區域) ---
// 通用設定
var icon_bottom_padding = 30; 
var icon_right_padding = 20;  
var icon_spacing = 10;        // <-- 你可以在這裡調整想要的視覺間距

// 精靈資源
bag_sprite = spr_bag;
monster_button_sprite = spr_mainbutton; 
touch_sprite = spr_touch;

// --- 背包圖示計算 (最右側，作為基準) ---
bag_width = sprite_get_width(bag_sprite);
bag_height = sprite_get_height(bag_sprite);
// 中心點位置 (基於畫布尺寸和邊距)
bag_x = display_get_gui_width() - (bag_width / 2) - icon_right_padding;
bag_y = display_get_gui_height() - (bag_height / 2) - icon_bottom_padding;
// 計算視覺寬度，用於後續間距計算
var bag_bbox_left = sprite_get_bbox_left(bag_sprite);
var bag_bbox_right = sprite_get_bbox_right(bag_sprite);
var bag_visual_width = bag_bbox_right - bag_bbox_left + 1;
// 點擊區域 (基於畫布尺寸)
bag_bbox = [bag_x - bag_width / 2, bag_y - bag_height / 2, bag_x + bag_width / 2, bag_y + bag_height / 2];

// --- 怪物管理按鈕計算 (背包左側) ---
monster_button_width = sprite_get_width(monster_button_sprite);
monster_button_height = sprite_get_height(monster_button_sprite);
// 計算視覺寬度
var mb_bbox_left = sprite_get_bbox_left(monster_button_sprite);
var mb_bbox_right = sprite_get_bbox_right(monster_button_sprite);
var mb_visual_width = mb_bbox_right - mb_bbox_left + 1;
// 計算中心點 X (基於背包中心、兩者視覺半寬、間距)
monster_button_x = bag_x - (bag_visual_width / 2) - icon_spacing - (mb_visual_width / 2);
monster_button_y = bag_y; // 垂直對齊
// 點擊區域 (基於畫布尺寸)
monster_button_bbox = [monster_button_x - monster_button_width / 2, monster_button_y - monster_button_height / 2, 
                       monster_button_x + monster_button_width / 2, monster_button_y + monster_button_height / 2];

// --- 互動提示圖示計算 (怪物管理按鈕左側) ---
touch_width = sprite_get_width(touch_sprite);
touch_height = sprite_get_height(touch_sprite);
// 計算視覺寬度
var touch_bbox_left = sprite_get_bbox_left(touch_sprite);
var touch_bbox_right = sprite_get_bbox_right(touch_sprite);
var touch_visual_width = touch_bbox_right - touch_bbox_left + 1;
// 計算中心點 X (基於怪物按鈕中心、兩者視覺半寬、間距)
touch_x = monster_button_x - (mb_visual_width / 2) - icon_spacing - (touch_visual_width / 2);
touch_y = bag_y - 10; // 垂直對齊<-- 控制互動提示的 Y 軸

// --- 拖放狀態變數 (新增) ---
is_dragging_hotbar_item = false;
dragged_item_inventory_index = noone;
dragged_from_hotbar_slot = -1;
dragged_item_sprite = -1;
drag_item_x = 0;
drag_item_y = 0;

// --- 其他設定 (未來可能用到) ---
selected_hotbar_slot = -1; // <-- 修改：初始設為 -1，表示沒有選中

// --- 輔助函數 (新增) ---
// 根據 GUI 座標獲取對應的快捷欄索引 (0-8)，如果不在任何格子內則返回 -1
function get_hotbar_slot_at_position(mx, my) {
    // --- 同步 Draw 事件邏輯：獲取外框的視覺尺寸 --- 
    var current_frame_visual_width = 96; // 後備值
    var current_frame_visual_height = 96; // 後備值
    if (sprite_exists(spr_itemframe)) {
        var frame_target_size_ref = 96; 
        var frame_original_width = sprite_get_width(spr_itemframe);
        var _frame_original_height = sprite_get_height(spr_itemframe); // 使用不同名稱
        var frame_scale = (frame_original_width > 0) ? frame_target_size_ref / frame_original_width : 1;
        var _bbox_left = sprite_get_bbox_left(spr_itemframe);
        var _bbox_right = sprite_get_bbox_right(spr_itemframe);
        var _bbox_top = sprite_get_bbox_top(spr_itemframe);
        var _bbox_bottom = sprite_get_bbox_bottom(spr_itemframe);
        var bbox_width = _bbox_right - _bbox_left + 1;
        var bbox_height = _bbox_bottom - _bbox_top + 1;
        current_frame_visual_width = bbox_width * frame_scale;
        current_frame_visual_height = bbox_height * frame_scale;
    }
    // --- 結束獲取視覺尺寸 ---

    // --- 同步 Draw 事件邏輯：追蹤視覺內容的起始 X ---
    var current_visual_content_x = hotbar_start_x;

    for (var i = 0; i < hotbar_slots; i++) {
        // --- 計算第 i 個格子實際繪製的矩形範圍 ---
        var slot_visual_x1 = current_visual_content_x;
        var slot_visual_y1 = hotbar_y; // Y 座標相對簡單，直接使用 hotbar_y
        var slot_visual_x2 = slot_visual_x1 + current_frame_visual_width;
        var slot_visual_y2 = slot_visual_y1 + current_frame_visual_height;

        // 使用滑鼠座標檢查是否在「實際繪製」的矩形範圍內
        if (point_in_rectangle(mx, my, slot_visual_x1, slot_visual_y1, slot_visual_x2, slot_visual_y2)) {
            return i; // 返回格子索引
        }

        // --- 同步 Draw 事件邏輯：更新下一個視覺內容的起始 X ---
        current_visual_content_x += current_frame_visual_width + hotbar_spacing;
    }
    return -1; // 不在任何格子內
}

show_debug_message("obj_main_hud Created");