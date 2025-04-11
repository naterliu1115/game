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
    
    var file = "skills/skills.csv";
    var skills_loaded_count = 0;
    
    // 檢查檔案是否存在
    if (!file_exists(file)) {
        show_debug_message("錯誤：技能資料檔案不存在 - " + file);
        return false;
    }
    
    // 開啟檔案
    var file_id = file_text_open_read(file);
    
    // 讀取標題行
    var header = file_text_read_string(file_id);
    file_text_readln(file_id);
    
    // 解析標題獲取欄位索引
    var header_fields = custom_string_split(header, ",");
    var field_indices = ds_map_create();
    
    for (var i = 0; i < array_length(header_fields); i++) {
        ds_map_add(field_indices, header_fields[i], i);
    }
    
    show_debug_message("識別到的欄位：" + string(array_length(header_fields)));
    
    // 讀取每一行資料
    while (!file_text_eof(file_id)) {
        var line = file_text_read_string(file_id);
        file_text_readln(file_id);
        
        // 跳過空行
        if (line == "") continue;
        
        // 解析CSV行
        var values = custom_string_split(line, ",");
        
        // 如果欄位數不足，跳過
        if (array_length(values) < array_length(header_fields)) {
            show_debug_message("警告：資料行欄位不足 - " + line);
            continue;
        }
        
        // 創建技能結構體
        var skill = {};
        
        // 填充所有欄位
        for (var i = 0; i < array_length(header_fields); i++) {
            var field_name = header_fields[i];
            var value = values[i];
            
            // 根據欄位類型轉換值
            switch (field_name) {
                case "damage_multiplier":
                case "range":
                case "cooldown":
                case "area_radius":
                    // 數值型欄位轉為數字
                    skill[$ field_name] = real(value);
                    break;
                    
                case "anim_damage_frames":
                    // 分號分隔的數字轉為陣列
                    var frames = custom_string_split(value, ";");
                    var frames_array = [];
                    
                    for (var j = 0; j < array_length(frames); j++) {
                        array_push(frames_array, real(frames[j]));
                    }
                    
                    skill[$ field_name] = frames_array;
                    break;
                    
                case "anim_frames":
                    // 單一數字轉為數字
                    skill[$ field_name] = real(value);
                    break;
                    
                default:
                    // 字串欄位保持字串
                    skill[$ field_name] = value;
                    break;
            }
        }
        
        // 添加到技能資料庫
        var skill_id = skill.id;
        ds_map_add(skill_database, skill_id, skill);
        skills_loaded_count++;
        
        show_debug_message("已載入技能: " + skill_id + " - " + skill.name);
    }
    
    // 關閉檔案
    file_text_close(file_id);
    
    // 清理臨時資料
    ds_map_destroy(field_indices);
    
    show_debug_message("技能載入完成，共載入 " + string(skills_loaded_count) + " 個技能");
    skills_loaded = true;
    
    return true;
};

// 取得技能資料
get_skill = function(skill_id) {
    if (!ds_map_exists(skill_database, skill_id)) {
        show_debug_message("警告：找不到技能 - " + skill_id);
        return undefined;
    }
    
    return ds_map_find_value(skill_database, skill_id);
};

// 複製技能資料 (避免修改原始資料)
copy_skill = function(skill_id, unit_data_or_id) {
    var skill_template = get_skill(skill_id);
    if (skill_template == undefined) return undefined;

    var skill_copy = {};
    var field_names = variable_struct_get_names(skill_template);
    for (var i = 0; i < array_length(field_names); i++) {
        var field = field_names[i];
        skill_copy[$ field] = skill_template[$ field];
    }

    show_debug_message("[SkillManager] Copied skill template: " + skill_id);

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