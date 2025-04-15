/// @description 繪製飛行道具及其效果

// --- 計算繪製座標和縮放 ---
var draw_y = y - z; // 根據 Z 高度調整繪製 Y 座標
var draw_scale = image_xscale; // 預設使用物件本身的縮放

// --- 處理 WAIT_ON_GROUND 狀態的浮動效果 ---
if (flight_state == FLYING_STATE.WAIT_ON_GROUND) {
    // 計算浮動效果
    float_timer += 1; // 在 Draw 事件中增加計時器，更平滑
    var float_offset = sin(float_timer * float_frequency) * float_amplitude;
    draw_y += float_offset; // 在 Z 調整後的基礎上增加浮動
    
    // (可選) 地面等待時稍微放大?
    // draw_scale *= 1.1; 
}

// --- (可選) 根據 Z 高度調整視覺縮放 --- 
/*
if (z > 0) { // 只在空中時縮放
    var scale_factor = 1 - (z / 100); // 假設 100 像素高度時縮放到最小 (可調整)
    draw_scale = max(0.4, image_xscale * scale_factor); // 限制最小縮放
}
*/

// --- 繪製外框 (恢復使用 bm_add 模擬原始效果) ---
gpu_set_blendmode(bm_add); // <--- 設定混合模式
var outline_draw_y = draw_y; // 外框也需要用調整後的 Y
// 需要從 Create 事件讀取 outline_offset 和 outline_color
// 假設 outline_offset 和 outline_color 在 Create 事件中已定義
for (var xx = -outline_offset; xx <= outline_offset; xx += outline_offset) {
    for (var yy = -outline_offset; yy <= outline_offset; yy += outline_offset) {
        if (xx != 0 || yy != 0) {
            draw_sprite_ext(sprite_index, image_index, x + xx, outline_draw_y + yy, 
                            draw_scale, draw_scale, image_angle, outline_color, 1); // <--- Alpha 改回 1
        }
    }
}
gpu_set_blendmode(bm_normal); // <--- 重設混合模式

// --- 繪製主 Sprite ---
draw_sprite_ext(sprite_index, 
                image_index, 
                x, 
                draw_y,          // 使用計算後的 Y
                draw_scale,      // 使用計算後的縮放
                draw_scale,      // 使用計算後的縮放
                image_angle, 
                image_blend, 
                image_alpha);

// --- (可選) 繪製除錯信息 ---
/*
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_text(x + 10, draw_y - 20, "State: " + string(flight_state));
draw_text(x + 10, draw_y - 10, "Z: " + string(round(z)) + " ZSpd: " + string(round(zspeed*10)/10));
draw_text(x + 10, draw_y     , "Y: " + string(round(y)) + " DrY: " + string(round(draw_y)));
*/

// 繪製數量（如果大於1）
// (保留這一段程式碼)
if (quantity > 1) {
    // 計算文字位置（在物品右下角，使用 draw_y）
    if (sprite_exists(sprite_index)) {
        var text_x = x + sprite_get_width(sprite_index)/2 - 4;
        var text_y = draw_y + sprite_get_height(sprite_index)/2 - 4; // <--- 使用 draw_y

        // 定義數量文字的縮放比例 (可調整)
        var quantity_scale = 0.5; // <--- 在這裡調整大小 (例如 0.7 = 70%)

        // 繪製經過縮放的數量文字
        draw_text_transformed(text_x, text_y, string(quantity), quantity_scale, quantity_scale, 0); // <--- 使用 transformed
    }
    
    // 重置繪製設置
    draw_set_color(c_white);
}