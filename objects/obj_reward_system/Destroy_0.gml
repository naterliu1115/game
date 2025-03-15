// =======================
// Destroy 事件代碼
// =======================

// obj_reward_system - Destroy_0.gml

// 取消事件訂閱
if (instance_exists(obj_event_manager)) {
    with (obj_event_manager) {
        unsubscribe_from_all_events(other.id);
    }
}