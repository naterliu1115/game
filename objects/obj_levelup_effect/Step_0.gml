// 星星/火花動畫更新
anim_time += 1;
var t = anim_time / anim_duration;
for (var i = 0; i < spark_count; ++i) {
    var f = spark_data[i];
    // 位置更新
    f.x += lengthdir_x(f.spd, f.angle);
    f.y += lengthdir_y(f.spd, f.angle);
    // 縮放與透明度動畫
    f.scale = lerp(f.scale, 0.5, t);
    f.alpha = 1 - t;
    spark_data[i] = f;
}
if (anim_time >= anim_duration) instance_destroy(); 