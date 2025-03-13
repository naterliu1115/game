// 继承父类的创建事件
event_inherited();
// 设置队伍为敌方
team = 1;
// 敌方特有属性
is_capturable = true;    // 是否可被捕获
capture_rate = 0.3;      // 基础捕获率(0-1)
drop_items = [];         // 可掉落的物品
// 进入战斗模式
enter_battle_mode = function() {
    // 设置战斗状态属性，可被子类覆盖
    show_debug_message("敌人: " + string(id) + " 进入战斗模式");
}
// 覆盖初始化函数
initialize = function() {
    // 调用父类的初始化
    event_inherited();
    
    // 重新确保team值正确
    team = 1;
    
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
    
    show_debug_message("敌人初始化完成: " + string(id) + ", team=" + string(team));
}
// 重新调用初始化
initialize();