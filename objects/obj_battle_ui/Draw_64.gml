// obj_battle_ui 的 Draw_64.gml

/*
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
// draw_surface(ui_surface, 0, ui_y);
*/

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

/*
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

*/

// 顯示戰鬥信息和提示 ... (保留)

/* 將繪製戰鬥狀態信息的程式碼移除 ... */

// --- 新增：繪製技能目標指示器 --- (如果存在，保留)

/* 徹底移除舊的全螢幕結果繪製邏輯
// 如果處於結果狀態，顯示戰鬥結果
if (instance_exists(obj_battle_manager) && obj_battle_manager.battle_state == BATTLE_STATE.RESULT) {
    // ... (所有舊的全螢幕結果繪製程式碼) ...
}
*/

// 重置繪圖顏色 (如果存在)
// draw_set_color(c_white);
