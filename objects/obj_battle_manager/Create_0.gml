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
            subscribe_to_event("show_battle_result", other.id, "on_show_battle_result");
            subscribe_to_event("battle_defeat_handled", other.id, "on_battle_defeat_handled");
            
            show_debug_message("正在訂閱單位相關事件...");
            // 單位相關事件
            subscribe_to_event("unit_died", other.id, "on_unit_died");
            subscribe_to_event("unit_stats_updated", other.id, "on_unit_stats_updated");
            
            show_debug_message("正在訂閱戰鬥階段相關事件...");
            // 戰鬥階段相關事件
            subscribe_to_event("battle_ending", other.id, "on_battle_ending");
            subscribe_to_event("battle_result_confirmed", other.id, "on_battle_result_confirmed");
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
    
    show_debug_message("死亡單位ID: " + string(data.unit_id));
    show_debug_message("單位隊伍: " + string(data.team));
    
    // 更新戰鬥日誌
    add_battle_log("單位 " + string(data.unit_id) + " 已陣亡");
    
    // 只在戰鬥進行中時檢查勝負
    if (battle_state == BATTLE_STATE.ACTIVE) {
        // 檢查單位數量
        if (instance_exists(obj_unit_manager)) {
            var enemy_count = ds_list_size(obj_unit_manager.enemy_units);
            var player_count = ds_list_size(obj_unit_manager.player_units);
            
            show_debug_message("單位死亡後檢查 - 敵人數量: " + string(enemy_count) + ", 玩家單位數量: " + string(player_count));
            
            // 更新單位統計
            broadcast_event("unit_stats_updated", {
                enemy_units: enemy_count,
                player_units: player_count
            });
            
            // 檢查是否所有敵人都被擊敗
            if (enemy_count <= 0) {
                show_debug_message("檢測到所有敵人被擊敗");
                broadcast_event("all_enemies_defeated", {
                    reason: "unit_died_check",
                    source: "unit_died_event"
                });
                return; // 提前返回，避免重複檢查
            }
            
            // 檢查是否所有玩家單位都被擊敗
            if (player_count <= 0) {
                show_debug_message("檢測到所有玩家單位被擊敗");
                broadcast_event("all_player_units_defeated", {
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
    if (battle_state == BATTLE_STATE.ACTIVE) {
        show_debug_message("===== 單位統計更新 =====");
        show_debug_message("玩家單位: " + string(data.player_units));
        show_debug_message("敵方單位: " + string(data.enemy_units));
    }
};

// 處理戰鬥結束事件
on_battle_ending = function(data) {
    show_debug_message("===== 收到戰鬥結束事件 =====");
    show_debug_message("勝利: " + string(data.victory));
    show_debug_message("原因: " + string(data.reason));
    show_debug_message("當前戰鬥狀態: " + string(battle_state));
    
    // 只在非結束狀態時處理
    if (battle_state != BATTLE_STATE.ENDING && battle_state != BATTLE_STATE.RESULT) {
        battle_state = BATTLE_STATE.ENDING;
        // 不重置battle_timer
        add_battle_log("戰鬥即將結束! 原因: " + string(data.reason));
        
        // 通知UI顯示相應信息
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info(data.victory ? "戰鬥勝利!" : "戰鬥失敗!");
        }
        
        // 顯示戰鬥結果
        broadcast_event("show_battle_result", {
            victory: data.victory,
            battle_duration: battle_timer / game_get_speed(gamespeed_fps),
            exp_gained: rewards.exp,
            gold_gained: rewards.gold,
            items_gained: rewards.items_list
        });
    }
};

// 處理戰鬥結果確認事件
on_battle_result_confirmed = function(data) {
    show_debug_message("===== 戰鬥結果已確認 =====");
    end_battle();
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
    broadcast_event("battle_start", {
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
    show_debug_message("===== 收到所有敵人被擊敗事件 =====");
    
    // 安全檢查
    if (!is_struct(data)) {
        data = { reason: "unknown", source: "system" };
    }
    
    show_debug_message("當前戰鬥狀態: " + string(battle_state));
    show_debug_message("觸發原因: " + string(data.reason));
    show_debug_message("來源: " + string(data.source));
    
    // 只在ACTIVE狀態且尚未開始結束流程時處理
    if (battle_state == BATTLE_STATE.ACTIVE) {
        // 檢查是否已經在處理結束流程
        var is_ending = false;
        if (instance_exists(obj_event_manager)) {
            with(obj_event_manager) {
                is_ending = variable_instance_exists(id, "pending_events") && 
                           ds_list_find_index(pending_events, "battle_ending") != -1;
            }
        }
        
        if (!is_ending) {
            show_debug_message("從 ACTIVE 狀態轉換到 ENDING 狀態");
            battle_state = BATTLE_STATE.ENDING;
            
            // 通知UI顯示勝利信息
            if (instance_exists(obj_battle_ui)) {
                obj_battle_ui.show_info("戰鬥勝利!");
            }
            
            add_battle_log("所有敵人被擊敗，戰鬥勝利!");
            
            // 發送戰鬥即將結束事件
            broadcast_event("battle_ending", {
                victory: true,
                reason: "all_enemies_defeated",
                source: data.source
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
    show_debug_message("當前戰鬥狀態: " + string(battle_state));
    show_debug_message("觸發原因: " + string(data.reason));
    
    if (battle_state == BATTLE_STATE.ACTIVE) {
        show_debug_message("從 ACTIVE 狀態轉換到 ENDING 狀態");
        battle_state = BATTLE_STATE.ENDING;
        battle_timer = 0;
        
        // 通知UI顯示失敗信息
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("戰鬥失敗!");
        }
        
        add_battle_log("所有玩家單位被擊敗，戰鬥失敗!");
        
        // 發送戰鬥即將結束事件
        broadcast_event("battle_ending", {
            victory: false,
            reason: "all_player_units_defeated"
        });
    } else {
        show_debug_message("警告：收到玩家單位被擊敗事件，但戰鬥狀態不是 ACTIVE（當前狀態：" + string(battle_state) + "）");
    }
    
    show_debug_message("===== 玩家單位被擊敗事件處理完成 =====");
};

// 添加戰鬥日誌
add_battle_log = function(message) {
    // 使用實際的battle_timer，不在ENDING狀態重置
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

// 新增：處理顯示戰鬥結果事件
on_show_battle_result = function(data) {
    show_debug_message("===== 顯示戰鬥結果 =====");
    
    // 更新獎勵數據
    rewards.exp = data.exp_gained;
    rewards.gold = data.gold_gained;
    rewards.items_list = data.items_gained;
    rewards.visible = true;
    
    // 更新UI顯示
    if (instance_exists(obj_battle_ui)) {
        obj_battle_ui.show_rewards();
    }
    
    add_battle_log("顯示戰鬥結果!");
};

// 新增：處理戰鬥失敗處理事件
on_battle_defeat_handled = function(data) {
    show_debug_message("===== 處理戰鬥失敗 =====");
    add_battle_log("戰鬥結果處理完成，勝利: " + string(data.victory));
    
    // 確保獎勵面板可見
    rewards.visible = true;
    
    // 更新UI顯示
    if (instance_exists(obj_battle_ui)) {
        obj_battle_ui.update_rewards_display();
    }
};

// 初始化
initialize_battle_manager();