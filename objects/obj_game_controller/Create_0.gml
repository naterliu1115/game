// obj_game_controller - Create_0.gml

// 初始化全局調試模式變數
if (!variable_global_exists("game_debug_mode")) {
    global.game_debug_mode = false; // 預設關閉調試模式
}

show_debug_message("目前玩家金錢：" + string(global.player_gold));


// UI控制變量
ui_enabled = true;  // 控制UI是否可用
ui_cooldown = 0;    // UI操作冷卻時間
active = false; // 或根據需要設定其他初始值
info_alpha = 1.0; // 初始化信息透明度
info_text = ""; // 初始化為空字串
global.info_timer = 0;  // UI 信息顯示相關變數
// 在Create事件中添加這兩個變數宣告
ui_x = 0;
ui_y = 0;

cancel_btn_x = 0;
cancel_btn_y = 0;
capture_animation = 0;
capture_btn_x = 0;
capture_btn_y = 0;
ui_surface = -1;

// 確保UI管理器存在
if (!instance_exists(obj_ui_manager)) {
    instance_create_layer(0, 0, "Instances", obj_ui_manager);
}

// 確保道具管理器存在
if (!instance_exists(obj_item_manager)) {
    instance_create_layer(0, 0, "Instances", obj_item_manager);
}

// 創建並註冊主介面 HUD
if (!instance_exists(obj_main_hud)) {
    var hud_inst = instance_create_layer(0, 0, "Instances", obj_main_hud);
    if (instance_exists(obj_ui_manager)) {
        with (obj_ui_manager) {
            register_ui(hud_inst, "main");
            show_ui(hud_inst, "main");
        }
    }
    show_debug_message("主介面 HUD 已創建並註冊");
}

// 初始化全局道具相關變量
if (!variable_global_exists("player_inventory")) {
    global.player_inventory = ds_list_create();
    // 預設道具初始化（只在遊戲啟動時加入一次）
    if (instance_exists(obj_item_manager)) {
        with (obj_item_manager) {
            add_item_to_inventory(1001, 5);  // 小型回復藥水
            add_item_to_inventory(1002, 3);  // 中型回復藥水
            add_item_to_inventory(1003, 1);  // 大型回復藥水
            add_item_to_inventory(2001, 1);  // 銅劍
            add_item_to_inventory(2002, 1);  // 鐵劍
            add_item_to_inventory(3001, 10); // 普通球
            add_item_to_inventory(3002, 5);  // 高級球
            add_item_to_inventory(4001, 20); // 銅礦石
            add_item_to_inventory(4002, 10); // 鐵礦石
            add_item_to_inventory(5001, 1);  // 採礦稿
        }
    }
}

// 添加缺失的变量初始化 - 解决警告
info_timer = 0;
open_animation = 0;
selected_monster = noone;
surface_needs_update = false;
details_needs_update = false;
ui_functions_initialized = false;

// 捕获系统相关变量
capture_chance = 0;
capture_methods = []; // 改为数组
capture_state = 0;
selected_method = 0;
target_enemy = noone;
ui_width = 300;
ui_height = 200;

// 初始化全局字體
function init_fonts() {
    // 檢查字體資源是否存在
    if (font_exists(fnt_dialogue)) {
        global.font_dialogue = fnt_dialogue;
        show_debug_message("成功初始化對話字體: fnt_dialogue");
    } else {
        global.font_dialogue = -1; // 使用默認字體
        show_debug_message("警告: 找不到對話字體資源 fnt_dialogue，使用默認字體");
    }

    // 您可以在這裡添加更多字體
    // global.font_title = fnt_title;
    // global.font_button = fnt_button;
    // 等等...

    // 設置默認字體
    draw_set_font(global.font_dialogue);
}

// 調用字體初始化
init_fonts();


// 設置調試模式
global.game_debug_mode = true; // 開發時為 true，發布時設為 false

// 在 obj_game_controller 或 obj_resource_manager 的 Create 事件中
function init_resources() {
    // 創建資源映射表
    global.resource_map = ds_map_create();

    // 檢查關鍵精靈是否存在
    var resource_list = [
        "spr_star",
        "spr_player",
        "spr_enemy",
        // 添加更多精靈...
    ];

    for (var i = 0; i < array_length(resource_list); i++) {
        var res_name = resource_list[i];
        var res_index = asset_get_index(res_name);

        if (res_index != -1 && sprite_exists(res_index)) {
            ds_map_add(global.resource_map, res_name, res_index);
        } else {
            show_debug_message("警告：資源 " + res_name + " 不存在！");
            // 可以加載替代資源或使用占位符
        }
    }
}

