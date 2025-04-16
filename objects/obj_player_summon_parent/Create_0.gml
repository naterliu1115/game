// 继承父类的创建事件
event_inherited();

// 设置队伍为玩家方
team = 0;

// 玩家召唤物特有属性
return_after_battle = true;  // 战斗后是否返回玩家的"队伍"
stamina = 100;               // 特殊耐力值，可用于延长战场时间
preferred_distance = 100;    // 与目标的理想战斗距离

// 移除 experience_to_level_up，改為從全局Map讀取
// experience_to_level_up = 100;
experience = 0;

// obj_player_summon_parent - level_up 函數與經驗值系統

// 級別提升函數 (不再處理連續升級或計算下一級經驗)
function level_up() {
    // 查找當前等級對應的下一級所需經驗 (用於判斷是否已是最高級)
    var _exp_for_next = ds_map_find_value(global.level_exp_map, level);
    if (is_undefined(_exp_for_next)) {
        show_debug_message(name + " 已經達到最高等級 (" + string(level) + ")，無法再升級。");
        return; // 如果已經是最高等級（在Map中找不到當前等級），則不執行升級
    }
    
    var _old_level = level;
    level++;
    // 升級時扣除經驗值，確保能連續升級
    experience -= _exp_for_next;
    show_debug_message("[Level Up] " + name + " 從 Lv." + string(_old_level) + " 升級至 Lv." + string(level) + "!");
    
    // 屬性提升 (保持不變)
    var hp_increase = 5 + irandom(10);
    var atk_increase = 1 + irandom(2);
    var def_increase = 1 + irandom(1);
    var spd_increase = random(1) < 0.7 ? 1 : 0; 
    
    max_hp += hp_increase;
    hp += hp_increase; 
    attack += atk_increase;
    defense += def_increase;
    spd += spd_increase;
    
    show_debug_message("    屬性提升: HP+" + string(hp_increase) + ", ATK+" + string(atk_increase) + ", DEF+" + string(def_increase) + ", SPD+" + string(spd_increase));
    
    // 更新ATB充能率 (保持不變)
    atb_rate = 1 + (spd * 0.1);
    
    // 升級特效 (保持不變)
    create_level_up_effect();
    
    // 音效 (修正版)
    if (variable_instance_exists(id, "snd_level_up") && audio_exists(snd_level_up)) {
        audio_play_sound(snd_level_up, 10, false);
    } else {
        show_debug_message("[LevelUp] 未設置升級音效，跳過播放。");
    }
    
    // --- 升級時檢查學習新技能 (使用我們之前討論的邏輯) ---
    if (variable_instance_exists(id, "template_skills") && variable_instance_exists(id, "template_skill_unlock_levels")) {
        var _num_template_skills = array_length(template_skills);
        show_debug_message("  [Level Up Skill Check] Unit: " + name + ", New Level: " + string(level) + ", Checking " + string(_num_template_skills) + " template skills.");

        for (var i = 0; i < _num_template_skills; i++) {
            var _skill_id_to_check = template_skills[i];
            var _unlock_level_required = (i < array_length(template_skill_unlock_levels)) ? template_skill_unlock_levels[i] : 1;

            if (level >= _unlock_level_required) {
                // 假設 obj_battle_unit_parent 中存在統一的 has_skill(skill_id) 方法
                if (variable_instance_exists(id, "has_skill")) {
                    if (!has_skill(_skill_id_to_check)) {
                        if (variable_instance_exists(id, "add_skill")) {
                            show_debug_message("    -> Level " + string(level) + " >= " + string(_unlock_level_required) + ", Skill '" + string(_skill_id_to_check) + "' not learned. Adding...");
                            add_skill(_skill_id_to_check);
                        } else {
                            show_debug_message("    -> ERROR: Cannot learn skill " + string(_skill_id_to_check) + " - add_skill method missing!");
                        }
                    } 
                } else {
                     show_debug_message("    -> ERROR: Cannot check skill " + string(_skill_id_to_check) + " - has_skill method missing!");
                     break; 
                }
            } 
        }
    } else {
         show_debug_message("  [Level Up Skill Check] Warning: Template skill data missing for " + name);
    }
    // --- 技能檢查結束 ---

    // 在戰鬥日誌中記錄 (保持不變)
    if (instance_exists(obj_battle_manager)) {
        with (obj_battle_manager) {
            add_battle_log(object_get_name(other.object_index) + " 升級至 " + string(other.level) + " 級!");
        }
    }
    
    // --- 升級後同步到 global.player_monsters ---
    if (variable_global_exists("player_monsters")) {
        for (var i = 0; i < array_length(global.player_monsters); ++i) {
            var m = global.player_monsters[i];
            show_debug_message("[LevelUp][SyncTest] index=" + string(i) + " type=" + string(m.type) + ", name=" + string(m.name) + ", level=" + string(m.level) + ", hp=" + string(m.hp) + ", max_hp=" + string(m.max_hp) + ", atk=" + string(m.attack) + ", def=" + string(m.defense) + ", spd=" + string(m.spd) + ", exp=" + string(m.exp));
            show_debug_message("[LevelUp][SyncTest] instance: type=" + string(object_index) + ", name=" + string(name) + ", level=" + string(level) + ", hp=" + string(hp) + ", max_hp=" + string(max_hp) + ", atk=" + string(attack) + ", def=" + string(defense) + ", spd=" + string(spd) + ", exp=" + string(experience));
        }
    }
}

