// obj_monster_manager_ui - Create_0.gml
event_inherited();

// 技能緩存系統
// skill_cache = ds_map_create(); // 不再需要緩存
skill_cache = undefined; // 確保變數存在以供 CleanUp 檢查

// 基本設置
visible = false; // 初始不可見
active = false;  // 初始非活動狀態
allow_player_movement = true; // 初始允許玩家移動
// 明確設置字體 - 與obj_dialogue_box相同
draw_set_font(fnt_dialogue);

// 標準UI方法
show = function() {
    active = true;
    visible = true;
    depth = -100; // 會被ui_manager覆蓋
    open_animation = 0; // 重置動畫
    surface_needs_update = true;
    details_needs_update = true;
    allow_player_movement = false; // 顯示UI時禁止玩家移動
    
    // 刷新怪物列表
    refresh_monster_list();
    apply_filters();
    
    // 預選第一個怪物
    selected_monster = (ds_list_size(filtered_list) > 0) ? 0 : -1;
    
    show_debug_message("怪物管理UI已顯示，禁止玩家移動");
};

hide = function() {
    active = false;
    visible = false;
    allow_player_movement = true; // 隱藏UI時允許玩家移動
    
    // 釋放表面資源
    if (surface_exists(ui_surface)) {
        surface_free(ui_surface);
        ui_surface = -1;
    }
    
    if (surface_exists(ui_details_surface)) {
        surface_free(ui_details_surface);
        ui_details_surface = -1;
    }
    
    show_debug_message("怪物管理UI已隱藏，允許玩家移動");
};

// 初始化 UI 信息透明度變數
info_alpha = 1.0; // 這個值可以根據 UI 需求調整
// 添加缺少的變量初始化
info_text = ""; // 初始化信息文本
info_timer = 0; // 初始化信息計時器

// UI尺寸和位置
ui_width = display_get_gui_width() * 0.9;
ui_height = display_get_gui_height() * 0.9;
ui_x = (display_get_gui_width() - ui_width) / 2;
ui_y = (display_get_gui_height() - ui_height) / 2;

// 創建UI表面
ui_surface = -1;
ui_details_surface = -1;
surface_needs_update = true;
details_needs_update = true;

// 分頁系統
enum MONSTER_TABS {
    ALL,      // 所有怪物
    TEAM,     // 戰鬥隊伍
    STATS,    // 數據分析
    INFO      // 圖鑑信息
}

current_tab = MONSTER_TABS.ALL;

// 怪物列表和選擇
monster_list = ds_list_create();
filtered_list = ds_list_create();
selected_monster = -1;
scroll_offset = 0;
max_visible_monsters = 6; // 一頁顯示的怪物數量

// 排序設置
sort_by = "level"; // 預設按等級排序
sort_ascending = false; // 預設降序

// 搜索過濾
search_text = "";
search_active = false;

// 按鈕區域
close_btn_x = ui_x + ui_width - 40;
close_btn_y = ui_y + 10;
close_btn_size = 30;

// 分頁按鈕
tab_width = ui_width / 4;
tab_height = 40;

// 怪物詳情區域
details_x = ui_x + ui_width * 0.6;
details_y = ui_y + 60;
details_width = ui_width * 0.38;
details_height = ui_height - 70;

// 過渡動畫參數
open_animation = 0;
open_speed = 0.08;

/// 刷新怪物列表
refresh_monster_list = function() {
    ds_list_clear(monster_list);
    show_debug_message("刷新怪物列表開始..."); // 添加日誌
    
    // 從全局玩家怪物列表加載
    if (variable_global_exists("player_monsters")) {
        var num_monsters = array_length(global.player_monsters);
        show_debug_message("  找到 " + string(num_monsters) + " 個玩家怪物。");
        
        for (var i = 0; i < num_monsters; i++) {
            var monster = global.player_monsters[i];
            ds_list_add(monster_list, monster);
            show_debug_message("    已添加怪物: " + (variable_struct_exists(monster, "name") ? monster.name : "未知名稱"));
            
            // --- 預加載並存儲顯示用的技能數據 ---
            // 確保 monster 是一個結構體
            if (is_struct(monster)) {
                // 調用 get_monster_skills 獲取包含完整結構體的技能陣列
                var display_skills_array = get_monster_skills(monster);
                // 將獲取的陣列存儲到 monster 結構體的新欄位中
                monster.display_skills = display_skills_array;
                show_debug_message("      預加載技能完成，共 " + string(array_length(display_skills_array)) + " 個技能。");
            } else {
                 show_debug_message("      警告：無法預加載技能，monster 不是結構體！");
                 // 可以考慮為非結構體設置一個空的 display_skills
                 // monster.display_skills = []; // 取決於後續代碼是否需要此欄位一定存在
            }
            // --- 預加載結束 ---
        }
    } else {
        show_debug_message("  全局玩家怪物列表 player_monsters 不存在。");
    }
    show_debug_message("刷新怪物列表結束。");
}

