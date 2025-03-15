// obj_battle_manager - Create_0.gml 完整版

// 在obj_battle_manager的Create事件開頭添加
reward_items_list = [];
item_rewards = [];
surface_needs_update = false;
atb_rate = 1.0;  // 或其他適當的初始值
experience = 0;  // 經驗值從0開始
experience_to_level_up = 100;  // 或其他適當的初始值

// 戰鬥狀態枚舉
enum BATTLE_STATE {
    INACTIVE,    // 非戰鬥狀態
    STARTING,    // 戰鬥開始過渡（邊界擴張）
    PREPARING,   // 戰鬥準備階段（玩家召喚單位）
    ACTIVE,      // 戰鬥進行中
    ENDING,      // 戰鬥結束過渡
    RESULT       // 顯示戰鬥結果
}

// 初始化戰鬥狀態
battle_state = BATTLE_STATE.INACTIVE;
battle_timer = 0;           // 戰鬥持續時間計時器
battle_boundary_radius = 0; // 戰鬥邊界半徑
battle_center_x = 0;        // 戰鬥中心X座標
battle_center_y = 0;        // 戰鬥中心Y座標
battle_result_handled = false; // 確保戰鬥結果（勝利或失敗）只會執行一次
boundary_alert_timer = 0;   // 邊界警告計時器

info_alpha = 1.0;  // 或其他適當的初始值
info_text = "";
info_timer = 0;
target = noone;
reward_exp = 0;
reward_gold = 0;
reward_items_list = [];
reward_visible = false;

// 捕獲相關變量
capture_animation = 0;
capture_state = "ready";
target_enemy = noone;

// 戰鬥單位管理
player_units = ds_list_create();   // 玩家方單位
enemy_units = ds_list_create();    // 敵方單位
max_player_units = 2;              // 初始最大召喚數量
global_summon_cooldown = 0;        // 全局召喚冷卻
max_global_cooldown = 15 * game_get_speed(gamespeed_fps); // 15秒冷卻

// 戰鬥結果
battle_result = {
    victory: false,
    exp_gained: 0,
    gold_gained: 0,
    item_drops: [],
    defeated_enemies: 0,
    duration: 0
};

// 為Step事件中使用的變數提前宣告 (避免警告)
active = false;
from_preparing_phase = false;
ui_surface = -1;
ui_details_surface = -1;

// 初始化粒子系統 (用於視覺效果)
if (!variable_global_exists("particle_system")) {
    global.particle_system = part_system_create();
    global.pt_boundary = part_type_create();
    global.pt_death = part_type_create();
    global.pt_level_up = part_type_create();
}

// 初始化方法
initialize_battle = function() {
    // 清空單位列表
    ds_list_clear(player_units);
    ds_list_clear(enemy_units);
    
    // 重置計時器和冷卻
    battle_timer = 0;
    global_summon_cooldown = 0;
    battle_result_handled = false;
    
    // 重置戰鬥結果
battle_result = {
    victory: false,
    exp_gained: 0,
    gold_gained: 0,
    item_drops: [], // 確保陣列初始化
    defeated_enemies: 0,
    duration: 0
};
    
    show_debug_message("戰鬥管理器初始化完成");
}

