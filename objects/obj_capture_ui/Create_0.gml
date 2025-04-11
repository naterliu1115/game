// obj_capture_ui - Create_0.gml
event_inherited();

// 初始化 UI 基本變數
ui_width = display_get_gui_width() * 0.7;
ui_height = display_get_gui_height() * 0.5;
ui_x = (display_get_gui_width() - ui_width) / 2;
ui_y = (display_get_gui_height() - ui_height) / 2;
ui_surface = -1; // 設為無效的表面 ID
surface_needs_update = true;

// 初始化捕獲相關變數
target_enemy = noone;
capture_state = "ready"; // 使用字串而非數字，方便識別
capture_animation = 0;
capture_result = false;
capture_chance = 0;

// 捕獲狀態變數
active = false;
visible = false;

// 動畫相關
open_animation = 0;
open_speed = 0.1;

// 捕獲方法 - 使用陣列
capture_methods = []; 
selected_method = 0;

// 按鈕位置和尺寸
capture_btn_width = 120;
capture_btn_height = 40;
capture_btn_x = 0; // 會在show()中更新
capture_btn_y = 0; // 會在show()中更新

cancel_btn_width = 120;
cancel_btn_height = 40;
cancel_btn_x = 0; // 會在show()中更新
cancel_btn_y = 0; // 會在show()中更新

// 定義開啟捕獲 UI 的函數
open_capture_ui = function(target) {
    if (!instance_exists(target)) {
        show_debug_message("錯誤: 嘗試捕獲不存在的目標");
        return;
    }
    
    show_debug_message("===== 開啟捕獲UI =====");
    show_debug_message("目標：" + object_get_name(target.object_index));
    
    // 檢查戰鬥狀態，確保UI不能在PREPARING開啟
    if (instance_exists(obj_battle_manager) && obj_battle_manager.battle_state == BATTLE_STATE.PREPARING) {
        show_debug_message("無法在戰鬥準備階段開啟捕獲 UI");
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("無法在戰鬥準備階段捕獲敵人！");
        }
        return;
    }

    // 確保UI只在ACTIVE時開啟
    if (instance_exists(obj_battle_manager) && obj_battle_manager.battle_state != BATTLE_STATE.ACTIVE) {
        show_debug_message("無法在當前戰鬥狀態開啟捕獲 UI");
        return;
    }
    
    // 設置目標和初始狀態
    target_enemy = target;
    capture_state = "ready";
    open_animation = 0;
    capture_animation = 0;
    surface_needs_update = true;

    // 重新初始化捕獲方法
    capture_methods = []; // 清空陣列

    // 添加捕獲方法 (這裡可以根據玩家持有的球和敵人類型動態添加)
    var method1 = {
        name: "普通捕獲",
        description: "用普通球捕獲怪物",
        cost: { item: "普通球", amount: 1 },
        bonus: 0
    };

    var method2 = {
        name: "高級捕獲",
        description: "用高級球捕獲怪物",
        cost: { item: "高級球", amount: 1 },
        bonus: 0.2
    };

    // 使用array_push添加到陣列
    array_push(capture_methods, method1, method2);

    // 初始選擇第一個方法
    selected_method = 0;

    // 計算初始捕獲率
    calculate_capture_chance();
    
    // 通過UI管理器顯示
    if (instance_exists(obj_ui_manager)) {
        show_debug_message("使用UI管理器顯示捕獲UI");
        with (obj_ui_manager) {
            show_ui(other.id, "overlay");
        }
    } else {
        // 備用方法，直接顯示
        show_debug_message("UI管理器不存在，使用直接顯示方法");
        show();
    }
    
    show_debug_message("===== 捕獲UI開啟完成 =====");
};

// 計算捕獲成功率
calculate_capture_chance = function() {
    if (!instance_exists(target_enemy)) {
        capture_chance = 0;
        return;
    }
    
    // 基礎捕獲率計算
    var hp_percent = target_enemy.hp / target_enemy.max_hp;
    var base_chance = 0.8; // 80% 基礎捕獲率
    var chance_modifier = 1 - hp_percent; // HP越低，成功率越高
    
    // 計算最終捕獲率
    capture_chance = base_chance + (chance_modifier * 0.3); // 最高額外 +30%
    
    // 如果有選擇捕獲方法，加入其加成
    if (selected_method >= 0 && selected_method < array_length(capture_methods)) {
        capture_chance += capture_methods[selected_method].bonus;
    }
    
    // 限制在合理範圍內
    capture_chance = clamp(capture_chance, 0.1, 0.95);
};

// 嘗試捕獲
attempt_capture = function() {
    if (target_enemy != noone && instance_exists(target_enemy)) {
        // 扣除物品 (實際遊戲中需要實作)
        var can_capture = true;
        
        if (!can_capture) {
            // 顯示缺少物品的提示 (實際遊戲中需要實作)
            return;
        }
        
        // 切換到捕獲中狀態
        capture_state = "capturing";
        capture_animation = 0;
        
        // 決定捕獲是否成功
        capture_result = (random(1) <= capture_chance);
        
        // Debug 輸出
        show_debug_message("嘗試捕獲: 機率 = " + string(capture_chance) + ", 結果 = " + (capture_result ? "成功" : "失敗"));
    }
};

