// obj_capture_ui 的 Draw_64.gml (針對性修正版)

// 調試輸出
show_debug_message("捕獲UI Draw_64 事件開始");
show_debug_message("active: " + string(active));
show_debug_message("visible: " + string(visible));
show_debug_message("ui_x: " + string(ui_x));
show_debug_message("ui_y: " + string(ui_y));
show_debug_message("ui_width: " + string(ui_width));
show_debug_message("ui_height: " + string(ui_height));
show_debug_message("target_enemy: " + string(target_enemy));
show_debug_message("capture_state: " + string(capture_state));
show_debug_message("alarm[0]: " + string(alarm[0]));
show_debug_message("alarm[1]: " + string(alarm[1]));

// 明確設置字體 - 與obj_dialogue_box相同
draw_set_font(fnt_dialogue);


// 如果 UI 不活躍，不進行繪製
if (!active) {
    show_debug_message("UI 未活躍，不繪製");
    return;
}

show_debug_message("UI active: " + string(active) + ", visible: " + string(visible));

// 計算 UI 中心座標和按鈕位置
var center_x = ui_x + ui_width / 2;
var center_y = ui_y + ui_height / 2;
capture_btn_x = ui_x + ui_width / 4 - capture_btn_width / 2;
capture_btn_y = ui_y + ui_height - 60;
cancel_btn_x = ui_x + ui_width * 3/4 - cancel_btn_width / 2;
cancel_btn_y = ui_y + ui_height - 60;

// 繪製半透明背景遮罩 (這始終會繪製，無論表面是否存在)
var gui_width = display_get_gui_width();
var gui_height = display_get_gui_height();
draw_set_color(c_black);
draw_set_alpha(0.7);
draw_rectangle(0, 0, gui_width, gui_height, false);
draw_set_alpha(1.0);
draw_set_color(c_white);

// 表面管理：重寫表面創建和繪製邏輯
var need_direct_draw = false; // 是否需要直接繪製 (不使用表面)

// 嘗試創建或更新表面
if (!surface_exists(ui_surface)) {
    // 確保尺寸合理
    var valid_width = max(100, ui_width);
    var valid_height = max(100, ui_height);
    
    show_debug_message("嘗試創建表面，尺寸：" + string(valid_width) + "x" + string(valid_height));
    
    // 嘗試創建新表面
    ui_surface = surface_create(valid_width, valid_height);
    
    if (surface_exists(ui_surface)) {
        show_debug_message("✅ 表面創建成功 ID: " + string(ui_surface));
        surface_needs_update = true;
    } else {
        show_debug_message("❌ 表面創建失敗，將使用直接繪製");
        need_direct_draw = true;
    }
}

// 更新表面內容 (如果表面存在且需要更新)
if (surface_exists(ui_surface) && surface_needs_update) {
    surface_set_target(ui_surface);
    
    // 清空表面並設置為暗紅色
    draw_clear_alpha(c_maroon, 1.0);
    
    // 繪製標題欄背景
    draw_set_color(make_color_rgb(120, 40, 40));
    draw_rectangle(1, 1, ui_width - 2, 40, false);
    
    // 繪製邊框
    draw_set_color(c_yellow);
    draw_rectangle(0, 0, ui_width - 1, ui_height - 1, true);
    
    // 重置繪圖設置
    draw_set_color(c_white);
    
    surface_reset_target();
    surface_needs_update = false;
    show_debug_message("表面內容已更新");
}

// 將表面繪製到畫面，或直接繪製 UI
if (surface_exists(ui_surface) && !need_direct_draw) {
    // 使用表面繪製
    draw_surface(ui_surface, ui_x, ui_y);
    show_debug_message("表面已繪製到座標：" + string(ui_x) + "," + string(ui_y));
} else {
    // 直接繪製 UI (表面不存在或創建失敗時的備用方法)
    need_direct_draw = true;
    show_debug_message("使用直接繪製模式");
    
    // 繪製主要背景
    draw_set_color(c_maroon);
    draw_rectangle(ui_x, ui_y, ui_x + ui_width, ui_y + ui_height, false);
    
    // 繪製標題欄背景
    draw_set_color(make_color_rgb(120, 40, 40));
    draw_rectangle(ui_x + 1, ui_y + 1, ui_x + ui_width - 2, ui_y + 40, false);
    
    // 繪製邊框
    draw_set_color(c_yellow);
    draw_rectangle(ui_x, ui_y, ui_x + ui_width, ui_y + ui_height, true);
    
    // 重置繪圖設置
    draw_set_color(c_white);
}

