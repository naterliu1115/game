/// @description 初始化道具管理器

// 注意：已禁用GameMaker的"Remove Unused Resources"選項，不再需要手動引用精靈

// 物品類型枚舉
enum ITEM_TYPE {
    CONSUMABLE,
    EQUIPMENT,
    CAPTURE,
    MATERIAL
}

enum ITEM_RARITY {
    COMMON = 0,
    UNCOMMON,
    RARE,
    EPIC,
    LEGENDARY
}

// 初始化數據結構
items_data = ds_map_create();
item_sprites = ds_map_create();

// 預加載 spr_gold 作為預設精靈
var default_sprite = asset_get_index("spr_gold");
if (default_sprite != -1 && sprite_exists(default_sprite)) {
    item_sprites[? "spr_gold"] = default_sprite;
    show_debug_message("預設精靈 spr_gold 已加載到緩存");
} else {
    show_debug_message("警告：預設精靈 spr_gold 無法加載");
}

// 數據驗證函數
function validate_item_data(item_data) {
    // 檢查必要欄位
    var required_fields = ["ID", "Name", "Type", "Description", "Rarity", "IconSprite",
                          "UseEffect", "EffectValue", "StackMax", "SellPrice", "Tags", "Category"];

    for (var i = 0; i < array_length(required_fields); i++) {
        if (!variable_struct_exists(item_data, required_fields[i])) {
            show_debug_message("錯誤：道具缺少必要欄位 " + required_fields[i]);
            return false;
        }
    }

    // 驗證Category
    if (!is_real(item_data.Category) || item_data.Category < 0 || item_data.Category > 4) {
        show_debug_message("錯誤：無效的物品分類 " + string(item_data.Category));
        return false;
    }

    // 驗證精靈資源是否存在

    // 嘗試直接加載精靈
    var icon_index = asset_get_index(item_data.IconSprite);
    if (icon_index != -1 && sprite_exists(icon_index)) {
        // 將精靈添加到緩存中
        item_sprites[? item_data.IconSprite] = icon_index;
        return true;
    }

    // 如果精靈無效，使用預設精靈 spr_gold
    show_debug_message("警告：找不到道具圖示 " + item_data.IconSprite + "，使用預設精靈 spr_gold");
    item_data.IconSprite = "spr_gold";

    // 確保 spr_gold 在緩存中
    if (!ds_map_exists(item_sprites, "spr_gold")) {
        var default_sprite = asset_get_index("spr_gold");
        if (default_sprite != -1 && sprite_exists(default_sprite)) {
            item_sprites[? "spr_gold"] = default_sprite;
        } else {
            show_debug_message("嚴重錯誤：預設精靈 spr_gold 也無效！");
            return false;
        }
    }

    return true;
}

// 輔助函數：分割字符串
function custom_string_split(str, delimiter) {
    var result = [];
    var pos = string_pos(delimiter, str);

    while (pos > 0) {
        array_push(result, string_copy(str, 1, pos - 1));
        str = string_delete(str, 1, pos);
        pos = string_pos(delimiter, str);
    }

    if (string_length(str) > 0) {
        array_push(result, str);
    }

    return result;
}

