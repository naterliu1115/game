// obj_inventory_ui - Create_0.gml

// 繼承父類事件
event_inherited();

// UI 基本設置
visible = false;
active = false;

// 檢查必要的系統依賴
var systems_ready = true;
var missing_systems = "";

// 檢查UI管理器
if (!instance_exists(obj_ui_manager)) {
    systems_ready = false;
    missing_systems += "UI管理器、";
}

// 檢查事件管理器
if (!instance_exists(obj_event_manager)) {
    systems_ready = false;
    missing_systems += "事件管理器、";
}

// 檢查物品管理器
if (!instance_exists(obj_item_manager)) {
    systems_ready = false;
    missing_systems += "物品管理器、";
}

if (!systems_ready) {
    missing_systems = string_delete(missing_systems, string_length(missing_systems), 1);
    show_debug_message("錯誤：道具UI初始化失敗，缺少必要系統：" + missing_systems);
    instance_destroy();
    exit;
}

// 訂閱事件
with (obj_event_manager) {
    subscribe_to_event("item_added", other.id, "on_item_added");
    subscribe_to_event("item_removed", other.id, "on_item_removed");
    subscribe_to_event("item_used", other.id, "on_item_used");
}

// 事件處理函數
on_item_added = function(data) {
    surface_needs_update = true;
    show_debug_message("物品已添加，更新UI");
};

on_item_removed = function(data) {
    surface_needs_update = true;
    show_debug_message("物品已移除，更新UI");
};

on_item_used = function(data) {
    surface_needs_update = true;
    show_debug_message("物品已使用，更新UI");
};

// 確保在UI管理器中註冊
with (obj_ui_manager) {
    register_ui(other.id, "main");
}

// UI 尺寸和位置
ui_width = display_get_gui_width() * 0.8;
ui_height = display_get_gui_height() * 0.8;
ui_x = (display_get_gui_width() - ui_width) / 2;
ui_y = (display_get_gui_height() - ui_height) / 2;

// 創建表面
ui_surface = -1;
surface_needs_update = true;

// 物品欄設置
slots_per_row = 8;
slot_size = 64;
slot_padding = 10;
inventory_start_x = ui_x + 20;
inventory_start_y = ui_y + 60;

// 分類標籤
current_category = 0;  // 默認顯示消耗品分類
category_buttons = [
    {name: "消耗品", category: 0},
    {name: "裝備", category: 1},
    {name: "捕捉道具", category: 2},
    {name: "材料", category: 3},
    {name: "工具", category: 4}
];

// 選中的物品
selected_item = noone;
hover_item = noone;
drag_item = noone;
drag_offset_x = 0;
drag_offset_y = 0;

// 滾動設置
scroll_offset = 0;
max_scroll = 0;

// 重寫顯示UI方法
show = function() {
    // 再次檢查系統依賴
    if (!instance_exists(obj_event_manager) || 
        !instance_exists(obj_item_manager) || 
        !instance_exists(obj_ui_manager)) {
        show_debug_message("錯誤：無法顯示道具UI，缺少必要系統");
        return;
    }
    
    visible = true;
    active = true;
    surface_needs_update = true;
    allow_player_movement = false;  // 明確設置不允許玩家移動
    
    // 重置選擇狀態
    selected_item = noone;
    hover_item = noone;
    drag_item = noone;
    scroll_offset = 0;
    
    // 更新最大滾動值
    update_max_scroll();
    
    // 檢查物品列表是否為空，如果為空添加測試物品
    // [已移除] UI 不再自動加測試道具，背包初始化由 game_controller 負責
    
    show_debug_message("道具UI已顯示");
};

// 重寫隱藏UI方法
hide = function() {
    visible = false;
    active = false;
    allow_player_movement = true;  // 確保在隱藏UI時重置移動控制
    
    // 清理表面
    if (surface_exists(ui_surface)) {
        surface_free(ui_surface);
        ui_surface = -1;
    }
    
    show_debug_message("道具UI已隱藏，允許玩家移動");
};

