# systemPatterns.md

## 系統架構
- 分層設計：遊戲邏輯、渲染、資源管理分離，控制器模式（manager 對象）主導各子系統。
- 主要物件：obj_battle_manager、obj_stone、obj_flying_item、obj_item_manager、Player、UI 物件。
- 物品、敵人、技能等皆以 CSV/資料驅動。

## 關鍵技術決策
- 狀態機模式：戰鬥系統、飛行道具、單位行為皆用明確狀態機管理。
- 事件驅動：發布-訂閱模式，鬆耦合組件通信。提供標準事件接口 (`subscribe_to_event`, `unsubscribe_from_event`, `trigger_event`) 由 `obj_event_manager` 管理。
- 工廠模式：敵人、掉落物品等皆以工廠/資料表生成。
- 資料驅動：物品、敵人、技能、掉落表皆以 CSV 管理。
- 佇列/Alarm 驅動：掉落動畫、戰鬥結果流程。
- 技能系統：skills 與 skill_cooldowns 均為 array，完全一一對應，所有操作皆用數字索引，不再用 struct/ds_map。

## 設計模式
- 狀態機模式（State Machine）
- 工廠模式（Factory）
- 事件驅動（Event-driven）(包含發布/訂閱)
- 父子類繼承（Parent-Child Inheritance）
- 資料驅動（Data-driven）

## 元件關係
- obj_battle_manager：戰鬥流程、掉落、經驗、事件流
- obj_stone：採集、礦石掉落
- obj_flying_item：掉落物動畫、收集
- obj_item_manager：物品資料、背包、快捷欄
- Player：玩家角色，掉落物目標
- UI 物件：主 HUD、戰鬥 UI、物品欄、彈窗等 