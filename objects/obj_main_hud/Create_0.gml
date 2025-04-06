// obj_main_hud - Create_0.gml

// --- 狀態變數 ---
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
touch_y = bag_y; // 垂直對齊

// --- 其他設定 (未來可能用到) ---
selected_hotbar_slot = 0; 

show_debug_message("obj_main_hud Created");