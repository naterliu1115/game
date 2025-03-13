// 確保 `global.player` 存在，避免不必要的搜尋
if (!instance_exists(global.player)) {
    show_debug_message("❌ `global.player` 未初始化！");
    exit;
}

// 直接使用 `global.player` 的座標
var player_x = global.player.bbox_left + (global.player.bbox_right - global.player.bbox_left) / 2;
var player_y = global.player.bbox_top + (global.player.bbox_bottom - global.player.bbox_top) / 2;

if (active && current_npc != noone) {
    // 確保 NPC 的位置正確
    var npc_x = current_npc.bbox_left + (current_npc.bbox_right - current_npc.bbox_left) / 2;
    var npc_y = current_npc.bbox_top + (current_npc.bbox_bottom - current_npc.bbox_top) / 2;

    // 計算玩家與 NPC 的距離
    var distance = point_distance(player_x, player_y, npc_x, npc_y);
	
    // 設定超出範圍時關閉對話
    var max_talk_distance = 100;
    if (distance > max_talk_distance) {
        active = false;
        current_npc = noone;
    }
}

// 只在对话激活但NPC无效时才输出错误
if (active && current_npc == noone) {
    show_debug_message("❌ 对话激活但current_npc = noone");
}
