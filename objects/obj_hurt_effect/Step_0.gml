/// @description 更新受傷效果

// 更新中心閃爍淡出效果
image_alpha -= fade_speed;

// 更新粒子
var all_particles_faded = true;
for (var i = ds_list_size(particles) - 1; i >= 0; i--) { // 反向遍歷以安全刪除
    var particle = particles[| i];
    
    // 更新位置
    particle.x += lengthdir_x(particle.speed, particle.direction);
    particle.y += lengthdir_y(particle.speed, particle.direction);
    
    // 更新透明度
    particle.alpha -= particle_fade_speed;
    
    // 檢查是否需要移除
    if (particle.alpha <= 0) {
        ds_list_delete(particles, i);
    } else {
        all_particles_faded = false; // 只要還有一個粒子沒消失，就不是全部消失
    }
}

// 檢查中心閃爍和所有粒子是否都已消失
if (image_alpha <= 0 && all_particles_faded) {
    instance_destroy(); // 全部消失後銷毀特效物件
}

// 可以添加其他效果，例如輕微縮放或旋轉
// image_angle += 5;
// image_xscale += 0.01;
// image_yscale += 0.01;

// 移除舊的移動或 Alarm 相關邏輯 (如果有的話) 