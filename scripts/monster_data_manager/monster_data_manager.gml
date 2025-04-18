/// @function get_template_by_id(template_id)
/// @desc 依模板 id 查詢怪物模板，回傳 struct 或 undefined
function get_template_by_id(template_id) {
    if (!ds_map_exists(global.enemy_templates, template_id)) return undefined;
    return global.enemy_templates[? template_id];
}

// 全域 UID 計數器，確保每個怪物有唯一標識
if (!variable_global_exists("monster_uid_counter")) {
    global.monster_uid_counter = 0;
}

// 確保 player_monsters 列表存在
if (!variable_global_exists("player_monsters")) {
    global.player_monsters = [];
}

// =============================
// 0. 初始化
// =============================
/// @function initialize_player_monsters()
/// @desc 初始化或清空玩家怪物列表
function initialize_player_monsters() {
    global.player_monsters = [];
    global.monster_uid_counter = 0; // 如果需要重置 UID
    show_debug_message("[Monster Data Manager] Player monsters list initialized.");
}

// =============================
// 1. 查詢怪物數據
// =============================
/// @function get_player_monsters()
/// @desc 獲取所有玩家怪物的列表 (返回陣列引用，請謹慎使用)
/// @returns {Array<Struct>}
function get_player_monsters() {
    // 注意：直接返回引用意味著外部可以修改！
    // 如果需要更安全的版本，可以考慮返回深拷貝，但會有效能損耗。
    // 目前設計依賴外部 UI 僅讀取，或通過此管理器修改。
    return global.player_monsters;
}

/// @function get_monster_by_uid(uid)
/// @desc 根據 UID 查詢怪物數據 (返回 Struct 引用)
/// @param {Real} uid 怪物唯一 ID
/// @returns {Struct|Undefined} 怪物數據 Struct 或 undefined
function get_monster_by_uid(uid) {
    for (var i = 0; i < array_length(global.player_monsters); ++i) {
        if (global.player_monsters[i].uid == uid) {
            return global.player_monsters[i]; // 返回引用
        }
    }
    show_debug_message("[Monster Data Manager] Warning: Monster with UID " + string(uid) + " not found.");
    return undefined;
}

/// @function get_monster_index_by_uid(uid)
/// @desc (內部輔助) 根據 UID 查詢怪物在陣列中的索引
/// @param {Real} uid 怪物唯一 ID
/// @returns {Real} 索引值 (>=0) 或 -1 (未找到)
function get_monster_index_by_uid(uid) {
    for (var i = 0; i < array_length(global.player_monsters); ++i) {
        if (global.player_monsters[i].uid == uid) {
            return i;
        }
    }
    return -1;
}

