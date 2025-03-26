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
            
        case TIMER_TYPE.HURT_RECOVERY:
            // 受傷後恢復動畫
            current_animation = UNIT_ANIMATION.IDLE;
            break;
    }
    
    // 重置計時器
    timer_type = TIMER_TYPE.NONE;
} else {
    // 還有剩餘時間，繼續計時
    alarm[0] = 1;
}