// =======================
// Destroy 事件代碼
// =======================

// obj_battle_manager (重構) - Destroy_0.gml

// 釋放資源
ds_list_destroy(battle_log);

// 取消事件訂閱
if (instance_exists(obj_event_manager)) {
    with (obj_event_manager) {
        unsubscribe_from_all_events(other.id);
    }
}

// 初始化戰鬥狀態
battle_state = BATTLE_STATE.INACTIVE;
battle_timer = 0;           // 戰鬥持續時間計時器
battle_result_handled = false; // 確保戰鬥結果只處理一次
battle_log = ds_list_create(); // 戰鬥日誌

// 初始化方法
initialize_battle_manager = function() {
    // 重置戰鬥狀態
    battle_state = BATTLE_STATE.INACTIVE;
    battle_timer = 0;
    battle_result_handled = false;
    
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
}

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
}

// 啟動戰鬥函數
start_battle = function(initial_enemy) {
    if (battle_state != BATTLE_STATE.INACTIVE) return false;
    
    // 設置戰鬥狀態
    battle_state = BATTLE_STATE.STARTING;
    battle_timer = 0;
    battle_result_handled = false;
    
    // 設置全局戰鬥標誌
    global.in_battle = true;
    
    // 記錄戰鬥開始
    add_battle_log("戰鬥開始! 初始敵人: " + object_get_name(initial_enemy.object_index));
    
    // 發送戰鬥開始事件
    broadcast_event("battle_start", {
        initial_enemy: initial_enemy,
        center_x: initial_enemy.x,
        center_y: initial_enemy.y
    });
    
    // 顯示戰鬥UI
    if (instance_exists(obj_battle_ui)) {
        with (obj_battle_ui) {
            show();
            show_info("戰鬥開始!");
        }
    }
    
    show_debug_message("戰鬥開始: 初始敵人 " + object_get_name(initial_enemy.object_index));
    return true;
}

// 結束戰鬥函數
end_battle = function() {
    // 恢復正常遊戲狀態
    battle_state = BATTLE_STATE.INACTIVE;
    
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
}

// 處理所有敵人被擊敗事件
on_all_enemies_defeated = function(data) {
    if (battle_state == BATTLE_STATE.ACTIVE) {
        battle_state = BATTLE_STATE.ENDING;
        show_debug_message("所有敵人已被擊敗，進入結束階段");
    }
}

// 處理所有玩家單位被擊敗事件
on_all_player_units_defeated = function(data) {
    if (battle_state == BATTLE_STATE.ACTIVE) {
        battle_state = BATTLE_STATE.ENDING;
        show_debug_message("所有玩家單位已被擊敗，進入結束階段");
    }
}

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
}

// 輔助函數：發送事件消息
broadcast_event = function(event_name, data = {}) {
    if (instance_exists(obj_event_manager)) {
        with (obj_event_manager) {
            handle_event(event_name, data);
        }
    } else {
        show_debug_message("警告: 事件管理器不存在，無法廣播事件: " + event_name);
    }
}