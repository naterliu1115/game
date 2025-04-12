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
enemies_defeated_this_battle = 0; // <--- 新增：本場戰鬥擊敗敵人數
defeated_enemy_ids_this_battle = []; // <--- 新增：記錄本場戰鬥擊敗敵人的模板ID列表

// 戰鬥邊界和動畫
border_target_scale = 0;
border_current_scale = 0;
border_anim_speed = 0.05;

// 結果相關
battle_result = ""; // "VICTORY", "DEFEAT", "ESCAPE"
battle_timer_end = 0;
final_battle_duration_seconds = 0; // 新增：儲存最終戰鬥持續時間（秒）

// === 新增：經驗值追蹤 ===
defeated_enemies_exp = ds_list_create(); // 記錄本場戰鬥擊敗敵人的經驗值

// 記錄被擊敗敵人的經驗值
record_defeated_enemy_exp = function(exp_value) {
    if (!is_real(exp_value) || exp_value <= 0) return; // 忽略無效值
    
    ds_list_add(defeated_enemies_exp, exp_value);
    show_debug_message("[Battle Manager] 記錄經驗值: " + string(exp_value));
}

// 分配戰鬥經驗值
distribute_battle_exp = function() {
    if (ds_list_size(defeated_enemies_exp) == 0) {
        show_debug_message("[Battle Manager] 沒有經驗值可分配。");
        return;
    }
    
    // 1. 計算總經驗值
    var total_exp_gained = 0;
    for (var i = 0; i < ds_list_size(defeated_enemies_exp); i++) {
        total_exp_gained += defeated_enemies_exp[| i];
    }
    show_debug_message("[Battle Manager] 本場戰鬥總經驗: " + string(total_exp_gained));
    
    // 2. 找到存活的我方單位
    var living_player_units = [];
    // (假設 player_units 列表會被正確維護)
    for (var i = 0; i < ds_list_size(player_units); i++) {
        var unit_id = player_units[| i];
        if (instance_exists(unit_id) && !unit_id.dead) {
            array_push(living_player_units, unit_id);
        }
    }
    
    if (array_length(living_player_units) == 0) {
        show_debug_message("[Battle Manager] 沒有存活的我方單位，無法分配經驗。");
        // 清理經驗列表
        ds_list_clear(defeated_enemies_exp);
        return;
    }
    
    // 3. 分配經驗 (目前平分，可以修改分配規則)
    var exp_per_unit = floor(total_exp_gained / array_length(living_player_units));
    show_debug_message("[Battle Manager] 分配給 " + string(array_length(living_player_units)) + " 個存活單位，每個單位獲得經驗: " + string(exp_per_unit));
    
    if (exp_per_unit > 0) {
        for (var i = 0; i < array_length(living_player_units); i++) {
            var unit_to_gain_exp = living_player_units[i];
            // 確保 gain_exp 方法存在
            if (variable_instance_exists(unit_to_gain_exp, "gain_exp")) {
                unit_to_gain_exp.gain_exp(exp_per_unit);
            } else {
                show_debug_message("警告：單位 " + object_get_name(unit_to_gain_exp.object_index) + " 沒有 gain_exp 方法。");
            }
        }
    }
    
    // 4. 清理經驗列表
    ds_list_clear(defeated_enemies_exp);
    show_debug_message("[Battle Manager] 經驗分配完成並清理列表。");
}

// 清理資源 (Destroy 事件會用到)
cleanup_battle_data = function() {
    if (ds_exists(player_units, ds_type_list)) ds_list_destroy(player_units);
    if (ds_exists(enemy_units, ds_type_list)) ds_list_destroy(enemy_units);
    if (ds_exists(defeated_enemies_exp, ds_type_list)) ds_list_destroy(defeated_enemies_exp);
    // 其他需要清理的資源...
}

