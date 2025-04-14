// obj_battle_ui 的 Draw_64.gml


if (!surface_exists(ui_surface) || surface_needs_update) {
    if (surface_exists(ui_surface)) {
        surface_free(ui_surface);
    }
    
    ui_surface = surface_create(ui_width, ui_height);
    surface_set_target(ui_surface);
    draw_clear_alpha(c_black, 0);
    
    // 繪製UI背景（半透明漸變）
    draw_set_alpha(0.8);
    draw_rectangle_color(0, 0, ui_width, ui_height, 
                       c_navy, c_navy, c_black, c_black, false);
    draw_set_alpha(1.0);
    
    // 繪製裝飾性邊框
    draw_set_color(c_aqua);
    draw_rectangle(0, 0, ui_width, ui_height, true);
    draw_line(0, 10, ui_width, 10);
    
    surface_reset_target();
    surface_needs_update = false;
}

// 繪製基本UI表面
draw_surface(ui_surface, 0, ui_y);


// 繪製玩家單位信息
if (instance_exists(obj_battle_manager)) {
    var player_units = obj_battle_manager.player_units;
    var units_count = ds_list_size(player_units);
    
    if (units_count > 0) {
        
        // 顯示單位卡片
        for (var i = 0; i < min(units_count, 3); i++) {
            var unit = player_units[| i];
            if (instance_exists(unit)) {
                var card_x = unit_info_x + (i * 110);
                var card_y = unit_info_y;
                
                // 卡片背景（帶呼吸效果）
                var pulse_effect = sin(current_time / 1000 + i) * 5;
                draw_set_alpha(0.8);
                draw_rectangle_color(
                    card_x, card_y,
                    card_x + 100, card_y + 80,
                    c_navy, c_blue, c_blue, c_navy, false
                );
                draw_set_alpha(1.0);
                
                // 卡片邊框
                draw_set_color(c_aqua);
                draw_rectangle(card_x, card_y, card_x + 100, card_y + 80, true);
                
                // 單位名稱
                draw_set_color(c_white);
                draw_text_safe(card_x + 5, card_y + 5, object_get_name(unit.object_index), c_white, TEXT_ALIGN_LEFT, TEXT_VALIGN_TOP);
                
                // HP條
                var hp_width = 90;
                var hp_fill = (unit.hp / unit.max_hp) * hp_width;
                
                draw_set_color(c_dkgray);
                draw_rectangle(card_x + 5, card_y + 25, card_x + 5 + hp_width, card_y + 35, false);
                
                var hp_color = make_color_rgb(
                    lerp(255, 0, unit.hp / unit.max_hp),
                    lerp(0, 255, unit.hp / unit.max_hp),
                    0
                );
                
                draw_set_color(hp_color);
                draw_rectangle(card_x + 5, card_y + 25, card_x + 5 + hp_fill, card_y + 35, false);
                
                // HP文字
                draw_set_color(c_white);
                draw_text_safe(card_x + 5, card_y + 27, string(unit.hp) + "/" + string(unit.max_hp), c_white, TEXT_ALIGN_LEFT, TEXT_VALIGN_TOP);
                
                // ATB條
                var atb_width = 90;
                var atb_fill = (unit.atb_current / unit.atb_max) * atb_width;
                
                draw_set_color(c_dkgray);
                draw_rectangle(card_x + 5, card_y + 45, card_x + 5 + atb_width, card_y + 50, false);
                
                draw_set_color(c_aqua);
                draw_rectangle(card_x + 5, card_y + 45, card_x + 5 + atb_fill, card_y + 50, false);
                
                // 顯示當前行動或技能
                draw_set_color(c_yellow);
                if (unit.atb_ready) {
                    draw_text_safe(card_x + 5, card_y + 60, "準備行動", c_yellow, TEXT_ALIGN_LEFT, TEXT_VALIGN_TOP);
                } else if (unit.is_acting) {
                    draw_text_safe(card_x + 5, card_y + 60, "行動中", c_yellow, TEXT_ALIGN_LEFT, TEXT_VALIGN_TOP);
                } else if (unit.current_skill != noone) {
                    draw_text_safe(card_x + 5, card_y + 60, unit.current_skill.name, c_yellow, TEXT_ALIGN_LEFT, TEXT_VALIGN_TOP);
                }
            }
        }
    }
}

