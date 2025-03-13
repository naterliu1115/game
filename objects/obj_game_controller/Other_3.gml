// obj_game_controller - Game End 事件
// 手動清理 UI 管理器
if (instance_exists(obj_ui_manager)) {
    with (obj_ui_manager) {
        cleanup();
        instance_destroy();
    }
}

// 清理其他全局資源
// ...