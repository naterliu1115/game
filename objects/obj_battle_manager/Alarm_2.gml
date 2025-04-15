/// @description 短暫延遲結束後，觸發戰鬥結果
show_debug_message("Alarm[2] 觸發 - 延遲結束，準備進入 RESULT 狀態");

// 確保我們是從 DELAYING 狀態過來的，並且主狀態仍然是 ENDING
if (battle_state == BATTLE_STATE.ENDING && ending_substate == ENDING_SUBSTATE.DELAYING) {

    ending_substate = ENDING_SUBSTATE.FINISHED; // 標記完成

    battle_state = BATTLE_STATE.RESULT;
    battle_timer = 0;  // 重置計時器給 RESULT 狀態用
    battle_result_handled = false; // 確保 RESULT 狀態可以處理結果

    // --- 執行原來邊界縮小完成後的邏輯 --- 
    var _duration_to_broadcast = 0;
    if (variable_instance_exists(id, "final_battle_duration_seconds")) {
        _duration_to_broadcast = final_battle_duration_seconds;
    } else {
        show_debug_message("警告: final_battle_duration_seconds 變數未定義! Setting duration to 0.");
    }

    // 發送事件以觸發最終的獎勵計算和結果顯示
    _event_broadcaster("finalize_battle_results", {
        defeated_enemies: enemies_defeated_this_battle,
        defeated_enemy_ids: defeated_enemy_ids_this_battle, 
        item_drops: current_battle_drops, // 傳遞之前記錄的總掉落物
        duration: _duration_to_broadcast
    });
    show_debug_message("[Battle Manager] Alarm[2]: Broadcasted finalize_battle_results with duration: " + string(_duration_to_broadcast) + ", defeated_enemies: " + string(enemies_defeated_this_battle) + ", IDs: " + json_stringify(defeated_enemy_ids_this_battle) + ", Drops: " + json_stringify(current_battle_drops));

} else {
     show_debug_message("警告：Alarm[2] 觸發，但狀態不符 (主狀態: " + string(battle_state) + ", 子狀態: " + string(ending_substate) + ")");
}

// Alarm 通常是一次性的，無需在此重置 ending_substate
// 重置應在戰鬥完全結束 (end_battle) 或重新開始 (initialize_battle_manager/start_battle) 時進行 