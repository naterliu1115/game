// obj_main_hud - Step_0.gml

if (global.ui_input_block) exit; // <<-- 新增：如果 UI 正在阻斷輸入，則跳過

// 調試：檢查 Step 事件是否執行
//show_debug_message("HUD Step: Active = " + string(active));
// 暫時註解掉，避免刷屏，如果完全沒反應再打開

if (!active) exit; // 如果物件非活動，不處理輸入

// --- 獲取當前滑鼠 GUI 座標 (避免重複獲取) ---
var mouse_gui_x = device_mouse_x_to_gui(0);
var mouse_gui_y = device_mouse_y_to_gui(0);

// --- 處理拖放邏輯 (新增) ---

// 1. 按下左鍵 - 檢查是否開始拖曳快捷欄物品
if (mouse_check_button_pressed(mb_left)) {
    if (!is_dragging_hotbar_item) { // 確保不在拖曳過程中再次觸發
        var clicked_slot = get_hotbar_slot_at_position(mouse_gui_x, mouse_gui_y);
        if (clicked_slot != -1) {
            // 檢查該欄位是否有物品
            var inventory_index = obj_item_manager.get_item_in_hotbar_slot(clicked_slot);
            if (inventory_index != noone) {
                // 開始拖曳
                is_dragging_hotbar_item = true;
                dragged_from_hotbar_slot = clicked_slot;
                dragged_item_inventory_index = inventory_index;

                // 獲取物品 ID 和 圖示
                var item_instance = global.player_inventory[| inventory_index];
                if (item_instance != undefined) {
                     var item_id = item_instance.item_id;
                     dragged_item_sprite = obj_item_manager.get_item_sprite(item_id);
                } else {
                    dragged_item_sprite = -1; // 找不到物品實例？
                }

                // 初始繪製位置
                drag_item_x = mouse_gui_x;
                drag_item_y = mouse_gui_y;

                show_debug_message("開始拖曳快捷欄位 " + string(clicked_slot) + " 中的物品 (背包索引: " + string(inventory_index) + ")");

                // 可選：拖曳時取消當前選擇框
                selected_hotbar_slot = -1;
            }
        }
    }
}

// 2. 按住左鍵 - 更新拖曳物品的位置
if (mouse_check_button(mb_left)) {
    if (is_dragging_hotbar_item) {
        drag_item_x = mouse_gui_x;
        drag_item_y = mouse_gui_y;
    }
}

// 3. 放開左鍵 - 檢查是否完成拖放交換
if (mouse_check_button_released(mb_left)) {
    if (is_dragging_hotbar_item) {
        var target_slot = get_hotbar_slot_at_position(mouse_gui_x, mouse_gui_y);

        if (target_slot != -1 && target_slot != dragged_from_hotbar_slot) {
            // 釋放在不同的有效欄位上，執行交換
            show_debug_message("嘗試將物品從欄位 " + string(dragged_from_hotbar_slot) + " 交換到欄位 " + string(target_slot));

            var item_in_target_slot = obj_item_manager.get_item_in_hotbar_slot(target_slot);

            // 執行交換 (直接修改全局數組)
            global.player_hotbar[target_slot] = dragged_item_inventory_index;
            global.player_hotbar[dragged_from_hotbar_slot] = item_in_target_slot;

            show_debug_message("快捷欄物品交換完成。");

            // 觸發更新事件 (可選)
            // if(instance_exists(obj_event_manager)) obj_event_manager.trigger_event("hotbar_updated");

        } else {
            // 釋放在無效位置或原位，取消拖放
            show_debug_message("釋放在無效位置或原位，取消拖放。");
        }

        // 重置拖曳狀態
        is_dragging_hotbar_item = false;
        dragged_item_inventory_index = noone;
        dragged_from_hotbar_slot = -1;
        dragged_item_sprite = -1;
    }
}

// --- 結束拖放邏輯 ---


