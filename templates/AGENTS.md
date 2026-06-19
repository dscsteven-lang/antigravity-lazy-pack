# 專案規則與記憶管理 (AntiGravity 2.0)

本專案名稱：{{PROJECT_NAME}}
專案個性化設定：{{PROJECT_PERSONALITY}}

## 核心規則與語言偏好
- **繁體中文溝通**：在執行本專案的所有任務時，你的所有中間思考步驟 (Thought) 以及與使用者的對話、執行程式/命令的畫面與輸出說明，都必須優先且盡可能使用**繁體中文 (Taiwan)** 進行。
- **註解與文件**：新增的程式碼註解、文件或說明，皆以繁體中文編寫，除非專案本身有特定的英文需求。

## MCP 與外掛整合狀態
- **NotebookLM MCP 連接**：{{NOTEBOOKLM_STATUS}}
- **GitHub CLI (gh) 連接**：{{GITHUB_CLI_STATUS}}

{{DRAW_GUIDELINE}}

---

## 工作流程與記憶備份 (開工/收工)

### 1. 開工流程 (Start Work)
當使用者輸入「開工」、「開始」或開始新對話時，AI 必須：
1. 讀取並載入本檔案 `.agents/AGENTS.md`。
2. 讀取 `記憶/自訂規則記憶/` 資料夾下的任何自訂規則，更新當前的思考模式與技能。
3. 簡述目前的專案狀態，並詢問使用者本次對話的目標。

### 2. 收工流程 (Finish Work)
當使用者輸入「收工」、「結束對話」或目前工作告一段落時，AI 必須執行以下步驟：
1. **自動備份對話歷史 (Conversation Transcripts)**：
   - 尋找當前對話紀錄檔案。主要路徑為：`<appDataDir>\brain\<conversation-id>\.system_generated\logs\transcript.jsonl`。
   - 將該檔案複製備份至專案根目錄的 `記憶/對話歷史記憶/` 底下。
   - 檔名格式為：`transcript_{{DATE}}_{{TIME}}_<conversation-id>.jsonl`。
2. **自動備份長期學習與自訂規則 (Customizations & Rules)**：
   - 將 `.agents/AGENTS.md`（本檔案）備份至專案根目錄的 `記憶/自訂規則記憶/` 底下。
   - 檔名格式為：`AGENTS_{{DATE}}_{{TIME}}.md`。
3. **Git 狀態檢查與提交詢問 (由使用者決定)**：
   - 執行 `git status` 與變更檢查，排除任何 API key、隱私金鑰或敏感資訊。
   - 向使用者報告今日有變動的檔案與 diff。
   - **生成建議的 Commit Message**。
   - ⚠️ **主動詢問使用者：「是否需要執行 Git commit 與 push 提交本次變更？」**。
   - **必須在得到使用者明確同意後**，才能執行 `git add`、`git commit` 與 `git push`；若使用者拒絕或未作答，則不可自動提交。
4. **工作成果報告**：
   - 簡述今天完成的工作。
   - 列出今日備份對話的檔案名稱與規則檔名稱。
   - 提供下次開工的建議待辦清單。

---

## 專案開發規範 (可視專案性質擴增)
- 遵循簡潔、清晰的程式碼風格。
- 在進行重大變更前，先以繁體中文與使用者確認設計方案。
