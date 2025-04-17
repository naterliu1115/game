// obj_enemy_placer - Create_0.gml
show_debug_message("[DEBUG] obj_enemy_placer Create Event - 開始");
// 這是一個編輯器工具物件，用於在房間編輯器中放置敵人

// 設置基本屬性（可在房間編輯器中修改）
template_id = 4001;          // 默認敵人模板ID (可在房間編輯器中覆蓋)
template_name = "未知敵人";   // 初始名稱（將從模板更新）
sprite_index = Monster1;    // 默認精靈（將從模板更新）
image_alpha = 0.8;           // 半透明
draw_template_id = true;

// 當前模板索引
current_template_index = 0;

// 選擇下一個模板
select_next_template = function() {
    if (array_length(available_templates) == 0) return;
    current_template_index = (current_template_index + 1) % array_length(available_templates);
    update_template_info(available_templates[current_template_index]);
    show_debug_message("選擇敵人模板：" + template_name + " (ID: " + string(template_id) + ")");
}

// 選擇上一個模板
select_prev_template = function() {
    if (array_length(available_templates) == 0) return;
    current_template_index = (current_template_index - 1 + array_length(available_templates)) % array_length(available_templates);
    update_template_info(available_templates[current_template_index]);
    show_debug_message("選擇敵人模板：" + template_name + " (ID: " + string(template_id) + ")");
}

// 轉換為實際敵人的標誌
converted = false;

on_managers_initialized = function(data) {
    show_debug_message("[DEBUG] obj_enemy_placer (ID: " + string(id) + ") 收到 managers_initialized 事件");
    alarm[0] = 1; // 立即啟動 alarm[0] 進行資料查詢重試
}

update_template_info = function(id) {
    show_debug_message("[DEBUG] update_template_info() - 開始, Pos: x=" + string(x) + ", y=" + string(y));
    var template = get_template_by_id(id);
    if (!is_undefined(template)) {
        template_id = template.id;
        template_name = template.name;
        if (!is_undefined(template.sprite_idle)) {
            var spr = asset_get_index(template.sprite_idle);
            if (spr != -1) sprite_index = spr;
        }
    }
    show_debug_message("[DEBUG] update_template_info() - 結束, Pos: x=" + string(x) + ", y=" + string(y));
}

convert_to_real_enemy = function() {
    show_debug_message("[DEBUG] convert_to_real_enemy() - 開始執行 (ID: " + string(id) + ", Template: " + string(template_id) + ", Pos: " + string(x) + "," + string(y) + ")");
    if (converted) {
        show_debug_message("[DEBUG] convert_to_real_enemy() - 已轉換，提前退出");
        return;
    }
    if (is_undefined(global.enemy_templates)) {
        show_debug_message("[DEBUG] convert_to_real_enemy() - enemy_templates 尚未初始化，延遲重試...");
        alarm[0] = 5;
        return;
    }
    var template = get_template_by_id(template_id);
    if (is_undefined(template)) {
        show_debug_message("[ERROR] convert_to_real_enemy() - 找不到模板，無法產生敵人");
        alarm[0] = 5;
        return;
    }
    // 產生敵人 instance 時，欄位結構與 monster_data_manager 標準一致
    var enemy_inst = instance_create_layer(x, y, "Instances", obj_test_enemy);
    if (!instance_exists(enemy_inst)) {
        show_debug_message("[ERROR] convert_to_real_enemy() - instance_create_layer 失敗");
        alarm[0] = 5;
        return;
    }
    with (enemy_inst) {
        template_id = template.id;
        name = template.name;
        level = is_undefined(other.enemyLevel) ? template.level : other.enemyLevel;
        max_hp = template.hp_base + template.hp_growth * (level - 1);
        hp = max_hp;
        attack = template.attack_base + template.attack_growth * (level - 1);
        defense = template.defense_base + template.defense_growth * (level - 1);
        spd = template.spd_base + template.spd_growth * (level - 1);
        experience = 0;
        skills = [];
        
        // === 再次修正精靈處理 ===
        var _sprite_index_from_template = template.sprite_idle; // 直接獲取工廠存儲的索引
        // show_debug_message("    [Enemy Init] sprite_idle index from template: " + string(_sprite_index_from_template) + ", Type = " + typeof(_sprite_index_from_template));

        var _final_sprite_index = -1; // 預設為無效

        // 使用 is_numeric() 檢查是否為數字，並檢查是否 >= 0
        if (is_numeric(_sprite_index_from_template) && _sprite_index_from_template >= 0) { 
            _final_sprite_index = _sprite_index_from_template;
            // show_debug_message("    [Enemy Init] Using valid numeric sprite index from template: " + string(_final_sprite_index));
        } else {
            // show_debug_message("    [Enemy Init] Invalid or negative sprite index from template (" + string(_sprite_index_from_template) + "). Setting sprite_index to -1.");
        }

        // 直接設置精靈索引
        display_sprite = _final_sprite_index; 
        sprite_index = _final_sprite_index;   

        // show_debug_message("    [Enemy Init] Final sprite_index set to: " + string(sprite_index));
        // === 精靈處理結束 ===

        // 技能解鎖 (已修正，直接使用工廠提供的陣列)
        var skill_ids_from_template = template.skills;          // 這是一個字串陣列
        var unlock_lvls_from_template = template.skill_unlock_levels; // 這是一個數字陣列
        
        // 確保兩個陣列長度一致，避免索引錯誤
        var num_skills = min(array_length(skill_ids_from_template), array_length(unlock_lvls_from_template)); 
        
        // 遍歷技能
        for (var i = 0; i < num_skills; ++i) {
            var unlock_level = unlock_lvls_from_template[i]; // 直接使用數字，無需 real()
            var skill_id_str = skill_ids_from_template[i];   // 獲取技能 ID 字串
            
            // 檢查等級是否達到解鎖條件
            if (level >= unlock_level) {
                // 將技能 ID 字串轉換為數字，並添加到實例的 skills 陣列中
                array_push(skills, real(skill_id_str)); 
            }
        }
    }
    show_debug_message("[DEBUG] convert_to_real_enemy() - 工廠產生 instance 結構已標準化");
    converted = true;
}

// 新增：在 Create 事件中訂閱 managers_initialized 事件邏輯
if (instance_exists(obj_event_manager)) {
    with (obj_event_manager) {
        subscribe_to_event("managers_initialized", other.id, "on_managers_initialized");
    }
} else {
    show_debug_message("[警告] obj_enemy_placer：找不到事件管理器，無法訂閱 managers_initialized 事件！");
}

// 在 Create 事件結束前打印座標
show_debug_message("[DEBUG] obj_enemy_placer Create Event - 最終結束, Pos: x=" + string(x) + ", y=" + string(y)); 