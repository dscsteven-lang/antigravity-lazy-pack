---
name: antigravity-project-initializer
description: AntiGravity 2.0 新專案初始化懶人包。當使用者說「建立新專案」、「初始化專案」、「建立 AntiGravity 專案」時載入此技能。
---

# AntiGravity 2.0 新專案自動初始化技能

當使用者提出要「建立新專案」或「初始化專案」時，AI Agent 應按照以下流程執行：

## 執行流程

### 步驟一：向使用者收集與確認專案設定
請以親切、專業的繁體中文，向使用者詢問以下資訊：
1. **專案名稱** (例如：專案儀表板、個人學習助理)
2. **資料夾名稱** (預設建立於 `G:\我的雲端硬碟\AntiGravity2\` 下)
3. **專案個性化設定** (例如：希望 Agent 扮演專家級全端工程師、熱情的程式導師，或極簡明快的工作助理？)
4. **是否連線 NotebookLM MCP** (是/否)
5. **是否啟用生圖指引與 UI 設計規範** (是/否)
6. **GitHub 與遠端 Git 設定** (請選擇：1. 自動新建 GitHub 儲存庫；2. 關聯現有的 GitHub 儲存庫 URL（需提供網址）；3. 不需要)

### 步驟二：列出預設規則並詢問是否增刪
向使用者展示預設套用於新專案 `.agents/AGENTS.md` 的核心規則：
- **語言偏好**：思考 (Thought) 與對話一律使用繁體中文。
- **開工流程**：載入歷史記憶與規則。
- **收工流程**：自動將對話歷史 `transcript.jsonl` 備份至 `記憶/對話歷史記憶/` 下。
- **Git 提交詢問**：分析變更並產生建議 Commit Message，由使用者決定是否提交。
- **生圖指引** (若啟用)：UI 設計配色與 Git 安全隔離。

**詢問使用者**：「這是目前預設的規則。請問您想對這些規則進行修改，或者想新增任何專案的專屬規則嗎？」並收集其需求。

### 步驟三：執行專案建立指令
收集齊全資訊後，在系統終端機中透過 `run_command` 執行此 PowerShell 腳本。

執行指令格式範例：
```powershell
# 範例 1：自動新建 GitHub 儲存庫 (會啟用 GitHub CLI)
powershell -ExecutionPolicy Bypass -File "g:\我的雲端硬碟\AntiGravity2\懶人包\Create-AntiGravityProject.ps1" -ProjectName "專案名稱" -FolderName "資料夾名稱" -Personality "個性化描述" -EnableNotebookLM -EnableGitHubCLI -CreateGithubRepo -EnableDrawGuideline

# 範例 2：關聯現有的 GitHub 儲存庫
powershell -ExecutionPolicy Bypass -File "g:\我的雲端硬碟\AntiGravity2\懶人包\Create-AntiGravityProject.ps1" -ProjectName "專案名稱" -FolderName "資料夾名稱" -Personality "個性化描述" -EnableNotebookLM -GithubRepoUrl "https://github.com/您的帳號/專案儲存庫.git" -EnableDrawGuideline
```

### 步驟四：成果回報與重啟提醒
腳本執行完畢後，請回報建置成果。
- 如果使用者在「步驟二」有提出自訂規則，請立即使用程式碼編輯工具將自訂規則附加到新專案的 `.agents/AGENTS.md` 結尾。
- **⚠️ 必須醒目提示使用者：「由於專案已成功註冊，請【重新啟動 AntiGravity 2.0】或點擊專案清單的「重新整理 (Refresh)」，『專案名稱』才會顯示在您的專案清單中！」**