// 啟動戰鬥函數
start_battle = function(initial_enemy) {
    if (battle_state != BATTLE_STATE.INACTIVE) return false;
    
    // 設置戰鬥狀態
    battle_state = BATTLE_STATE.STARTING;
    battle_boundary_radius = 10; // 初始很小，會逐漸擴大
    
    // 記錄戰鬥中心位置
    battle_center_x = initial_enemy.x;
    battle_center_y = initial_enemy.y;
    
    // 添加初始敵人到敵方單位列表
    ds_list_add(enemy_units, initial_enemy);
    
    // 將附近敵人也添加到戰鬥中
    var nearby_radius = 150;
    // 保存對當前實例的引用
    var battle_manager = id;
    
    with (obj_enemy_parent) {
        // 使用battle_manager引用來訪問正確的變量
        if (id != initial_enemy && 
            point_distance(x, y, battle_manager.battle_center_x, battle_manager.battle_center_y) <= nearby_radius) {
            ds_list_add(battle_manager.enemy_units, id);
        }
    }
    
    // 通知所有敵人進入戰鬥狀態
    for (var i = 0; i < ds_list_size(enemy_units); i++) {
        var enemy = enemy_units[| i];
        with (enemy) {
            if (variable_instance_exists(id, "enter_battle_mode")) {
                enter_battle_mode();
            }
        }
    }
    
    // 設置全局戰鬥標誌
    global.in_battle = true;
    
    // 顯示戰鬥UI - 確保UI被創建且正確初始化
    if (!instance_exists(obj_battle_ui)) {
        var ui_inst = instance_create_layer(0, 0, "Instances", obj_battle_ui);
        with (ui_inst) {
            show();  // 確保調用show方法
            active = true;
            visible = true;
            depth = -100;  // 確保正確的深度
        }
        show_debug_message("創建戰鬥UI，深度設為: " + string(ui_inst.depth));
    } else {
        with (obj_battle_ui) {
            show();
            active = true;
            visible = true;
        }
        show_debug_message("已存在戰鬥UI，設為活躍和可見");
    }
    
    // 創建準備階段遮罩
    if (!instance_exists(obj_battle_overlay)) {
        var overlay_inst = instance_create_layer(0, 0, "Instances", obj_battle_overlay);
        with (overlay_inst) {
            depth = -1000;  // 確保在最上層
            visible = true;
        }
        show_debug_message("創建戰鬥準備階段遮罩，深度設為: " + string(overlay_inst.depth));
    } else {
        with (obj_battle_overlay) {
            visible = true;
            depth = -1000;  // 再次確保深度正確
        }
        show_debug_message("已存在戰鬥準備階段遮罩，設為可見");
    }
    
    // 初始化全局戰鬥計數器
    if (!variable_global_exists("defeated_enemies_count")) {
        global.defeated_enemies_count = 0;
    } else {
        global.defeated_enemies_count = 0; // 重置
    }
    
    if (!variable_global_exists("defeated_player_units")) {
        global.defeated_player_units = 0;
    } else {
        global.defeated_player_units = 0; // 重置
    }
    
    add_battle_log("戰鬥開始準備! 敵人數量: " + string(ds_list_size(enemy_units)));
    show_debug_message("战斗开始准备! 敌人数量: " + string(ds_list_size(enemy_units)));
    return true;
}

// 結束戰鬥函數
end_battle = function() {
    // 恢復正常遊戲狀態
    battle_state = BATTLE_STATE.INACTIVE;
    battle_boundary_radius = 0;
    
    // 重置全局戰鬥標誌
    global.in_battle = false;
    
    // 移除戰鬥UI
    if (instance_exists(obj_battle_ui)) {
        instance_destroy(obj_battle_ui);
    }
    
    // 移除其他戰鬥相關UI
    if (instance_exists(obj_battle_overlay)) {
        instance_destroy(obj_battle_overlay);
    }
    
    // 清理單位
    for (var i = 0; i < ds_list_size(player_units); i++) {
        var unit = player_units[| i];
        if (instance_exists(unit)) {
            // 更新玩家的怪物數據（經驗值、狀態等）
            for (var j = 0; j < array_length(global.player_monsters); j++) {
                var monster_data = global.player_monsters[j];
                if (monster_data.type == unit.object_index) {
                    // 更新怪物數據
                    monster_data.level = unit.level;
                    monster_data.hp = unit.hp;
                    monster_data.max_hp = unit.max_hp;
                    monster_data.attack = unit.attack;
                    monster_data.defense = unit.defense;
                    monster_data.spd = unit.spd;
                    
                    // 可以在這裡添加更多數據更新
                    break;
                }
            }
            
            // 創建回收效果
            var recall_x = unit.x;
            var recall_y = unit.y;
            
            // 如果沒有特定的回收效果物件，可以創建一個簡單的視覺效果
            instance_create_layer(recall_x, recall_y, "Instances", obj_recall_effect);
            
            // 銷毀單位實例
            instance_destroy(unit);
        }
    }
    
    // 清空單位列表
    ds_list_clear(player_units);
    ds_list_clear(enemy_units);
    
    add_battle_log("戰鬥完全結束!");
    show_debug_message("戰鬥完全結束!");
}

