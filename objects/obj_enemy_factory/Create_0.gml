// obj_enemy_factory - Create_0.gml
show_debug_message("===== 敵人工廠初始化開始 =====");

// 敵人模板庫
enemy_templates = ds_map_create();

// 初始化敵人庫
initialize = function() {
    show_debug_message("初始化敵人模板庫");
    
    // 訂閱相關事件
    if (instance_exists(obj_event_manager)) {
        with (obj_event_manager) {
            subscribe_to_event("game_save", other.id, "on_game_save");
            subscribe_to_event("game_load", other.id, "on_game_load");
        }
        show_debug_message("已訂閱相關事件");
    } else {
        show_debug_message("警告：事件管理器不存在，無法訂閱事件");
    }
    
    // 嘗試從CSV載入敵人數據
    var csv_loaded = load_enemies_from_csv("enemies.csv");
    
    // 如果CSV載入失敗，顯示錯誤並停止遊戲
    if (!csv_loaded) {
        show_error("嚴重錯誤：無法載入敵人數據 'enemies.csv'！遊戲無法繼續。", true);
    }
    
    show_debug_message("敵人工廠初始化完成，共 " + string(ds_map_size(enemy_templates)) + " 個敵人模板");
}

// 註冊單個敵人模板
register_enemy_template = function(enemy_id, template_data) {
    if (ds_map_exists(enemy_templates, enemy_id)) {
        show_debug_message("警告：重複註冊敵人模板 ID: " + string(enemy_id));
        return false;
    }
    
    ds_map_add(enemy_templates, enemy_id, template_data);
    show_debug_message("註冊敵人模板: " + string(enemy_id) + " - " + template_data.name);
    return true;
}

// 根據ID獲取敵人模板
get_enemy_template = function(enemy_id) {
    if (!ds_map_exists(enemy_templates, enemy_id)) {
        show_debug_message("錯誤：嘗試獲取不存在的敵人模板 ID: " + string(enemy_id));
        return undefined;
    }
    
    var template_to_return = enemy_templates[? enemy_id];
    
    // === 新增除錯：打印將要返回的模板結構 ===
    // show_debug_message("[get_enemy_template] Returning template for ID " + string(enemy_id) + ": " + json_stringify(template_to_return));
    // === 除錯結束 ===
    
    return template_to_return;
}