// --- 處理其他滑鼠點擊 (背包、怪物按鈕 或 戰鬥按鈕) ---
// 將原有的點擊檢查移到這裡，並確保 *不在拖曳時* 才觸發
if (mouse_check_button_pressed(mb_left) && !is_dragging_hotbar_item) {

    // 獲取戰鬥狀態
    var _in_battle = (instance_exists(obj_battle_manager) && obj_battle_manager.battle_state != BATTLE_STATE.INACTIVE);

    if (!_in_battle) {
        // --- 非戰鬥狀態：處理原按鈕點擊 --- 
        // 檢查是否點擊背包圖示
        if (point_in_rectangle(mouse_gui_x, mouse_gui_y,
            bag_bbox[0], bag_bbox[1],
            bag_bbox[2], bag_bbox[3])) {
            if (instance_exists(obj_game_controller)) {
                with (obj_game_controller) { toggle_inventory_ui(); }
            }
        // 檢查是否點擊怪物管理按鈕
        } else if (point_in_rectangle(mouse_gui_x, mouse_gui_y,
                   monster_button_bbox[0], monster_button_bbox[1],
                   monster_button_bbox[2], monster_button_bbox[3])) {
            if (instance_exists(obj_game_controller)) {
                with (obj_game_controller) {
                    if (variable_instance_exists(id, "toggle_monster_manager_ui")) {
                        toggle_monster_manager_ui();
                    } else {
                        show_debug_message("錯誤：obj_game_controller 中缺少 toggle_monster_manager_ui 函數！");
                    }
                }
            }
        }
    } else {
        // --- 戰鬥狀態：處理新按鈕點擊 --- 
        // 檢查是否點擊召喚按鈕 (使用 bag_bbox，因為它取代了背包位置)
        if (point_in_rectangle(mouse_gui_x, mouse_gui_y,
            bag_bbox[0], bag_bbox[1],
            bag_bbox[2], bag_bbox[3])) {
            if (instance_exists(obj_battle_manager)) {
                // 假設 obj_battle_manager 有 try_summon 方法檢查冷卻並召喚
                if (variable_instance_exists(obj_battle_manager, "try_summon") && is_method(obj_battle_manager.try_summon)) {
                    obj_battle_manager.try_summon();
                } else if (variable_instance_exists(obj_battle_manager, "summon_monster") && is_method(obj_battle_manager.summon_monster)){
                     // 如果沒有 try_summon，直接呼叫 summon_monster (可能需要手動檢查冷卻)
                     // obj_battle_manager.summon_monster(); // 這裡需要召喚邏輯的更多細節
                     show_debug_message("呼叫 obj_battle_manager.summon_monster() - 需要確認參數和冷卻");
                } else {
                    show_debug_message("錯誤：obj_battle_manager 中缺少召喚相關方法！");
                }
            }
        // 檢查是否點擊收服按鈕 (使用 monster_button_bbox)
        } else if (point_in_rectangle(mouse_gui_x, mouse_gui_y,
                   monster_button_bbox[0], monster_button_bbox[1],
                   monster_button_bbox[2], monster_button_bbox[3])) {
             if (instance_exists(obj_game_controller)) {
                // 呼叫遊戲控制器的 toggle_capture_ui，它內部會檢查戰鬥狀態
                with (obj_game_controller) { toggle_capture_ui(); }
            }
        // 檢查是否點擊戰術按鈕 (使用 tactics_button_bbox)
        } else if (point_in_rectangle(mouse_gui_x, mouse_gui_y,
                   tactics_button_bbox[0], tactics_button_bbox[1],
                   tactics_button_bbox[2], tactics_button_bbox[3])) {
             if (instance_exists(obj_battle_manager)) {
                 // 呼叫戰鬥管理器中的戰術切換方法
                 if (variable_instance_exists(obj_battle_manager, "cycle_player_unit_tactics") && is_method(obj_battle_manager.cycle_player_unit_tactics)) {
                     obj_battle_manager.cycle_player_unit_tactics();
                 } else {
                     show_debug_message("錯誤：obj_battle_manager 中缺少 cycle_player_unit_tactics 方法！");
                 }
             }
        }
    }
}

