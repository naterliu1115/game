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
    if (!variable_global_exists("player_inventory")) {
        global.player_inventory = ds_list_create();
    }
    
    if (ds_list_size(global.player_inventory) == 0) {
        show_debug_message("物品列表為空，添加測試物品");
        
        with (obj_item_manager) {
            // 消耗品
            add_item_to_inventory(1001, 5);  // 小型回復藥水
            add_item_to_inventory(1002, 3);  // 中型回復藥水
            add_item_to_inventory(1003, 1);  // 大型回復藥水
            
            // 裝備
            add_item_to_inventory(2001, 1);  // 銅劍
            add_item_to_inventory(2002, 1);  // 鐵劍
            
            // 捕捉道具
            add_item_to_inventory(3001, 10); // 普通球
            add_item_to_inventory(3002, 5);  // 高級球
            
            // 材料
            add_item_to_inventory(4001, 20); // 銅礦石
            add_item_to_inventory(4002, 10); // 鐵礦石
            
            // 工具
            add_item_to_inventory(5001, 1);  // 採礦稿
        }
    }
    
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
    
    // 計算相對於物品欄起始位置的偏移
    var rel_x = mouse_x - inventory_start_x;
    var rel_y = mouse_y - inventory_start_y + scroll_offset;
    
    // 檢查是否在物品欄範圍內
    if (rel_x < 0 || rel_x >= slots_per_row * (slot_size + slot_padding)) return noone;
    if (rel_y < 0) return noone;
    
    // 計算槽位索引
    var slot_x = floor(rel_x / (slot_size + slot_padding));
    var slot_y = floor(rel_y / (slot_size + slot_padding));
    var slot_index = slot_y * slots_per_row + slot_x;
    
    // 檢查是否是有效的槽位
    if (slot_index >= ds_list_size(global.player_inventory)) return noone;
    
    return slot_index;
};

// 使用物品
use_selected_item = function() {
    if (selected_item == noone) return;
    
    var item = global.player_inventory[| selected_item];
    if (item == undefined) return;
    
    // 檢查是否可以使用該物品
    var item_data = obj_item_manager.get_item(item.id);
    if (item_data == undefined) return;
    
    // 只有消耗品可以直接使用
    if (item_data.type == ITEM_TYPE.CONSUMABLE) {
        if (obj_item_manager.use_item(item.id)) {
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
    var total_items = ds_list_size(global.player_inventory);
    var rows = ceil(total_items / slots_per_row);
    var visible_rows = floor((ui_height - 100) / (slot_size + slot_padding));
    max_scroll = max(0, (rows - visible_rows) * (slot_size + slot_padding));
    
    show_debug_message("更新滾動值：" + string(max_scroll));
}; 