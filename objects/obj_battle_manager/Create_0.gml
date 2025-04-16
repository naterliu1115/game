// obj_battle_manager - Create_0.gml 核心 (Reorganized)

// ==========================
// Enums
// ==========================
enum BATTLE_STATE {
    INACTIVE,    // 非戰鬥狀態
    STARTING,    // 戰鬥開始過渡（邊界擴張）
    PREPARING,   // 戰鬥準備階段（玩家召喚單位）
    ACTIVE,      // 戰鬥進行中
    ENDING,      // 戰鬥結束過渡
    RESULT       // 顯示戰鬥結果
}

enum ENDING_SUBSTATE {
    SHRINKING,       // 正在縮小邊界
    WAITING_DROPS,   // 等待掉落物動畫
    DELAYING,        // 短暫延遲
    FINISHED         // 結束流程完成
}

// ==========================
// 載入 callback function、初始化、訂閱事件
// ==========================
battle_callbacks();

// ==========================
// Variable Initialization
// ==========================

// --- 核心狀態 ---
battle_state = BATTLE_STATE.INACTIVE;
ending_substate = ENDING_SUBSTATE.SHRINKING;
battle_timer = 0;
battle_result_handled = false;
processing_last_enemy_drops = false;

// --- 列表 ---
player_units = ds_list_create();
enemy_units = ds_list_create();
last_enemy_flying_items = ds_list_create();
battle_log = ds_list_create();
defeated_enemies_exp = ds_list_create();
defeated_enemy_ids_this_battle = [];
current_battle_drops = [];
pending_flying_items = [];

// --- 戰鬥區域 ---
battle_area = {
    center_x: 0,
    center_y: 0,
    boundary_radius: 0
};
battle_center_x = battle_area.center_x;
battle_center_y = battle_area.center_y;
battle_boundary_radius = battle_area.boundary_radius;

// --- UI 相關 ---
ui_data = {
    info_text: "",
    info_alpha: 1.0,
    info_timer: 0,
    surface_needs_update: true
};
info_alpha = ui_data.info_alpha;
info_text = ui_data.info_text;
info_timer = ui_data.info_timer;
surface_needs_update = ui_data.surface_needs_update;

// --- 單位系統相關 ---
units_data = {
    global_summon_cooldown: 0,
    atb_rate: 0
};
global_summon_cooldown = units_data.global_summon_cooldown;
atb_rate = units_data.atb_rate;

// --- 經驗與升級 ---
exp_system = {
    experience: 0,
    experience_to_level_up: 100
};
experience = exp_system.experience;
experience_to_level_up = exp_system.experience_to_level_up;

// --- 獎勵相關 ---
rewards = {
    exp: 0,
    gold: 0,
    items_list: [],
    visible: false
};
reward_exp = rewards.exp;
reward_gold = rewards.gold;
reward_items_list = rewards.items_list;
reward_visible = rewards.visible;

// --- 戰鬥結束相關 ---
battle_result = ""; // "VICTORY", "DEFEAT", "ESCAPE"
battle_timer_end = 0;
final_battle_duration_seconds = 0;
enemies_defeated_this_battle = 0;

// --- 邊界動畫 ---
border_target_scale = 0;
border_current_scale = 0;
border_anim_speed = 0.05;

// ==========================
// Method Bindings
// ==========================
_on_unit_died_method = method(self, on_unit_died);
_on_unit_stats_updated_method = method(self, on_unit_stats_updated);
_on_battle_ending_method = method(self, on_battle_ending);
_on_battle_result_confirmed_method = method(self, on_battle_result_confirmed);
_on_rewards_calculated_method = method(self, on_rewards_calculated);
_on_all_enemies_defeated_method = method(self, on_all_enemies_defeated);
_on_all_player_units_defeated_method = method(self, on_all_player_units_defeated);
_on_battle_defeat_handled_method = method(self, on_battle_defeat_handled);
_on_battle_result_closed_method = method(self, on_battle_result_closed);

// ==========================
// 初始化與事件訂閱
// ==========================
battle_init();
battle_event_subscribe();

// ==========================
// Function Definitions
// ==========================

// --- 經驗相關 ---
record_defeated_enemy_exp = function(exp_value) {
    if (!is_real(exp_value) || exp_value <= 0) return;
    ds_list_add(defeated_enemies_exp, exp_value);
    show_debug_message("[Battle Manager] 記錄經驗值: " + string(exp_value));
};

