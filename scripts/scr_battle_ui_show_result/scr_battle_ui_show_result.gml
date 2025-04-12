/// @function scr_battle_ui_show_result(event_data, ui_instance_id)
/// @description 處理 show_battle_result 事件的回調腳本，更新戰鬥UI。
/// @param {struct} event_data 事件管理器傳遞的數據結構體。
/// @param {Id.Instance} ui_instance_id 觸發此回調的 obj_battle_ui 實例ID。

function scr_battle_ui_show_result(event_data, ui_instance_id) {
    // 檢查 UI 實例是否存在，以防萬一
    if (!instance_exists(ui_instance_id)) {
        show_debug_message("警告 (scr_battle_ui_show_result): UI 實例 " + string(ui_instance_id) + " 不存在!");
        return;
    }

    // 切換到 UI 實例的上下文
    with (ui_instance_id) {
        // --- 將原來 on_show_battle_result 的邏輯複製到這裡 ---
        show_debug_message("[DEBUG] scr_battle_ui_show_result: Executing for instance " + string(id));
        show_debug_message("===== obj_battle_ui (via script) 收到 show_battle_result 事件 ====="); // 標識來源
        show_debug_message("Received data: " + json_stringify(event_data));

        // 從結構體中提取數據
        var _victory = variable_struct_get(event_data, "victory");
        var _duration = variable_struct_get(event_data, "battle_duration");
        var _defeated = variable_struct_get(event_data, "defeated_enemies");
        var _exp = variable_struct_get(event_data, "exp_gained");
        var _gold = variable_struct_get(event_data, "gold_gained");
        var _items = variable_struct_get(event_data, "item_drops"); // 確保使用正確的鍵名

        // 檢查數據是否存在
        if (is_undefined(_victory) || is_undefined(_duration) || is_undefined(_defeated) || is_undefined(_exp) || is_undefined(_gold) || is_undefined(_items)) {
            show_debug_message("警告 (scr_battle_ui_show_result): 收到的 show_battle_result 事件數據不完整！");
            return;
        }

        // 呼叫實例自身的 show_rewards 方法
        show_rewards(_victory, _duration, _defeated, _exp, _gold, _items);
        show_debug_message("(via script) 已呼叫 show_rewards 函數。");

        // 如果是失敗，確保更新懲罰文本
        if (!_victory) {
            update_rewards_display();
            show_debug_message("(via script) 檢測到失敗，已呼叫 update_rewards_display。");
        }
        // --- 複製結束 ---
    }
}