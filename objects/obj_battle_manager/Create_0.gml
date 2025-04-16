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
pending_flying_items = []; // 確保這個飛行道具佇列也被初始化

// --- 戰鬥區域 ---
battle_area = {
    center_x: 0,
    center_y: 0,
    boundary_radius: 0
};
// (兼容舊代碼的直接引用)
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
// (兼容舊代碼的直接引用)
info_alpha = ui_data.info_alpha;
info_text = ui_data.info_text;
info_timer = ui_data.info_timer;
surface_needs_update = ui_data.surface_needs_update;

// --- 單位系統相關 ---
units_data = {
    global_summon_cooldown: 0,
    atb_rate: 0
};
// (兼容舊代碼的直接引用)
global_summon_cooldown = units_data.global_summon_cooldown;
atb_rate = units_data.atb_rate;

// --- 經驗與升級 ---
exp_system = {
    experience: 0,
    experience_to_level_up: 100
};
// (兼容舊代碼的直接引用)
experience = exp_system.experience;
experience_to_level_up = exp_system.experience_to_level_up;

// --- 獎勵相關 ---
rewards = {
    exp: 0,
    gold: 0,
    items_list: [],
    visible: false
};
// (兼容舊代碼的直接引用)
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

// --- 事件訂閱 ---
subscribe_to_events = function() {
    show_debug_message("===== 開始訂閱戰鬥事件 =====");
    if (instance_exists(obj_event_manager)) {
        show_debug_message("事件管理器存在，開始訂閱...");
        with (obj_event_manager) {
            show_debug_message("正在訂閱戰鬥結果相關事件...");
            subscribe_to_event("all_enemies_defeated", other.id, "on_all_enemies_defeated");
            subscribe_to_event("all_player_units_defeated", other.id, "on_all_player_units_defeated");
            subscribe_to_event("battle_defeat_handled", other.id, "on_battle_defeat_handled");
            subscribe_to_event("battle_result_closed", other.id, "on_battle_result_closed"); // 新增訂閱 (技術債)
            show_debug_message("正在訂閱單位相關事件...");
            subscribe_to_event("unit_stats_updated", other.id, "on_unit_stats_updated");
            subscribe_to_event("unit_died", other.id, "on_unit_died");
            show_debug_message("正在訂閱戰鬥階段相關事件...");
            subscribe_to_event("battle_ending", other.id, "on_battle_ending");
            subscribe_to_event("battle_result_confirmed", other.id, "on_battle_result_confirmed"); // 注意: 這個事件似乎沒用了
            subscribe_to_event("rewards_calculated", other.id, "on_rewards_calculated");
             subscribe_to_event("battle_start", other.id, "start_battle"); // 從這裡訂閱戰鬥開始
        }
        show_debug_message("所有事件訂閱完成");
    }
};