// 獲取指定位置的物品槽
get_slot_at_position = function(mouse_x, mouse_y) {
    if (!active) return noone;
    
    // 計算相對於UI左上角的點擊位置 (表面座標系)
    var cx = mouse_x - ui_x;
    var cy = mouse_y - ui_y;
    
    // 調試輸出點擊位置 (表面座標系)
    if (global.game_debug_mode) {
        show_debug_message("原始點擊位置：" + string(mouse_x) + ", " + string(mouse_y));
        show_debug_message("UI起始位置：" + string(ui_x) + ", " + string(ui_y));
        show_debug_message("點擊相對UI位置（表面座標）：" + string(cx) + ", " + string(cy));
    }
    
    // 計算物品槽區域的起始Y座標 (與Draw_64一致)
    var buttons_y = 60;
    var button_height = 40; // 從Draw_64參考，或應定義為變數
    var slots_area_y = buttons_y + button_height + 10;
    
    var items_drawn = 0;
    for (var i = 0; i < ds_list_size(global.player_inventory); i++) {
        var item = global.player_inventory[| i];
        if (item != undefined) {
            var item_data = obj_item_manager.get_item(item.item_id);
            if (item_data != undefined) {
                var item_category = -1;
                if (variable_struct_exists(item_data, "Category")) {
                    item_category = real(item_data.Category);
                }
                
                if (item_category == real(current_category)) {
                    // 計算這個物品在UI表面上的實際繪製位置 (與Draw_64一致)
                    var slot_draw_x = 20 + (items_drawn mod slots_per_row) * (slot_size + slot_padding);
                    var slot_draw_y = slots_area_y - scroll_offset + floor(items_drawn / slots_per_row) * (slot_size + slot_padding);
                    
                    // 調試輸出每個槽位的計算位置
                    if (global.game_debug_mode) {
                        show_debug_message("檢查物品 " + string(i) + ": ID " + string(item.item_id) + " (" + item_data.Name + ")");
                        show_debug_message("    預計繪製位置（表面座標）：" + string(slot_draw_x) + ", " + string(slot_draw_y));
                        show_debug_message("    槽位大小：" + string(slot_size));
                    }
                    
                    // 使用表面座標檢查點擊是否在這個槽位的繪製範圍內
                    if (point_in_rectangle(cx, cy,
                        slot_draw_x, slot_draw_y,
                        slot_draw_x + slot_size, slot_draw_y + slot_size)) {
                        
                        if (global.game_debug_mode) {
                            show_debug_message("--> 點擊命中物品 " + string(i));
                        }
                        // 移除過時的調試輸出
                        //ds_list_destroy(valid_slots); // valid_slots 未被使用，可以移除
                        return i;
                    }
                    
                    items_drawn++;
                }
            }
        }
    }
    
    if (global.game_debug_mode) {
        show_debug_message("點擊未命中任何物品");
    }
    
    //ds_list_destroy(valid_slots); // valid_slots 未被使用，可以移除
    return noone;
};

// 使用物品
use_selected_item = function() {
    if (selected_item == noone) return;
    
    var item = global.player_inventory[| selected_item];
    if (item == undefined) return;
    
    // 檢查是否可以使用該物品
    var item_data = obj_item_manager.get_item(item.item_id);
    if (item_data == undefined) return;
    
    // 只有消耗品可以直接使用
    if (item_data.type == ITEM_TYPE.CONSUMABLE) {
        if (obj_item_manager.use_item(item.item_id)) {
            // 使用成功，更新UI
            surface_needs_update = true;
            
            // 如果物品用完了，取消選擇
            if (item.quantity <= 0) {
                selected_item = noone;
            }
            
            show_debug_message("物品使用成功：" + item_data.name);
        }
    }
};

// 更新最大滾動值
update_max_scroll = function() {
    // 計算當前分類的物品數量
    var items_in_category = 0;
    for (var i = 0; i < ds_list_size(global.player_inventory); i++) {
        var item = global.player_inventory[| i];
        if (item != undefined) {
            var item_data = obj_item_manager.get_item(item.item_id);
            if (item_data != undefined) {
                if (variable_struct_exists(item_data, "Category")) {
                    if (item_data.Category == current_category) {
                        items_in_category++;
                    }
                }
            }
        }
    }
    
    var rows = ceil(items_in_category / slots_per_row);
    var visible_rows = floor((ui_height - 100) / (slot_size + slot_padding));
    max_scroll = max(0, (rows - visible_rows) * (slot_size + slot_padding));
    
    if (global.game_debug_mode) {
        show_debug_message("更新滾動值：");
        show_debug_message("當前分類物品數: " + string(items_in_category));
        show_debug_message("最大滾動值: " + string(max_scroll));
    }
};

// 物品資訊彈窗函數
function show_item_info(item_data, inventory_index, mouse_x, mouse_y) {
    if (global.game_debug_mode) {
        show_debug_message("嘗試顯示物品資訊：" + item_data.Name + " (索引: " + string(inventory_index) + ")");
    }
    
    // 先清理現有彈窗
    with(obj_item_info_popup) {
        close();
    }
    
    // 創建新的彈窗實例
    var popup = instance_create_layer(0, 0, "UI", obj_item_info_popup);
    if (popup != noone) {
        // 設置物品資訊，包含索引
        popup.setup_item_data(item_data, inventory_index);
        
        // 計算彈窗位置
        // 預設在點擊位置右側20像素處
        var preferred_x = mouse_x + 20;
        var preferred_y = mouse_y;
        
        // 確保不會超出螢幕右側
        if (preferred_x + popup.width > display_get_gui_width()) {
            // 如果右側放不下，就放在左側
            preferred_x = mouse_x - popup.width - 20;
        }
        
        // 確保不會超出螢幕底部
        if (preferred_y + popup.height > display_get_gui_height()) {
            preferred_y = display_get_gui_height() - popup.height;
        }
        
        // 確保不會超出螢幕頂部
        preferred_y = max(0, preferred_y);
        
        // 設置彈窗位置
        popup.x = preferred_x;
        popup.y = preferred_y;
        popup.ui_x = preferred_x;
        popup.ui_y = preferred_y;
        
        // 註冊到UI管理器
        if (instance_exists(obj_ui_manager)) {
            obj_ui_manager.register_ui(popup, "popup");
            obj_ui_manager.show_ui(popup, "popup");
        }
        
        if (global.game_debug_mode) {
            show_debug_message("物品資訊彈窗已創建：" + string(popup));
            show_debug_message("位置：" + string(popup.x) + ", " + string(popup.y));
        }
    } else {
        show_debug_message("錯誤：無法創建物品資訊彈窗");
    }
} 