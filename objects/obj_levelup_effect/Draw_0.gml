// 畫出星星/火花
for (var i = 0; i < spark_count; ++i) {
    var f = spark_data[i];
    draw_set_alpha(f.alpha);
    draw_set_color(f.color);
    // 畫星星（五角星）
    var px = x + f.x;
    var py = y + f.y;
    var r = 10 * f.scale;
    for (var j = 0; j < 5; ++j) {
        var a0 = degtorad(j * 72);
        var a1 = degtorad(((j + 2) % 5) * 72);
        draw_line(px + lengthdir_x(r, radtodeg(a0)), py + lengthdir_y(r, radtodeg(a0)),
                  px + lengthdir_x(r, radtodeg(a1)), py + lengthdir_y(r, radtodeg(a1)));
    }
}
draw_set_alpha(1);
draw_set_color(c_white); 