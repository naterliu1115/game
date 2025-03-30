// obj_hurt_effect - Draw_0.gml

// 使用在 Create 和 Step 事件中控制的 alpha 和 blend 屬性
draw_set_alpha(image_alpha);
draw_set_color(image_blend); // 應該是 Create 事件中設置的 c_red

// 設置混合模式為 Additive，產生更亮的閃爍效果
gpu_set_blendmode(bm_add);

// 繪製中心閃爍 (使用白色和當前 alpha)
draw_set_alpha(image_alpha);
draw_set_color(c_white); // 使用 Create 中設置的 image_blend (已改為 c_white)
var flash_radius = 12; // 中心閃爍半徑
draw_circle(x, y, flash_radius, false);

// 繪製粒子
for (var i = 0; i < ds_list_size(particles); i++) {
    var particle = particles[| i];
    draw_set_alpha(particle.alpha);
    draw_set_color(particle.color); // 使用粒子自身的顏色
    var particle_radius = 4 * particle.scale; // 粒子半徑，可調整
    draw_circle(particle.x, particle.y, particle_radius, false);
}

// 重置繪圖設置
draw_set_alpha(1.0);
gpu_set_blendmode(bm_normal);