// 優化的戰鬥邊界控制函數
enforce_battle_boundary = function() {
    // 戰鬥未激活時不處理邊界
    if (battle_state == BATTLE_STATE.INACTIVE) return;
    
    // 計算不同單位類型的邊界比例 (避免互相重疊)
    var player_boundary_ratio = 0.95; // 玩家保持在邊界95%處
    var ally_boundary_ratio = 0.92;   // 己方單位保持在邊界92%處
    var enemy_boundary_ratio = 0.88;  // 敵方單位保持在邊界88%處
    
    // 限制玩家角色
    if (instance_exists(global.player)) {
        var dist = point_distance(global.player.x, global.player.y, battle_center_x, battle_center_y);
        if (dist > battle_boundary_radius * player_boundary_ratio) {
            // 將玩家推回邊界內部
            var dir = point_direction(battle_center_x, battle_center_y, global.player.x, global.player.y);
            var target_x = battle_center_x + lengthdir_x(battle_boundary_radius * player_boundary_ratio, dir);
            var target_y = battle_center_y + lengthdir_y(battle_boundary_radius * player_boundary_ratio, dir);
            
            // 漸進式移動而非瞬間傳送 (提高平滑度)
            global.player.x = lerp(global.player.x, target_x, 0.2);
            global.player.y = lerp(global.player.y, target_y, 0.2);
            
            // 當玩家碰到邊界時顯示視覺提示
            if (!variable_instance_exists(id, "boundary_alert_timer") || boundary_alert_timer <= 0) {
                if (instance_exists(obj_battle_ui)) {
                    obj_battle_ui.show_info("無法離開戰鬥區域!");
                }
                boundary_alert_timer = game_get_speed(gamespeed_fps) * 3; // 3秒冷卻
            }
        }
    }
    
    // 更新邊界警告計時器
    if (variable_instance_exists(id, "boundary_alert_timer") && boundary_alert_timer > 0) {
        boundary_alert_timer--;
    }
    
    // 限制玩家單位 (召喚物)
    for (var i = 0; i < ds_list_size(player_units); i++) {
        var unit = player_units[| i];
        if (instance_exists(unit)) {
            var dist = point_distance(unit.x, unit.y, battle_center_x, battle_center_y);
            
            // 檢查是否超出邊界
            if (dist > battle_boundary_radius * ally_boundary_ratio) {
                // 將單位推回邊界內
                var dir = point_direction(battle_center_x, battle_center_y, unit.x, unit.y);
                var target_x = battle_center_x + lengthdir_x(battle_boundary_radius * ally_boundary_ratio, dir);
                var target_y = battle_center_y + lengthdir_y(battle_boundary_radius * ally_boundary_ratio, dir);
                
                // 依據單位類型調整移動方式
                if (variable_instance_exists(unit, "path_speed") && unit.path_speed > 0) {
                    // 中斷路徑尋找
                    unit.path_end();
                    
                    // 創建邊界效果提示
                    create_boundary_effect(unit.x, unit.y, c_lime);
                    
                    // 立即設置新位置
                    unit.x = target_x;
                    unit.y = target_y;
                } else {
                    // 緩慢推回 (用於普通移動)
                    unit.x = lerp(unit.x, target_x, 0.15);
                    unit.y = lerp(unit.y, target_y, 0.15);
                }
                
                // 特殊處理 - 如果單位具有追蹤AI，則重新設定目標
                if (variable_instance_exists(unit, "ai_mode") && unit.ai_mode == AI_MODE.PURSUIT) {
                    // 重新選擇目標
                    with (unit) {
                        find_new_target();
                    }
                }
            }
        }
    }
    
    // 限制敵方單位
    for (var i = 0; i < ds_list_size(enemy_units); i++) {
        var unit = enemy_units[| i];
        if (instance_exists(unit)) {
            var dist = point_distance(unit.x, unit.y, battle_center_x, battle_center_y);
            
            // 檢查是否超出邊界
            if (dist > battle_boundary_radius * enemy_boundary_ratio) {
                // 將單位推回邊界內
                var dir = point_direction(battle_center_x, battle_center_y, unit.x, unit.y);
                var target_x = battle_center_x + lengthdir_x(battle_boundary_radius * enemy_boundary_ratio, dir);
                var target_y = battle_center_y + lengthdir_y(battle_boundary_radius * enemy_boundary_ratio, dir);
                
                // 依據單位類型調整移動方式
                if (variable_instance_exists(unit, "is_boss") && unit.is_boss) {
                    // Boss 單位特殊處理 - 更慢推回，避免打斷技能
                    unit.x = lerp(unit.x, target_x, 0.08);
                    unit.y = lerp(unit.y, target_y, 0.08);
                    
                    // 創建視覺效果
                    create_boundary_effect(unit.x, unit.y, c_red);
                } else if (variable_instance_exists(unit, "path_speed") && unit.path_speed > 0) {
                    // 有路徑的敵人 - 中斷路徑
                    unit.path_end();
                    
                    // 立即設置新位置
                    unit.x = target_x;
                    unit.y = target_y;
                } else {
                    // 普通敵人 - 正常推回
                    unit.x = lerp(unit.x, target_x, 0.12);
                    unit.y = lerp(unit.y, target_y, 0.12);
                }
                
                // 敵人碰到邊界時的特殊行為
                if (variable_instance_exists(unit, "on_boundary_hit") && 
                    is_method(unit.on_boundary_hit)) {
                    unit.on_boundary_hit();
                } else {
                    // 預設行為 - 重新選擇目標
                    with (unit) {
                        if (variable_instance_exists(id, "find_new_target")) {
                            find_new_target();
                        }
                    }
                }
            }
        }
    }
};

