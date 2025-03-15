// obj_battle_manager - Create_0.gml 核心

// 戰鬥狀態枚舉
enum BATTLE_STATE {
    INACTIVE,    // 非戰鬥狀態
    STARTING,    // 戰鬥開始過渡（邊界擴張）
    PREPARING,   // 戰鬥準備階段（玩家召喚單位）
    ACTIVE,      // 戰鬥進行中
    ENDING,      // 戰鬥結束過渡
    RESULT       // 顯示戰鬥結果
}

// 戰鬥核心數據
battle_state = BATTLE_STATE.INACTIVE;
battle_timer = 0;
battle_result_handled = false;

// 初始化單位列表
player_units = ds_list_create();
enemy_units = ds_list_create();

// 戰鬥區域數據
battle_area = {
    center_x: 0,
    center_y: 0,
    boundary_radius: 0
};

// UI顯示數據
ui_data = {
    info_text: "",
    info_alpha: 1.0,
    info_timer: 0,
    surface_needs_update: true
};

// 單位系統數據
units_data = {
    global_summon_cooldown: 0,
    atb_rate: 0
};

// 經驗與升級數據
exp_system = {
    experience: 0,
    experience_to_level_up: 100
};

// 獎勵系統數據
rewards = {
    exp: 0,
    gold: 0,
    items_list: [],
    visible: false
};

// 為了向後兼容，添加直接變數引用
battle_center_x = battle_area.center_x;
battle_center_y = battle_area.center_y;
battle_boundary_radius = battle_area.boundary_radius;
info_alpha = ui_data.info_alpha;
info_text = ui_data.info_text;
info_timer = ui_data.info_timer;
global_summon_cooldown = units_data.global_summon_cooldown;
atb_rate = units_data.atb_rate;
experience = exp_system.experience;
experience_to_level_up = exp_system.experience_to_level_up;
reward_exp = rewards.exp;
reward_gold = rewards.gold;
reward_items_list = rewards.items_list;
reward_visible = rewards.visible;
surface_needs_update = ui_data.surface_needs_update;

// 戰鬥日誌
battle_log = ds_list_create();

// 初始化方法
initialize_battle_manager = function() {
    // 重置戰鬥狀態
    battle_state = BATTLE_STATE.INACTIVE;
    battle_timer = 0;
    battle_result_handled = false;
    
    // 重置戰鬥區域
    battle_area.center_x = 0;
    battle_area.center_y = 0;
    battle_area.boundary_radius = 0;
    
    // 更新直接引用
    battle_center_x = battle_area.center_x;
    battle_center_y = battle_area.center_y;
    battle_boundary_radius = battle_area.boundary_radius;
    
    // 清空戰鬥日誌
    ds_list_clear(battle_log);
    
    // 檢查並創建必要的管理器
    ensure_managers_exist();
    
    // 訂閱相關事件
    if (instance_exists(obj_event_manager)) {
        with (obj_event_manager) {
            subscribe_to_event("all_enemies_defeated", other.id, other.on_all_enemies_defeated);
            subscribe_to_event("all_player_units_defeated", other.id, other.on_all_player_units_defeated);
        }
    }
    
    show_debug_message("戰鬥管理器已初始化");
};

// 確保所有必要的管理器都存在
ensure_managers_exist = function() {
    // 檢查並創建事件管理器
    if (!instance_exists(obj_event_manager)) {
        instance_create_layer(0, 0, "Controllers", obj_event_manager);
        show_debug_message("創建事件管理器");
    }
    
    // 檢查並創建單位管理器
    if (!instance_exists(obj_unit_manager)) {
        instance_create_layer(0, 0, "Controllers", obj_unit_manager);
        show_debug_message("創建單位管理器");
    }
    
    // 檢查並創建獎勵系統
    if (!instance_exists(obj_reward_system)) {
        instance_create_layer(0, 0, "Controllers", obj_reward_system);
        show_debug_message("創建獎勵系統");
    }
    
    // 檢查並創建戰鬥UI
    if (!instance_exists(obj_battle_ui)) {
        instance_create_layer(0, 0, "UI", obj_battle_ui);
        show_debug_message("創建戰鬥UI");
    }
};

