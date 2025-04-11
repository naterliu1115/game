// 將父對象事件繼承
event_inherited();

// 設置模板ID (默認使用測試怪物)
template_id = 4001;

// 戰鬥冷卻時間（防止頻繁觸發戰鬥）
battle_cooldown = 0;
battle_cooldown_max = room_speed * 3; // 3秒冷卻

// 初始化函數（根據 template_id 從工廠讀取數據）
initialize = function() {
    // 呼叫父對象的初始化方法
    event_inherited();
    
    show_debug_message("obj_test_enemy 初始化開始，模板 ID: " + string(template_id));
    
    // 嘗試從工廠獲取模板數據
    var _template = undefined;
    if (instance_exists(obj_enemy_factory)) {
        _template = obj_enemy_factory.get_enemy_template(template_id);
    } else {
        show_debug_message("錯誤：obj_enemy_factory 不存在，無法獲取模板數據");
    }
    
    if (_template == undefined) {
        show_debug_message("錯誤：無法獲取 ID 為 " + string(template_id) + " 的模板，使用預設值");
        // 設置基本的預設值或錯誤狀態
        name = "錯誤敵人";
        max_hp = 1;
        hp = 1;
        attack = 1;
        defense = 1;
        spd = 1;
        team = 1;
        // 清空技能或其他可能存在的數據
        if (ds_exists(skills, ds_type_list)) ds_list_clear(skills);
        if (ds_exists(skill_cooldowns, ds_type_map)) ds_map_clear(skill_cooldowns);
        return; // 結束初始化
    }
    
    // --- 使用模板數據設置屬性 (邏輯來自 obj_enemy_factory) ---
    name = _template.name;
    
    // 設置等級 (使用模板的基礎等級)
    var _actual_level = _template.level;
    level = _actual_level;
    
    // 計算屬性
    max_hp = ceil(_template.hp_base + (_template.hp_base * _template.hp_growth * (_actual_level - 1)));
    hp = max_hp;
    attack = ceil(_template.attack_base + (_template.attack_base * _template.attack_growth * (_actual_level - 1)));
    defense = ceil(_template.defense_base + (_template.defense_base * _template.defense_growth * (_actual_level - 1)));
    spd = ceil(_template.speed_base + (_template.speed_base * _template.speed_growth * (_actual_level - 1)));
    
    // 設置捕獲相關
    is_capturable = _template.capturable;
    capture_rate = _template.capture_rate_base;
    
    // 視覺相關
    if (_template.sprite_idle != -1) sprite_index = _template.sprite_idle;
    // 確保初始幀設置正確 (如果 animation_frames 存在)
    if (variable_struct_exists(self, "animation_frames") && variable_struct_exists(animation_frames, "IDLE")) {
        image_index = animation_frames.IDLE[0];
    }
    
    // 設置團隊
    team = 1; // 確保是敵方
    
    // 記錄敵人類別信息
    enemy_category = _template.category;
    enemy_rank = _template.rank;
    
    // 技能設置
    if (ds_exists(skills, ds_type_list)) {
        ds_list_clear(skills); // 清空父類可能添加的基礎技能
        // skill_ids 列表似乎不再需要，因為 skills 列表本身存儲完整數據
        // if (ds_exists(skill_ids, ds_type_list)) {
        //     ds_list_clear(skill_ids);
        // }
        if (ds_exists(skill_cooldowns, ds_type_map)) {
            ds_map_clear(skill_cooldowns); // 清空舊的冷卻數據
        } else {
            skill_cooldowns = ds_map_create(); // 如果不存在則創建
        }
        
        if (instance_exists(obj_skill_manager) && array_length(_template.skills) > 0) {
            show_debug_message("    開始從模板加載技能...");
            for (var i = 0; i < array_length(_template.skills); i++) {
                var skill_id_to_add = _template.skills[i];
                var add_this_skill = false;
                
                // 檢查等級解鎖條件
                if (i < array_length(_template.skill_unlock_levels)) {
                    if (_actual_level >= _template.skill_unlock_levels[i]) {
                        add_this_skill = true;
                    }
                } else {
                    add_this_skill = true; // 如果沒有對應的解鎖等級，默認添加
                }
                
                if (add_this_skill) {
                    // --- 修改後的技能加載邏輯 ---
                    show_debug_message("      嘗試加載技能 ID: " + string(skill_id_to_add));
                    // 調用 Skill Manager 獲取完整技能數據副本
                    var full_skill_data = obj_skill_manager.copy_skill(skill_id_to_add, self);
                    
                    if (full_skill_data != undefined) {
                        // 檢查是否已存在 (可選，以防模板重複)
                        if (!has_skill(skill_id_to_add)) {
                            // 將完整的技能數據添加到列表
                            ds_list_add(skills, full_skill_data);
                            // 將技能ID和初始冷卻添加到 map
                            ds_map_add(skill_cooldowns, skill_id_to_add, 0);
                            show_debug_message("        成功添加技能: " + string(skill_id_to_add));
                            // --- 新增：打印完整技能數據 --- 
                            show_debug_message("          完整技能數據: " + json_stringify(full_skill_data));
                            // --- 新增結束 ---
                        } else {
                             show_debug_message("        警告：技能 " + string(skill_id_to_add) + " 已存在，跳過重複添加。");
                        }
                    } else {
                        show_debug_message("        錯誤：無法從 Skill Manager 獲取 ID 為 " + string(skill_id_to_add) + " 的技能數據。");
                    }
                    // --- 修改結束 ---
                }
            }
        } else if (!instance_exists(obj_skill_manager)) {
            show_debug_message("    錯誤：obj_skill_manager 不存在，無法加載技能。");
        }
    }
    
    // 設置掉落物
    if (variable_struct_exists(_template, "loot_table")) {
        drop_items = array_create(array_length(_template.loot_table));
        array_copy(drop_items, 0, _template.loot_table, 0, array_length(_template.loot_table));
    }
    
    // 設置獎勵
    exp_reward = _template.exp_reward;
    gold_reward = _template.gold_reward;
    
    // AI設置
    ai_type = _template.ai_type; // 保留原始的 ai_type 數字

    // 根據 ai_type 設置 ai_mode
    switch(ai_type) {
        case 0: // 明確定義 CSV 中的 0 代表 Aggressive
            ai_mode = AI_MODE.AGGRESSIVE;
            break;
        // case 1:
            // ai_mode = AI_MODE.SOME_OTHER_MODE; // 未來可以為 1 定義其他模式 (例如 FOLLOW 或 BOSS_AI)
            // break;
        // case ...: // 未來可以添加更多 case
        default: // 對於 CSV 中其他未明確定義的 ai_type 值，暫時預設為 Aggressive
            show_debug_message("警告：ai_type 值 " + string(ai_type) + " 尚未明確定義對應的 AI_MODE，預設為 AGGRESSIVE");
            ai_mode = AI_MODE.AGGRESSIVE;
            break;
    }
    show_debug_message("設置 AI 模式為: " + string(ai_mode) + " (基於 ai_type: " + string(ai_type) + ")");
    
    // 冷卻時間初始化
    battle_cooldown = 0;
    
    // --- 增加除錯訊息：打印載入的屬性 --- 
    show_debug_message("--- [" + name + "] 模板數據載入完成 ---");
    show_debug_message("    Level: " + string(level) + " (來自模板)");
    show_debug_message("    HP: " + string(hp) + " / " + string(max_hp));
    show_debug_message("    Attack: " + string(attack));
    show_debug_message("    Defense: " + string(defense));
    show_debug_message("    Speed: " + string(spd));
    show_debug_message("    Capturable: " + string(is_capturable) + " (Rate: " + string(capture_rate) + ")");
    show_debug_message("    Sprite: " + sprite_get_name(sprite_index));
    show_debug_message("    Rank: " + string(enemy_rank) + ", Category: " + string(enemy_category));
    show_debug_message("    AI Mode: " + string(ai_mode) + " (From Type: " + string(ai_type) + ")");
    
    // --- 增加除錯訊息：打印添加的技能 --- 
    if (ds_exists(skills, ds_type_list) && ds_list_size(skills) > 0) {
        show_debug_message("    添加的技能列表:");
        for (var j = 0; j < ds_list_size(skills); j++) {
            var _skill_data = skills[| j];
            if (is_struct(_skill_data)) { // 確保是結構
                 // --- 修改：打印完整技能數據而非僅 ID ---
                 show_debug_message("      - 數據: " + json_stringify(_skill_data));
                 // --- 修改結束 ---
            } else {
                show_debug_message("      - 無效的技能數據格式");
            }
        }
    } else {
        show_debug_message("    未添加任何技能。");
    }
    show_debug_message("--- [" + name + "] 初始化結束 ---");
    
    show_debug_message("obj_test_enemy 初始化完成，使用模板: " + name);
}