// 關閉所有活躍的UI函數
close_all_active_uis = function() {
    // 確保UI管理器存在
    if (instance_exists(obj_ui_manager)) {
        // 關閉主層UI
        if (ds_map_exists(obj_ui_manager.active_ui, "main")) {
            var main_ui = obj_ui_manager.active_ui[? "main"];
            if (instance_exists(main_ui)) {
                obj_ui_manager.hide_ui(main_ui);
            }
        }
        
        // 關閉浮層UI
        if (ds_map_exists(obj_ui_manager.active_ui, "overlay")) {
            var overlay_ui = obj_ui_manager.active_ui[? "overlay"];
            if (instance_exists(overlay_ui)) {
                obj_ui_manager.hide_ui(overlay_ui);
            }
        }
        
        // 或者使用層級關閉函數
        obj_ui_manager.hide_layer("main");
        obj_ui_manager.hide_layer("overlay");
        
        show_debug_message("已在戰鬥階段切換時關閉所有UI");
    } else {
        // 直接通過實例關閉
        if (instance_exists(obj_summon_ui)) {
            with (obj_summon_ui) {
                hide();
            }
        }
        
        if (instance_exists(obj_monster_manager_ui)) {
            with (obj_monster_manager_ui) {
                hide();
            }
        }
        
        if (instance_exists(obj_capture_ui)) {
            with (obj_capture_ui) {
                hide();
            }
        }
    }
};

// 戰鬥獎勵發放
grant_rewards = function() {
    if (battle_result_handled) return; // 確保只處理一次
    
    var total_exp = 0;
    var total_gold = 0;
    var item_rewards = []; // 確保陣列初始化
    
    // 計算經驗值和金錢獎勵
    for (var i = 0; i < global.defeated_enemies_count; i++) {
        // 隨機經驗值（可根據敵人類型調整）
        var exp_base = 25 + (5 * global.defeated_enemies_count);
        var exp_variance = exp_base * 0.2; // 20% 變異
        var exp_gained = exp_base + random_range(-exp_variance, exp_variance);
        
        // 隨機金錢
        var gold_base = 10 + (2 * global.defeated_enemies_count);
        var gold_variance = gold_base * 0.3; // 30% 變異
        var gold_gained = gold_base + random_range(-gold_variance, gold_variance);
        
        total_exp += round(exp_gained);
        total_gold += round(gold_gained);
        
        // 小概率獲得道具（10%機率每個敵人）
        if (random(1) < 0.1) {
            // 假設有一個道具ID表（此處簡化為0-9的數字）
            var item_id = irandom(9);
            array_push(item_rewards, item_id);
        }
    }
    
    // 將經驗值分配給參與戰鬥的怪物
    if (ds_list_size(player_units) > 0) {
        var exp_per_unit = total_exp / ds_list_size(player_units);
        
        for (var i = 0; i < ds_list_size(player_units); i++) {
            var unit = player_units[| i];
            if (instance_exists(unit) && variable_instance_exists(unit, "gain_exp")) {
                unit.gain_exp(exp_per_unit);
                
                // 更新怪物經驗值
                for (var j = 0; j < array_length(global.player_monsters); j++) {
                    var monster_data = global.player_monsters[j];
                    if (monster_data.type == unit.object_index) {
                        monster_data.exp += exp_per_unit;
                        
                        // 檢查升級條件（簡化的等級系統）
                        var next_level_exp = monster_data.level * 100;
                        if (monster_data.exp >= next_level_exp) {
                            monster_data.level++;
                            monster_data.exp -= next_level_exp;
                            monster_data.max_hp += irandom_range(5, 15);
                            monster_data.attack += irandom_range(1, 3);
                            monster_data.defense += irandom_range(1, 2);
                            monster_data.spd += irandom_range(0, 1);
                            
                            // 在下一輪戰鬥中應用升級屬性
                            show_debug_message(object_get_name(monster_data.type) + 
                                            " 升到等級 " + string(monster_data.level) + "!");
                        }
                        break;
                    }
                }
            }
        }
    }
    
    // 增加玩家金錢
    if (variable_global_exists("player_gold")) {
        global.player_gold += total_gold;
    } else {
        global.player_gold = total_gold; // 如果不存在，創建
    }
    
    // 添加獲得的道具（假設有一個全局道具數組）
    if (!variable_global_exists("player_items")) {
        global.player_items = [];
    }
    
    for (var i = 0; i < array_length(item_rewards); i++) {
        array_push(global.player_items, item_rewards[i]);
    }
    
    // 更新戰鬥結果數據
    battle_result.exp_gained = total_exp;
    battle_result.gold_gained = total_gold;
    battle_result.item_drops = [];
for (var i = 0; i < array_length(item_rewards); i++) {
    array_push(battle_result.item_drops, item_rewards[i]);
}
    
    // 更新UI顯示獎勵
    if (instance_exists(obj_battle_ui)) {
        obj_battle_ui.show_rewards(total_exp, total_gold, item_rewards);
    }
    
    // 標記為已處理
    battle_result_handled = true;
    
    add_battle_log("戰鬥獎勵已發放: 經驗=" + string(total_exp) + 
                 ", 金錢=" + string(total_gold) + 
                 ", 道具=" + string(array_length(item_rewards)));
    show_debug_message("獲得經驗值：" + string(total_exp) + ", 金錢：" + string(total_gold));
};