// 啟動戰鬥函數
start_battle = function(initial_enemy) {
    show_debug_message("===== 開始初始化戰鬥 =====");
    if (battle_state != BATTLE_STATE.INACTIVE) {
        show_debug_message("警告：戰鬥已經在進行中，狀態：" + string(battle_state));
        return false;
    }
    
    // 設置戰鬥狀態
    battle_state = BATTLE_STATE.STARTING;
    battle_timer = 0;
    battle_result_handled = false;
    
    // 設置全局戰鬥標誌
    global.in_battle = true;
    
    show_debug_message("初始敵人信息：");
    show_debug_message("- ID: " + string(initial_enemy));
    show_debug_message("- 類型: " + object_get_name(initial_enemy.object_index));
    show_debug_message("- 位置: (" + string(initial_enemy.x) + ", " + string(initial_enemy.y) + ")");
    with (initial_enemy) {
        show_debug_message("- Team值: " + string(team));
    }
    
    // 記錄戰鬥開始
    add_battle_log("戰鬥開始! 初始敵人: " + object_get_name(initial_enemy.object_index));
    
    // 設置戰鬥區域 - 使用初始敵人位置作為中心點
    battle_area.center_x = initial_enemy.x;
    battle_area.center_y = initial_enemy.y;
    battle_area.boundary_radius = 0; // 初始為0，會在Step事件中擴張
    
    // 更新直接引用
    battle_center_x = initial_enemy.x;
    battle_center_y = initial_enemy.y;
    battle_boundary_radius = 0;
    
    show_debug_message("發送戰鬥開始事件");
    // 發送戰鬥開始事件
    broadcast_event("battle_start", {
        initial_enemy: initial_enemy,
        center_x: initial_enemy.x,
        center_y: initial_enemy.y,
        required_radius: 300 // 使用預設值
    });
    
    // 顯示戰鬥UI
    if (instance_exists(obj_battle_ui)) {
        with (obj_battle_ui) {
            show();
            show_info("戰鬥開始!");
        }
    }
    
    show_debug_message("===== 戰鬥初始化完成 =====");
    return true;
};

// 結束戰鬥函數
end_battle = function() {
    // 恢復正常遊戲狀態
    battle_state = BATTLE_STATE.INACTIVE;
    
    // 保存玩家單位狀態
    if (instance_exists(obj_unit_manager)) {
        obj_unit_manager.save_player_units_state();
    }
    
    // 重置全局戰鬥標誌
    global.in_battle = false;
    
    // 發送戰鬥結束事件
    broadcast_event("battle_end", {
        duration: battle_timer / game_get_speed(gamespeed_fps)
    });
    
    // 隱藏戰鬥UI
    if (instance_exists(obj_battle_ui)) {
        instance_destroy(obj_battle_ui);
    }
    
    add_battle_log("戰鬥完全結束!");
    show_debug_message("戰鬥完全結束!");
};

// 處理所有敵人被擊敗事件
on_all_enemies_defeated = function(data) {
    if (battle_state == BATTLE_STATE.ACTIVE) {
        battle_state = BATTLE_STATE.ENDING;
        show_debug_message("所有敵人已被擊敗，進入結束階段");
    }
};

// 處理所有玩家單位被擊敗事件
on_all_player_units_defeated = function(data) {
    if (battle_state == BATTLE_STATE.ACTIVE) {
        battle_state = BATTLE_STATE.ENDING;
        show_debug_message("所有玩家單位已被擊敗，進入結束階段");
    }
};

// 添加戰鬥日誌
add_battle_log = function(message) {
    // 添加時間戳
    var time_stamp = string_format(battle_timer / game_get_speed(gamespeed_fps), 2, 1);
    var full_message = "[" + time_stamp + "s] " + message;
    
    // 添加到日誌
    ds_list_add(battle_log, full_message);
    
    // 限制日誌大小
    if (ds_list_size(battle_log) > 100) {
        ds_list_delete(battle_log, 0);
    }
    
    // 在UI中顯示最新日誌訊息
    if (instance_exists(obj_battle_ui)) {
        obj_battle_ui.battle_info = full_message;
    }
    
    show_debug_message("戰鬥日誌: " + full_message);
};

// 輔助函數：發送事件消息
broadcast_event = function(event_name, data = {}) {
    if (instance_exists(obj_event_manager)) {
        with (obj_event_manager) {
            handle_event(event_name, data);
        }
    } else {
        show_debug_message("警告: 事件管理器不存在，無法廣播事件: " + event_name);
    }
};

// 初始化
initialize_battle_manager();