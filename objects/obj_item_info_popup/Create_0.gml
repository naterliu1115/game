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
inventory_index = -1; // 新增：儲存物品在背包中的索引
is_assigned_to_hotbar = false; // <-- 新增: 追蹤是否已指派
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

// 新增：按鈕相關變數
assign_button_text = "指派快捷";
unassign_button_text = "取消指派"; // <-- 新增
assign_color = make_color_rgb(60, 180, 75); // <-- 新增 (綠色)
unassign_color = make_color_rgb(230, 25, 75); // <-- 新增 (紅色)
assign_button_height = 30;
assign_button_width = 100;
assign_button_x = 0; // 會在 Draw 事件中計算
assign_button_y = 0; // 會在 Draw 事件中計算

// 設置物品數據
function setup_item_data(_item_data, _inventory_index) {
    item_data = _item_data;
    inventory_index = _inventory_index; // 儲存索引
    
    // 檢查 _item_data 是否有效
    if (_item_data == noone || !is_struct(_item_data)) {
        show_debug_message("錯誤：無效的 item_data 傳入 setup_item_data");
        title = "錯誤";
        description = "無法載入物品資訊";
        return;
    }
    
    title = _item_data.Name;
    description = _item_data.Description;
    rarity = _item_data.Rarity;
    type = _item_data.Type;
    icon_sprite = asset_get_index(_item_data.IconSprite);
    use_effect = _item_data.UseEffect;
    effect_value = _item_data.EffectValue;
    stack_max = _item_data.StackMax;
    sell_price = _item_data.SellPrice;
    tags = _item_data.Tags;
    
    // <-- 修改: 加入更詳細的檢查 -->
    show_debug_message("setup_item_data: 檢查物品管理器和快捷欄狀態...");
    is_assigned_to_hotbar = false; // 先預設為 false

    if (instance_exists(obj_item_manager)) {
        show_debug_message("  - obj_item_manager 實例存在。");

        // 獲取實例 ID，避免直接使用對象索引
        var item_manager_inst = instance_find(obj_item_manager, 0);

        // 檢查函數是否存在於該實例上
        if (variable_instance_exists(item_manager_inst, "get_hotbar_slot_for_item")) {
             show_debug_message("  - get_hotbar_slot_for_item 函數存在。");
             var assigned_slot = item_manager_inst.get_hotbar_slot_for_item(_inventory_index);
             is_assigned_to_hotbar = (assigned_slot != -1);
             if (global.game_debug_mode) {
                 show_debug_message("  - 物品索引 " + string(_inventory_index) + " 指派狀態: " + string(is_assigned_to_hotbar) + (is_assigned_to_hotbar ? " (欄位 " + string(assigned_slot) + ")" : ""));
             }
        } else {
            show_debug_message("  - 錯誤：obj_item_manager 實例上找不到 get_hotbar_slot_for_item 函數！");
        }

    } else {
        show_debug_message("  - 錯誤：obj_item_manager 實例不存在！無法檢查快捷欄指派狀態。");
    }
    // <-- 結束修改 -->

    if (global.game_debug_mode) {
        show_debug_message("物品資訊彈窗 - 設置物品數據完成：" + title + " (索引: " + string(inventory_index) + ")");
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
    // depth = -200;  // <<-- 移除或註解掉這行，讓 UI 管理器決定深度
}

// 重寫父類的 hide 方法
function hide() {
    if (global.game_debug_mode) {
        show_debug_message("物品資訊彈窗 - hide() 被調用（只設狀態，不呼叫父類）");
    }
    visible = false;
    active = false;
    last_active_state = false;
    // 不再呼叫 event_inherited() 或 parent_ui.hide
}

// 關閉彈窗
function close() {
    if (global.game_debug_mode) {
        show_debug_message("物品資訊彈窗 - close() 被調用（只釋放資源與銷毀，不呼叫 hide/parent_ui）");
    }
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