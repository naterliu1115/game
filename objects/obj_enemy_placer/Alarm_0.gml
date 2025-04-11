// obj_enemy_placer - Alarm_0.gml
// 在遊戲啟動時自動執行轉換為真正敵人的操作

show_debug_message("[DEBUG] obj_enemy_placer Alarm 0 - 觸發");
show_debug_message("[DEBUG] obj_enemy_placer Alarm 0 - 當前座標, x=" + string(x) + ", y=" + string(y));

convert_to_real_enemy(); 