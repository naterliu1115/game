/// @description 繪製物品資訊彈窗

// 繪製背景
draw_set_alpha(background_alpha);
draw_set_color(c_black);
draw_rectangle(x, y, x + width, y + height, false);
draw_set_alpha(1);

// 繪製邊框
draw_set_color(border_color);
draw_rectangle(x, y, x + width, y + height, true);

// 設置字體
draw_set_font(title_font);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var current_y = y + padding;
var content_x = x + padding;
var icon_size = 96; // 使用與物品欄相同的尺寸
var icon_padding = 10; // 圖示和文字之間的間距
var section_spacing = 20; // 段落之間的間距

// 繪製物品圖示、外框和名稱
if (icon_sprite != -1 && sprite_exists(icon_sprite)) {
    // 計算縮放比例（確保圖示會填滿64x64的空間）
    var spr_width = sprite_get_width(icon_sprite);
    var spr_height = sprite_get_height(icon_sprite);
    var scale_x = icon_size / spr_width;
    var scale_y = icon_size / spr_height;
    
    // 計算繪製中心點座標
    var draw_center_x = content_x + icon_size / 2;
    var draw_center_y = current_y + icon_size / 2;
    
    // 繪製圖示，將精靈中心對準繪製中心點
    draw_sprite_ext(icon_sprite, 0, 
                   draw_center_x, 
                   draw_center_y, 
                   scale_x, scale_y, 0, c_white, 1);
    
    // 根據稀有度繪製外框
    var frame_color = rarity_colors[? rarity] ?? c_white;
    draw_set_color(frame_color);
    
    // 繪製2像素粗的外框
    for(var i = 0; i < 2; i++) {
        draw_rectangle(content_x - i, current_y - i, 
                      content_x + icon_size + i, current_y + icon_size + i, 
                      true);
    }
    
    // 根據稀有度設置標題顏色
    draw_set_color(frame_color);
    draw_text(content_x + icon_size + icon_padding, current_y + (icon_size - string_height(title)) / 2, title);
}

current_y += icon_size + section_spacing;

// 繪製稀有度和類型
draw_set_font(content_font);
draw_set_color(content_color);
draw_text(content_x, current_y, "類型: " + type);
current_y += string_height("類型") + 5;
draw_text(content_x, current_y, "稀有度: " + rarity);
current_y += string_height("稀有度") + section_spacing;

// 繪製描述
draw_text_ext(content_x, current_y, description, 20, width - (padding * 2));
current_y += string_height_ext(description, 20, width - (padding * 2)) + section_spacing;

// 繪製效果
if (use_effect != "none") {
    var effect_desc = effect_descriptions[? use_effect] ?? use_effect;
    draw_text(content_x, current_y, "效果: " + effect_desc);
    if (effect_value != 0) {
        var effect_text = "";
        if (use_effect == "heal") {
            effect_text = "+" + string(effect_value) + " HP";
        } else if (use_effect == "atk_boost") {
            effect_text = "+" + string(effect_value) + " ATK";
        } else {
            effect_text = string(effect_value);
        }
        draw_text(content_x + string_width("效果: " + effect_desc) + 10, current_y, effect_text);
    }
    current_y += string_height("效果") + section_spacing;
}

// 繪製其他屬性
draw_text(content_x, current_y, "最大堆疊: " + string(stack_max));
current_y += string_height("最大堆疊") + 5;
draw_text(content_x, current_y, "售價: " + string(sell_price) + "G");
current_y += string_height("售價") + section_spacing;

// 繪製標籤
if (array_length(tags) > 0) {
    draw_text(content_x, current_y, "標籤:");
    current_y += string_height("標籤") + 10;
    
    var tag_x = content_x;
    var tag_padding = 10;
    var tag_height = 20;
    
    for (var i = 0; i < array_length(tags); i++) {
        var tag = tags[i];
        var tag_width = string_width(tag) + tag_padding * 2;
        
        // 檢查是否需要換行
        if (tag_x + tag_width > x + width - padding) {
            tag_x = content_x;
            current_y += tag_height + 5;
        }
        
        // 繪製標籤背景
        draw_set_color(c_dkgray);
        draw_rectangle(tag_x, current_y, tag_x + tag_width, current_y + tag_height, false);
        
        // 繪製標籤文字
        draw_set_color(c_white);
        draw_text(tag_x + tag_padding, current_y + (tag_height - string_height(tag)) / 2, tag);
        
        tag_x += tag_width + 5;
    }
    current_y += tag_height + 5; // 確保 Y 座標更新
}

// --- 新增：繪製指派快捷按鈕 ---
assign_button_x = x + (width - assign_button_width) / 2; // 水平置中
assign_button_y = y + height - padding - assign_button_height; // 底部對齊

// 檢查是否可以指派 (例如，不是裝備)
var can_assign = true;
if (item_data != noone && item_data.Type == "EQUIPMENT") {
    can_assign = false;
}

if (can_assign) {
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    
    // 繪製按鈕背景
    draw_set_color(c_gray); // 或其他顏色
    draw_rectangle(assign_button_x, assign_button_y, 
                  assign_button_x + assign_button_width, assign_button_y + assign_button_height, false);
                  
    // 繪製按鈕文字
    draw_set_color(c_white);
    draw_text(assign_button_x + assign_button_width / 2, 
              assign_button_y + assign_button_height / 2, 
              assign_button_text);

    // 重設繪圖設定
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
} else {
    // 如果不能指派，可以選擇不畫按鈕或顯示灰色不可用狀態
}

// --- 重設最終繪圖設定 (如果需要) ---
draw_set_color(c_white);
draw_set_alpha(1); 