// 完成捕獲過程
finalize_capture = function() {
    if (capture_result) {
        // 捕獲成功的處理邏輯
        if (target_enemy != noone && instance_exists(target_enemy)) {
            show_debug_message("成功捕獲: " + object_get_name(target_enemy.object_index));

            // --- Start: Revised logic to create captured monster data ---

            // 1. Get essential info from the captured instance
            var _template_id = target_enemy.template_id;
            var _level = target_enemy.level;
            var _name = target_enemy.name; // Use the instance's name
            var _type = target_enemy.object_index;

            // 2. Fetch the template from the factory
            var _template = undefined;
            if (instance_exists(obj_enemy_factory)) {
                _template = obj_enemy_factory.get_enemy_template(_template_id);
            }

            if (_template == undefined) {
                show_debug_message("錯誤：無法從工廠獲取模板 ID: " + string(_template_id) + "。無法保存捕獲的怪物。");
                // Optionally, still destroy the enemy or handle error differently
                 with (target_enemy) { instance_destroy(); }
                 hide();
                 return; // Stop processing capture
            }

            // 3. Calculate stats based on template and captured level
            // Ensure template fields exist before accessing
            var _hp_base = variable_struct_exists(_template, "hp_base") ? _template.hp_base : 1;
            var _hp_growth = variable_struct_exists(_template, "hp_growth") ? _template.hp_growth : 0;
            var _attack_base = variable_struct_exists(_template, "attack_base") ? _template.attack_base : 1;
            var _attack_growth = variable_struct_exists(_template, "attack_growth") ? _template.attack_growth : 0;
            var _defense_base = variable_struct_exists(_template, "defense_base") ? _template.defense_base : 1;
            var _defense_growth = variable_struct_exists(_template, "defense_growth") ? _template.defense_growth : 0;
            var _speed_base = variable_struct_exists(_template, "speed_base") ? _template.speed_base : 1;
            var _speed_growth = variable_struct_exists(_template, "speed_growth") ? _template.speed_growth : 0;

            var _max_hp = ceil(_hp_base + (_hp_base * _hp_growth * (_level - 1)));
            var _attack = ceil(_attack_base + (_attack_base * _attack_growth * (_level - 1)));
            var _defense = ceil(_defense_base + (_defense_base * _defense_growth * (_level - 1)));
            var _spd = ceil(_speed_base + (_speed_base * _speed_growth * (_level - 1)));
            
            // Ensure minimum stats
            _max_hp = max(1, _max_hp);
            _attack = max(1, _attack);
            _defense = max(1, _defense);
            _spd = max(1, _spd);

            // --- 添加：獲取模板的基礎 Sprite --- 
            var _sprite_idle = variable_struct_exists(_template, "sprite_idle") ? _template.sprite_idle : -1;
            show_debug_message(">>> finalize_capture: Template sprite_idle = " + string(_sprite_idle)); // DEBUG ADDED
            // --- 添加結束 ---

            // 4 & 5. Create the standardized data structure
            var captured_monster_data = {
                id: _template_id,
                level: _level,
                name: _name,
                type: _type,
                display_sprite: _sprite_idle,
                max_hp: _max_hp,
                hp: _max_hp, // Set current HP to max HP after capture
                attack: _attack,
                defense: _defense,
                spd: _spd
                // No need to store skills array here
            };

            // 6. Ensure global array exists and add the monster
            if (!variable_global_exists("player_monsters")) {
                global.player_monsters = [];
            }
            array_push(global.player_monsters, captured_monster_data);
            show_debug_message("已將 [" + captured_monster_data.name + " Lv." + string(_level) + "] (ID: " + string(_template_id) + ") 添加到玩家列表");
            show_debug_message(">>> Added to global_player_monsters: " + json_stringify(captured_monster_data)); // DEBUG ADDED - Print full structure

            // --- End: Revised logic ---

            // Destroy the captured enemy instance
            with (target_enemy) {
                instance_destroy();
            }

            // Notify Battle UI
            if (instance_exists(obj_battle_ui)) {
                obj_battle_ui.show_info("成功捕獲怪物！");
            }
        }
    } else {
        // Capture failed
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("捕獲失敗！");
        }
    }

    // Close the UI
    hide();
};

// 定義標準UI方法
show = function() {
    show_debug_message("===== 顯示捕獲UI =====");
    
    active = true;
    visible = true;
    depth = -150; // 確保UI在overlay層級
    
    // 重新計算UI尺寸（確保每次都使用最新的屏幕尺寸）
    ui_width = display_get_gui_width() * 0.7;
    ui_height = display_get_gui_height() * 0.5;
    
    // 確保UI不會太小
    ui_width = max(300, ui_width);
    ui_height = max(200, ui_height);
    
    // 中心對齊
    ui_x = (display_get_gui_width() - ui_width) / 2;
    ui_y = (display_get_gui_height() - ui_height) / 2;
    
    // 標記需要更新
    surface_needs_update = true;
    
    // 重新計算按鈕位置
    capture_btn_x = ui_x + ui_width / 4 - capture_btn_width / 2;
    capture_btn_y = ui_y + ui_height - 60;
    cancel_btn_x = ui_x + ui_width * 3/4 - cancel_btn_width / 2;
    cancel_btn_y = ui_y + ui_height - 60;
    
    show_debug_message("捕獲UI已打開，尺寸: " + string(ui_width) + "x" + string(ui_height) + " 位置: " + string(ui_x) + "," + string(ui_y));
};

hide = function() {
    show_debug_message("===== 隱藏捕獲UI =====");
    
    active = false; 
    visible = false;
    
    // 釋放表面資源
    if (surface_exists(ui_surface)) {
        surface_free(ui_surface);
        ui_surface = -1;
    }
    
    // 保留target_enemy參考，但將狀態重置
    // 這樣再次開啟時可以繼續顯示相同的敵人
    capture_state = "ready";
    capture_animation = 0;
    
    show_debug_message("捕獲UI已關閉，資源已釋放");
};

show_debug_message("捕獲UI創建完成");