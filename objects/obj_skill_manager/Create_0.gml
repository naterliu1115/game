/// @description 初始化技能管理器

// 技能資料庫
skill_database = ds_map_create();

// 資料載入狀態
skills_loaded = false;

// 初始化函數
initialize = function() {
    show_debug_message("===== 初始化技能管理器 =====");
    
    // 清空技能資料庫
    ds_map_clear(skill_database);
    
    // 載入技能資料
    load_skills_from_csv();
    
    // 訂閱相關事件
    subscribe_to_events();
    
    show_debug_message("技能管理器初始化完成");
};

// 載入CSV技能資料
load_skills_from_csv = function() {
    show_debug_message("正在從CSV載入技能資料...");
    
    var _csv_file = "skills/skills.csv";
    var grid = load_csv(_csv_file); // load_csv 會處理 datafiles/ 前綴檢查
    
    if (!ds_exists(grid, ds_type_grid)) {
        show_debug_message("錯誤：無法通過 load_csv 加載技能文件: " + _csv_file);
        skills_loaded = false;
        return false;
    }
    
    // 獲取行數和列數
    var width = ds_grid_width(grid);
    var height = ds_grid_height(grid);
    show_debug_message("技能CSV讀取成功：" + string(height - 1) + " 行數據 (共 " + string(width) + " 列)");
    
    var skills_loaded_count = 0;
    // 從第二行開始讀取
    for (var i = 1; i < height; i++) {
        var skill = {};
        var _skill_id = ""; // 存儲ID用於Map鍵
        var _valid_row = true;
        
        // 遍歷所有列名 (假設標題行在第0行)
        for (var j = 0; j < width; j++) {
            var field_name = ds_grid_get(grid, j, 0); // 從grid獲取列名
            var value_raw = ds_grid_get(grid, j, i); // 獲取原始值
            var value_str = ""; // Default to empty string
            
            // 檢查原始值是否為字符串，如果不是則嘗試轉換
            try {
                if (!is_undefined(value_raw)) {
                    value_str = string(value_raw);
                }
            } catch (_err) {
                show_debug_message("錯誤：在行 " + string(i+1) + ", 列 " + string(j) + " 轉換值時發生錯誤: " + string(_err));
                value_str = "";
                 _valid_row = false; // Consider invalidating row on conversion error
                 // break; // Optional: break inner loop if conversion fails
            }
            
            // 修改：使用更安全的 Trim 邏輯
            var trimmed_value_str = value_str; // Start with the potentially converted string
            if (is_string(trimmed_value_str)) { // Double-check it's a string before proceeding
                // 手動移除前端空格 (ASCII 32)
                while (string_length(trimmed_value_str) > 0 && ord(string_char_at(trimmed_value_str, 1)) == 32) {
                    trimmed_value_str = string_delete(trimmed_value_str, 1, 1);
                }
                // 手動移除後端空格 (ASCII 32)
                while (string_length(trimmed_value_str) > 0 && ord(string_char_at(trimmed_value_str, string_length(trimmed_value_str))) == 32) {
                    trimmed_value_str = string_delete(trimmed_value_str, string_length(trimmed_value_str), 1);
                }
                // 可以在這裡添加對其他不可見字符的檢查和移除 (例如 ord(char) < 32)
            } else {
                // 如果轉換後仍然不是字符串，則保持為空
                trimmed_value_str = "";
                 show_debug_message("警告：在行 " + string(i+1) + ", 列 " + string(j) + " 無法獲取有效的字符串值用於Trim。");
                 if (field_name == "id") { // If ID field is problematic, invalidate
                     _valid_row = false;
                 }
            }
            
            // 增加詳細調試，就在錯誤行之前
            // show_debug_message("Debug Check: Row=" + string(i+1) + ", Col=" + string(j) + ", Field='" + field_name + "', ValueStr='" + value_str + "', TrimmedValue='" + trimmed_value_str + "'");

            // 使用處理過的 trimmed_value_str 進行判斷
            if (field_name == "id") {
                 if(string_length(trimmed_value_str) == 0) { // 使用手動 trim 後的結果
                     _valid_row = false;
                     // 如果ID行為空，可以選擇跳過該行的剩餘列處理
                      show_debug_message("  因ID為空或無效，跳過行 " + string(i+1));
                     break; // 跳出內層 j 循環
                 } else {
                     _skill_id = real(trimmed_value_str); // 直接轉為數字ID
                 }
            }

             // 如果行因ID無效，跳過剩餘列
             if (!_valid_row) continue;

            // 根據欄位名稱轉換類型
            switch (field_name) {
                case "id":
                    skill[$ field_name] = _skill_id; // 使用已驗證的數字ID
                    break;
                case "damage_multiplier":
                case "range":
                case "cooldown":
                case "area_radius":
                case "anim_frames":
                    try { // 添加 try-catch 以便捕獲特定行的錯誤
                        if (is_string(trimmed_value_str) && is_numeric_safe(trimmed_value_str)) {
                             skill[$ field_name] = real(trimmed_value_str);
                        } else {
                             // show_debug_message("  -> WARNING: Value is not a numeric string. Setting to 0.");
                             skill[$ field_name] = 0;
                        }
                    } catch (_err) {
                         show_debug_message("  -> CRITICAL ERROR during numeric check/conversion: " + string(_err));
                         skill[$ field_name] = 0; 
                    }
                    break;
                case "anim_damage_frames":
                    var frames_array = [];
                    if (string_length(trimmed_value_str) > 0) {
                        var frames = string_split(trimmed_value_str, ";"); 
                        for (var k = 0; k < array_length(frames); k++) {
                            var frame_str_raw = frames[k];
                            var frame_str_trimmed = frame_str_raw;
                            if (is_string(frame_str_trimmed)) {
                                while (string_length(frame_str_trimmed) > 0 && ord(string_char_at(frame_str_trimmed, 1)) == 32) { frame_str_trimmed = string_delete(frame_str_trimmed, 1, 1); }
                                while (string_length(frame_str_trimmed) > 0 && ord(string_char_at(frame_str_trimmed, string_length(frame_str_trimmed))) == 32) { frame_str_trimmed = string_delete(frame_str_trimmed, string_length(frame_str_trimmed), 1); }
                            }
                            try { 
                                if (is_string(frame_str_trimmed) && is_numeric_safe(frame_str_trimmed)) {
                                    array_push(frames_array, real(frame_str_trimmed));
                                } else {
                                    if (string_length(frame_str_trimmed) > 0) {
                                         show_debug_message("  -> WARNING: Invalid frame value '" + frame_str_trimmed + "' in anim_damage_frames, Row: " + string(i+1));
                                    }
                                }
                            } catch (_f_err) {
                                show_debug_message("  -> CRITICAL ERROR during frame conversion for frame '" + frame_str_trimmed + "': " + string(_f_err));
                            }
                        }
                    }
                    skill[$ field_name] = frames_array;
                    break;
                default:
                    // 對於 name, description 等，使用原始轉換後的 value_str
                    skill[$ field_name] = value_str;
                    // 如果確定也要移除它們的前後空格，可以用 trimmed_value_str
                    // skill[$ field_name] = trimmed_value_str; 
                    break;
            }
        }
        
        // 如果是有效行，添加到數據庫
        if (_valid_row && _skill_id != "") {
            ds_map_add(skill_database, _skill_id, skill); // 以數字ID為key
            skills_loaded_count++;
        } else if (!_valid_row && _skill_id == "") {
            // 只有當是因為ID無效而跳過時才顯示此信息
            // show_debug_message("警告：跳過技能數據行 " + string(i+1) + "，因為 ID 為空或數據無效。");
        } else if (_skill_id != "") {
            // 如果 ID 有效但行中其他地方出錯(例如轉換失敗)
            show_debug_message("警告：跳過技能數據行 " + string(i+1) + " (ID: " + _skill_id + ")，可能因為行中存在轉換錯誤。");
        }
    }
    
    // 清理 grid
    ds_grid_destroy(grid);
    
    show_debug_message("技能載入完成，共載入 " + string(skills_loaded_count) + " 個技能");
    skills_loaded = (skills_loaded_count > 0);
    
    return skills_loaded;
};

