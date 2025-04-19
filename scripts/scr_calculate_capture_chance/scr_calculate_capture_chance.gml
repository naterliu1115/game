/// @function scr_calculate_capture_chance(target_id, item_id)
/// @param {Id.Instance} target_id The enemy instance to calculate chance for.
/// @param {Real} item_id The ID of the capture item being used (pass noone or -1 if none).
/// @description Calculates the capture chance based on enemy stats, status, and item used.
/// @returns {Real} The capture chance (0.0 to 1.0), or -1 if the target is not capturable.
function scr_calculate_capture_chance(_target_id, _item_id) {

    // --- 1. 基本驗證 ---
    if (!instance_exists(_target_id)) {
        show_debug_message("scr_calculate_capture_chance: Target instance does not exist.");
        return 0; // 無效目標，機率為 0
    }

    // --- 2. 檢查是否可捕獲 ('capturable' 屬性) ---
    // 假設敵人實例有 'capturable' 變數，在創建時從模板加載
    if (!variable_instance_exists(_target_id, "capturable") || !_target_id.capturable) {
         show_debug_message("scr_calculate_capture_chance: Target " + object_get_name(_target_id.object_index) + " is not capturable.");
        return -1; // 返回 -1 表示不可捕獲
    }

    // --- 3. 獲取計算所需的變數 ---
    var _current_hp = _target_id.hp;
    var _max_hp = _target_id.max_hp;
    // 假設敵人實例有 'capture_rate' 變數，在創建時從模板的 capture_rate_base 加載
    var _base_capture_rate = variable_instance_get(_target_id, "capture_rate"); // Get the variable value
    if (is_undefined(_base_capture_rate)) { // Check if the variable exists
        _base_capture_rate = 0.1; // Assign default value if it doesn't exist
        show_debug_message("警告：在目標 " + object_get_name(_target_id.object_index) + " 上未找到 capture_rate 變數，使用預設值 0.1");
    }

    // 狀態修正 (假設有函數 get_status_capture_modifier 返回狀態加成值)
    // 如果沒有，則暫時設為 1
    var _status_modifier = 1.0;
    if (script_exists(get_status_capture_modifier)) { // 檢查函數是否存在
        _status_modifier = get_status_capture_modifier(_target_id);
    } else {
        // show_debug_message("scr_calculate_capture_chance: Function get_status_capture_modifier not found, using default 1.0");
        // 可以添加檢查敵人是否有特定狀態效果變數
        if (variable_instance_exists(_target_id, "is_sleeping") && _target_id.is_sleeping) _status_modifier = max(_status_modifier, 2.0);
        if (variable_instance_exists(_target_id, "is_paralyzed") && _target_id.is_paralyzed) _status_modifier = max(_status_modifier, 1.5);
    }


    // --- 4. 獲取道具加成 ---
    var _item_bonus = 1.0;
    if (!is_undefined(_item_id) && _item_id != noone && _item_id != -1) {
        // 假設存在全局物品數據 global.items_data 或函數 get_item_data
        // 並且物品數據結構包含 Type 和 EffectValue
        var _item_data = undefined;
        if (variable_global_exists("items_data_map") && ds_map_exists(global.items_data_map, _item_id)) {
             _item_data = global.items_data_map[? _item_id];
        } else if (script_exists(get_item_data)) {
             _item_data = get_item_data(_item_id);
        }

        if (!is_undefined(_item_data)) {
            if (variable_struct_exists(_item_data, "Type") && _item_data.Type == "CAPTURE") {
                if (variable_struct_exists(_item_data, "EffectValue")) {
                    _item_bonus = _item_data.EffectValue;
                    // 確保 EffectValue 是有效的正數
                    if (!is_real(_item_bonus) || _item_bonus <= 0) {
                        _item_bonus = 1.0;
                        show_debug_message("警告：捕獲道具 " + string(_item_id) + " 的 EffectValue 無效 (" + string(_item_data.EffectValue) + ")，使用預設值 1.0");
                    }
                } else {
                     show_debug_message("警告：捕獲道具 " + string(_item_id) + " 缺少 EffectValue，使用預設值 1.0");
                }
            } else {
                // 雖然傳入了 ID，但不是捕獲道具，加成仍為 1
                 show_debug_message("提示：嘗試用於計算捕獲率的道具 " + string(_item_id) + " 不是 CAPTURE 類型。");
            }
        } else {
            show_debug_message("警告：無法獲取道具 ID " + string(_item_id) + " 的數據，使用預設加成 1.0");
        }
    }

    // --- 5. 計算捕獲機率 (使用新公式) ---
    // 防止除以零
    if (_max_hp <= 0) {
        show_debug_message("scr_calculate_capture_chance: Target max_hp is zero or negative.");
        return 0; // HP 無效，機率為 0
    }

    // 確保 current_hp 不超過 max_hp (雖然通常不會，但以防萬一)
    _current_hp = min(_current_hp, _max_hp);
    _current_hp = max(0, _current_hp); // 確保 hp 不為負

    // HP 因子計算
    var _hp_factor = (3 * _max_hp - 2 * _current_hp) / (3 * _max_hp);

    // 最終機率計算
    var _final_chance = _hp_factor * _base_capture_rate * _status_modifier * _item_bonus;

    // --- 6. Clamp 結果並返回 ---
    _final_chance = clamp(_final_chance, 0, 1); // 確保機率在 0.0 到 1.0 之間

    // Debug 輸出詳細計算過程
    // show_debug_message(string_format("捕獲計算: HP={0}/{1} (Factor={2}), Rate={3}, StatusMod={4}, ItemBonus={5} => FinalChance={6}",
    //    _current_hp, _max_hp, string_format("{0:0.3f}", _hp_factor), _base_capture_rate, _status_modifier, _item_bonus, string_format("{0:0.3f}", _final_chance)));

    return _final_chance;
}
