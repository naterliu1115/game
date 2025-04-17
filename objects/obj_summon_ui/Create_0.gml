// obj_summon_ui - Create_0.gml
event_inherited();
// 召喚UI基本設置
visible = false; // 初始不可見
active = false;  // 初始非活動狀態

show = function() {
    // 確保單位管理器存在
    if (!instance_exists(obj_unit_manager)) {
        if (instance_exists(obj_battle_manager)) {
            obj_battle_manager.ensure_managers_exist();
        } else {
            instance_create_layer(0, 0, "Controllers", obj_unit_manager);
        }
    }
    
    active = true;
    visible = true;
    depth = -100; // 設置默認深度
    open_animation = 0;
    surface_needs_update = true;
    process_internal_input_flag = true;
    
    // 從玩家怪物列表加載數據
    refresh_monster_list();
    
    // 預選第一個怪物
    if (ds_list_size(monster_list) > 0) {
        selected_monster = 0;
    } else {
        selected_monster = -1;
    }
    
    show_debug_message("召喚UI已打開");
};

// 添加缺少的變量初始化
info_alpha = 1.0; // 初始化信息透明度
info_text = "";  // 初始化信息文本
info_timer = 0;  // 初始化信息計時器
from_preparing_phase = false; // 標記是否從準備階段打開的

// UI尺寸和位置
ui_width = display_get_gui_width() * 0.8;
ui_height = display_get_gui_height() * 0.7;
ui_x = (display_get_gui_width() - ui_width) / 2;
ui_y = (display_get_gui_height() - ui_height) / 2;

// 創建UI表面
ui_surface = -1;
surface_needs_update = true;

// 怪物列表和選擇
monster_list = ds_list_create();
selected_monster = -1;
scroll_offset = 0;
max_visible_monsters = 4;

// 按鈕區域
summon_btn_x = ui_x + ui_width * 0.7;
summon_btn_y = ui_y + ui_height - 60;
summon_btn_width = 120;
summon_btn_height = 40;

cancel_btn_x = ui_x + ui_width * 0.3 - 60;
cancel_btn_y = ui_y + ui_height - 60;
cancel_btn_width = 120;
cancel_btn_height = 40;

// 過渡動畫參數
open_animation = 0;
open_speed = 0.1;

/// 刷新怪物列表
refresh_monster_list = function() {
    ds_list_clear(monster_list);
    
    // 從全局玩家怪物列表加載
    if (variable_global_exists("player_monsters")) {
        for (var i = 0; i < array_length(global.player_monsters); i++) {
            var monster = global.player_monsters[i];
            // 只添加可用的怪物（HP > 0）
            var _hp = variable_struct_exists(monster, "hp") ? monster.hp : 1;
            var _max_hp = variable_struct_exists(monster, "max_hp") ? monster.max_hp : 1;
            var _atk = variable_struct_exists(monster, "attack") ? monster.attack : 1;
            var _def = variable_struct_exists(monster, "defense") ? monster.defense : 0;
            var _spd = variable_struct_exists(monster, "spd") ? monster.spd : 1;
            if (_hp > 0) {
                // 建立防禦性結構
                var safe_monster = {
                    template_id: variable_struct_exists(monster, "template_id") ? monster.template_id : (variable_struct_exists(monster, "id") ? monster.id : -1),
                    name: variable_struct_exists(monster, "name") ? monster.name : "???",
                    level: variable_struct_exists(monster, "level") ? monster.level : 1,
                    hp: _hp,
                    max_hp: _max_hp,
                    attack: _atk,
                    defense: _def,
                    spd: _spd,
                    display_sprite: variable_struct_exists(monster, "display_sprite") ? monster.display_sprite : (variable_struct_exists(monster, "sprite_index") ? monster.sprite_index : -1),
                    skills: variable_struct_exists(monster, "skills") ? monster.skills : [],
                    skill_unlock_levels: variable_struct_exists(monster, "skill_unlock_levels") ? monster.skill_unlock_levels : [],
                    type: variable_struct_exists(monster, "type") ? monster.type : "obj_test_summon"
                };
                ds_list_add(monster_list, safe_monster);
            }
        }
    }
}