// 添加戰鬥日誌
add_battle_log = function(log_text) {
    // 檢查 battle_log 是否有效 (以防萬一)
    if (!ds_exists(battle_log, ds_type_list)) {
        show_debug_message("錯誤：add_battle_log 嘗試操作無效的 battle_log！");
        battle_log = ds_list_create(); // 嘗試重新初始化
    }

    ds_list_add(battle_log, log_text); // 使用 ds_list_add
    // 假設 max_log_lines 在某處定義
    if (variable_instance_exists(id, "max_log_lines") || variable_global_exists("max_log_lines")) {
         var _max_lines = (variable_instance_exists(id, "max_log_lines")) ? max_log_lines : global.max_log_lines; 
         if (ds_list_size(battle_log) > _max_lines) { // 使用 ds_list_size
             ds_list_delete(battle_log, 0); // 使用 ds_list_delete (刪除第0個元素)
         }
    } else {
         // 如果 max_log_lines 未定義，添加警告並設置默認值以防崩潰
         show_debug_message("警告：add_battle_log 中未找到 max_log_lines 定義，使用默認值 10");
         if (ds_list_size(battle_log) > 10) { 
             ds_list_delete(battle_log, 0);
         }
    }
}

// 初始化方法
initialize_battle_manager = function() {
    show_debug_message("===== 初始化戰鬥管理器 =====");
    
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
    subscribe_to_events();
    
    enemies_defeated_this_battle = 0; // <--- 重置計數器
    
    show_debug_message("戰鬥管理器初始化完成");
};

// 訂閱事件
subscribe_to_events = function() {
    show_debug_message("===== 開始訂閱戰鬥事件 =====");
    
    if (instance_exists(obj_event_manager)) {
        show_debug_message("事件管理器存在，開始訂閱...");
        
        with (obj_event_manager) {
            show_debug_message("正在訂閱戰鬥結果相關事件...");
            // 戰鬥結果相關事件
            subscribe_to_event("all_enemies_defeated", other.id, "on_all_enemies_defeated");
            subscribe_to_event("all_player_units_defeated", other.id, "on_all_player_units_defeated");
            subscribe_to_event("battle_defeat_handled", other.id, "on_battle_defeat_handled");
            
            show_debug_message("正在訂閱單位相關事件...");
            // 單位相關事件
            subscribe_to_event("unit_died", other.id, "on_unit_died");
            subscribe_to_event("unit_stats_updated", other.id, "on_unit_stats_updated");
            
            show_debug_message("正在訂閱戰鬥階段相關事件...");
            // 戰鬥階段相關事件
            subscribe_to_event("battle_ending", other.id, "on_battle_ending");
            subscribe_to_event("battle_result_confirmed", other.id, "on_battle_result_confirmed");
            
            // 新增：訂閱獎勵計算完成事件
            subscribe_to_event("rewards_calculated", other.id, "on_rewards_calculated");
        }
        show_debug_message("所有事件訂閱完成");
    }
};

// 處理單位死亡事件
on_unit_died = function(data) {
    show_debug_message("===== 單位死亡事件處理 =====");
    
    // 安全檢查
    if (!is_struct(data) || !variable_struct_exists(data, "unit_id") || !variable_struct_exists(data, "team")) {
        show_debug_message("錯誤：單位死亡事件數據無效");
        return;
    }
    
    var _unit_id = data.unit_id;
    var _team = data.team;
    
    show_debug_message("死亡單位ID: " + string(_unit_id));
    show_debug_message("單位隊伍: " + string(_team));
    
    // 更新戰鬥日誌
    add_battle_log("單位 " + string(_unit_id) + " 已陣亡");
    
    // 增加擊敗計數器並記錄ID
    if (_team == 1) { // 假設 1 代表敵方隊伍
        enemies_defeated_this_battle++;
        show_debug_message("[Battle Manager] 擊敗敵人數 +1，目前: " + string(enemies_defeated_this_battle));
        
        // 檢查實例是否存在且是否有 template_id
        if (instance_exists(_unit_id) && variable_instance_exists(_unit_id, "template_id")) {
            var _template_id = _unit_id.template_id;
            array_push(defeated_enemy_ids_this_battle, _template_id);
            show_debug_message("[Battle Manager] 記錄被擊敗敵人的 Template ID: " + string(_template_id));
        } else {
            show_debug_message("警告：死亡的敵方單位實例不存在或缺少 template_id，無法記錄其 ID。");
        }
    }
    
    // 只在戰鬥進行中時檢查勝負
    if (battle_state == BATTLE_STATE.ACTIVE) {
        // 檢查單位數量
        if (instance_exists(obj_unit_manager)) {
            var enemy_count = ds_list_size(obj_unit_manager.enemy_units);
            var player_count = ds_list_size(obj_unit_manager.player_units);
            
            show_debug_message("單位死亡後檢查 - 敵人數量: " + string(enemy_count) + ", 玩家單位數量: " + string(player_count));
            
            // 更新單位統計
            _event_broadcaster("unit_stats_updated", {
                enemy_units: enemy_count,
                player_units: player_count
            });
            
            // 檢查是否所有敵人都被擊敗
            if (enemy_count <= 0) {
                show_debug_message("檢測到所有敵人被擊敗");
                _event_broadcaster("all_enemies_defeated", {
                    reason: "unit_died_check",
                    source: "unit_died_event"
                });
                return; // 提前返回，避免重複檢查
            }
            
            // 檢查是否所有玩家單位都被擊敗
            if (player_count <= 0) {
                show_debug_message("檢測到所有玩家單位被擊敗");
                _event_broadcaster("all_player_units_defeated", {
                    reason: "unit_died_check",
                    source: "unit_died_event"
                });
                return; // 提前返回，避免重複檢查
            }
        }
    }
};