// 繪製標題
draw_text_safe(center_x, ui_y + 20, "捕獲怪物", c_white, TEXT_ALIGN_CENTER);

// 根據捕獲狀態繪製不同內容
switch (capture_state) {
    case "ready":
        // 繪製捕獲和取消按鈕
        draw_ui_button(
            capture_btn_x, capture_btn_y,
            capture_btn_width, capture_btn_height,
            "捕獲"
        );
        
        draw_ui_button(
            cancel_btn_x, cancel_btn_y,
            cancel_btn_width, cancel_btn_height,
            "取消"
        );
        break;

    case "capturing":
        // 捕獲中動畫
        var capture_duration = capture_animation_duration; // 使用類變數而非硬編碼
        var time_remaining = max(0, alarm[0]); // 剩餘時間
        var time_elapsed = capture_duration - time_remaining; // 已經過時間
        var capture_progress = clamp(time_elapsed / capture_duration, 0, 1);
        
        // 調試輸出捕獲進度
        show_debug_message("捕獲動畫: 進度=" + string(capture_progress) + " 已經過=" + string(time_elapsed) + "/" + string(capture_duration) + " alarm[0]=" + string(time_remaining));
        
        // 進度文字 - 使用脈動效果提高可見性
        var text_pulse = 1 + 0.2 * sin(current_time * 0.01);
        draw_text_transformed_safe(center_x, center_y - 30, "捕獲中...", c_white, text_pulse, text_pulse, 0, TEXT_ALIGN_CENTER, TEXT_VALIGN_MIDDLE);

        // 使用進度條函數
        var colors = [real(c_dkgray), real(c_yellow), real(c_white), real(c_white)];
        draw_progress_bar(center_x - 100, center_y, 200, 20, capture_progress * 100, 100, colors, true);
        
        // 捕獲球動畫效果 - 脈動並旋轉
        var ball_base_size = 40;
        var ball_size = ball_base_size * (0.8 + 0.2 * sin(current_time * 0.01));
        var rotation = (current_time * 0.1) % 360;
        
        // 外圈
        draw_set_color(c_red);
        draw_circle(center_x, center_y + 60, ball_size, false);
        
        // 內圈
        draw_set_color(c_white);
        draw_circle(center_x, center_y + 60, ball_size * 0.7, false);
        
        // 中間線
        draw_set_color(c_black);
        draw_line_width(
            center_x - ball_size, center_y + 60,
            center_x + ball_size, center_y + 60,
            3
        );
        
        // 中央按鈕
        draw_set_color(c_white);
        draw_circle(center_x, center_y + 60, ball_size * 0.2, false);
        draw_set_color(c_black);
        draw_circle(center_x, center_y + 60, ball_size * 0.2, true);
        
        // 如果捕獲進度超過50%，添加發光效果
        if (capture_progress > 0.5) {
            var glow_alpha = (capture_progress - 0.5) * 2; // 0 -> 1
            var glow_size = ball_size * (1 + glow_alpha * 0.5);
            
            draw_set_alpha(glow_alpha * 0.5);
            draw_set_color(c_yellow);
            draw_circle(center_x, center_y + 60, glow_size, false);
            draw_set_alpha(1.0);
        }
        break;

    case "success":
        // 成功畫面
        var success_anim_duration = capture_result_duration; // 使用類變數
        var time_remaining = max(0, alarm[1]); // 剩餘時間
        var elapsed_time = success_anim_duration - time_remaining; // 已經過時間
        var anim_progress = elapsed_time / success_anim_duration; // 動畫進度 (0.0 -> 1.0)
        
        show_debug_message("成功動畫: 已經過=" + string(elapsed_time) + "/" + string(success_anim_duration) + " 進度=" + string(anim_progress) + " alarm[1]=" + string(alarm[1]));

        // 綠色閃光效果 - 在動畫初期更強烈
        var flash_alpha = max(0, 0.8 - anim_progress * 0.8); // 整個動畫過程中逐漸減弱
        draw_set_color(c_lime);
        draw_set_alpha(flash_alpha);
        draw_rectangle(0, 0, gui_width, gui_height, false);
        draw_set_alpha(1);

        // 成功文字 (始終顯示，帶脈動效果)
        var pulse_speed = 6; // 控制脈動速度
        var text_scale = 1.5 + 0.5 * sin(current_time * 0.01); // 脈動效果
        var text_angle = sin(current_time * 0.005) * 5; // 輕微擺動
        
        // 繪製帶有描邊的成功文字
        var text_color = make_color_rgb(0, 220, 0); // 亮綠色
        var outline_color = c_black;
        draw_text_outlined(
            center_x, center_y,
            "捕獲成功！", 
            text_color, outline_color,
            TEXT_ALIGN_CENTER, TEXT_VALIGN_MIDDLE,
            text_scale
        );
       
        // 顯示星星特效 - 從中心向外擴散
        var star_count = 12; // 星星數量
        for (var i = 0; i < star_count; i++) {
            // 計算星星位置 - 根據當前動畫進度確定半徑
            var base_radius = 20; // 最小半徑
            var max_radius_add = 150; // 最大額外半徑
            var radius = base_radius + (anim_progress * max_radius_add); // 星星擴散的半徑
            
            var angle = (current_time * 0.05) + (i * (360 / star_count)); // 旋轉角度，均勻分布
            var star_x = center_x + lengthdir_x(radius, angle);
            var star_y = center_y + lengthdir_y(radius, angle);
            
            // 星星大小隨時間略微變化
            var star_size = 10 + 5 * sin(current_time * 0.01 + i);
            
            // 星星透明度隨時間和距離淡出
            var star_alpha = max(0, 1 - (anim_progress * 0.8)); // 隨時間淡出
            
            // 繪製星星
            draw_set_color(c_yellow);
            draw_set_alpha(star_alpha);
            draw_circle(star_x, star_y, star_size, false);
            
            // 星星光芒 (內部白色部分)
            draw_set_color(c_white);
            draw_set_alpha(star_alpha * 0.7);
            draw_circle(star_x, star_y, star_size * 0.6, false);
        }
        
        // 捕獲怪物訊息
        var monster_name = "(未知)";
        if (target_enemy != noone && is_struct(captured_monster_data) && variable_struct_exists(captured_monster_data, "name")) {
            monster_name = captured_monster_data.name;
        }
        
        draw_text_transformed_safe(
            center_x, center_y + 60, 
            "獲得 " + monster_name + "！", 
            c_white, 1, 1, 0, 
            TEXT_ALIGN_CENTER, TEXT_VALIGN_MIDDLE
        );
        
        // 重設繪圖設置
        draw_set_alpha(1.0);
        draw_set_color(c_white);
        break;

    case "failed":
        // 失敗畫面
        var fail_anim_duration = capture_result_duration; // 使用類變數
        var time_remaining = max(0, alarm[1]); // 剩餘時間
        var elapsed_time = fail_anim_duration - time_remaining; // 已經過時間
        var anim_progress = elapsed_time / fail_anim_duration; // 動畫進度 (0.0 -> 1.0)
        
        show_debug_message("失敗動畫: 已經過=" + string(elapsed_time) + "/" + string(fail_anim_duration) + " 進度=" + string(anim_progress) + " alarm[1]=" + string(alarm[1]));

        // 紅色閃光效果 - 在整個動畫過程中逐漸衰減
        var flash_alpha_fail = max(0, 0.7 - anim_progress * 0.7); 
        draw_set_color(c_red);
        draw_set_alpha(flash_alpha_fail);
        draw_rectangle(0, 0, gui_width, gui_height, false);
        draw_set_alpha(1);

        // 失敗文字 (抖動效果)
        var max_shake = 8; // 最大抖動幅度
        var shake_amount = max_shake * (1 - anim_progress * 0.7); // 抖動程度隨時間減弱但不完全消失
        var shake_x = random_range(-shake_amount, shake_amount);
        var shake_y = random_range(-shake_amount, shake_amount);
        
        // 文字大小也隨時間變化，初期較大
        var text_scale_fail = 1.5 - (0.3 * anim_progress);
        
        // 繪製帶有描邊的失敗文字
        var text_color = make_color_rgb(255, 50, 50); // 鮮紅色
        var outline_color = c_black;
        draw_text_outlined(
            center_x + shake_x, center_y + shake_y,
            "捕獲失敗！", 
            text_color, outline_color,
            TEXT_ALIGN_CENTER, TEXT_VALIGN_MIDDLE,
            text_scale_fail
        );
        
        // 顯示破碎效果 - 從中心向外飛散的碎片
        var fragment_count = 15; // 增加碎片數量
        for (var i = 0; i < fragment_count; i++) {
            // 計算碎片位置 - 隨時間向外飛散
            var base_radius = 10; // 初始半徑
            var max_radius_add = 180; // 增加最大半徑
            var fragment_radius = base_radius + (anim_progress * max_radius_add);
            
            // 添加隨機性到每個碎片的移動中
            var speed_variance = 0.7 + random(0.6); // 0.7-1.3的速度變化
            fragment_radius *= speed_variance;
            
            var fragment_angle = (360 / fragment_count) * i + current_time * 0.02; // 均勻分布並緩慢旋轉
            var fragment_x = center_x + lengthdir_x(fragment_radius, fragment_angle);
            var fragment_y = center_y + lengthdir_y(fragment_radius, fragment_angle);
            
            // 碎片透明度隨時間淡出但不完全消失
            var fragment_alpha = max(0.2, 1 - anim_progress * 0.8);
            
            // 隨機形狀的碎片
            draw_set_color(c_red);
            draw_set_alpha(fragment_alpha);
            
            // 隨機決定碎片形狀
            var shape_type = (i % 3); // 0=三角形, 1=矩形, 2=圓形
            var fragment_size = 8 + random(6); // 增加碎片大小
            
            if (shape_type == 0) {
                // 三角形碎片
                var x1 = fragment_x;
                var y1 = fragment_y - fragment_size;
                var x2 = fragment_x - fragment_size;
                var y2 = fragment_y + fragment_size;
                var x3 = fragment_x + fragment_size;
                var y3 = fragment_y + fragment_size;
                draw_triangle(x1, y1, x2, y2, x3, y3, false);
            } 
            else if (shape_type == 1) {
                // 矩形碎片
                draw_rectangle(fragment_x - fragment_size, fragment_y - fragment_size, 
                              fragment_x + fragment_size, fragment_y + fragment_size, false);
            }
            else {
                // 圓形碎片
                draw_circle(fragment_x, fragment_y, fragment_size, false);
            }
        }
        
        // 失敗原因訊息
        if (variable_instance_exists(id, "fail_reason") && fail_reason != "") {
            draw_text_transformed_safe(
                center_x, center_y + 60, 
                fail_reason, 
                c_white, 1, 1, 0, 
                TEXT_ALIGN_CENTER, TEXT_VALIGN_MIDDLE
            );
        }
        
        // 重設繪圖設置
        draw_set_alpha(1.0);
        draw_set_color(c_white);
        break;
}

