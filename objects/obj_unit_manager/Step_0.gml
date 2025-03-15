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

// 在 Step 事件中
if (global.in_battle && battle_boundary_radius > 0) {
    enforce_battle_boundary();  // 調用在 Create 事件中定義的函數
}