distribute_battle_exp = function() {
    if (ds_list_size(defeated_enemies_exp) == 0) {
        show_debug_message("[Battle Manager] 沒有經驗值可分配。");
        return;
    }
    var total_exp_gained = 0;
    for (var i = 0; i < ds_list_size(defeated_enemies_exp); i++) {
        total_exp_gained += defeated_enemies_exp[| i];
    }
    show_debug_message("[Battle Manager] 本場戰鬥總經驗: " + string(total_exp_gained));
    var living_player_units = [];
    for (var i = 0; i < ds_list_size(player_units); i++) {
        var unit_id = player_units[| i];
        if (instance_exists(unit_id) && !unit_id.dead) {
            array_push(living_player_units, unit_id);
        }
    }
    if (array_length(living_player_units) == 0) {
        show_debug_message("[Battle Manager] 沒有存活的我方單位，無法分配經驗。");
        ds_list_clear(defeated_enemies_exp);
        return;
    }
    var exp_per_unit = floor(total_exp_gained / array_length(living_player_units));
    show_debug_message("[Battle Manager] 分配給 " + string(array_length(living_player_units)) + " 個存活單位，每個單位獲得經驗: " + string(exp_per_unit));
    if (exp_per_unit > 0) {
        for (var i = 0; i < array_length(living_player_units); i++) {
            var unit_to_gain_exp = living_player_units[i];
            if (variable_instance_exists(unit_to_gain_exp, "gain_exp")) {
                unit_to_gain_exp.gain_exp(exp_per_unit);
            } else {
                show_debug_message("警告：單位 " + object_get_name(unit_to_gain_exp.object_index) + " 沒有 gain_exp 方法。");
            }
        }
    }
    ds_list_clear(defeated_enemies_exp);
    show_debug_message("[Battle Manager] 經驗分配完成並清理列表。");
};

// --- 日誌 ---
add_battle_log = function(log_text) {
    if (!ds_exists(battle_log, ds_type_list)) {
        show_debug_message("錯誤：add_battle_log 嘗試操作無效的 battle_log！");
        battle_log = ds_list_create();
    }
    ds_list_add(battle_log, log_text);
    if (variable_instance_exists(id, "max_log_lines") || variable_global_exists("max_log_lines")) {
         var _max_lines = (variable_instance_exists(id, "max_log_lines")) ? max_log_lines : global.max_log_lines;
         if (ds_list_size(battle_log) > _max_lines) {
             ds_list_delete(battle_log, 0);
         }
    } else {
         show_debug_message("警告：add_battle_log 中未找到 max_log_lines 定義，使用默認值 10");
         if (ds_list_size(battle_log) > 10) {
             ds_list_delete(battle_log, 0);
         }
    }
};

// --- 管理器檢查 ---
ensure_managers_exist = function() {
    if (!instance_exists(obj_event_manager)) {
        instance_create_layer(0, 0, "Controllers", obj_event_manager);
        show_debug_message("創建事件管理器");
    }
    if (!instance_exists(obj_unit_manager)) {
        instance_create_layer(0, 0, "Controllers", obj_unit_manager);
        show_debug_message("創建單位管理器");
    }
    if (!instance_exists(obj_reward_system)) {
        instance_create_layer(0, 0, "Controllers", obj_reward_system);
        show_debug_message("創建獎勵系統");
    }
    if (!instance_exists(obj_battle_ui)) {
        instance_create_layer(0, 0, "UI", obj_battle_ui);
        show_debug_message("創建戰鬥UI");
    }
};

// --- 戰鬥流程控制 ---
start_battle = function(initial_enemy) {
    show_debug_message("===== 開始初始化戰鬥 =====");
    if (battle_state != BATTLE_STATE.INACTIVE) { show_debug_message("警告：戰鬥已經在進行中"); return false; }
    if (!instance_exists(initial_enemy)) { show_debug_message("錯誤：初始敵人不存在"); return false; }

    battle_state = BATTLE_STATE.STARTING;
    battle_timer = 0;
    battle_result_handled = false;
    global.in_battle = true;
    final_battle_duration_seconds = 0; // 重置

    show_debug_message("初始敵人: " + object_get_name(initial_enemy.object_index) + " at (" + string(initial_enemy.x) + "," + string(initial_enemy.y) + ")");
    with (initial_enemy) { if (!variable_instance_exists(id, "initialized")) { initialize(); initialized = true; } team = 1; }

    if (!instance_exists(obj_unit_manager)) { instance_create_layer(0, 0, "Controllers", obj_unit_manager); }
    with (obj_unit_manager) {
        if (!ds_exists(enemy_units, ds_type_list)) enemy_units = ds_list_create();
        if (ds_list_find_index(enemy_units, initial_enemy) == -1) ds_list_add(enemy_units, initial_enemy);
        if (ds_list_find_index(enemy_units, initial_enemy) == -1) { show_debug_message("錯誤：添加敵人失敗"); return false; }
    }

    add_battle_log("戰鬥開始! 初始敵人: " + object_get_name(initial_enemy.object_index));
    battle_area.center_x = initial_enemy.x; battle_area.center_y = initial_enemy.y; battle_area.boundary_radius = 0;
    battle_center_x = initial_enemy.x; battle_center_y = initial_enemy.y; battle_boundary_radius = 0;

    _local_broadcast_event("battle_start", { initial_enemy: initial_enemy, center_x: initial_enemy.x, center_y: initial_enemy.y, required_radius: 300 });
    if (!instance_exists(obj_battle_ui)) instance_create_layer(0, 0, "UI", obj_battle_ui);
    if (instance_exists(obj_battle_ui)) { with (obj_battle_ui) { show(); show_info("戰鬥開始!"); } }

    show_debug_message("===== 戰鬥初始化完成 =====");
    return true;
};

