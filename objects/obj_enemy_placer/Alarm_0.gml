// obj_enemy_placer - Alarm_0.gml
// 在遊戲啟動時自動執行轉換為真正敵人的操作

if (!is_undefined(global.enemy_templates)) {
    /* // 移除或註解掉這一段開始
    available_templates = [];
    template_names = [];
    var key_list = ds_list_create();
    var template_map = global.enemy_templates;
    var key = ds_map_find_first(template_map);
    while (!is_undefined(key)) {
        var template = get_template_by_id(key);
        if (!is_undefined(template)) {
            array_push(available_templates, template.id);
            array_push(template_names, template.name);
        }
        key = ds_map_find_next(template_map, key);
    }
    ds_list_destroy(key_list);
    if (array_length(available_templates) > 0) {
        update_template_info(available_templates[0]); // <--- 特別是這行，它覆蓋了 template_id
    }
    */ // 移除或註解掉這一段結束

    // 直接調用轉換函數，它會使用實例自身的 template_id
    convert_to_real_enemy(); 
    
    // === 加入實例數量檢查 ===
    show_debug_message("[DEBUG] obj_enemy_placer Alarm 0 - obj_test_enemy count after conversion: " + string(instance_number(obj_test_enemy)));
    // === 檢查結束 ===
    
    show_debug_message("[DEBUG] obj_enemy_placer - 怪物模板資料已成功初始化！"); // 注意：此日誌可能不再完全準確
    show_debug_message("[DEBUG] obj_enemy_placer Alarm 0 - 觸發");
    show_debug_message("[DEBUG] obj_enemy_placer Alarm 0 - 當前座標, x=" + string(x) + ", y=" + string(y));

    // === 將銷毀操作移到這裡 ===
    instance_destroy(); // 銷毀 placer 自身
    // === 銷毀結束 ===
} else {
    show_debug_message("[DEBUG] obj_enemy_placer - enemy_templates 尚未初始化，延遲重試...");
    alarm[0] = 5; // 過幾步再重試
}



