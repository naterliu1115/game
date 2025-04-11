// 敵人分類
enum ENEMY_CATEGORY {
    NORMAL,     // 普通敵人
    ELITE,      // 精英敵人
    BOSS        // 頭目敵人
}

// 敵人稀有度
enum ENEMY_RANK {
    COMMON,     // 普通
    UNCOMMON,   // 罕見
    RARE,       // 稀有
    EPIC,       // 史詩
    LEGENDARY   // 傳說
}

// 敵人AI行為類型
enum ENEMY_AI {
    AGGRESSIVE, // 積極攻擊
    DEFENSIVE,  // 防禦性
    PASSIVE,    // 被動
    SUPPORT     // 支援型
}

// 群組生成模式
enum SPAWN_PATTERN {
    RANDOM,     // 隨機生成
    CIRCLE,     // 圓形陣型
    GRID,       // 網格陣型
    TRIANGLE,   // 三角陣型
    V_FORMATION // V字陣型
} 