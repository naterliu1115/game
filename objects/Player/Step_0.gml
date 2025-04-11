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

// 更新滑鼠方向
mouse_direction = point_direction(x, y, mouse_x, mouse_y);
facing_direction = mouse_direction;

// 更新裝備的工具
if (instance_exists(obj_item_manager)) {
    var tool = obj_item_manager.get_selected_tool();

    // 如果選中了新的工具，更新裝備狀態
    if (tool != noone) {
        if (equipped_tool_id != tool.id) {
            equipped_tool = tool;
            equipped_tool_id = tool.id;
            equipped_tool_sprite = obj_item_manager.get_item_sprite(tool.id);
            equipped_tool_name = tool.data.Name;
            equipped_tool_value = tool.data.EffectValue;

            show_debug_message("玩家裝備了工具：" + equipped_tool_name);
        }
    } else {
        // 如果沒有選中工具，清除裝備狀態
        if (equipped_tool_id != -1) {
            equipped_tool = noone;
            equipped_tool_id = -1;
            equipped_tool_sprite = -1;
            equipped_tool_name = "";
            equipped_tool_value = 0;

            show_debug_message("玩家取消裝備工具");
        }
    }
}

// 處理挖礦邏輯
var is_mouse_pressed = mouse_check_button(mb_left);
var is_mouse_pressed_new = mouse_check_button_pressed(mb_left);
var has_pickaxe = (equipped_tool_id == 5001); // 檢查是否裝備了礦錘（ID 5001）

// 根據面向方向決定挖礦動畫
mining_direction = (facing_direction > 90 && facing_direction < 270) ?
    PLAYER_ANIMATION.MINING_LEFT : PLAYER_ANIMATION.MINING_RIGHT;

// 只有在裝備礦錘的情況下才允許挖礦
if (has_pickaxe && (is_mouse_pressed_new || (is_mouse_pressed && mining_animation_complete))) {
    // 開始新的挖礦動作
    is_mining = true;
    mining_animation_complete = false;
    mining_animation_frame = 0;
    current_animation = mining_direction;
}

// 更新挖礦動畫
if (is_mining) {
    // 獲取當前動畫的幀範圍
    var frame_range = (mining_direction == PLAYER_ANIMATION.MINING_LEFT) ?
        ANIMATION_FRAMES.MINING_LEFT : ANIMATION_FRAMES.MINING_RIGHT;

    // 檢查是否到達最後一幀
    var is_last_frame = (floor(mining_animation_frame) >= (frame_range[1] - frame_range[0]));

    if (is_last_frame) {
        // 在最後一幀停留
        image_index = frame_range[1];
        mining_last_frame_timer++;

        // 檢查是否完成停留時間
        if (mining_last_frame_timer >= MINING_LAST_FRAME_DELAY) {
            mining_animation_complete = true;
            mining_last_frame_timer = 0;

            if (!is_mouse_pressed) {
                // 如果沒有按住滑鼠，結束挖礦
                is_mining = false;
                current_animation = PLAYER_ANIMATION.IDLE;
            } else {
                // 重置動畫幀以繼續挖礦
                mining_animation_frame = 0;
            }
        }
    } else {
        // 正常更新挖礦動畫幀
        mining_animation_frame += MINING_ANIMATION_SPEED;
        image_index = frame_range[0] + floor(mining_animation_frame);
    }
}

// 只有在不挖礦時才允許移動
if (!is_mining) {
    // 獲取WASD輸入
    var move_x = keyboard_check(ord("D")) - keyboard_check(ord("A"));
    var move_y = keyboard_check(ord("S")) - keyboard_check(ord("W"));

    // 保存上一幀的位置
    last_x = x;
    last_y = y;

    // 判斷是否正在移動
    is_moving = (move_x != 0 || move_y != 0);

    // 更新動畫狀態
    if (!is_moving) {
        // 待機動畫 - 使用IDLE
        current_animation = PLAYER_ANIMATION.IDLE;
    } else {
        // 移動動畫 - 根據面向方向選擇
        var angle_segment = (facing_direction + 22.5) mod 360;
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
} else {
    // 在挖礦時禁止移動
    move_x = 0;
    move_y = 0;
    is_moving = false;
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
    case PLAYER_ANIMATION.MINING_LEFT: frame_range = ANIMATION_FRAMES.MINING_LEFT; break;
    case PLAYER_ANIMATION.MINING_RIGHT: frame_range = ANIMATION_FRAMES.MINING_RIGHT; break;
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
if (move_x != 0 || move_y != 0) {
    // 計算移動方向
    var move_dir = point_direction(0, 0, move_x, move_y);
    var move_len = move_speed;

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
    var can_interact = false;

    if (nearest_npc != noone) {
        var dist = point_distance(x, y, nearest_npc.x, nearest_npc.y);
        if (dist <= interact_radius) {
            // 更新 HUD 的互動提示
            can_interact = true;
            if (keyboard_check_pressed(ord("E"))) {
                start_dialogue(nearest_npc.id);
            }
        }
    }

    // 更新 HUD 的互動提示
    if (instance_exists(obj_main_hud)) {
        obj_main_hud.show_interaction_prompt = can_interact;
    }
} else {
    // 在對話狀態下，隱藏互動提示
    if (instance_exists(obj_main_hud)) {
        obj_main_hud.show_interaction_prompt = false;
    }

    if (keyboard_check_pressed(vk_enter) || keyboard_check_pressed(ord("E"))) {
        advance_dialogue();
    }
}

// **進入戰鬥檢查**
if (!in_battle) {
    var enemy = instance_place(x, y, obj_enemy_parent);
    if (enemy != noone) {
        // 檢查敵人是否有冷卻期
        if (!variable_instance_exists(enemy, "battle_cooldown") || enemy.battle_cooldown <= 0) {
            // 保存敵人信息
            var enemy_x = enemy.x;
            var enemy_y = enemy.y;
            
            // 獲取敵人模板ID
            var template_id = 1001; // 默認基礎敵人模板ID
            if (variable_instance_exists(enemy, "template_id") && enemy.template_id != -1) {
                template_id = enemy.template_id;
            }
            
            // 從地圖移除原始敵人
            instance_destroy(enemy);
            
            // 檢查戰鬥管理器是否存在
            if (!instance_exists(obj_battle_manager)) {
                instance_create_layer(0, 0, "Controllers", obj_battle_manager);
            }
            
            // 使用工廠啟動戰鬥
            with (obj_battle_manager) {
                // 使用新的工廠方法啟動戰鬥
                if (instance_exists(obj_enemy_factory)) {
                    start_factory_battle(template_id, enemy_x, enemy_y);
                } else {
                    // 如果工廠不存在，使用傳統方法
                    show_debug_message("警告：敵人工廠不存在，使用傳統方法啟動戰鬥");
                    var fallback_enemy = instance_create_layer(enemy_x, enemy_y, "Instances", obj_test_enemy);
                    start_battle(fallback_enemy);
                }
            }
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