/// 繪製怪物卡片
/// @param {real} x 卡片x座標
/// @param {real} y 卡片y座標
/// @param {struct} monster_data 怪物數據
/// @param {bool} is_selected 是否被選中
draw_monster_card = function(x, y, monster_data, is_selected) {
    var card_width = 220;
    var card_height = 120;
    
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
    draw_rectangle(x + 10, y + 10, x + 70, y + 70, true);
    
    // 繪製怪物縮略圖
    draw_set_color(c_dkgray);
    draw_rectangle(x + 11, y + 11, x + 69, y + 69, false);
    
    // --- 修改：嘗試從 monster_data.display_sprite 獲取精靈 --- 
    var monster_sprite = -1;
    if (variable_struct_exists(monster_data, "display_sprite")) {
        monster_sprite = monster_data.display_sprite;
       // show_debug_message(">>> draw_monster_card: Found display_sprite = " + string(monster_sprite) + " for " + monster_data.name); // DEBUG ADDED (顯示值和名稱)
    } else {
        show_debug_message(">>> draw_monster_card: display_sprite NOT FOUND in monster_data for " + monster_data.name); // DEBUG ADDED
    }
    // --- 修改結束 ---
    
    if (monster_sprite != -1 && sprite_exists(monster_sprite)) { // <-- 添加 sprite_exists 檢查
        draw_sprite_stretched(monster_sprite, 0, x + 11, y + 11, 58, 58);
    } else {
        // 如未找到精靈，繪製一個占位符
        draw_set_color(c_gray);
        draw_rectangle(x + 20, y + 20, x + 60, y + 60, false);
        draw_set_color(c_white);
        draw_text(x + 30, y + 35, "?");
    }
    
    // 怪物名稱
    draw_set_color(c_white);
    draw_text(x + 80, y + 15, monster_data.name);
    
    // 怪物等級
    draw_text(x + 80, y + 35, "Lv. " + string(monster_data.level));
    
    // HP條
    var hp_x = x + 80;
    var hp_y = y + 55;
    var hp_width = 130;
    var hp_height = 10;
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
    draw_text(x + 80, hp_y + hp_height + 25, "攻: " + string(monster_data.attack) + " 防: " + string(monster_data.defense) + " 速: " + string(monster_data.spd));
    
    // 恢復繪圖顏色
    draw_set_color(c_white);
};

// --- 新增：UI管理器接口函數和標誌 ---

process_internal_input_flag = false; // 標誌：是否應處理內部輸入

// 處理關閉輸入 (ESC)
handle_close_input = function() {
    show_debug_message("[Summon UI] handle_close_input called (ESC). Requesting UI Manager hide.");
    if (instance_exists(obj_ui_manager)) {
        obj_ui_manager.hide_ui(id);
    } else {
        show_debug_message("警告：UI Manager 不存在，無法請求隱藏 Summon UI");
    }
}

// 處理確認輸入 (Enter/Space) - 改為直接調用全局腳本函數，不再傳遞管理器參數
handle_confirm_input = function() {
    // 直接調用全局腳本函數，只傳遞 UI 實例
    summon_ui_handle_confirm(id);
}

// 處理鼠標點擊 (由 UI 管理器傳遞) - 改為直接調用全局腳本函數，不再傳遞管理器參數
handle_mouse_click = function(mx, my) {
    // 直接調用全局腳本函數，傳遞 UI 實例和鼠標坐標
    return summon_ui_handle_mouse_click(id, mx, my);
}

// --- 結束新增 ---

// 添加清理事件
event_user(15); // Clean Up (假設 EV_CLEAN_UP = 15)

// 清理函數定義
on_cleanup = function() {
    // 確保列表存在再銷毀
    if (ds_exists(monster_list, ds_type_list)) {
        ds_list_destroy(monster_list);
        monster_list = -1; // 標記為無效
    }
    
    // 釋放表面
    if (surface_exists(ui_surface)) {
        surface_free(ui_surface);
        ui_surface = -1;
    }
}

show_debug_message("obj_summon_ui Create event finished.");