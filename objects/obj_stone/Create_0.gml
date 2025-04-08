/// @description 初始化礦石物件

// 設置精靈和深度
sprite_index = spr_ore;
// depth = 0;  // <-- 註解掉這一行，讓物件繼承圖層深度
image_speed = 0;        // 停止自動播放動畫
image_index = 0;        // 設置為第一幀
image_alpha = 1;        // 確保初始透明度為1

// 基本屬性
ore_item_id = 4001;      // 產出的礦石ID (銅礦石)
durability = 3;          // 需要挖掘的次數
max_durability = 3;      // 最大耐久度 (用於顯示進度)

// 互動範圍
interaction_radius = 50;  // 玩家需要在多近才能互動

// 狀態
is_being_mined = false;  // 是否正在被挖掘
mining_progress = 0;     // 挖掘進度 (0-1之間)
is_destroyed = false;    // 是否已經被破壞
destroy_timer = 0;       // 銷毀計時器
destroy_delay = 120;     // 銷毀延遲（120幀 = 2秒）
fade_start_delay = 45;   // 開始淡出前的延遲（0.75秒）
fade_duration = 75;      // 淡出持續時間（1.25秒）

// 視覺效果
shake_amount = 0;        // 震動效果的強度
original_x = x;          // 原始X位置
original_y = y;          // 原始Y位置
scale_multiplier = 1;    // 縮放倍數

// 粒子效果系統
particle_system = part_system_create();
part_system_depth(particle_system, -9700);  // 確保粒子在石頭上方

// 粒子計時器
particle_timer = 0;
particle_interval = 3;   // 每3步產生一次粒子

// 創建粒子類型
particle = part_type_create();
part_type_sprite(particle, spr_mining_particle, true, true, true);  // 啟用動畫和隨機幀
part_type_size(particle, 0.8, 1.2, -0.02, 0);      // 增加整體大小
part_type_scale(particle, 1, 1);
part_type_speed(particle, 3, 6, -0.15, 0);         // 增加初始速度，加快減速
part_type_direction(particle, 0, 360, 0, 10);      // 增加旋轉變化
part_type_orientation(particle, 0, 360, 6, 0, 1);  // 增加旋轉速度
part_type_life(particle, 30, 40);                  // 增加生命週期
part_type_alpha3(particle, 1, 0.9, 0);             // 提高整體不透明度
part_type_gravity(particle, 0.3, 270);             // 增加重力效果

/// @description 清理函數
cleanup = function() {
    if (part_system_exists(particle_system)) {
        part_system_destroy(particle_system);
    }
    if (part_type_exists(particle)) {
        part_type_destroy(particle);
    }
} 