// --- 事件處理回調 ---
on_unit_died = function(data) {
    if (!variable_struct_exists(data, "unit_instance")) {
        show_debug_message("[on_unit_died] 錯誤：事件數據缺少 'unit_instance'！"); return;
    }
    var _unit_instance = data.unit_instance;
    if (!instance_exists(_unit_instance)) {
        show_debug_message("[on_unit_died] 警告：傳入的 unit_instance (ID: " + string(_unit_instance) + ") 已不存在。"); return;
    }
    if (!variable_instance_exists(_unit_instance, "team") || _unit_instance.team != 1) {
        show_debug_message("[on_unit_died] 死亡單位非敵方 (Team: " + (variable_instance_exists(_unit_instance, "team") ? string(_unit_instance.team) : "未知") + ")，忽略掉落計算。"); return;
    }

    // --- 記錄擊敗信息 ---
    enemies_defeated_this_battle += 1;
    show_debug_message("[Battle Manager] 擊敗敵人數 +1，目前: " + string(enemies_defeated_this_battle));
    var _template_id = variable_instance_exists(_unit_instance, "template_id") ? _unit_instance.template_id : undefined;
    if (!is_undefined(_template_id)) {
        array_push(defeated_enemy_ids_this_battle, _template_id);
        show_debug_message("[Battle Manager] 記錄被擊敗敵人的 Template ID: " + string(_template_id));
    } else {
        show_debug_message("[Battle Manager] 警告：死亡單位缺少 template_id，無法記錄。");
    }

    // --- 經驗值記錄 ---
     if (!is_undefined(_template_id) && instance_exists(obj_enemy_factory)) {
         var _template = obj_enemy_factory.get_enemy_template(_template_id);
         if (is_struct(_template) && variable_struct_exists(_template, "exp_reward") && is_real(_template.exp_reward)) {
             record_defeated_enemy_exp(_template.exp_reward);
         } else { show_debug_message("[on_unit_died] 無法從模板 ID " + string(_template_id) + " 獲取有效的 exp_reward 來記錄。"); }
     } else { show_debug_message("[on_unit_died] 無法獲取 template_id 或 obj_enemy_factory 不存在，無法記錄經驗。"); }

    // --- 掉落物計算 ---
    if (is_undefined(_template_id) || !instance_exists(obj_enemy_factory)) return;
    var template = obj_enemy_factory.get_enemy_template(_template_id);
    if (!is_struct(template) || !variable_struct_exists(template, "loot_table") || !is_string(template.loot_table) || template.loot_table == "") {
        show_debug_message("[Unit Died Drop Calc] 模板 ID " + string(_template_id) + " 沒有有效的 loot_table，不掉落物品。"); return;
    }
    var loot_table_string = template.loot_table;
    var drop_entries = string_split(loot_table_string, ";");
    var _item_manager_exists = instance_exists(obj_item_manager);

    // --- 判斷是否最後敵人 ---
    var is_last_enemy = false;
    if (battle_state == BATTLE_STATE.ACTIVE && instance_exists(obj_unit_manager)) {
        var living_enemy_count = 0;
        for (var i = 0; i < ds_list_size(obj_unit_manager.enemy_units); i++) {
            var enemy_id = obj_unit_manager.enemy_units[| i];
            if (instance_exists(enemy_id) && enemy_id != _unit_instance && !enemy_id.dead) {
                living_enemy_count++; break;
            }
        }
        if (living_enemy_count == 0) {
             is_last_enemy = true;
             show_debug_message("[Battle Manager] 偵測到最後一個敵人死亡，將標記其掉落物。");
        }
    }

    // --- 處理掉落表 ---
    for (var j = 0; j < array_length(drop_entries); j++) {
        var entry = drop_entries[j];
        if (entry == "") continue;
        var details = string_split(entry, ":");
        if (array_length(details) == 3) {
            var item_id_str = details[0], chance_str = details[1], range_str = details[2];
            var item_id, chance, min_qty, max_qty, quantity_dropped;
            if (!is_numeric_safe(item_id_str)) { show_debug_message("[Unit Died Drop Calc] ! 無效的物品ID格式: '" + item_id_str + "'"); continue; }
            item_id = real(item_id_str);
            if (!is_numeric_safe(chance_str)) { show_debug_message("[Unit Died Drop Calc] ! 無效的機率格式: '" + chance_str + "'"); continue; }
            chance = real(chance_str);
            var range_parts = string_split(range_str, "-");
            if (array_length(range_parts) == 2 && is_numeric_safe(range_parts[0]) && is_numeric_safe(range_parts[1])) {
                min_qty = real(range_parts[0]); max_qty = real(range_parts[1]);
                if (min_qty > max_qty) { var temp = min_qty; min_qty = max_qty; max_qty = temp; }
            } else { show_debug_message("[Unit Died Drop Calc] ! 無效的數量範圍格式: '" + range_str + "'"); continue; }

            if (random(1) <= chance) { // 掉落成功
                quantity_dropped = (min_qty == max_qty) ? min_qty : irandom_range(min_qty, max_qty);
                array_push(current_battle_drops, { item_id: item_id, quantity: quantity_dropped });

                var item_data = undefined;
                if (_item_manager_exists) item_data = obj_item_manager.get_item(item_id); else continue;
                if (is_undefined(item_data)) continue;

                var _sprite_index = -1;
                if (_item_manager_exists) _sprite_index = obj_item_manager.get_item_sprite(item_id); else continue;

                if (sprite_exists(_sprite_index)) {
                    var flying_item_info = { item_id: item_id, quantity: quantity_dropped, sprite_index: _sprite_index,
                                             start_world_x: _unit_instance.x, start_world_y: _unit_instance.y, source_type: "monster" };
                    array_push(pending_flying_items, flying_item_info);
                }
            }
        } else { show_debug_message("[Unit Died Drop Calc] ! 格式錯誤: '" + entry + "'"); }
    } // 掉落表迴圈結束

    // --- 觸發飛行道具 Alarm ---
    if (array_length(pending_flying_items) > 0) {
        if (is_last_enemy) {
            processing_last_enemy_drops = true;
            show_debug_message("[Battle Manager] 設置 processing_last_enemy_drops = true");
        }
        alarm[1] = 5;
        show_debug_message("[Drop Anim Trigger] 飛行道具佇列中有 " + string(array_length(pending_flying_items)) + " 個物品，觸發 Alarm[1]。");
    }
};

