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

hide = function() {
    active = false; 
    visible = false;
    depth = 0;
    allow_player_movement = true;  // 添加這行來恢復玩家移動能力
    
    // 釋放表面資源
    if (surface_exists(ui_surface)) {
        surface_free(ui_surface);
        ui_surface = -1;
    }
    
    // 重置繪圖屬性，避免影響其他UI
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_set_alpha(1.0);
    
    // 如果是從準備階段打開的，讓戰鬥UI知道玩家已經關閉了召喚UI
    if (from_preparing_phase && instance_exists(obj_battle_ui)) {
        // 可以在這裡做一些清理工作或顯示提示
    }
    
    from_preparing_phase = false; // 重置標記
    show_debug_message("召喚UI已關閉，資源已釋放");
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
            if (monster.hp > 0) {
                ds_list_add(monster_list, monster);
            }
        }
    }
}

/// 召喚選中的怪物
summon_selected_monster = function() {
    if (selected_monster >= 0 && selected_monster < ds_list_size(monster_list)) {
        var monster_data = monster_list[| selected_monster];
        
        // 首先檢查 obj_unit_manager 是否存在
        if (!instance_exists(obj_unit_manager)) {
            if (instance_exists(obj_battle_ui)) {
                obj_battle_ui.show_info("單位管理器不存在！");
            }
            return false;
        }
        
        // 檢查召喚條件
        if (obj_unit_manager.global_summon_cooldown <= 0 && 
            ds_list_size(obj_unit_manager.player_units) < obj_unit_manager.max_player_units) {
            // 獲取召喚位置（靠近玩家）
            var summon_x = global.player.x + 50;
            var summon_y = global.player.y;
            
            // 創建對應類型的召喚物
            var summon_type = monster_data.type;
            // 在創建前打印 summon_type 的值
            show_debug_message("[Summon UI] 準備創建實例，類型 object_index: " + string(summon_type) + " (" + object_get_name(summon_type) + ")");
            var new_summon = instance_create_layer(summon_x, summon_y, "Instances", summon_type);
            
            // 設置召喚物的屬性與數據匹配
            with (new_summon) {
                // 1. 首先設置 active 變量，防止 parent_ui 的 Step 事件出錯
                if (variable_instance_exists(id, "active")) {
                     active = false;  // 確保重置為 false，即使父類可能設置了
                } else {
                     active = false;  // 如果不存在，直接創建並設為 false
                }
                
                // 2. 然後設置 template_id (假設 monster_data.id 是模板 ID)
                if (variable_struct_exists(monster_data, "id")) { // 檢查 id 是否存在
                    template_id = monster_data.id;
                    show_debug_message("設置召喚物 template_id 為: " + string(template_id));
                } else {
                    show_debug_message("錯誤：monster_data 中缺少 id (template_id)");
                    instance_destroy(); // 創建失敗，銷毀
                    return false; // 或者返回錯誤
                }
                
                // 3. 設置 level (從 monster_data 中獲取)
                if (variable_struct_exists(monster_data, "level")) { // 檢查 level 是否存在
                    level = monster_data.level;
                    show_debug_message("設置召喚物 level 為: " + string(level));
                } else {
                    show_debug_message("警告：monster_data 中缺少 level，預設為 1");
                    level = 1; // 如果缺少 level，提供一個預設值
                }
                
                // 4. 最後才調用 initialize
                if (variable_instance_exists(id, "initialize")) {
                     initialize();
                     show_debug_message("玩家召唤物初始化完成: ref instance " + string(id));
                } else {
                    show_debug_message("錯誤：召喚物缺少 initialize 函數");
                    // 可能需要額外處理
                }
            }
            
            // 添加到玩家單位列表
            ds_list_add(obj_unit_manager.player_units, new_summon);
            
            // 設置全局召喚冷卻
            obj_unit_manager.global_summon_cooldown = obj_unit_manager.max_global_cooldown;
            
            // 創建召喚效果
            instance_create_layer(summon_x, summon_y, "Instances", obj_summon_effect);
            
            // 如果在準備階段召喚，立即開始戰鬥
            if (instance_exists(obj_battle_manager) && obj_battle_manager.battle_state == BATTLE_STATE.PREPARING) {
                obj_battle_manager.battle_state = BATTLE_STATE.ACTIVE;
                obj_battle_manager.battle_timer = 0;
                
                // 更新UI提示
                if (instance_exists(obj_battle_ui)) {
                    obj_battle_ui.show_info("戰鬥開始!");
                }
            }
            
            // 顯示成功召喚提示
            if (instance_exists(obj_battle_ui)) {
                obj_battle_ui.show_info("已召喚 " + monster_data.name + "!");
            }
            return true;
        } else {
            // 提示玩家無法召喚的原因
            var reason = "";
            if (obj_unit_manager.global_summon_cooldown > 0) {
                reason = "召喚冷卻中!";
            } else if (ds_list_size(obj_unit_manager.player_units) >= obj_unit_manager.max_player_units) {
                reason = "已達到最大召喚數量!";
            }
            
            if (instance_exists(obj_battle_ui)) {
                obj_battle_ui.show_info("無法召喚: " + reason);
            }
            return false;
        }
    }
    return false;
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
        show_debug_message(">>> draw_monster_card: Found display_sprite = " + string(monster_sprite) + " for " + monster_data.name); // DEBUG ADDED (顯示值和名稱)
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