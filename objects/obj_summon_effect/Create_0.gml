// obj_summon_effect 的 Create_0.gml
// 特效參數
image_blend = c_aqua;    // 水藍色特效
image_alpha = 1.0;       // 初始不透明度
scale = 0.1;             // 初始大小（從小到大）
max_scale = 2.0;         // 最大尺寸
grow_speed = 0.15;       // 成長速度
fade_speed = 0.04;       // 淡出速度
rotation = 0;            // 旋轉角度
particles = [];          // 粒子數組

// 創建初始粒子
for (var i = 0; i < 15; i++) {
    var angle = random(360);
    var spd = random_range(1, 3);
    var life = random_range(30, 60);
    var size = random_range(3, 8);
    
    array_push(particles, {
        x: 0,
        y: 0,
        dir: angle,
        speed: spd,
        life: life,
        max_life: life,
        size: size
    });
}

// 階段控制
phase = 0;  // 0=擴張, 1=閃爍, 2=消失
phase_timer = 0;

// obj_summon_effect 的 Step_0.gml
// 更新特效
switch (phase) {
    case 0: // 擴張階段
        scale += grow_speed;
        if (scale >= max_scale) {
            scale = max_scale;
            phase = 1;
            phase_timer = 20; // 閃爍持續20幀
        }
        break;
        
    case 1: // 閃爍階段
        // 閃爍效果
        image_alpha = 0.5 + sin(current_time / 50) * 0.5;
        
        phase_timer--;
        if (phase_timer <= 0) {
            phase = 2; // 進入消失階段
        }
        break;
        
    case 2: // 消失階段
        scale -= 0.05;
        image_alpha -= fade_speed;
        
        if (image_alpha <= 0 || scale <= 0) {
            instance_destroy();
        }
        break;
}

// 更新旋轉
rotation += 2;

// 更新粒子
for (var i = 0; i < array_length(particles); i++) {
    var p = particles[i];
    
    // 移動粒子
    p.x += lengthdir_x(p.speed, p.dir);
    p.y += lengthdir_y(p.speed, p.dir);
    
    // 減少生命值
    p.life--;
    
    if (p.life <= 0) {
        // 重置消失的粒子
        if (phase < 2) {
            p.x = 0;
            p.y = 0;
            p.dir = random(360);
            p.speed = random_range(1, 3);
            p.life = random_range(30, 60);
            p.max_life = p.life;
        } else {
            // 消失階段不再生成新粒子
            array_delete(particles, i, 1);
            i--;
        }
    }
}

// obj_summon_effect 的 Draw_0.gml
// 繪製主要光圈
draw_set_color(image_blend);
draw_set_alpha(image_alpha);

// 內圈
var inner_radius = 20 * scale;
draw_circle(x, y, inner_radius, false);

// 外圈（半透明）
draw_set_alpha(image_alpha * 0.5);
var outer_radius = 30 * scale;
draw_circle(x, y, outer_radius, false);

// 旋轉光線
draw_set_alpha(image_alpha * 0.7);
for (var i = 0; i < 8; i++) {
    var ray_angle = rotation + i * 45;
    var ray_x1 = x + lengthdir_x(inner_radius * 0.8, ray_angle);
    var ray_y1 = y + lengthdir_y(inner_radius * 0.8, ray_angle);
    var ray_x2 = x + lengthdir_x(outer_radius * 1.5, ray_angle);
    var ray_y2 = y + lengthdir_y(outer_radius * 1.5, ray_angle);
    
    draw_line_width(ray_x1, ray_y1, ray_x2, ray_y2, 2);
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