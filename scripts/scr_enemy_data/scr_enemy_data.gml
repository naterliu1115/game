/// @function create_enemy_base_data()
/// @description 創建敵人基礎數據結構
/// @returns {struct} 敵人數據結構
function create_enemy_base_data() {
    return {
        // 基本識別和分類信息
        template_id: -1,                  // 唯一模板ID (原為 id)
        name: "未命名敵人",                 // 顯示名稱
        category: ENEMY_CATEGORY.NORMAL,  // 敵人類別
        family: "",                       // 種族系列
        variant: "",                      // 變種類型
        rank: ENEMY_RANK.COMMON,          // 稀有度
        
        // 基礎屬性
        level: 1,                         // 敵人等級
        hp_base: 10,                      // 基礎生命值
        attack_base: 5,                   // 基礎攻擊力
        defense_base: 2,                  // 基礎防禦力
        speed_base: 3,                    // 基礎速度
        
        // 成長係數
        hp_growth: 0.1,                   // HP成長係數
        attack_growth: 0.05,              // 攻擊成長係數
        defense_growth: 0.03,             // 防禦成長係數
        speed_growth: 0.02,               // 速度成長係數
        
        // 視覺相關
        sprite_idle: -1,                  // 站立精靈
        sprite_move: -1,                  // 移動精靈
        sprite_attack: -1,                // 攻擊精靈
        
        // 群組生成相關
        is_pack_leader: false,            // 是否為群組首領
        pack_min: 1,                      // 最小生成數量
        pack_max: 1,                      // 最大生成數量
        pack_pattern: SPAWN_PATTERN.CIRCLE, // 生成模式
        companions: [],                   // 可能的同伴 [{id:敵人ID, weight:權重}]
        
        // 戰利品相關
        loot_table: [],                   // 掉落表 [{item_id:物品ID, chance:機率, quantity:[最小,最大]}]
        exp_reward: 5,                    // 經驗值獎勵
        gold_reward: 2,                   // 金幣獎勵
        
        // 戰鬥相關
        ai_type: ENEMY_AI.AGGRESSIVE,     // AI類型
        attack_range: 50,                 // 攻擊範圍
        aggro_range: 150,                 // 仇恨範圍
        attack_interval: 60,              // 攻擊間隔(幀)
        
        // 捕獲相關
        capturable: true,                 // 是否可捕獲
        capture_rate_base: 0.3,           // 基礎捕獲率
        
        // 技能相關
        skills: [],                       // 技能ID列表
        skill_unlock_levels: []           // 技能解鎖等級
    };
} 