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
    m.id = template.id;
    m.name = variable_struct_exists(template, "name") ? template.name : "Unknown";
    m.type = variable_struct_exists(template, "type") ? template.type : 0; // 假設 0 是預設 type
    m.level = level;
    // 計算屬性 (確保模板中有這些欄位)
    var hp_base = variable_struct_exists(template, "hp_base") ? template.hp_base : 10;
    var hp_growth = variable_struct_exists(template, "hp_growth") ? template.hp_growth : 1;
    m.max_hp = hp_base + hp_growth * (level - 1);
    m.hp = m.max_hp; // 新怪物滿血
    var attack_base = variable_struct_exists(template, "attack_base") ? template.attack_base : 5;
    var attack_growth = variable_struct_exists(template, "attack_growth") ? template.attack_growth : 1;
    m.attack = attack_base + attack_growth * (level - 1);
    var defense_base = variable_struct_exists(template, "defense_base") ? template.defense_base : 5;
    var defense_growth = variable_struct_exists(template, "defense_growth") ? template.defense_growth : 1;
    m.defense = defense_base + defense_growth * (level - 1);
    var spd_base = variable_struct_exists(template, "spd_base") ? template.spd_base : 5;
    var spd_growth = variable_struct_exists(template, "spd_growth") ? template.spd_growth : 1;
    m.spd = spd_base + spd_growth * (level - 1);
    m.experience = 0; // 新怪物經驗為 0
    m.skills = []; // 技能列表
    m.display_sprite = asset_get_index(variable_struct_exists(template, "sprite_idle") ? template.sprite_idle : "spr_default"); // 確保有預設 Sprite
    // 技能解鎖
    if (variable_struct_exists(template, "skills") && variable_struct_exists(template, "skill_unlock_levels")) {
        // 確保分割函數存在且安全
        var skill_ids_str = variable_struct_exists(template, "skills") ? template.skills : "";
        var unlock_lvls_str = variable_struct_exists(template, "skill_unlock_levels") ? template.skill_unlock_levels : "";
        // TODO: 替換為更安全的分割函數 scr_string_split 或類似功能
        var skill_ids = string_split(skill_ids_str, ";");
        var unlock_lvls = string_split(unlock_lvls_str, ";");
        if (array_length(skill_ids) == array_length(unlock_lvls)) {
            for (var i = 0; i < array_length(skill_ids); ++i) {
                // 使用 is_numeric_safe 或類似函數進行安全轉換
                var unlock_level = real(unlock_lvls[i]); // 假設 is_numeric_safe 已檢查
                var skill_id = real(skill_ids[i]);     // 假設 is_numeric_safe 已檢查
                if (level >= unlock_level) {
                     array_push(m.skills, skill_id);
                }
            }
        } else {
             show_debug_message("[Monster Data Manager] Warning: Mismatched skills and unlock levels for template ID " + string(template_id));
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
    // 獲取怪物 Struct 的引用
    var m_ref = get_monster_by_uid(uid);
    if (is_undefined(m_ref)) return false; // 未找到怪物

    // 確保 experience 欄位存在
    if (!variable_struct_exists(m_ref, "experience")) {
        m_ref.experience = 0; // 如果不存在則初始化
    }
    m_ref.experience += experience;

    // 依賴 global.level_exp_map
    if (!variable_global_exists("level_exp_map")) {
        show_debug_message("[Monster Data Manager] Error: global.level_exp_map does not exist! Cannot process level up.");
        return false; // 無法處理升級
    }
    var level_exp_map = global.level_exp_map; // 假設已載入

    // 處理升級 (確保 level 欄位存在)
    if (!variable_struct_exists(m_ref, "level")) {
        m_ref.level = 1; // 如果不存在則初始化
    }

    var leveled_up = false;
    // 檢查是否達到最大等級 (假設 level_exp_map 的長度代表最大等級 + 1)
    while (m_ref.level < array_length(level_exp_map) && m_ref.experience >= level_exp_map[m_ref.level]) {
        m_ref.experience -= level_exp_map[m_ref.level];
        m_ref.level += 1;
        leveled_up = true;
        show_debug_message("[Monster Data Manager] Monster UID " + string(uid) + " leveled up to " + string(m_ref.level));

        // 屬性成長 (需要怪物模板)
        var template = get_template_by_id(m_ref.id); // 假設怪物 struct 中有 id 欄位
        if (!is_undefined(template)) {
            // 安全地更新屬性
            var hp_base = variable_struct_exists(template, "hp_base") ? template.hp_base : 10;
            var hp_growth = variable_struct_exists(template, "hp_growth") ? template.hp_growth : 1;
            m_ref.max_hp = hp_base + hp_growth * (m_ref.level - 1);
            m_ref.hp = m_ref.max_hp; // 升級補滿血

            var attack_base = variable_struct_exists(template, "attack_base") ? template.attack_base : 5;
            var attack_growth = variable_struct_exists(template, "attack_growth") ? template.attack_growth : 1;
            m_ref.attack = attack_base + attack_growth * (m_ref.level - 1);

            var defense_base = variable_struct_exists(template, "defense_base") ? template.defense_base : 5;
            var defense_growth = variable_struct_exists(template, "defense_growth") ? template.defense_growth : 1;
            m_ref.defense = defense_base + defense_growth * (m_ref.level - 1);

            var spd_base = variable_struct_exists(template, "spd_base") ? template.spd_base : 5;
            var spd_growth = variable_struct_exists(template, "spd_growth") ? template.spd_growth : 1;
            m_ref.spd = spd_base + spd_growth * (m_ref.level - 1);

            // TODO: 處理技能解鎖
            // ...

        } else {
            show_debug_message("[Monster Data Manager] Warning: Template not found for ID " + string(m_ref.id) + ". Cannot apply stat growth.");
        }
    }

    // 因為 m_ref 是引用，修改已直接生效於 global.player_monsters 中的 Struct
    // 不需要 global.player_monsters[i] = m;

    if (leveled_up) {
        // 廣播事件 (如果需要)
        // monster_data_manager_broadcast("monster_leveled_up", {uid: uid, monster: m_ref});
    } else {
         // 廣播經驗值變更事件 (如果需要)
         // monster_data_manager_broadcast("monster_exp_changed", {uid: uid, monster: m_ref});
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