// =============================
// 3. 新增怪物
// =============================
/// @function add_monster_from_template(template_id, level)
/// @desc 根據模板 id 與等級新增怪物，並自動分配 uid
/// @returns {Real|Undefined} 新怪物的 UID 或 undefined (失敗時)
function add_monster_from_template(template_id, level) {
    var template = get_template_by_id(template_id);
    if (is_undefined(template)) {
        show_debug_message("[Monster Data Manager] Error: Cannot add monster. Template ID " + string(template_id) + " not found.");
        return undefined;
    }
    var m = {}; // 使用 Struct 替代 {} 以提高性能和清晰度
    m.uid = global.monster_uid_counter++;
    m.template_id = template.template_id;
    m.name = variable_struct_exists(template, "name") ? template.name : "Unknown";
    m.type = variable_struct_exists(template, "type") ? template.type : 0; // 假設 0 是預設 type
    m.level = level;
    // 計算屬性 (確保模板中有這些欄位)
    var hp_base = variable_struct_exists(template, "hp_base") ? template.hp_base : 10;
    var hp_growth = variable_struct_exists(template, "hp_growth") ? template.hp_growth : 1;
    m.max_hp = ceil(hp_base + (hp_base * hp_growth * (level - 1)));
    m.hp = m.max_hp; // 新怪物滿血
    var attack_base = variable_struct_exists(template, "attack_base") ? template.attack_base : 5;
    var attack_growth = variable_struct_exists(template, "attack_growth") ? template.attack_growth : 1;
    m.attack = ceil(attack_base + (attack_base * attack_growth * (level - 1)));
    var defense_base = variable_struct_exists(template, "defense_base") ? template.defense_base : 5;
    var defense_growth = variable_struct_exists(template, "defense_growth") ? template.defense_growth : 1;
    m.defense = ceil(defense_base + (defense_base * defense_growth * (level - 1)));
    var spd_base = variable_struct_exists(template, "spd_base") ? template.spd_base : 5;
    var spd_growth = variable_struct_exists(template, "spd_growth") ? template.spd_growth : 1;
    m.spd = ceil(spd_base + (spd_base * spd_growth * (level - 1)));
    m.experience = 0; // 新怪物經驗為 0
    m.skills = []; // 技能列表
    m.display_sprite = asset_get_index(variable_struct_exists(template, "sprite_idle") ? template.sprite_idle : "spr_default"); // 確保有預設 Sprite
    
    // 技能解鎖 (已修正，直接使用模板提供的陣列)
    if (variable_struct_exists(template, "skills") && variable_struct_exists(template, "skill_unlock_levels")) {
        // 直接獲取模板中的陣列
        var skill_id_array = template.skills;          // 這個是技能 ID 字串的陣列
        var unlock_level_array = template.skill_unlock_levels; // 這個是解鎖等級數字的陣列

        // 確保獲取的是有效的陣列且長度匹配
        if (is_array(skill_id_array) && is_array(unlock_level_array) && array_length(skill_id_array) == array_length(unlock_level_array)) {
            for (var i = 0; i < array_length(skill_id_array); ++i) {
                // 直接使用數字陣列中的解鎖等級
                var unlock_level = unlock_level_array[i]; 
                // 獲取技能 ID 字串並轉換為數字
                var skill_id_str = skill_id_array[i];
                var skill_id = real(skill_id_str); // 假設技能 ID 應為數字存儲

                // 檢查等級要求和轉換有效性
                if (level >= unlock_level) {
                    if (!is_nan(skill_id)) { // 確保 real() 轉換成功
                        array_push(m.skills, skill_id);
                    } else {
                        show_debug_message("[Monster Data Manager] Warning: Invalid skill ID string found in template " + string(template_id) + ": '" + skill_id_str + "'");
                    }
                }
            }
        } else {
             show_debug_message("[Monster Data Manager] Warning: Mismatched or invalid skills/unlock levels arrays for template ID " + string(template_id));
        }
    }

    // 添加到全域列表
    array_push(global.player_monsters, m);
    show_debug_message("[Monster Data Manager] Monster added: UID=" + string(m.uid) + ", Name=" + m.name);

    // 廣播事件 (如果需要)
    // monster_data_manager_broadcast("monster_added", {uid: m.uid, monster: m});

    return m.uid;
}

// (可選) 直接添加已存在的 Struct (用於捕獲等場景)
/// @function add_player_monster(monster_struct)
/// @desc 直接添加一個已存在的怪物數據 Struct (會分配新 UID)
/// @param {Struct} monster_struct 包含怪物數據的 Struct
/// @returns {Real|Undefined} 新怪物的 UID 或 undefined (失敗時)
function add_player_monster(monster_struct) {
    if (!is_struct(monster_struct)) {
         show_debug_message("[Monster Data Manager] Error: Invalid data provided to add_player_monster.");
         return undefined;
    }
    // 分配新 UID
    monster_struct.uid = global.monster_uid_counter++;
    // 確保必要欄位存在 (可選)
    if (!variable_struct_exists(monster_struct, "hp")) monster_struct.hp = 1;
    if (!variable_struct_exists(monster_struct, "max_hp")) monster_struct.max_hp = 1;
    // ... 其他必要欄位檢查 ...

    array_push(global.player_monsters, monster_struct);
    show_debug_message("[Monster Data Manager] Monster added directly: UID=" + string(monster_struct.uid) + ", Name=" + (variable_struct_exists(monster_struct,"name")?monster_struct.name:"Unknown"));

    // 廣播事件 (如果需要)
    // monster_data_manager_broadcast("monster_added", {uid: monster_struct.uid, monster: monster_struct});

    return monster_struct.uid;
}

