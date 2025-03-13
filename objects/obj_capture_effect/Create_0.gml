// obj_capture_effect 的 Create_0.gml
// 特效參數
image_blend = c_yellow;   // 黃色特效
image_alpha = 1.0;        // 初始不透明度
scale = 0.1;              // 初始大小（從小到大）
max_scale = 2.5;          // 最大尺寸
particles = [];           // 粒子數組
phase = 0;                // 0=收縮, 1=爆炸, 2=消失
phase_timer = 0;          // 階段計時器
rotation = 0;             // 旋轉角度

// 爆裂效果的點
explosion_points = [];
for (var i = 0; i < 12; i++) {
    array_push(explosion_points, {
        angle: i * 30,
        dist: 0,
        max_dist: random_range(80, 140),
        speed: random_range(2, 4)
    });
}

// 創建初始粒子
for (var i = 0; i < 20; i++) {
    var angle = random(360);
    var dist = random_range(10, 30);
    var life = random_range(30, 60);
    var size = random_range(2, 6);
    
    array_push(particles, {
        x: lengthdir_x(dist, angle),
        y: lengthdir_y(dist, angle),
        dir: angle,
        speed: random_range(0.5, 2),
        life: life,
        max_life: life,
        size: size
    });
}

// obj_capture_effect 的 Step_0.gml
// 更新旋轉
rotation += 5;

// 根據階段更新特效
switch (phase) {
    case 0: // 收縮階段
        // 增大到最大尺寸
        scale += 0.15;
        if (scale >= max_scale) {
            scale = max_scale;
            phase_timer++;
            
            // 短暫停留在最大尺寸
            if (phase_timer >= 15) {
                phase = 1; // 進入爆炸階段
                phase_timer = 0;
                
                // 生成更多粒子
                for (var i = 0; i < 15; i++) {
                    var angle = random(360);
                    var dist = random_range(10, 30) * scale;
                    var life = random_range(30, 60);
                    var size = random_range(3, 8);
                    
                    array_push(particles, {
                        x: lengthdir_x(dist, angle),
                        y: lengthdir_y(dist, angle),
                        dir: angle,
                        speed: random_range(3, 7),
                        life: life,
                        max_life: life,
                        size: size
                    });
                }
            }
        }
        break;
        
    case 1: // 爆炸階段
        // 爆裂效果
        var all_max = true;
        for (var i = 0; i < array_length(explosion_points); i++) {
            var point = explosion_points[i];
            
            if (point.dist < point.max_dist) {
                point.dist += point.speed;
                all_max = false;
            }
        }
        
        // 縮小中心圓
        scale -= 0.1;
        if (scale <= 0) scale = 0;
        
        // 所有爆炸點達到最大距離
        if (all_max && scale <= 0) {
            phase = 2; // 進入消失階段
        }
        break;
        
    case 2: // 消失階段
        // 淡出所有粒子
        var all_gone = true;
        for (var i = 0; i < array_length(particles); i++) {
            var p = particles[i];
            p.life -= 2;
            
            if (p.life > 0) {
                all_gone = false;
            }
        }
        
        // 爆炸點消失
        for (var i = 0; i < array_length(explosion_points); i++) {
            var point = explosion_points[i];
            point.max_dist -= 2;
            
            if (point.max_dist < point.dist) {
                point.dist = point.max_dist;
            }
            
            if (point.max_dist > 0) {
                all_gone = false;
            }
        }
        
        // 全部消失後銷毀
        if (all_gone) {
            instance_destroy();
        }
        break;
}

// 更新粒子
for (var i = 0; i < array_length(particles); i++) {
    var p = particles[i];
    
    // 移動粒子
    p.x += lengthdir_x(p.speed, p.dir);
    p.y += lengthdir_y(p.speed, p.dir);
    
    // 減少生命值
    p.life--;
    
    if (p.life <= 0) {
        // 移除消失的粒子
        array_delete(particles, i, 1);
        i--;
    }
}

// obj_capture_effect 的 Draw_0.gml
// 繪製中心特效
draw_set_color(image_blend);
draw_set_alpha(image_alpha);

// 在收縮階段繪製脈動圓圈
if (phase == 0) {
    // 內圈
    var inner_radius = 20 * scale;
    draw_circle(x, y, inner_radius, false);
    
    // 外圈（半透明）
    draw_set_alpha(image_alpha * 0.6);
    var outer_radius = 30 * scale;
    draw_circle(x, y, outer_radius, false);
    
    // 閃爍效果
    draw_set_alpha(image_alpha * (0.5 + sin(current_time / 50) * 0.3));
    draw_circle(x, y, outer_radius * 1.2, true);
    
    // 旋轉星形
    draw_set_alpha(image_alpha * 0.8);
    for (var i = 0; i < 6; i++) {
        var ray_angle = rotation + i * 60;
        var ray_x1 = x + lengthdir_x(inner_radius, ray_angle);
        var ray_y1 = y + lengthdir_y(inner_radius, ray_angle);
        var ray_x2 = x + lengthdir_x(outer_radius * 1.8, ray_angle);
        var ray_y2 = y + lengthdir_y(outer_radius * 1.8, ray_angle);
        
        draw_line_width(ray_x1, ray_y1, ray_x2, ray_y2, 2);
    }
}

// 在爆炸階段繪製爆裂效果
if (phase >= 1) {
    // 中心圓（變小）
    if (scale > 0) {
        draw_set_alpha(image_alpha);
        draw_circle(x, y, 20 * scale, false);
    }
    
    // 爆炸射線
    draw_set_alpha(min(1, image_alpha * 0.9));
    for (var i = 0; i < array_length(explosion_points); i++) {
        var point = explosion_points[i];
        var point_x = x + lengthdir_x(point.dist, point.angle);
        var point_y = y + lengthdir_y(point.dist, point.angle);
        
        // 射線由粗到細
        var line_width = max(1, 4 * (1 - point.dist / point.max_dist));
        draw_line_width(x, y, point_x, point_y, line_width);
        
        // 射線端點小圓
        if (phase < 2 || point.max_dist > 20) {
            draw_circle(point_x, point_y, line_width * 2, false);
        }
    }
}

// 繪製粒子
for (var i = 0; i < array_length(particles); i++) {
    var p = particles[i];
    var p_alpha = (p.life / p.max_life) * image_alpha;
    var p_size = p.size * (0.5 + 0.5 * (p.life / p.max_life));
    
    draw_set_alpha(p_alpha);
    draw_circle(x + p.x, y + p.y, p_size, false);
}

// 重置繪圖設置
draw_set_alpha(1.0);
draw_set_color(c_white);

// 可選：添加光暈效果（如果遊戲支持）
// gpu_set_blendmode(bm_add);
// draw_sprite_ext(spr_glow, 0, x, y, scale, scale, 0, image_blend, image_alpha * 0.5);
// gpu_set_blendmode(bm_normal);