// obj_enemy_placer - Create_0.gml
show_debug_message("[DEBUG] obj_enemy_placer Create Event - 開始");
// 這是一個編輯器工具物件，用於在房間編輯器中放置敵人

// 設置基本屬性（可在房間編輯器中修改）
template_id = 4001;          // 默認敵人模板ID (可在房間編輯器中覆蓋)
template_name = "未知敵人";   // 初始名稱（將從CSV更新）
sprite_index = Monster1;    // 默認精靈（將從CSV更新）
image_alpha = 0.8;           // 半透明

// 顯示模板ID的文字
draw_template_id = true;

// 在創建時獲取可用的模板列表
available_templates = [];
template_names = [];

// 更新模板信息
update_template_info = function(id) {
    show_debug_message("[DEBUG] update_template_info() - 開始, Pos: x=" + string(x) + ", y=" + string(y));
    // 尋找對應的模板索引
    var index = -1;
    for (var i = 0; i < array_length(available_templates); i++) {
        if (available_templates[i] == id) {
            index = i;
            break;
        }
    }
    
    // 如果找到了模板
    if (index != -1) {
        template_id = id;
        template_name = template_names[index];
        current_template_index = index;
        
        // 嘗試從工廠獲取精靈
        if (instance_exists(obj_enemy_factory)) {
            with (obj_enemy_factory) {
                var template = get_enemy_template(other.template_id);
                if (template != undefined && template.sprite_idle != -1) {
                    other.sprite_index = template.sprite_idle;
                }
            }
        }
    }
    show_debug_message("[DEBUG] update_template_info() - 結束, Pos: x=" + string(x) + ", y=" + string(y));
}

// 優先使用敵人工廠
show_debug_message("[DEBUG] Create Event - 檢查工廠前, Pos: x=" + string(x) + ", y=" + string(y));
if (instance_exists(obj_enemy_factory)) {
    with (obj_enemy_factory) {
        var key = ds_map_find_first(enemy_templates);
        while (!is_undefined(key)) {
            var template = enemy_templates[? key];
            array_push(other.available_templates, real(key));
            array_push(other.template_names, template.name);
            key = ds_map_find_next(enemy_templates, key);
        }
    }
    
    // 更新當前模板的信息
    if (array_length(available_templates) > 0) {
        show_debug_message("[DEBUG] Create Event - 準備調用 update_template_info (工廠存在)");
        update_template_info(template_id);
    }
} else {
    // 如果敵人工廠不存在，直接從CSV讀取
    show_debug_message("[DEBUG] Create Event - 準備調用 load_enemies_from_csv");
    load_enemies_from_csv();
}
show_debug_message("[DEBUG] Create Event - 工廠檢查後, Pos: x=" + string(x) + ", y=" + string(y));

// 從CSV文件加載敵人數據
load_enemies_from_csv = function() {
    show_debug_message("[DEBUG] load_enemies_from_csv() - 開始, Pos: x=" + string(x) + ", y=" + string(y));
    show_debug_message("從CSV加載敵人數據");
    
    // 清空現有數據
    available_templates = [];
    template_names = [];
    
    // 檢查CSV文件是否存在
    var csv_filename = "enemies.csv";
    if (!file_exists(csv_filename)) {
        csv_filename = working_directory + "datafiles/" + csv_filename;
        if (!file_exists(csv_filename)) {
            show_debug_message("錯誤：找不到enemies.csv文件");
            return false;
        }
    }
    
    // 讀取CSV文件
    var file = file_text_open_read(csv_filename);
    if (file == -1) {
        show_debug_message("錯誤：無法打開enemies.csv文件");
        return false;
    }
    
    // 跳過標題行
    var header = file_text_read_string(file);
    file_text_readln(file);
    
    // 讀取每一行
    while (!file_text_eof(file)) {
        var line = file_text_read_string(file);
        file_text_readln(file);
        
        // 解析CSV行
        var data = string_split(line, ",");
        if (array_length(data) >= 3) { // 確保至少有ID和名稱
            var enemy_id = real(data[0]);
            var enemy_name = data[1];
            
            // 添加到可用模板
            array_push(available_templates, enemy_id);
            array_push(template_names, enemy_name);
            
            // 如果這是當前選擇的模板，更新信息
            if (enemy_id == template_id) {
                template_name = enemy_name;
                // 尋找精靈索引
                if (array_length(data) >= 16) { // sprite_idle位於索引15
                    var sprite_name = data[15];
                    if (sprite_name != "") {
                        var spr = asset_get_index(sprite_name);
                        if (spr != -1) sprite_index = spr;
                    }
                }
            }
        }
    }
    
    file_text_close(file);
    show_debug_message("從CSV載入了 " + string(array_length(available_templates)) + " 個敵人模板");
    show_debug_message("[DEBUG] load_enemies_from_csv() - 結束, Pos: x=" + string(x) + ", y=" + string(y));
    return true;
}

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

// 【新增】先定義響應事件的方法
on_managers_initialized = function(data) {
    show_debug_message("[DEBUG] obj_enemy_placer (ID: " + string(id) + ") 收到 managers_initialized 事件"); // 添加 ID
    convert_to_real_enemy();
}

