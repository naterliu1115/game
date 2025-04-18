/// @function summon_monster_from_ui(monster_data, player_monster_list)
/// @description Creates a new monster instance based on UI selection and adds it to the player's list.
/// @param {Struct} monster_data The data of the monster selected in the UI (should contain template_id and level).
/// @param {Array<Struct>} player_monster_list The global list of player monsters.
/// @return {Bool} True if summoning was successful, false otherwise.
function summon_monster_from_ui(monster_data, player_monster_list) {
    // 驗證輸入數據
    if (!is_struct(monster_data) || !variable_struct_exists(monster_data, "template_id") || !variable_struct_exists(monster_data, "level")) {
        show_debug_message("[Summon Logic] Error: Invalid monster_data provided.");
        return false;
    }
    if (!is_array(player_monster_list)) {
        show_debug_message("[Summon Logic] Error: Invalid player_monster_list provided.");
        return false;
    }

    var _template_id = monster_data.template_id;
    var _level = monster_data.level;
    var _factory = obj_enemy_factory; // 假設工廠物件存在

    if (!instance_exists(_factory)) {
        show_debug_message("[Summon Logic] Error: Enemy factory instance does not exist.");
        return false;
    }

    // 1. 嘗試從工廠獲取模板數據 (移到 with 之外)
    var _summon_template = _factory.get_enemy_template(_template_id);
    if (is_undefined(_summon_template)) {
        show_debug_message("[Summon Logic] Error: Template ID " + string(_template_id) + " not found in factory.");
        return false;
    }

    // 2. 克隆技能和等級列表 (移到 with 之外)
    var _cloned_skills = [];
    var _cloned_levels = [];

    if (variable_struct_exists(_summon_template, "skills")) {
        var _skills_data = variable_struct_get(_summon_template, "skills");
        if (is_array(_skills_data)) {
            // 使用 array_copy 進行淺拷貝以避免作用域問題
            array_copy(_cloned_skills, 0, _skills_data, 0, array_length(_skills_data));
        } else if (is_string(_skills_data)) {
            var _skill_ids_str = string_split(_skills_data, ";");
            for (var i = 0; i < array_length(_skill_ids_str); i++) {
                var skill_id = real(_skill_ids_str[i]);
                if (skill_id > 0) { // Basic validation
                    array_push(_cloned_skills, skill_id);
                }
            }
        }
    }
    
    if (variable_struct_exists(_summon_template, "skill_unlock_levels")) {
        var _levels_data = variable_struct_get(_summon_template, "skill_unlock_levels");
        if (is_array(_levels_data)) {
           // 使用 array_copy 進行淺拷貝以避免作用域問題
           array_copy(_cloned_levels, 0, _levels_data, 0, array_length(_levels_data));
        } else if (is_string(_levels_data)) {
            var _levels_str = string_split(_levels_data, ";");
            for (var i = 0; i < array_length(_levels_str); i++) {
                var level_num = real(_levels_str[i]);
                 if (level_num > 0) { // Basic validation
                    array_push(_cloned_levels, level_num);
                 }
            }
        }
    }

    // 3. 創建新的召喚物實例 (但還不添加到列表)
    var _target_object_index = obj_test_summon; // Or determine based on template later
    if (variable_struct_exists(_summon_template, "object_index") && !is_undefined(_summon_template.object_index)) {
         _target_object_index = _summon_template.object_index;
    }
    
    show_debug_message("[Summon Logic] 準備創建實例，類型 object_index: " + object_get_name(_target_object_index) + " (" + string(_target_object_index) + ")");
    var new_summon = instance_create_layer(0, 0, "Instances", _target_object_index); // 初始位置不重要

    // 4. 使用 with 語句設置實例變量並初始化
    if (instance_exists(new_summon)) {
        show_debug_message("設置召喚物 template_id 為: " + string(_template_id));
        show_debug_message("設置召喚物 level 為: " + string(_level));

        with (new_summon) {
            template_id = _template_id; // 模板ID
            level = _level;             // 初始等級
            
            // 將預先克隆好的數組賦值給實例變量
            template_skills = _cloned_skills; 
            template_skill_unlock_levels = _cloned_levels;

            // 調用初始化函數（假設它需要 template_id, level, template_skills 等已設置）
            initialize(); // 這個函數應該基於已設置的 template_id 和 level 等來完成初始化
        }
        
        // 5. 將新創建並初始化的怪物數據轉換為結構體並添加到全局列表
        //    **確保包含所有 UI 繪圖所需的欄位**
        var monster_instance_data = {
            uid: new_summon.id, // 或者需要一個唯一的管理器ID？
            template_id: _template_id,
            name: new_summon.name, // 從實例獲取最終名稱
            level: new_summon.level, // 從實例獲取最終等級
            current_exp: (variable_instance_exists(new_summon, "current_exp") ? new_summon.current_exp : 0),
            hp: new_summon.hp,
            max_hp: new_summon.max_hp,
            attack: new_summon.attack,
            defense: new_summon.defense,
            spd: new_summon.spd,
            skills: new_summon.template_skills, // 使用實例上最終的技能列表 (假設格式與 UI 兼容)
            skill_unlock_levels: new_summon.template_skill_unlock_levels,
            // 嘗試獲取 display_sprite，如果不存在則設為 undefined 或 -1，讓UI處理
            display_sprite: (variable_instance_exists(new_summon, "display_sprite") ? new_summon.display_sprite : (variable_instance_exists(new_summon, "sprite_index") ? new_summon.sprite_index : -1)),
            instance_ref: new_summon // 可選：儲存實例引用
        };
        
        add_player_monster(monster_instance_data); // 使用我們的管理器函數添加
        
        show_debug_message("[Summon Logic] Successfully summoned monster: " + string(new_summon.id));
        return true; // 召喚成功

    } else {
        show_debug_message("[Summon Logic] Error: Failed to create instance of " + object_get_name(_target_object_index));
        return false; // 召喚失敗
    }
} 

