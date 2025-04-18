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

// === 升級事件處理方法 ===
function handle_monster_leveled_up(event_data) {
    show_debug_message("[obj_level_manager][METHOD] 收到 monster_leveled_up 事件: " + json_stringify(event_data));
    var uid = event_data.uid;
    var new_level = event_data.new_level;
    var monster = event_data.monster; // monster 結構體包含了升級後的資訊
    var found = false;

    with (obj_player_summon_parent) { // 找到升級的那個怪物實例
        if (variable_instance_exists(id, "uid") && uid == event_data.uid) {
            found = true;
            show_debug_message("[obj_level_manager][METHOD] 找到怪物實例 UID=" + string(uid) + " at (" + string(x) + "," + string(y) + ")，準備創建升級特效...");

            // --- 特效邏輯開始 (從 obj_player_summon_parent 移入) ---

            // --- 1. 顯示 "Level Up!" 浮動文字 ---
            if (object_exists(obj_floating_text)) {
                // 使用當前找到的怪物實例的 x, y 座標
                var _text_effect = instance_create_layer(x, y - 32, "Effects", obj_floating_text);
                if (instance_exists(_text_effect)) {
                    _text_effect.display_text = "Level Up!";
                    _text_effect.text_color = c_yellow;
                    _text_effect.scale = 1.3;
                    _text_effect.float_speed = 0.7;
                    // 將持續時間從遊戲速度改為秒 (更可靠)
                    _text_effect.duration = 1.5 * game_get_speed(gamespeed_fps); // 持續 1.5 秒
                    show_debug_message("    創建了 'Level Up!' 浮動文字。");
                } else {
                    show_debug_message("    警告：未能創建 Level Up 文字特效實例。");
                }
            } else {
                show_debug_message("    警告：obj_floating_text 物件資源不存在，無法創建 Level Up 文字特效。");
            }

            // --- 2. 創建粒子效果或物件特效 ---
            var effect_created = false;
            // 檢查全局粒子系統和類型是否存在
            if (variable_global_exists("particle_system") && part_system_exists(global.particle_system)) {
                if (variable_global_exists("pt_level_up_sparkle") && part_type_exists(global.pt_level_up_sparkle)) {
                     // 使用當前找到的怪物實例的 x, y 座標
                    part_particles_create(global.particle_system, x, y, global.pt_level_up_sparkle, 25);
                    show_debug_message("    創建了 Level Up 火花粒子。");
                    effect_created = true;
                } else {
                    show_debug_message("    警告：全局升級火花粒子類型 pt_level_up_sparkle 未定義或無效。");
                }
            } else {
                show_debug_message("    警告：全局粒子系統 global.particle_system 不存在或無效，無法創建升級粒子特效。");
            }

            // 若無法產生粒子，則創建 obj_levelup_effect 作為後備
            if (!effect_created) {
                if (object_exists(obj_levelup_effect)) {
                    // 使用當前找到的怪物實例的 x, y 座標
                    var eff = instance_create_layer(x, y, "Effects", obj_levelup_effect);
                     if (!is_undefined(eff)) {
                         // 可以傳遞一些數據給特效物件 (可選)
                         eff.target_uid = uid;
                         eff.new_level = new_level;
                         eff.monster_name = is_undefined(monster.name) ? "?" : monster.name;
                         show_debug_message("    使用 obj_levelup_effect 物件產生後備火花動畫。");
                     } else {
                         show_debug_message("    警告：無法創建後備特效 obj_levelup_effect 實例！");
                     }
                } else {
                    show_debug_message("    警告：obj_levelup_effect 物件不存在，無法產生後備火花動畫。");
                }
            }
             // --- 特效邏輯結束 ---

             // --- 3. 音效 (如果需要的話，可以從 player_summon 移過來) ---
             // (這裡可以加入播放升級音效的代碼)
             // 例如: if (audio_exists(snd_level_up)) { audio_play_sound(snd_level_up, 10, false); }

             // --- 4. (可選) UI 更新觸發 ---
             // 如果有怪物管理 UI 需要立即更新，可以在這裡觸發事件
             // 例如: broadcast_event("ui_update_monster_stats", { uid: uid });
        }
    }

    if (!found) {
        show_debug_message("[obj_level_manager][METHOD] 未找到對應怪物實例，無法創建特效，UID=" + string(uid));
    }
}


// === 訂閱升級事件 ===
with (obj_event_manager) {
    // 使用方法名稱字串作為回呼
    subscribe_to_event("monster_leveled_up", other.id, "handle_monster_leveled_up");
    show_debug_message("[obj_level_manager][Create] 已嘗試訂閱 monster_leveled_up 事件，回調方法: handle_monster_leveled_up");
} 