// 取消 Alarm 設置
// alarm[0] = 2; // 延遲2幀後轉換，確保敵人工廠已經創建

// 然後再訂閱管理器初始化完成事件
if (instance_exists(obj_event_manager)) {
    with (obj_event_manager) {
        subscribe_to_event("managers_initialized", other.id, "on_managers_initialized");
    }
    show_debug_message("[DEBUG] obj_enemy_placer 已訂閱 managers_initialized 事件");
} else {
    show_debug_message("[ERROR] obj_enemy_placer 無法訂閱事件，事件管理器不存在！將嘗試使用 Alarm 作為備用。");
    alarm[0] = 5; // 設置一個稍長的 Alarm 作為備用
}

// 轉換為真正的敵人
convert_to_real_enemy = function() {
    show_debug_message("[DEBUG] convert_to_real_enemy() - 開始執行 (ID: " + string(id) + ", Template: " + string(template_id) + ", Pos: " + string(x) + "," + string(y) + ")");
    if (converted) {
        show_debug_message("[DEBUG] convert_to_real_enemy() - 已轉換，提前退出");
        return; // 防止重複轉換
    }
    converted = true;
    
    // 確保敵人工廠存在
    if (!instance_exists(obj_enemy_factory)) {
        show_debug_message("[DEBUG] convert_to_real_enemy() - 敵人工廠不存在，創建一個");
        instance_create_layer(0, 0, "Controllers", obj_enemy_factory);
        // 注意：這裡創建的工廠可能未經初始化，後續調用可能失敗
    }
    
    // 使用敵人工廠創建真正的敵人
    var real_enemy = noone;
    show_debug_message("[DEBUG] convert_to_real_enemy() - 準備調用工廠創建...");
    if (instance_exists(obj_enemy_factory)) { // 再次檢查以防萬一
        with (obj_enemy_factory) {
            show_debug_message("    [Factory Context] 調用 create_enemy_instance (ID: " + string(other.template_id) + ", Pos: " + string(other.x) + "," + string(other.y) + ", Level: " + string(other.enemyLevel) + ")");
            real_enemy = create_enemy_instance(other.template_id, other.x, other.y, other.enemyLevel);
        }
    } else {
        show_debug_message("[DEBUG] convert_to_real_enemy() - 調用工廠前發現工廠仍不存在!");
    }
    show_debug_message("[DEBUG] convert_to_real_enemy() - 工廠創建返回值: " + string(real_enemy)); // 打印返回值
    
    // 如果創建成功，銷毀放置器
    if (real_enemy != noone) {
        show_debug_message("[DEBUG] convert_to_real_enemy() - 工廠創建成功 (ID: " + string(real_enemy) + ")，銷毀放置器 (ID: " + string(id) + ")");
        instance_destroy();
    } else {
        show_debug_message("[DEBUG] convert_to_real_enemy() - 工廠創建失敗，嘗試備用創建 obj_test_enemy...");
        // 如果工廠創建失敗，使用備用方法
        var enemy = instance_create_layer(x, y, "Instances", obj_test_enemy);
        show_debug_message("[DEBUG] convert_to_real_enemy() - 備用創建返回值: " + string(enemy)); // 打印備用創建返回值
        
        if (instance_exists(enemy)) { // 檢查是否成功創建
             show_debug_message("[DEBUG] convert_to_real_enemy() - 成功創建備用 obj_test_enemy (ID: " + string(enemy) + ")");
             with (enemy) {
                 template_id = other.template_id; 
                 level = other.enemyLevel; // 備用創建時也設置 level
                 // 最好也調用 initialize
                 if (variable_instance_exists(id, "initialize")) {
                     initialize();
                 }
             }
             show_debug_message("[DEBUG] convert_to_real_enemy() - 備用創建成功後，銷毀放置器 (ID: " + string(id) + ")");
             instance_destroy(); // 銷毀放置器
        } else {
            show_debug_message("[ERROR] convert_to_real_enemy() - 連備用 obj_test_enemy 都無法創建! 放置器 (ID: " + string(id) + ") 將殘留。");
            converted = false; // 重置轉換狀態
            show_debug_message("[ERROR] convert_to_real_enemy() - 連備用 obj_test_enemy 都無法創建!");
            converted = false; // 重置轉換狀態，也許可以重試？
        }
    }
}

// 初始化
// 更新初始模板信息
show_debug_message("[DEBUG] Create Event - 更新初始模板信息前, Pos: x=" + string(x) + ", y=" + string(y));
if (array_length(available_templates) > 0) {
    show_debug_message("[DEBUG] Create Event - 準備調用 update_template_info (初始化)");
    update_template_info(template_id);
} 
show_debug_message("[DEBUG] Create Event - 更新初始模板信息後, Pos: x=" + string(x) + ", y=" + string(y));

// 在 Create 事件結束前打印座標
show_debug_message("[DEBUG] obj_enemy_placer Create Event - 最終結束, Pos: x=" + string(x) + ", y=" + string(y)); 