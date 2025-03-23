// 继承父类的创建事件
event_inherited();

// 覆盖初始化函数
initialize = function() {
    // show_debug_message("===== obj_test_summon 初始化開始 =====");
    // show_debug_message("初始化前 team = " + string(team));
    
    // 调用父类的初始化（这会设置team=0）
    event_inherited();
    
    // show_debug_message("父類初始化後 team = " + string(team));
    
    // 设置测试召唤物的特定属性
    max_hp = 60;
    hp = max_hp;
    attack = 10;
    defense = 4;
    spd = 6;
    
    // 确保AI模式设置正确
    ai_mode = AI_MODE.AGGRESSIVE;
    
    // 确保ATB系统正确初始化
    atb_current = 0;
    atb_ready = false;
    atb_rate = 1 + (spd * 0.1);
    
    // 添加特殊技能
    var special_attack = {
        id: "water_blast",
        name: "水弹",
        damage: attack * 1.2,
        range: 80,
        cooldown: 60
    };
    
    ds_list_add(skills, special_attack);
    ds_map_add(skill_cooldowns, "water_blast", 0);
    
    // show_debug_message("測試召喚物屬性設置完成：");
    // show_debug_message("- team = " + string(team));
    // show_debug_message("- AI模式 = " + string(ai_mode));
    // show_debug_message("- HP = " + string(hp) + "/" + string(max_hp));
    // show_debug_message("- 攻擊力 = " + string(attack));
    // show_debug_message("- 防禦力 = " + string(defense));
    // show_debug_message("- 速度 = " + string(spd));
    // show_debug_message("===== obj_test_summon 初始化完成 =====");
}

// 重新调用初始化
initialize();