/// @description 加載等級數據

show_debug_message("===== obj_level_manager 初始化開始 =====");

// 創建全局等級經驗映射表
global.level_exp_map = ds_map_create();

// --- 加入詳細 debug log ---
show_debug_message("[LevelManager] 嘗試載入 levels.csv ...");
var _csv_grid = load_csv("levels.csv");
show_debug_message("[LevelManager] load_csv('levels.csv') 回傳: " + string(_csv_grid));

// 檢查加載是否成功
if (!ds_exists(_csv_grid, ds_type_grid)) { // load_csv 失敗返回 -1，不是有效的 grid ID
    show_error("錯誤：無法通過 load_csv 加載 levels.csv！", true);
    show_debug_message("[LevelManager] 載入 levels.csv 失敗，_csv_grid = " + string(_csv_grid));
    return;
}
// --- 修改結束 --- 

// --- 使用加載的 Grid 填充 Map --- 
var _height = ds_grid_height(_csv_grid);
show_debug_message("[LevelManager] ds_grid_height = " + string(_height));
var _found_data = false;
for (var i = 1; i < _height; i++) { // 從 1 開始，跳過標題行
    // 使用 csv_grid_get (來自 scr_csv_parser) 來安全獲取數據
    var _level_str = csv_grid_get(_csv_grid, "level", i);
    var _exp_str = csv_grid_get(_csv_grid, "exp_to_next", i);
    show_debug_message("[LevelManager] 解析第 " + string(i) + " 行: level='" + string(_level_str) + "', exp_to_next='" + string(_exp_str) + "'");

    // 確保讀取的值是字符串並且可以解析為數字
    if (is_string(_level_str) && is_string(_exp_str) && is_numeric_safe(_level_str) && is_numeric_safe(_exp_str)) {
        var _level_val = real(_level_str);
        var _exp_val = real(_exp_str);
        global.level_exp_map[? _level_val] = _exp_val;
        show_debug_message("[LevelManager] 加入等級映射: " + string(_level_val) + " -> " + string(_exp_val));
        _found_data = true;
    } else {
        if (string_length(trim(_level_str)) > 0 || string_length(trim(_exp_str)) > 0) { // 忽略完全空行產生的空字符串
             show_debug_message("警告：levels.csv (通過 grid) 第 " + string(i+1) + " 行數據格式錯誤 (非數字)。 Level: '" + _level_str + "', Exp: '" + _exp_str + "'");
        }
    }
}

// 處理完畢後銷毀 Grid
ds_grid_destroy(_csv_grid);
// --- 數據處理結束 --- 

// 最終檢查 Map 是否為空
if (!_found_data) {
    show_error("錯誤：未能從 levels.csv 解析並加載任何有效的等級數據到 Map！", true);
    show_debug_message("[LevelManager] global.level_exp_map size = 0");
} else {
    show_debug_message("成功解析並加載 " + string(ds_map_size(global.level_exp_map)) + " 條等級數據到 global.level_exp_map。");
}

show_debug_message("===== obj_level_manager 初始化完成 =====");

// **重要提示:** 確保此對象是 Persistent (持久化)
// **重要提示:** 確保此對象在遊戲啟動時被創建 (例如放在第一個房間) 