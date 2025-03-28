// obj_battle_manager - Draw_0.gml

if (battle_state != BATTLE_STATE.INACTIVE && battle_area.boundary_radius > 0) {
    // 绘制战斗边界圆圈
    draw_set_color(c_red);
    draw_set_alpha(0.3);
    draw_circle(battle_area.center_x, battle_area.center_y, battle_area.boundary_radius, false);
    
    // 绘制边界轮廓
    draw_set_color(c_red);
    draw_set_alpha(0.7);
    draw_circle(battle_area.center_x, battle_area.center_y, battle_area.boundary_radius, true);
    
    // 重置绘制设置
    draw_set_color(c_white);
    draw_set_alpha(1.0);
    
    // 可选：在调试模式下显示单位数量
    var debug_y = 10;
    draw_text(10, debug_y, "战斗时间: " + string(battle_timer / game_get_speed(gamespeed_fps)) + "秒");
    debug_y += 20;
    
    if (instance_exists(obj_unit_manager)) {
        draw_text(10, debug_y, "玩家单位: " + string(ds_list_size(obj_unit_manager.player_units)));
        debug_y += 20;
        draw_text(10, debug_y, "敌方单位: " + string(ds_list_size(obj_unit_manager.enemy_units)));
    }
}