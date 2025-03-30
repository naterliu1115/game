// obj_floating_text - Step Event

// 向上移動
y -= float_speed;

// 淡出
image_alpha -= fade_speed;

// 檢查是否完全淡出
if (image_alpha <= 0) {
    instance_destroy(); // 淡出後銷毀
}