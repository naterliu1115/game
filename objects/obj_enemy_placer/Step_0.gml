// obj_enemy_placer - Step_0.gml

// 【移除】強制跟隨滑鼠位置
// x = mouse_x;
// y = mouse_y;

// 【移除】互動按鍵處理
/*
// 按下E切換到下一個敵人模板
if (keyboard_check_pressed(ord("E"))) {
    select_next_template();
}

// 按下Q切換到上一個敵人模板
if (keyboard_check_pressed(ord("Q"))) {
    select_prev_template();
}

// 按下左鍵放置敵人
if (mouse_check_button_pressed(mb_left)) {
    place_enemy(); // 這個函數未定義，會報錯
}

// 按下R鍵刪除最近的敵人
if (keyboard_check_pressed(ord("R"))) {
    var nearest_enemy = noone;
    var min_dist = 100000;
    
    with (obj_test_enemy) {
        var dist = point_distance(x, y, mouse_x, mouse_y);
        if (dist < min_dist) {
            min_dist = dist;
            nearest_enemy = id;
        }
    }
    
    if (nearest_enemy != noone && min_dist < 50) {
        show_debug_message("刪除敵人，位置: (" + string(nearest_enemy.x) + ", " + string(nearest_enemy.y) + ")");
        instance_destroy(nearest_enemy);
    }
}

// 按下ESC退出放置模式
if (keyboard_check_pressed(vk_escape)) {
    instance_destroy();
}
*/

// 可以保留 Step 中的 debug message，用於確認物件是否還存在以及其位置
show_debug_message("[STEP] obj_enemy_placer - ID: " + string(id) + ", Pos: x=" + string(x) + ", y=" + string(y) + ", Converted: " + string(converted));

// 如果需要，可以在這裡加入一些檢查條件，例如只在前幾幀打印
// if (current_time < 10) { // 假設 current_time 在 Create 中初始化為 0
//    show_debug_message(...);
//    current_time++;
// } 