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
        // 繪製捕獲動畫
        capture_animation += 1;

        // 居中顯示捕獲進度
        var capture_progress = min(capture_animation / 120, 1); // 120幀的捕獲過程

        // 使用進度條函數 - 修复类型不匹配问题
        var colors = [
            real(c_dkgray), 
            real(c_yellow), 
            real(c_white), 
            real(c_white)
        ];
        
        draw_progress_bar(
        center_x - 100, center_y + 20,
        200, 20,
        capture_progress, 1,
        colors,
        false
        );

        // 進度文字
        draw_text_safe(center_x, center_y - 20, "捕獲中...", c_white, TEXT_ALIGN_CENTER);

        // 如果啟用 debug 模式，輸出當前捕獲進度
        if (variable_global_exists("game_debug_mode") && global.game_debug_mode) {
            show_debug_message("捕獲進度: " + string(capture_progress * 100) + "%");
        }

        // 捕獲成功與失敗的判斷
        if (capture_animation >= 120) {
            if (capture_result) {
                capture_state = "success";
                capture_animation = 0;
            } else {
                capture_state = "failed";
                capture_animation = 0;
            }
        }
        break;

    case "success":
        // 成功畫面
        capture_animation += 1;

        // 綠色閃光效果
        draw_set_color(c_lime);
        draw_set_alpha(max(0, 1 - capture_animation / 30));
        draw_rectangle(0, 0, gui_width, gui_height, false);
        draw_set_alpha(1);

        // 成功文字
        if (capture_animation <= 60) {
            draw_text_safe(center_x, center_y, "捕獲成功！", c_lime, TEXT_ALIGN_CENTER, TEXT_VALIGN_MIDDLE);
        }

        // 顯示星星特效
        for (var i = 0; i < 10; i++) {
            var star_x = center_x + lengthdir_x(50 + capture_animation, capture_animation * 2 + i * 36);
            var star_y = center_y + lengthdir_y(50 + capture_animation, capture_animation * 3 + i * 36);
            
            // 直接繪製一個圓形代替星星特效
            draw_set_color(c_yellow);
            draw_set_alpha(0.8);
            draw_circle(star_x, star_y, 5, false);
            draw_set_alpha(1.0);
            draw_set_color(c_white);
        }

        // 結束計時
        if (capture_animation >= 90) {
            finalize_capture();
        }
        break;

    case "failed":
        // 失敗畫面
        capture_animation += 1;

        // 紅色閃光效果
        draw_set_color(c_red);
        draw_set_alpha(max(0, 0.5 - capture_animation / 60));
        draw_rectangle(0, 0, gui_width, gui_height, false);
        draw_set_alpha(1);

        // 失敗文字
        if (capture_animation <= 60) {
            draw_text_safe(center_x, center_y, "捕獲失敗！", c_red, TEXT_ALIGN_CENTER, TEXT_VALIGN_MIDDLE);
        }

        // 結束計時
        if (capture_animation >= 90) {
            finalize_capture();
        }
        break;
}

// 如果有目標敵人，繪製敵人信息
if (target_enemy != noone && instance_exists(target_enemy)) {
    // 敵人精靈
    var enemy_sprite = object_get_sprite(target_enemy.object_index);
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