on_unit_stats_updated = function(data) {
    show_debug_message("[on_unit_stats_updated] Received data: " + json_stringify(data));
    if (!is_struct(data)) { show_debug_message("錯誤：單位統計更新事件數據無效 (非 struct)"); return; }
    if (!variable_struct_exists(data, "player_units") || !variable_struct_exists(data, "enemy_units")) {
         show_debug_message("錯誤：單位統計更新事件數據缺少 player_units 或 enemy_units"); return;
    }
    if (battle_state == BATTLE_STATE.ACTIVE) {
        show_debug_message("===== 單位統計更新 =====");
        show_debug_message("玩家單位: " + string(data.player_units));
        show_debug_message("敵方單位: " + string(data.enemy_units));
    }
    if (variable_struct_exists(data, "reason")) { show_debug_message("統計更新原因 (額外欄位): " + string(data.reason)); }
};

on_battle_ending = function(data) {
    show_debug_message("===== 收到戰鬥結束事件 =====");
    var _reason = "unknown", _victory = false, _source = "system";
    if (is_struct(data)) {
        if (variable_struct_exists(data, "reason")) _reason = data.reason;
        if (variable_struct_exists(data, "victory")) _victory = data.victory;
        if (variable_struct_exists(data, "source")) _source = data.source;
    } else { show_debug_message("警告: on_battle_ending 收到非 struct 數據"); }
    show_debug_message("勝利: " + string(_victory) + ", 原因: " + string(_reason) + ", 來源: " + string(_source));
    show_debug_message("當前戰鬥狀態: " + string(battle_state));
    battle_state = BATTLE_STATE.ENDING;
    add_battle_log("戰鬥即將結束! 原因: " + string(_reason));
    if (instance_exists(obj_battle_ui)) { obj_battle_ui.show_info(_victory ? "戰鬥勝利!" : "戰鬥失敗!"); }
};

on_battle_result_confirmed = function(data) { // 這個事件可能不再需要
    show_debug_message("===== 戰鬥結果已確認 (on_battle_result_confirmed - 可能已棄用) =====");
    // end_battle(); // 不應在此調用 end_battle，改由 on_battle_result_closed 處理
};

on_rewards_calculated = function(data) {
    if (is_struct(data)) {
        if (variable_struct_exists(data, "exp_gained")) rewards.exp = data.exp_gained;
        if (variable_struct_exists(data, "gold_gained")) rewards.gold = data.gold_gained;
        if (variable_struct_exists(data, "item_drops")) rewards.items_list = data.item_drops;
        if (variable_struct_exists(data, "defeated_enemies")) enemies_defeated_this_battle = data.defeated_enemies;

        var _victory = variable_struct_exists(data, "victory") ? variable_struct_get(data, "victory") : false;
        var _duration = variable_struct_exists(data, "duration") ? variable_struct_get(data, "duration") : 0;
        _local_broadcast_event("show_battle_result", {
            victory: _victory, battle_duration: _duration, defeated_enemies: enemies_defeated_this_battle,
            exp_gained: rewards.exp, gold_gained: rewards.gold, item_drops: rewards.items_list,
            reason: "rewards_calculated", source: "reward_system"
        });
    } else { show_debug_message("警告: on_rewards_calculated 收到非 struct 數據"); }
};

on_all_enemies_defeated = function(data) {
    show_debug_message("===== 收到所有敵人被擊敗事件 =====");
    var _reason = "unknown", _source = "system";
    if (is_struct(data)) {
        if (variable_struct_exists(data, "reason")) _reason = data.reason;
        if (variable_struct_exists(data, "source")) _source = data.source;
    } else { show_debug_message("警告: on_all_enemies_defeated 收到非 struct 數據"); }
    show_debug_message("原因: " + string(_reason) + ", 來源: " + string(_source) + ", 當前狀態: " + string(battle_state));
    if (battle_state == BATTLE_STATE.ACTIVE) {
        final_battle_duration_seconds = battle_timer / game_get_speed(gamespeed_fps);
        battle_state = BATTLE_STATE.ENDING;
        if (instance_exists(obj_battle_ui)) obj_battle_ui.show_info("戰鬥勝利!");
        add_battle_log("所有敵人被擊敗，戰鬥勝利!");
        distribute_battle_exp();
        _local_broadcast_event("battle_ending", { victory: true, reason: "all_enemies_defeated", source: _source });
    } else { show_debug_message("警告：收到敵人被擊敗事件，但戰鬥狀態不是 ACTIVE"); }
    show_debug_message("===== 敵人被擊敗事件處理完成 =====");
};

