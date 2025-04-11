/// @description 初始化測試攻擊者

// 基本屬性
name = "測試攻擊者";
attack = 0;  // 將由測試控制器設置
target = noone;  // 將由測試控制器設置
current_skill = noone;  // 將由測試控制器設置

// 應用技能傷害
apply_skill_damage = function() {
    if (target == noone || !instance_exists(target) || current_skill == noone) {
        show_debug_message("[傷害系統] 應用傷害取消：無效的目標或技能。");
        show_debug_message("- 目標存在：" + string(target != noone));
        show_debug_message("- 實例存在：" + string(instance_exists(target)));
        show_debug_message("- 技能存在：" + string(current_skill != noone));
        return;
    }
    
    // 詳細的傷害計算日誌
    show_debug_message("\n[傷害系統] 開始計算傷害");
    show_debug_message("------------------------");
    
    var multiplier = variable_struct_exists(current_skill, "damage_multiplier") ? current_skill.damage_multiplier : 0;
    show_debug_message("技能倍率：" + string(multiplier));
    
    var attacker_attack = attack;
    show_debug_message("攻擊者攻擊力：" + string(attacker_attack));
    
    var calculated_damage = attacker_attack * multiplier;
    show_debug_message("基礎傷害 (攻擊力×倍率)：" + string(calculated_damage));
    
    var target_defense = 0;
    if (variable_instance_exists(target, "defense") && is_real(target.defense)) {
        target_defense = target.defense;
        show_debug_message("目標防禦力：" + string(target_defense));
    } else {
        show_debug_message("警告：目標防禦力無效，使用預設值 0");
    }
    
    calculated_damage = max(1, calculated_damage - target_defense);
    show_debug_message("最終傷害 (考慮防禦後)：" + string(calculated_damage));
    show_debug_message("------------------------");
    
    // 應用傷害
    with (target) {
        take_damage(calculated_damage, other.id, other.current_skill.id);
    }
} 