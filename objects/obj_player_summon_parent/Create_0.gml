// 继承父类的创建事件
event_inherited();

// 设置队伍为玩家方
team = 0;

// 玩家召唤物特有属性
return_after_battle = true;  // 战斗后是否返回玩家的"队伍"
stamina = 100;               // 特殊耐力值，可用于延长战场时间
preferred_distance = 100;    // 与目标的理想战斗距离

// 覆盖初始化函数
initialize = function() {
    // 调用父类的初始化
    event_inherited();
    
    // 添加基础技能
    var basic_attack = {
        id: "basic_attack",
        name: "基础攻击",
        damage: attack,
        range: 50,
        cooldown: 30
    };
    
    ds_list_add(skills, basic_attack);
    ds_map_add(skill_cooldowns, "basic_attack", 0);
    
    // 添加入场动画或效果的代码可以放这里
    
    show_debug_message("玩家召唤物初始化完成: " + string(id));
}

// 重新调用初始化
initialize();