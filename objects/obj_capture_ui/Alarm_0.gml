// obj_capture_ui - Alarm 0
show_debug_message("Alarm 0 觸發 - 處理捕獲結果");

// 重置狀態變數
captured_monster_data = undefined;
fail_reason = "";

// 設置 capture_state (繪圖需要)
if (capture_result) {
    capture_state = "success";
} else {
    capture_state = "failed";
}

// --- 在處理結果前，先消耗使用的道具 --- 
// 我們在 attempt_capture 中將使用的 ID 存入了 last_used_item_id
if (last_used_item_id != noone && last_used_item_id != -1) {
    // --- 直接調用計劃中的函數 --- 
    var item_removed = false;
    var item_manager_inst = instance_find(obj_item_manager, 0); // 查找第一個實例
    if (instance_exists(item_manager_inst)) { 
        // 直接調用，依賴於 obj_item_manager 未來實現此函數
        item_removed = item_manager_inst.remove_item_from_inventory(last_used_item_id, 1);
        if (item_removed) {
            show_debug_message("Alarm 0: 已通過管理器消耗捕獲道具 ID: " + string(last_used_item_id));
        } else {
             show_debug_message("Alarm 0 警告: 管理器嘗試消耗道具 ID: " + string(last_used_item_id) + " 失敗! (可能數量不足或函數問題)");
             // 這裡可以根據遊戲設計決定是否要因為消耗失敗而取消捕獲
             // capture_result = false; 
             // fail_reason = "道具消耗失敗";
        }
    } else {
        show_debug_message("Alarm 0 警告: 未找到 obj_item_manager 實例。無法消耗道具。");
    }
    // --- 調用結束 ---
    
    // 重置 last_used_item_id，避免重複消耗
    last_used_item_id = noone;
    
} else {
     show_debug_message("Alarm 0: 未使用捕獲道具 (last_used_item_id is noone).");
}
// --- 道具消耗結束 ---

// 調用 finalize_capture_action 並獲取其結果
var _result = undefined;
if (instance_exists(target_enemy)) {
    _result = finalize_capture_action(target_enemy, capture_result);
    show_debug_message("finalize_capture_action 返回: " + string(_result));
} else {
    show_debug_message("Alarm 0 警告: target_enemy 在 finalize_capture_action 調用前已不存在！");
    // 如果目標消失，也需要設置失敗原因
    if (!capture_result) {
        fail_reason = "目標消失";
    }
}

// 根據結果處理 captured_monster_data 和 fail_reason
if (capture_result) {
    // 成功情況
    if (is_struct(_result)) {
        captured_monster_data = _result; // 儲存返回的怪物數據
        show_debug_message("成功捕獲數據已設置: " + string(captured_monster_data));
    } else {
        // 雖然 capture_result 是 true，但 finalize 返回的不是 struct
        show_debug_message("警告: 捕獲成功，但 finalize_capture_action 未返回有效的怪物數據結構體。");
        captured_monster_data = { name: "(數據錯誤)" }; // 提供一個用於顯示的備用結構
    }
} else {
    // 失敗情況
    captured_monster_data = undefined; // 確保失敗時為 undefined
    if (is_string(_result)) {
        fail_reason = _result; // 使用返回的失敗原因字串
    } else if (fail_reason == "") { // 僅在之前未設置原因時使用默認值
         fail_reason = "捕獲失敗！"; // 默認失敗原因
    }
    show_debug_message("捕獲失敗原因已設置: " + fail_reason);
}


// 設置 Alarm 1 以顯示結果一段時間後關閉 UI
alarm[1] = capture_result_duration; // 使用類變數

// Alarm 0 執行完畢後會自動變為 -1