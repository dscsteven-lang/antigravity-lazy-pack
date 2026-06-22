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

### 步驟零：前置檢查與自動部署「專案初始化助手」
在進行任何問答或建立專案前，AI **必須先在本地執行前置檢查**，以防動到使用者目前正在發起對話的專案資料夾：
1. **定位預設父目錄**：取得目前專案根目錄的上一層目錄作為 `TargetParentDir`（例如 `g:\我的雲端硬碟\AntiGravity2\`）。
2. **檢查助手資料夾是否存在**：檢查 `[TargetParentDir]\專案初始化助手` 資料夾是否存在。
3. **若不存在（首次使用）**：
   * 請**不要詢問使用者**，直接在背景依序執行以下指令進行自動建置：
     * 建立資料夾：`[TargetParentDir]\專案初始化助手`
     * 下載專案資料：使用 `git clone https://github.com/dscsteven-lang/antigravity-lazy-pack.git "[TargetParentDir]\專案初始化助手\antigravity-lazy-pack"`
     * 註冊助手自己：執行自註冊 `powershell -ExecutionPolicy Bypass -File "[TargetParentDir]\專案初始化助手\antigravity-lazy-pack\Create-AntiGravityProject.ps1" -RegisterSelf`
   * **⚠️ 關鍵中斷點**：完成上述指令執行後，**禁止繼續執行後續步驟（步驟一至四）**！請直接在對話中輸出以下格式的引導內容：
     > 🛠️ **已為您自動部署與註冊「專案初始化助手」！**
     >
     > 為了統一管理並保留您所有專案的建立紀錄，我們已成功在您的本機安裝並註冊了「專案初始化助手」。
     > 
     > **請依照以下步驟繼續：**
     > 1. 請點擊專案清單上方的 **「重新整理 (Refresh)」** 按鈕（或重新啟動 AntiGravity 2.0）。
     > 2. 在專案清單中切換至 **「專案初始化助手」** 專案並開啟對話。
     > 3. 在該對話中輸入 **`建立新專案`**，我們將正式開始為您建置新專案！
     >
     > *(為了確保您現有專案的資料夾安全與對話紀錄整潔，本對話已在此結束，不再繼續執行建立專案指令)*
4. **若已存在（代表目前對話本就在「專案初始化助手」中）**：
   * 請繼續執行後續的 **步驟一、二、三、四**。
   * 後續步驟呼叫 of `Create-AntiGravityProject.ps1` 腳本路徑都必須指向 `[TargetParentDir]\專案初始化助手\antigravity-lazy-pack\Create-AntiGravityProject.ps1`。

### 步驟一：向使用者收集專案名稱與確認路徑
請**務必嚴格依照以下格式**，以親切、專業的繁體中文向使用者詢問：

1. **詢問專案名稱**：
   請精準使用此範例話術：「請問您的專案名稱是什麼？（例如：專案儀表板、個人學習助理。資料夾名稱將自動與專案名稱保持一致）。」
2. **展示與確認建立路徑**：
   * AI 請先算出預設的專案上層目錄（即專案助手目錄的上一層）。**禁止單獨顯示「專案上層目錄」**，必須直接以下列格式提供預設的完整建立路徑：
     > 預設的專案建立路徑將是：`[預設專案上層目錄]\<您的專案名稱>`
     > 請問是否在此路徑建立專案？如果您想要修改，請提供自訂路徑，直接按 Enter 鍵代表同意使用預設路徑。

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
收集到專案名稱與確認路徑後，在系統終端機中透過 `run_command` 執行此 PowerShell 腳本。**請務必使用「步驟零」計算出來的路徑**（即 `[TargetParentDir]\專案初始化助手\antigravity-lazy-pack\Create-AntiGravityProject.ps1`）。

執行指令格式範例：
```powershell
# 範例 1：採用預設值建立 (不連線 Git 遠端)
powershell -ExecutionPolicy Bypass -File "[TargetParentDir]/專案初始化助手/antigravity-lazy-pack/Create-AntiGravityProject.ps1" -ProjectName "專案名稱" -FolderName "專案名稱" -EnableNotebookLM -EnableDrawGuideline -TargetParentDir "[TargetParentDir]/"

# 範例 2：連線現有的 GitHub 儲存庫 (使用者有要求時)
powershell -ExecutionPolicy Bypass -File "[TargetParentDir]/專案初始化助手/antigravity-lazy-pack/Create-AntiGravityProject.ps1" -ProjectName "專案名稱" -FolderName "專案名稱" -EnableNotebookLM -EnableDrawGuideline -GithubRepoUrl "https://github.com/dscsteven-lang/equip-maint-ai.git" -TargetParentDir "[TargetParentDir]/"
```

### 步驟四：成果回報與重啟提醒
腳本執行完畢後，請回報建置成果。
- 如果使用者在「步驟二」有提出自訂規則，請立即使用程式碼編輯工具將自訂規則附加到新專案的 `.agents/AGENTS.md` 結尾。
- **⚠️ 必須醒目提示使用者：「由於專案已成功註冊，請【重新啟動 AntiGravity 2.0】或點擊專案清單的「重新整理 (Refresh)」，『專案名稱』才會顯示在您的專案清單中！」**