start_factory_battle = function(enemy_template_id, center_x, center_y) { // 已移到 BIND 之前
    show_debug_message("===== 開始使用工廠啟動戰鬥 =====");
    if (battle_state != BATTLE_STATE.INACTIVE) { show_debug_message("警告：戰鬥已經在進行中"); return false; }

    battle_state = BATTLE_STATE.STARTING;
    battle_timer = 0;
    battle_result_handled = false;
    global.in_battle = true;
    final_battle_duration_seconds = 0; // 重置

    battle_area.center_x = center_x; battle_area.center_y = center_y; battle_area.boundary_radius = 0;
    battle_center_x = center_x; battle_center_y = center_y; battle_boundary_radius = 0;

    if (!instance_exists(obj_enemy_factory)) instance_create_layer(0, 0, "Controllers", obj_enemy_factory);
    if (!instance_exists(obj_unit_manager)) instance_create_layer(0, 0, "Controllers", obj_unit_manager);

    var enemies = [];
    with (obj_enemy_factory) { var default_enemy_level = 1; enemies = generate_enemy_group(enemy_template_id, center_x, center_y, default_enemy_level); }

    if (array_length(enemies) == 0) { show_debug_message("錯誤：無法生成敵人"); battle_state = BATTLE_STATE.INACTIVE; global.in_battle = false; return false; }

    with (obj_unit_manager) {
        if (!ds_exists(enemy_units, ds_type_list)) enemy_units = ds_list_create(); // 確保列表存在
        ds_list_clear(enemy_units);
        for (var i = 0; i < array_length(enemies); i++) ds_list_add(enemy_units, enemies[i]);
        show_debug_message("已添加 " + string(array_length(enemies)) + " 個敵人到單位管理器");
    }

    add_battle_log("戰鬥開始! 敵人模板: " + string(enemy_template_id) + ", 數量: " + string(array_length(enemies)));
    _local_broadcast_event("battle_start", { center_x: center_x, center_y: center_y, required_radius: 300, template_id: enemy_template_id });

    if (!instance_exists(obj_battle_ui)) instance_create_layer(0, 0, "UI", obj_battle_ui);
    if (instance_exists(obj_battle_ui)) { with (obj_battle_ui) { show(); show_info("戰鬥開始!"); } }

    show_debug_message("===== 工廠戰鬥初始化完成 =====");
    return true;
};

_execute_end_battle_core = function() { // 技術債修改
     battle_state = BATTLE_STATE.INACTIVE;
    if (instance_exists(obj_unit_manager)) obj_unit_manager.save_player_units_state();
    global.in_battle = false;
    var duration_to_report = (final_battle_duration_seconds > 0) ? final_battle_duration_seconds : (battle_timer / game_get_speed(gamespeed_fps));
    _local_broadcast_event("battle_end", { duration: duration_to_report });
    add_battle_log("戰鬥完全結束 (Core Logic)!");
    show_debug_message("戰鬥完全結束 (Core Logic)!");
};

end_battle = function() { // 技術債修改
    show_debug_message("警告: 直接調用 end_battle() 可能已棄用，應通過事件流程處理。");
    _execute_end_battle_core();
};


// --- 事件廣播輔助 ---
_local_broadcast_event = function(event_name, data = {}) {
    if (instance_exists(obj_event_manager)) {
        show_debug_message("[BattleManager Broadcaster] Attempting to broadcast: " + event_name + " with data: " + json_stringify(data));
        with (obj_event_manager) { handle_event(event_name, data); }
    } else { show_debug_message("警告: [BattleManager Broadcaster] 事件管理器不存在，無法廣播事件: " + event_name); }
};

// ==========================
// Initialization Function (was initialize_battle_manager)
// ==========================
initialize = function() { // Renamed for consistency
    show_debug_message("===== 初始化戰鬥管理器 =====");
    battle_state = BATTLE_STATE.INACTIVE;
    ending_substate = ENDING_SUBSTATE.SHRINKING;
    battle_timer = 0;
    battle_result_handled = false;
    processing_last_enemy_drops = false;
    battle_area.center_x = 0; battle_area.center_y = 0; battle_area.boundary_radius = 0;
    battle_center_x = 0; battle_center_y = 0; battle_boundary_radius = 0;
    if (ds_exists(battle_log, ds_type_list)) ds_list_clear(battle_log);
    if (ds_exists(last_enemy_flying_items, ds_type_list)) ds_list_clear(last_enemy_flying_items); else last_enemy_flying_items = ds_list_create();
    enemies_defeated_this_battle = 0; defeated_enemy_ids_this_battle = []; current_battle_drops = [];
    if (ds_exists(defeated_enemies_exp, ds_type_list)) ds_list_clear(defeated_enemies_exp);
    ensure_managers_exist();
    battle_event_subscribe();
    show_debug_message("戰鬥管理器初始化完成");
};

// ==========================
// Final Initialization Call
// ==========================
initialize(); // Calling the renamed initialize function