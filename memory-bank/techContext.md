# techContext.md

## 使用技術
- GameMaker Studio 2
- GML（GameMaker Language）
- 主要使用 fnt_dialogue 作為標準字體

## 開發環境
- Windows 10
- 推薦使用 Cursor IDE 或 GameMaker IDE

## 技術限制
- 需要有效管理物件層級（Instances、GUI 等），避免混用座標導致視覺或邏輯錯誤。
- GML 缺乏原生類型檢查，需要依賴註解和防禦性程式設計來確保穩定性。
- 在 `with` 區塊中使用變數前必須先宣告。
- **開發實踐：對於涉及物理模擬、動畫或複雜狀態機的問題，必須優先使用 `show_debug_message` 或 GameMaker 的除錯工具進行逐步驗證，以確保邏輯符合預期，避免視覺錯誤或狀態卡死。**

## 依賴與資源
- 物品資料、掉落表由 obj_item_manager 管理
- 採用全局變數與結構體傳遞跨物件資料
- 粒子系統用於視覺特效

## 其他
- 專案規範：所有新功能需以世界層為主，避免 GUI/世界混用
- 掉落工廠統一化為未來優化目標 