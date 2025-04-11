/// @description 初始化測試目標

// 基本屬性
name = "測試目標";
defense = 0;  // 將由測試控制器設置
max_hp = 1000;
hp = max_hp;

// 記錄最後受到的傷害
last_damage_taken = 0;

// 接收傷害的函數
take_damage = function(damage, attacker_id, skill_id) {
    last_damage_taken = damage;
    hp = max(0, hp - damage);
} 