// 調用初始化
init_resources();


// 初始化全局變量
global.in_battle = false;      // 全局戰鬥狀態標誌
global.player_level = 1;       // 玩家等級
global.captured_monsters = []; // 已捕獲的怪物數組

// 檢查是否已經初始化過玩家怪物列表
// 確保變數存在
initialize_player_monsters(); // <-- 使用管理器初始化

// 在 initialize_managers 函數中添加敵人工廠初始化
initialize_managers = function() {
    // 檢查並創建事件管理器
    if (!instance_exists(obj_event_manager)) {
        instance_create_layer(0, 0, "Controllers", obj_event_manager);
        show_debug_message("創建事件管理器");
    }
    
    // 檢查並創建敵人工廠
    if (!instance_exists(obj_enemy_factory)) {
        instance_create_layer(0, 0, "Controllers", obj_enemy_factory);
        show_debug_message("創建敵人工廠");
    }
    
    // ... 其他管理器初始化 ...
    
    // 檢查並創建單位管理器
    if (!instance_exists(obj_unit_manager)) {
        instance_create_layer(0, 0, "Controllers", obj_unit_manager);
        show_debug_message("創建單位管理器");
    }
    
    // 檢查並創建物品管理器
    if (!instance_exists(obj_item_manager)) {
        instance_create_layer(0, 0, "Controllers", obj_item_manager);
        show_debug_message("創建物品管理器");
    }

    // 檢查並創建技能管理器
    if (!instance_exists(obj_skill_manager)) {
        instance_create_layer(0, 0, "Controllers", obj_skill_manager);
        show_debug_message("創建技能管理器");
    }
    
    // ... 其他管理器初始化 ...
};

// 在檢查和添加初始怪物之前，先確保所有管理器已初始化
initialize_managers();

// 檢查陣列是否為空，然後初始化測試怪物
if (array_length(global.player_monsters) == 0) {
    show_debug_message("初始化玩家怪物列表");

    // 確保敵人工廠存在且已初始化 (現在應該已經存在)
    if (!instance_exists(obj_enemy_factory)) {
         show_debug_message("錯誤：敵人工廠不存在，無法添加初始怪物。");
    } else {
        // 定義要添加的初始怪物 (模板ID 和 等級)
        var initial_monster_setup = [
            { template_id: 4001, level: 5 } // 測試怪物 (ID 4001, Lv 1)
            // 如果需要，可以在這裡添加更多初始怪物
            // { template_id: 1001, level: 5 }, // 假設的火焰龍
        ];

        // 遍歷設定，創建標準化的怪物數據
        for (var i = 0; i < array_length(initial_monster_setup); i++) {
            var setup = initial_monster_setup[i];
            var _template_id = setup.template_id;
            var _level = setup.level;

            // --- ADDED: Directly call the manager function --- 
            add_monster_from_template(_template_id, _level);
            // Optional: Add a simpler debug message if needed, 
            // possibly requiring add_monster_from_template to return info.
            show_debug_message("Attempted to add initial monster (Template ID: " + string(_template_id) + " Lv." + string(_level) + ") via manager.");
        }
    }

    show_debug_message("玩家列表初始化完成，包含 " + string(array_length(global.player_monsters)) + " 個怪物");
}

// 確保戰鬥管理器存在
if (!instance_exists(obj_battle_manager)) {
    instance_create_layer(0, 0, "Instances", obj_battle_manager);
}


