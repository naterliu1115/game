// obj_battle_result_popup - Step_0.gml

if (!active) exit; // 如果 UI 不活躍，不處理輸入




// --- 新增：更新滑入+淡入動畫 --- 
var animation_finished = true; // 假設動畫已完成

// 更新 Y 座標
if (abs(current_y - target_y) > 0.5) { // 檢查 Y 是否到達目標 (增加容錯)
    current_y = lerp(current_y, target_y, open_speed);
    animation_finished = false;
} else if (current_y != target_y) {
    current_y = target_y; // 直接設為目標值
}

// 更新 Alpha
if (abs(current_alpha - 1) > 0.01) { // 檢查 Alpha 是否到達目標
    current_alpha = lerp(current_alpha, 1, open_speed);
    animation_finished = false;
} else if (current_alpha != 1) {
    current_alpha = 1; // 直接設為目標值
}
// --- 結束新增 ---

// 檢查是否按下 空白鍵 或 ESC 鍵
if (keyboard_check_pressed(vk_space) || keyboard_check_pressed(vk_escape)) {
    handle_close_input();
} 