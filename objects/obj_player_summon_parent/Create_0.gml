// 继承父类的创建事件
event_inherited();

// 设置队伍为玩家方
team = 0;

// 玩家召唤物特有属性
return_after_battle = true;  // 战斗后是否返回玩家的"队伍"
stamina = 100;               // 特殊耐力值，可用于延长战场时间
preferred_distance = 100;    // 与目标的理想战斗距离

experience = 0;
experience_to_level_up = 100;

// obj_player_summon_parent - level_up 函數與經驗值系統

// 級別提升函數
function level_up() {
    level++;
    experience -= experience_to_level_up;
    
    // 計算下一級所需經驗值 (隨等級增加)
    experience_to_level_up = 100 + (level * 20);
    
    // 屬性提升 (稍微增加隨機性)
    var hp_increase = 5 + irandom(10);
    var atk_increase = 1 + irandom(2);
    var def_increase = 1 + irandom(1);
    var spd_increase = random(1) < 0.7 ? 1 : 0; // 70% 機率增加速度
    
    max_hp += hp_increase;
    hp += hp_increase; // 升級時恢復增加的HP
    attack += atk_increase;
    defense += def_increase;
    spd += spd_increase;
    
    // 更新ATB充能率 (基於速度)
    atb_rate = 1 + (spd * 0.1);
    
    // 升級特效
    create_level_up_effect();
    
    // 音效
    if (audio_exists(snd_level_up)) {
        audio_play_sound(snd_level_up, 10, false);
    }
    
    // 檢查是否可以學習新技能
    check_new_skills();
    
    // 在戰鬥日誌中記錄
    if (instance_exists(obj_battle_manager)) {
        with (obj_battle_manager) {
            add_battle_log(object_get_name(other.object_index) + " 升級至 " + string(other.level) + " 級!");
        }
    }
    
    // 升級後檢查是否可以再次升級
    if (experience >= experience_to_level_up) {
        level_up(); // 遞迴調用實現連續升級
    }
}

// 建立升級特效
function create_level_up_effect() {
    // 如果沒有專門的特效物件，可以臨時創建簡單的效果
    for (var i = 0; i < 20; i++) {
        var effect_x = x + random_range(-16, 16);
        var effect_y = y + random_range(-16, 16);
        
        // 創建粒子或使用現有特效物件
        var effect_obj = asset_get_index("obj_level_effect");
        if (object_exists(effect_obj)) {
            var effect = instance_create_layer(effect_x, effect_y, "Instances", effect_obj);
            
            // 設定特效屬性
            if (instance_exists(effect)) {
                effect.speed = random_range(1, 3);
                effect.direction = random(360);
                effect.image_blend = c_yellow; // 使用黃色表示升級
            }
        } else {
            // 如果沒有特效物件，使用粒子系統
            if (variable_global_exists("particle_system") && part_system_exists(global.particle_system)) {
                if (variable_global_exists("pt_level_up") && part_type_exists(global.pt_level_up)) {
                    part_type_shape(global.pt_level_up, pt_shape_star);
                    part_type_size(global.pt_level_up, 0.3, 0.8, -0.02, 0);
                    part_type_color3(global.pt_level_up, c_yellow, c_orange, c_white);
                    part_type_alpha3(global.pt_level_up, 1, 0.8, 0);
                    part_type_speed(global.pt_level_up, 1, 3, -0.1, 0);
                    part_type_direction(global.pt_level_up, 0, 360, 0, 15);
                    part_type_life(global.pt_level_up, 20, 40);
                    
                    part_particles_create(global.particle_system, effect_x, effect_y, global.pt_level_up, 1);
                }
            }
        }
    }
    
    // 顯示升級文字
    var text_obj = asset_get_index("obj_floating_text");
    if (object_exists(text_obj)) {
        var level_text = instance_create_layer(x, y - 30, "Instances", text_obj);
        if (instance_exists(level_text)) {
            level_text.text = "Level Up!";
            level_text.color = c_yellow;
            level_text.scale = 1.5;
            level_text.float_speed = 0.5;
        }
    }
}

