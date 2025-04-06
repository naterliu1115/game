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

// 提前計算外框的視覺尺寸和偏移 (假設 spr_itemframe 存在且有效)
var frame_visual_width = 96; // 後備值
var frame_visual_height = 96; // 後備值
var draw_offset_x = 0; // 後備值
var draw_offset_y = 0; // 後備值
if (sprite_exists(spr_itemframe)) {
    var frame_target_size_ref = 96; 
    var frame_original_width = sprite_get_width(spr_itemframe);
    var frame_original_height = sprite_get_height(spr_itemframe);
    var frame_scale = (frame_original_width > 0) ? frame_target_size_ref / frame_original_width : 1;
    
    // 使用新的變數名 (_bbox_*) 避免與內建變數衝突
    var _bbox_left = sprite_get_bbox_left(spr_itemframe);
    var _bbox_right = sprite_get_bbox_right(spr_itemframe);
    var _bbox_top = sprite_get_bbox_top(spr_itemframe);
    var _bbox_bottom = sprite_get_bbox_bottom(spr_itemframe);
    
    // 計算原始視覺尺寸 (使用新變數名)
    var bbox_width = _bbox_right - _bbox_left + 1;
    var bbox_height = _bbox_bottom - _bbox_top + 1;
    
    // 計算縮放後的視覺尺寸
    frame_visual_width = bbox_width * frame_scale;
    frame_visual_height = bbox_height * frame_scale;
    
    // 計算繪製偏移（讓視覺左上角對齊邏輯左上角，使用新變數名）
    draw_offset_x = _bbox_left * frame_scale;
    draw_offset_y = _bbox_top * frame_scale;
}

// 當前視覺元件的起始 X 座標
var current_visual_x = hotbar_start_x;

for (var i = 0; i < hotbar_slots; i++) {
    // 當前格子的邏輯 Y 座標
    var _y = hotbar_y; 
    // 當前格子的視覺內容起始 Y 座標 (與 _y 對齊)
    var visual_content_start_y = _y;

    // --- 繪製外框 --- 
    // 計算繪製座標
    var draw_frame_x = current_visual_x - draw_offset_x;
    var draw_frame_y = visual_content_start_y - draw_offset_y;
    
    if (sprite_exists(spr_itemframe)) {
        draw_sprite_ext(spr_itemframe, 0, draw_frame_x, draw_frame_y, frame_scale, frame_scale, 0, c_white, 1);
    } else {
        // 後備繪製 (基於視覺尺寸)
        draw_set_color(c_dkgray);
        draw_rectangle(current_visual_x, visual_content_start_y, 
                       current_visual_x + frame_visual_width, visual_content_start_y + frame_visual_height, true);
        draw_set_color(c_white);
    }

    // --- 繪製快捷欄物品 --- 
    if (hotbar_ready && inventory_ready && item_manager_exists) {
        var inventory_index = global.player_hotbar[i];
        if (inventory_index != noone && inventory_index >= 0 && inventory_index < ds_list_size(global.player_inventory)) {
            var item = global.player_inventory[| inventory_index];
            if (item != undefined) {
                var current_item_id = item.id;
                var current_item_quantity = item.quantity;
                with (obj_item_manager) {
                    var item_sprite = get_item_sprite(current_item_id); 
                    if (sprite_exists(item_sprite)) {
                        // 圖示目標尺寸 (保持內縮)
                        var target_size = 80; 
                        var spr_w = sprite_get_width(item_sprite);
                        var spr_h = sprite_get_height(item_sprite);
                        var scale_x = (spr_w > 0) ? target_size / spr_w : 1;
                        var scale_y = (spr_h > 0) ? target_size / spr_h : 1;
                        
                        // 計算繪製中心點 (基於視覺外框的中心，直接使用外層的區域變數)
                        var draw_center_x = current_visual_x + frame_visual_width / 2;
                        var draw_center_y = visual_content_start_y + frame_visual_height / 2;
                        
                        // 繪製圖示
                        draw_sprite_ext(item_sprite, 0, draw_center_x, draw_center_y, scale_x, scale_y, 0, c_white, 1);
                        
                        // 繪製數量 (基於圖示右下角)
                        if (current_item_quantity > 1) {
                            draw_set_halign(fa_right);  
                            draw_set_valign(fa_bottom); 
                            draw_set_color(c_white);
                            var icon_br_x = draw_center_x + target_size / 2;
                            var icon_br_y = draw_center_y + target_size / 2;
                            var text_offset_x = -2;
                            var text_offset_y = -2;
                            draw_text(icon_br_x + text_offset_x, icon_br_y + text_offset_y, string(current_item_quantity));
                            draw_set_halign(fa_left);
                            draw_set_valign(fa_top);
                        }
                    }
                }
            } else { global.player_hotbar[i] = noone; }
        }
    }

    // --- 標示選中的框 --- 
    if (i == selected_hotbar_slot) {
        draw_set_color(c_yellow);
        draw_set_alpha(0.5);
        // 選定框現在基於視覺尺寸
        draw_rectangle(
            current_visual_x, visual_content_start_y,
            current_visual_x + frame_visual_width -1, // 減 1 修正邊界
            visual_content_start_y + frame_visual_height -1, // 減 1 修正邊界
            false
        );
        draw_set_alpha(1);
        draw_set_color(c_white);
    }
    
    // 更新下一個視覺元件的起始 X 座標
    current_visual_x += frame_visual_width + hotbar_spacing; // 使用視覺寬度 + 間距
}

// --- 繪製右下角圖示區域 ---

// 通用繪製設定
var hint_font = fnt_dialogue; 
var hint_color = c_white;
var hint_bg_color = c_black; // 背景顏色
var hint_bg_alpha = 0.5;    // 背景透明度
var hint_bg_padding = 2;    // 背景比文字寬多少 (左右各加 padding)
var hint_padding_x = 4; 
var hint_padding_y = 4; 

