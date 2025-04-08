/// @description 繪製飛行道具及外框

// --- 繪製外框 ---
// 使用 Additive Blending
gpu_set_blendmode(bm_add);

var outline_alpha = 1; // 外框始終不透明
var offsets = [
    [-outline_offset, -outline_offset], [0, -outline_offset], [outline_offset, -outline_offset],
    [-outline_offset, 0],                                     [outline_offset, 0],
    [-outline_offset, outline_offset], [0, outline_offset], [outline_offset, outline_offset]
];

for (var i = 0; i < array_length(offsets); i++) {
    var ox = offsets[i][0];
    var oy = offsets[i][1];
    draw_sprite_ext(
        sprite_index, image_index,
        x + ox, y + oy, // 偏移位置
        image_xscale, image_yscale, image_angle,
        outline_color, // 使用 Create 事件中定義的 outline_color
        outline_alpha
    );
}

// --- 重設 Blending Mode ---
gpu_set_blendmode(bm_normal);

// --- 繪製主要精靈 ---
draw_self(); // 使用物件自身的屬性繪製精靈