// =============================================
// Summon UI Interaction Logic (Moved from obj_summon_ui Create)
// =============================================

/// @function summon_ui_handle_confirm(summon_ui_inst)
/// @description 處理召喚UI的確認操作，從UI介面中獲取選擇的怪物數據並召喚怪物
/// @param {Id.Instance} summon_ui_inst 召喚UI實例
function summon_ui_handle_confirm(summon_ui_inst) {
    show_debug_message("===== summon_ui_handle_confirm 開始 =====");
    
    // 檢查UI實例是否存在
    if (!instance_exists(summon_ui_inst)) {
        show_debug_message("錯誤：UI實例不存在");
        return false;
    }
    
    // 獲取選中的怪物索引
    var selected_index = (variable_instance_exists(summon_ui_inst, "selected_monster")) ? summon_ui_inst.selected_monster : -1;
    if (selected_index == -1 || selected_index >= array_length(global.player_monsters)) {
        show_debug_message("錯誤：未選擇怪物或索引無效 - " + string(selected_index));
        return false;
    }
    
    // 獲取選中的怪物數據，並檢查 uid
    var monster_data = global.player_monsters[selected_index];
    if (!is_struct(monster_data) || !variable_struct_exists(monster_data, "uid")) {
        show_debug_message("錯誤：選中的怪物數據無效或缺少 UID");
        return false;
    }
    var monster_uid = monster_data.uid;
    show_debug_message("選中的怪物數據：");
    if(variable_struct_exists(monster_data, "name")) show_debug_message("- 名稱：" + string(monster_data.name));
    if(variable_struct_exists(monster_data, "level")) show_debug_message("- 等級：" + string(monster_data.level));
    show_debug_message("- UID：" + string(monster_uid));

    // 獲取模板ID和等級
    var template_id = -1;
    if (variable_struct_exists(monster_data, "template_id")) {
        template_id = monster_data.template_id;
        show_debug_message("- 使用模板ID：" + string(template_id));
    } else if (variable_struct_exists(monster_data, "id")) {
        template_id = monster_data.id;
        show_debug_message("- 使用舊格式ID：" + string(template_id));
    } else {
        show_debug_message("錯誤：未找到有效的template_id或id");
        return false;
    }
    var level = variable_struct_get_or_default(monster_data, "level", 1);
    show_debug_message("- 模板ID確認：" + string(template_id));
    show_debug_message("- 等級確認：" + string(level));

    // 檢查單位管理器是否存在
    if (!instance_exists(obj_unit_manager)) {
        show_debug_message("錯誤：單位管理器不存在，無法召喚怪物");
        return false;
    }
    
    // 確定一個合適的召喚位置（基於玩家位置）
    var summon_x = 0;
    var summon_y = 0;
    var player_inst = instance_find(Player, 0);
    if (instance_exists(player_inst)) {
        summon_x = player_inst.x + 64;
        summon_y = player_inst.y;
        summon_x = clamp(summon_x, 32, room_width - 32);
        summon_y = clamp(summon_y, 32, room_height - 32);
        show_debug_message("使用玩家位置進行召喚：(" + string(summon_x) + ", " + string(summon_y) + ")");
    } else {
        summon_x = room_width / 2;
        summon_y = room_height / 2;
        show_debug_message("使用預設位置進行召喚：(" + string(summon_x) + ", " + string(summon_y) + ")");
    }
    
    // --- 移除從 monster_data 獲取 type 的邏輯 ---
    // var monster_type_name = variable_struct_get_or_default(monster_data, "type", "obj_test_summon");
    // var monster_type = asset_get_index(monster_type_name);
    // if (monster_type == -1) {
    //     show_debug_message("警告：無法解析怪物類型 - \" + monster_type_name + \"，使用預設類型 obj_test_summon");
    //     monster_type = obj_test_summon;
    // }
    // --- 直接固定使用 obj_test_summon ---
    var monster_type = obj_test_summon;
    show_debug_message("固定使用怪物類型: obj_test_summon");

    show_debug_message("將使用以下參數召喚怪物：");
    show_debug_message("- 怪物類型：" + object_get_name(monster_type));
    show_debug_message("- 位置：(" + string(summon_x) + ", " + string(summon_y) + ")");
    show_debug_message("- 模板ID：" + string(template_id));
    show_debug_message("- 等級：" + string(level));
    show_debug_message("- UID：" + string(monster_uid));

    // 使用單位管理器的 summon_monster 函數召喚怪物，並傳遞 uid
    var success = obj_unit_manager.summon_monster(monster_type, summon_x, summon_y, template_id, level, monster_uid); // <-- 傳遞 monster_uid
    
    if (success) {
        show_debug_message("怪物成功召喚到戰場！");
        
        // 關閉召喚UI
        if (instance_exists(summon_ui_inst) && variable_instance_exists(summon_ui_inst, "hide")) {
            summon_ui_inst.hide();
            show_debug_message("召喚UI已關閉");
        } else if (instance_exists(obj_ui_manager)) {
            obj_ui_manager.hide_ui(summon_ui_inst);
            show_debug_message("通過UI管理器關閉召喚UI");
        }
        
        return true;
    } else {
        // 嘗試獲取失敗原因
        var reason = "未知原因";
        if (instance_exists(obj_unit_manager)) {
            if (obj_unit_manager.global_summon_cooldown > 0) {
                reason = "冷卻中 (" + string(obj_unit_manager.global_summon_cooldown) + ")";
            } else if (ds_list_size(obj_unit_manager.player_units) >= obj_unit_manager.max_player_units) {
                reason = "已達到最大單位數 (" + string(obj_unit_manager.max_player_units) + ")";
            } else if (variable_global_exists("in_battle") && !global.in_battle) {
                reason = "不在戰鬥中";
            }
        }
        
        show_debug_message("錯誤：怪物召喚失敗 - " + reason);
        
        // 顯示失敗信息
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("召喚失敗: " + reason);
        }
        
        return false;
    }
}

