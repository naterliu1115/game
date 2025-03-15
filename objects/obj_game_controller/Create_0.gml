// obj_game_controller - Create_0.gml

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
        show_ui(summon_ui_inst, "main");
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
        show_ui(monster_ui_inst, "main");
    }
    
    ui_cooldown = 5;
}

// obj_game_controller.gml 中的 toggle_capture_ui 函數

toggle_capture_ui = function() {
    if (!ui_enabled || ui_cooldown > 0) return;
    
    // 不允許在準備階段開啟捕獲UI
    if (instance_exists(obj_battle_manager) && 
        obj_battle_manager.battle_state == BATTLE_STATE.PREPARING) {
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("無法在戰鬥準備階段捕獲敵人！");
        }
        return;
    }
    
    // 檢查是否已經打開，如果是則關閉
    if (instance_exists(obj_capture_ui) && obj_capture_ui.active) {
        with (obj_capture_ui) {
            hide();
        }
        ui_cooldown = 5;
        return;
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
        // 確保UI管理器存在
        if (!instance_exists(obj_ui_manager)) {
            instance_create_layer(0, 0, "Instances", obj_ui_manager);
        }
        
        // 獲取或創建捕獲UI實例
        var capture_ui_inst;
        if (instance_exists(obj_capture_ui)) {
            capture_ui_inst = instance_find(obj_capture_ui, 0);
            
            // 確保ui_inst的所有狀態已重置
            with (capture_ui_inst) {
                // 重設重要變量，確保UI狀態回到初始狀態
                active = false;
                visible = false;
                capture_state = "ready";
                open_animation = 0;
                capture_animation = 0;
                surface_needs_update = true;
            }
        } else {
            capture_ui_inst = instance_create_layer(0, 0, "Instances", obj_capture_ui);
        }
        
        // 通過UI實例直接呼叫open_capture_ui函數
        with (capture_ui_inst) {
            open_capture_ui(target);
        }
        
        ui_cooldown = 5;
        show_debug_message("已開啟捕獲UI，目標: " + string(object_get_name(target.object_index)));
    } else {
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("沒有可捕獲的敵人！");
        }
        show_debug_message("無法開啟捕獲UI：找不到有效的敵人目標");
    }
}