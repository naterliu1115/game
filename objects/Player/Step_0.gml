// 更新全局戰鬥計時器
if (!variable_global_exists("battle_timer")) {
    global.battle_timer = 0;
}
global.battle_timer++;

// 檢查是否有活躍的UI阻止移動
var can_move = true;
if (instance_exists(obj_ui_manager)) {
    with (obj_ui_manager) {
        var keys = ds_map_keys_to_array(active_ui);
        for (var i = 0; i < array_length(keys); i++) {
            var layer_name = keys[i];
            var active_list = active_ui[? layer_name];
            for (var j = 0; j < ds_list_size(active_list); j++) {
                var ui = active_list[| j];
                if (instance_exists(ui) && variable_instance_exists(ui, "allow_player_movement") && !ui.allow_player_movement) {
                    can_move = false;
                    break;
                }
            }
            if (!can_move) break;
        }
    }
}

if (!can_move) {
    // 清除移動輸入
    move_x = 0;
    move_y = 0;
    exit;
}

// **获取输入**
var move_x = keyboard_check(vk_right) - keyboard_check(vk_left);
var move_y = keyboard_check(vk_down) - keyboard_check(vk_up);

// 保存上一幀的位置
last_x = x;
last_y = y;

// 更新動畫狀態 - 八方向實現
if (move_x == 0 && move_y == 0) {
    // 待機動畫
    current_animation = PLAYER_ANIMATION.IDLE;
} else {
    // 計算移動方向
    var move_dir = point_direction(0, 0, move_x, move_y);

    // 將360度分成8個區域，每個區域45度
    var angle_segment = move_dir + 22.5;
    if (angle_segment >= 360) angle_segment -= 360;

    var animation_index = floor(angle_segment / 45);

    switch(animation_index) {
        case 0: current_animation = PLAYER_ANIMATION.WALK_RIGHT; break;
        case 1: current_animation = PLAYER_ANIMATION.WALK_UP_RIGHT; break;
        case 2: current_animation = PLAYER_ANIMATION.WALK_UP; break;
        case 3: current_animation = PLAYER_ANIMATION.WALK_UP_LEFT; break;
        case 4: current_animation = PLAYER_ANIMATION.WALK_LEFT; break;
        case 5: current_animation = PLAYER_ANIMATION.WALK_DOWN_LEFT; break;
        case 6: current_animation = PLAYER_ANIMATION.WALK_DOWN; break;
        case 7: current_animation = PLAYER_ANIMATION.WALK_DOWN_RIGHT; break;
    }
}

// 根據當前動畫設置sprite範圍
var frame_range;
switch(current_animation) {
    case PLAYER_ANIMATION.IDLE: frame_range = ANIMATION_FRAMES.IDLE; break;
    case PLAYER_ANIMATION.WALK_DOWN: frame_range = ANIMATION_FRAMES.WALK_DOWN; break;
    case PLAYER_ANIMATION.WALK_DOWN_RIGHT: frame_range = ANIMATION_FRAMES.WALK_DOWN_RIGHT; break;
    case PLAYER_ANIMATION.WALK_RIGHT: frame_range = ANIMATION_FRAMES.WALK_RIGHT; break;
    case PLAYER_ANIMATION.WALK_UP_RIGHT: frame_range = ANIMATION_FRAMES.WALK_UP_RIGHT; break;
    case PLAYER_ANIMATION.WALK_UP: frame_range = ANIMATION_FRAMES.WALK_UP; break;
    case PLAYER_ANIMATION.WALK_UP_LEFT: frame_range = ANIMATION_FRAMES.WALK_UP_LEFT; break;
    case PLAYER_ANIMATION.WALK_LEFT: frame_range = ANIMATION_FRAMES.WALK_LEFT; break;
    case PLAYER_ANIMATION.WALK_DOWN_LEFT: frame_range = ANIMATION_FRAMES.WALK_DOWN_LEFT; break;
}

// 動畫更新邏輯
if (is_array(frame_range)) {
    // 檢測動畫變更
    var animation_name = string(current_animation);
    if (animation_name != current_animation_name) {
        current_animation_name = animation_name;
        image_index = frame_range[0];
        image_speed = (current_animation == PLAYER_ANIMATION.IDLE) ? 
            idle_animation_speed : animation_speed;
    }
    
    // 確保幀在正確範圍內
    if (image_index < frame_range[0] || image_index > frame_range[1]) {
        image_index = frame_range[0];
    }
}

// **设置移动速度变量**
var move_speed = 3;

// 获取战斗状态相关变量
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

if (move_x != 0 || move_y != 0) {
    move_dir = point_direction(0, 0, move_x, move_y);
    move_len = move_speed;

    var hsp = lengthdir_x(move_len, move_dir);
    var vsp = lengthdir_y(move_len, move_dir);

    hsp += x_remainder;
    vsp += y_remainder;

    var hsp_final = floor(abs(hsp)) * sign(hsp);
    var vsp_final = floor(abs(vsp)) * sign(vsp);

    x_remainder = hsp - hsp_final;
    y_remainder = vsp - vsp_final;

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
    }

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

xprevious_precise = x;
yprevious_precise = y;

// **相機跟隨**
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

// **玩家與 NPC 互動**
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

if (is_dialogue_active() && (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(ord("E")))) {
    advance_dialogue();
}

// **進入戰鬥檢查**
if (!in_battle) {
    var enemy = instance_place(x, y, obj_enemy_parent);
    if (enemy != noone && battle_manager_exists) {
        with (obj_battle_manager) {
            start_battle(enemy);
        }
    }
}

// **空白鍵開啟召喚UI**
if (in_battle && keyboard_check_pressed(vk_space)) {
    if (instance_exists(obj_battle_manager) && obj_battle_manager.battle_state == BATTLE_STATE.PREPARING) {
        if (instance_exists(obj_game_controller)) {
            with (obj_game_controller) {
                toggle_summon_ui();
            }
        } else {
            if (!instance_exists(obj_summon_ui)) {
                instance_create_layer(0, 0, "Instances", obj_summon_ui);
            }

            if (instance_exists(obj_summon_ui)) {
                with (obj_summon_ui) {
                    from_preparing_phase = true;
                    open_summon_ui();
                }
            }
        }
    } else if (instance_exists(obj_battle_ui)) {
        obj_battle_ui.show_info("只能在戰鬥準備階段召喚怪物！");
    }
}

// **M鍵標記敵人**
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
        with (obj_battle_unit_parent) {
            marked = false;
        }

        nearest_enemy.marked = true;
        show_debug_message("標記了敵人: " + string(nearest_enemy));

        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.battle_info = "已標記敵人為目標!";
        }
    } else {
        if (instance_exists(obj_battle_ui)) {
            obj_battle_ui.battle_info = "沒有可標記的敵人!";
        }
    }
}
