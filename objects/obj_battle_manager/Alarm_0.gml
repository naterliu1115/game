/// @description 延遲創建飛行道具 (已移除 - 邏輯與當前設計衝突)

// Alarm 0 的內容已被移除，因為它在 GUI 層創建 obj_flying_item，
// 並使用了不準確的 world_to_gui_coords，且功能與 obj_stone Alarm 0
// 或 obj_battle_manager Alarm 1 重疊或衝突。
// 飛行道具創建現在統一由 obj_stone Alarm 0 (採集) 
// 或 obj_battle_manager Alarm 1 (怪物掉落) 在世界層處理。 