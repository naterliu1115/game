// obj_capture_ui - Create_0.gml
event_inherited();

// 初始化 UI 基本變數
ui_width = 0;
ui_height = 0;
ui_x = 0;
ui_y = 0;
ui_surface = -1; // 設為無效的表面 ID
surface_needs_update = true;

// 捕獲狀態變數
active = false;
visible = false;

// 定義標準UI方法
show = function() {
    visible = true;
    active = true;
    depth = -150; // 確保UI在overlay層級
    
    // 設定UI尺寸
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
    
    show_debug_message("捕獲UI已打開");
};

hide = function() {
    visible = false;
    active = false;
    depth = 0;
    
    // 釋放表面資源
    if (surface_exists(ui_surface)) {
        surface_free(ui_surface);
        ui_surface = -1;
    }
    
    // 清除目標參考
    target_enemy = noone;
    
    show_debug_message("捕獲UI已關閉");
};

target_enemy = noone;
capture_state = "ready";
capture_animation = 0;
capture_result = false;
capture_chance = 0;

// 動畫相關
open_animation = 0;
open_speed = 0.1;

// 捕獲方法 - 使用数组
capture_methods = []; 
selected_method = 0;

// 按鈕位置和尺寸
capture_btn_width = 120;
capture_btn_height = 40;
capture_btn_x = 0;
capture_btn_y = 0;

cancel_btn_width = 120;
cancel_btn_height = 40;
cancel_btn_x = 0;
cancel_btn_y = 0;

// 定義開啟捕獲 UI 的函數
open_capture_ui = function(target) {
    if (!instance_exists(target)) {
        show_debug_message("錯誤: 嘗試捕獲不存在的目標");
        return;
    }
    
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
    
    show_debug_message("打開捕獲 UI，目標：" + string(object_get_name(target.object_index)));
    
    // 通過UI管理器顯示
    if (instance_exists(obj_ui_manager)) {
        with(obj_ui_manager) {
            show_ui("overlay", other.id);
        }
    } else {
        // 備用方法，直接顯示
        show();
    }
    
    target_enemy = target;
    capture_state = "ready";
    open_animation = 0;

    // 重新初始化捕獲方法
    capture_methods = []; // 清空数组

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

    // 使用array_push添加到数组
    array_push(capture_methods, method1, method2);

    // 初始選擇第一個方法
    selected_method = 0;

    // 計算初始捕獲率
    calculate_capture_chance();

    // 確保 UI 需要更新
    surface_needs_update = true;
};

// 計算捕獲成功率
calculate_capture_chance = function() {
    if (target_enemy != noone && instance_exists(target_enemy)) {
        // 基礎捕獲率 (這可以根據怪物稀有度等調整)
        var base_chance = 0.3;
        
        // HP 影響 (HP 越低，捕獲率越高)
        var hp_factor = 1 - (target_enemy.hp / target_enemy.max_hp);
        
        // 捕獲方法的加成
        var method_bonus = 0;
        if (selected_method < array_length(capture_methods)) {
            var capture_method = capture_methods[selected_method]; // 使用数组索引
            if (variable_struct_exists(capture_method, "bonus")) {
                method_bonus = capture_method.bonus;
            }
        }
        
        // 計算最終捕獲率
        capture_chance = base_chance + (hp_factor * 0.4) + method_bonus;
        
        // 限制在 0 到 1 之間
        capture_chance = clamp(capture_chance, 0, 1);
        
        // Debug 輸出
        if (variable_global_exists("game_debug_mode") && global.game_debug_mode) {
            show_debug_message("捕獲率計算: 基礎=" + string(base_chance) + 
                             ", HP影響=" + string(hp_factor * 0.4) + 
                             ", 方法加成=" + string(method_bonus) + 
                             ", 最終=" + string(capture_chance));
        }
    } else {
        capture_chance = 0;
    }
};