// =============================
// 4. 刪除怪物
// =============================
/// @function remove_monster(uid)
/// @desc 依 uid 刪除怪物
/// @returns {Bool} 是否成功刪除
function remove_monster(uid) {
    var index = get_monster_index_by_uid(uid);
    if (index != -1) {
        array_delete(global.player_monsters, index, 1);
        show_debug_message("[Monster Data Manager] Monster removed: UID=" + string(uid));
        // 廣播事件 (如果需要)
        // monster_data_manager_broadcast("monster_removed", {uid: uid});
        return true;
    }
    show_debug_message("[Monster Data Manager] Warning: Failed to remove monster. UID " + string(uid) + " not found.");
    return false;
}

// =============================
// 5. 修改屬性/升級/經驗
// =============================
/// @function add_experience(uid, experience)
/// @desc 增加經驗值並自動升級
/// @returns {Bool} 是否成功處理
function add_experience(uid, experience) {
    var m_ref = get_monster_by_uid(uid);
    if (is_undefined(m_ref)) {
        show_debug_message("[Monster Data Manager][LOG] add_experience: 未找到怪物 UID=" + string(uid));
        return false;
    }
    if (!variable_struct_exists(m_ref, "experience")) {
        m_ref.experience = 0;
        show_debug_message("[Monster Data Manager][LOG] add_experience: 怪物 UID=" + string(uid) + " 無 experience 欄位，已初始化為 0");
    }
    m_ref.experience += experience;
    show_debug_message("[Monster Data Manager][LOG] add_experience: 怪物 UID=" + string(uid) + " 當前經驗=" + string(m_ref.experience) + " (本次獲得=" + string(experience) + ")");

    // --- 恢復原有的 global.level_exp_map 檢查 --- (保留縮排)
    if (!variable_global_exists("level_exp_map")) {
        show_debug_message("[Monster Data Manager][LOG][DEBUG] Error: global.level_exp_map does not exist! Cannot process level up.");
        return false;
    }
    var level_exp_map = global.level_exp_map; // 取得引用
    // --- 加入 ds_map 類型檢查 (這是好的實踐，但不是原始碼的一部分，保留它) --- (保留縮排)
    if (!ds_exists(level_exp_map, ds_type_map)) {
        show_debug_message("[Monster Data Manager][LOG][DEBUG] Error: global.level_exp_map is not a valid ds_map!");
        return false;
    }

    if (!variable_struct_exists(m_ref, "level")) {
        m_ref.level = 1;
        show_debug_message("[Monster Data Manager][LOG] add_experience: 怪物 UID=" + string(uid) + " 無 level 欄位，已初始化為 1");
    }

    var leveled_up = false;
    var old_level = m_ref.level;

    // --- 保留加入的 Log 點 --- (保留縮排)
    show_debug_message("    [Monster Data Manager][LOG][DEBUG] 檢查升級條件：UID=" + string(uid) + ", 當前 Level=" + string(m_ref.level) + ", 當前 Exp=" + string(m_ref.experience));

    var required_exp = undefined; // 先設為 undefined
    if (ds_map_exists(level_exp_map, m_ref.level)) {
        required_exp = level_exp_map[? m_ref.level]; // <-- 使用 Map Accessor 讀取
        show_debug_message("        [Monster Data Manager][LOG][DEBUG] 等級 " + string(m_ref.level) + " 升級所需經驗 (從 Map 讀取): " + string(required_exp));
    } else {
        show_debug_message("        [Monster Data Manager][LOG][DEBUG] 在 level_exp_map 中找不到等級 " + string(m_ref.level) + " 的升級經驗！");
    }

    // --- 使用讀取到的值進行判斷 --- (保留縮排)
    if (!is_undefined(required_exp) && m_ref.experience >= required_exp) {
        show_debug_message("        [Monster Data Manager][LOG][DEBUG] 經驗值滿足升級條件，準備進入 while 迴圈...");
    } else {
        show_debug_message("        [Monster Data Manager][LOG][DEBUG] 經驗值 (" + string(m_ref.experience) + ") 未滿足升級條件 (" + string(required_exp) + ") 或所需經驗未定義。");
    }

    // --- 保持原有的 while 迴圈，但內部也加上 Log --- (保留縮排)
    while (!is_undefined(required_exp) && m_ref.experience >= required_exp) { // 條件也使用讀取的值
        show_debug_message("        [Monster Data Manager][LOG][DEBUG] 進入升級迴圈：扣除經驗 " + string(required_exp));
        m_ref.experience -= required_exp; // 使用讀取的值
        m_ref.level += 1;
        leveled_up = true;
        // 保留原有的升級訊息
        show_debug_message("        [Monster Data Manager][LOG] 怪物 UID=" + string(uid) + " 升級至 " + string(m_ref.level) + " 級 (原等級=" + string(old_level) + ")");

        // --- 更新下一次迴圈所需的經驗值 --- (保留縮排)
        old_level = m_ref.level - 1; // 更新舊等級記錄以供下次循環log
        if (ds_map_exists(level_exp_map, m_ref.level)) {
             required_exp = level_exp_map[? m_ref.level];
             show_debug_message("            [Monster Data Manager][LOG][DEBUG] 下一級 (" + string(m_ref.level) + ") 升級所需經驗: " + string(required_exp) + ", 剩餘經驗: " + string(m_ref.experience));
        } else {
             show_debug_message("            [Monster Data Manager][LOG][DEBUG] 找不到下一級 (" + string(m_ref.level) + ") 的升級經驗，跳出迴圈。");
             required_exp = undefined; // 設為 undefined 以跳出迴圈
        }

        // --- 屬性成長邏輯不變 --- (保留縮排)
        var template = get_template_by_id(m_ref.template_id);
        if (!is_undefined(template)) {
            var hp_base = variable_struct_get_or_default(template, "hp_base", 10);
            var hp_growth = variable_struct_get_or_default(template, "hp_growth", 1);
            m_ref.max_hp = ceil(hp_base + (hp_base * hp_growth * (m_ref.level - 1)));
            m_ref.hp = m_ref.max_hp;
            var attack_base = variable_struct_get_or_default(template, "attack_base", 5);
            var attack_growth = variable_struct_get_or_default(template, "attack_growth", 1);
            m_ref.attack = ceil(attack_base + (attack_base * attack_growth * (m_ref.level - 1)));
            var defense_base = variable_struct_get_or_default(template, "defense_base", 5);
            var defense_growth = variable_struct_get_or_default(template, "defense_growth", 1);
            m_ref.defense = ceil(defense_base + (defense_base * defense_growth * (m_ref.level - 1)));
            var spd_base = variable_struct_get_or_default(template, "spd_base", 5);
            var spd_growth = variable_struct_get_or_default(template, "spd_growth", 1);
            m_ref.spd = ceil(spd_base + (spd_base * spd_growth * (m_ref.level - 1)));
            // TODO: 處理技能解鎖
        } else {
            show_debug_message("        [Monster Data Manager][LOG] Warning: Template not found for ID " + string(m_ref.template_id) + ". Cannot apply stat growth.");
        }
    }

    // ... (廣播事件邏輯不變) ...
    if (leveled_up) {
        show_debug_message("    [Monster Data Manager][LOG] 準備發送 monster_leveled_up 事件: UID=" + string(uid) + ", old_level=" + string(old_level) + ", new_level=" + string(m_ref.level));
        if (is_undefined(monster_data_manager_broadcast)) {
            show_debug_message("    [Monster Data Manager][LOG] Warning: monster_data_manager_broadcast 未定義，無法廣播升級事件。");
        } else {
            monster_data_manager_broadcast("monster_leveled_up", {uid: uid, old_level: old_level, new_level: m_ref.level, monster: m_ref});
            show_debug_message("    [Monster Data Manager][LOG] 已發送 monster_leveled_up 事件: UID=" + string(uid) + ", new_level=" + string(m_ref.level));
        }
    } else { // <-- 如果迴圈從未執行
        show_debug_message("    [Monster Data Manager][LOG] 本次未升級，僅經驗變更: UID=" + string(uid) + ", level=" + string(m_ref.level) + ", exp=" + string(m_ref.experience));
    }

    return true;
}

/// @function add_experience_batch(uids, experience_array)
/// @desc 批次增加多隻怪物經驗值
/// @returns {Bool} 是否成功處理 (至少處理了一個)
function add_experience_batch(uids, experience_array) {
    if (!is_array(uids) || !is_array(experience_array) || array_length(uids) != array_length(experience_array)) {
        show_debug_message("[Monster Data Manager] Error: Invalid input for add_experience_batch.");
        return false;
    }

    var success = false;
    for (var j = 0; j < array_length(uids); ++j) {
        var uid = uids[j];
        var experience = experience_array[j];
        // 調用單個添加經驗的函數進行處理
        if (add_experience(uid, experience)) {
             success = true;
        }
    }
    return success;
}