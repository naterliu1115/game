// 绘制单位本身
draw_self();

// 绘制生命条
var hp_width = 30;
var hp_height = 4;
var hp_x = x - hp_width/2;
var hp_y = y - sprite_height/2 - 10;

// 背景
draw_set_color(c_black);
draw_rectangle(hp_x, hp_y, hp_x + hp_width, hp_y + hp_height, false);

// 生命值
draw_set_color(c_green);
var hp_fill = (hp / max_hp) * hp_width;
draw_rectangle(hp_x, hp_y, hp_x + hp_fill, hp_y + hp_height, false);

// 如果被标记，绘制标记指示器
if (marked) {
    draw_set_color(c_yellow);
    draw_circle(x, y - sprite_height/2 - 15, 5, false);
}

// 绘制ATB条(如果在战斗中)
if (instance_exists(obj_battle_manager) && obj_battle_manager.battle_state == BATTLE_STATE.ACTIVE) {
    var atb_width = 30;
    var atb_height = 2;
    var atb_x = x - atb_width/2;
    var atb_y = y - sprite_height/2 - 5;
    
    // 背景
    draw_set_color(c_gray);
    draw_rectangle(atb_x, atb_y, atb_x + atb_width, atb_y + atb_height, false);
    
    // ATB填充
    draw_set_color(c_blue);
    var atb_fill = (atb_current / atb_max) * atb_width;
    draw_rectangle(atb_x, atb_y, atb_x + atb_fill, atb_y + atb_height, false);
}

// 重置绘图颜色
draw_set_color(c_white);