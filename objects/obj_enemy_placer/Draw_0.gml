// obj_enemy_placer - Draw_0.gml

// 繪製半透明的敵人精靈
draw_sprite_ext(sprite_index, image_index, x, y, image_xscale, image_yscale, image_angle, c_white, image_alpha);

// 繪製模板ID和名稱
if (draw_template_id) {
    draw_set_font(fnt_dialogue);
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    
    // 繪製背景
    var text = string(template_id) + ": " + template_name;
    var text_width = string_width(text) + 10;
    var text_height = string_height(text) + 6;
    
    draw_set_alpha(0.7);
    draw_rectangle_color(
        x - text_width/2, y + sprite_height/2,
        x + text_width/2, y + sprite_height/2 + text_height,
        c_black, c_black, c_black, c_black, false
    );
    draw_set_alpha(1);
    
    // 繪製文字
    draw_text_color(
        x, y + sprite_height/2 + 3,
        text,
        c_white, c_white, c_white, c_white, 1
    );
    
    // 重置對齊
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// 繪製使用說明
/*
var instructions = [
    "← 放置工具說明 →",
    "左鍵: 放置敵人",
    "Q/E: 切換敵人類型",
    "R: 刪除附近敵人",
    "ESC: 退出放置模式"
];

var margin = 10;
var padding = 5;
var line_height = 20;
var text_width = 0;

// 計算文字寬度
for (var i = 0; i < array_length(instructions); i++) {
    var w = string_width(instructions[i]) + padding * 2;
    if (w > text_width) text_width = w;
}

// 繪製背景
draw_set_alpha(0.8);
draw_rectangle_color(
    margin, margin,
    margin + text_width, margin + line_height * array_length(instructions),
    c_black, c_black, c_black, c_black, false
);
draw_set_alpha(1);

// 繪製文字
draw_set_font(fnt_dialogue);
for (var i = 0; i < array_length(instructions); i++) {
    var y_pos = margin + i * line_height;
    draw_text_color(
        margin + padding, y_pos + padding,
        instructions[i],
        c_white, c_white, c_white, c_white, 1
    );
} 
*/ 