/// 應用過濾器和排序
apply_filters = function() {
    ds_list_clear(filtered_list);
    
    // 根據當前標籤篩選
    for (var i = 0; i < ds_list_size(monster_list); i++) {
        var monster = monster_list[| i];
        var include = true;
        
        // 根據標籤過濾
        switch(current_tab) {
            case MONSTER_TABS.ALL:
                // 所有怪物都包括
                break;
                
            case MONSTER_TABS.TEAM:
                // 只包括戰鬥隊伍中的怪物
                include = false;
                // 這裡可以添加隊伍檢查邏輯
                // 例如，檢查monster.in_team變量
                break;
        }
        
        // 根據搜索文本過濾
        if (include && search_text != "") {
            include = false;
            
            // 檢查名稱匹配
            if (string_pos(string_lower(search_text), string_lower(monster.name)) > 0) {
                include = true;
            }
            
            // 這裡可以添加更多搜索條件
        }
        
        if (include) {
            ds_list_add(filtered_list, monster);
        }
    }
    
    // 應用排序
    sort_monster_list();
}

/// 排序怪物列表
sort_monster_list = function() {
    // 使用冒泡排序（簡單實現）
    var n = ds_list_size(filtered_list);
    
    for (var i = 0; i < n - 1; i++) {
        for (var j = 0; j < n - i - 1; j++) {
            var monster1 = filtered_list[| j];
            var monster2 = filtered_list[| j + 1];
            var swap = false;
            
            // 根據排序條件比較
            switch(sort_by) {
                case "level":
                    if (sort_ascending) {
                        swap = (monster1.level > monster2.level);
                    } else {
                        swap = (monster1.level < monster2.level);
                    }
                    break;
                    
                case "name":
                    if (sort_ascending) {
                        swap = (monster1.name > monster2.name);
                    } else {
                        swap = (monster1.name < monster2.name);
                    }
                    break;
                    
                case "hp":
                    if (sort_ascending) {
                        swap = (monster1.hp > monster2.hp);
                    } else {
                        swap = (monster1.hp < monster2.hp);
                    }
                    break;
                    
                case "attack":
                    if (sort_ascending) {
                        swap = (monster1.attack > monster2.attack);
                    } else {
                        swap = (monster1.attack < monster2.attack);
                    }
                    break;
            }
            
            // 交換位置
            if (swap) {
                var temp = filtered_list[| j];
                filtered_list[| j] = filtered_list[| j + 1];
                filtered_list[| j + 1] = temp;
            }
        }
    }
}

/// 切換排序方式
change_sort = function(new_sort) {
    if (sort_by == new_sort) {
        // 相同排序條件，切換升序/降序
        sort_ascending = !sort_ascending;
    } else {
        // 新的排序條件，設為降序
        sort_by = new_sort;
        sort_ascending = false;
    }
    
    sort_monster_list();
}

/// 切換標籤
switch_tab = function(new_tab) {
    if (current_tab != new_tab) {
        current_tab = new_tab;
        scroll_offset = 0;
        selected_monster = -1;
        apply_filters();
        
        if (ds_list_size(filtered_list) > 0) {
            selected_monster = 0;
        }
        
        surface_needs_update = true;
        details_needs_update = true;
    }
}

