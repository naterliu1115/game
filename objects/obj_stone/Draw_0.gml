/// @description 繪製礦石和進度條

// 應用震動效果
var draw_x = x;
var draw_y = y;
if (shake_amount > 0) {
    draw_x += random_range(-shake_amount, shake_amount);
    draw_y += random_range(-shake_amount, shake_amount);
    shake_amount *= 0.9; // 逐漸減少震動
}

// --- 判斷是否顯示外框提示 ---
var show_outline = false;
if (instance_exists(Player)) {
    var dist = point_distance(x, y, Player.x, Player.y);
    
    // 基礎條件：在範圍內、未挖掘、未破壞
    if (dist <= interaction_radius && !is_being_mined && !is_destroyed) {
        
        // 額外條件：滑鼠懸停 或 角色面向
        var is_mouse_over = position_meeting(mouse_x, mouse_y, id);
        var is_facing_stone = false;
        var angle_to_stone = point_direction(Player.x, Player.y, x, y);
        var facing_angle = Player.facing_direction;
        var angle_diff = angle_difference(facing_angle, angle_to_stone);
        if (abs(angle_diff) <= 45) { 
            is_facing_stone = true;
        }
        
        // 必須滿足額外條件之一
        if (is_mouse_over || is_facing_stone) {
            show_outline = true;
        }
    }
}

// --- 繪製外框 (如果需要) ---
if (show_outline) {
    // --- Set Additive Blending for Outline ---
    gpu_set_blendmode(bm_add);
    
    var outline_alpha = 1; // Force outline to be opaque for brighter effect
    var outline_color = c_white;
    var outline_offset = 2;
    var offsets = [
        [-outline_offset, -outline_offset], [0, -outline_offset], [outline_offset, -outline_offset],
        [-outline_offset, 0],                                     [outline_offset, 0],
        [-outline_offset, outline_offset], [0, outline_offset], [outline_offset, outline_offset]
    ];

    // 繪製8個方向的偏移白色精靈作為外框
    for (var i = 0; i < array_length(offsets); i++) {
        var ox = offsets[i][0];
        var oy = offsets[i][1];

        draw_sprite_ext(
            sprite_index, image_index,
            draw_x + ox, draw_y + oy, // 偏移位置
            image_xscale, image_yscale, image_angle,
            outline_color, // 使用白色
            outline_alpha  // 強制為1，配合 bm_add
        );
    }
    
    // --- Reset Blending Mode ---
    gpu_set_blendmode(bm_normal);
}

// --- 繪製主要礦石精靈 ---
draw_sprite_ext(
    sprite_index, 
    image_index, 
    draw_x, 
    draw_y, 
    image_xscale, 
    image_yscale, 
    image_angle,    // 可以設置為0如果不需要旋轉
    image_blend,    // 使用物件的混合色
    image_alpha     // 使用物件的alpha值
);

// --- 繪製進度條 (如果需要) ---
if (is_being_mined || mining_progress > 0) {
    var bar_width = 40;
    var bar_height = 6;
    var bar_x = x - bar_width/2;
    var bar_y = y - sprite_height/2 - 10;
    
    // 繪製背景
    draw_set_color(c_gray);
    draw_rectangle(bar_x, bar_y, bar_x + bar_width, bar_y + bar_height, false);
    
    // 繪製進度
    draw_set_color(c_yellow);
    draw_rectangle(bar_x, bar_y, bar_x + bar_width * (1 - durability/max_durability), bar_y + bar_height, false);
    
    // 重置顏色
    draw_set_color(c_white);
} 