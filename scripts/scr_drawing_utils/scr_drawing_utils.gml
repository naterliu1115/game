/************************************************************************
 * 檔案: scr_drawing_utils.gml
 * 描述: 通用繪圖輔助函數集合
 * 功能: 提供安全的繪圖函數，處理資源缺失和保持繪圖狀態一致性
 ************************************************************************/

// 定義自己的對齊常數，避免使用 GameMaker 的內建常數
#macro TEXT_ALIGN_LEFT 0
#macro TEXT_ALIGN_CENTER 1
#macro TEXT_ALIGN_RIGHT 2
#macro TEXT_VALIGN_TOP 0
#macro TEXT_VALIGN_MIDDLE 1
#macro TEXT_VALIGN_BOTTOM 2

// 文字繪製相關函數
#region TEXT DRAWING FUNCTIONS

/// @function draw_text_safe(x, y, text, color, halign, valign)
/// @description 安全地繪製文字，並在繪製後還原繪圖狀態
/// @param {real} x X 座標
/// @param {real} y Y 座標
/// @param {string} text 要顯示的文字
/// @param {real} color 文字顏色 (預設為白色)
/// @param {real} halign 水平對齊方式 (預設為左對齊)
/// @param {real} valign 垂直對齊方式 (預設為頂部對齊)
function draw_text_safe(x, y, text, color = c_white, halign = TEXT_ALIGN_LEFT, valign = TEXT_VALIGN_TOP) {
    var original_color = draw_get_color();
    var original_halign = draw_get_halign();
    var original_valign = draw_get_valign();
    
    draw_set_color(color);
    
    // 將自定義的對齊常量映射到 GameMaker 的內建常量
    var gm_halign = fa_left;
    if (halign == TEXT_ALIGN_CENTER) gm_halign = fa_center;
    else if (halign == TEXT_ALIGN_RIGHT) gm_halign = fa_right;
    
    var gm_valign = fa_top;
    if (valign == TEXT_VALIGN_MIDDLE) gm_valign = fa_middle;
    else if (valign == TEXT_VALIGN_BOTTOM) gm_valign = fa_bottom;
    
    draw_set_halign(gm_halign);
    draw_set_valign(gm_valign);
    
    draw_text(x, y, string(text));
    
    draw_set_color(original_color);
    draw_set_halign(original_halign);
    draw_set_valign(original_valign);
}

/// @function draw_text_outlined(x, y, text, text_color, outline_color, halign, valign, scale)
/// @description 繪製帶輪廓的文字，支援縮放
/// @param {real} x X 座標
/// @param {real} y Y 座標
/// @param {string} text 要顯示的文字
/// @param {real} text_color 文字顏色
/// @param {real} outline_color 輪廓顏色
/// @param {real} halign 水平對齊方式 (預設為左對齊)
/// @param {real} valign 垂直對齊方式 (預設為頂部對齊)
/// @param {real} scale 縮放比例 (預設為 1)
function draw_text_outlined(x, y, text, text_color = c_white, outline_color = c_black, halign = TEXT_ALIGN_LEFT, valign = TEXT_VALIGN_TOP, scale = 1) {
    var original_color = draw_get_color();
    var original_halign = draw_get_halign();
    var original_valign = draw_get_valign();
    
    // 將自定義的對齊常量映射到 GameMaker 的內建常量
    var gm_halign = fa_left;
    if (halign == TEXT_ALIGN_CENTER) gm_halign = fa_center;
    else if (halign == TEXT_ALIGN_RIGHT) gm_halign = fa_right;
    
    var gm_valign = fa_top;
    if (valign == TEXT_VALIGN_MIDDLE) gm_valign = fa_middle;
    else if (valign == TEXT_VALIGN_BOTTOM) gm_valign = fa_bottom;
    
    draw_set_halign(gm_halign);
    draw_set_valign(gm_valign);
    
    // 繪製輪廓
    draw_set_color(outline_color);
    draw_text_transformed(x+1, y+1, string(text), scale, scale, 0);
    draw_text_transformed(x-1, y-1, string(text), scale, scale, 0);
    draw_text_transformed(x+1, y-1, string(text), scale, scale, 0);
    draw_text_transformed(x-1, y+1, string(text), scale, scale, 0);
    
    // 繪製主要文字
    draw_set_color(text_color);
    draw_text_transformed(x, y, string(text), scale, scale, 0);
    
    // 恢復原始設置
    draw_set_color(original_color);
    draw_set_halign(original_halign);
    draw_set_valign(original_valign);
}

#endregion

// 精靈繪製相關函數
#region SPRITE DRAWING FUNCTIONS

