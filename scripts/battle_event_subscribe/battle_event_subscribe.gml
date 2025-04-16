/// @description 訂閱戰鬥管理器相關事件
/// @author AI
function battle_event_subscribe() {
    show_debug_message("===== 開始訂閱戰鬥事件 (battle_event_subscribe) =====");
    if (instance_exists(obj_event_manager)) {
        show_debug_message("事件管理器存在，開始訂閱...");
        with (obj_event_manager) {
            show_debug_message("正在訂閱戰鬥結果相關事件...");
            subscribe_to_event("all_enemies_defeated", other.id, "on_all_enemies_defeated");
            subscribe_to_event("all_player_units_defeated", other.id, "on_all_player_units_defeated");
            subscribe_to_event("battle_defeat_handled", other.id, "on_battle_defeat_handled");
            subscribe_to_event("battle_result_closed", other.id, "on_battle_result_closed");
            show_debug_message("正在訂閱單位相關事件...");
            subscribe_to_event("unit_stats_updated", other.id, "on_unit_stats_updated");
            subscribe_to_event("unit_died", other.id, "on_unit_died");
            show_debug_message("正在訂閱戰鬥階段相關事件...");
            subscribe_to_event("battle_ending", other.id, "on_battle_ending");
            subscribe_to_event("battle_result_confirmed", other.id, "on_battle_result_confirmed");
            subscribe_to_event("rewards_calculated", other.id, "on_rewards_calculated");
            subscribe_to_event("battle_start", other.id, "start_battle");
        }
        show_debug_message("所有事件訂閱完成 (battle_event_subscribe)");
    }
} 