// 戰鬥失敗處理
handle_defeat = function() {
    // 計算懲罰 - 例如金錢損失
    var gold_loss = 0;
    if (variable_global_exists("player_gold")) {
        gold_loss = round(global.player_gold * 0.1); // 損失10%金錢
        global.player_gold -= gold_loss;
        global.player_gold = max(0, global.player_gold); // 確保不會變成負數
    }
    
    // 怪物HP降低
    if (variable_global_exists("player_monsters")) {
        for (var i = 0; i < array_length(global.player_monsters); i++) {
            var monster = global.player_monsters[i];
            // 所有參戰的怪物HP減半
            var was_in_battle = false;
            for (var j = 0; j < ds_list_size(player_units); j++) {
                if (instance_exists(player_units[| j]) && player_units[| j].object_index == monster.type) {
                    was_in_battle = true;
                    break;
                }
            }
            
            if (was_in_battle) {
                monster.hp = max(1, floor(monster.hp * 0.5)); // 至少保留1點HP
            }
        }
    }
    
    // 顯示失敗訊息
    if (instance_exists(obj_battle_ui)) {
        obj_battle_ui.show_info("戰鬥失敗! 損失 " + string(gold_loss) + " 金錢");
    }
    
    add_battle_log("戰鬥失敗處理完成: 損失金錢=" + string(gold_loss));
    show_debug_message("戰鬥失敗處理完成: 損失金錢=" + string(gold_loss));
};

// 處理戰鬥過程中的單位死亡
handle_unit_death = function(unit) {
    if (!instance_exists(unit)) return;
    
    // 判斷單位屬於哪個陣營
    var is_player_unit = (ds_list_find_index(player_units, unit) != -1);
    var is_enemy_unit = (ds_list_find_index(enemy_units, unit) != -1);
    
    if (!is_player_unit && !is_enemy_unit) {
        // 單位不在戰鬥中
        return;
    }
    
    if (is_player_unit) {
        // 處理玩家單位死亡
        ds_list_delete(player_units, ds_list_find_index(player_units, unit));
        
        // 檢查是否所有玩家單位都死亡
        if (ds_list_size(player_units) <= 0) {
            // 如果是準備階段，給玩家更多時間召喚
            if (battle_state == BATTLE_STATE.PREPARING) {
                if (instance_exists(obj_battle_ui)) {
                    obj_battle_ui.show_info("請召喚更多單位！");
                }
            } else {
                // 否則進入結束階段
                battle_state = BATTLE_STATE.ENDING;
            }
        }
        
        // 記錄死亡單位
        global.defeated_player_units++;
        add_battle_log("玩家單位陣亡: " + object_get_name(unit.object_index));
        
    } else if (is_enemy_unit) {
        // 處理敵方單位死亡
        ds_list_delete(enemy_units, ds_list_find_index(enemy_units, unit));
        
        // 增加擊敗敵人計數
        global.defeated_enemies_count++;
        
        // 檢查是否所有敵人都已擊敗
        if (ds_list_size(enemy_units) <= 0) {
            battle_state = BATTLE_STATE.ENDING;
        }
        
        add_battle_log("擊敗敵人: " + object_get_name(unit.object_index));
    }
    
    // 死亡動畫和音效
    var death_x = unit.x;
    var death_y = unit.y;
    
    // 創建死亡特效
    if (object_exists(obj_death_effect)) {
        instance_create_layer(death_x, death_y, "Instances", obj_death_effect);
    } else {
        // 使用粒子系統 (如果沒有特效物件)
        if (variable_global_exists("pt_death")) {
            // 簡單的死亡粒子效果
            part_type_shape(global.pt_death, pt_shape_pixel);
            part_type_size(global.pt_death, 1, 3, -0.05, 0);
            part_type_color3(global.pt_death, c_red, c_orange, c_yellow);
            part_type_alpha3(global.pt_death, 1, 0.8, 0);
            part_type_speed(global.pt_death, 1, 3, -0.1, 0);
            part_type_direction(global.pt_death, 0, 360, 0, 20);
            part_type_life(global.pt_death, 20, 30);
            
            part_particles_create(global.particle_system, death_x, death_y, global.pt_death, 30);
        }
    }
    
    // 播放死亡音效
    if (audio_exists(snd_unit_death)) {
        audio_play_sound(snd_unit_death, 10, false);
    }
    
    // 銷毀單位實例
    instance_destroy(unit);
    
    show_debug_message("單位死亡處理完成: " + (is_player_unit ? "玩家單位" : "敵方單位"));
};

