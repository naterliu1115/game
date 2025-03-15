// 在所有 UI 物件的 CleanUp 事件中
if (surface_exists(ui_surface)) {
    surface_free(ui_surface);
}
// 其他本地資源清理...

