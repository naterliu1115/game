// obj_recall_effect 的 Draw 事件
// 繪製方塊效果
draw_set_color(image_blend);
draw_set_alpha(image_alpha);
var size = 20 * scale;
draw_rectangle(x - size/2, y - size/2, x + size/2, y + size/2, false);
draw_set_alpha(1.0);
draw_set_color(c_white);