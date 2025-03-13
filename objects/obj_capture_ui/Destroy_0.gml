// obj_capture_ui 的 Destroy_0.gml


// 釋放表面 - 確保使用正確的類型檢查
if (is_real(ui_surface) && ui_surface > -1) {
    if (surface_exists(ui_surface)) {
        surface_free(ui_surface);
    }
    ui_surface = -1;
}

// 清除目標參考
target_enemy = noone;