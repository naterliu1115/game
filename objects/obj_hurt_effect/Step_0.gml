/// @description 更新受傷效果

// 淡出效果
image_alpha -= fade_speed;

// 縮放效果
image_xscale += grow_speed;
image_yscale += grow_speed;

// 如果透明度為0則銷毀
if (image_alpha <= 0) {
    instance_destroy();
} 