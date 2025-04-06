// obj_main_hud - Draw_64.gml

// --- 繪製道具快捷欄 ---
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);
draw_set_color(c_white);

// 檢查快捷欄數據結構是否存在
var hotbar_ready = variable_global_exists("player_hotbar") && is_array(global.player_hotbar);
var inventory_ready = variable_global_exists("player_inventory") && ds_exists(global.player_inventory, ds_type_list);
var item_manager_exists = instance_exists(obj_item_manager);

for (var i = 0; i < hotbar_slots; i++) {
    var _x = hotbar_start_x + i * (hotbar_slot_width + hotbar_spacing);
    var _y = hotbar_y;

    // 繪製外框 (使用 draw_sprite_ext 進行縮放)
    var frame_target_size = 96;
    var frame_original_size = 128; // 假設 spr_itemframe 原始尺寸為 128x128
    // 防止除以零
    var frame_scale = (frame_original_size > 0) ? frame_target_size / frame_original_size : 1; 
    
    if (sprite_exists(spr_itemframe)) {
        // 因為 spr_itemframe 原點是 Top Left，所以繪製座標仍然是 _x, _y
        // 但應用縮放比例 frame_scale
        draw_sprite_ext(spr_itemframe, 0, _x, _y, frame_scale, frame_scale, 0, c_white, 1);
    } else {
        // 如果 spr_itemframe 不存在，可以畫一個簡單的矩形代替
        draw_set_color(c_dkgray);
        draw_rectangle(_x, _y, _x + frame_target_size, _y + frame_target_size, true);
        draw_set_color(c_white);
    }

    // 繪製快捷欄物品 (基於 global.player_hotbar)
    if (hotbar_ready && inventory_ready && item_manager_exists) {
        var inventory_index = global.player_hotbar[i];
        
        // 檢查索引是否有效且指向一個實際物品
        if (inventory_index != noone && inventory_index >= 0 && inventory_index < ds_list_size(global.player_inventory)) {
            var item = global.player_inventory[| inventory_index];
            
            if (item != undefined) {
                // 將 item.id 和 item.quantity 存儲在臨時變量中
                var current_item_id = item.id;
                var current_item_quantity = item.quantity;
                
                // 通過 obj_item_manager 實例獲取物品圖示
                with (obj_item_manager) {
                    // 使用臨時變量 current_item_id
                    var item_sprite = get_item_sprite(current_item_id); 
                    if (sprite_exists(item_sprite)) {
                        // 計算縮放比例，將原始圖示縮放到目標尺寸 (例如 80x80)
                        var target_size = 80; // <-- 將目標尺寸從 96 改為 80 (或你想要的其他值)
                        var spr_w = sprite_get_width(item_sprite);
                        var spr_h = sprite_get_height(item_sprite);
                        // 防止除以零
                        var scale_x = (spr_w > 0) ? target_size / spr_w : 1;
                        var scale_y = (spr_h > 0) ? target_size / spr_h : 1;
                        
                        // 計算繪製中心點 (仍然基於 96x96 的格子尺寸)
                        var draw_center_x = _x + other.hotbar_slot_width / 2;
                        var draw_center_y = _y + other.hotbar_slot_height / 2;
                        
                        // 繪製物品圖示 (使用計算出的縮放比例和中心點)
                        draw_sprite_ext(
                            item_sprite, 0,
                            draw_center_x,
                            draw_center_y,
                            scale_x, // 使用計算的縮放 X
                            scale_y, // 使用計算的縮放 Y
                            0, c_white, 1
                        );
                        
                        // 如果物品可堆疊且數量大於1，顯示數量 (位置計算不變)
                        if (current_item_quantity > 1) {
                            draw_set_halign(fa_right);
                            draw_set_valign(fa_bottom);
                            draw_set_color(c_white);
                            draw_text(
                                _x + other.hotbar_slot_width - 2, 
                                _y + other.hotbar_slot_height - 2, 
                                string(current_item_quantity)
                            );
                            // 重設文字對齊
                            draw_set_halign(fa_left);
                            draw_set_valign(fa_top);
                        }
                    }
                }
            } else {
                // 如果索引指向的物品無效，可以選擇清除該快捷欄位
                global.player_hotbar[i] = noone; 
            }
        }
        // 如果 inventory_index 是 noone，則不繪製任何物品，格子為空
    }

    // 標示選中的框
    if (i == selected_hotbar_slot) {
        draw_set_color(c_yellow);
        draw_set_alpha(0.5);
        draw_rectangle(
            _x, _y,
            _x + hotbar_slot_width,
            _y + hotbar_slot_height,
            false
        );
        draw_set_alpha(1);
        draw_set_color(c_white);
    }
}

// --- 繪製背包圖示 ---
draw_sprite(bag_sprite, 0, bag_x, bag_y);

// --- 繪製互動提示 (如果需要) ---
if (show_interaction_prompt) {
    draw_sprite(touch_sprite, 0, touch_x, touch_y);
}

// --- 重設繪圖設定 ---
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);
draw_set_color(c_white);
