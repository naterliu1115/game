// 继承父类的创建事件
event_inherited();

// 设置队伍为玩家方
team = 0;

// 玩家召唤物特有属性
return_after_battle = true;  // 战斗后是否返回玩家的"队伍"
stamina = 100;               // 特殊耐力值，可用于延长战场时间
preferred_distance = 100;    // 与目标的理想战斗距离

// 移除 experience_to_level_up，改為從全局Map讀取
// experience_to_level_up = 100;
// experience = 0; // 經驗值現在由 monster_data_manager 管理

// === 以下方法已移除，邏輯轉移到 monster_data_manager 和 obj_level_manager ===
/*
// obj_player_summon_parent - level_up 函數與經驗值系統

// 級別提升函數 (不再處理連續升級或計算下一級經驗)
function level_up() { ... }

// 建立升級特效 (使用粒子系統 + obj_floating_text)
create_level_up_effect = function() { ... }

// 獲得經驗值 (負責檢查升級和處理連續升級)
function gain_exp(exp_amount) { ... }
*/

// === [事件系統註冊：已移除對 monster_leveled_up 的訂閱] ===
/*
if (team == 0 && instance_exists(obj_event_manager)) {
    with (obj_event_manager) {
        subscribe_to_event("monster_leveled_up", other.id, "on_monster_leveled_up");
    }
    event_registered = true;
} else {
    show_debug_message("[警告] obj_event_manager 不存在，無法註冊事件！");
    event_registered = false;
}
*/

// 覆盖初始化函数 (保持不變)
initialize = function() {
    // 调用父类的初始化
    event_inherited();
    // 添加入场动画或效果的代码可以放这里
    show_debug_message("玩家召唤物初始化完成: " + string(id));
}