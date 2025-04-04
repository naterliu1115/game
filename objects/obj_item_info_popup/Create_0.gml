/// @description 初始化物品資訊彈窗

// 繼承父類事件
event_inherited();

// UI 基礎設置
layer_name = "popup";
accept_input = true;
allow_player_movement = true; // 允許玩家移動
allow_game_controls = true;   // 允許遊戲控制

// 彈窗尺寸
width = 300;
height = 400;
padding = 10;

// 設置UI位置（使用父類的變數）
ui_width = width;
ui_height = height;
ui_x = (display_get_gui_width() - width) / 2;
ui_y = (display_get_gui_height() - height) / 2;

// 物品資訊
item_data = noone;
title = "";
description = "";
rarity = "";
type = "";
icon_sprite = -1;
use_effect = "";
effect_value = 0;
stack_max = 0;
sell_price = 0;
tags = [];

// 字體設置
title_font = fnt_dialogue;
content_font = fnt_dialogue;

// 顏色設置
background_color = c_black;
background_alpha = 0.9;
border_color = c_white;
title_color = c_white;
content_color = c_ltgray;

// 稀有度顏色映射
rarity_colors = ds_map_create();
rarity_colors[? "COMMON"] = c_white;
rarity_colors[? "UNCOMMON"] = c_lime;
rarity_colors[? "RARE"] = c_aqua;
rarity_colors[? "EPIC"] = c_fuchsia;
rarity_colors[? "LEGENDARY"] = c_yellow;

// 效果文字描述映射
effect_descriptions = ds_map_create();
effect_descriptions[? "heal"] = "治療";
effect_descriptions[? "atk_boost"] = "攻擊力提升";
effect_descriptions[? "capture"] = "捕捉";
effect_descriptions[? "mining"] = "採礦";
effect_descriptions[? "none"] = "無";

// 設置物品數據
function setup_item_data(_item_data) {
    item_data = _item_data;
    title = item_data.Name;
    description = item_data.Description;
    rarity = item_data.Rarity;
    type = item_data.Type;
    icon_sprite = asset_get_index(item_data.IconSprite);
    use_effect = item_data.UseEffect;
    effect_value = item_data.EffectValue;
    stack_max = item_data.StackMax;
    sell_price = item_data.SellPrice;
    tags = item_data.Tags;
    
    if (global.game_debug_mode) {
        show_debug_message("物品資訊彈窗 - 設置物品數據：" + title);
    }
}

// 重寫父類的 show 方法
function show() {
    if (global.game_debug_mode) {
        show_debug_message("物品資訊彈窗 - show() 被調用");
    }
    
    // 調用父類的 show
    event_inherited();
    
    // 設置最上層深度
    depth = -200;  // 確保在最上層
}

// 重寫父類的 hide 方法
function hide() {
    if (global.game_debug_mode) {
        show_debug_message("物品資訊彈窗 - hide() 被調用");
    }
    
    // 調用父類的 hide
    event_inherited();
}

// 關閉彈窗
function close() {
    if (global.game_debug_mode) {
        show_debug_message("物品資訊彈窗 - close() 被調用");
    }
    
    // 先隱藏UI
    hide();
    
    // 清理資源
    if (ds_exists(rarity_colors, ds_type_map)) {
        ds_map_destroy(rarity_colors);
    }
    if (ds_exists(effect_descriptions, ds_type_map)) {
        ds_map_destroy(effect_descriptions);
    }
    
    // 最後銷毀實例
    instance_destroy();
} 