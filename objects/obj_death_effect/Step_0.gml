// obj_death_effect - Step Event

// 更新縮放
current_scale = lerp(current_scale, max_scale, scale_speed);

// 更新透明度
alpha = max(0.0, alpha - fade_speed);

// 更新粒子
for (var i = 0; i < ds_list_size(particles); i++) {
    var particle = particles[| i];
    
    // 更新位置
    particle.x += lengthdir_x(particle.speed, particle.direction);
    particle.y += lengthdir_y(particle.speed, particle.direction);
    
    // 更新透明度和縮放
    particle.alpha = alpha;
    particle.scale = current_scale;
    
    // 更新粒子結構體
    particles[| i] = particle;
}

// 如果完全透明則銷毀
if (alpha <= 0.0) {
    // 清理資源
    ds_list_destroy(particles);
    instance_destroy();
} 