/// @function summon_ui_handle_mouse_click(ui_instance, mx, my)
/// @desc Handles mouse click input for the summon UI.
/// @param {Id.Instance} ui_instance The instance ID of the calling summon UI.
/// @param {Real} mx Mouse X coordinate (GUI layer).
/// @param {Real} my Mouse Y coordinate (GUI layer).
/// @returns {Bool} True if the click was handled, false otherwise.
function summon_ui_handle_mouse_click(ui_instance, mx, my) {
     if (!instance_exists(ui_instance)) return false; // Safety check

     var _handled = false;

     // 1. 檢查是否點擊了召喚按鈕
    if (ui_instance.selected_monster >= 0 && point_in_rectangle(
        mx, my,
        ui_instance.summon_btn_x, ui_instance.summon_btn_y,
        ui_instance.summon_btn_x + ui_instance.summon_btn_width, ui_instance.summon_btn_y + ui_instance.summon_btn_height
    )) {
        show_debug_message("[Summon Logic Script] Summon button clicked for UI instance: " + string(ui_instance));
        _handled = true;

        var _selected_monster_data = ds_list_find_value(ui_instance.monster_list, ui_instance.selected_monster);

        if (!is_struct(_selected_monster_data)) {
            show_debug_message("[Summon Logic Script] Error: Failed to retrieve valid monster data struct (button click)");
            return _handled;
        }

        // --- 新的、職責分離的召喚流程 ---
        var _template_id = -1;
        var _level = 1;

        if (variable_struct_exists(_selected_monster_data, "template_id")) { _template_id = _selected_monster_data.template_id; }
        else if (variable_struct_exists(_selected_monster_data, "id")) { _template_id = _selected_monster_data.id; }
        else { show_debug_message("[Summon Logic Script] Error: No template_id/id found (button click)."); return _handled; }

        if (variable_struct_exists(_selected_monster_data, "level")) { _level = _selected_monster_data.level; }

        // 1. 調用數據管理器添加數據 (直接調用全局函數)
        var _new_monster_uid = add_monster_from_template(_template_id, _level);
        if (is_undefined(_new_monster_uid)) {
            show_debug_message("[Summon Logic Script] Failed to add data via manager (button click).");
            if (instance_exists(obj_battle_ui)) obj_battle_ui.show_info("添加數據失敗!");
            return _handled;
        }
        show_debug_message("[Summon Logic Script] Data added via button. UID: " + string(_new_monster_uid));

        // 2. 準備部署實例到戰場 (安全訪問工廠)
        var _template = undefined;
        
        if (instance_exists(obj_enemy_factory)) {
            _template = obj_enemy_factory.get_enemy_template(_template_id);
        } else {
            show_debug_message("[Summon Logic Script] Error: Enemy factory instance not found (button click).");
            remove_monster(_new_monster_uid);
            if (instance_exists(obj_battle_ui)) obj_battle_ui.show_info("工廠異常!");
            return _handled;
        }
        
        if (is_undefined(_template)) {
             show_debug_message("[Summon Logic Script] Error: Cannot get template (button click).");
             remove_monster(_new_monster_uid); // Rollback
             if (instance_exists(obj_battle_ui)) obj_battle_ui.show_info("獲取模板失敗!");
             return _handled;
        }
        
        var _target_object_index = obj_test_summon;
        if (variable_struct_exists(_template, "object_index") && !is_undefined(_template.object_index)) { 
            _target_object_index = _template.object_index; 
        }

        // 確定放置位置 (靠近玩家)
        var _pos_x = 0;
        var _pos_y = 0;
        
        if (instance_exists(global.player)) {
            _pos_x = global.player.x + 50;
            _pos_y = global.player.y;
        } else {
            show_debug_message("[Summon Logic Script] Warning: Player not found, using default position (button click).");
            _pos_x = room_width / 2;
            _pos_y = room_height / 2;
        }

        // 調用單位管理器召喚 (安全訪問單位管理器)，額外傳遞 template_id 和 level
        var _summon_success = false;
        
        if (instance_exists(obj_unit_manager)) {
            _summon_success = obj_unit_manager.summon_monster(_target_object_index, _pos_x, _pos_y, _template_id, _level);
        } else {
            show_debug_message("[Summon Logic Script] Error: Unit manager instance not found (button click).");
            remove_monster(_new_monster_uid);
            if (instance_exists(obj_battle_ui)) obj_battle_ui.show_info("單位管理器異常!");
            return _handled;
        }

        if (_summon_success) {
             show_debug_message("[Summon Logic Script] Instance deployed via button. Requesting UI hide.");
             if (instance_exists(obj_ui_manager)) { obj_ui_manager.hide_ui(ui_instance); }
        } else {
             show_debug_message("[Summon Logic Script] Unit Manager failed to summon instance via button.");
             remove_monster(_new_monster_uid); // Rollback data addition
             show_debug_message("[Summon Logic Script] Rolled back data addition (button click).");
             
             // 獲取失敗原因
             var reason = "未知原因";
             if (instance_exists(obj_unit_manager)) {
                 if (obj_unit_manager.global_summon_cooldown > 0) {
                     reason = "冷卻中";
                 } else if (ds_list_size(obj_unit_manager.player_units) >= obj_unit_manager.max_player_units) {
                     reason = "數量已達上限";
                 }
             }
             
             if (instance_exists(obj_battle_ui)) {
                 obj_battle_ui.show_info("無法召喚: " + reason);
             }
        }
        // --- 結束新的召喚流程 ---
        return _handled; // Return true because the summon button click was handled
    }

    // 2. 檢查是否點擊了取消按鈕
    if (point_in_rectangle(
        mx, my,
        ui_instance.cancel_btn_x, ui_instance.cancel_btn_y,
        ui_instance.cancel_btn_x + ui_instance.cancel_btn_width, ui_instance.cancel_btn_y + ui_instance.cancel_btn_height
    )) {
        show_debug_message("[Summon Logic Script] Cancel button clicked for UI instance: " + string(ui_instance));
        if (instance_exists(obj_ui_manager)) {
            obj_ui_manager.hide_ui(ui_instance);
             _handled = true;
        } else {
            show_debug_message("警告：UI Manager 不存在，無法請求隱藏 Summon UI");
        }
        return _handled;
    }

    // 3. 檢查是否點擊了怪物卡片
    var list_count = ds_list_size(ui_instance.monster_list);
    if (list_count > 0) {
        var start_index = clamp(ui_instance.scroll_offset, 0, max(0, list_count - ui_instance.max_visible_monsters));
        var end_index = min(start_index + ui_instance.max_visible_monsters, list_count);

        for (var i = start_index; i < end_index; i++) {
            var card_y = ui_instance.ui_y + 50 + (i - start_index) * 130; // Use ui_instance.ui_y

            if (point_in_rectangle(
                mx, my,
                ui_instance.ui_x + 20, card_y, // Use ui_instance.ui_x
                ui_instance.ui_x + 20 + 220, card_y + 120
            )) {
                ui_instance.selected_monster = i;
                show_debug_message("[Summon Logic Script] Card selected via click: index " + string(i));
                ui_instance.surface_needs_update = true;
                _handled = true;
                break;
            }
        }
    }
    if (_handled) return true;

    // 4. 檢查是否點擊了滾動箭頭
     if (ds_list_size(ui_instance.monster_list) > ui_instance.max_visible_monsters) {
        // 上滾動箭頭
        if (point_in_rectangle(
            mx, my,
            ui_instance.ui_x + ui_instance.ui_width - 40, ui_instance.ui_y + 45, // Use instance vars
            ui_instance.ui_x + ui_instance.ui_width - 5, ui_instance.ui_y + 65
        )) {
            if (ui_instance.scroll_offset > 0) {
                ui_instance.scroll_offset--;
                show_debug_message("[Summon Logic Script] Scrolled up via click.");
                ui_instance.surface_needs_update = true;
                _handled = true;
            }
        }
        // 下滾動箭頭
        else if (point_in_rectangle(
            mx, my,
            ui_instance.ui_x + ui_instance.ui_width - 40, ui_instance.ui_y + ui_instance.ui_height - 90, // Use instance vars
            ui_instance.ui_x + ui_instance.ui_width - 5, ui_instance.ui_y + ui_instance.ui_height - 70
        )) {
            if (ui_instance.scroll_offset < ds_list_size(ui_instance.monster_list) - ui_instance.max_visible_monsters) {
                ui_instance.scroll_offset++;
                show_debug_message("[Summon Logic Script] Scrolled down via click.");
                ui_instance.surface_needs_update = true;
                _handled = true;
            }
        }
    }

    return _handled;
} 