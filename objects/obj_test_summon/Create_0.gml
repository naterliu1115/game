// 繼承父類的創建事件
event_inherited();

can_wander = false; 
// 覆蓋初始化函數
initialize = function() {
    // 確保 active 變量存在並設置
    if (!variable_instance_exists(id, "active")) {
        active = false;
    }
    
    show_debug_message("[obj_test_summon initialize] 開始，模板 ID: " + string(template_id) + ", 等級: " + string(level));
    
    // 1. 移除對父類初始化的重複調用
    // event_inherited(); // <-- 移除或註解掉此行
    // show_debug_message("    [Summon Init] Parent (obj_battle_unit_parent) event_inherited() 完成");

    // 2. 嘗試從工廠獲取模板數據
    var _template = undefined;
    if (instance_exists(obj_enemy_factory)) {
        _template = obj_enemy_factory.get_enemy_template(template_id);
    } else {
        show_debug_message("    [Summon Init] 錯誤：obj_enemy_factory 不存在!");
    }
    
    if (_template == undefined) {
        show_debug_message("    [Summon Init] 錯誤：無法獲取 ID 為 " + string(template_id) + " 的模板，使用基礎預設值");
        // 設置基本的預設值或錯誤狀態 (確保team=0)
        name = "錯誤召喚物";
        max_hp = 1;
        hp = 1;
        attack = 1;
        defense = 1;
        spd = 1;
        team = 0; // 玩家隊伍
        // 清空父類可能初始化的技能列表
        skills = [];
        skill_ids = [];
        return; // 結束初始化
    }
    show_debug_message("    [Summon Init] 成功獲取模板: " + _template.name);
    
    // --- 3. 使用模板數據設置屬性 (基於自身的 level) ---
    name = _template.name;
    // level 已經由 obj_summon_ui 傳遞設置
    var _actual_level = level; 
    
    // 計算屬性 (與之前相同，但移除敵人專屬屬性)
    var _hp_base = variable_struct_exists(_template, "hp_base") ? _template.hp_base : 1;
    var _hp_growth = variable_struct_exists(_template, "hp_growth") ? _template.hp_growth : 0;
    var _attack_base = variable_struct_exists(_template, "attack_base") ? _template.attack_base : 1;
    var _attack_growth = variable_struct_exists(_template, "attack_growth") ? _template.attack_growth : 0;
    var _defense_base = variable_struct_exists(_template, "defense_base") ? _template.defense_base : 1;
    var _defense_growth = variable_struct_exists(_template, "defense_growth") ? _template.defense_growth : 0;
    var _speed_base = variable_struct_exists(_template, "speed_base") ? _template.speed_base : 1;
    var _speed_growth = variable_struct_exists(_template, "speed_growth") ? _template.speed_growth : 0;
    
    max_hp = ceil(_hp_base + (_hp_base * _hp_growth * (_actual_level - 1)));
    hp = max_hp;
    attack = ceil(_attack_base + (_attack_base * _attack_growth * (_actual_level - 1)));
    defense = ceil(_defense_base + (_defense_base * _defense_growth * (_actual_level - 1)));
    spd = ceil(_speed_base + (_speed_base * _speed_growth * (_actual_level - 1)));
    max_hp = max(1, max_hp);
    hp = max_hp;
    attack = max(1, attack);
    defense = max(1, defense);
    spd = max(1, spd);
        
    // 視覺相關
    if (variable_struct_exists(_template, "sprite_idle") && _template.sprite_idle != -1) {
        sprite_index = _template.sprite_idle;
    }
    if (variable_instance_exists(id, "animation_frames") && variable_struct_exists(animation_frames, "IDLE")) {
        image_index = animation_frames.IDLE[0];
    }
    
    // 設置團隊 (確保是玩家隊伍)
    team = 0;
    show_debug_message("    [Summon Init] 強制設置 team = " + string(team));
    
    // 技能設置 (使用父類的 add_skill)
    skills = [];
    skill_ids = [];
    
    if (variable_struct_exists(_template, "skills") && array_length(_template.skills) > 0) {
        var skill_levels = variable_struct_exists(_template, "skill_unlock_levels") ? _template.skill_unlock_levels : [];
        for (var i = 0; i < array_length(_template.skills); i++) {
            var skill_id = real(_template.skills[i]); // 強制轉為數字
            var unlock_level = (i < array_length(skill_levels)) ? skill_levels[i] : 1;
            
            if (_actual_level >= unlock_level) {
                if (variable_instance_exists(id, "add_skill")) {
                    add_skill(skill_id);
                } else {
                    show_debug_message("    [Summon Init] 警告: add_skill 方法不存在!");
                }
            }
        }
    } else {
        show_debug_message("    [Summon Init] 警告: skills 列表不存在!");
    }
    
    // 移除召喚物 AI 的設置，使其繼承父類的 AGGRESSIVE
    /*
    ai_mode = AI_MODE.FOLLOW; // 召喚物預設跟隨玩家
    if (instance_exists(Player)) {
        follow_target = Player;
    }
    */
    
    // 重新計算 ATB rate
    atb_rate = 1 + (spd * 0.1);
    atb_current = 0; // 重置 ATB
    atb_ready = false;
    
    show_debug_message("    [Summon Init] 初始化完成，使用模板: " + name + " (ID: " + string(template_id) + ")");
    show_debug_message("--- [Summon Init] 最終屬性 ---");
    show_debug_message("    Level: " + string(level));
    show_debug_message("    HP: " + string(hp) + " / " + string(max_hp));
    show_debug_message("    Attack: " + string(attack));
    show_debug_message("    Defense: " + string(defense));
    show_debug_message("    Speed: " + string(spd));
    show_debug_message("    Team: " + string(team));
    show_debug_message("    AI Mode: " + string(ai_mode));
    show_debug_message("--- [Summon Init] 結束 ---");
}

// 在創建時調用一次初始化
// initialize(); // <-- 移除或註解掉此行，初始化應由創建者在設置 template_id 後呼叫