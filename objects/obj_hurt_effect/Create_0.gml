/// @description 初始化受傷效果

// 特效參數
fade_speed = 0.15;      // 中心閃爍淡出速度 (快一點)
initial_alpha = 1.0;    // 初始透明度
image_alpha = initial_alpha;
image_blend = c_white; // 中心閃爍用白色 (配合 bm_add)
image_speed = 0;       // 不使用內建動畫
image_xscale = 1.0;
image_yscale = 1.0;

// 粒子效果參數
particle_count = 6;      // 粒子數量 (比死亡少)
particle_speed = 2.5;    // 粒子速度
particle_fade_speed = 0.1; // 粒子淡出速度
particle_colors = [c_red, c_orange, make_color_rgb(255, 100, 0)]; // 粒子顏色選項
particles = ds_list_create();

// 創建粒子
for (var i = 0; i < particle_count; i++) {
    var angle = random(360); // 隨機方向
    var chosen_color = particle_colors[irandom(array_length(particle_colors) - 1)];
    var particle = {
        x: x, // 從中心開始
        y: y,
        speed: particle_speed * random_range(0.8, 1.2), // 速度略有變化
        direction: angle,
        alpha: initial_alpha,
        scale: random_range(0.8, 1.2),
        color: chosen_color
    };
    ds_list_add(particles, particle);
}

// 設置深度 (可以保留或調整，確保在單位之上)
depth = -500; // 確保在單位和UI之上，但可能在死亡特效之下

// 設置移動參數
direction = random(360);
speed = random_range(1, 3);

// 設置淡出和縮放效果
grow_speed = random_range(0.01, 0.03);

// 移除舊的 Alarm 設置 (如果有的話)
// alarm[0] = 15; // 不再需要基於固定時間的 Alarm 