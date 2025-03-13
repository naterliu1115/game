// obj_battle_overlay - Create_0.gml
visible = true;
depth = -1000; // 確保最上層
target_state = BATTLE_STATE.PREPARING; // 目標戰鬥狀態

// 追蹤其他 UI 可見性的變數
summon_ui_visible = false;
monster_ui_visible = false;
should_check_visibility = true; // 標記是否需要檢查可見性