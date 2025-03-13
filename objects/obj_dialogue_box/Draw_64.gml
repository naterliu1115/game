draw_set_font(fnt_dialogue);

// 確保 npc 在使用前已被定義
var npc = noone;
if (instance_exists(obj_dialogue_manager) && obj_dialogue_manager.active) {
    npc = obj_dialogue_manager.current_npc;
}

if (instance_exists(obj_dialogue_manager) && obj_dialogue_manager.active) {
    if (obj_dialogue_manager.dialogue_index < array_length(obj_dialogue_manager.dialogue)) {
        var text = obj_dialogue_manager.dialogue[obj_dialogue_manager.dialogue_index];

        // 對話框最大寬度根據視窗大小動態調整
        var max_width = window_get_width() - 60; // 內縮 60px
        var final_width = clamp(string_width(text) + 60, 300, max_width);
        
        var box_x = window_get_width() / 2 - final_width / 2; // 置中
        var box_y = window_get_height() - 100; // 設置在畫面下方
        var box_height = 50; // 固定對話框高度
        
        // 检查surface是否需要更新或创建
        if (!surface_exists(dialogue_surface) || 
            surface_needs_update || 
            surface_width != final_width || 
            surface_height != box_height) {
            
            // 如果surface已存在但尺寸变化，先释放旧的
            if (surface_exists(dialogue_surface)) {
                surface_free(dialogue_surface);
            }
            
            // 创建新surface
            dialogue_surface = surface_create(final_width, box_height);
            surface_width = final_width;
            surface_height = box_height;
            
            // 在surface上绘制对话框
            surface_set_target(dialogue_surface);
            draw_clear_alpha(c_black, 0); // 清除surface内容，透明背景
            
            // 绘制对话框背景
            draw_sprite(spr_dialogue_left, 0, 0, 0);
            draw_sprite_stretched(spr_dialogue_middle, 0, 
                                 sprite_get_width(spr_dialogue_left), 0, 
                                 final_width - sprite_get_width(spr_dialogue_left) - sprite_get_width(spr_dialogue_right), 
                                 box_height);
            draw_sprite(spr_dialogue_right, 0, 
                       final_width - sprite_get_width(spr_dialogue_right), 0);
            
            // 绘制文本
            draw_set_color(c_white);
            draw_set_halign(fa_left);
            draw_set_valign(fa_middle);
            
            var text_y = box_height / 2;
            
            // 检查文本是否过长
            if (string_width(text) > final_width - 60) {
                // 截断文本
                var display_text = "";
                var char_count = 0;
                var total_width = 0;
                
                while (char_count < string_length(text)) {
                    char_count++;
                    var substr = string_copy(text, 1, char_count);
                    total_width = string_width(substr);
                    
                    if (total_width > final_width - 80) {
                        display_text = string_copy(text, 1, char_count - 3) + "...";
                        break;
                    }
                }
                
                draw_text(30, text_y, display_text);
                
                // 添加"下一页"提示
                var indicator_x = final_width - 30;
                draw_text(indicator_x, text_y, "▼");
            } else {
                // 正常显示文本
                draw_text(30, text_y, text);
            }
            
            // 如果这是对话的最后一条，添加完成指示
            if (obj_dialogue_manager.dialogue_index == array_length(obj_dialogue_manager.dialogue) - 1) {
                var end_indicator_x = final_width - 30;
                draw_text(end_indicator_x, text_y, "✓");
            }
            
            surface_reset_target();
            surface_needs_update = false;
        }
        
        // 绘制surface到屏幕
        draw_surface(dialogue_surface, box_x, box_y);
    }
}

// 检查surface是否需要在下一帧更新
if (instance_exists(obj_dialogue_manager) && obj_dialogue_manager.dialogue_box_needs_update) {
    surface_needs_update = true;
    obj_dialogue_manager.dialogue_box_needs_update = false;
}