// obj_game_controller - Create_0.gml
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

// 確保UI管理器存在
if (!instance_exists(obj_ui_manager)) {
    instance_create_layer(0, 0, "Instances", obj_ui_manager);
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
if (!variable_global_exists("player_monsters")) {
    global.player_monsters = [];
}

// 確保 `global.player_monsters` 是陣列，避免 `Undefined` 錯誤
if (!is_array(global.player_monsters)) {
    global.player_monsters = [];
}

// 檢查陣列是否為空，然後初始化測試怪物
if (array_length(global.player_monsters) == 0) {
    show_debug_message("初始化玩家怪物列表");

    var initial_monster1 = {
        type: obj_test_summon,
        name: "火焰龍",
        level: 5,
        hp: 100,
        max_hp: 100,
        attack: 15,
        defense: 8,
        spd: 12,
        abilities: ["火焰噴射", "熱浪"]
    };

    var initial_monster2 = {
        type: obj_test_summon,
        name: "水精靈",
        level: 3,
        hp: 75,
        max_hp: 75,
        attack: 10,
        defense: 5,
        spd: 15,
        abilities: ["水彈", "治癒之波"]
    };

    var initial_monster3 = {
        type: obj_test_summon,
        name: "測試怪物",
        level: 1,
        hp: 60,
        max_hp: 60,
        attack: 10,
        defense: 4,
        spd: 6,
        abilities: ["水彈", "基礎攻擊"]
    };

    array_push(global.player_monsters, initial_monster1);
    array_push(global.player_monsters, initial_monster2);
    array_push(global.player_monsters, initial_monster3);

    show_debug_message("已添加 " + string(array_length(global.player_monsters)) + " 個怪物到玩家列表");
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
    if (instance_exists(obj_battle_manager)) {
        in_preparing_phase = (obj_battle_manager.battle_state == BATTLE_STATE.PREPARING);
        
        if (!in_preparing_phase) {
            if (instance_exists(obj_battle_ui)) {
                obj_battle_ui.show_info("只能在戰鬥準備階段召喚怪物！");
            }
            return;
        }
    } else {
        show_debug_message("戰鬥管理器不存在，無法打開召喚UI");
        return;
    }
    
    // 檢查是否有可用怪物
    var has_usable_monsters = false;
    if (variable_global_exists("player_monsters")) {
        for (var i = 0; i < array_length(global.player_monsters); i++) {
            if (global.player_monsters[i].hp > 0) {
                has_usable_monsters = true;
                break;
            }
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
        show_ui("main", summon_ui_inst); // 現在傳遞的是實例
    }
    
    // 標記從準備階段打開
    with (summon_ui_inst) {
        from_preparing_phase = true;
    }
    
    ui_cooldown = 5;
}

toggle_monster_manager_ui = function() {
    if (!ui_enabled || ui_cooldown > 0) return;
    
    // 確保UI管理器存在
    if (!instance_exists(obj_ui_manager)) {
        instance_create_layer(0, 0, "Instances", obj_ui_manager);
    }
    
    // 獲取或創建怪物管理UI實例
    var monster_ui_inst;
    if (instance_exists(obj_monster_manager_ui)) {
        monster_ui_inst = instance_find(obj_monster_manager_ui, 0);
    } else {
        monster_ui_inst = instance_create_layer(0, 0, "Instances", obj_monster_manager_ui);
    }
    
    // 使用UI管理器顯示UI
    with (obj_ui_manager) {
        show_ui("main", monster_ui_inst); // 現在傳遞的是實例
    }
    
    ui_cooldown = 5;
}

toggle_capture_ui = function() {
    if (!ui_enabled || ui_cooldown > 0) return;
    
    // 設定捕獲目標
    var target = noone;
    
    // 尋找一個活著的敵人實例
    if (instance_exists(obj_battle_manager) && ds_exists(obj_battle_manager.enemy_units, ds_type_list)) {
        if (ds_list_size(obj_battle_manager.enemy_units) > 0) {
            var enemy_obj = obj_battle_manager.enemy_units[| 0];
            if (instance_exists(enemy_obj)) {
                target = enemy_obj;
            }
        }
    }
    
    if (target != noone) {
        // 確保UI管理器存在
        if (!instance_exists(obj_ui_manager)) {
            instance_create_layer(0, 0, "Instances", obj_ui_manager);
        }
        
        // 先顯示UI
        with (obj_ui_manager) {
            show_ui("overlay", obj_capture_ui);
        }
        
        // 設置捕獲目標
        if (instance_exists(obj_capture_ui)) {
            with (obj_capture_ui) {
                target_enemy = target;
                capture_state = "ready";
                open_animation = 0;
                
                // 初始化捕獲方法
                capture_methods = [];
                
                var method1 = {
                    name: "普通捕獲",
                    description: "用普通球捕獲怪物",
                    cost: { item: "普通球", amount: 1 },
                    bonus: 0
                };
                
                var method2 = {
                    name: "高級捕獲",
                    description: "用高級球捕獲怪物",
                    cost: { item: "高級球", amount: 1 },
                    bonus: 0.2
                };
                
                array_push(capture_methods, method1, method2);
                selected_method = 0;
                calculate_capture_chance();
                surface_needs_update = true;
            }
        }
        
        ui_cooldown = 5;
    } else {
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("沒有可捕獲的敵人！");
        }
    }
}

toggle_capture_ui = function() {
    if (!ui_enabled || ui_cooldown > 0) return;

    show_debug_message("嘗試打開捕獲 UI");

    // 確保 obj_capture_ui 存在並獲取其實例
    var ui_instance = noone;
    if (instance_exists(obj_capture_ui)) {
        ui_instance = instance_find(obj_capture_ui, 0); // 獲取第一個實例
    } else {
        // 創建 UI 實例
        ui_instance = instance_create_layer(0, 0, "Instances", obj_capture_ui);
    }
    
    // 檢查實例是否存在並有必要的函數
    if (ui_instance == noone || !variable_instance_exists(ui_instance, "open_capture_ui")) {
        show_debug_message("錯誤：obj_capture_ui 尚未初始化 `open_capture_ui`！");
        exit;
    }

    // 設定捕獲目標
    var target = noone;
    
    // 尋找一個活著的敵人實例
    if (instance_exists(obj_battle_manager) && ds_exists(obj_battle_manager.enemy_units, ds_type_list)) {
        if (ds_list_size(obj_battle_manager.enemy_units) > 0) {
            var enemy_obj = obj_battle_manager.enemy_units[| 0];
            if (instance_exists(enemy_obj)) {
                target = enemy_obj;
            }
        }
    }

    if (target != noone) {
        with (ui_instance) {
            open_capture_ui(target);
        }
        ui_cooldown = 5;
    } else {
        show_debug_message("沒有可捕獲的敵人！");
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("沒有可捕獲的敵人！");
        }
    }
};

toggle_monster_manager_ui = function() {
    if (!ui_enabled || ui_cooldown > 0) return;
    
    show_debug_message("嘗試打開怪物管理UI");
    
    // 確保怪物管理UI存在
    if (!instance_exists(obj_monster_manager_ui)) {
        instance_create_layer(0, 0, "Instances", obj_monster_manager_ui);
    }
    
    // 使用UI管理器顯示UI
    if (instance_exists(obj_ui_manager)) {
        with (obj_ui_manager) {
            show_ui("main", obj_monster_manager_ui);
        }
    } else {
        // 備用方法，直接操作UI
        with (obj_monster_manager_ui) {
            // 直接修改尺寸值而不是替換函數
            details_width = max(1, details_width);
            details_height = max(1, details_height);
            
            // 標記為需要更新
            if (variable_instance_exists(id, "details_needs_update")) {
                details_needs_update = true;
            }
            show();
        }
    }
    
    ui_cooldown = 5;
}