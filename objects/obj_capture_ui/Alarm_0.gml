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