// UI控制函數
toggle_summon_ui = function() {
    if (!ui_enabled || ui_cooldown > 0) return;

    // 檢查是否在準備階段，如果不是則不打開UI
    var in_preparing_phase = false;
    if (!instance_exists(obj_battle_manager)) {
        instance_create_layer(0, 0, "Controllers", obj_battle_manager);
    }

    with (obj_battle_manager) {
        ensure_managers_exist(); // 確保所有管理器存在
        in_preparing_phase = (battle_state == BATTLE_STATE.PREPARING);

        if (!in_preparing_phase) {
            if (instance_exists(obj_battle_ui)) {
                obj_battle_ui.show_info("只能在戰鬥準備階段召喚怪物！");
            }
            return;
        }
    }

    // 檢查是否有可用怪物
    var has_usable_monsters = false;
    var player_monsters_list = get_player_monsters(); // <-- 使用管理器獲取列表
    for (var i = 0; i < array_length(player_monsters_list); i++) { // <-- 遍歷獲取的列表
        if (player_monsters_list[i].hp > 0) { // <-- 檢查獲取列表中的數據
            has_usable_monsters = true;
            break;
        }
    }

    if (!has_usable_monsters) {
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("沒有可用的怪物！");
        }
        return;
    }

    // 確保UI管理器存在
    if (!instance_exists(obj_ui_manager)) {
        instance_create_layer(0, 0, "Instances", obj_ui_manager);
    }

    // 獲取或創建召喚UI實例
    var summon_ui_inst;
    if (instance_exists(obj_summon_ui)) {
        summon_ui_inst = instance_find(obj_summon_ui, 0);
    } else {
        summon_ui_inst = instance_create_layer(0, 0, "Instances", obj_summon_ui);
    }

    // 使用UI管理器顯示UI
    with (obj_ui_manager) {
        show_ui(summon_ui_inst, "main");
    }

    // 標記從準備階段打開
    with (summon_ui_inst) {
        from_preparing_phase = true;
    }

    ui_cooldown = 5;
}

toggle_monster_manager_ui = function() {
    if (!ui_enabled || ui_cooldown > 0) {
        show_debug_message("UI被禁用或在冷卻中 (怪物管理)");
        return;
    }

    show_debug_message("===== 開始切換怪物管理UI =====");

    // 檢查並創建UI管理器
    if (!instance_exists(obj_ui_manager)) {
        show_debug_message("創建UI管理器");
        instance_create_layer(0, 0, "Instances", obj_ui_manager);
    }

    // 獲取或創建怪物管理UI實例
    var monster_ui_inst;
    var is_new_instance = false; // 添加一個標記

    if (instance_exists(obj_monster_manager_ui)) {
        monster_ui_inst = instance_find(obj_monster_manager_ui, 0);
        show_debug_message("找到現有的怪物管理UI實例");

        // 如果UI已經開啟，則關閉它
        if (monster_ui_inst.active) {
            show_debug_message("關閉已開啟的怪物管理UI");
            with (obj_ui_manager) {
                hide_ui(monster_ui_inst);
            }
            ui_cooldown = 5;
            return;
        }
        // UI存在但未開啟，準備顯示
    } else {
        show_debug_message("創建新的怪物管理UI實例");
        monster_ui_inst = instance_create_layer(0, 0, "Instances", obj_monster_manager_ui);
        is_new_instance = true; // 標記為新實例
    }

    // 使用UI管理器顯示UI
    show_debug_message("顯示怪物管理UI");
    with (obj_ui_manager) {
        // 只在新創建實例時註冊
        if (is_new_instance) {
            register_ui(monster_ui_inst, "main");
            show_debug_message("新怪物管理UI已註冊");
        }
        show_ui(monster_ui_inst, "main"); // 無論如何都要顯示
        show_debug_message("怪物管理UI已顯示");
    }

    ui_cooldown = 5;
    show_debug_message("===== 怪物管理UI切換完成 =====");
}

// obj_game_controller.gml 中的 toggle_capture_ui 函數

