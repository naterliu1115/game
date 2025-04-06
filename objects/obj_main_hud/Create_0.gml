// obj_main_hud - Create_0.gml

// --- 狀態變數 ---
show_interaction_prompt = false; // 是否顯示互動提示圖示 (由 Player 物件控制)
allow_player_movement = true;    // HUD 預設不阻止玩家移動

// --- 快捷欄設定 ---
hotbar_slots = 10;          // 快捷欄數量
// 先定義格子尺寸和間距
hotbar_slot_width = 96;  // <-- 定義格子寬度
hotbar_slot_height = 96; // <-- 定義格子高度
hotbar_spacing = 8;        // <-- 定義框格間距

// 再計算位置
// hotbar_x = display_get_gui_width() / 2; // 移除置中計算
var hotbar_left_padding = 20; // <-- 新增：定義左邊距
var hotbar_bottom_padding = 30; // <-- 這是底部邊距
hotbar_y = display_get_gui_height() - hotbar_slot_height - hotbar_bottom_padding; 
// hotbar_start_x = hotbar_x - (hotbar_slots * (hotbar_slot_width + hotbar_spacing) - hotbar_spacing) / 2; // 移除基於置中的計算
hotbar_start_x = hotbar_left_padding; // <-- 修改：直接使用左邊距設置起始 X

// --- 背包圖示設定 ---
bag_sprite = spr_bag;
// 重新計算背包圖示位置，假設原點為 Middle Center，並添加邊距
var bag_padding = 20; // 圖示距離螢幕邊緣的距離
bag_x = display_get_gui_width() - (sprite_get_width(bag_sprite) / 2) - bag_padding;
bag_y = display_get_gui_height() - (sprite_get_height(bag_sprite) / 2) - bag_padding;
// 更新點擊區域計算（如果需要，但通常基於 sprite 大小和中心點即可）
bag_width = sprite_get_width(bag_sprite);
bag_height = sprite_get_height(bag_sprite);
bag_bbox = [bag_x - bag_width / 2, bag_y - bag_height / 2, bag_x + bag_width / 2, bag_y + bag_height / 2]; // 點擊區域基於中心點和寬高

// --- 互動提示圖示設定 ---
touch_sprite = spr_touch;
// 調整互動提示位置，使其相對背包圖示
touch_x = bag_x; // 背包左邊一點 (基於新的 bag_x)
touch_y = bag_y - 200; // 與背包 Y 對齊 (基於新的 bag_y)
touch_width = sprite_get_width(touch_sprite);
touch_height = sprite_get_height(touch_sprite);

// --- 其他設定 (未來可能用到) ---
selected_hotbar_slot = 0; // 當前選中的快捷欄索引

show_debug_message("obj_main_hud Created");