// 繪製召喚按鈕（帶發光效果）
var summon_enabled = true;
if (instance_exists(obj_battle_manager)) {
    summon_enabled = (obj_battle_manager.global_summon_cooldown <= 0);
}

if (summon_enabled) {
    // 發光效果
    var glow = sin(current_time / 300) * 20;
    draw_set_alpha(0.5);
    draw_rectangle_color(
        summon_btn_x - glow/2, summon_btn_y - glow/2,
        summon_btn_x + summon_btn_width + glow/2, summon_btn_y + summon_btn_height + glow/2,
        c_aqua, c_aqua, c_blue, c_blue, false
    );
    draw_set_alpha(1.0);
    
    draw_set_color(c_blue);
    draw_rectangle(summon_btn_x, summon_btn_y, summon_btn_x + summon_btn_width, summon_btn_y + summon_btn_height, false);
    draw_set_color(c_white);
    draw_text_safe(summon_btn_x + 20, summon_btn_y + 15, "召喚 (空格)", c_white, TEXT_ALIGN_LEFT, TEXT_VALIGN_MIDDLE);
} else {
    // 冷卻中的按鈕
    var cooldown_percent = obj_battle_manager.global_summon_cooldown / obj_battle_manager.max_global_cooldown;
    
    draw_set_color(c_dkgray);
    draw_rectangle(summon_btn_x, summon_btn_y, summon_btn_x + summon_btn_width, summon_btn_y + summon_btn_height, false);
    
    // 冷卻進度條
    draw_set_color(c_gray);
    draw_rectangle(
        summon_btn_x, summon_btn_y,
        summon_btn_x + (1 - cooldown_percent) * summon_btn_width, summon_btn_y + summon_btn_height, 
        false
    );
    
    draw_set_color(c_white);
    draw_text_safe(summon_btn_x + 20, summon_btn_y + 15, "冷卻: " + string(ceil(cooldown_percent * 100)) + "%", c_white, TEXT_ALIGN_LEFT, TEXT_VALIGN_MIDDLE);
}

// 繪製戰術切換按鈕
draw_set_color(c_green);
draw_rectangle(tactics_btn_x, tactics_btn_y, tactics_btn_x + tactics_btn_width, tactics_btn_y + tactics_btn_height, false);
draw_set_color(c_white);

// 顯示當前戰術模式
var tactic_text = "";
var tactic_icon = "";
var tactic_color = c_white;
switch(current_tactic) {
    case 0: 
        tactic_text = "積極"; 
        tactic_color = c_red;
        break;
    case 1: 
        tactic_text = "跟隨"; 
        tactic_color = c_lime;
        break;
    case 2: 
        tactic_text = "待命"; 
        tactic_color = c_aqua;
        break;
}
draw_set_color(tactic_color);
draw_text_safe(tactics_btn_x + 20, tactics_btn_y + 15, tactic_icon + " " + tactic_text, tactic_color, TEXT_ALIGN_LEFT, TEXT_VALIGN_MIDDLE);

// 顯示戰鬥信息和提示（帶淡入淡出效果）
if (info_alpha > 0) {
    draw_set_alpha(info_alpha);
    
    // 在屏幕中央顯示重要提示
    draw_text_outlined(
        display_get_gui_width() / 2, 
        display_get_gui_height() * 0.3,
        info_text,
        c_yellow,
        c_black,
        TEXT_ALIGN_CENTER,
        TEXT_VALIGN_MIDDLE
    );
    
    draw_set_alpha(1.0);
}

// 顯示戰鬥狀態信息
draw_set_color(c_white);
var battle_status = "戰鬥進行中";
if (instance_exists(obj_battle_manager)) {
    var player_count = ds_list_size(obj_battle_manager.player_units);
    var enemy_count = ds_list_size(obj_battle_manager.enemy_units);
    var battle_time = obj_battle_manager.battle_timer / game_get_speed(gamespeed_fps);
    
    battle_status = "時間: " + string_format(battle_time, 3, 1) + "秒 | 我方: " + string(player_count) + " | 敵方: " + string(enemy_count);
}
draw_text_safe(10, ui_y + 5, battle_status, c_white, TEXT_ALIGN_LEFT, TEXT_VALIGN_TOP);

