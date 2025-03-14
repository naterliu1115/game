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
                draw_text(card_x + 5, card_y + 5, object_get_name(unit.object_index));
                
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
                draw_text(card_x + 5, card_y + 27, string(unit.hp) + "/" + string(unit.max_hp));
                
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
                    draw_text(card_x + 5, card_y + 60, "準備行動");
                } else if (unit.is_acting) {
                    draw_text(card_x + 5, card_y + 60, "行動中");
                } else if (unit.current_skill != noone) {
                    draw_text(card_x + 5, card_y + 60, unit.current_skill.name);
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
    draw_text(summon_btn_x + 20, summon_btn_y + 15, "召喚 (空格)");
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
    draw_text(summon_btn_x + 20, summon_btn_y + 15, "冷卻: " + string(ceil(cooldown_percent * 100)) + "%");
}

// 繪製戰術切換按鈕
draw_set_color(c_green);
draw_rectangle(tactics_btn_x, tactics_btn_y, tactics_btn_x + tactics_btn_width, tactics_btn_y + tactics_btn_height, false);
draw_set_color(c_white);

// 顯示當前戰術模式
var tactic_text = "";
var tactic_icon = "";
switch(current_tactic) {
    case 0: 
        tactic_text = "積極"; 
        break;
    case 1: 
        tactic_text = "防守"; 
        break;
    case 2: 
        tactic_text = "追擊"; 
        break;
}
draw_text(tactics_btn_x + 20, tactics_btn_y + 15, tactic_icon + " " + tactic_text);