// 如果有目標敵人，繪製敵人信息
if (target_enemy != noone && instance_exists(target_enemy)) {
    // 敵人精靈
    var enemy_sprite = target_enemy.sprite_index;
    var enemy_x = ui_x + 100;
    var enemy_y = ui_y + ui_height / 2 - 30;
    
    // 敵人縮略圖區域
    draw_set_color(c_white);
    draw_rectangle(enemy_x - 50, enemy_y - 50, enemy_x + 50, enemy_y + 50, true);
    
    // 繪製敵人精靈
    if (sprite_exists(enemy_sprite)) {
        var sprite_scale = min(100 / sprite_get_width(enemy_sprite), 100 / sprite_get_height(enemy_sprite));
        draw_sprite_ext(enemy_sprite, 0, enemy_x, enemy_y, sprite_scale, sprite_scale, 0, c_white, 1);
    }
    
    // 顯示敵人名稱
    draw_text_safe(enemy_x, enemy_y + 60, object_get_name(target_enemy.object_index), c_white, TEXT_ALIGN_CENTER);
    
    // HP信息
    var hp_percent = target_enemy.hp / target_enemy.max_hp;
    draw_text_safe(ui_x + 180, ui_y + 80, "HP: " + string(target_enemy.hp) + "/" + string(target_enemy.max_hp), c_white);
    
    // HP條
    var hp_bar_x = ui_x + 180;
    var hp_bar_y = ui_y + 100;
    var hp_bar_width = 200;
    var hp_bar_height = 20;
    
    // 創建HP顏色
    var hp_color = make_color_rgb(
        255 * (1 - hp_percent),
        255 * hp_percent,
        0
    );
    
    // 修复類型不匹配問題
    var colors = [
        real(c_dkgray), 
        real(hp_color), 
        real(c_white), 
        real(c_white)
    ];
    
    draw_progress_bar(
        hp_bar_x, hp_bar_y,
        hp_bar_width, hp_bar_height,
        target_enemy.hp, target_enemy.max_hp,
        colors,
        false
    );
    
    // 捕獲率信息
    var chance_text = "捕獲成功率: " + string(round(capture_chance * 100)) + "%";
    draw_text_safe(ui_x + 180, ui_y + 130, chance_text, c_yellow);
    
    // 捕獲提示
    var tip_text = "受傷的怪物更容易捕獲!";
    draw_text_safe(ui_x + 180, ui_y + 150, tip_text, c_white);
    
    // 捕獲方法列表
    var method_count = array_length(capture_methods);
    var method_x = ui_x + 180;
    var method_y = ui_y + 180;
    
    draw_text_safe(method_x, method_y, "選擇捕獲方式:", c_white);
    
    for (var i = 0; i < method_count; i++) {
        var capture_method = capture_methods[i]; // 使用数组索引
        var is_selected = (i == selected_method);
        
        var option_y = method_y + 25 + (i * 30);
        
        // 選中標記
        if (is_selected) {
            draw_set_color(c_yellow);
            draw_triangle(method_x - 20, option_y, method_x - 10, option_y - 5, method_x - 10, option_y + 5, false);
        }
        
        // 方法名稱
        var text_color = is_selected ? real(c_yellow) : real(c_white);
        draw_text_safe(method_x, option_y, capture_method.name, text_color);
        
        // 方法描述（簡短）
        draw_text_safe(method_x + 120, option_y, capture_method.description, c_silver);
        
        // 如果有消耗，顯示消耗
        if (variable_struct_exists(capture_method, "cost")) {
            draw_text_safe(method_x + 300, option_y, "消耗: " + capture_method.cost.item + " x" + string(capture_method.cost.amount), c_orange);
        }
    }

    // Debug 訊息
    if (variable_global_exists("game_debug_mode") && global.game_debug_mode) {
        show_debug_message("捕獲敵人: " + object_get_name(target_enemy.object_index));
    }
}

// 如果没有有效目标，且处于准备状态
if ((target_enemy == noone || !instance_exists(target_enemy)) && (capture_state == "ready")) {
    // 如果沒有有效目標
    draw_text_safe(
        center_x,
        center_y,
        "沒有可捕獲的目標！",
        c_white, 
        TEXT_ALIGN_CENTER, 
        TEXT_VALIGN_MIDDLE
    );
    
    // 關閉按鈕 - 使用修改後的函數名
    draw_ui_button(
        center_x - 60, 
        ui_y + ui_height - 60,
        120, 
        40,
        "關閉"
    );
}

// 重置繪圖設置
draw_set_halign(0); // 0 = fa_left
draw_set_valign(0); // 0 = fa_top
draw_set_color(c_white);
draw_set_alpha(1.0);

show_debug_message("捕獲UI Draw_64 事件結束");