// 創建敵人實例
create_enemy_instance = function(_enemy_id, _x_pos, _y_pos, _level_param) {
    show_debug_message("--- [Factory] create_enemy_instance 開始 --- ");
    show_debug_message("    傳入參數: _enemy_id=" + string(_enemy_id) + ", _x=" + string(_x_pos) + ", _y=" + string(_y_pos) + ", _level_param=" + (argument_count > 3 ? string(_level_param) : "未提供"));
    
    // 獲取模板
    var template = get_enemy_template(_enemy_id);
    if (template == undefined) {
        show_debug_message("    [Factory] 錯誤：無法獲取模板 ID: " + string(_enemy_id));
        show_debug_message("--- [Factory] create_enemy_instance 結束 (模板錯誤) ---");
        return noone;
    }
    show_debug_message("    [Factory] 成功獲取模板: " + template.name);
    
    // 使用 obj_test_enemy 作為基礎敵人類型
    var obj_type = obj_test_enemy; 
    show_debug_message("    [Factory] 準備創建物件類型: " + object_get_name(obj_type));
    
    // 創建實例
    show_debug_message("    [Factory] 執行 instance_create_layer...");
    var inst = instance_create_layer(_x_pos, _y_pos, "Instances", obj_type);
    show_debug_message("    [Factory] instance_create_layer 完成，返回實例 ID: " + string(inst));
    
    // 初始化敵人數據
    if (instance_exists(inst)) {
        show_debug_message("    [Factory] 實例存在，進入 with(inst) 區塊...");
        with (inst) {
            show_debug_message("        [Factory with(inst)] 開始設置... 當前實例 ID: " + string(id));
            // 工廠仍然需要傳遞 template_id，以便 initialize 函數能正確讀取
            show_debug_message("        [Factory with(inst)] 準備設置 template_id = " + string(_enemy_id)); // 檢查這裡的 _enemy_id
            template_id = _enemy_id;
            show_debug_message("        [Factory with(inst)] 實際設置後 template_id = " + string(template_id));
            
            // 工廠可以選擇性地傳遞 level_param 來覆蓋模板等級
            var _actual_level = template.level;
            if (argument_count > 3 && _level_param != undefined && _level_param > 0) { // 檢查 level_param 是否有效傳入
                show_debug_message("        [Factory with(inst)] 使用傳入的 _level_param: " + string(_level_param));
                _actual_level = _level_param;
            }
            show_debug_message("        [Factory with(inst)] 準備設置 level = " + string(_actual_level));
            level = _actual_level; // 確保 level 被正確設置
            show_debug_message("        [Factory with(inst)] 實際設置後 level = " + string(level));

            // 直接調用目標實例的 initialize 函數
            show_debug_message("        [Factory with(inst)] 準備直接調用 inst.initialize()...");
            if (variable_instance_exists(id, "initialize")) { // 仍然檢查一下函數是否存在
                 initialize(); // 直接調用，因為我們在 with(inst) 內
                 show_debug_message("        [Factory with(inst)] inst.initialize() 調用完成。");
            } else {
                 show_debug_message("        [Factory with(inst)] 錯誤：inst.initialize 不存在!");
            }
            
            show_debug_message("        [Factory with(inst)] with 區塊結束。");

            // 以下大部分屬性設置已移至 obj_test_enemy 的 initialize 函數中處理
            // name = template.name; 
            // max_hp = ceil(...);
            // hp = max_hp;
            // attack = ceil(...);
            // defense = ceil(...);
            // spd = ceil(...);
            // is_capturable = template.capturable;
            // capture_rate = template.capture_rate_base;
            // if (template.sprite_idle != -1) sprite_index = template.sprite_idle;
            // team = 1;
            // enemy_category = template.category;
            // enemy_rank = template.rank;
            // 清空/添加技能的邏輯...
            // drop_items = ...;
            // exp_reward = template.exp_reward;
            // gold_reward = template.gold_reward;
            // ai_type = template.ai_type;
        }
        
        show_debug_message("    [Factory] 成功創建敵人 (使用 obj_test_enemy): " + string(inst) + " - " + template.name + " (ID:" + string(_enemy_id) + ")");
        show_debug_message("--- [Factory] create_enemy_instance 結束 (成功) ---");
        return inst;
    } else {
        show_debug_message("    [Factory] 錯誤：instance_create_layer 後實例不存在!");
    }
    
    show_debug_message("    [Factory] 錯誤：無法創建敵人實例");
    show_debug_message("--- [Factory] create_enemy_instance 結束 (失敗) ---");
    return noone;
}