// 用於創建戰鬥日誌的函數
add_battle_log = function(message) {
    if (!variable_global_exists("battle_log")) {
        global.battle_log = ds_list_create();
    }
    
    // 添加時間戳
    var time_stamp = string_format(battle_timer / game_get_speed(gamespeed_fps), 2, 1);
    var full_message = "[" + time_stamp + "s] " + message;
    
    // 添加到日誌
    ds_list_add(global.battle_log, full_message);
    
    // 限制日誌大小，避免佔用太多內存
    if (ds_list_size(global.battle_log) > 100) {
        ds_list_delete(global.battle_log, 0);
    }
    
    // 在UI中顯示最新日誌訊息
    if (instance_exists(obj_battle_ui)) {
        obj_battle_ui.battle_info = full_message;
    }
    
    show_debug_message("戰鬥日誌: " + full_message);
};

// 設置戰鬥難度
set_battle_difficulty = function(difficulty) {
    // 難度範圍: 0=簡單, 1=普通, 2=困難
    difficulty = clamp(difficulty, 0, 2);
    
    switch(difficulty) {
        case 0: // 簡單
            // 減少敵人數值
            for (var i = 0; i < ds_list_size(enemy_units); i++) {
                var enemy = enemy_units[| i];
                if (instance_exists(enemy)) {
                    enemy.attack *= 0.8; // 減少攻擊力
                    enemy.defense *= 0.8; // 減少防禦力
                    enemy.atb_rate *= 0.9; // 降低ATB充能速率
                }
            }
            
            // 增加玩家優勢
            max_player_units = 3; // 允許多召喚一個單位
            max_global_cooldown *= 0.7; // 減少召喚冷卻時間
            
            add_battle_log("設置戰鬥難度: 簡單");
            break;
            
        case 1: // 普通 (預設值)
            max_player_units = 2;
            add_battle_log("設置戰鬥難度: 普通");
            break;
            
        case 2: // 困難
            // 增強敵人
            for (var i = 0; i < ds_list_size(enemy_units); i++) {
                var enemy = enemy_units[| i];
                if (instance_exists(enemy)) {
                    enemy.attack *= 1.2; // 增加攻擊力
                    enemy.defense *= 1.2; // 增加防禦力
                    enemy.atb_rate *= 1.1; // 提高ATB充能速率
                }
            }
            
            // 降低玩家優勢
            max_global_cooldown *= 1.3; // 增加召喚冷卻時間
            
            add_battle_log("設置戰鬥難度: 困難");
            break;
    }
    
    global.battle_difficulty = difficulty;
    
    // 如果在準備階段，更新UI提示
    if (battle_state == BATTLE_STATE.PREPARING && instance_exists(obj_battle_ui)) {
        var difficulty_text = "";
        switch(difficulty) {
            case 0: difficulty_text = "簡單"; break;
            case 1: difficulty_text = "普通"; break;
            case 2: difficulty_text = "困難"; break;
        }
        
        obj_battle_ui.show_info("難度已設置為: " + difficulty_text);
    }
};

