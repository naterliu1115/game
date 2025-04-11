/// @function load_csv(filename)
/// @description 載入並解析CSV文件
/// @param {string} filename - CSV文件名 (不含 'datafiles/' 前綴)
/// @returns {ds_grid} 包含CSV數據的網格，失敗返回 -1
function load_csv(filename) {
    // --- 修改：嘗試多個可能的相對路徑 --- 
    var _csv_file_path = ""; // 存儲找到的有效路徑
    // 優先嘗試 datafiles/ 前綴，然後嘗試根目錄
    var _paths_to_try = ["datafiles/" + filename, filename]; 

    for (var i = 0; i < array_length(_paths_to_try); i++) {
        var _current_path = _paths_to_try[i];
        show_debug_message("[load_csv] 嘗試檢查路徑: " + _current_path);
        if (file_exists(_current_path)) {
            _csv_file_path = _current_path;
            show_debug_message("  [load_csv] 文件找到於: " + _csv_file_path);
            break; // 找到就跳出循環
        }
    }

    // 檢查是否找到了文件
    if (_csv_file_path == "") {
        // 兩種路徑都找不到
        show_debug_message("錯誤 [load_csv]：文件 " + filename + " 未在預期路徑找到! (已嘗試: " + string(_paths_to_try) + ")");
        return -1; // 失敗返回 -1
    }
    // --- 路徑檢查結束 --- 
    
    // var file_path = working_directory + "datafiles/" + filename; // <-- 移除 working_directory
    // if (!file_exists(file_path)) { ... } // <-- 移除舊的檢查
    
    // 使用找到的有效路徑打開文件
    var file = file_text_open_read(_csv_file_path);
    if (file == -1) {
        show_debug_message("錯誤 [load_csv]：無法打開文件 " + _csv_file_path);
        return -1;
    }
    
    // 讀取標題行
    var header_line = file_text_readln(file);
    
    // 如果有BOM標記 (EF BB BF)，需要移除
    if (string_length(header_line) >= 3) {
        if (ord(string_char_at(header_line, 1)) == 239 && 
            ord(string_char_at(header_line, 2)) == 187 && 
            ord(string_char_at(header_line, 3)) == 191) {
            header_line = string_delete(header_line, 1, 3);
        }
    }
    
    // 分割標題行
    var headers = string_split(header_line, ",");
    var col_count = array_length(headers);
    
    // 讀取所有行以計算行數
    var rows = [];
    var row_count = 0;
    
    while (!file_text_eof(file)) {
        var line = file_text_readln(file);
        
        // 跳過注釋行和空白行
        if (string_length(line) > 0 && string_char_at(line, 1) != "#" && string_char_at(line, 1) != "\n") {
            row_count++;
            array_push(rows, line);
        }
    }
    
    // 關閉文件 (在數據讀取循環之後)
    // file_text_close(file); // <-- 這行需要移到數據處理完畢後
    
    // 如果沒有實際行數據，返回錯誤
    if (row_count == 0) {
        show_debug_message("警告：CSV文件沒有數據行");
        return -1;
    }
    
    // 創建網格
    var grid = ds_grid_create(col_count, row_count + 1); // +1 包含標題
    
    // 填入標題行
    for (var i = 0; i < col_count; i++) {
        ds_grid_set(grid, i, 0, headers[i]);
    }
    
    // 填入數據行
    for (var i = 0; i < row_count; i++) {
        var values = string_split(rows[i], ",");
        
        for (var j = 0; j < col_count; j++) {
            if (j < array_length(values)) {
                ds_grid_set(grid, j, i + 1, string_trim(values[j]));
            } else {
                ds_grid_set(grid, j, i + 1, ""); // 缺少值時填入空字符串
            }
        }
    }
    
    // 在填充完 grid 後關閉文件
    file_text_close(file);

    show_debug_message("成功載入CSV文件：" + filename + " (從 " + _csv_file_path + ")，共 " + string(row_count) + " 行，" + string(col_count) + " 列");
    return grid;
}

/// @function string_split(str, delimiter)
/// @description 將字符串按分隔符分割為數組
/// @param {string} str - 要分割的字符串
/// @param {string} delimiter - 分隔符
/// @returns {array} 分割後的字符串數組
function string_split(str, delimiter) {
    var result = [];
    var last_pos = 1;
    var pos = string_pos(delimiter, str);
    
    // 處理帶引號的CSV字段
    var in_quotes = false;
    var current_chunk = "";
    
    for (var i = 1; i <= string_length(str); i++) {
        var char = string_char_at(str, i);
        
        if (char == "\"") {
            in_quotes = !in_quotes;
        } else if (char == delimiter && !in_quotes) {
            array_push(result, current_chunk);
            current_chunk = "";
        } else {
            current_chunk += char;
        }
    }
    
    // 添加最後一個部分
    array_push(result, current_chunk);
    
    return result;
}

/// @function string_trim(str)
/// @description 移除字符串前後的空白字符和引號
/// @param {string} str - 要處理的字符串
/// @returns {string} 處理後的字符串
function string_trim(str) {
    // 移除前後的空白
    while (string_length(str) > 0 && string_char_at(str, 1) == " ") {
        str = string_delete(str, 1, 1);
    }
    
    while (string_length(str) > 0 && string_char_at(str, string_length(str)) == " ") {
        str = string_delete(str, string_length(str), 1);
    }
    
    // 移除前後的引號
    if (string_length(str) >= 2) {
        if (string_char_at(str, 1) == "\"" && string_char_at(str, string_length(str)) == "\"") {
            str = string_copy(str, 2, string_length(str) - 2);
        }
    }
    
    return str;
}

/// @function csv_grid_get(grid, col_name, row)
/// @description 根據列名獲取CSV網格中的值
/// @param {ds_grid} grid - CSV數據網格
/// @param {string} col_name - 列名
/// @param {real} row - 行索引（從1開始）
/// @returns {string} 指定單元格的值
function csv_grid_get(grid, col_name, row) {
    // 找出列名對應的索引
    var col_index = -1;
    for (var i = 0; i < ds_grid_width(grid); i++) {
        if (ds_grid_get(grid, i, 0) == col_name) {
            col_index = i;
            break;
        }
    }
    
    if (col_index == -1) {
        show_debug_message("警告：找不到列名 " + col_name);
        return "";
    }
    
    if (row < 1 || row >= ds_grid_height(grid)) {
        show_debug_message("警告：行索引超出範圍 " + string(row));
        return "";
    }
    
    return ds_grid_get(grid, col_index, row);
}

/// @function bool(value)
/// @description 將字符串轉換為布爾值
/// @param {string/real} value - 要轉換的值
/// @returns {bool} 轉換後的布爾值
function bool(value) {
    if (is_string(value)) {
        value = string_lower(value);
        return value == "true" || value == "1" || value == "yes" || value == "y" || value == "t";
    } else {
        return value != 0;
    }
} 