// 處理單位統計更新事件
on_unit_stats_updated = function(data) {
    // 加入詳細調試訊息，查看收到的原始數據
    show_debug_message("[on_unit_stats_updated] Received data: " + json_stringify(data)); 
    
    // 安全檢查 data 是否為 struct
    if (!is_struct(data)) {
        show_debug_message("錯誤：單位統計更新事件數據無效 (非 struct)");
        return;
    }

    // 檢查必要的欄位是否存在
    if (!variable_struct_exists(data, "player_units") || !variable_struct_exists(data, "enemy_units")) {
         show_debug_message("錯誤：單位統計更新事件數據缺少 player_units 或 enemy_units");
         return;
    }

    if (battle_state == BATTLE_STATE.ACTIVE) {
        show_debug_message("===== 單位統計更新 =====");
        show_debug_message("玩家單位: " + string(data.player_units));
        show_debug_message("敵方單位: " + string(data.enemy_units));
    }
    
    // 可選：處理可能存在的 reason 欄位（防禦性程式碼）
    if (variable_struct_exists(data, "reason")) {
        var _reason = data.reason;
        show_debug_message("統計更新原因 (額外欄位): " + string(_reason));
        // 可以在這裡根據 reason 做額外處理
    }
};

// 處理戰鬥結束事件
on_battle_ending = function(data) {
    show_debug_message("===== 收到戰鬥結束事件 =====");
    // 加入檢查並設置預設值
    var _reason = "unknown";
    var _victory = false;
    var _source = "system"; // 新增 source 預設值
    if (is_struct(data)) {
        if (variable_struct_exists(data, "reason")) { _reason = data.reason; }
        if (variable_struct_exists(data, "victory")) { _victory = data.victory; }
        if (variable_struct_exists(data, "source")) { _source = data.source; } // 檢查 source
    } else {
         show_debug_message("警告: on_battle_ending 收到非 struct 數據");
    }

    show_debug_message("勝利: " + string(_victory));
    show_debug_message("原因: " + string(_reason)); // 使用檢查過的 _reason
    show_debug_message("來源: " + string(_source)); // 顯示來源
    show_debug_message("當前戰鬥狀態: " + string(battle_state));

    // 只在非結束狀態時處理
    battle_state = BATTLE_STATE.ENDING;
    add_battle_log("戰鬥即將結束! 原因: " + string(_reason)); // 使用檢查過的 _reason

    if (instance_exists(obj_battle_ui)) {
        obj_battle_ui.show_info(_victory ? "戰鬥勝利!" : "戰鬥失敗!");
    }
};

// 處理戰鬥結果確認事件
on_battle_result_confirmed = function(data) {
    show_debug_message("===== 戰鬥結果已確認 =====");
    end_battle();
};

