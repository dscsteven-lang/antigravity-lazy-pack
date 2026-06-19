---
name: antigravity-project-initializer
description: AntiGravity 2.0 新專案初始化懶人包。當使用者說「建立新專案」、「初始化專案」、「建立 AntiGravity 專案」時載入此技能。
---

# AntiGravity 2.0 新專案自動初始化技能

當使用者提出要「建立新專案」或「初始化專案」時，AI Agent 應按照以下流程執行：

## 執行流程

### 步驟一：向使用者收集專案設定資訊
請以親切、專業的繁體中文，向使用者詢問以下資訊：
1. **專案名稱** (例如：專案儀表板、個人學習助理)
2. **資料夾名稱** (預設會建立於 `G:\我的雲端硬碟\AntiGravity2\` 下，例如：`project-dashboard`)
3. **專案個性化設定** (例如：希望 Agent 扮演專家級全端工程師、熱情的程式導師、或極簡明快的工作助理？)
4. **是否連線 NotebookLM MCP** (是/否)
5. **是否連線 GitHub CLI** (是/否)
6. **是否啟用生圖指引與 UI 設計規範** (是/否，適用於前端、UI 設計或需要視覺素材之專案)
7. **是否在 GitHub 上自動建立與推送同名儲存庫** (是/否)

### 步驟二：執行專案建立指令
收集齊全資訊後，請在工作區中尋找 `Create-AntiGravityProject.ps1` 的絕對路徑（若在目前懶人包目錄，路徑為 `g:\我的雲端硬碟\AntiGravity2\懶人包\Create-AntiGravityProject.ps1`），並在系統終端機中透過 `run_command` 執行此 PowerShell 腳本。

執行指令格式範例：
```powershell
powershell -ExecutionPolicy Bypass -File "g:\我的雲端硬碟\AntiGravity2\懶人包\Create-AntiGravityProject.ps1" -ProjectName "專案名稱" -FolderName "資料夾名稱" -Personality "個性化設定描述" -EnableNotebookLM -EnableGitHubCLI -CreateGithubRepo -EnableDrawGuideline
```
*(注意：依據使用者的選擇，若為「是」則加入對應參數，若為「否」則在命令中省略該參數)*

### 步驟三：回報結果與開工指引
腳本執行完畢後，請閱讀腳本的輸出，並以繁體中文向使用者回報：
1. 專案資料夾與 `記憶` 備份目錄已成功建立。
2. `.agents/AGENTS.md` 已根據使用者的個人化設定、繁中偏好與備份機制配置完成。
3. 提示使用者如何在新專案中開始工作：
   - 開啟剛建立的專案資料夾作為新的工作區。
   - 在新對話中輸入「開工」來自動載入設定與備份流程。