// 如果處於結果狀態，顯示戰鬥結果
if (instance_exists(obj_battle_manager) && obj_battle_manager.battle_state == BATTLE_STATE.RESULT) {
    draw_set_alpha(0.8);
    draw_rectangle_color(0, 0, display_get_gui_width(), display_get_gui_height(),
                      c_black, c_navy, c_navy, c_black, false);
    draw_set_alpha(1.0);
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    
    // 修改：判斷戰鬥結果，使用 battle_victory_status
    var result_text = "";
    var result_color = c_white;
    var stats_y = display_get_gui_height() / 2; // 統計文本的起始 Y 座標

    if (battle_victory_status == 1) { // 勝利
        result_text = "戰鬥勝利!";
        result_color = c_lime;
        
        // 繪製勝利文字
        var scale = 1.5 + sin(current_time / 200) * 0.2;
        draw_text_outlined(
            display_get_gui_width() / 2,
            stats_y - 100, // 向上移動標題
            result_text,
            result_color,
            c_black,
            TEXT_ALIGN_CENTER,
            TEXT_VALIGN_MIDDLE,
            scale * 2.0 // 調整縮放
        );

        // 顯示獎勵信息
        if (reward_visible) {
            draw_set_color(c_white);
            // 修改：使用記錄的變數顯示統計
            draw_text_safe(display_get_gui_width() / 2, stats_y - 30, "戰鬥時間: " + string_format(battle_duration, 3, 1) + "秒", c_white, TEXT_ALIGN_CENTER, TEXT_VALIGN_MIDDLE);
            draw_text_safe(display_get_gui_width() / 2, stats_y + 0, "擊敗敵人: " + string(defeated_enemies_count), c_white, TEXT_ALIGN_CENTER, TEXT_VALIGN_MIDDLE);
            draw_set_color(c_yellow);
            draw_text_safe(display_get_gui_width() / 2, stats_y + 30, "獲得經驗: " + string(reward_exp), c_yellow, TEXT_ALIGN_CENTER, TEXT_VALIGN_MIDDLE);
            draw_set_color(make_color_rgb(255, 215, 0)); // 金色
            draw_text_safe(display_get_gui_width() / 2, stats_y + 60, "獲得金幣: " + string(reward_gold), make_color_rgb(255, 215, 0), TEXT_ALIGN_CENTER, TEXT_VALIGN_MIDDLE);
            
            // --- 新增：繪製獲得物品網格 --- 
            var list_size = ds_list_size(reward_items_list);
            if (list_size > 0) {
                draw_set_halign(fa_left);
                draw_set_valign(fa_top);
                draw_set_font(fnt_dialogue);
                draw_set_color(c_white);
                draw_text(items_start_x, items_start_y - 30, "獲得物品:");
                
                for (var i = 0; i < list_size; i++) {
                    var item_struct = reward_items_list[| i];
                    var item_id = item_struct.item_id;
                    var quantity = item_struct.quantity;
                    
                    // **從 reward_items 結構體獲取 item_data**
                    // **假設 reward_items[i] 的結構是 { item_id: ..., quantity: ..., item_data: ... }**
                    // **如果不是，需要先用 get_item 獲取**
                    var item_data = obj_item_manager.get_item(item_id); // **假設需要重新獲取**
                    if (is_undefined(item_data)) {
                        show_debug_message("警告: 在繪製戰利品時找不到物品資料 ID: " + string(item_id));
                        continue; // 跳過這個物品
                    }

                    var col = i % items_cols;
                    var row = floor(i / items_cols);
                    
                    // 計算格子和圖示的繪製位置
                    var cell_x = items_start_x + col * items_cell_width;
                    var cell_y = items_start_y + row * items_cell_height;
                    var icon_x = cell_x + (items_cell_width - items_icon_size) / 2;
                    var icon_y = cell_y + (items_cell_height - items_icon_size) / 2;
                    
                    // --- 新增：使用 draw_ui_item_slot 繪製物品槽 ---
                    draw_ui_item_slot(
                        cell_x, 
                        cell_y, 
                        items_cell_width, 
                        items_cell_height, 
                        item_data,        // 傳遞完整的物品資料
                        quantity,         // 傳遞數量
                        false             // is_selected 設為 false
                    );
                    // --- 結束新增 ---
                    
                    // (可選) 繪製懸停高亮
                    if (hovered_reward_item_index == i) {
                        draw_set_alpha(0.3);
                        draw_set_color(c_yellow);
                        draw_rectangle(cell_x, cell_y, cell_x + items_cell_width - 1, cell_y + items_cell_height - 1, false); // 畫一個高亮框
                        draw_set_alpha(1.0);
                    }
                }
                // 重置繪製對齊和顏色
                draw_set_halign(fa_center);
                draw_set_valign(fa_middle);
                draw_set_color(c_white);
            }
            // --- 結束新增 --- 
        }
    } else if (battle_victory_status == 0) { // 失敗
        result_text = "戰鬥失敗!";
        result_color = c_red;
        
        // 繪製失敗文字
        var scale = 1.5 + sin(current_time / 200) * 0.2;
        draw_text_outlined(
            display_get_gui_width() / 2,
            stats_y - 80, // 向上移動標題
            result_text,
            result_color,
            c_black,
            TEXT_ALIGN_CENTER,
            TEXT_VALIGN_MIDDLE,
            scale * 2.4
        );

        // 顯示懲罰信息
        draw_set_color(c_white);
        // *** 添加繪製前日誌 ***
        //show_debug_message("[Draw GUI] Drawing defeat stats: duration=" + string(battle_duration) + ", defeated=" + string(defeated_enemies_count));
        draw_text_safe(display_get_gui_width() / 2, stats_y - 30, "戰鬥時間: " + string_format(battle_duration, 3, 1) + "秒", c_white, TEXT_ALIGN_CENTER, TEXT_VALIGN_MIDDLE);
        draw_text_safe(display_get_gui_width() / 2, stats_y + 0, "擊敗敵人: " + string(defeated_enemies_count), c_white, TEXT_ALIGN_CENTER, TEXT_VALIGN_MIDDLE);
        // 顯示經驗 (可能是部分經驗)
        if (reward_exp > 0) {
            draw_set_color(c_yellow);
            // *** 添加繪製前日誌 ***
            //show_debug_message("[Draw GUI] Drawing defeat exp: " + string(reward_exp));
            draw_text_safe(display_get_gui_width() / 2, stats_y + 30, "獲得經驗: " + string(reward_exp), c_yellow, TEXT_ALIGN_CENTER, TEXT_VALIGN_MIDDLE);
        }
        // 顯示金幣損失 (使用 defeat_penalty_text)
        if (variable_instance_exists(id, "defeat_penalty_text") && defeat_penalty_text != "") {
             // *** 添加繪製前日誌 ***
            //show_debug_message("[Draw GUI] Drawing defeat penalty text: " + defeat_penalty_text);
             draw_text_outlined(
                 display_get_gui_width() / 2,
                 stats_y + 60, // 調整Y位置
                 defeat_penalty_text,
                 c_white,
                 c_black,
                 TEXT_ALIGN_CENTER,
                 TEXT_VALIGN_MIDDLE
            );
        }
    } else { // 未知狀態
        result_text = "等待結果...";
        result_color = c_white;
        draw_set_color(result_color);
        draw_text_safe(display_get_gui_width() / 2, display_get_gui_height() / 2, result_text, result_color, TEXT_ALIGN_CENTER, TEXT_VALIGN_MIDDLE);
    }
    
    // 添加通用提示
    if (battle_victory_status != -1) { // 只有在結果確定後才顯示
        draw_set_color(c_white);
        draw_text_safe(display_get_gui_width() / 2, display_get_gui_height() - 60, "按空格鍵繼續", c_white, TEXT_ALIGN_CENTER, TEXT_VALIGN_BOTTOM);
    }
}

// 重置繪圖顏色
draw_set_color(c_white);