// 計算生成位置 - 徹底重構避免內建變數衝突
calculate_spawn_position = function(_pattern, _ind, _tot, _cx, _cy) {
    // 創建返回結構
    var _result = { 
        x: _cx, 
        y: _cy 
    };
    
    // 基本半徑
    var _rad = 64;
    
    // 根據模式計算位置
    if (_pattern == SPAWN_PATTERN.CIRCLE) {
        // 圓形陣型
        var _ang = (360 / _tot) * _ind;
        _result.x = _cx + lengthdir_x(_rad, _ang);
        _result.y = _cy + lengthdir_y(_rad, _ang);
    }
    else if (_pattern == SPAWN_PATTERN.GRID) {
        // 網格陣型
        var _r = floor(_ind / 3);
        var _c = _ind % 3;
        _result.x = _cx + (_c - 1) * _rad;
        _result.y = _cy + _r * _rad;
    }
    else if (_pattern == SPAWN_PATTERN.TRIANGLE) {
        // 三角陣型
        var _rows = ceil(sqrt(_tot * 2));
        var _crow = 0;
        var _prow = 0;
        var _counter = 0;
        
        // 確定當前行和行中位置
        for (var _r = 0; _r < _rows; _r++) {
            for (var _p = 0; _p <= _r; _p++) {
                if (_counter == _ind) {
                    _crow = _r;
                    _prow = _p;
                    break;
                }
                _counter++;
            }
            if (_counter > _ind) break;
        }
        
        _result.x = _cx + (_prow - _crow/2) * _rad;
        _result.y = _cy + _crow * _rad * 0.8;
    }
    else if (_pattern == SPAWN_PATTERN.V_FORMATION) {
        // V字陣型
        var _side = (_ind % 2 == 0) ? -1 : 1;
        var _depth = floor(_ind / 2);
        var _angle = 30; // V形的角度
        
        _result.x = _cx + lengthdir_x(_rad * _depth, 90 + _angle * _side);
        _result.y = _cy + lengthdir_y(_rad * _depth, 90 + _angle * _side);
    }
    else {
        // 隨機或默認
        var _angle = random(360);
        var _dist = random_range(_rad * 0.5, _rad);
        _result.x = _cx + lengthdir_x(_dist, _angle);
        _result.y = _cy + lengthdir_y(_dist, _angle);
    }
    
    return _result;
}

// 生成敵人群組
generate_enemy_group = function(leader_id, center_x, center_y, level_param) {
    var template = get_enemy_template(leader_id);
    if (template == undefined) {
        show_debug_message("錯誤：無法生成敵人群組，首領模板不存在: " + string(leader_id));
        return [];
    }
    
    var generated_enemies = [];
    
    // 創建首領敵人
    var leader = create_enemy_instance(leader_id, center_x, center_y, level_param);
    if (leader != noone) {
        array_push(generated_enemies, leader);
    } else {
        show_debug_message("錯誤：無法創建群組首領");
        return [];
    }
    
    // 決定是否生成額外敵人
    if (template.is_pack_leader && array_length(template.companions) > 0) {
        var companion_count = irandom_range(template.pack_min, template.pack_max);
        
        for (var i = 0; i < companion_count; i++) {
            // 選擇同伴類型
            var companion_id = leader_id; // 預設使用相同類型
            
            // 如果有指定同伴，使用權重系統選擇
            if (array_length(template.companions) > 0) {
                var total_weight = 0;
                for (var c = 0; c < array_length(template.companions); c++) {
                    total_weight += template.companions[c].weight;
                }
                
                var roll = random(total_weight);
                var current_weight = 0;
                
                for (var c = 0; c < array_length(template.companions); c++) {
                    current_weight += template.companions[c].weight;
                    if (roll < current_weight) {
                        companion_id = template.companions[c].id;
                        break;
                    }
                }
            }
            
            // 計算生成位置
            var pos = calculate_spawn_position(
                template.pack_pattern,
                i,
                companion_count,
                center_x,
                center_y
            );
            
            // 創建同伴實例
            var companion_level = max(1, level_param - irandom_range(0, 2)); // 同伴比首領弱一些
            var companion = create_enemy_instance(companion_id, pos.x, pos.y, companion_level);
            
            if (companion != noone) {
                array_push(generated_enemies, companion);
            }
        }
    }
    
    show_debug_message("生成敵人群組完成，共 " + string(array_length(generated_enemies)) + " 個敵人");
    return generated_enemies;
}

// 事件處理函數
on_game_save = function(data) {
    // 遊戲保存時的處理（如果需要）
}

on_game_load = function(data) {
    // 遊戲載入時的處理（如果需要）
}

// 清理資源
cleanup = function() {
    show_debug_message("清理敵人工廠資源");
    if (ds_exists(enemy_templates, ds_type_map)) {
        ds_map_destroy(enemy_templates);
    }
}

