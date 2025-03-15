// obj_death_effect - Draw Event

// 設置混合模式
gpu_set_blendmode(bm_add);

// 繪製中心光環
draw_set_alpha(alpha);
draw_set_color(c_white);
var circle_radius = real(20 * current_scale);
draw_circle(x, y, circle_radius, false);

// 繪製粒子
for (var i = 0; i < ds_list_size(particles); i++) {
    var particle = particles[| i];
    draw_set_alpha(particle.alpha);
    var particle_radius = real(5 * particle.scale);
    draw_circle(particle.x, particle.y, particle_radius, false);
}

// 重置繪製設置
draw_set_alpha(1.0);
gpu_set_blendmode(bm_normal); 