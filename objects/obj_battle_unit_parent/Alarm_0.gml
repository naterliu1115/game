/// @description 實體銷毀

// 減少計時器計數
timer_count--;

// 檢查計時器是否完成
if (timer_count <= 0) {
    // 根據計時器類型執行不同操作
    switch (timer_type) {
        case TIMER_TYPE.DEATH:
            // 死亡後自我銷毀
            instance_destroy();
            break;
            
        // --- 移除 HURT_RECOVERY case --- 
        /*
        case TIMER_TYPE.HURT_RECOVERY:
            // 受傷後恢復
            current_animation = UNIT_ANIMATION.IDLE; // 恢復閒置動畫
            current_state = UNIT_STATE.IDLE;     // 強制狀態回到閒置
            is_acting = false;                   // 確保行動標誌被重置
            is_attacking = false;                // 確保攻擊標誌被重置
            skill_animation_playing = false;     // 確保動畫播放標誌被重置
            // atb_paused = false; // 是否需要解除 ATB 暫停取決於具體邏輯，可以暫時不加
            show_debug_message(object_get_name(object_index) + " 恢復自受傷狀態。"); // 添加除錯訊息
            break;
        */
    }
    
    // 重置計時器
    timer_type = TIMER_TYPE.NONE;
} else {
    // 還有剩餘時間，繼續計時
    alarm[0] = 1;
}