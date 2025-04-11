/// @description 初始化傷害測試控制器

// 測試用例列表
test_cases = [
    {
        name: "基礎傷害測試",
        attacker_attack: 100,
        skill_multiplier: 1.5,
        target_defense: 50,
        expected_damage: 100 // 100 * 1.5 - 50 = 100
    },
    {
        name: "最小傷害測試",
        attacker_attack: 10,
        skill_multiplier: 0.5,
        target_defense: 100,
        expected_damage: 1 // 10 * 0.5 - 100 = -95 -> max(1, -95) = 1
    },
    {
        name: "高倍率測試",
        attacker_attack: 100,
        skill_multiplier: 3.0,
        target_defense: 0,
        expected_damage: 300 // 100 * 3.0 - 0 = 300
    }
];

// 當前測試用例索引
current_test = 0;

// 測試結果列表
test_results = [];

// 開始測試
alarm[0] = 1;

// 執行測試用例
run_test_case = function() {
    if (current_test >= array_length(test_cases)) {
        show_debug_message("\n所有測試完成！");
        show_test_results();
        return;
    }
    
    var test = test_cases[current_test];
    show_debug_message("\n執行測試用例 #" + string(current_test + 1) + ": " + test.name);
    
    // 創建測試單位 (使用更清晰的變數名)
    var attacker_inst = instance_create_layer(room_width/3, room_height/2, "Instances", obj_test_attacker);
    var target_inst = instance_create_layer(2*room_width/3, room_height/2, "Instances", obj_test_target);
    
    // 檢查實例是否成功創建 (可選但更健壯)
    if (!instance_exists(attacker_inst) || !instance_exists(target_inst)) {
        show_error("測試錯誤：無法創建攻擊者或目標實例！", true);
        return;
    }

    // 設置測試參數 (直接訪問實例變數)
    attacker_inst.attack = test.attacker_attack;
    attacker_inst.current_skill = {
        id: 1,
        name: "測試技能",
        damage_multiplier: test.skill_multiplier
    };
    attacker_inst.target = target_inst; // **修正：直接將目標實例ID賦值給攻擊者的 target 變數**
    
    target_inst.defense = test.target_defense;
    
    // 執行攻擊 (直接調用實例的函數)
    attacker_inst.apply_skill_damage();
    
    // 記錄結果
    var actual_damage = 0;
    // 確保目標實例仍然存在才讀取傷害
    if (instance_exists(target_inst)) {
         actual_damage = target_inst.last_damage_taken;
    } else {
        show_debug_message("警告：目標實例在記錄結果前已被銷毀。實際傷害設為 0。");
    }
    var passed = (actual_damage == test.expected_damage);
    
    array_push(test_results, {
        name: test.name,
        expected: test.expected_damage,
        actual: actual_damage,
        passed: passed
    });
    
    // 清理測試實例 (檢查是否存在後再銷毀)
    if (instance_exists(attacker_inst)) {
        instance_destroy(attacker_inst);
    }
    if (instance_exists(target_inst)) {
        instance_destroy(target_inst);
    }
    
    // 準備下一個測試
    current_test++;
    alarm[0] = 1; // 保持 Alarm 延遲為 1 幀
}

// 顯示測試結果
show_test_results = function() {
    show_debug_message("\n測試結果總結：");
    show_debug_message("------------------------");
    
    var total_tests = array_length(test_results);
    var passed_tests = 0;
    
    for (var i = 0; i < total_tests; i++) {
        var result = test_results[i];
        var status = result.passed ? "通過" : "失敗";
        show_debug_message(
            string(i + 1) + ". " + result.name + " - " + status + "\n" +
            "   預期傷害: " + string(result.expected) + "\n" +
            "   實際傷害: " + string(result.actual)
        );
        
        if (result.passed) passed_tests++;
    }
    
    show_debug_message("------------------------");
    show_debug_message("總結: " + string(passed_tests) + "/" + string(total_tests) + " 測試通過");
} 