/// 獲取怪物的技能列表 (修正版 - 處理 Array)
get_monster_skills = function(monster_data) {
    // 檢查 monster_data 是否有效，以及 skills 欄位是否存在且為陣列
    if (is_struct(monster_data) && variable_struct_exists(monster_data, "skills") && is_array(monster_data.skills)) {

        // 直接從 monster_data 複製技能陣列 (創建副本以防外部修改)
        var skills_array_copy = [];
        var original_array = monster_data.skills;
        for (var i = 0; i < array_length(original_array); i++) {
             var skill_data = original_array[i];
             if (is_struct(skill_data)) {
                // 深拷貝結構體 (防止修改副本影響原數據)
                var skill_copy = {};
                var names = variable_struct_get_names(skill_data);
                for(var n=0; n<array_length(names); n++){
                    skill_copy[$ names[n]] = skill_data[$ names[n]];
                }
                array_push(skills_array_copy, skill_copy);
             } else {
                 // 如果陣列中存的不是結構體 (例如只有 ID)，這裡需要處理
                 // 嘗試用 ID 去 Skill Manager 查詢完整數據 (需要 obj_skill_manager 存在)
                 var skill_id_str = string(skill_data); // 確保是字符串 ID
                 if (instance_exists(obj_skill_manager)) {
                     // var context_unit_id = ... // 不再需要計算 context_unit_id
                     // 直接傳遞 monster_data 結構體
                     var full_skill_data = obj_skill_manager.copy_skill(skill_id_str, monster_data); 
                     if (full_skill_data != undefined) {
                         array_push(skills_array_copy, full_skill_data);
                     } else {
                         show_debug_message("警告：在 get_monster_skills 中找不到技能 ID: " + skill_id_str);
                     }
                 } else {
                      show_debug_message("警告：在 get_monster_skills 中 Skill Manager 不存在");
                 }
             }
        }
        return skills_array_copy;

    } else {
        // 如果 monster_data 無效或沒有技能陣列，返回空陣列
        // 避免在 monster_data 無效時嘗試讀取 name
        if (!is_struct(monster_data)) {
             show_debug_message("警告：無法獲取技能，傳入的 monster_data 不是有效的結構體。");
        } else if (!variable_struct_exists(monster_data, "skills")) {
            show_debug_message("警告：無法獲取技能，monster_data 中缺少 'skills' 欄位。Name: " + (variable_struct_exists(monster_data, "name") ? monster_data.name : "未知"));
        } else if (!is_array(monster_data.skills)){
            show_debug_message("警告：無法獲取技能，monster_data.skills 不是陣列。Name: " + (variable_struct_exists(monster_data, "name") ? monster_data.name : "未知"));
        }
        return [];
    }
}

