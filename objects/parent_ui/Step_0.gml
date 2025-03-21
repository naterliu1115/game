// parent_ui Step Event

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
} 