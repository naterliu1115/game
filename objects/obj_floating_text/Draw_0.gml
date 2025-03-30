// obj_floating_text - Draw Event

// --- 移除 Draw 事件 Log ---
// show_debug_message("Draw event for floating text ID: " + string(id) + ", Pos: " + string(x) + "," + string(y) + ", Alpha: " + string(image_alpha) + ", Text: '" + display_text + "'");
// --- Log 結束 ---

// --- 在 Draw 事件中設置繪圖狀態 ---
// 設置字體
if (variable_global_exists("fnt_dialogue")) {
    draw_set_font(fnt_dialogue);
} else {
    // draw_set_font(fnt_default); // 設置備用字體
}

// 設置對齊
draw_set_halign(fa_center);
draw_set_valign(fa_middle);

// 設置顏色和透明度
draw_set_color(text_color);
draw_set_alpha(image_alpha);
// --- 繪圖狀態設置結束 ---

// 繪製文字
draw_text(x, y, display_text);

// --- 重置繪圖狀態 ---
// 重置 alpha 和顏色是好習慣
draw_set_alpha(1);
draw_set_color(c_white);
// 字體和對齊通常不需要每幀重置，除非您在其他地方也修改它們
// --- 重置結束 ---