toggle_capture_ui = function() {
    if (!ui_enabled || ui_cooldown > 0) return;

    show_debug_message("===== 開始檢查捕獲條件 =====");

    // 檢查戰鬥狀態，只允許在ACTIVE狀態使用
    if (!instance_exists(obj_battle_manager)) {
        show_debug_message("錯誤：找不到戰鬥管理器");
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("戰鬥系統未初始化！");
        }
        return;
    }

    if (obj_battle_manager.battle_state != BATTLE_STATE.ACTIVE) {
        show_debug_message("錯誤：戰鬥狀態不是ACTIVE，當前狀態：" + string(obj_battle_manager.battle_state));
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("只能在戰鬥進行中使用捕獲功能！");
        }
        return;
    }

    // 檢查是否已經打開，如果是則關閉
    if (instance_exists(obj_capture_ui) && obj_capture_ui.active) {
        show_debug_message("關閉已開啟的捕獲UI");
        with (obj_capture_ui) {
            hide();
        }
        ui_cooldown = 5;
        return;
    }

    // 設定捕獲目標
    var target = noone;

    // 檢查enemy_units列表
    if (!instance_exists(obj_unit_manager)) {
        show_debug_message("錯誤：找不到單位管理器");
        return;
    }

    with (obj_unit_manager) {
        show_debug_message("檢查敵人列表：");
        show_debug_message("- enemy_units 是否存在: " + string(ds_exists(enemy_units, ds_type_list)));

        if (!ds_exists(enemy_units, ds_type_list)) {
            show_debug_message("錯誤：enemy_units不是有效的列表");
            return;
        }

        var enemy_count = ds_list_size(enemy_units);
        show_debug_message("- 敵人數量: " + string(enemy_count));

        if (enemy_count > 0) {
            // 遍歷所有敵人，找到第一個活著的
            for (var i = 0; i < enemy_count; i++) {
                var enemy_obj = enemy_units[| i];
                show_debug_message("檢查敵人 #" + string(i) + ":");
                show_debug_message("- 實例是否存在: " + string(instance_exists(enemy_obj)));

                if (instance_exists(enemy_obj)) {
                    show_debug_message("- HP: " + string(enemy_obj.hp) + "/" + string(enemy_obj.max_hp));
                    if (enemy_obj.hp > 0) {
                        target = enemy_obj;
                        show_debug_message("找到有效目標：" + object_get_name(enemy_obj.object_index));
                        break;
                    }
                }
            }
        }
    }

    if (target != noone) {
        show_debug_message("準備開啟捕獲UI");
        // 確保UI管理器存在
        if (!instance_exists(obj_ui_manager)) {
            instance_create_layer(0, 0, "Instances", obj_ui_manager);
        }

        // 獲取或創建捕獲UI實例
        var capture_ui_inst;
        if (instance_exists(obj_capture_ui)) {
            capture_ui_inst = instance_find(obj_capture_ui, 0);

            // 重置UI狀態
            with (capture_ui_inst) {
                active = false;
                visible = false;
                capture_state = "ready";
                open_animation = 0;
                capture_animation = 0;
                surface_needs_update = true;
            }
        } else {
            capture_ui_inst = instance_create_layer(0, 0, "UI", obj_capture_ui);
        }

        // 開啟捕獲UI
        with (capture_ui_inst) {
            open_capture_ui(target);
        }

        ui_cooldown = 5;
        show_debug_message("已開啟捕獲UI，目標: " + string(object_get_name(target.object_index)));
    } else {
        show_debug_message("錯誤：沒有找到有效的目標");
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("沒有可捕獲的敵人！");
        }
    }

    show_debug_message("===== 捕獲檢查結束 =====");
}

toggle_inventory_ui = function() {
    if (!ui_enabled || ui_cooldown > 0) {
        show_debug_message("UI被禁用或在冷卻中");
        return;
    }

    show_debug_message("===== 開始切換道具UI =====");

    // 檢查並創建必要的系統
    if (!instance_exists(obj_ui_manager)) {
        show_debug_message("創建UI管理器");
        instance_create_layer(0, 0, "Instances", obj_ui_manager);
    }

    if (!instance_exists(obj_event_manager)) {
        show_debug_message("創建事件管理器");
        instance_create_layer(0, 0, "Instances", obj_event_manager);
    }

    // 確保全局背包存在
    if (!variable_global_exists("player_inventory")) {
        show_debug_message("創建玩家背包");
        global.player_inventory = ds_list_create();
    }

    // 獲取或創建物品欄UI實例
    var inventory_ui_inst;
    var is_new_instance = false; // 添加標記

    if (instance_exists(obj_inventory_ui)) {
        inventory_ui_inst = instance_find(obj_inventory_ui, 0);
        show_debug_message("找到現有的道具UI實例");

        // 如果UI已經開啟，則關閉它
        if (inventory_ui_inst.active) {
            show_debug_message("關閉已開啟的道具UI");
            with (obj_ui_manager) {
                hide_ui(inventory_ui_inst);
            }
            ui_cooldown = 5;
            return;
        }
        // UI存在但未開啟，準備顯示
    } else {
        show_debug_message("創建新的道具UI實例");
        inventory_ui_inst = instance_create_layer(0, 0, "Instances", obj_inventory_ui);
        is_new_instance = true; // 標記為新實例
    }

    // 使用UI管理器顯示UI
    show_debug_message("顯示道具UI");
    with (obj_ui_manager) {
        // 只在新創建實例時註冊
        if (is_new_instance) {
            register_ui(inventory_ui_inst, "main");
            show_debug_message("新道具UI已註冊");
        }
        show_ui(inventory_ui_inst, "main"); // 無論如何都要顯示
        show_debug_message("道具UI已顯示");
    }

    // 添加一些測試物品（如果背包為空）
    if (ds_list_size(global.player_inventory) == 0) {
        show_debug_message("添加測試物品到背包");
        with (obj_item_manager) {
            add_item_to_inventory(1001, 5);  // 小型回復藥水
            add_item_to_inventory(2001, 1);  // 銅劍
            add_item_to_inventory(3001, 3);  // 普通球
        }
    }

    ui_cooldown = 5;
    show_debug_message("===== 道具UI切換完成 =====");
};

