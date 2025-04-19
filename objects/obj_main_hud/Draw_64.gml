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
    var _y = hotbar_y;
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
    var skip_drawing_item = (is_dragging_hotbar_item && i == dragged_from_hotbar_slot);
    
    if (!skip_drawing_item && hotbar_ready && inventory_ready && item_manager_exists) {
        var inventory_index = global.player_hotbar[i];
        if (inventory_index != noone && inventory_index >= 0 && inventory_index < ds_list_size(global.player_inventory)) {
            var item = global.player_inventory[| inventory_index];
            if (item != undefined) {
                var current_item_id = item.item_id;
                var current_item_quantity = item.quantity;
                with (obj_item_manager) {
                    var item_sprite = get_item_sprite(current_item_id);
                    if (sprite_exists(item_sprite)) {
                        // --- 修改開始 ---
                        // 預設圖示目標繪製尺寸 (在 96x96 的框內)
                        var default_target_size = 80;
                        var current_target_size = default_target_size; // 初始化為預設值

                        // [特殊規則] 如果是藥水 (ID 1001-1003)，則稍微縮小一點，避免滿版看起來過大
                        if (current_item_id >= 1001 && current_item_id <= 1003) {
                            current_target_size = default_target_size * 0.7; // <-- 將藥水目標尺寸縮小為 80%
                        }
                        // --- 修改結束 ---

                        var spr_w = sprite_get_width(item_sprite);
                        var spr_h = sprite_get_height(item_sprite);
                        // --- 修改開始 ---
                        // 使用 current_target_size 計算縮放比例
                        var scale_x = (spr_w > 0) ? current_target_size / spr_w : 1;
                        var scale_y = (spr_h > 0) ? current_target_size / spr_h : 1;
                        // --- 修改結束 ---

                        // --- DEBUGGING: 印出藥水繪製資訊 ---
                        // [移除] 這段偵錯訊息不再需要
                        // if (current_item_id >= 1001 && current_item_id <= 1003) {
                        //     show_debug_message("繪製藥水 ID: " + string(current_item_id) +
                        //                        ", 原始尺寸: " + string(spr_w) + "x" + string(spr_h) +
                        //                        ", 目標尺寸: " + string(current_target_size) +
                        //                        ", 縮放比例: " + string(scale_x) + "x" + string(scale_y));
                        // }
                        // --- END DEBUGGING ---

                        // 計算繪製中心點 (基於視覺外框的中心)
                        var draw_center_x = current_visual_x + frame_visual_width / 2;
                        var draw_center_y = visual_content_start_y + frame_visual_height / 2;

                        // 繪製圖示 (使用計算好的縮放比例)
                        draw_sprite_ext(item_sprite, 0, draw_center_x, draw_center_y, scale_x, scale_y, 0, c_white, 1);

                        // 繪製數量 (統一基於格子右下角)
                        if (current_item_quantity > 1) {
                            draw_set_halign(fa_right);
                            draw_set_valign(fa_bottom);
                            draw_set_color(c_white);
                            // --- 修改開始 ---
                            // 將數量定位點改為基於快捷欄「格子」的視覺右下角，以保持一致性
                            var slot_visual_right = current_visual_x + frame_visual_width;
                            var slot_visual_bottom = visual_content_start_y + frame_visual_height;
                            var quantity_padding_x = 5; // 離格子右邊界的 X 距離 (可調整)
                            var quantity_padding_y = 5; // 離格子下邊界的 Y 距離 (可調整)

                            // 計算最終繪製位置 (由於對齊是 right, bottom，這就是繪製點)
                            var text_draw_x = slot_visual_right - quantity_padding_x;
                            var text_draw_y = slot_visual_bottom - quantity_padding_y;
                            // --- 修改結束 ---

                            draw_text(text_draw_x, text_draw_y, string(current_item_quantity)); // 使用新的座標
                            draw_set_halign(fa_left); // 恢復預設對齊
                            draw_set_valign(fa_top);  // 恢復預設對齊
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

// --- 新增：繪製正在拖曳的物品 --- 
if (is_dragging_hotbar_item && sprite_exists(dragged_item_sprite)) {
    // 使用與快捷欄內繪製相同的目標尺寸和縮放邏輯
    var target_size = 80; 
    var spr_w = sprite_get_width(dragged_item_sprite);
    var spr_h = sprite_get_height(dragged_item_sprite);
    var scale_x = (spr_w > 0) ? target_size / spr_w : 1;
    var scale_y = (spr_h > 0) ? target_size / spr_h : 1;
    
    // 繪製中心點就是跟隨滑鼠的 drag_item_x, drag_item_y (可以稍微偏移)
    var draw_drag_x = drag_item_x; 
    var draw_drag_y = drag_item_y;
    
    // 設置半透明效果，表示正在拖曳
    draw_set_alpha(0.7);
    draw_sprite_ext(dragged_item_sprite, 0, draw_drag_x, draw_drag_y, scale_x, scale_y, 0, c_white, 1);
    draw_set_alpha(1); // 恢復透明度
}
// --- 結束繪製拖曳物品 --- 

// --- 繪製右下角圖示區域 ---

// 獲取戰鬥狀態
var _in_battle = (instance_exists(obj_battle_manager) && obj_battle_manager.battle_state != BATTLE_STATE.INACTIVE);

// 通用繪製設定
var hint_font = fnt_dialogue; 
var hint_color = c_white;
var hint_bg_color = c_black; // 背景顏色
var hint_bg_alpha = 0.5;    // 背景透明度
var hint_bg_padding = 2;    // 背景比文字寬多少 (左右各加 padding)
var hint_padding_x = 4; 
var hint_padding_y = 4; 

if (!_in_battle) {
    // --- 非戰鬥狀態：繪製原背包和怪物管理按鈕 --- 
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
        var hint_char = "O";
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
} else {
    // --- 戰鬥狀態：繪製召喚、收服、戰術按鈕 --- 
    
    // --- 新增：繪製頂部戰鬥狀態信息 --- 
    var battle_status = "讀取戰鬥信息...";
    var player_count = 0; // 初始化
    var enemy_count = 0;  // 初始化
    var battle_time = 0;  // 初始化

    if (instance_exists(obj_battle_manager)) {
        battle_time = obj_battle_manager.battle_timer / game_get_speed(gamespeed_fps);
        // 從 obj_unit_manager 獲取單位數量
        if (instance_exists(obj_unit_manager)) {
            if (ds_exists(obj_unit_manager.player_units, ds_type_list)) {
                player_count = ds_list_size(obj_unit_manager.player_units);
            }
            if (ds_exists(obj_unit_manager.enemy_units, ds_type_list)) {
                enemy_count = ds_list_size(obj_unit_manager.enemy_units);
            }
        } else {
             show_debug_message("[HUD Draw] 警告: obj_unit_manager 不存在，無法獲取單位數量。");
        }
    } else {
        show_debug_message("[HUD Draw] 警告: obj_battle_manager 不存在，無法獲取戰鬥時間。");
    }
    
    // 組合狀態字串
    battle_status = "時間: " + string_format(battle_time, 3, 1) + "秒 | 我方: " + string(player_count) + " | 敵方: " + string(enemy_count);
    
    draw_set_font(hint_font);
    // draw_set_color(c_white); // Color is handled by draw_text_outlined
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_text_outlined(display_get_gui_width() / 2, 20, battle_status, c_yellow, c_black, fa_center, fa_top, 1.2); // <-- Use outlined text
    // --- 結束新增：戰鬥狀態信息 ---
    
    // --- 修改：繪製召喚按鈕 (加入冷卻顯示) --- 
    if (sprite_exists(spr_summon)) {
        var summon_sprite = spr_summon;
        var summon_x = bag_x;
        var summon_y = bag_y;
        var draw_color = c_white;
        var draw_alpha = 1.0;
        var show_cooldown_overlay = false;
        var cooldown_percent = 0;

        if (instance_exists(obj_battle_manager)) {
            if (obj_battle_manager.global_summon_cooldown > 0) {
                draw_color = c_dkgray; // 變暗
                draw_alpha = 0.7;
                show_cooldown_overlay = true;
                // 確保 max_global_cooldown 存在且不為0
                if (variable_instance_exists(obj_battle_manager, "max_global_cooldown") && obj_battle_manager.max_global_cooldown > 0) {
                     cooldown_percent = obj_battle_manager.global_summon_cooldown / obj_battle_manager.max_global_cooldown;
                } else {
                     cooldown_percent = 1; // 無法計算，假設滿冷卻
                     // show_debug_message("警告: 無法讀取 max_global_cooldown");
                }
            }
        }

        // 繪製按鈕本身
        draw_sprite_ext(summon_sprite, 0, summon_x, summon_y, 1, 1, 0, draw_color, draw_alpha);

        // 如果在冷卻中，繪製疊加效果
        if (show_cooldown_overlay) {
            var spr_h = sprite_get_height(summon_sprite);
            var spr_w = sprite_get_width(summon_sprite);
            var overlay_x1 = summon_x - spr_w / 2;
            var overlay_y1 = summon_y + spr_h / 2; // 底部 Y
            var overlay_x2 = summon_x + spr_w / 2;
            var overlay_y2 = overlay_y1 - spr_h * (1 - cooldown_percent); // 根據完成度計算頂部 Y

            draw_set_alpha(0.6); // 半透明疊加
            draw_set_color(c_blue);
            draw_rectangle(overlay_x1, overlay_y1, overlay_x2, overlay_y2, false);
            draw_set_alpha(1.0); // 恢復

            // (可選) 繪製冷卻百分比文字
            /*
            draw_set_color(c_white);
            draw_set_halign(fa_center);
            draw_set_valign(fa_middle);
            draw_text(summon_x, summon_y, string(ceil((1-cooldown_percent)*100)) + "%");
            */
        }
        
        // --- 繪製召喚快捷鍵提示 (Space) --- 
        var hint_char = "Space"; // 使用文字
        draw_set_font(hint_font);
        var hint_w = string_width(hint_char);
        var hint_h = string_height(hint_char);
        var visual_off_x = sprite_get_bbox_right(summon_sprite) - sprite_get_xoffset(summon_sprite);
        var visual_off_y = sprite_get_bbox_bottom(summon_sprite) - sprite_get_yoffset(summon_sprite);
        var visual_br_x = bag_x + visual_off_x;
        var visual_br_y = bag_y + visual_off_y;
        var text_x = visual_br_x - hint_padding_x;
        var text_y = visual_br_y - hint_padding_y;
        var bg_x1 = text_x - hint_w - hint_bg_padding; var bg_y1 = text_y - hint_h - hint_bg_padding;
        var bg_x2 = text_x + hint_bg_padding; var bg_y2 = text_y + hint_bg_padding;
        draw_set_color(hint_bg_color); draw_set_alpha(hint_bg_alpha);
        draw_rectangle(bg_x1, bg_y1, bg_x2, bg_y2, false);
        draw_set_alpha(1); draw_set_color(hint_color);
        draw_set_halign(fa_right); draw_set_valign(fa_bottom);
        draw_text(text_x, text_y, hint_char);
    }
    
    // 繪製收服按鈕 (取代怪物管理位置)
    if (sprite_exists(spr_capture)) {
        draw_sprite(spr_capture, 0, monster_button_x, monster_button_y);
        // --- 繪製收服快捷鍵提示 (C) --- 
        var hint_char = "C";
        draw_set_font(hint_font);
        var hint_w = string_width(hint_char);
        var hint_h = string_height(hint_char);
        var text_x = monster_button_x - hint_padding_x;
        var text_y = monster_button_y - hint_padding_y;
        var bg_x1 = text_x - hint_w - hint_bg_padding; var bg_y1 = text_y - hint_h - hint_bg_padding;
        var bg_x2 = text_x + hint_bg_padding; var bg_y2 = text_y + hint_bg_padding;
        draw_set_color(hint_bg_color); draw_set_alpha(hint_bg_alpha);
        draw_rectangle(bg_x1, bg_y1, bg_x2, bg_y2, false);
        draw_set_alpha(1); draw_set_color(hint_color);
        draw_set_halign(fa_right); draw_set_valign(fa_bottom);
        draw_text(text_x, text_y, hint_char);
    }
    
    // 繪製戰術按鈕
    if (sprite_exists(spr_tactics)) {
        draw_sprite(spr_tactics, 0, tactics_button_x, tactics_button_y);
        // --- 繪製戰術快捷鍵提示 (T) --- 
        var hint_char = "T";
        draw_set_font(hint_font);
        var hint_w = string_width(hint_char);
        var hint_h = string_height(hint_char);
        var text_x = tactics_button_x - hint_padding_x;
        var text_y = tactics_button_y - hint_padding_y;
        var bg_x1 = text_x - hint_w - hint_bg_padding; var bg_y1 = text_y - hint_h - hint_bg_padding;
        var bg_x2 = text_x + hint_bg_padding; var bg_y2 = text_y + hint_bg_padding;
        draw_set_color(hint_bg_color); draw_set_alpha(hint_bg_alpha);
        draw_rectangle(bg_x1, bg_y1, bg_x2, bg_y2, false);
        draw_set_alpha(1); draw_set_color(hint_color);
        draw_set_halign(fa_right); draw_set_valign(fa_bottom);
        draw_text(text_x, text_y, hint_char);
    }
    
    // --- 繪製當前戰術模式文字 --- 
    if (instance_exists(obj_battle_manager)) {
        var current_tactic = obj_battle_manager.current_global_tactic;
        var tactic_text = "未知";
        switch(current_tactic) {
            case AI_MODE.AGGRESSIVE: tactic_text = "模式:積極"; break;
            case AI_MODE.FOLLOW: tactic_text = "模式:跟隨"; break;
            case AI_MODE.PASSIVE: tactic_text = "模式:待命"; break;
        }
        
        draw_set_font(hint_font);
        var text_w = string_width(tactic_text);
        var text_h = string_height(tactic_text);
        
        // 定位在戰術按鈕上方
        var tactic_text_x = tactics_button_x; // 中心對齊
        var tactic_text_y = tactics_button_y - sprite_get_height(spr_tactics) / 2 - text_h / 2 - 5; // 向上偏移5像素
        
        // 計算背景
        var bg_x1 = tactic_text_x - text_w / 2 - hint_bg_padding;
        var bg_y1 = tactic_text_y - text_h / 2 - hint_bg_padding;
        var bg_x2 = tactic_text_x + text_w / 2 + hint_bg_padding;
        var bg_y2 = tactic_text_y + text_h / 2 + hint_bg_padding;
        
        // 繪製背景
        draw_set_color(hint_bg_color); draw_set_alpha(hint_bg_alpha);
        draw_rectangle(bg_x1, bg_y1, bg_x2, bg_y2, false);
        draw_set_alpha(1);
        
        // 繪製文字
        draw_set_color(c_white);
        draw_set_halign(fa_center);
        draw_set_valign(fa_middle);
        draw_text(tactic_text_x, tactic_text_y, tactic_text);
    }
}

// --- 繪製互動提示圖示 (只在非戰鬥時顯示) ---
if (!_in_battle && show_interaction_prompt && sprite_exists(touch_sprite)) {
    // ... (原有的互動提示繪製程式碼) ...
    // draw_sprite(touch_sprite, 0, touch_x, touch_y);
}

// 恢復預設繪製對齊
draw_set_halign(fa_left);
draw_set_valign(fa_top);
