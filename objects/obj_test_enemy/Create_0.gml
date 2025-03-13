// 继承父类的创建事件
event_inherited();

// 设置测试敌人的特定属性
max_hp = 50;
hp = max_hp;
attack = 8;
defense = 3;
spd = 4;

// 测试敌人的捕获率
capture_rate = 0.4;

// 覆盖初始化函数
initialize = function() {
    // 调用父类的初始化
    event_inherited();
    
    // 添加基础攻击技能
    var basic_attack = {
        id: "basic_attack",
        name: "基础攻击",
        damage: attack,
        range: 50,
        cooldown: 30
    };
    
    ds_list_add(skills, basic_attack);
    ds_map_add(skill_cooldowns, "basic_attack", 0);
    
    // 添加特殊技能
    var special_attack = {
        id: "fireball",
        name: "火球",
        damage: attack * 1.5,
        range: 100,
        cooldown: 90
    };
    
    ds_list_add(skills, special_attack);
    ds_map_add(skill_cooldowns, "fireball", 0);
    
    show_debug_message("测试敌人初始化完成，技能数量: " + string(ds_list_size(skills)));
}

// 重新调用初始化
initialize();
show_debug_message("敌人team值确认为: " + string(team));