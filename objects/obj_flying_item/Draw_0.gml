/// @description 繪製飛行道具及外框

// --- 繪製外框 (bm_add 方式，在 draw_self 之前，固定 Alpha) ---
// >>> 新增檢查：確保 sprite_index 有效 <<<
if (sprite_exists(sprite_index)) {
    gpu_set_blendmode(bm_add);
    var outline_alpha = 1; // 使用固定的 Alpha = 1
    var outline_color = c_white;
    var outline_offset = 2; // 使用 Create 事件中定義的實例變數
    var offsets = [
        [-outline_offset, -outline_offset], [0, -outline_offset], [outline_offset, -outline_offset],
        [-outline_offset, 0],                                     [outline_offset, 0],
        [-outline_offset, outline_offset], [0, outline_offset], [outline_offset, outline_offset]
    ];
    for (var i = 0; i < array_length(offsets); i++) {
        draw_sprite_ext(
            sprite_index, image_index,
            x + offsets[i][0], y + offsets[i][1],
            image_xscale, image_yscale, image_angle,
            outline_color, // 使用白色
            outline_alpha  // 使用固定的 Alpha = 1
        );
    }
    gpu_set_blendmode(bm_normal); // 重設混合模式
}
// >>> 結束檢查 <<<
// --- 外框繪製結束 ---


// --- 繪製主要精靈 ---
// >>> 同樣加上檢查 <<<
if (sprite_exists(sprite_index)) {
    // draw_self() 會使用物件的 image_alpha
    draw_self();
}

// 繪製數量（如果大於1）
// (保留這一段程式碼)
if (quantity > 1) {
    // 設置字體和顏色
    draw_set_font(fnt_dialogue);
    draw_set_color(c_white);
    
    // 計算文字位置（在物品右下角）
    // 確保 sprite_width/height 在 sprite 有效時才讀取
    if (sprite_exists(sprite_index)) {
        var text_x = x + sprite_get_width(sprite_index)/2 - 4;
        var text_y = y + sprite_get_height(sprite_index)/2 - 4;
        // 繪製數量文字
        draw_text(text_x, text_y, string(quantity));
    }
    
    // 重置繪製設置
    draw_set_color(c_white);
}