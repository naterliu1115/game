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
            // 在這裡添加怪物加入收藏的邏輯
            show_debug_message("成功捕獲: " + object_get_name(target_enemy.object_index));
            
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