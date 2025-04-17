// obj_test_enemy - Step_0.gml

// 處理冷卻時間
if (!variable_instance_exists(self, "battle_cooldown")) battle_cooldown = 0;
if (battle_cooldown > 0) {
    battle_cooldown--;
}

// 繼承父物件的Step事件
event_inherited(); 