// 處理獎勵計算完成事件
on_rewards_calculated = function(data) {
    // show_debug_message("===== 收到獎勵計算完成事件 ====="); // 可以移除
    // show_debug_message("Received data: " + json_stringify(data)); // 可以移除

    if (is_struct(data)) {
        // 更新內部的 rewards 結構
        if (variable_struct_exists(data, "exp_gained")) { rewards.exp = data.exp_gained; }
        if (variable_struct_exists(data, "gold_gained")) { rewards.gold = data.gold_gained; }
        if (variable_struct_exists(data, "item_drops")) { rewards.items_list = data.item_drops; } // 注意欄位名稱是 item_drops
        // 更新擊敗敵人數
        if (variable_struct_exists(data, "defeated_enemies")) { enemies_defeated_this_battle = data.defeated_enemies; }
        
        // show_debug_message("內部獎勵數據已更新: EXP=" + string(rewards.exp) + ", Gold=" + string(rewards.gold) + ", Defeated=" + string(enemies_defeated_this_battle)); // 可以移除

        // 提取數據用於廣播 (修改 variable_struct_get 的用法)
        var _victory = variable_struct_exists(data, "victory") ? variable_struct_get(data, "victory") : false; // <-- 使用兩參數版本
        var _duration = variable_struct_exists(data, "duration") ? variable_struct_get(data, "duration") : 0; // <-- 使用兩參數版本
        var _reason = "rewards_calculated";
        var _source = "reward_system";

        // --- 實際的廣播呼叫 --- 
        _event_broadcaster("show_battle_result", {
            victory: _victory,
            battle_duration: _duration,
            defeated_enemies: enemies_defeated_this_battle, // 使用更新後的計數
            exp_gained: rewards.exp,                 // 使用更新後的經驗
            gold_gained: rewards.gold,                // 使用更新後的金幣
            item_drops: rewards.items_list,           // 使用更新後的物品列表 (鍵名確認為 item_drops)
            reason: _reason,
            source: _source
        });
        // --- 新增結束 ---

        // show_debug_message("已廣播 show_battle_result 事件 (來自 on_rewards_calculated)"); // 可以移除
    } else {
        show_debug_message("警告: on_rewards_calculated 收到非 struct 數據");
    }
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
    show_debug_message("檢查系統狀態：");
    show_debug_message("- 事件管理器存在: " + string(instance_exists(obj_event_manager)));
    show_debug_message("- 單位管理器存在: " + string(instance_exists(obj_unit_manager)));
    show_debug_message("- 當前戰鬥狀態: " + string(battle_state));
    
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
    if (instance_exists(initial_enemy)) {
        show_debug_message("- ID: " + string(initial_enemy));
        show_debug_message("- 類型: " + object_get_name(initial_enemy.object_index));
        show_debug_message("- 位置: (" + string(initial_enemy.x) + ", " + string(initial_enemy.y) + ")");
        
        // 確保敵人初始化
        with (initial_enemy) {
            if (!variable_instance_exists(id, "initialized")) {
                show_debug_message("- 初始化敵人");
                initialize();
                initialized = true;
            }
            show_debug_message("- 初始化狀態: " + string(variable_instance_exists(id, "initialized")));
            show_debug_message("- Team值: " + string(team));
            team = 1; // 確保敵人的team值正確設置
        }
        
        // 確保敵人被添加到敵人列表
        if (!instance_exists(obj_unit_manager)) {
            show_debug_message("錯誤：單位管理器不存在");
            instance_create_layer(0, 0, "Controllers", obj_unit_manager);
            show_debug_message("已創建單位管理器");
        }
        
        with (obj_unit_manager) {
            show_debug_message("檢查敵人列表：");
            
            // 檢查enemy_units是否為有效的ds_list
            if (!ds_exists(enemy_units, ds_type_list)) {
                show_debug_message("錯誤：enemy_units不是有效的列表");
                enemy_units = ds_list_create();
                show_debug_message("已創建新的enemy_units列表");
            }
            
            show_debug_message("- 當前敵人數量: " + string(ds_list_size(enemy_units)));
            
            // 檢查敵人是否已經在列表中
            var enemy_index = ds_list_find_index(enemy_units, initial_enemy);
            if (enemy_index == -1) {
                // 添加初始敵人
                ds_list_add(enemy_units, initial_enemy);
                show_debug_message("- 已添加初始敵人到列表");
            } else {
                show_debug_message("- 敵人已在列表中，索引: " + string(enemy_index));
            }
            
            show_debug_message("- 新敵人數量: " + string(ds_list_size(enemy_units)));
            
            // 驗證敵人是否在列表中
            var index = ds_list_find_index(enemy_units, initial_enemy);
            show_debug_message("- 驗證：敵人在列表中的索引: " + string(index));
            
            if (index == -1) {
                show_debug_message("錯誤：添加敵人失敗");
                return false;
            }
        }
    } else {
        show_debug_message("錯誤：初始敵人不存在");
        return false;
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
    
    show_debug_message("準備發送戰鬥開始事件...");
    // 發送戰鬥開始事件
    _event_broadcaster("battle_start", {
        initial_enemy: initial_enemy,
        center_x: initial_enemy.x,
        center_y: initial_enemy.y,
        required_radius: 300 // 使用預設值
    });
    show_debug_message("戰鬥開始事件已發送");
    
    // 顯示戰鬥UI
    if (instance_exists(obj_battle_ui)) {
        with (obj_battle_ui) {
            show();
            show_info("戰鬥開始!");
        }
    } else {
        show_debug_message("警告：戰鬥UI不存在");
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
    _event_broadcaster("battle_end", {
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
    show_debug_message("===== 收到所有敵人被擊敗事件 =====");
    // 加入檢查並設置預設值
    var _reason = "unknown";
    var _source = "system";
    if (is_struct(data)) {
        if (variable_struct_exists(data, "reason")) { _reason = data.reason; }
        if (variable_struct_exists(data, "source")) { _source = data.source; }
    } else {
         show_debug_message("警告: on_all_enemies_defeated 收到非 struct 數據");
    }

    show_debug_message("當前戰鬥狀態: " + string(battle_state));
    show_debug_message("觸發原因: " + string(_reason)); // 使用檢查過的 _reason
    show_debug_message("來源: " + string(_source)); // 使用檢查過的 _source

    // 只在ACTIVE狀態且尚未開始結束流程時處理
    if (battle_state == BATTLE_STATE.ACTIVE) {
        // 檢查是否已經在處理結束流程 (這段檢查 is_ending 的邏輯可能需要根據你的 event_manager 實現調整)
        var is_ending = false;
        // if (instance_exists(obj_event_manager)) {
        //     with(obj_event_manager) {
        //         is_ending = variable_instance_exists(id, "pending_events") &&
        //                    ds_list_find_index(pending_events, "battle_ending") != -1;
        //     }
        // }

        if (!is_ending) { // 暫時移除 is_ending 檢查，如果需要請恢復
            // show_debug_message("從 ACTIVE 狀態轉換到 ENDING 狀態 (勝利)"); // 保留或移除皆可
            final_battle_duration_seconds = battle_timer / game_get_speed(gamespeed_fps);
            // show_debug_message("[Battle Manager Event] final_battle_duration_seconds set to: " + string(final_battle_duration_seconds) + " seconds (Victory)"); // 可以移除
            battle_state = BATTLE_STATE.ENDING;

            // 通知UI顯示勝利信息
            if (instance_exists(obj_battle_ui)) {
                obj_battle_ui.show_info("戰鬥勝利!");
            }

            add_battle_log("所有敵人被擊敗，戰鬥勝利!");

            // 分配經驗值
            distribute_battle_exp(); // <--- 在這裡觸發經驗分配

            // 發送戰鬥即將結束事件
            _event_broadcaster("battle_ending", {
                victory: true,
                reason: "all_enemies_defeated", // 這裡廣播時可以固定原因
                source: _source // 可以傳遞原始來源
            });
        } else {
            show_debug_message("忽略重複的敵人被擊敗事件：結束流程已在進行中");
        }
    } else {
        show_debug_message("警告：收到敵人被擊敗事件，但戰鬥狀態不是 ACTIVE（當前狀態：" + string(battle_state) + "）");
    }

    show_debug_message("===== 敵人被擊敗事件處理完成 =====");
};

// 處理所有玩家單位被擊敗事件
on_all_player_units_defeated = function(data) {
    show_debug_message("===== 收到所有玩家單位被擊敗事件 =====");
    // 加入檢查並設置預設值
    var _reason = "unknown";
    var _source = "system"; // 新增 source 預設值
    if (is_struct(data)) {
        if (variable_struct_exists(data, "reason")) { _reason = data.reason; }
        if (variable_struct_exists(data, "source")) { _source = data.source; } // 檢查 source
    } else {
         show_debug_message("警告: on_all_player_units_defeated 收到非 struct 數據");
    }

    show_debug_message("當前戰鬥狀態: " + string(battle_state));
    show_debug_message("觸發原因: " + string(_reason)); // 使用檢查過的 _reason
    show_debug_message("來源: " + string(_source)); // 顯示來源

    if (battle_state == BATTLE_STATE.ACTIVE) {
        // show_debug_message("從 ACTIVE 狀態轉換到 ENDING 狀態 (失敗)"); // 保留或移除皆可
        final_battle_duration_seconds = battle_timer / game_get_speed(gamespeed_fps);
        // show_debug_message("[Battle Manager Event] final_battle_duration_seconds set to: " + string(final_battle_duration_seconds) + " seconds (Defeat)"); // 可以移除
        battle_state = BATTLE_STATE.ENDING;
        // battle_timer = 0; // 失敗時是否重置計時器？根據需要決定

        // 通知UI顯示失敗信息
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("戰鬥失敗!");
        }

        add_battle_log("所有玩家單位被擊敗，戰鬥失敗!");

        // 發送戰鬥即將結束事件
        _event_broadcaster("battle_ending", {
            victory: false,
            reason: "all_player_units_defeated", // 這裡廣播時可以固定原因
            source: _source // 可以傳遞原始來源
        });
    } else {
        show_debug_message("警告：收到玩家單位被擊敗事件，但戰鬥狀態不是 ACTIVE（當前狀態：" + string(battle_state) + "）");
    }

    show_debug_message("===== 玩家單位被擊敗事件處理完成 =====");
};

// 輔助函數：發送事件消息
_local_broadcast_event = function(event_name, data = {}) {
    if (instance_exists(obj_event_manager)) {
        show_debug_message("[BattleManager Broadcaster] Attempting to broadcast: " + event_name + " with data: " + json_stringify(data)); // <-- 保留這個重要的LOG
        with (obj_event_manager) {
            // 在呼叫 handle_event 前再加一層日誌，確保 with 塊執行
            // show_debug_message("[BattleManager Broadcaster] Inside with(obj_event_manager) block, about to call handle_event for: " + event_name); // <-- 註解掉
            handle_event(event_name, data);
        }
        // show_debug_message("[BattleManager Broadcaster] Call to handle_event seems completed for: " + event_name); // <-- 註解掉
    } else {
        show_debug_message("警告: [BattleManager Broadcaster] 事件管理器不存在，無法廣播事件: " + event_name);
    }
};

/* // <-- Start comment block
// 新增：處理顯示戰鬥結果事件
on_show_battle_result = function(data) {
    show_debug_message("===== 顯示戰鬥結果 =====");
    show_debug_message("Received data: " + json_stringify(data)); // 添加日誌

    // 加入檢查並設置預設值
    var _victory = false;
    var _duration = 0;
    var _defeated_count = 0; 
    var _exp_gained = 0;
    var _gold_gained = 0;
    var _items_gained = [];
    if (is_struct(data)) {
        if (variable_struct_exists(data, "victory")) { _victory = data.victory; }
        if (variable_struct_exists(data, "battle_duration")) { _duration = data.battle_duration; }
        if (variable_struct_exists(data, "defeated_enemies")) { _defeated_count = data.defeated_enemies; }
        if (variable_struct_exists(data, "exp_gained")) { _exp_gained = data.exp_gained; }
        if (variable_struct_exists(data, "gold_gained")) { _gold_gained = data.gold_gained; }
        if (variable_struct_exists(data, "items_gained")) { _items_gained = data.items_gained; }
    } else {
        show_debug_message("警告: on_show_battle_result 收到非 struct 數據");
    }

    // 更新獎勵數據 (使用檢查後的值)
    rewards.exp = _exp_gained;
    rewards.gold = _gold_gained;
    rewards.items_list = _items_gained;
    rewards.visible = true;
	
	

    // 更新UI顯示 - 傳遞所有參數給 show_rewards
    if (instance_exists(obj_battle_ui)) {
        var ui_instance = instance_find(obj_battle_ui, 0); // 獲取第一個找到的實例
        if (instance_exists(ui_instance)) { // 再次確認獲取的實例有效
             show_debug_message(">>> 準備呼叫 show_rewards on instance: " + string(ui_instance)); // *** 新增日誌 ***
             ui_instance.show_rewards(_victory, _duration, _defeated_count, rewards.exp, rewards.gold, rewards.items_list);
             show_debug_message("<<< show_rewards 呼叫完成"); // *** 新增日誌 ***
        } else {
             show_debug_message("警告: instance_find(obj_battle_ui, 0) 未找到有效實例");
        }
    } else {
        show_debug_message("警告: obj_battle_ui 不存在於 on_show_battle_result");
    }

    add_battle_log("顯示戰鬥結果!");

*/ // <-- End comment block

// 新增：處理戰鬥失敗處理事件
on_battle_defeat_handled = function(data) {
    show_debug_message("===== 處理戰鬥失敗 =====");
    show_debug_message("Received data: " + json_stringify(data)); // 添加日誌

    // 加入檢查並設置預設值
    var _victory = false; // Defeat is handled, assume victory is false unless specified
    var _gold_loss = 0;
    if (is_struct(data)) {
        if (variable_struct_exists(data, "victory")) { _victory = data.victory; }
        if (variable_struct_exists(data, "gold_loss")) { _gold_loss = data.gold_loss; } // 檢查 gold_loss
    } else {
         show_debug_message("警告: on_battle_defeat_handled 收到非 struct 數據");
    }
    
    add_battle_log("戰鬥結果處理完成，勝利: " + string(_victory) + ", 金幣損失: " + string(_gold_loss)); // 使用檢查後的值

    // 確保獎勵面板可見
    rewards.visible = true;

    // 更新UI顯示
    if (instance_exists(obj_battle_ui)) {
        obj_battle_ui.update_rewards_display();
    }
};

// 將事件廣播方法綁定到實例變數
#region BIND_METHODS
// ... 其他綁定 ...
_event_broadcaster = method(self, _local_broadcast_event); // <-- 修改賦值
// ... 其他綁定 ...
#endregion

// 添加工廠式戰鬥啟動函數
start_factory_battle = function(enemy_template_id, center_x, center_y) {
    show_debug_message("===== 開始使用工廠啟動戰鬥 =====");
    show_debug_message("敵人模板ID: " + string(enemy_template_id));
    show_debug_message("位置: (" + string(center_x) + ", " + string(center_y) + ")");
    
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
    
    // 設置戰鬥區域
    battle_area.center_x = center_x;
    battle_area.center_y = center_y;
    battle_area.boundary_radius = 0; // 初始為0，會在Step事件中擴張
    
    // 更新直接引用
    battle_center_x = center_x;
    battle_center_y = center_y;
    battle_boundary_radius = 0;
    
    // 檢查敵人工廠是否存在
    if (!instance_exists(obj_enemy_factory)) {
        show_debug_message("錯誤：敵人工廠不存在");
        instance_create_layer(0, 0, "Controllers", obj_enemy_factory);
    }
    
    // 檢查單位管理器是否存在
    if (!instance_exists(obj_unit_manager)) {
        show_debug_message("錯誤：單位管理器不存在");
        instance_create_layer(0, 0, "Controllers", obj_unit_manager);
    }
    
    // 使用敵人工廠生成敵人群組
    var enemies = [];
    with (obj_enemy_factory) {
        // 修正：添加第四個參數 level_param (暫設為 1)
        var default_enemy_level = 1; // 或者根據需要設置其他等級邏輯
        enemies = generate_enemy_group(enemy_template_id, center_x, center_y, default_enemy_level);
    }
    
    // 檢查是否成功生成敵人
    if (array_length(enemies) == 0) {
        show_debug_message("錯誤：無法生成敵人");
        battle_state = BATTLE_STATE.INACTIVE;
        global.in_battle = false;
        return false;
    }
    
    // 添加敵人到單位管理器
    with (obj_unit_manager) {
        // 先清空敵人列表
        ds_list_clear(enemy_units);
        
        // 添加生成的敵人
        for (var i = 0; i < array_length(enemies); i++) {
            ds_list_add(enemy_units, enemies[i]);
        }
        
        show_debug_message("已添加 " + string(array_length(enemies)) + " 個敵人到單位管理器");
    }
    
    // 記錄戰鬥開始
    add_battle_log("戰鬥開始! 敵人模板: " + string(enemy_template_id) + ", 數量: " + string(array_length(enemies)));
    
    // 發送戰鬥開始事件
    _event_broadcaster("battle_start", {
        center_x: center_x,
        center_y: center_y,
        required_radius: 300, // 使用預設值
        template_id: enemy_template_id
    });
    
    // 顯示戰鬥UI
    if (instance_exists(obj_battle_ui)) {
        with (obj_battle_ui) {
            show();
            show_info("戰鬥開始!");
        }
    } else {
        instance_create_layer(0, 0, "UI", obj_battle_ui);
    }
    
    show_debug_message("===== 戰鬥初始化完成 =====");
    return true;
};

// 初始化
initialize_battle_manager();