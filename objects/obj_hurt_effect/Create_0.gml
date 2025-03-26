/// @description 初始化受傷效果

// 設置基本屬性
image_speed = 0.5;
image_alpha = 0.8;
image_blend = c_red;

// 設置移動參數
direction = random(360);
speed = random_range(1, 3);

// 設置淡出和縮放效果
fade_speed = random_range(0.02, 0.05);
grow_speed = random_range(0.01, 0.03);

// 設置壽命計時器
alarm[0] = random_range(15, 30); 