// 【新增】在 Create 事件末尾設置 Alarm 來延遲廣播
show_debug_message("[GameController Create] 所有初始化完成，設置 Alarm[0] 以廣播 managers_initialized");
alarm[0] = 1; // 延遲 1 幀後廣播

/// @description 初始化遊戲控制器，包括全局粒子系統

// 確保其他單例管理器存在 (如果有的話)
// instance_create_unique(obj_event_manager);
// instance_create_unique(obj_unit_manager);
// instance_create_unique(obj_item_manager);
// instance_create_unique(obj_skill_manager);
// instance_create_unique(obj_level_manager); // 確保 level_manager 存在
// instance_create_unique(obj_enemy_factory); // 確保 enemy_factory 存在
// instance_create_unique(obj_battle_manager);

// --- 初始化全局粒子系統 ---
if (!variable_global_exists("particle_system")) {
    // 檢查 "Effects" 圖層是否存在，如果不存在則創建它
    var _particle_layer_name = "Effects"; 
    if (!layer_exists(_particle_layer_name)) {
        // 不指定深度，讓 GameMaker 根據圖層順序自動處理
        layer_create(0, _particle_layer_name); // 使用深度 0 或其他預設值，但GM通常會把它放在合適位置
        show_debug_message("創建了粒子圖層: " + _particle_layer_name);
    }
    
    // 在指定的 "Effects" 圖層創建粒子系統
    global.particle_system = part_system_create_layer(_particle_layer_name, false); 
    if (part_system_exists(global.particle_system)) {
        show_debug_message("全局粒子系統已創建。 ID: " + string(global.particle_system) + " 在圖層: " + _particle_layer_name);

        // --- 創建升級特效粒子類型：pt_level_up_sparkle ---
        if (!variable_global_exists("pt_level_up_sparkle")) {
            global.pt_level_up_sparkle = part_type_create();
            if (part_type_exists(global.pt_level_up_sparkle)) {
                show_debug_message("  創建粒子類型: pt_level_up_sparkle. ID: " + string(global.pt_level_up_sparkle));
                // 配置粒子外觀和行為
                part_type_shape(global.pt_level_up_sparkle, pt_shape_spark);     
                part_type_size(global.pt_level_up_sparkle, 0.15, 0.35, -0.01, 0); 
                part_type_scale(global.pt_level_up_sparkle, 1, 1);               
                part_type_color1(global.pt_level_up_sparkle, c_yellow);          
                part_type_alpha3(global.pt_level_up_sparkle, 1, 0.8, 0);         
                part_type_speed(global.pt_level_up_sparkle, 1.5, 3.5, -0.08, 0);  
                part_type_direction(global.pt_level_up_sparkle, 60, 120, 0, 15); 
                part_type_gravity(global.pt_level_up_sparkle, 0.1, 270);         
                part_type_life(global.pt_level_up_sparkle, room_speed * 0.4, room_speed * 0.8); 
            } else {
                show_error("錯誤：無法創建 pt_level_up_sparkle 粒子類型！", false);
            }
        }
        // --- 可以在此處添加其他全局粒子類型 --- 

    } else {
        show_error("錯誤：無法創建全局粒子系統！", true);
        global.particle_system = -1; // 標記為無效
    }
}

// --- 其他遊戲控制器初始化代碼... ---
// 示例：初始化全局玩家怪物列表
if (!variable_global_exists("player_monsters")) {
    global.player_monsters = [];
    // 在這裡添加加載初始怪物的代碼 (如果需要)
    // 例如: add_initial_monster(1001, 5); // 添加 ID 1001 的怪物，等級 5
}

// 示例：初始化全局快捷欄
if (!variable_global_exists("player_hotbar")) {
    // 假設快捷欄有 10 格，初始為空 (用 noone 表示)
    global.player_hotbar = array_create(10, noone);
}

// 延遲廣播管理器初始化完成事件 (確保其他實例完成創建)
// alarm[0] = 1; // 假設 Alarm 0 用於此目的


show_debug_message("obj_game_controller 初始化完成。請確保此物件持久化。")