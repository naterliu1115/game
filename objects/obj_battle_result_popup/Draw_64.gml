if (!visible) exit;

victory_pulse += 0.2;
// === 初始參數 ===
var base_y = popup_y + 40;
var line_height = 30;
var item_slot_size = 64;
var item_padding = 10;
var items_cols = 5;

var items_list = [];
var result_data = undefined;
if (instance_exists(obj_battle_manager)) {
    result_data = obj_battle_manager.last_battle_result;
    if (variable_struct_exists(result_data, "item_drops")) {
        items_list = result_data.item_drops;
    }
}

// === 預先計算高度 ===
var current_y_draw = base_y;
current_y_draw += line_height * 1.5;
current_y_draw += line_height * 3;
current_y_draw += line_height * 1.5;
current_y_draw += line_height * 0.8;

if (is_array(items_list) && array_length(items_list) > 0) {
    var num_rows = ceil(array_length(items_list) / items_cols);
    current_y_draw += num_rows * (item_slot_size + item_padding);
} else {
    current_y_draw += line_height;
}

current_y_draw += 40;
popup_height = current_y_draw - popup_y + 20;

// === 背景繪製（spr_ui_result, 無彈性縮放） ===
draw_set_alpha(current_alpha);
var spr = spr_ui_result;
var sx = popup_width / sprite_get_width(spr);
var sy = popup_height / sprite_get_height(spr);
draw_sprite_ext(spr, 0, popup_x, popup_y, sx, sy, 0, c_white, current_alpha);

// === 正式內容繪製 ===
if (current_alpha > 0.9) {
    var content_x = popup_x;
    var content_y = popup_y;
    var content_center = content_x + popup_width / 2;
    var current_y_draw = content_y + 40;

    draw_set_font(fnt_dialogue);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);

// === 更大、更粗、更快的「戰鬥勝利」字樣 ===
if (result_data != undefined) {
    var victory_text = result_data.victory == 1 ? "戰鬥勝利!" : "戰鬥失敗";
    var base_y = popup_y - 30;
    var pulse_scale = 1.5 + 0.1 * sin(victory_pulse); // 更大 + 快跳動
    var color = result_data.victory == 1 ? c_lime : c_red;

    draw_set_font(fnt_dialogue);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_black);

    // 粗體描邊 (畫 8 向偏移)
    for (var ox = -1; ox <= 1; ox++) {
        for (var oy = -1; oy <= 1; oy++) {
            if (ox != 0 || oy != 0) {
                draw_text_transformed(content_center + ox, base_y + oy, victory_text, pulse_scale, pulse_scale, 0);
            }
        }
    }

    // 中心主文字
    draw_set_color(color);
    draw_text_transformed(content_center, base_y, victory_text, pulse_scale, pulse_scale, 0);
}

current_y_draw += line_height * 1.5;


    // 資訊內容
    draw_set_halign(fa_left);
    draw_set_color(c_white);
    var stats_x = content_x + (popup_width - 400) / 2; // 文字區塊置中寬度 400
    draw_text(stats_x, current_y_draw, "戰鬥時間: " + string_format(result_data.battle_duration, 3, 1) + " 秒");
    current_y_draw += line_height;
    draw_text(stats_x, current_y_draw, "擊敗敵人: " + string(result_data.defeated_enemies));
    current_y_draw += line_height;

    draw_set_color(c_yellow);
    draw_text(stats_x, current_y_draw, "獲得經驗: " + string(result_data.exp_gained));
    current_y_draw += line_height;

    draw_set_color(make_color_rgb(255, 215, 0));
    var gold = result_data.gold_gained;
    draw_text(stats_x, current_y_draw, (gold >= 0 ? "獲得金幣: " : "損失金幣: ") + string(abs(gold)));
    current_y_draw += line_height * 1.5;

    // 物品
    draw_set_color(c_white);
    draw_text(stats_x, current_y_draw, "獲得物品:");
    current_y_draw += line_height * 0.8;

    if (is_array(items_list) && array_length(items_list) > 0) {
        var item_manager_exists = instance_exists(obj_item_manager);
        var item_area_width = items_cols * (item_slot_size + item_padding) - item_padding;
        var item_start_x = content_x + (popup_width - item_area_width) / 2;

        for (var i = 0; i < array_length(items_list); i++) {
            var item_struct = items_list[i];
            if (!is_struct(item_struct)) continue;

            var item_id = item_struct.item_id;
            var quantity = item_struct.quantity;
            var item_data = item_manager_exists ? obj_item_manager.get_item(item_id) : undefined;

            var col = i mod items_cols;
            var row = i div items_cols;
            var slot_x = item_start_x + col * (item_slot_size + item_padding);
            var slot_y = current_y_draw + row * (item_slot_size + item_padding);

            if (script_exists(asset_get_index("draw_ui_item_slot"))) {
                draw_ui_item_slot(slot_x, slot_y, item_slot_size, item_slot_size, item_data, quantity, false);
            } else {
                var spr_item = obj_item_manager.get_item_sprite(item_id);
                if (sprite_exists(spr_item)) {
                    draw_sprite_stretched(spr_item, 0, slot_x, slot_y, item_slot_size, item_slot_size);
                    if (quantity > 1) {
                        draw_set_halign(fa_right);
                        draw_set_valign(fa_bottom);
                        draw_text(slot_x + item_slot_size - 2, slot_y + item_slot_size - 2, string(quantity));
                        draw_set_halign(fa_left);
                        draw_set_valign(fa_top);
                    }
                } else {
                    draw_rectangle(slot_x, slot_y, slot_x + item_slot_size, slot_y + item_slot_size, true);
                    draw_text(slot_x + 2, slot_y + 2, "?" + string(item_id));
                }
            }
        }

        var num_rows = ceil(array_length(items_list) / items_cols);
        current_y_draw += num_rows * (item_slot_size + item_padding);
    } else {
        draw_set_color(c_gray);
        draw_text(stats_x, current_y_draw, "(沒有獲得物品)");
        current_y_draw += line_height;
    }

    // 關閉提示
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom);
    draw_set_color(c_white);
    draw_text(content_center, current_y_draw + 20, "按 [空格] 或 [ESC] 關閉");
}

// 恢復繪圖狀態
draw_set_alpha(1.0);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