/// @function draw_sprite_safe(sprite_id, subimg, x, y, xscale, yscale, rot, col, alpha)
/// @description 安全地繪製精靈，如果精靈不存在則繪製替代圖形
/// @param {Asset.GMSprite} sprite_id 精靈的索引或名稱
/// @param {real} subimg 子圖像索引
/// @param {real} x X座標
/// @param {real} y Y座標
/// @param {real} xscale X縮放
/// @param {real} yscale Y縮放
/// @param {real} rot 旋轉角度
/// @param {real} col 顏色
/// @param {real} alpha 透明度
function draw_sprite_safe(sprite_id, subimg, x, y, xscale = 1, yscale = 1, rot = 0, col = c_white, alpha = 1) {
    // 檢查精靈是否有效
    if (sprite_exists(sprite_id)) {
        draw_sprite_ext(sprite_id, subimg, x, y, xscale, yscale, rot, col, alpha);
        return true;
    } else {
        // 繪製替代圖形
        var original_color = draw_get_color();
        var original_alpha = draw_get_alpha();
        
        draw_set_color(col);
        draw_set_alpha(alpha);
        
        // 繪製簡單的替代形狀
        var size = 5 * max(xscale, yscale);
        draw_rectangle(x - size, y - size, x + size, y + size, false);
        draw_set_color(c_black);
        draw_line(x - size, y - size, x + size, y + size);
        draw_line(x - size, y + size, x + size, y - size);
        
        // 恢復原始繪圖設置
        draw_set_color(original_color);
        draw_set_alpha(original_alpha);
        
        // 如果是調試模式，顯示缺失資源警告
        if (variable_global_exists("game_debug_mode") && global.game_debug_mode) {
            draw_text(x, y + 15, "缺: " + string(sprite_id));
        }
        
        return false;
    }
}

#endregion

// UI 元素繪製函數
#region UI ELEMENT FUNCTIONS

/// @function draw_ui_panel(x, y, width, height, title, show_title)
/// @description 繪製一個UI面板
/// @param {real} x 面板左上角X座標
/// @param {real} y 面板左上角Y座標
/// @param {real} width 面板寬度
/// @param {real} height 面板高度
/// @param {string} title 面板標題
/// @param {bool} show_title 是否顯示標題欄
function draw_ui_panel(x, y, width, height, title, show_title) {
    var bg_color = make_color_rgb(40, 40, 40);
    var frame_color = make_color_rgb(60, 60, 60);
    var text_color = c_white;
    
    // 繪製背景
    draw_set_alpha(0.9);
    draw_rectangle_color(x, y, x + width, y + height,
        bg_color, bg_color, bg_color, bg_color, false);
    
    // 繪製邊框
    draw_set_alpha(1);
    draw_rectangle_color(x, y, x + width, y + height,
        frame_color, frame_color, frame_color, frame_color, true);
    
    // 繪製標題欄
    if (show_title) {
        var title_height = 40;
        draw_rectangle_color(x, y, x + width, y + title_height,
            frame_color, frame_color, frame_color, frame_color, false);
        
        draw_text_safe(x + 20, y + title_height/2, title, text_color,
            TEXT_ALIGN_LEFT, TEXT_VALIGN_MIDDLE);
    }
}

/// @function draw_ui_button(x, y, width, height, text, is_selected)
/// @description 繪製一個UI按鈕
/// @param {real} x 按鈕左上角X座標
/// @param {real} y 按鈕左上角Y座標
/// @param {real} width 按鈕寬度
/// @param {real} height 按鈕高度
/// @param {string} text 按鈕文字
/// @param {bool} is_selected 是否被選中
function draw_ui_button(x, y, width, height, text, is_selected = false) {
    var bg_color = is_selected ? make_color_rgb(80, 80, 80) : make_color_rgb(60, 60, 60);
    var frame_color = is_selected ? c_white : make_color_rgb(60, 60, 60);
    var text_color = c_white;
    
    // 繪製按鈕背景
    draw_rectangle_color(x, y, x + width, y + height,
        bg_color, bg_color, bg_color, bg_color, false);
    
    // 繪製按鈕邊框
    draw_rectangle_color(x, y, x + width, y + height,
        frame_color, frame_color, frame_color, frame_color, true);
    
    // 繪製按鈕文字
    draw_text_safe(x + width/2, y + height/2, text, text_color,
        TEXT_ALIGN_CENTER, TEXT_VALIGN_MIDDLE);
}

