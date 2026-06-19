# AntiGravity 2.0 新專案建立懶人包

本懶人包旨在協助使用者在 **AntiGravity 2.0**（或相容之 AI Agent）環境下，快速建立與初始化全新的開發專案。

透過此懶人包，您可以快速建立符合統一規範的專案結構，包含自動化的**繁體中文偏好設定**、**開工/收工備份機制**、以及 **NotebookLM MCP / GitHub CLI 連接狀態整合**。

---

## 📂 專案初始化後的目錄結構

每次建立新專案時，將會自動在預設路徑 `G:\我的雲端硬碟\AntiGravity2\<專案資料夾>\` 下建立以下目錄與檔案。為了避免團隊協作時將個人的「歷史對話記憶」與「自訂規則」同步上傳到 GitHub，我們採用了**外層本地工作區**與**內層共享程式碼子目錄**的分離設計：

```text
專案工作區根目錄/                     # 本地專屬，不上傳版控
├── .agents/
│   └── AGENTS.md                  # 本地端專案層級的 AI 規則（繁中偏好、開工收工流程）
├── 記憶/                          # 存放與管理本專案的對話紀錄與自訂規則
│   ├── 對話歷史記憶/              # [自動備份] 每次收工時備份當前對話的 transcript.jsonl
│   └── 自訂規則記憶/              # [自動備份] 備份並累積長期學習到的自訂規則
└── <共享程式碼子目錄>/               # 這是 Git 程式碼儲存庫（依據 GitHub 倉庫名稱命名）
    ├── .git/                      # [Git] 程式碼的版控目錄
    ├── .gitignore                 # [Git] 已合併 AntiGravity 快取排除規則的設定檔
    └── ...                        # 您的專案程式碼檔案
```

### 🔒 團隊協作與分支保護機制
* **外層隔離**：外層的 `記憶/` 與 `.agents/` 目錄不在 `<共享程式碼子目錄>` 之下，因此**絕對不會**被 Git 追蹤或上傳到 GitHub，確保每位開發者的對話歷史與個人規則維持獨立。
* **強制分支**：當您選擇**連接現有的 GitHub 儲存庫**時，腳本會自動將其 clone 到專案的子目錄中，並**強制建立一個專屬分支**（命名為 `[Git使用者名稱]/setup-agents` 或自訂分支名稱）並推送至 GitHub。這能防止開發者不小心直接 push 到主分支（`main`），保護共享的專案程式碼。

---

## 🛠️ 事前準備
請確保您的系統已安裝以下工具（特別是 Windows 環境）：
1. **Git**：用於專案版控。
2. **GitHub CLI (gh)**：若要整合 GitHub（選用）。
3. **nlm (NotebookLM MCP CLI)**：若要整合 NotebookLM MCP（選用）。

---

## 🚀 使用方式

此懶人包提供兩種專案初始化方式：

### 方式一：直接貼給 AI 自動建立（最推薦）

您可以直接將此 GitHub 儲存庫網址複製，在 AntiGravity 對話中貼給 AI 並輸入以下指令：

```text
這是我的 AntiGravity 2.0 專案初始化懶人包：
https://github.com/<您的用戶名>/antigravity-lazy-pack

請讀取其中的 SKILL.md 技能，並協助我初始化一個新專案。
```

**AI 將會自動執行以下互動流程**：
1. 詢問您的 **專案名稱**。
2. 詢問 **資料夾名稱**（例如：`my-new-app`）。
3. 詢問專案的 **個性化偏好**（例如：扮演嚴謹的後端架構師）。
4. 詢問是否啟用 **NotebookLM MCP**、**GitHub CLI** 以及 **生圖指引與 UI 規範**。
5. AI 會自動在背景呼叫 PowerShell 腳本，為您一鍵建立完成！

---

### 方式二：在 PowerShell 中手動執行

如果您想在終端機中手動執行建立，可以在本懶人包目錄下開啟 PowerShell，並執行以下指令：

```powershell
# 解除 PowerShell 腳本執行限制並執行初始化
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# 執行初始化 (若要啟用 NotebookLM、GitHub CLI 或生圖指引，直接帶入對應參數即可)
.\Create-AntiGravityProject.ps1 `
  -ProjectName "我的新專案" `
  -FolderName "my-new-project" `
  -Personality "扮演一位專業的 React 前端工程師，回答力求簡潔並給出最佳實踐。" `
  -EnableNotebookLM `
  -EnableGitHubCLI `
  -CreateGithubRepo `
  -EnableDrawGuideline
```

#### 可用參數說明：
- `-ProjectName` (必要)：專案的中文/英文名稱。
- `-FolderName` (必要)：建立於 `G:\我的雲端硬碟\AntiGravity2\` 底下的資料夾名稱。
- `-Personality` (選用)：指定此專案 AI 的獨特個性。
- `-EnableNotebookLM` (選用開關)：若加入此參數，代表啟用 NotebookLM MCP。
- `-EnableGitHubCLI` (選用開關)：若加入此參數，代表啟用 GitHub CLI。
- `-CreateGithubRepo` (選用開關)：若加入此參數，且本機有登入 `gh`，會自動在 GitHub 上建立同名公開儲存庫並 Push。
- `-EnableDrawGuideline` (選用開關)：若加入此參數，代表啟用生圖與 UI 設計指引規範。
- `-TargetParentDir` (選用)：預設為 `G:\我的雲端硬碟\AntiGravity2/`，可手動指定其他父目錄。

---

## 🔄 核心機制：開工與收工備份

新專案的 `.agents/AGENTS.md` 中已經內建了專屬的開收工流程規範：

1. **開工 (Start Work)**：
   當您在對話中輸入「**開工**」時，AI Agent 會自動讀取專案內的 `.agents/AGENTS.md`，同步長期記憶與專案背景，並確認今日開發目標。
2. **收工 (Finish Work)**：
   當您輸入「**收工**」或結束工作時，AI Agent 會**自動定位當前對話本機的對話歷史紀錄** (`transcript.jsonl`)，將其複製至 `記憶/對話歷史記憶/` 下備份；同時也會將當前的 `.agents/AGENTS.md` 規則備份至 `記憶/自訂規則記憶/` 下。這能確保專案的對話紀錄與規則永遠與專案程式碼同步保存！
