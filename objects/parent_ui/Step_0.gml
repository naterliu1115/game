// parent_ui Step Event

// 添加檢查：在讀取 active 之前確認它是否存在
if (!variable_instance_exists(id, "active")) {
    show_debug_message("!!! 嚴重錯誤：實例 " + string(id) + " (" + object_get_name(object_index) + ") 的 Step 事件正在運行，但 'active' 變數不存在！");
    // 添加默認值
    active = false; // 確保 active 存在
    exit; // 退出 Step 事件，防止崩潰
}

// 如果UI活躍，禁止遊戲中的按鍵操作
if (active) {
    // 禁止玩家移動 - 更強制的方法
    if (instance_exists(Player)) {
        with (Player) {
            // 如果不是對話UI或其他特殊UI，則禁止移動
            if (!other.allow_player_movement) {
                keyboard_clear(vk_left);
                keyboard_clear(vk_right);
                keyboard_clear(vk_up);
                keyboard_clear(vk_down);
                // 額外設置速度為0
                hspeed = 0;
                vspeed = 0;
                speed = 0;
            }
        }
    }
    
    // 禁止其他遊戲操作（根據UI類型決定）
    if (!allow_game_controls) {
        keyboard_clear(ord("E")); // 互動鍵
        keyboard_clear(vk_space); // 召喚UI
        keyboard_clear(ord("M")); // 標記目標
    }
} else {
    // 如果UI不活動，檢查是否需要完全隱藏（關閉動畫完成後）
    if (visible && open_animation > 0) {
        open_animation -= open_speed;
        if (open_animation <= 0) {
            open_animation = 0;
            visible = false; // 動畫結束後才設置為不可見
        }
        surface_needs_update = true; // 動畫過程中需要更新表面
    }
} 