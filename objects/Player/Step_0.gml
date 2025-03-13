// **获取输入**
var move_x = keyboard_check(vk_right) - keyboard_check(vk_left);
var move_y = keyboard_check(vk_down) - keyboard_check(vk_up);

// **设置移动速度变量**
var move_speed = 4;

// 获取战斗状态相关变量 - 整合到一处以提高代码可读性
var in_battle = global.in_battle;
var battle_manager_exists = instance_exists(obj_battle_manager);
var boundary_radius = 0;

if (in_battle && battle_manager_exists) {
    with (obj_battle_manager) {
        boundary_radius = battle_boundary_radius;
    }
}

// **精确移动计算**
var move_dir = 0;
var move_len = 0;

// 只有当玩家实际移动时才进行计算
if (move_x != 0 || move_y != 0) {
    move_dir = point_direction(0, 0, move_x, move_y);
    move_len = (move_x != 0 && move_y != 0) ? move_speed : move_speed;

    var hsp = lengthdir_x(move_len, move_dir);
    var vsp = lengthdir_y(move_len, move_dir);

    hsp += x_remainder;
    vsp += y_remainder;

    var hsp_final = floor(abs(hsp)) * sign(hsp);
    var vsp_final = floor(abs(vsp)) * sign(vsp);

    x_remainder = hsp - hsp_final;
    y_remainder = vsp - vsp_final;

    // X轴移动与碰撞
    if (hsp_final != 0) {
        var target_x = x + hsp_final;
        if (!place_meeting(target_x, y, obj_solid)) {
            x = target_x;
        } else {
            while (!place_meeting(x + sign(hsp_final), y, obj_solid)) {
                x += sign(hsp_final);
            }
            x_remainder = 0;
        }
        image_xscale = (hsp > 0) ? 1 : -1;
    }

    // Y轴移动与碰撞
    if (vsp_final != 0) {
        var target_y = y + vsp_final;
        if (!place_meeting(x, target_y, obj_solid)) {
            y = target_y;
        } else {
            while (!place_meeting(x, y + sign(vsp_final), obj_solid)) {
                y += sign(vsp_final);
            }
            y_remainder = 0;
        }
    }
}

// 保存当前精确位置以供下一步使用
xprevious_precise = x;
yprevious_precise = y;

// **优化后的相机跟随代码**
var view_w = camera_get_view_width(view_camera[0]);
var view_h = camera_get_view_height(view_camera[0]);

var cam_x = x - (view_w / 2);
var cam_y = y - (view_h / 2);

var cam_smooth = 1.0;
var current_cam_x = camera_get_view_x(view_camera[0]);
var current_cam_y = camera_get_view_y(view_camera[0]);

cam_x = lerp(current_cam_x, cam_x, cam_smooth);
cam_y = lerp(current_cam_y, cam_y, cam_smooth);

cam_x = round(cam_x);
cam_y = round(cam_y);

camera_set_view_pos(view_camera[0], cam_x, cam_y);

// **玩家与 NPC 互动**
if (!is_dialogue_active()) {
    var interact_radius = 50;
    var nearest_npc = instance_nearest(x, y, obj_npc_parent);
    
    if (nearest_npc != noone) {
        var dist = point_distance(x, y, nearest_npc.x, nearest_npc.y);
        if (dist <= interact_radius && keyboard_check_pressed(ord("E"))) {
            start_dialogue(nearest_npc.id);
        }
    }
}

// 玩家按 E 或 Enter 继续对话
if (is_dialogue_active() && (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(ord("E")))) {
    advance_dialogue();
}

// **检测战斗并触发**
if (!in_battle) {
    var enemy = instance_place(x, y, obj_enemy_parent);
    if (enemy != noone && battle_manager_exists) {
        with (obj_battle_manager) {
            start_battle(enemy);
        }
    }
}

// **在战斗中按空格键打开召唤UI**
if (in_battle && keyboard_check_pressed(vk_space)) {
    if (instance_exists(obj_battle_manager) && obj_battle_manager.battle_state == BATTLE_STATE.PREPARING) {
        // 只在准备阶段允许召唤
        if (instance_exists(obj_game_controller)) {
            with (obj_game_controller) {
                toggle_summon_ui();
            }
        } else {
            // 后备方案：直接创建和操作召唤UI
            if (!instance_exists(obj_summon_ui)) {
                instance_create_layer(0, 0, "Instances", obj_summon_ui);
            }
            
            // 确保UI存在后再调用其方法
            if (instance_exists(obj_summon_ui)) {
                with (obj_summon_ui) {
                    from_preparing_phase = true; // 标记为准备阶段打开
                    open_summon_ui();
                }
            }
        }
    } else if (instance_exists(obj_battle_ui)) {
        // 在其他阶段显示提示
        obj_battle_ui.show_info("只能在戰鬥準備階段召喚怪物！");
    }
}

// **在战斗中按M键标记目标**
if (in_battle && keyboard_check_pressed(ord("M"))) {
    var nearest_enemy = noone;
    var min_dist = 100000;   
    
    with (obj_enemy_parent) {
        var dist = point_distance(x, y, other.x, other.y);
        if (dist < min_dist) {
            min_dist = dist;
            nearest_enemy = id;
        }
    }
    
    if (nearest_enemy != noone) {
        // 清除所有单位的标记状态
        with (obj_battle_unit_parent) {
            marked = false;
        }
        
        // 标记选中的敌人
        nearest_enemy.marked = true;
        show_debug_message("标记了敌人: " + string(nearest_enemy));
        
        // 更新UI信息
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.battle_info = "已标记敌人为目标!";
        }
    } else {
        // 没有找到敌人时的提示
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.battle_info = "没有可标记的敌人!";
        }
    }
}