on_all_player_units_defeated = function(data) {
    show_debug_message("===== 收到所有玩家單位被擊敗事件 =====");
    var _reason = "unknown", _source = "system";
    if (is_struct(data)) {
        if (variable_struct_exists(data, "reason")) _reason = data.reason;
        if (variable_struct_exists(data, "source")) _source = data.source;
    } else { show_debug_message("警告: on_all_player_units_defeated 收到非 struct 數據"); }
    show_debug_message("原因: " + string(_reason) + ", 來源: " + string(_source) + ", 當前狀態: " + string(battle_state));
    if (battle_state == BATTLE_STATE.ACTIVE) {
        final_battle_duration_seconds = battle_timer / game_get_speed(gamespeed_fps);
        battle_state = BATTLE_STATE.ENDING;
        if (instance_exists(obj_battle_ui)) obj_battle_ui.show_info("戰鬥失敗!");
        add_battle_log("所有玩家單位被擊敗，戰鬥失敗!");
        _local_broadcast_event("battle_ending", { victory: false, reason: "all_player_units_defeated", source: _source });
    } else { show_debug_message("警告：收到玩家單位被擊敗事件，但戰鬥狀態不是 ACTIVE"); }
    show_debug_message("===== 玩家單位被擊敗事件處理完成 =====");
};

on_battle_defeat_handled = function(data) {
    show_debug_message("===== 處理戰鬥失敗 on_battle_defeat_handled =====");
    show_debug_message("Received data: " + json_stringify(data));
    var _victory = false, _gold_loss = 0;
    if (is_struct(data)) {
        if (variable_struct_exists(data, "victory")) _victory = data.victory;
        if (variable_struct_exists(data, "gold_loss")) _gold_loss = data.gold_loss;
    } else { show_debug_message("警告: on_battle_defeat_handled 收到非 struct 數據"); }
    add_battle_log("戰鬥失敗處理完成，勝利: " + string(_victory) + ", 金幣損失: " + string(_gold_loss));
    rewards.visible = true; // 確保獎勵面板可見 (即使是失敗)
    if (instance_exists(obj_battle_ui)) obj_battle_ui.update_rewards_display();
};

on_battle_result_closed = function(data) { // 技術債修改
    show_debug_message("[Battle Manager] 收到 battle_result_closed 事件");
    if (battle_state == BATTLE_STATE.RESULT) {
         _execute_end_battle_core();
    } else { show_debug_message("警告：收到 battle_result_closed 事件，但狀態不是 RESULT（當前：" + string(battle_state) + "），已忽略。"); }
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
    subscribe_to_events();
    show_debug_message("戰鬥管理器初始化完成");
};

// ==========================
// Method Bindings
// ==========================
#region BIND_METHODS
_record_defeated_enemy_exp_method = method(self, record_defeated_enemy_exp);
_distribute_battle_exp_method = method(self, distribute_battle_exp);
// _cleanup_battle_data_method = method(self, cleanup_battle_data); // Removed as logic moved to CleanUp event
_add_battle_log_method = method(self, add_battle_log);
// _initialize_battle_manager_method = method(self, initialize_battle_manager); // Renamed
_subscribe_to_events_method = method(self, subscribe_to_events);
_on_unit_died_method = method(self, on_unit_died);
_on_unit_stats_updated_method = method(self, on_unit_stats_updated);
_on_battle_ending_method = method(self, on_battle_ending);
_on_battle_result_confirmed_method = method(self, on_battle_result_confirmed);
_on_rewards_calculated_method = method(self, on_rewards_calculated);
_ensure_managers_exist_method = method(self, ensure_managers_exist);
_start_battle_method = method(self, start_battle);
__execute_end_battle_core_method = method(self, _execute_end_battle_core);
_end_battle_method = method(self, end_battle);
_on_battle_result_closed_method = method(self, on_battle_result_closed);
_on_all_enemies_defeated_method = method(self, on_all_enemies_defeated);
_on_all_player_units_defeated_method = method(self, on_all_player_units_defeated);
_local_broadcast_event_method = method(self, _local_broadcast_event); // Binding the broadcaster helper
_on_battle_defeat_handled_method = method(self, on_battle_defeat_handled);
_start_factory_battle_method = method(self, start_factory_battle); // Binding start_factory_battle
_initialize_method = method(self, initialize); // Binding initialize (renamed)
#endregion

// ==========================
// Final Initialization Call
// ==========================
initialize(); // Calling the renamed initialize function