# Create-AntiGravityProject.ps1
# AntiGravity 2.0 新專案自動初始化腳本

param (
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,

    [Parameter(Mandatory=$true)]
    [string]$FolderName,

    [string]$Personality = "未設定特別個性化，請由 AI 自由發揮並依據開發歷程學習調整。",

    [switch]$EnableNotebookLM,

    [switch]$EnableGitHubCLI,

    [switch]$EnableDrawGuideline,

    [string]$TargetParentDir = "G:/我的雲端硬碟/AntiGravity2/"
)

# 設定 PowerShell 輸出為 UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  AntiGravity 2.0 專案初始化腳本開始執行" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "專案名稱: $ProjectName"
Write-Host "資料夾名稱: $FolderName"
Write-Host "預設父路徑: $TargetParentDir"
Write-Host "專案個性化: $Personality"
Write-Host "NotebookLM MCP 連接: $(if ($EnableNotebookLM) { '是' } else { '否' })"
Write-Host "GitHub CLI 連接: $(if ($EnableGitHubCLI) { '是' } else { '否' })"
Write-Host "生圖指引與 UI 規範: $(if ($EnableDrawGuideline) { '是' } else { '否' })"
Write-Host "------------------------------------------"

# 1. 建立完整專案目標路徑
$ProjectDir = Join-Path $TargetParentDir $FolderName
$ProjectDir = [System.IO.Path]::GetFullPath($ProjectDir)

Write-Host "正在建立專案目錄..." -ForegroundColor Yellow
if (-not (Test-Path $ProjectDir)) {
    New-Item -ItemType Directory -Path $ProjectDir -Force | Out-Null
    Write-Host "成功建立資料夾: $ProjectDir" -ForegroundColor Green
} else {
    Write-Host "資料夾已存在: $ProjectDir" -ForegroundColor Yellow
}

# 2. 建立記憶與自訂設定子目錄
$MemoryDir = Join-Path $ProjectDir "記憶"
$TranscriptDir = Join-Path $MemoryDir "對話歷史記憶"
$RuleDir = Join-Path $MemoryDir "自訂規則記憶"
$AgentConfigDir = Join-Path $ProjectDir ".agents"

$DirsToCreate = @($MemoryDir, $TranscriptDir, $RuleDir, $AgentConfigDir)
foreach ($dir in $DirsToCreate) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "建立目錄: $dir" -ForegroundColor Gray
    }
}

# 3. 初始化 Git 儲存庫
Write-Host "正在初始化 Git 儲存庫..." -ForegroundColor Yellow
if (Get-Command git -ErrorAction SilentlyContinue) {
    if (-not (Test-Path (Join-Path $ProjectDir ".git"))) {
        Push-Location $ProjectDir
        git init | Out-Null
        Pop-Location
        Write-Host "Git 儲存庫初始化成功！" -ForegroundColor Green
    } else {
        Write-Host "Git 儲存庫先前已初始化。" -ForegroundColor Yellow
    }
} else {
    Write-Warning "未在本機找到 git 指令，跳過 Git 初始化。請手動安裝 Git。"
}

# 4. 複製與處理模板檔案
$ScriptDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($ScriptDir)) {
    $ScriptDir = Get-Location
}

$GitignoreTemplate = Join-Path $ScriptDir "templates/gitignore.template"
$AgentsTemplate = Join-Path $ScriptDir "templates/AGENTS.md"

# 4.1 複製並建立 .gitignore
$TargetGitignore = Join-Path $ProjectDir ".gitignore"
if (Test-Path $GitignoreTemplate) {
    Copy-Item -Path $GitignoreTemplate -Destination $TargetGitignore -Force
    Write-Host "建立 .gitignore 成功。" -ForegroundColor Green
} else {
    Write-Warning "未找到 gitignore 模板: $GitignoreTemplate，跳過複製。"
}