/// @function draw_ui_item_slot(x, y, width, height, item_data, quantity, is_selected)
/// @description 繪製一個物品槽
/// @param {real} x 槽位左上角X座標
/// @param {real} y 槽位左上角Y座標
/// @param {real} width 槽位寬度
/// @param {real} height 槽位高度
/// @param {struct} item_data 物品數據
/// @param {real} quantity 物品數量
/// @param {bool} is_selected 是否被選中
function draw_ui_item_slot(x, y, width, height, item_data, quantity, is_selected) {
    var slot_color = make_color_rgb(60, 60, 60);
    var frame_color = is_selected ? c_white : make_color_rgb(60, 60, 60);
    var text_color = c_white;
    
    // 繪製槽位背景
    draw_rectangle_color(x, y, x + width, y + height,
        slot_color, slot_color, slot_color, slot_color, false);
    
    // 繪製物品圖示
    var sprite = asset_get_index(item_data.IconSprite);
    if (sprite_exists(sprite)) {
        draw_sprite_stretched(sprite, 0,
            x + 4, y + 4,
            width - 8, height - 8);
    }
    
    // 繪製數量
    if (quantity > 1) {
        draw_text_safe(x + width - 4, y + height - 4,
            string(quantity), text_color,
            TEXT_ALIGN_RIGHT, TEXT_VALIGN_BOTTOM);
    }
    
    // 繪製選中框
    if (is_selected) {
        draw_rectangle_color(x, y, x + width, y + height,
            frame_color, frame_color, frame_color, frame_color, true);
    }
}

/// @function draw_ui_dragged_item(x, y, size, item_data)
/// @description 繪製正在拖動的物品
/// @param {real} x 物品左上角X座標
/// @param {real} y 物品左上角Y座標
/// @param {real} size 物品大小
/// @param {struct} item_data 物品數據
function draw_ui_dragged_item(x, y, size, item_data) {
    var sprite = asset_get_index(item_data.IconSprite);
    if (sprite_exists(sprite)) {
        draw_sprite_ext(sprite, 0,
            x, y, size/sprite_get_width(sprite), size/sprite_get_height(sprite),
            0, c_white, 0.7);
    }
}

/// @function draw_progress_bar(x, y, width, height, value, max_value, colors, show_text)
/// @description 繪製進度條
/// @param {real} x 進度條左上角X座標
/// @param {real} y 進度條左上角Y座標
/// @param {real} width 進度條寬度
/// @param {real} height 進度條高度
/// @param {real} value 當前值
/// @param {real} max_value 最大值
/// @param {array} colors 進度條顏色陣列 [背景色, 填充色, 邊框色, 文字色]
/// @param {bool} show_text 是否顯示進度文字
function draw_progress_bar(x, y, width, height, value, max_value, colors = [c_dkgray, c_green, c_white, c_white], show_text = true) {
    // 確保顏色是實數類型
    var bg_color = colors[0];
    var fill_color = colors[1];
    var border_color = colors[2];
    var text_color = colors[3];
    
    var progress = clamp(value / max_value, 0, 1);
    var fill_width = width * progress;
    
    // 繪製背景
    draw_set_color(bg_color);
    draw_rectangle(x, y, x + width, y + height, false);
    
    // 繪製填充部分
    draw_set_color(fill_color);
    if (fill_width > 0) {
        draw_rectangle(x, y, x + fill_width, y + height, false);
    }
    
    // 繪製邊框
    draw_set_color(border_color);
    draw_rectangle(x, y, x + width, y + height, true);
    
    // 顯示進度文字
    if (show_text) {
        var percent_text = string(round(progress * 100)) + "%";
        draw_text_safe(
            x + width / 2,
            y + height / 2,
            percent_text,
            text_color,
            TEXT_ALIGN_CENTER,
            TEXT_VALIGN_MIDDLE
        );
    }
}

/// @function check_button_pressed(x, y, width, height)
/// @description 檢查按鈕是否被點擊
/// @param {real} x 按鈕左上角X座標
/// @param {real} y 按鈕左上角Y座標
/// @param {real} width 按鈕寬度
/// @param {real} height 按鈕高度
/// @returns {bool} 如果按鈕被點擊則返回 true
function check_button_pressed(x, y, width, height) {
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    
    return point_in_rectangle(mx, my, x, y, x + width, y + height) && mouse_check_button_pressed(mb_left);
}

#endregion

/// @function color_to_real(color)
/// @description 将颜色常量转换为实数值
/// @param {constant.color} color 颜色常量
/// @returns {real} 转换后的实数值
function color_to_real(color) {
    return real(color);
}


// 初始化
#region INITIALIZATION

/// @function init_drawing_utils()
/// @description 初始化繪圖工具，創建所需的全局資源
function init_drawing_utils() {
    // 檢查是否已經初始化
    if (!variable_global_exists("resource_map")) {
        global.resource_map = ds_map_create();
        show_debug_message("繪圖工具初始化完成");
    }
}

// 自動初始化
init_drawing_utils();

#endregion