// 嘗試捕獲敵人
attempt_capture = function() {
    if (target_enemy != noone && instance_exists(target_enemy)) {
        // 扣除物品
        var can_capture = true;
        if (selected_method < array_length(capture_methods)) {
            var capture_method = capture_methods[selected_method]; // 使用数组索引
            if (variable_struct_exists(capture_method, "cost")) {
                // 這裡應該添加檢查玩家是否有足夠的物品
                // 如: if (!player_has_item(capture_method.cost.item, capture_method.cost.amount)) can_capture = false;
            }
        }
        
        if (!can_capture) {
            // 顯示缺少物品的提示
            // show_message("缺少必要的捕獲道具!");
            return;
        }
        
        // 切換到捕獲中狀態
        capture_state = "capturing";
        capture_animation = 0;
        
        // 決定捕獲是否成功
        capture_result = (random(1) <= capture_chance);
        
        // Debug 輸出
        if (variable_global_exists("game_debug_mode") && global.game_debug_mode) {
            show_debug_message("嘗試捕獲: 機率 = " + string(capture_chance) + ", 結果 = " + (capture_result ? "成功" : "失敗"));
        }
    }
};

// 完成捕獲過程
finalize_capture = function() {
    if (capture_result) {
        // 捕獲成功的處理邏輯
        if (target_enemy != noone && instance_exists(target_enemy)) {
            // 在這裡添加怪物加入收藏的邏輯
            if (variable_global_exists("game_debug_mode") && global.game_debug_mode) {
                show_debug_message("成功捕獲: " + object_get_name(target_enemy.object_index));
            }
            
            // 這裡應該添加怪物加入玩家收藏的代碼
            // add_monster_to_collection(target_enemy);
            
            // 刪除敵人
            with (target_enemy) {
                instance_destroy();
            }
            
            // 通知戰鬥UI
            if (instance_exists(obj_battle_ui)) {
                obj_battle_ui.show_info("成功捕獲怪物！");
            }
        }
    } else {
        // 捕獲失敗
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.show_info("捕獲失敗！");
        }
    }
    
    // 關閉 UI
    hide();
};

// 添加UI繪製實用函數
draw_ui_button = function(x, y, width, height, text) {
    draw_set_color(c_dkgray);
    draw_rectangle(x, y, x + width, y + height, false);
    
    draw_set_color(c_white);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(x + width/2, y + height/2, text);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
};

// 安全繪製文本函數
draw_text_safe = function(x, y, text, color, halign = fa_left, valign = fa_top) {
    var old_halign = draw_get_halign();
    var old_valign = draw_get_valign();
    var old_color = draw_get_color();
    
    draw_set_halign(halign);
    draw_set_valign(valign);
    draw_set_color(color);
    
    draw_text(x, y, text);
    
    draw_set_halign(old_halign);
    draw_set_valign(old_valign);
    draw_set_color(old_color);
};

// 繪製進度條函數
draw_progress_bar = function(x, y, width, height, value, max_value, colors, is_vertical) {
    // 確保顏色是陣列
    if (!is_array(colors)) {
        colors = [c_dkgray, c_lime, c_white, c_white];
    }
    
    // 確保有足夠的顏色定義
    while (array_length(colors) < 4) {
        array_push(colors, c_white);
    }
    
    // 計算進度百分比
    var progress = clamp(value / max_value, 0, 1);
    
    // 繪製背景
    draw_set_color(colors[0]); // 背景色
    draw_rectangle(x, y, x + width, y + height, false);
    
    // 繪製填充部分
    if (progress > 0) {
        draw_set_color(colors[1]); // 填充色
        if (is_vertical) {
            draw_rectangle(x, y + height * (1 - progress), x + width, y + height, false);
        } else {
            draw_rectangle(x, y, x + width * progress, y + height, false);
        }
    }
    
    // 繪製邊框
    draw_set_color(colors[2]); // 邊框色
    draw_rectangle(x, y, x + width, y + height, true);
    
    // 繪製進度文字
    draw_set_color(colors[3]); // 文字色
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_text(x + width/2, y + height/2, string(floor(progress * 100)) + "%");
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
};

// obj_capture_ui/Create_0.gml
show_debug_message("捕获UI创建完成");