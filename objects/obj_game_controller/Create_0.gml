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
        skills: ds_list_create()
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
        skills: ds_list_create()
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
        skills: ds_list_create()
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
    } else {
        show_debug_message("創建新的怪物管理UI實例");
        monster_ui_inst = instance_create_layer(0, 0, "Instances", obj_monster_manager_ui);
    }
    
    // 使用UI管理器顯示UI
    show_debug_message("顯示怪物管理UI");
    with (obj_ui_manager) {
        register_ui(monster_ui_inst, "main");
        show_ui(monster_ui_inst, "main");
        show_debug_message("怪物管理UI已註冊並顯示");
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
    
    if (!instance_exists(obj_item_manager)) {
        show_debug_message("創建物品管理器");
        instance_create_layer(0, 0, "Instances", obj_item_manager);
    }
    
    // 確保全局背包存在
    if (!variable_global_exists("player_inventory")) {
        show_debug_message("創建玩家背包");
        global.player_inventory = ds_list_create();
    }
    
    // 獲取或創建物品欄UI實例
    var inventory_ui_inst;
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
    } else {
        show_debug_message("創建新的道具UI實例");
        inventory_ui_inst = instance_create_layer(0, 0, "Instances", obj_inventory_ui);
    }
    
    // 使用UI管理器顯示UI
    show_debug_message("顯示道具UI");
    with (obj_ui_manager) {
        register_ui(inventory_ui_inst, "main");
        show_ui(inventory_ui_inst, "main");
        show_debug_message("UI已註冊並顯示");
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

// 初始化全局快捷欄數據結構
global.player_hotbar_slots = 10; // 與 obj_main_hud 的 hotbar_slots 保持一致
global.player_hotbar = array_create(global.player_hotbar_slots, noone);
show_debug_message("全局快捷欄數據已初始化，大小：" + string(global.player_hotbar_slots));

// 指派物品到快捷欄的函數
assign_item_to_hotbar = function(inventory_index) {
    show_debug_message("嘗試將背包索引 " + string(inventory_index) + " 指派到快捷欄");
    
    // 檢查 inventory_index 是否有效
    if (!variable_global_exists("player_inventory") || !ds_exists(global.player_inventory, ds_type_list)) {
        show_debug_message("錯誤：玩家背包列表不存在。");
        return false;
    }
    if (inventory_index < 0 || inventory_index >= ds_list_size(global.player_inventory)) {
        show_debug_message("錯誤：無效的背包索引 " + string(inventory_index));
        return false;
    }
    
    // 檢查物品是否已經在快捷欄中 (可選)
    for (var i = 0; i < global.player_hotbar_slots; i++) {
        if (global.player_hotbar[i] == inventory_index) {
            show_debug_message("物品已在快捷欄位置 " + string(i));
            // 可以選擇直接返回 true，或通知玩家
            if (instance_exists(obj_main_hud)) {
                 // 假設 obj_main_hud 有 show_info 方法
                 // obj_main_hud.show_info("物品已在快捷欄"); 
            }
            return true; 
        }
    }

    // 查找第一個空位
    var assigned = false;
    for (var i = 0; i < global.player_hotbar_slots; i++) {
        if (global.player_hotbar[i] == noone) {
            global.player_hotbar[i] = inventory_index;
            show_debug_message("物品成功指派到快捷欄位置 " + string(i));
            assigned = true;
            
            // 通知 HUD 更新 (如果 HUD 存在)
            if (instance_exists(obj_main_hud)) {
                // 可以設置一個標誌，讓 HUD 在 Draw 事件中檢測並更新
                // obj_main_hud.needs_redraw = true; 
            }
            break; // 找到空位就退出循環
        }
    }

    if (!assigned) {
        show_debug_message("快捷欄已滿，無法指派物品。");
        // 通知玩家
         if (instance_exists(obj_main_hud)) {
             // obj_main_hud.show_info("快捷欄已滿"); 
         }
        return false;
    }
    
    return true;
}