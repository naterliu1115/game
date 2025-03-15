// obj_death_effect - Create Event

// 特效參數
fade_speed = 0.05;        // 淡出速度
scale_speed = 0.1;        // 縮放速度
rotation_speed = 5.0;     // 旋轉速度
initial_scale = 1.0;      // 初始縮放
max_scale = 1.5;         // 最大縮放
alpha = 1.0;             // 透明度
current_scale = initial_scale;

// 粒子效果參數
particle_count = 8;      // 粒子數量
particle_speed = 2.0;    // 粒子速度
particles = ds_list_create();

// 創建粒子
for (var i = 0; i < particle_count; i++) {
    var angle = (360.0 / particle_count) * i;
    var particle = {
        x: x,
        y: y,
        speed: particle_speed,
        direction: angle,
        alpha: 1.0,
        scale: initial_scale
    };
    ds_list_add(particles, particle);
}

// 設置深度
depth = -1000; // 確保特效顯示在其他物件上方 