// 繪製背包圖示
if (sprite_exists(bag_sprite)) {
    draw_sprite(bag_sprite, 0, bag_x, bag_y);
    
    // --- 繪製背包快捷鍵提示 ('I') ---
    var hint_char = "I";
    draw_set_font(hint_font);
    // 計算文字尺寸
    var hint_w = string_width(hint_char);
    var hint_h = string_height(hint_char);
    // 計算視覺右下角絕對座標
    var bag_visual_off_x = sprite_get_bbox_right(bag_sprite) - sprite_get_xoffset(bag_sprite);
    var bag_visual_off_y = sprite_get_bbox_bottom(bag_sprite) - sprite_get_yoffset(bag_sprite);
    var bag_visual_br_x = bag_x + bag_visual_off_x;
    var bag_visual_br_y = bag_y + bag_visual_off_y;
    // 計算文字定位點 (右下角)
    var text_x = bag_visual_br_x - hint_padding_x;
    var text_y = bag_visual_br_y - hint_padding_y;
    
    // 計算背景矩形範圍
    var bg_x1 = text_x - hint_w - hint_bg_padding; 
    var bg_y1 = text_y - hint_h - hint_bg_padding;
    var bg_x2 = text_x + hint_bg_padding;
    var bg_y2 = text_y + hint_bg_padding;
    
    // 繪製背景
    draw_set_color(hint_bg_color);
    draw_set_alpha(hint_bg_alpha);
    draw_rectangle(bg_x1, bg_y1, bg_x2, bg_y2, false);
    draw_set_alpha(1); // 恢復文字透明度

    // 繪製文字
    draw_set_color(hint_color);
    draw_set_halign(fa_right);
    draw_set_valign(fa_bottom);
    draw_text(text_x, text_y, hint_char);
}

// 繪製怪物管理按鈕
if (sprite_exists(monster_button_sprite)) {
    draw_sprite(monster_button_sprite, 0, monster_button_x, monster_button_y);
    
    // --- 繪製怪物管理快捷鍵提示 ('O') --- 
    var hint_char = "O"; // <-- 將 "3" 修改為 "O"
    draw_set_font(hint_font);
    // 計算文字尺寸
    var hint_w = string_width(hint_char);
    var hint_h = string_height(hint_char);
    // 計算視覺右下角絕對座標
    var mb_visual_off_x = sprite_get_bbox_right(monster_button_sprite) - sprite_get_xoffset(monster_button_sprite);
    var mb_visual_off_y = sprite_get_bbox_bottom(monster_button_sprite) - sprite_get_yoffset(monster_button_sprite);
    var mb_visual_br_x = monster_button_x + mb_visual_off_x;
    var mb_visual_br_y = monster_button_y + mb_visual_off_y;
    // 計算文字定位點 (右下角)
    var text_x = mb_visual_br_x - hint_padding_x;
    var text_y = mb_visual_br_y - hint_padding_y;
    
    // 計算背景矩形範圍
    var bg_x1 = text_x - hint_w - hint_bg_padding; 
    var bg_y1 = text_y - hint_h - hint_bg_padding;
    var bg_x2 = text_x + hint_bg_padding;
    var bg_y2 = text_y + hint_bg_padding;
    
    // 繪製背景
    draw_set_color(hint_bg_color);
    draw_set_alpha(hint_bg_alpha);
    draw_rectangle(bg_x1, bg_y1, bg_x2, bg_y2, false);
    draw_set_alpha(1); // 恢復文字透明度
    
    // 繪製文字
    draw_set_color(hint_color);
    draw_set_halign(fa_right);
    draw_set_valign(fa_bottom);
    draw_text(text_x, text_y, hint_char); 
}

// 繪製互動提示 (如果需要)
if (show_interaction_prompt && sprite_exists(touch_sprite)) {
    draw_sprite(touch_sprite, 0, touch_x, touch_y);
    
    // --- 繪製互動快捷鍵提示 ('E') --- 
    var hint_char = "E";
    draw_set_font(hint_font);
    // 計算文字尺寸
    var hint_w = string_width(hint_char);
    var hint_h = string_height(hint_char);
    // 計算視覺右下角絕對座標
    var touch_visual_off_x = sprite_get_bbox_right(touch_sprite) - sprite_get_xoffset(touch_sprite);
    var touch_visual_off_y = sprite_get_bbox_bottom(touch_sprite) - sprite_get_yoffset(touch_sprite);
    var touch_visual_br_x = touch_x + touch_visual_off_x;
    var touch_visual_br_y = touch_y + touch_visual_off_y;
    // 計算文字定位點 (右下角)
    var text_x = touch_visual_br_x - hint_padding_x;
    var text_y = touch_visual_br_y - hint_padding_y;
    
    // 計算背景矩形範圍
    var bg_x1 = text_x - hint_w - hint_bg_padding; 
    var bg_y1 = text_y - hint_h - hint_bg_padding;
    var bg_x2 = text_x + hint_bg_padding;
    var bg_y2 = text_y + hint_bg_padding;
    
    // 繪製背景
    draw_set_color(hint_bg_color);
    draw_set_alpha(hint_bg_alpha);
    draw_rectangle(bg_x1, bg_y1, bg_x2, bg_y2, false);
    draw_set_alpha(1); // 恢復文字透明度
    
    // 繪製文字
    draw_set_color(hint_color);
    draw_set_halign(fa_right);
    draw_set_valign(fa_bottom);
    draw_text(text_x, text_y, hint_char);
}

// --- 重設繪圖設定 ---
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_set_alpha(1);
draw_set_color(c_white);
