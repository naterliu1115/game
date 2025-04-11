// 继承父类的创建事件
event_inherited();

// 敌方特有属性
is_capturable = true;    // 是否可被捕获
capture_rate = 0.3;      // 基础捕获率(0-1)
drop_items = [];         // 可掉落的物品

// 模板相關屬性
template_id = -1;        // 對應的敵人模板ID
name = "未命名敵人";     // 顯示名稱
family = "";             // 種族系列
variant = "";            // 變種類型
level = 1;               // 敵人等級
exp_reward = 5;          // 經驗值獎勵
gold_reward = 2;         // 金幣獎勵

// 覆盖初始化函数
initialize = function() {
    show_debug_message("===== obj_enemy_parent 初始化開始 =====");
    show_debug_message("初始化前 team = " + string(team));
    
    // 调用父类的初始化
    event_inherited();
    
    show_debug_message("父類初始化後 team = " + string(team));
    
    // 设置队伍为敌方（确保在所有初始化之后）
    team = 1;
    
    show_debug_message("設置敵方team後 = " + string(team));
    
    show_debug_message("敵人屬性設置完成：");
    show_debug_message("- team = " + string(team));
    show_debug_message("- 可捕獲 = " + string(is_capturable));
    show_debug_message("- 捕獲率 = " + string(capture_rate));
    show_debug_message("- 模板ID = " + string(template_id));
    show_debug_message("- 名稱 = " + string(name));
    show_debug_message("- 等級 = " + string(level));
    show_debug_message("===== obj_enemy_parent 初始化完成 =====");
}

// 进入战斗模式
enter_battle_mode = function() {
    // 再次确认team值
    team = 1;
    show_debug_message("敌人: " + string(id) + " 进入战斗模式，确认team值为: " + string(team));
}

// 调用初始化