// 從CSV創建物品數據結構
function create_item_from_csv_row(grid, row) {
    var item = {
        ID: real(grid[# 0, row]),
        Name: grid[# 1, row],
        Type: grid[# 2, row],
        Description: grid[# 3, row],
        Rarity: grid[# 4, row],
        IconSprite: grid[# 5, row],
        UseEffect: grid[# 6, row],
        EffectValue: real(grid[# 7, row]),
        StackMax: real(grid[# 8, row]),
        SellPrice: real(grid[# 9, row]),
        Tags: custom_string_split(grid[# 10, row], ";"),
        Category: real(grid[# 11, row])
    };

    // 物品創建完成

    return item;
}

// 載入物品數據
function load_items_data() {
    show_debug_message("===== 開始載入物品數據 =====");

    var file = "items_data.csv";
    show_debug_message("嘗試讀取文件: " + file);

    var grid = load_csv(file);
    if (grid == -1) {
        show_debug_message("錯誤：無法載入物品數據文件");
        return false;
    }

    var width = ds_grid_width(grid);
    var height = ds_grid_height(grid);
    show_debug_message("CSV 網格大小: " + string(width) + "x" + string(height));

    // 從第二行開始讀取（跳過標題行）
    var items_loaded = 0;
    for (var i = 1; i < height; i++) {
        // 創建物品數據結構
        var item_data = create_item_from_csv_row(grid, i);

        // 檢查圖示精靈

        // 驗證物品數據
        if (validate_item_data(item_data)) {
            // 添加到數據庫
            items_data[? item_data.ID] = item_data;
            items_loaded++;
        } else {
            show_debug_message("警告：物品數據驗證失敗，跳過該物品：" + string(item_data.ID));
        }
    }

    // 清理網格
    ds_grid_destroy(grid);

    show_debug_message("物品數據載入完成，成功載入 " + string(items_loaded) + " 個物品");
    show_debug_message("物品數據庫大小：" + string(ds_map_size(items_data)));
    show_debug_message("===== 物品數據載入結束 =====");

    return true;
}

// 獲取物品數據
function get_item(item_id) {
    if (ds_map_exists(items_data, item_id)) {
        return items_data[? item_id];
    }
    show_debug_message("警告：嘗試獲取不存在的物品ID: " + string(item_id));
    return undefined;
}

function get_item_sprite(item_id) {
    var item = get_item(item_id);
    if (item != undefined) {
        // 先嘗試使用緩存中的精靈
        if (ds_map_exists(item_sprites, item.IconSprite)) {
            var cached_sprite = item_sprites[? item.IconSprite];
            if (sprite_exists(cached_sprite)) {
                return cached_sprite;
            }
        }

        // 如果緩存中沒有，嘗試直接加載
        var sprite = asset_get_index(item.IconSprite);
        if (sprite != -1 && sprite_exists(sprite)) {
            // 將精靈添加到緩存中
            item_sprites[? item.IconSprite] = sprite;
            return sprite;
        }

        // 如果精靈無效，使用預設精靈 spr_gold
        show_debug_message("警告：物品 " + string(item_id) + " 的圖示精靈無效，使用預設精靈 spr_gold");

        // 從緩存中獲取 spr_gold
        if (ds_map_exists(item_sprites, "spr_gold")) {
            return item_sprites[? "spr_gold"];
        }

        // 如果緩存中沒有，嘗試直接加載
        var default_sprite = asset_get_index("spr_gold");
        if (default_sprite != -1 && sprite_exists(default_sprite)) {
            // 將預設精靈添加到緩存中
            item_sprites[? "spr_gold"] = default_sprite;
            return default_sprite;
        } else {
            show_debug_message("嚴重錯誤：預設精靈 spr_gold 也無效！");
            return -1; // 如果連預設精靈都找不到，返回-1
        }
    } else {
        show_debug_message("警告：找不到物品 " + string(item_id) + "，使用預設精靈 spr_gold");

        // 從緩存中獲取 spr_gold
        if (ds_map_exists(item_sprites, "spr_gold")) {
            return item_sprites[? "spr_gold"];
        }

        return asset_get_index("spr_gold");
    }
}

function get_item_type(item_id) {
    return floor(item_id / 1000);
}

function is_stackable(item_id) {
    var item = get_item(item_id);
    return item != undefined && item.StackMax > 1;
}

function can_use_item(item_id) {
    var item = get_item(item_id);
    return item != undefined && item.UseEffect != "none";
}

// 添加物品到背包
function add_item_to_inventory(item_id, quantity) {
    if (!ds_map_exists(items_data, item_id)) {
        show_debug_message("錯誤：嘗試添加不存在的物品ID: " + string(item_id));
        return false;
    }

    // 確保global.player_inventory存在
    if (!variable_global_exists("player_inventory")) {
        global.player_inventory = ds_list_create();
        show_debug_message("創建新的玩家物品欄");
    }

    // 檢查是否已有該物品
    var inventory_size = ds_list_size(global.player_inventory);
    for (var i = 0; i < inventory_size; i++) {
        var inv_item = global.player_inventory[| i];
        if (inv_item.id == item_id) {
            // 更新數量
            inv_item.quantity += quantity;
            show_debug_message("更新物品數量：ID=" + string(item_id) + " 新數量=" + string(inv_item.quantity));

            // 觸發事件
            var evt_data = {
                added_item_id: item_id,
                added_quantity: quantity
            };

            if (instance_exists(obj_event_manager)) {
                var event_manager = instance_find(obj_event_manager, 0);
                if (variable_instance_exists(event_manager, "trigger_event")) {
                    event_manager.trigger_event("item_added", evt_data);
                } else {
                    show_debug_message("警告：事件管理器缺少trigger_event函數");
                }
            } else {
                show_debug_message("警告：找不到事件管理器實例");
            }

            return true;
        }
    }

    // 添加新物品
    var new_item = {
        id: item_id,
        quantity: quantity
    };
    ds_list_add(global.player_inventory, new_item);
    show_debug_message("添加新物品：ID=" + string(item_id) + " 數量=" + string(quantity));

    // 觸發事件
    var evt_data = {
        added_item_id: item_id,
        added_quantity: quantity
    };

    if (instance_exists(obj_event_manager)) {
        var event_manager = instance_find(obj_event_manager, 0);
        if (variable_instance_exists(event_manager, "trigger_event")) {
            event_manager.trigger_event("item_added", evt_data);
        } else {
            show_debug_message("警告：事件管理器缺少trigger_event函數");
        }
    } else {
        show_debug_message("警告：找不到事件管理器實例");
    }

    return true;
}

// 使用物品
function use_item(item_id) {
    if (!ds_map_exists(items_data, item_id)) {
        show_debug_message("錯誤：嘗試使用不存在的物品ID: " + string(item_id));
        return false;
    }

    // 檢查物品是否在背包中
    var inventory_size = ds_list_size(global.player_inventory);
    for (var i = 0; i < inventory_size; i++) {
        var inv_item = global.player_inventory[| i];
        if (inv_item.id == item_id && inv_item.quantity > 0) {
            var item_data = items_data[? item_id];

            // 執行使用效果
            var use_success = execute_item_effect(item_data);
            if (use_success) {
                // 減少數量
                inv_item.quantity--;
                show_debug_message("使用物品：" + item_data.Name + " 剩餘數量：" + string(inv_item.quantity));

                // 如果數量為0，從背包中移除
                if (inv_item.quantity <= 0) {
                    ds_list_delete(global.player_inventory, i);
                    show_debug_message("物品用盡，從背包中移除");
                }

                // 觸發事件
                if (instance_exists(obj_event_manager)) {
                    var event_manager = instance_find(obj_event_manager, 0);
                    if (variable_instance_exists(event_manager, "trigger_event")) {
                        event_manager.trigger_event("item_used", {item_id: item_id});
                    } else {
                        show_debug_message("警告：事件管理器缺少trigger_event函數");
                    }
                } else {
                    show_debug_message("警告：找不到事件管理器實例");
                }

                return true;
            }
        }
    }

    show_debug_message("使用物品失敗：物品不在背包中或數量不足");
    return false;
}

// 執行物品效果
function execute_item_effect(item_data) {
    if (item_data.Type != "CONSUMABLE") {
        show_debug_message("警告：嘗試使用非消耗品");
        return false;
    }

    switch (item_data.UseEffect) {
        case "heal":
            if (instance_exists(Player)) {
                with (Player) {
                    hp = min(max_hp, hp + item_data.EffectValue);
                }
                show_debug_message("治療效果：+" + string(item_data.EffectValue) + " HP");
                return true;
            }
            break;
    }

    show_debug_message("物品效果執行失敗");
    return false;
}

// 移除 get_item_sprite_full 函數，因為不再需要
// 如果其他地方有使用，可以讓它直接返回與 get_item_sprite 相同的結果
function get_item_sprite_full(item_id) {
    return get_item_sprite(item_id);
}

show_debug_message("obj_item_manager Create: 即將調用 load_items_data()...");

// 初始化時載入數據
if (!load_items_data()) {
    show_debug_message("錯誤：物品數據載入失敗 (load_items_data 返回 false)");
    // 在這裡考慮是否要 instance_destroy() 或設置一個錯誤狀態？
} else {
     show_debug_message("obj_item_manager Create: load_items_data() 調用成功完成。");
}

// --- 新增/遷移：快捷欄管理 ---
global.player_hotbar_slots = 10;
global.player_hotbar = array_create(global.player_hotbar_slots, noone);
show_debug_message("  - 全局快捷欄數據已初始化");

// 指派物品到快捷欄的函數
assign_item_to_hotbar = function(inventory_index) {
    show_debug_message("物品管理器：嘗試將背包索引 " + string(inventory_index) + " 指派到快捷欄");

    // 檢查 inventory_index 是否有效
    if (!variable_global_exists("player_inventory") || !ds_exists(global.player_inventory, ds_type_list)) {
        show_debug_message("錯誤：玩家背包列表不存在。");
        return false;
    }
    if (inventory_index < 0 || inventory_index >= ds_list_size(global.player_inventory)) {
        show_debug_message("錯誤：無效的背包索引 " + string(inventory_index));
        return false;
    }

    // 檢查物品是否已經在快捷欄中
    for (var i = 0; i < global.player_hotbar_slots; i++) {
        if (global.player_hotbar[i] == inventory_index) {
            show_debug_message("物品已在快捷欄位置 " + string(i));
            // TODO: 通知玩家物品已指派
            return true;
        }
    }

    // 查找第一個空位
    var assigned_slot = -1;
    for (var i = 0; i < global.player_hotbar_slots; i++) {
        if (global.player_hotbar[i] == noone) {
            global.player_hotbar[i] = inventory_index;
            show_debug_message("物品成功指派到快捷欄位置 " + string(i));
            assigned_slot = i;
            break; // 找到空位就退出循環
        }
    }

    if (assigned_slot == -1) {
        show_debug_message("快捷欄已滿，無法指派物品。");
        // TODO: 通知玩家快捷欄已滿
        return false;
    }

    // 觸發更新事件 (可選，通知 HUD 等)
    // trigger_event("hotbar_updated", {slot: assigned_slot, index: inventory_index});
    show_debug_message("  - assign_item_to_hotbar 函數已定義");
    return true;
}

// 取消物品的快捷欄指派
unassign_item_from_hotbar = function(inventory_index) {
    var unassigned = false;
    for (var i = 0; i < global.player_hotbar_slots; i++) {
        if (global.player_hotbar[i] == inventory_index) {
            global.player_hotbar[i] = noone; // 使用 noone 表示空位
            show_debug_message("物品索引 " + string(inventory_index) + " 已從快捷欄位 " + string(i) + " 取消指派");
            unassigned = true;
            // 觸發更新事件 (可選)
            // trigger_event("hotbar_updated", {slot: i, index: noone});
            break; // 找到並取消後就退出
        }
    }
    if (!unassigned) {
         show_debug_message("嘗試取消指派失敗：物品索引 " + string(inventory_index) + " 未在快捷欄找到");
    }
    show_debug_message("  - unassign_item_from_hotbar 函數已定義");
    return unassigned;
}

// 新增：查詢物品被指派到哪個快捷欄
get_hotbar_slot_for_item = function(inventory_index) {
    if (inventory_index == -1) return -1; // 無效索引直接返回
    for (var i = 0; i < global.player_hotbar_slots; i++) {
        if (global.player_hotbar[i] == inventory_index) {
            return i; // 返回快捷欄位索引 (0-9)
        }
    }
    return -1; // 未找到
}

// 新增：獲取指定快捷欄位的物品背包索引
get_item_in_hotbar_slot = function(hotbar_slot) {
    if (hotbar_slot < 0 || hotbar_slot >= global.player_hotbar_slots) {
        return noone; // 無效欄位
    }
    return global.player_hotbar[hotbar_slot]; // 返回背包索引或 noone
}
show_debug_message("  - get_item_in_hotbar_slot 函數已定義");
show_debug_message("obj_item_manager Create: 快捷欄管理函數定義完成。");

// --- 結束 快捷欄管理 ---

// 清理函數
function cleanup_item_manager() {
    if (ds_exists(items_data, ds_type_map)) {
        ds_map_destroy(items_data);
    }
    if (ds_exists(item_sprites, ds_type_map)) {
        ds_map_destroy(item_sprites);
    }
}

// 測試函數
function test_item_manager() {
    show_debug_message("===== 開始測試道具管理器 =====");

    // 測試1：檢查道具數據載入
    show_debug_message("\n1. 測試道具數據載入：");
    show_debug_message("數據庫大小：" + string(ds_map_size(items_data)));

    // 測試2：檢查各類型道具
    show_debug_message("\n2. 測試道具類型檢查：");
    var test_ids = [1001, 2001, 3001, 4001];
    var type_names = ["消耗品", "裝備", "捕捉道具", "材料"];

    for (var i = 0; i < array_length(test_ids); i++) {
        var item = get_item(test_ids[i]);
        if (item != undefined) {
            show_debug_message(type_names[i] + " 測試: ID " + string(test_ids[i]) +
                             " - " + item.Name + " [" + item.Type + "]");
        } else {
            show_debug_message(type_names[i] + " 測試失敗: 找不到ID " + string(test_ids[i]));
        }
    }

    // 測試3：測試道具屬性
    show_debug_message("\n3. 測試道具屬性：");
    var test_item = get_item(1001); // 小型回復藥水
    if (test_item != undefined) {
        show_debug_message("道具名稱: " + test_item.Name);
        show_debug_message("堆疊上限: " + string(test_item.StackMax));
        show_debug_message("效果值: " + string(test_item.EffectValue));
        show_debug_message("售價: " + string(test_item.SellPrice));
        show_debug_message("可堆疊: " + string(is_stackable(1001)));
        show_debug_message("可使用: " + string(can_use_item(1001)));
    }

    // 測試4：測試無效道具ID
    show_debug_message("\n4. 測試錯誤處理：");
    var invalid_item = get_item(9999);
    show_debug_message("無效道具測試: " + string(invalid_item == undefined ? "正確" : "錯誤"));

    // 測試5：測試精靈載入
    show_debug_message("\n5. 測試精靈載入：");
    var sprite_id = get_item_sprite(1001);
    show_debug_message("精靈測試: " + (sprite_id != -1 ? "成功" : "未找到精靈"));

    // 測試6：測試新的Sprite系統
    show_debug_message("\n6. 測試Sprite系統：");
    var test_items = [1001, 2001, 3001, 4001];

    for (var i = 0; i < array_length(test_items); i++) {
        var item = get_item(test_items[i]);
        if (item != undefined) {
            show_debug_message("測試物品 " + item.Name + ":");
            show_debug_message("- 圖示(IconSprite): " + string(item.IconSprite));

            // 測試get_item_sprite函數
            var icon = get_item_sprite(test_items[i]);

            show_debug_message("- get_item_sprite結果: " + string(icon));

            // 檢查是否使用預設精靈
            if (item.IconSprite == asset_get_index("spr_gold")) {
                show_debug_message("- 使用預設精靈(spr_gold)");
            }
        }
    }

    // 可以添加快捷欄相關測試

    show_debug_message("===== 道具管理器測試完成 =====");
}



