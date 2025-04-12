// String Helper Functions

/// @function is_numeric_safe(str)
/// @description 安全地檢查字符串是否代表數字 (整數或浮點數)。
/// @param {string} str 要檢查的字符串。
/// @return {bool} 如果字符串代表數字則返回 true，否則返回 false。
function is_numeric_safe(str) {
    if (!is_string(str)) {
        return false;
    }
    
    str = string_trim(str);
    
    var _len = string_length(str);
    if (_len == 0) {
        return false; // 空字符串不是數字
    }
    
    var _has_decimal = false;
    var _start_index = 1; // GML 字符串索引從 1 開始

    // 檢查可選的開頭負號
    if (string_char_at(str, 1) == "-") {
        if (_len == 1) {
            return false; // 只有 "-" 不是數字
        }
        _start_index = 2;
    }

    for (var i = _start_index; i <= _len; i++) {
        var _char = string_char_at(str, i);
        var _ord = ord(_char); // 獲取字符的 ASCII 值
        
        // === 新增：打印正在檢查的字符和 ASCII ===
        // show_debug_message("  [is_numeric_safe] Checking char '" + _char + "' (ASCII: " + string(_ord) + ") at index " + string(i)); // <-- 註解掉
        // === 新增結束 ===

        if (_char == ".") {
            if (_has_decimal) {
                 // show_debug_message("  [is_numeric_safe] Failed: Multiple decimals."); // <-- 註解掉
                return false; // 超過一個小數點
            }
             // 檢查是否只有 "." 或 "-."
            if (_len == _start_index) { 
                 // show_debug_message("  [is_numeric_safe] Failed: String is only '.' or '-.'."); // <-- 註解掉
                return false; 
            }
            _has_decimal = true;
        } else if (!(_ord >= 48 && _ord <= 57)) { // 檢查是否為數字 '0'-'9'
             // show_debug_message("  [is_numeric_safe] Failed: Character is not a digit (0-9)."); // <-- 註解掉
            return false; // 不是數字也不是小數點
        }
    }
    
    // 再次確保字符串不只是 "." 或 "-."
     if (_len == 1 + (_start_index - 1) && _has_decimal) {
          // show_debug_message("  [is_numeric_safe] Failed: String is only '.' or '-.' (final check)."); // <-- 註解掉
         return false;
     }

    // show_debug_message("  [is_numeric_safe] Passed for string: '" + str + "'"); // <-- 註解掉
    return true; // 所有字符都有效
} 