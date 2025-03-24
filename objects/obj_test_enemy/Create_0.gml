// 將父對象事件繼承
event_inherited();

// 初始化屬性
max_hp = 120;
hp = max_hp;
attack = 12;
defense = 3;
spd = 3;

// 設置新的動畫配置
animation_frames = {
    WALK_DOWN_RIGHT: [0, 4],   // 0-4是右下角移動
    WALK_UP_RIGHT: [5, 9],     // 5-9是右上角移動
    WALK_UP_LEFT: [10, 14],    // 10-14是左上角移動 
    WALK_DOWN_LEFT: [15, 19],  // 15-19是左下角移動
    WALK_DOWN: [20, 24],       // 20-24是正下方移動
    WALK_RIGHT: [25, 29],      // 25-29是右邊移動
    WALK_UP: [30, 34],         // 30-34是上面移動
    WALK_LEFT: [35, 39],       // 35-39是左邊移動
    IDLE: [0, 4],              // 臨時用右下角移動替代
    ATTACK: [0, 4],            // 臨時用右下角移動替代
    HURT: [0, 4],              // 臨時用右下角移動替代
    DIE: [0, 4]                // 臨時用右下角移動替代
}

// 設置動畫速度 (使用精確值避免小數點問題)
animation_speed = 0.8;
image_speed = animation_speed; // 確保image_speed也更新
idle_animation_speed = 0.3;

// 確保初始幀設置正確
image_index = animation_frames.IDLE[0];

// 設置技能
var fireball = {
    id: "fireball",
    name: "火球術",
    damage: attack * 1.2,
    range: 150,
    cooldown: 120
};

ds_list_add(skills, fireball);

// 設置AI模式
ai_mode = AI_MODE.AGGRESSIVE;

// 初始化函數（安裝完成時執行）
initialize = function() {
    // 呼叫父對象的初始化方法
    event_inherited();
    
    // 註釋掉調試輸出
    // show_debug_message("測試敵人初始化: " + string(id));
    
    // 初始化技能冷卻時間
    for (var i = 0; i < ds_list_size(skills); i++) {
        var skill = skills[| i];
        ds_map_add(skill_cooldowns, skill.id, 0);
    }
}

// 執行初始化
initialize();