---
name: antigravity-project-initializer
description: AntiGravity 2.0 新專案自動初始化工具。當使用者說「建立新專案」、「初始化專案」、「建立 AntiGravity 專案」時載入此技能。
---

# AntiGravity 2.0 新專案自動初始化技能

> [!IMPORTANT]
> **本技能禁止啟動 Planning Mode**：
> 本任務（新專案初始化）屬於一鍵式自動化腳本執行，**禁止為此建立任何實作計畫（如 `implementation_plan.md`）！**請直接遵循下述的「執行流程」，在對話中向使用者詢問極簡問題，並立即透過 `run_command` 呼叫腳本執行。

當使用者提出要「建立新專案」或「初始化專案」時，AI Agent 應按照以下流程執行：

## 執行流程

### 步驟一：向使用者收集專案名稱與確認路徑
請以親切、專業的繁體中文，向使用者詢問以下資訊：
1. **專案名稱** (例如：專案儀表板、個人學習助理。資料夾名稱將自動與專案名稱保持一致)。
2. **確認建立路徑**：
   * AI 請先找出**「當前工作目錄的上層目錄」**作為預設的專案父目錄。例如，若目前本對話位於 `D:\AntiGravity2\專案初始化助手`，則上層目錄預設為 `D:\AntiGravity2\`。
   * 向使用者展示預設的專案路徑：`[上層目錄預設]\<專案名稱>`，並詢問：「請問是否在此路徑建立專案？如果您想要修改，請提供自訂路徑，直接按 Enter 鍵代表同意使用預設路徑。」

💡 **同時告知預設選項**：
向使用者說明，為了加速專案建立，以下設定將**直接採用預設值**：
* **連線 NotebookLM MCP**：預設為 **是** (連線)。
* **啟用生圖指引與 UI 設計規範**：預設為 **是** (啟用)。
* **GitHub 與遠端 Git**：預設為 **不需要**。
  *(💡 若您需要，請在回覆時告訴我：1. **關聯現有的 GitHub**：請提供「儲存庫 URL（例如 `https://github.com/username/repo.git`）」；2. **自動新建 GitHub 儲存庫**：請告知我新建，並確保本機已安裝與登入 GitHub CLI `gh`，AI 將自動以專案資料夾名稱在您的 GitHub 建立同名公開儲存庫。)*
* **專案個性化設定**：預設為「未設定特別個性化，請由 AI 自由發揮並依據開發歷程學習調整。」
* *（註：若您需要對上述預設選項進行修改，或者想新增任何專屬的規則，請在回答專案名稱時一併告訴我！）*

### 步驟二：確認核心規則
向使用者告知 `.agents/AGENTS.md` 將內建的預設核心規則：
- 思考與對話一律使用繁體中文。
- 開工時自動讀取 `記憶/` 中的最新歷史備份與規則以還原脈絡。
- 收工時自動備份對話紀錄與自訂規則至 `記憶/` 下。
- 本地「記憶」與「規則」安全隔離於 Git 外部，不進版控、不上傳。

### 步驟三：執行專案建立指令
收集到專案名稱與確認路徑後，在系統終端機中透過 `run_command` 執行此 PowerShell 腳本。

執行指令格式範例：
```powershell
# 範例 1：採用預設值建立 (不連線 Git 遠端)
powershell -ExecutionPolicy Bypass -File "[專案初始化助手目錄]/Create-AntiGravityProject.ps1" -ProjectName "專案名稱" -FolderName "專案名稱" -EnableNotebookLM -EnableDrawGuideline -TargetParentDir "[上層目錄路徑]/"

# 範例 2：連線現有的 GitHub 儲存庫 (使用者有要求時)
powershell -ExecutionPolicy Bypass -File "[專案初始化助手目錄]/Create-AntiGravityProject.ps1" -ProjectName "專案名稱" -FolderName "專案名稱" -EnableNotebookLM -EnableDrawGuideline -GithubRepoUrl "https://github.com/dscsteven-lang/equip-maint-ai.git" -TargetParentDir "[上層目錄路徑]/"
```

### 步驟四：成果回報與重啟提醒
腳本執行完畢後，請回報建置成果。
- 如果使用者在「步驟二」有提出自訂規則，請立即使用程式碼編輯工具將自訂規則附加到新專案的 `.agents/AGENTS.md` 結尾。
- **⚠️ 必須醒目提示使用者：「由於專案已成功註冊，請【重新啟動 AntiGravity 2.0】或點擊專案清單的「重新整理 (Refresh)」，『專案名稱』才會顯示在您的專案清單中！」**