// 檢查新技能
function check_new_skills() {
    // 根據等級和怪物類型判斷是否應該學習新技能
    var type_name = object_get_name(object_index);
    var learned_new_skill = false;
    
    // 這裡可以寫具體不同類型怪物在不同等級的技能學習邏輯
    switch (type_name) {
        case "obj_test_summon":
            if (level == 3 && !has_skill("water_shield")) {
                var water_shield = {
                    id: "water_shield",
                    name: "水之護盾",
                    effect: "defense",
                    power: 5,
                    range: 0,
                    cooldown: 120
                };
                
                ds_list_add(skills, water_shield);
                ds_map_add(skill_cooldowns, "water_shield", 0);
                learned_new_skill = true;
            }
            else if (level == 5 && !has_skill("tidal_wave")) {
                var tidal_wave = {
                    id: "tidal_wave",
                    name: "潮汐波",
                    effect: "damage_aoe",
                    damage: attack * 1.5,
                    range: 100,
                    cooldown: 180
                };
                
                ds_list_add(skills, tidal_wave);
                ds_map_add(skill_cooldowns, "tidal_wave", 0);
                learned_new_skill = true;
            }
            break;
            
        // 可以添加更多怪物類型的技能判斷
        case "obj_fire_summon":
            if (level == 3 && !has_skill("fire_blast")) {
                var fire_blast = {
                    id: "fire_blast",
                    name: "火焰衝擊",
                    effect: "damage_single",
                    damage: attack * 2.0,
                    range: 120,
                    cooldown: 90
                };
                
                ds_list_add(skills, fire_blast);
                ds_map_add(skill_cooldowns, "fire_blast", 0);
                learned_new_skill = true;
            }
            break;
            
        case "obj_earth_summon":
            if (level == 4 && !has_skill("rock_armor")) {
                var rock_armor = {
                    id: "rock_armor",
                    name: "岩石護甲",
                    effect: "buff_defense",
                    power: 10,
                    duration: 180,
                    cooldown: 240
                };
                
                ds_list_add(skills, rock_armor);
                ds_map_add(skill_cooldowns, "rock_armor", 0);
                learned_new_skill = true;
            }
            break;
    }
    
    if (learned_new_skill) {
        // 顯示學習新技能的提示
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info(object_get_name(object_index) + " 學習了新技能!");
        }
    }
}

// 檢查是否擁有特定技能
function has_skill(skill_id) {
    for (var i = 0; i < ds_list_size(skills); i++) {
        var skill = skills[| i];
        if (skill.id == skill_id) {
            return true;
        }
    }
    return false;
}

// 獲得經驗值
function gain_exp(exp_amount) {
    if (!variable_instance_exists(id, "experience")) {
        experience = 0;
    }
    
    if (!variable_instance_exists(id, "experience_to_level_up")) {
        experience_to_level_up = 100 + (level * 20);
    }
    
    // 添加經驗值
    experience += exp_amount;
    
    // 顯示獲得經驗值的提示
    var text_obj = asset_get_index("obj_floating_text");
    if (object_exists(text_obj)) {
        var exp_text = instance_create_layer(x, y - 20, "Instances", text_obj);
        if (instance_exists(exp_text)) {
            exp_text.text = "+" + string(exp_amount) + " EXP";
            exp_text.color = c_aqua;
            exp_text.float_speed = 0.3;
        }
    }
    
    // 檢查是否升級
    if (experience >= experience_to_level_up) {
        level_up();
    }
}



// 覆盖初始化函数
initialize = function() {
    // 调用父类的初始化
    event_inherited();
    
    // 添加基础技能
    var basic_attack = {
        id: "basic_attack",
        name: "基础攻击",
        damage: attack,
        range: 50,
        cooldown: 30
    };
    
    ds_list_add(skills, basic_attack);
    ds_map_add(skill_cooldowns, "basic_attack", 0);
    
    // 添加入场动画或效果的代码可以放这里
    
    show_debug_message("玩家召唤物初始化完成: " + string(id));
}

// 重新调用初始化
initialize();