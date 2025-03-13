// 继承父类的创建事件
event_inherited();

// 设置测试召唤物的特定属性
max_hp = 60;
hp = max_hp;
attack = 10;
defense = 4;
spd = 6;

// 覆盖初始化函数
initialize = function() {
    // 调用父类的初始化
    event_inherited();
    

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
    
    show_debug_message("测试召唤物初始化完成");
}

// 重新调用初始化
initialize();