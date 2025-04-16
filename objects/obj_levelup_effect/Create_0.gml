// 升級特效：星星/火花飛散
// 初始化參數
spark_count = 8;
spark_data = array_create(spark_count);
for (var i = 0; i < spark_count; ++i) {
    var angle = irandom_range(0, 359);
    var spd = random_range(2, 4);
    spark_data[i] = {
        x: 0,
        y: 0,
        angle: angle,
        spd: spd,
        scale: 1 + random_range(0, 0.5),
        alpha: 1,
        color: make_color_rgb(255, 230, 80) // 金黃色
    };
}
// 動畫參數
anim_time = 0;
anim_duration = 18; // 約0.3秒 