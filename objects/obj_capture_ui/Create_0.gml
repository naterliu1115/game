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
last_used_item_id = noone;

// 新增：動畫持續時間變數
capture_animation_duration = 120; // 捕獲動畫持續幀數 (2 秒 @ 60fps)
capture_result_duration = 90; // 捕獲結果顯示持續幀數 (1.5 秒 @ 60fps)
captured_monster_data = undefined; // 初始化用於儲存成功捕獲的怪物數據

// 捕獲狀態變數
active = false;
visible = false;

// 動畫相關
open_animation = 0;
open_speed = 0.1;

// 捕獲方法 - 使用陣列 (現在會動態填充)
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

    // --- 動態填充 capture_methods --- 
    capture_methods = []; // 清空舊列表
    selected_method = -1; // 重置選擇

    // 假設 obj_item_manager.get_inventory_items_by_type 返回一個陣列
    // 每個元素包含 { item_id: ..., quantity: ..., name: ..., effect_value: ... }
    var available_capture_items = []; 
    var item_manager_inst = instance_find(obj_item_manager, 0); // 查找第一個實例
    if (instance_exists(item_manager_inst)) { 
        // 直接調用，依賴於 obj_item_manager 未來實現此函數
        available_capture_items = item_manager_inst.get_inventory_items_by_type("CAPTURE"); 
    } else {
        show_debug_message("警告：找不到 obj_item_manager 實例，無法獲取捕獲道具。");
    }
    
    if (array_length(available_capture_items) == 0) {
        show_debug_message("玩家沒有可用的捕獲道具！");
        // 可以在這裡顯示提示給玩家並阻止 UI 打開
         if (instance_exists(obj_battle_ui)) {
             obj_battle_ui.show_info("沒有捕獲道具!");
         }
         // hide(); // 可以選擇直接關閉
         // 或者允許打開，但在Draw中顯示提示
         capture_chance = 0; // 沒有道具，機率為0 (如果目標可捕獲)
         active = true; // 仍然激活UI以顯示消息
         visible = true;
         depth = -150;
         // ... 更新UI尺寸和位置 ...
         return; // 阻止後續的機率計算
    }
    
    // 將可用的捕獲道具添加到 capture_methods
    for (var i = 0; i < array_length(available_capture_items); i++) {
        var item_info = available_capture_items[i];
        // 創建 capture_methods 需要的結構
        var method_entry = {
            item_id: item_info.item_id,
            name: item_info.name, // 從返回的數據獲取名稱
            quantity: item_info.quantity, // 從返回的數據獲取數量
            effect_value: item_info.effect_value, // 從返回的數據獲取效果值
            description: "使用 " + item_info.name + " 捕獲 (剩餘: " + string(item_info.quantity) + ")" // 可以動態生成描述
        };
        array_push(capture_methods, method_entry);
    }

    // 初始選擇第一個可用方法
    selected_method = 0; 

    // 計算初始捕獲率 (使用第一個道具)
    var initial_item_id = capture_methods[0].item_id; // 獲取第一個道具的 ID
    capture_chance = scr_calculate_capture_chance(target_enemy, initial_item_id);
    if (capture_chance == -1) {
        show_debug_message("目標不可捕獲！");
        if (instance_exists(obj_battle_ui)) {
             obj_battle_ui.show_info("這個敵人無法被捕獲!");
        }
        // 允許 UI 打開以顯示目標圖像，但在 Draw 中處理不可捕獲狀態
        capture_chance = 0; // 設置為 0 以免顯示錯誤機率
        // hide(); // 或者選擇不打開
    }
    // --- 捕獲方法填充結束 ---

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

// 嘗試捕獲 (重構後)
attempt_capture = function() {
    if (target_enemy != noone && instance_exists(target_enemy) && array_length(capture_methods) > 0 && selected_method != -1) {
        // 獲取選擇的道具信息
        var selected_capture_method = capture_methods[selected_method];
        var selected_item_id = selected_capture_method.item_id;
        
        // 檢查玩家是否確實擁有該物品 (數量檢查)
        var current_item_count = 0;
        var item_manager_inst = instance_find(obj_item_manager, 0); // 查找第一個實例
        if (instance_exists(item_manager_inst)) { 
            // 直接調用，依賴於 obj_item_manager 未來實現此函數
            current_item_count = item_manager_inst.get_item_count_in_inventory(selected_item_id); 
        } else {
             show_debug_message("警告：找不到 obj_item_manager 實例，無法檢查物品數量。");
             // 這裡可能需要報錯或假設數量為0
             current_item_count = 0;
        }

        if (current_item_count <= 0) {
            show_debug_message("缺少捕獲道具: " + selected_capture_method.name + " (ID: " + string(selected_item_id) + ")");
            if (instance_exists(obj_battle_ui)) {
                 obj_battle_ui.show_info("你沒有 " + selected_capture_method.name + " 了!"); // 顯示提示
            }
            // 需要刷新 capture_methods 列表嗎？或者僅阻止本次嘗試？
            // 最好刷新列表
            open_capture_ui(target_enemy); // 重新打開以刷新列表和選擇
            return; // 缺少物品，無法捕獲
        }
        
        // 1. 計算捕獲機率 (使用新腳本和選擇的道具ID)
        var calculated_chance = scr_calculate_capture_chance(target_enemy, selected_item_id);
        
        // 檢查是否不可捕獲 (-1)
        if (calculated_chance == -1) {
            show_debug_message("嘗試捕獲失敗：目標不可捕獲。");
             if (instance_exists(obj_battle_ui)) {
                 obj_battle_ui.show_info("這個敵人無法被捕獲!"); // 顯示提示
            }
            return;
        }
        
        // 更新顯示用的 capture_chance
        capture_chance = calculated_chance;
        surface_needs_update = true;
        
        // 2. 決定捕獲是否成功
        capture_result = (random(1) <= calculated_chance);
        
        // 3. 設置捕獲狀態和計時器
        capture_state = "capturing";
        var capture_duration = 120;
        alarm[0] = capture_duration;
        
        // 儲存本次使用的道具 ID，以便 Alarm 0 消耗
        last_used_item_id = selected_item_id; 
        
        // Debug 輸出
        show_debug_message("嘗試捕獲 (使用道具: " + selected_capture_method.name + " ID: " + string(selected_item_id) + "): 機率 = " + string(calculated_chance) + ", 結果將在 " + string(capture_duration) + " 幀後確定: " + (capture_result ? "預期成功" : "預期失敗"));
        
        // 標記表面需要更新以顯示 "捕獲中"
        surface_needs_update = true; 
    } else {
         show_debug_message("嘗試捕獲失敗：無目標、無可用道具或未選擇道具。");
    }
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