debug_message_printed = false;
// 是否正在對話
active = false;
show_debug_message("Dialogue Active: " + string(active));

// 預設對話內容
dialogue = ["這是一個測試對話！", "你應該看到這行字！"];
dialogue_index = 0;

show_debug_message("初始對話內容: " + string(dialogue));

current_npc = noone; // 確保變數初始化，避免 GameMaker 誤報錯誤
dialogue_box_width = 0;
dialogue_box_x = 0;
dialogue_box_y = 0;
dialogue_box_needs_update = false; // 預設為 false，表示不需要更新