// --- 處理快捷欄選擇 (數字鍵、滾輪) ---
// 確保 *不在拖曳時* 才處理選擇
if (!is_dragging_hotbar_item) {
    var selection_changed = false;
    var current_selection = selected_hotbar_slot;

    // --- 數字鍵 1-0 選擇/取消快捷欄 ---
    for (var i = 0; i < hotbar_slots; i++) {
        var key;
        // GMS 2.3+ 使用 vk_numpad0 到 vk_numpad9, 或 vk_0 到 vk_9
        // 為了兼容性，我們繼續用 ord()，但要注意 numpad 的情況可能需要額外處理
        if (i == 9) { key = ord("0"); } // 索引 9 對應數字鍵 '0'
        else { key = ord(string(i + 1)); } // 索引 0-8 對應數字鍵 '1'-'9'

        if (keyboard_check_pressed(key)) {
            // show_debug_message("按鍵按下: " + chr(key) + " (對應索引 " + string(i) + ")");
            if (selected_hotbar_slot == i) { // 如果按下的是當前已選中的鍵
                selected_hotbar_slot = -1; // 取消選中
                selection_changed = true;
                // show_debug_message("快捷欄取消選擇");
            } else { // 如果按下的是其他鍵，或當前未選中
                selected_hotbar_slot = i; // 選中對應欄位
                selection_changed = true;
            }
            break; // 找到按下的鍵就退出循環
        }
    }

    // --- 滑鼠滾輪切換/取消快捷欄 ---
    var wheel = mouse_wheel_up() - mouse_wheel_down();
    if (wheel != 0) {
        // show_debug_message("滑鼠滾輪: " + string(wheel));
        if (selected_hotbar_slot == -1) { // 如果當前未選中
            selected_hotbar_slot = 0; // 從第一個欄位開始選中 (索引 0)
            selection_changed = true;
        } else { // 如果當前已選中
            var current_slot = selected_hotbar_slot;
            if (wheel == 1 && current_slot == 0) { // 向上滾動且已在第一個欄位
                selected_hotbar_slot = -1; // 取消選中
                selection_changed = true;
                // show_debug_message("滾輪向上取消選擇");
            } else if (wheel == -1 && current_slot == hotbar_slots - 1) { // 向下滾動且已在最後一個欄位
                selected_hotbar_slot = -1; // 取消選中
                selection_changed = true;
                // show_debug_message("滾輪向下取消選擇");
            } else { // 正常滾動切換
                // 避免直接使用 modulo 導致從 -1 變為 hotbar_slots - 1
                selected_hotbar_slot -= wheel;
                // 確保在有效範圍內循環 (0 到 hotbar_slots - 1)
                // 注意: GML 的 % (modulo) 對負數的處理可能不如預期，手動處理更安全
                if (selected_hotbar_slot >= hotbar_slots) {
                     selected_hotbar_slot = 0; // 從尾部繞回頭部
                } else if (selected_hotbar_slot < -1) { // 防止滾輪過快導致跳過 -1
                     selected_hotbar_slot = hotbar_slots - 1; // 從頭部繞回尾部 (如果從 0 往上滾)
                } else if (selected_hotbar_slot < 0 && wheel > 0) { // 處理從 0 向上滾變 -1 後再向上滾的情況
                     selected_hotbar_slot = hotbar_slots - 1;
                }

                // 只有在實際改變選擇時才標記
                if (selected_hotbar_slot != current_slot) {
                    selection_changed = true;
                }
            }
        }
    }

    // 如果選擇改變，輸出新的選擇狀態 (可以保留此調試信息)
    if (selection_changed) {
        if (selected_hotbar_slot == -1) {
            show_debug_message("快捷欄取消選擇");
        } else {
            show_debug_message("快捷欄新選擇: " + string(selected_hotbar_slot));

            // 檢查選中欄位是否有工具類物品
            if (instance_exists(obj_item_manager)) {
                var inventory_index = obj_item_manager.get_item_in_hotbar_slot(selected_hotbar_slot);
                if (inventory_index != noone) {
                    var item_instance = global.player_inventory[| inventory_index];
                    if (item_instance != undefined) {
                        var item_id = item_instance.item_id;
                        var item_data = obj_item_manager.get_item(item_id);

                        // 如果是工具類型，使用工具
                        if (item_data != undefined && item_data.Category == ITEM_TYPE.TOOL) {
                            obj_item_manager.use_tool(item_id);
                        }
                    }
                }
            }
        }
    }
}