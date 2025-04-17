/// @function finalize_capture_action(target_enemy_instance, capture_success_flag)
/// @description Handles the final steps after a capture attempt (success or failure).
/// @param {Id.Instance} target_enemy_instance The instance ID of the enemy being captured.
/// @param {Bool} capture_success_flag True if the capture was successful, false otherwise.
function finalize_capture_action(target_enemy_instance, capture_success_flag) {

    if (capture_success_flag) {
        // 捕獲成功的處理邏輯
        if (target_enemy_instance != noone && instance_exists(target_enemy_instance)) {
            show_debug_message("成功捕獲 (來自腳本): " + object_get_name(target_enemy_instance.object_index));

            // --- Start: Logic to create captured monster data ---
             var _template_id = target_enemy_instance.template_id;
             var _level = target_enemy_instance.level;
             var _name = "Unknown"; // Default name
             // var _type = target_enemy_instance.object_index; // Object index might not be needed by manager
             var _sprite_idle = target_enemy_instance.sprite_index; // Get current sprite as default

             // Try to get more precise data from the factory if possible
             var _template = undefined;
             if (instance_exists(obj_enemy_factory)) {
                 _template = obj_enemy_factory.get_enemy_template(_template_id);
                 if (_template != undefined) {
                     _name = variable_struct_exists(_template, "name") ? _template.name : "Unknown Template Name";
                     // Use template sprite if available and valid
                     var _template_sprite = variable_struct_get(_template, "sprite_idle");
                     if (!is_undefined(_template_sprite) && sprite_exists(_template_sprite)) {
                           _sprite_idle = _template_sprite; 
                     }
                 }
             }

             if (_template == undefined) {
                 show_debug_message("錯誤(腳本)：無法從工廠獲取模板 ID: " + string(_template_id) + "，將使用實例數據。");
                 // Fallback to instance data if template is missing
                 if (variable_instance_exists(target_enemy_instance,"name")) {
                     _name = target_enemy_instance.name; // Assuming enemy instance has a 'name' variable
                 }
                 // Keep using instance sprite_index as fallback
             }

             // Calculate stats based on template (or defaults if template unavailable)
             var _hp_base = 1, _hp_growth = 0, _attack_base = 1, _attack_growth = 0, _defense_base = 1, _defense_growth = 0, _speed_base = 1, _speed_growth = 0;

             if (_template != undefined) {
                 _hp_base = variable_struct_get_or_default(_template, "hp_base", 1);
                 _hp_growth = variable_struct_get_or_default(_template, "hp_growth", 0);
                 _attack_base = variable_struct_get_or_default(_template, "attack_base", 1);
                 _attack_growth = variable_struct_get_or_default(_template, "attack_growth", 0);
                 _defense_base = variable_struct_get_or_default(_template, "defense_base", 1);
                 _defense_growth = variable_struct_get_or_default(_template, "defense_growth", 0);
                 _speed_base = variable_struct_get_or_default(_template, "speed_base", 1);
                 _speed_growth = variable_struct_get_or_default(_template, "speed_growth", 0);
             } else {
                 show_debug_message("警告(腳本): 無法計算基礎屬性，模板未找到。將使用默認值。");
             }

             // Helper function for safer struct access (define elsewhere or inline)
             #macro variable_struct_get_or_default function(_struct, _key, _default) { return variable_struct_exists(_struct, _key) ? variable_struct_get(_struct, _key) : _default; }

             var _max_hp = ceil(_hp_base + (_hp_base * _hp_growth * (_level - 1)));
             var _attack = ceil(_attack_base + (_attack_base * _attack_growth * (_level - 1)));
             var _defense = ceil(_defense_base + (_defense_base * _defense_growth * (_level - 1)));
             var _spd = ceil(_speed_base + (_speed_base * _speed_growth * (_level - 1)));

             _max_hp = max(1, _max_hp);
             _attack = max(1, _attack);
             _defense = max(1, _defense);
             _spd = max(1, _spd);

             // --- 更新：根據捕獲等級計算當前技能 ---
             var _current_skills = []; // 初始化為空列表
             if (_template != undefined) {
                 var _template_skills = [];
                 var _template_unlock_levels = [];

                 // 獲取模板的技能列表 (鍵名：skills)
                 if (variable_struct_exists(_template, "skills")) {
                     var _skills_data = variable_struct_get(_template, "skills");
                     if (is_array(_skills_data)) {
                         _template_skills = array_clone(_skills_data);
                     } else if (is_string(_skills_data)) {
                         var _skill_ids_str = string_split(_skills_data, ";");
                         for(var i = 0; i < array_length(_skill_ids_str); i++) {
                             var _id = real(_skill_ids_str[i]);
                             if (!is_nan(_id)) array_push(_template_skills, _id);
                         }
                     }
                 }
                 
                 // 獲取模板的技能解鎖等級列表 (鍵名：skill_unlock_levels)
                 if (variable_struct_exists(_template, "skill_unlock_levels")) {
                      var _levels_data = variable_struct_get(_template, "skill_unlock_levels");
                     if (is_array(_levels_data)) {
                         _template_unlock_levels = array_clone(_levels_data);
                     } else if (is_string(_levels_data)) {
                         var _levels_str = string_split(_levels_data, ";");
                         for(var i = 0; i < array_length(_levels_str); i++) {
                             var _lvl = real(_levels_str[i]);
                             if (!is_nan(_lvl)) array_push(_template_unlock_levels, _lvl);
                         }
                     }
                 }
                 
                 // 確保兩個列表長度匹配
                 var _num_skills = array_length(_template_skills);
                 if (_num_skills > 0 && _num_skills == array_length(_template_unlock_levels)) {
                     show_debug_message(">>> finalize_capture_action: Checking " + string(_num_skills) + " skills against captured level " + string(_level));
                     // 遍歷技能列表，判斷是否達到解鎖等級
                     for (var i = 0; i < _num_skills; i++) {
                         if (_level >= _template_unlock_levels[i]) {
                             array_push(_current_skills, _template_skills[i]);
                         }
                     }
                     show_debug_message(">>> finalize_capture_action: Calculated " + string(array_length(_current_skills)) + " current skills for captured monster.");
                 } else if (_num_skills > 0) {
                      show_debug_message("警告(腳本): 模板技能列表與解鎖等級列表長度不匹配！無法計算當前技能。");
                 } else {
                     show_debug_message("警告(腳本): 模板中未找到有效的技能數據。");
                 }
                 
             } else {
                 show_debug_message("警告(腳本): 模板未定義，無法計算當前技能。");
             }
             // --- 當前技能計算結束 ---

             show_debug_message(">>> finalize_capture_action: Final sprite = " + sprite_get_name(_sprite_idle) + " (" + string(_sprite_idle) + ")");

             // Create the final data struct for the monster manager
             var captured_monster_data = {
                 template_id: _template_id, // Use template_id
                 level: _level,
                 name: _name,
                 display_sprite: _sprite_idle, // Sprite for display purposes
                 max_hp: _max_hp,
                 hp: _max_hp, // Captured at full health
                 attack: _attack,
                 defense: _defense,
                 spd: _spd,
                 current_exp: 0, // Start with 0 exp
                 skills: _current_skills // 添加計算出的當前技能列表
                 // Add other necessary fields if monster_data_manager expects them
             };
             // --- End: Logic to create captured monster data ---


            // Add the captured monster using the manager
            var new_monster_uid = add_player_monster(captured_monster_data);
            if (!is_undefined(new_monster_uid)) {
                show_debug_message("已將(腳本) [" + captured_monster_data.name + " Lv." + string(_level) + "] (ID: " + string(_template_id) + ", UID: " + string(new_monster_uid) + ") 添加到玩家列表");

                // Broadcast the capture success event
                show_debug_message("[Capture Success - Script] Broadcasting unit_captured event for ID: " + string(target_enemy_instance));
                
                // 使用全局廣播函數，而不是嘗試通過實例調用 broadcast 方法
                broadcast_event("unit_captured", { unit_instance: target_enemy_instance });

                // 成功時返回創建的怪物數據
                return captured_monster_data; 

            } else {
                 show_debug_message("錯誤(腳本)：添加捕獲的怪物到管理器失敗！");
                 return undefined; // 添加失敗也算失敗，返回 undefined
            }

        } else {
            show_debug_message("finalize_capture_action 錯誤: 目標敵人不存在或無效！");
            return undefined; // 目標不存在，返回 undefined
        }

    } else {
        // 捕獲失敗的處理邏輯
        show_debug_message("捕獲失敗(腳本)，無需處理成功邏輯。" );
        // 失敗時返回失敗原因字串
        return "捕獲失敗！"; 
    }

    // Note: Closing the UI is handled by obj_capture_ui's Alarm 1
}