// 建立升級特效 (使用粒子系統 + obj_floating_text)
create_level_up_effect = function() {
    // --- 1. 顯示 "Level Up!" 浮動文字 (保留) ---
    if (object_exists(obj_floating_text)) {
        var _text_effect = instance_create_layer(x, y - 32, "Effects", obj_floating_text);
        if (instance_exists(_text_effect)) {
            _text_effect.display_text = "Level Up!";
            _text_effect.text_color = c_yellow;
            _text_effect.scale = 1.3;
            _text_effect.float_speed = 0.7;
            _text_effect.duration = game_get_speed(gamespeed_fps) * 1.5;
        } else {
            show_debug_message("警告：未能創建 Level Up 文字特效實例。");
        }
    } else {
        show_debug_message("警告：obj_floating_text 物件資源不存在，無法創建 Level Up 文字特效。");
    }

    // --- 2. 創建粒子效果或物件特效 ---
    var effect_created = false;
    if (variable_global_exists("particle_system") && part_system_exists(global.particle_system)) {
        if (variable_global_exists("global.pt_level_up_sparkle") && part_type_exists(global.pt_level_up_sparkle)) {
            part_particles_create(global.particle_system, x, y, global.pt_level_up_sparkle, 25);
            show_debug_message("創建了 Level Up 火花粒子。");
            effect_created = true;
        } else {
            show_debug_message("警告：全局升級火花粒子類型 global.pt_level_up_sparkle 未定義或無效。");
        }
    } else {
        show_debug_message("警告：全局粒子系統 global.particle_system 不存在或無效，無法創建升級粒子特效。");
    }
    // 若無法產生粒子，則自動生成 obj_levelup_effect
    if (!effect_created) {
        if (object_exists(obj_levelup_effect)) {
            instance_create_layer(x, y, "Effects", obj_levelup_effect);
            show_debug_message("[LevelUp] 使用 obj_levelup_effect 物件產生火花動畫。");
        } else {
            show_debug_message("[LevelUp] 警告：obj_levelup_effect 物件不存在，無法產生火花動畫。");
        }
    }
}

// 獲得經驗值 (負責檢查升級和處理連續升級)
function gain_exp(exp_amount) {
    // 檢查必需的變數是否存在
    if (!variable_instance_exists(id, "experience")) {
        experience = 0;
        show_debug_message("警告： " + name + " 的 experience 變數不存在，已初始化為 0。");
    }
    if (!variable_instance_exists(id, "level")) {
        level = 1;
        show_debug_message("警告： " + name + " 的 level 變數不存在，已初始化為 1。");
    }
    // 檢查全局等級表是否存在
    if (!variable_global_exists("level_exp_map") || !ds_exists(global.level_exp_map, ds_type_map)) {
        show_error("錯誤：無法獲得經驗，全局等級表 global.level_exp_map 不存在！", false);
        return;
    }
    
    // 添加經驗值
    experience += exp_amount;
    show_debug_message(name + " 獲得 " + string(exp_amount) + " EXP. 當前總經驗: " + string(experience) + " (Lv." + string(level) + ")");
    
    // 顯示獲得經驗值的提示 (保持不變)
    var text_obj = asset_get_index("obj_floating_text");
    if (object_exists(text_obj)) {
        var exp_text = instance_create_layer(x, y - 20, "Instances", text_obj);
        if (instance_exists(exp_text)) {
            exp_text.text = "+" + string(exp_amount) + " EXP";
            exp_text.color = c_aqua;
            exp_text.float_speed = 0.3;
        }
    }
    
    // 使用 while 迴圈檢查並處理（連續）升級
    var can_level_up = true;
    while (can_level_up) {
        // 查找升到下一級所需的總經驗值
        var required_exp = ds_map_find_value(global.level_exp_map, level);
        
        // 檢查是否達到最高等級 (Map中找不到當前等級的條目)
        if (is_undefined(required_exp)) {
            show_debug_message(name + " 已達最高等級 (" + string(level) + ") 或等級表數據缺失。");
            can_level_up = false; // 停止檢查
            // 可選：將經驗值限制在當前等級所需的最大值？
            // var prev_level_exp = (level > 1) ? ds_map_find_value(global.level_exp_map, level - 1) : 0;
            // if (!is_undefined(prev_level_exp)) { experience = max(experience, prev_level_exp); } // 確保經驗不會超過滿級所需
            break; // 跳出 while 迴圈
        }
        
        // 檢查經驗是否足夠升級
        if (experience >= required_exp) {
            // 足夠升級，調用 level_up 函數處理升級邏輯
            level_up(); 
            // level_up 函數會增加 level，while 迴圈會自動檢查新的等級要求
        } else {
            // 經驗不足以升級
            show_debug_message(name + " (Lv." + string(level) + ") 當前經驗 " + string(experience) + " / " + string(required_exp) + "，無法升級。");
            can_level_up = false; // 停止檢查
        }
    }
}

// 覆盖初始化函数 (保持不變)
initialize = function() {
    // 调用父类的初始化
    event_inherited();
    // 添加入场动画或效果的代码可以放这里
    show_debug_message("玩家召唤物初始化完成: " + string(id));
}