// 玩家召喚怪物
summon_monster = function(monster_type) {
    if (battle_state != BATTLE_STATE.ACTIVE && battle_state != BATTLE_STATE.PREPARING) {
        show_debug_message("戰鬥未激活，無法召喚");
        return false;
    }
    
    // 檢查是否達到最大召喚數量
    if (ds_list_size(player_units) >= max_player_units) {
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("已達最大召喚數量!");
        }
        show_debug_message("已達最大召喚數量: " + string(max_player_units));
        return false;
    }
    
    // 檢查全局召喚冷卻時間
    if (battle_state == BATTLE_STATE.ACTIVE && global_summon_cooldown > 0) {
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("召喚冷卻中! 剩餘: " + 
                                 string_format(global_summon_cooldown / game_get_speed(gamespeed_fps), 1, 1) + "秒");
        }
        show_debug_message("召喚冷卻中: " + string(global_summon_cooldown));
        return false;
    }
    
    // 檢查玩家是否有該怪物
    var has_monster = false;
    var monster_index = -1;
    for (var i = 0; i < array_length(global.player_monsters); i++) {
        if (global.player_monsters[i].type == monster_type) {
            has_monster = true;
            monster_index = i;
            break;
        }
    }
    
    if (!has_monster) {
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("你沒有這個怪物!");
        }
        show_debug_message("玩家沒有怪物類型: " + object_get_name(monster_type));
        return false;
    }
    
    // 計算召喚位置（靠近玩家但在戰鬥區域內部）
    var summon_x = global.player.x;
    var summon_y = global.player.y - 20; // 略微偏上
    
    // 確保位置在戰鬥範圍內
    var dist_to_center = point_distance(summon_x, summon_y, battle_center_x, battle_center_y);
    if (dist_to_center > battle_boundary_radius * 0.8) {
        var dir = point_direction(battle_center_x, battle_center_y, summon_x, summon_y);
        summon_x = battle_center_x + lengthdir_x(battle_boundary_radius * 0.7, dir);
        summon_y = battle_center_y + lengthdir_y(battle_boundary_radius * 0.7, dir);
    }
    
    // 創建怪物實例
    var monster_inst = instance_create_layer(summon_x, summon_y, "Instances", monster_type);
    
    // 設置怪物屬性（從玩家擁有的怪物數據中獲取）
    if (monster_index != -1) {
        var monster_data = global.player_monsters[monster_index];
        monster_inst.level = monster_data.level;
        monster_inst.hp = monster_data.hp;
        monster_inst.max_hp = monster_data.max_hp;
        monster_inst.attack = monster_data.attack;
        monster_inst.defense = monster_data.defense;
        monster_inst.spd = monster_data.spd;
        
        // 可以在這裡設置更多屬性
    }
    
    // 初始化戰鬥相關屬性
    monster_inst.player_controlled = true; // 標記為玩家控制的單位
    monster_inst.atb_current = 0;
    monster_inst.atb_max = 100;
    monster_inst.atb_ready = false;
    monster_inst.is_acting = false;
    monster_inst.current_skill = noone;
    
    // 添加到玩家單位列表
    ds_list_add(player_units, monster_inst);
    
    // 設置全局召喚冷卻時間（只有在戰鬥活躍階段才設置）
    if (battle_state == BATTLE_STATE.ACTIVE) {
        global_summon_cooldown = max_global_cooldown;
    }
    
    // 召喚特效
    instance_create_layer(summon_x, summon_y, "Instances", obj_summon_effect);
    
    // 音效
    if (audio_exists(snd_summon)) {
        audio_play_sound(snd_summon, 10, false);
    }
    
    if (instance_exists(obj_battle_ui)) {
        obj_battle_ui.show_info(object_get_name(monster_type) + " 已召喚!");
    }
    
    add_battle_log("玩家召喚了 " + object_get_name(monster_type));
    show_debug_message("成功召喚怪物: " + object_get_name(monster_type));
    return true;
};

// 嘗試捕捉敵人
try_capture_enemy = function(target) {
    if (!instance_exists(target) || ds_list_find_index(enemy_units, target) == -1) {
        show_debug_message("無效的捕捉目標!");
        return false;
    }
    
    // 計算捕捉成功率
    var hp_percent = target.hp / target.max_hp;
    var base_chance = 0.8; // 80% 基礎捕捉率
    var chance_modifier = 1 - hp_percent; // HP越低，成功率越高
    
    var final_chance = base_chance + (chance_modifier * 0.3); // 最高額外 +30%
    final_chance = clamp(final_chance, 0.1, 0.95); // 限制在 10% - 95% 之間
    
    show_debug_message("捕捉嘗試: HP%=" + string(hp_percent) + ", 成功率=" + string(final_chance));
    
    // 保存捕捉目標引用
    target_enemy = target;
    
    // 開始捕捉動畫
    capture_state = "animating";
    capture_animation = 0;
    
    // 音效
    if (audio_exists(snd_capture_attempt)) {
        audio_play_sound(snd_capture_attempt, 10, false);
    }
    
    // 決定是否成功捕捉
    var roll = random(1);
    var success = (roll <= final_chance);
    
    add_battle_log("嘗試捕獲 " + object_get_name(target.object_index) + 
                 ", 成功率: " + string(round(final_chance * 100)) + "%");
    show_debug_message("捕捉結果: 擲骰=" + string(roll) + ", 成功=" + string(success));
    
    // 延遲效果處理 - 將在Step中的capture_animation階段處理
    return true;
};