// 取得技能資料
get_skill = function(skill_id) {
    skill_id = real(skill_id); // 強制轉為數字
    if (!ds_map_exists(skill_database, skill_id)) {
        show_debug_message("警告：找不到技能 - " + string(skill_id));
        return undefined;
    }
    return ds_map_find_value(skill_database, skill_id);
};

// 複製技能資料 (避免修改原始資料)
copy_skill = function(skill_id, unit_data_or_id) {
    skill_id = real(skill_id); // 強制轉為數字
    var skill_template = get_skill(skill_id);
    if (skill_template == undefined) return undefined;
    var skill_copy = {};
    var field_names = variable_struct_get_names(skill_template);
    for (var i = 0; i < array_length(field_names); i++) {
        var field = field_names[i];
        skill_copy[$ field] = skill_template[$ field];
    }
    show_debug_message("[SkillManager] Copied skill template: " + string(skill_id));
    return skill_copy;
};

// 獲取所有技能ID
get_all_skill_ids = function() {
    var keys = ds_map_keys_to_array(skill_database);
    return keys;
};

// 用於斷開外部引用的清理
cleanup = function() {
    // 清空資料庫
    ds_map_destroy(skill_database);
};

// 訂閱事件
subscribe_to_events = function() {
    if (instance_exists(obj_event_manager)) {
        with (obj_event_manager) {
            subscribe_to_event("game_save", other.id, "on_game_save");
            subscribe_to_event("game_load", other.id, "on_game_load");
        }
    }
};

// 輔助函數：分割字串 (改名為custom_string_split以避免與內建函數衝突)
custom_string_split = function(str, delimiter) {
    var result = [];
    var pos = string_pos(delimiter, str);
    
    while (pos > 0) {
        array_push(result, string_copy(str, 1, pos - 1));
        str = string_delete(str, 1, pos);
        pos = string_pos(delimiter, str);
    }
    
    // 添加最後一部分
    if (string_length(str) > 0) {
        array_push(result, str);
    }
    
    return result;
};

// 立即初始化
initialize(); 