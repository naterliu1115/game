// 确保速度为0
speed = 0;

// 只在战斗状态下更新
if (!instance_exists(obj_battle_manager) || obj_battle_manager.battle_state != BATTLE_STATE.ACTIVE || dead) {
    // 非战斗状态下不移动
    exit;
}

// 更新ATB
if (!atb_ready && !is_acting) {
    atb_current += atb_rate;
    
    // 调试输出ATB状态（每秒一次）
    if (variable_global_exists("battle_timer") && global.battle_timer % 60 == 0) {
        show_debug_message(object_get_name(object_index) + " (ID: " + string(id) + ", team: " + string(team) + ") ATB: " + string(atb_current) + "/" + string(atb_max) + " (率: " + string(atb_rate) + ")");
    }
    
    if (atb_current >= atb_max) {
        atb_current = atb_max;
        atb_ready = true;
        // 准备行动
        prepare_action();
    }
}

// 更新技能冷却
var _keys = ds_map_keys_to_array(skill_cooldowns);
for (var i = 0; i < array_length(_keys); i++) {
    var _skill_id = _keys[i];
    var _cooldown = skill_cooldowns[? _skill_id];
    if (_cooldown > 0) {
        _cooldown--;
        ds_map_set(skill_cooldowns, _skill_id, _cooldown);
    }
}

// AI决策和行动
if (atb_ready && !is_acting) {
    execute_ai_action();
}