// 處理捕捉結果
handle_capture_result = function(success) {
    if (!instance_exists(target_enemy) || ds_list_find_index(enemy_units, target_enemy) == -1) {
        capture_state = "ready";
        target_enemy = noone;
        show_debug_message("捕捉目標已消失!");
        return false;
    }
    
    if (success) {
        // 捕捉成功
        show_debug_message("捕捉成功: " + object_get_name(target_enemy.object_index));
        var monster_name = object_get_name(target_enemy.object_index);
        // 將敵人添加到玩家的怪物集合中
        var monster_data = {
            type: target_enemy.object_index,
            name: object_get_name(target_enemy.object_index),
            level: target_enemy.level,
            hp: target_enemy.hp,
            max_hp: target_enemy.max_hp,
            attack: target_enemy.attack,
            defense: target_enemy.defense,
            spd: target_enemy.spd,
            exp: 0,
            skills: [] // 可能需要複製技能
        };
        
        // 將怪物加入到玩家擁有的怪物列表中
        array_push(global.player_monsters, monster_data);
        
        // 顯示成功訊息
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info(monster_name + " 被成功捕獲!");
        }
        
        // 從敵人列表中移除
        ds_list_delete(enemy_units, ds_list_find_index(enemy_units, target_enemy));
        
        // 播放成功音效
        if (audio_exists(snd_capture_success)) {
            audio_play_sound(snd_capture_success, 10, false);
        }
        
        // 創建捕獲特效
        if (object_exists(obj_capture_success_effect)) {
            instance_create_layer(target_enemy.x, target_enemy.y, "Instances", obj_capture_success_effect);
        }
        
        // 銷毀敵人實例
        instance_destroy(target_enemy);
        
        // 檢查戰鬥結束條件
        if (ds_list_size(enemy_units) <= 0) {
            battle_state = BATTLE_STATE.ENDING;
        }
        
        add_battle_log(monster_name + " 被成功捕獲並加入隊伍!");
    } else {
        // 捕捉失敗
        show_debug_message("捕捉失敗!");
        
        // 顯示失敗訊息
        if (instance_exists(obj_battle_ui)) {
            var monster_name = object_get_name(target_enemy.object_index);
            obj_battle_ui.show_info(monster_name + " 掙脫了!");
        }
        
        // 播放失敗音效
        if (audio_exists(snd_capture_fail)) {
            audio_play_sound(snd_capture_fail, 10, false);
        }
        
        // 創建失敗特效
        if (object_exists(obj_capture_fail_effect)) {
            instance_create_layer(target_enemy.x, target_enemy.y, "Instances", obj_capture_fail_effect);
        }
        
        // 敵人可能有反應（例如憤怒狀態）
        with (target_enemy) {
            if (variable_instance_exists(id, "on_capture_fail")) {
                on_capture_fail();
            }
        }
        
        add_battle_log("捕獲 " + object_get_name(target_enemy.object_index) + " 失敗");
    }
    
    // 重置捕捉狀態
    capture_state = "ready";
    target_enemy = noone;
    
    return success;
};

// 創建邊界效果
create_boundary_effect = function(x_pos, y_pos, color) {
    // 檢查是否有邊界效果物件，如果沒有則使用通用效果
    var effect_obj = asset_get_index("obj_boundary_effect");
    if (!object_exists(effect_obj)) {
        effect_obj = asset_get_index("obj_effect"); // 使用通用效果物件
        
        // 如果連通用效果物件都不存在，則使用粒子
        if (!object_exists(effect_obj)) {
            // 簡單的內建粒子效果
            if (variable_global_exists("pt_boundary") && part_type_exists(global.pt_boundary)) {
                part_type_shape(global.pt_boundary, pt_shape_ring);
                part_type_size(global.pt_boundary, 0.5, 1.5, -0.05, 0.1);
                part_type_color1(global.pt_boundary, color);
                part_type_alpha2(global.pt_boundary, 0.8, 0);
                part_type_speed(global.pt_boundary, 0.5, 2, -0.1, 0.1);
                part_type_direction(global.pt_boundary, 0, 360, 0, 20);
                part_type_life(global.pt_boundary, 20, 30);
                
                part_particles_create(global.particle_system, x_pos, y_pos, global.pt_boundary, 10);
            }
            return;
        }
    }
    
    // 創建視覺效果物件
    var effect = instance_create_layer(x_pos, y_pos, "Effects", effect_obj);
    if (instance_exists(effect)) {
        effect.image_blend = color;
        effect.depth = -100; // 確保效果顯示在單位上方
    }
};

// 在第一次创建时初始化
initialize_battle();