// 顯示戰鬥信息和提示（帶淡入淡出效果）
if (info_alpha > 0) {
    draw_set_alpha(info_alpha);
    draw_set_halign(fa_center);
    draw_set_color(c_yellow);
    
    // 在屏幕中央顯示重要提示
    draw_text_transformed(
        display_get_gui_width() / 2, 
        display_get_gui_height() * 0.3,
        info_text,
        1.5, 1.5, 0
    );
    
    draw_set_halign(fa_left);
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
draw_text(10, ui_y + 5, battle_status);

// 如果處於結果狀態，顯示戰鬥結果
if (instance_exists(obj_battle_manager) && obj_battle_manager.battle_state == BATTLE_STATE.RESULT) {
    draw_set_alpha(0.8);
    draw_rectangle_color(0, 0, display_get_gui_width(), display_get_gui_height(),
                      c_black, c_navy, c_navy, c_black, false);
    draw_set_alpha(1.0);
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    
    // 判斷戰鬥結果
    var result_text = "";
    if (ds_list_size(obj_battle_manager.enemy_units) <= 0) {
        result_text = "戰鬥勝利!";
        draw_set_color(c_lime);
        
        show_debug_message("[DEBUG] 獎勵面板狀態檢查：");
        show_debug_message("[DEBUG] - reward_visible = " + string(reward_visible));
        show_debug_message("[DEBUG] - reward_exp = " + string(reward_exp));
        show_debug_message("[DEBUG] - reward_gold = " + string(reward_gold));
        show_debug_message("[DEBUG] - items count = " + string(array_length(reward_items_list)));
        
        // 顯示獎勵視窗
        if (reward_visible) {
            show_debug_message("[DEBUG] 開始繪製獎勵面板");
            
            // 計算完全置中的位置
            var reward_x, reward_y, panel_width, panel_height;
            
            if (sprite_exists(spr_reward_panel)) {
                panel_width = sprite_get_width(spr_reward_panel);
                panel_height = sprite_get_height(spr_reward_panel);
                reward_x = (display_get_gui_width() - panel_width) / 2;
                reward_y = (display_get_gui_height() - panel_height) / 2;
                
                show_debug_message("[DEBUG] 使用 spr_reward_panel 繪製背景");
                show_debug_message("[DEBUG] 面板尺寸: " + string(panel_width) + "x" + string(panel_height));
                show_debug_message("[DEBUG] 置中位置: (" + string(reward_x) + ", " + string(reward_y) + ")");
                
                // 先繪製勝利文字
                var scale = 1.5 + sin(current_time / 200) * 0.2;
                draw_text_transformed(
                    reward_x + panel_width/2,    // X 位置：面板中心
                    reward_y - 60,               // Y 位置：面板上方
                    result_text,
                    scale * 2, scale * 2,
                    0
                );
                
                // 再繪製背板
                draw_sprite(spr_reward_panel, 0, reward_x, reward_y);
            } else {
                show_debug_message("[DEBUG] spr_reward_panel 不存在，使用備用背景");
                // 備用背景（固定大小 300x200）
                panel_width = 300;
                panel_height = 200;
                reward_x = (display_get_gui_width() - panel_width) / 2;
                reward_y = (display_get_gui_height() - panel_height) / 2;
                
                // 先繪製勝利文字
                var scale = 1.5 + sin(current_time / 200) * 0.2;
                draw_text_transformed(
                    reward_x + panel_width/2,    // X 位置：面板中心
                    reward_y - 60,               // Y 位置：面板上方
                    result_text,
                    scale * 2, scale * 2,
                    0
                );
                
                // 再繪製備用背景
                draw_set_color(c_navy);
                draw_rectangle(reward_x, reward_y, reward_x + panel_width, reward_y + panel_height, false);
                draw_set_color(c_aqua);
                draw_rectangle(reward_x, reward_y, reward_x + panel_width, reward_y + panel_height, true);
            }
            
            // 根據面板位置調整內容位置
            var content_x = reward_x + 30;  // 內容左邊距
            var title_x = reward_x + panel_width/2;  // 標題置中
            
            // 繪製獎勵內容
            draw_set_halign(fa_center);
            draw_set_color(c_yellow);
            draw_text(title_x, reward_y + 30, "戰鬥獎勵");
            
            draw_set_halign(fa_left);
            draw_set_color(c_white);
            
            // 繪製經驗值和金幣圖示
            if (sprite_exists(spr_gold)) {
                show_debug_message("[DEBUG] 使用 spr_gold 繪製金幣圖示");
                draw_sprite(spr_gold, 0, content_x, reward_y + 100);
                draw_text(content_x + 30, reward_y + 100, string(reward_gold));
            } else {
                show_debug_message("[DEBUG] spr_gold 不存在，使用純文字顯示");
                draw_text(content_x, reward_y + 100, "金幣: " + string(reward_gold));
            }
            
            draw_text(content_x, reward_y + 70, "經驗值: " + string(reward_exp));
            
            // 畫道具圖示（最多顯示 3 個）
            if (array_length(reward_items_list) > 0) {
                for (var i = 0; i < min(array_length(reward_items_list), 3); i++) {
                    if (sprite_exists(spr_gold)) {
                        draw_sprite(spr_gold, 0, content_x + (i * 40), reward_y + 140);
                    } else {
                        draw_set_color(c_yellow);
                        draw_circle(content_x + (i * 40), reward_y + 140, 15, false);
                    }
                }
            }
        } else {
            // 如果獎勵面板還沒顯示，將勝利文字置中
            var scale = 1.5 + sin(current_time / 200) * 0.2;
            draw_text_transformed(
                display_get_gui_width() / 2,
                display_get_gui_height() / 2 - 80,
                result_text,
                scale * 2, scale * 2,
                0
            );
        }
    } else {
        result_text = "戰鬥失敗!";
        draw_set_color(c_red);
        
        // 顯示失敗文字
        var scale = 1.5 + sin(current_time / 200) * 0.2;
        draw_text_transformed(
            display_get_gui_width() / 2,
            display_get_gui_height() / 2 - 80,
            result_text,
            scale * 2, scale * 2,
            0
        );
    }
    
    // 戰鬥統計數據
    draw_set_color(c_white);
    var stats_y = display_get_gui_height() / 2;
    draw_text(display_get_gui_width() / 2, stats_y, "戰鬥時間: " + string(battle_result.duration) + "秒");
    draw_text(display_get_gui_width() / 2, stats_y + 30, "擊敗敵人: " + string(battle_result.defeated_enemies));
    
    if (battle_result.victory) {
        draw_set_color(c_yellow);
        draw_text(display_get_gui_width() / 2, stats_y + 60, "獲得經驗: " + string(battle_result.exp_gained));
    }
    
    draw_set_color(c_aqua);
    draw_text(display_get_gui_width() / 2, display_get_gui_height() / 2 + 100, 
              "按空格鍵繼續");
    
    // 重置文本對齊
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// 重置繪圖顏色
draw_set_color(c_white);
