// obj_unit_manager - Step_0.gml

// 更新全局冷卻
if (global_summon_cooldown > 0) {
    global_summon_cooldown--;
}

// 清理不存在的單位引用
for (var i = ds_list_size(player_units) - 1; i >= 0; i--) {
    if (!instance_exists(player_units[| i])) {
        ds_list_delete(player_units, i);
    }
}

for (var i = ds_list_size(enemy_units) - 1; i >= 0; i--) {
    if (!instance_exists(enemy_units[| i])) {
        ds_list_delete(enemy_units, i);
    }
}

// 如果戰鬥正在進行，處理戰鬥邊界約束
if (global.in_battle && battle_boundary_radius > 0) {
    enforce_battle_boundary();
}

// 輔助函數：強制單位在戰鬥邊界內
enforce_battle_boundary = function() {
    // 計算不同單位類型的邊界比例 (避免互相重疊)
    var player_boundary_ratio = 0.95; // 玩家保持在邊界95%處
    var ally_boundary_ratio = 0.92;   // 己方單位保持在邊界92%處
    var enemy_boundary_ratio = 0.88;  // 敵方單位保持在邊界88%處
    
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
                
                // 緩慢推回 (用於普通移動)
                unit.x = lerp(unit.x, target_x, 0.15);
                unit.y = lerp(unit.y, target_y, 0.15);
                
                // 特殊處理 - 如果單位具有追蹤AI，則重新設定目標
                if (variable_instance_exists(unit, "ai_mode") && unit.ai_mode == AI_MODE.PURSUIT) {
                    // 重新選擇目標
                    with (unit) {
                        if (variable_instance_exists(id, "find_new_target")) {
                            find_new_target();
                        }
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