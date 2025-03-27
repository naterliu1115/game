// 继承父类的创建事件
event_inherited();

// 覆盖初始化函数
initialize = function() {
    // 調用父類的初始化（這會設置 team=0 和基本攻擊）
    // 注意：這裡調用父類的initialize，而不是event_inherited()
    // event_inherited() 是在物件創建時調用，而initialize是手動調用
    
    // 先檢查是否已初始化
    var already_initialized = false;
    if (ds_list_size(skill_ids) > 0) {
        already_initialized = true;
        show_debug_message("obj_test_summon 已初始化，跳過父類初始化");
    } else {
        // 繼承自父類別的初始化
        script_execute(battle_unit_parent_initialize);
    }
    
    // 設置測試召喚物的特定屬性
    max_hp = 60;
    hp = max_hp;
    attack = 10;
    defense = 4;
    spd = 6;
    
    // 確保ATB系統正確初始化
    atb_current = 0;
    atb_ready = false;
    atb_rate = 1 + (spd * 0.1);
    
    // 添加特殊技能（使用新的技能系統）
    // 但只有當技能列表為空或不包含此技能時才添加
    if (!already_initialized) {
        add_skill("water_blast");
    }
}

// 保存父類的初始化方法引用，避免重複調用event_inherited()
battle_unit_parent_initialize = obj_battle_unit_parent.initialize;

// 在創建時調用一次初始化
initialize();