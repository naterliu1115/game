// Surface丢失检测 (如窗口调整大小或最小化后)
if (!surface_exists(dialogue_surface) && surface_width > 0) {
    surface_needs_update = true;
}