// 從CSV載入敵人數據
load_enemies_from_csv = function(file_name) {
    show_debug_message("===== 開始從CSV載入敵人數據 =====");
    show_debug_message("文件名: " + file_name);
    
    // 載入CSV
    var grid = load_csv(file_name);
    if (grid == -1) {
        show_debug_message("無法載入CSV文件，使用備用敵人數據");
        return false;
    }
    
    // 讀取列數和行數
    var columns = ds_grid_width(grid);
    var rows = ds_grid_height(grid);
    
    show_debug_message("CSV讀取成功：" + string(rows - 1) + " 行敵人數據 (共 " + string(columns) + " 列)");
    
    // 逐行處理，跳過標題行
    var success_count = 0;
    for (var i = 1; i < rows; i++) {
        // 創建敵人數據結構
        var enemy_data = create_enemy_base_data();
        
        // 讀取基本屬性
        enemy_data.id = real(csv_grid_get(grid, "id", i));
        enemy_data.name = csv_grid_get(grid, "name", i);
        enemy_data.category = real(csv_grid_get(grid, "category", i));
        enemy_data.family = csv_grid_get(grid, "family", i);
        enemy_data.variant = csv_grid_get(grid, "variant", i);
        enemy_data.rank = real(csv_grid_get(grid, "rank", i));
        enemy_data.level = real(csv_grid_get(grid, "level", i));
        
        // 讀取基本屬性值
        enemy_data.hp_base = real(csv_grid_get(grid, "hp_base", i));
        enemy_data.attack_base = real(csv_grid_get(grid, "attack_base", i));
        enemy_data.defense_base = real(csv_grid_get(grid, "defense_base", i));
        enemy_data.speed_base = real(csv_grid_get(grid, "speed_base", i));
        
        // 讀取成長係數
        enemy_data.hp_growth = real(csv_grid_get(grid, "hp_growth", i));
        enemy_data.attack_growth = real(csv_grid_get(grid, "attack_growth", i));
        enemy_data.defense_growth = real(csv_grid_get(grid, "defense_growth", i));
        enemy_data.speed_growth = real(csv_grid_get(grid, "speed_growth", i));
        
        // 讀取精靈
        var sprite_idle_name = csv_grid_get(grid, "sprite_idle", i);
        var sprite_move_name = csv_grid_get(grid, "sprite_move", i);
        var sprite_attack_name = csv_grid_get(grid, "sprite_attack", i);
        
        if (sprite_idle_name != "") enemy_data.sprite_idle = asset_get_index(sprite_idle_name);
        if (sprite_move_name != "") enemy_data.sprite_move = asset_get_index(sprite_move_name);
        if (sprite_attack_name != "") enemy_data.sprite_attack = asset_get_index(sprite_attack_name);
        
        // 讀取群組信息
        enemy_data.is_pack_leader = bool(csv_grid_get(grid, "is_pack_leader", i));
        enemy_data.pack_min = real(csv_grid_get(grid, "pack_min", i));
        enemy_data.pack_max = real(csv_grid_get(grid, "pack_max", i));
        
        // 讀取生成模式
        var pattern_str = csv_grid_get(grid, "pack_pattern", i);
        if (pattern_str != "") {
            switch(string_lower(pattern_str)) {
                case "circle": enemy_data.pack_pattern = SPAWN_PATTERN.CIRCLE; break;
                case "grid": enemy_data.pack_pattern = SPAWN_PATTERN.GRID; break;
                case "triangle": enemy_data.pack_pattern = SPAWN_PATTERN.TRIANGLE; break;
                case "v_formation": enemy_data.pack_pattern = SPAWN_PATTERN.V_FORMATION; break;
                default: enemy_data.pack_pattern = SPAWN_PATTERN.RANDOM; break;
            }
        }
        
        // 讀取同伴列表
        var companions_str = csv_grid_get(grid, "companions", i);
        enemy_data.companions = [];
        
        if (companions_str != "") {
            var companions_array = string_split(companions_str, ";");
            for (var c = 0; c < array_length(companions_array); c++) {
                var companion_data = string_split(companions_array[c], ":");
                if (array_length(companion_data) >= 2) {
                    array_push(enemy_data.companions, {
                        id: real(companion_data[0]),
                        weight: real(companion_data[1])
                    });
                }
            }
        }
        
        // 讀取掉落表
        var loot_str = csv_grid_get(grid, "loot_table", i);
        enemy_data.loot_table = [];
        
        if (loot_str != "") {
            var loot_array = string_split(loot_str, ";");
            for (var l = 0; l < array_length(loot_array); l++) {
                var loot_data = string_split(loot_array[l], ":");
                if (array_length(loot_data) >= 3) {
                    var quantity_range = string_split(loot_data[2], "-");
                    var min_qty = 1;
                    var max_qty = 1;
                    
                    if (array_length(quantity_range) >= 2) {
                        min_qty = real(quantity_range[0]);
                        max_qty = real(quantity_range[1]);
                    } else if (array_length(quantity_range) == 1) {
                        min_qty = max_qty = real(quantity_range[0]);
                    }
                    
                    array_push(enemy_data.loot_table, {
                        item_id: real(loot_data[0]),
                        chance: real(loot_data[1]),
                        quantity: [min_qty, max_qty]
                    });
                }
            }
        }
        
        // 讀取AI和戰鬥屬性
        enemy_data.ai_type = real(csv_grid_get(grid, "ai_type", i));
        enemy_data.attack_range = real(csv_grid_get(grid, "attack_range", i));
        enemy_data.aggro_range = real(csv_grid_get(grid, "aggro_range", i));
        enemy_data.attack_interval = real(csv_grid_get(grid, "attack_interval", i));
        
        // 讀取捕獲相關
        enemy_data.capturable = bool(csv_grid_get(grid, "capturable", i));
        enemy_data.capture_rate_base = real(csv_grid_get(grid, "capture_rate_base", i));
        
        // 讀取獎勵
        var raw_exp = csv_grid_get(grid, "exp_reward", i);
        var raw_gold = csv_grid_get(grid, "gold_reward", i);
        // show_debug_message("  Row " + string(i) + " Enemy " + string(enemy_data.id) + ": Raw exp_reward='" + string(raw_exp) + "', Raw gold_reward='" + string(raw_gold) + "'");
        
        enemy_data.exp_reward = real(raw_exp); // Keep using real() for now
        enemy_data.gold_reward = real(raw_gold);
        // show_debug_message("  Row " + string(i) + " Enemy " + string(enemy_data.id) + ": Parsed exp=" + string(enemy_data.exp_reward) + ", Parsed gold=" + string(enemy_data.gold_reward));
        
        // 讀取技能
        var skills_str = csv_grid_get(grid, "skills", i);
        var skills_unlock_str = csv_grid_get(grid, "skill_unlock_levels", i);
        
        enemy_data.skills = [];
        if (skills_str != "") {
            enemy_data.skills = string_split(skills_str, ";");
            // 可以考慮在這裡也對技能ID進行trim
            for (var sk = 0; sk < array_length(enemy_data.skills); sk++) {
                enemy_data.skills[@ sk] = string_trim(enemy_data.skills[sk]);
            }
        }
        
        enemy_data.skill_unlock_levels = [];
        if (skills_unlock_str != "") {
            var skill_levels = string_split(skills_unlock_str, ";");
            for (var s = 0; s < array_length(skill_levels); s++) {
                // 修正：在轉換為real之前trim空格
                var level_str = string_trim(skill_levels[s]);
                if (level_str != "") { // 確保不是空字符串
                    array_push(enemy_data.skill_unlock_levels, real(level_str));
                } else {
                    show_debug_message("警告：在行 " + string(i) + " 的 skill_unlock_levels 中發現空值");
                }
            }
        }
        
        // 註冊敵人模板
        var success = register_enemy_template(enemy_data.id, enemy_data);
        if (success) success_count++;
    }
    
    // 清理網格
    ds_grid_destroy(grid);
    
    show_debug_message("成功載入 " + string(success_count) + " 個敵人模板");
    show_debug_message("===== 敵人CSV載入完成 =====");
    return (success_count > 0);
}

// 執行初始化
initialize();

show_debug_message("===== 敵人工廠初始化完成 ====="); 