# 4.2 處理並建立 .agents/AGENTS.md
$TargetAgents = Join-Path $AgentConfigDir "AGENTS.md"
if (Test-Path $AgentsTemplate) {
    $AgentsContent = Get-Content -Path $AgentsTemplate -Raw -Encoding utf8
    
    # 進行參數取代
    $AgentsContent = $AgentsContent.Replace("{{PROJECT_NAME}}", $ProjectName)
    $AgentsContent = $AgentsContent.Replace("{{PROJECT_PERSONALITY}}", $Personality)
    
    $NotebookLMVal = if ($EnableNotebookLM) { "已連線 (請確認 nlm cli 可正常執行)" } else { "未連線 (有需要時可手動設定)" }
    $GithubVal = if ($EnableGitHubCLI) { "已連線 (請確認 gh auth status 可正常執行)" } else { "未連線 (有需要時可手動設定)" }
    
    $DrawGuidelineText = ""
    if ($EnableDrawGuideline) {
        $DrawGuidelineText = @"
## 🎨 生圖指引與 UI 設計規範 (已啟用)
- **工具使用**：當需要設計網頁、UI 介面或產生圖示素材時，使用 generate_image 工具。
- **生圖規範**：
  - 生成 UI 設計圖時，僅產生介面本身，不包含外圍的設備外框（如電腦、手機等形狀），除非使用者明確要求。
  - 設計應使用高質感現代配色，避免純紅、純綠、純藍等單調配色，優先採用漸層、玻璃擬態（Glassmorphism）與和諧的 HSL 調色盤。
  - 將專案引用的正式圖片/素材保存在專案的 assets/ 目錄中，並以小寫及底線命名。
  - **Git 安全**：暫時生成或測試用的臨時圖片，請放置於 .gitignore 排除的目錄（如 temp/ 或 scratch/），切勿直接 commit 到 Git。
"@
    }
    
    $AgentsContent = $AgentsContent.Replace("{{NOTEBOOKLM_STATUS}}", $NotebookLMVal)
    $AgentsContent = $AgentsContent.Replace("{{GITHUB_CLI_STATUS}}", $GithubVal)
    $AgentsContent = $AgentsContent.Replace("{{DRAW_GUIDELINE}}", $DrawGuidelineText)
    
    # 寫入目標檔案 (UTF-8)
    [System.IO.File]::WriteAllText($TargetAgents, $AgentsContent, [System.Text.Encoding]::UTF8)
    Write-Host "建立 .agents/AGENTS.md 成功。" -ForegroundColor Green
} else {
    Write-Warning "未找到 AGENTS.md 模板: $AgentsTemplate，跳過複製。"
}

# 5. 連接 NotebookLM MCP 與 GitHub CLI 狀態確認
if ($EnableGitHubCLI) {
    Write-Host "正在確認 GitHub CLI 登入狀態..." -ForegroundColor Yellow
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        $ghStatus = gh auth status 2>&1
        if ($ghStatus -match "Logged in to") {
            Write-Host "GitHub CLI 已完成授權登入。" -ForegroundColor Green
        } else {
            Write-Host "GitHub CLI 未登入，正開啟瀏覽器授權登入..." -ForegroundColor Yellow
            gh auth login --web --git-protocol https
        }
    } else {
        Write-Warning "未在本機找到 GitHub CLI (gh) 指令，請先安裝 gh。"
    }
}

if ($EnableNotebookLM) {
    Write-Host "正在確認 NotebookLM MCP 狀態..." -ForegroundColor Yellow
    if (Get-Command nlm -ErrorAction SilentlyContinue) {
        $nlmDoctor = nlm doctor 2>&1
        if ($nlmDoctor -match "OK" -or $nlmDoctor -match "successful") {
            Write-Host "NotebookLM MCP CLI 運作正常！" -ForegroundColor Green
        } else {
            Write-Host "nlm 狀態異常，請在 PowerShell 中執行 'nlm login' 重新驗證。" -ForegroundColor Yellow
        }
    } else {
        Write-Warning "未在本機找到 nlm 指令。請參考懶人包 README 安裝 notebooklm-mcp-cli。"
    }
}

# 6. 成功輸出
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  AntiGravity 2.0 專案初始化完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "專案路徑: $ProjectDir" -ForegroundColor Green
Write-Host "現在您可以在 AntiGravity 2.0 中開啟此專案資料夾作為工作區並輸入「開工」開始工作！`n"