/// 繪製怪物卡片
/// @param {real} x 卡片x座標
/// @param {real} y 卡片y座標
/// @param {struct} monster_data 怪物數據
/// @param {bool} is_selected 是否被選中
draw_monster_card = function(x, y, monster_data, is_selected) {
    var card_width = ui_width * 0.55;
    var card_height = 100;
    
    // 計算卡片顏色（基於怪物屬性）
    var card_color1, card_color2;
    
    // 根據怪物類型設置不同顏色
    if (monster_data.hp < monster_data.attack * 4) {
        // 攻擊型 - 紅色調
        card_color1 = make_color_rgb(120, 20, 20);
        card_color2 = make_color_rgb(180, 40, 40);
    } else if (monster_data.defense > monster_data.attack) {
        // 防禦型 - 藍色調
        card_color1 = make_color_rgb(20, 40, 120);
        card_color2 = make_color_rgb(40, 60, 180);
    } else {
        // 平衡型 - 綠色調
        card_color1 = make_color_rgb(20, 100, 20);
        card_color2 = make_color_rgb(40, 150, 40);
    }
    
    // 如果被選中，增加明亮度
    if (is_selected) {
        card_color1 = merge_color(card_color1, c_white, 0.3);
        card_color2 = merge_color(card_color2, c_white, 0.3);
        
        // 繪製選中指示器
        draw_set_color(c_yellow);
        draw_set_alpha(0.5 + sin(current_time/200) * 0.3); // 呼吸效果
        draw_rectangle(x - 5, y - 5, x + card_width + 5, y + card_height + 5, false);
        draw_set_alpha(1.0);
    }
    
    // 繪製卡片背景
    draw_rectangle_color(
        x, y, 
        x + card_width, y + card_height,
        card_color1, card_color1, card_color2, card_color2,
        false
    );
    
    // 繪製卡片邊框
    draw_set_color(is_selected ? c_yellow : c_white);
    draw_rectangle(x, y, x + card_width, y + card_height, true);
    
    // 怪物縮略圖區域
    draw_rectangle(x + 10, y + 10, x + 90, y + 90, true);
    
    // 繪製怪物縮略圖
    draw_set_color(c_dkgray);
    draw_rectangle(x + 11, y + 11, x + 89, y + 89, false);
    
    // --- 修改：嘗試從 monster_data.display_sprite 獲取精靈 ---
    var monster_sprite = -1;
    if (variable_struct_exists(monster_data, "display_sprite")) {
        monster_sprite = monster_data.display_sprite;
    }
    // --- 修改結束 ---
    
    if (monster_sprite != -1 && sprite_exists(monster_sprite)) { // <-- 添加 sprite_exists 檢查
        draw_sprite_stretched(monster_sprite, 0, x + 11, y + 11, 78, 78);
    } else {
        // 如未找到精靈，繪製一個占位符
        draw_set_color(c_gray);
        draw_rectangle(x + 30, y + 30, x + 70, y + 70, false);
        draw_set_color(c_white);
        draw_text(x + 45, y + 45, "?");
    }
    
    // 怪物名稱與等級
    draw_set_color(c_white);
    draw_text(x + 100, y + 15, monster_data.name + " (Lv. " + string(monster_data.level) + ")");
    
    // HP條
    var hp_x = x + 100;
    var hp_y = y + 40;
    var hp_width = card_width - 120;
    var hp_height = 12;
    var hp_percent = monster_data.hp / monster_data.max_hp;
    
    draw_set_color(c_dkgray);
    draw_rectangle(hp_x, hp_y, hp_x + hp_width, hp_y + hp_height, false);
    
    // HP條顏色根據HP百分比變化
    var hp_color = make_color_rgb(
        255 * (1 - hp_percent),
        255 * hp_percent,
        0
    );
    
    draw_set_color(hp_color);
    draw_rectangle(hp_x, hp_y, hp_x + hp_width * hp_percent, hp_y + hp_height, false);
    
    // HP文字
    draw_set_color(c_white);
    draw_text(hp_x, hp_y + hp_height + 5, "HP: " + string(monster_data.hp) + "/" + string(monster_data.max_hp));
    
    // 怪物主要屬性
    draw_text(x + 100, hp_y + hp_height + 25, "攻: " + string(monster_data.attack) + " 防: " + string(monster_data.defense) + " 速: " + string(monster_data.spd));
    
    // 繪製技能列表
    var skills = variable_struct_exists(monster_data, "display_skills") && is_array(monster_data.display_skills) 
               ? monster_data.display_skills 
               : []; // 如果 display_skills 不存在或不是數組，則使用空數組

    var skill_y = y + 80; // 保留原始 Y 座標
    var max_skills_on_card = 1; // 卡片上最多顯示 1 個技能

    if (array_length(skills) > 0) {
        for (var i = 0; i < min(array_length(skills), max_skills_on_card); i++) {
            var skill = skills[i];
            // 檢查技能數據是否有效
            if (is_struct(skill) && variable_struct_exists(skill, "name")) {
                draw_text(x + 10, skill_y, skill.name); // 保留原始 x+10 座標
            } else {
                draw_text(x + 10, skill_y, "<錯誤技能數據>"); // 保留原始 x+10 座標
            }
            skill_y += 20; // 保留原始 Y 遞增
        }
        // 如果技能數量超過限制，顯示省略號
        if (array_length(skills) > max_skills_on_card) {
             draw_text(x + 10, skill_y, "..."); // 保留原始 x+10 座標
        }
    }
    // else { // 原代碼沒有處理無技能情況，保持不變 }
    
    // 恢復繪圖顏色
    draw_set_color(c_white);
}

