# Cursor Memory Bank 使用說明

## 工具簡介
Cursor Memory Bank 是一套讓 AI 助手（如 Cursor agent）能夠跨多次對話、跨 session 持續記憶專案上下文的系統。它透過 `memory-bank` 目錄下的多個 Markdown 文件，記錄專案架構、規則、進度與團隊共識，確保 AI 回答與協作都能延續正確脈絡。

---

## 主要指令說明

- **PLAN**：進入規劃模式，討論需求、設計方案、釐清問題。AI 只會討論與規劃，不會動到任何程式碼。
- **ACT**：確認規劃方案後，讓 AI 執行實際的程式碼修改。執行完畢後自動回到 PLAN 模式。
- **update memory bank**：同步/刷新 AI 記憶庫。當專案有重大重構、合併新功能、規則或進度有重大變更時，請執行此指令，讓 AI 重新讀取最新內容。

---

## 日常使用流程
1. 在專案資料夾下開啟 AI 助手，AI 會自動讀取 `memory-bank` 內容。
2. 有新需求時，直接描述或加上「PLAN」指令，AI 會進入規劃模式。
3. 規劃方案確認後，輸入「ACT」讓 AI 執行實際修改。
4. 專案有重大變更時，輸入「update memory bank」同步記憶內容。

---

## 團隊協作建議
- 請將 `memory-bank` 目錄納入 git 版本控制，確保每位成員的 AI 助手都能同步最新上下文。
- 每次重大重構、合併新功能、規則或進度有重大變更時，務必執行 `update memory bank`。
- 新成員加入時，請先閱讀 `memory-bank/` 內所有說明文件。

---

## 常見 Q&A

**Q: 只要在任何聊天室都能用這個上下文記憶嗎？**
A: 只要你在同一個專案資料夾（有 `.cursor/rules` 與 `memory-bank`）下開啟支援 Cursor Memory Bank 的 AI 工具（如 Cursor IDE、VSCode 插件），AI 就能自動讀取這些記憶檔案。Web 版 ChatGPT 或一般 Discord Bot 無法直接讀取本地 memory-bank。

**Q: 什麼時候該用 PLAN/ACT/update memory bank？**
A: 
- PLAN：討論、規劃、釐清需求時。
- ACT：規劃確認後，要讓 AI 動手修改程式碼時。
- update memory bank：重大重構、pull/merge、規則或進度有重大變更時。

**Q: 可以把工具使用說明也放進 memory-bank 嗎？**
A: 可以！這是大型專案、多人協作的最佳實踐之一。

---

## 我們的共識
- 本專案團隊高度重視 AI 記憶庫的正確性與同步性。
- 每次重大變更後，會主動執行 ` memupdateory bank` 並公告團隊。
- 鼓勵每位成員閱讀並遵循本文件內容，確保 AI 助手能發揮最大效益。

---

如有任何疑問或建議，歡迎隨時補充本文件內容！ 