/// 繪製怪物詳細信息
/// @param {struct} monster_data 怪物數據
draw_monster_details = function(monster_data) {
    // 確保尺寸有效
    details_width = max(1, details_width);
    details_height = max(1, details_height);
    
    // 創建或更新詳細信息表面
    if (!surface_exists(ui_details_surface) || details_needs_update) {
        if (surface_exists(ui_details_surface)) {
            surface_free(ui_details_surface);
        }
        
        ui_details_surface = surface_create(details_width, details_height);
        surface_set_target(ui_details_surface);
        draw_clear_alpha(c_black, 0);
        
        // 繪製詳細信息背景
        draw_set_alpha(0.8);
        draw_rectangle_color(0, 0, details_width, details_height, 
                         c_navy, c_navy, c_black, c_black, false);
        draw_set_alpha(1.0);
        
        // 繪製邊框
        draw_set_color(c_aqua);
        draw_rectangle(0, 0, details_width, details_height, true);
        
        // 標題
        draw_set_color(c_white);
        draw_set_halign(fa_center);
        draw_text(details_width / 2, 15, monster_data.name + " 詳細信息");
        draw_line(10, 35, details_width - 10, 35);
        draw_set_halign(fa_left);
        
        // 怪物圖示
        var sprite_x = details_width / 2;
        var sprite_y = 80;
        
        // --- 修改：嘗試從 monster_data.display_sprite 獲取精靈 ---
        var monster_sprite = -1;
        if (variable_struct_exists(monster_data, "display_sprite")) {
            monster_sprite = monster_data.display_sprite;
        }
        // --- 修改結束 ---
        
        if (monster_sprite != -1 && sprite_exists(monster_sprite)) { // <-- 添加 sprite_exists 檢查
            var sprite_scale = min(128 / sprite_get_width(monster_sprite), 128 / sprite_get_height(monster_sprite));
            draw_sprite_ext(monster_sprite, 0, sprite_x, sprite_y, sprite_scale, sprite_scale, 0, c_white, 1);
        } else {
            // 如未找到精靈，繪製一個占位符
            draw_set_color(c_gray);
            draw_rectangle(sprite_x - 50, sprite_y - 50, sprite_x + 50, sprite_y + 50, false);
            draw_set_color(c_white);
            draw_text(sprite_x, sprite_y, "?");
        }
        
        // 基本數據
        var data_y = 150;
        draw_set_color(c_yellow);
        draw_text(20, data_y, "基本數據:");
        draw_set_color(c_white);
        
        data_y += 25;
        draw_text(20, data_y, "等級: " + string(monster_data.level));
        
        data_y += 20;
        draw_text(20, data_y, "HP: " + string(monster_data.hp) + "/" + string(monster_data.max_hp));
        
        data_y += 20;
        draw_text(20, data_y, "攻擊力: " + string(monster_data.attack));
        
        data_y += 20;
        draw_text(20, data_y, "防禦力: " + string(monster_data.defense));
        
        data_y += 20;
        draw_text(20, data_y, "速度: " + string(monster_data.spd));
        
        // 技能列表
        data_y += 40;
        draw_set_color(c_yellow);
        draw_text(20, data_y, "技能:");
        draw_set_color(c_white);
        
        // var skills = get_monster_skills(monster_data); // <-- 不再需要調用
        var skills = variable_struct_exists(monster_data, "display_skills") && is_array(monster_data.display_skills) 
                   ? monster_data.display_skills 
                   : []; // 如果 display_skills 不存在或不是數組，則使用空數組

        if (array_length(skills) > 0) {
            for (var i = 0; i < array_length(skills); i++) {
                data_y += 20; // 保留原始 Y 遞增
                var skill = skills[i]; // 獲取技能數據
                // 檢查技能數據是否有效
                if (is_struct(skill) && variable_struct_exists(skill, "name")) {
                    draw_text(40, data_y, "- " + skill.name); // 保留原始 X 座標 40
                } else {
                    draw_text(40, data_y, "- <錯誤技能數據>"); // 保留原始 X 座標 40
                }
            }
        } else {
            data_y += 20; // 保留原始 Y 遞增
            draw_text(40, data_y, "沒有特殊技能"); // 保留原始 X 座標 40 和文本
        }
        
        // 操作按鈕
        var button_y = details_height - 80;
        
        // 使用按鈕
        draw_set_color(c_green);
        draw_rectangle(details_width / 2 - 110, button_y, details_width / 2 - 10, button_y + 30, false);
        draw_set_color(c_white);
        draw_set_halign(fa_center);
        draw_text(details_width / 2 - 60, button_y + 15, "設為主力");
        
        // 治療按鈕
        draw_set_color(c_lime);
        draw_rectangle(details_width / 2 + 10, button_y, details_width / 2 + 110, button_y + 30, false);
        draw_set_color(c_white);
        draw_text(details_width / 2 + 60, button_y + 15, "治療");
        
        draw_set_halign(fa_left);
        
        surface_reset_target();
        details_needs_update = false;
    }
    
    // 繪製詳細信息表面
    draw_surface(ui_details_surface, details_x, details_y);
}