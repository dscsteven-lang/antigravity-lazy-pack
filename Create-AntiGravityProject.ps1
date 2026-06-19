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

    [switch]$CreateGithubRepo,

    [string]$GithubRepoUrl,

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
Write-Host "GitHub 遠端儲存庫建立: $(if ($CreateGithubRepo) { '是' } else { '否' })"
Write-Host "GitHub 遠端儲存庫 URL: $(if ($GithubRepoUrl) { $GithubRepoUrl } else { '無' })"
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
$HasGit = $false
if (Get-Command git -ErrorAction SilentlyContinue) {
    $HasGit = $true
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

# 6. 自動化在 GitHub 上建立或關聯遠端儲存庫
if (($CreateGithubRepo -or -not [string]::IsNullOrEmpty($GithubRepoUrl)) -and $HasGit) {
    Push-Location $ProjectDir
    
    # 確保有 initial commit，否則無法 push
    git rev-parse --quiet --verify HEAD | Out-Null
    if ($LASTEXITCODE -ne 0) {
        git add . | Out-Null
        git commit -m "Initial commit: $ProjectName project initialized by AntiGravity Lazy Pack" | Out-Null
        git branch -M main | Out-Null
    }

    if (-not [string]::IsNullOrEmpty($GithubRepoUrl)) {
        Write-Host "正在關聯現有的 GitHub 儲存庫: $GithubRepoUrl ..." -ForegroundColor Yellow
        $existingRemote = git remote 2>&1
        if ($existingRemote -match "origin") {
            git remote set-url origin $GithubRepoUrl | Out-Null
        } else {
            git remote add origin $GithubRepoUrl | Out-Null
        }
        
        Write-Host "正在推送程式碼至 $GithubRepoUrl ..." -ForegroundColor Yellow
        $pushResult = git push -u origin main 2>&1
        if ($pushResult -match "branch 'main' set up to track" -or $pushResult -match "Everything up-to-date") {
            Write-Host "成功關聯並推送程式碼至現有儲存庫！" -ForegroundColor Green
        } else {
            Write-Warning "推送程式碼失敗，可能因為遠端儲存庫非空或無權限。詳細輸出："
            Write-Host $pushResult -ForegroundColor Red
        }
    }
    elseif ($CreateGithubRepo) {
        Write-Host "正在嘗試在 GitHub 上建立新的同名儲存庫..." -ForegroundColor Yellow
        if (Get-Command gh -ErrorAction SilentlyContinue) {
            $ghResult = gh repo create $FolderName --public --source=. --remote=origin --push 2>&1
            if ($ghResult -match "https://github.com") {
                Write-Host "GitHub 儲存庫建立並推送成功！" -ForegroundColor Green
                Write-Host "連結: https://github.com/dscsteven-lang/$FolderName" -ForegroundColor Green
            } else {
                Write-Warning "自動建立 GitHub 儲存庫失敗。可能因為未登入或已存在同名倉庫。詳細輸出："
                Write-Host $ghResult -ForegroundColor Red
            }
        } else {
            Write-Warning "未在本機找到 GitHub CLI (gh) 指令，無法自動建立儲存庫。"
            Write-Host "請手動在 GitHub 上建立 $FolderName 儲存庫，並在專案目錄執行：" -ForegroundColor Gray
            Write-Host "  git remote add origin https://github.com/<您的帳號>/$FolderName.git" -ForegroundColor Gray
            Write-Host "  git push -u origin main" -ForegroundColor Gray
        }
    }
    
    Pop-Location
}

# 7. 自動向 AntiGravity 2.0 註冊此專案 (寫入專案設定 JSON 檔)
Write-Host "正在將專案註冊至 AntiGravity 2.0 專案清單..." -ForegroundColor Yellow
$ConfigProjectsDir = Join-Path $env:USERPROFILE ".gemini/config/projects"
if (-not (Test-Path $ConfigProjectsDir)) {
    New-Item -ItemType Directory -Path $ConfigProjectsDir -Force | Out-Null
}

# 產生 UUID
$ProjectId = [guid]::NewGuid().ToString()

# 計算 URL 百分比編碼的 folderUri
$UriSegments = $ProjectDir.Replace('\', '/').Split('/')
$EscapedSegments = @()
foreach ($seg in $UriSegments) {
    if ($seg -like "*:") {
        $EscapedSegments += $seg.ToLower().Replace(":", "%3A")
    } else {
        $EscapedSegments += [System.Uri]::EscapeDataString($seg)
    }
}
$FolderUri = "file:///" + ($EscapedSegments -join "/")

$ProjectJson = @"
{
  "id":  "$ProjectId",
  "name":  "$ProjectName",
  "projectResources":  {
    "resources":  [
      {
        "gitFolder":  {
          "folderUri":  "$FolderUri",
          "defaultBranch":  "main"
        }
      }
    ]
  },
  "settings":  {
    "fileAccessPolicy":  "AGENT_SETTING_POLICY_ALLOW",
    "internetPolicy":  "AGENT_SETTING_POLICY_ASK",
    "autoExecutionPolicy":  "CASCADE_COMMANDS_AUTO_EXECUTION_EAGER",
    "artifactReviewMode":  "ARTIFACT_REVIEW_MODE_ALWAYS"
  }
}
"@

$JsonFilePath = Join-Path $ConfigProjectsDir "$ProjectId.json"
[System.IO.File]::WriteAllText($JsonFilePath, $ProjectJson, [System.Text.Encoding]::UTF8)
Write-Host "成功將專案註冊至 AntiGravity 清單！設定檔: $JsonFilePath" -ForegroundColor Green

# 8. 成功輸出
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  AntiGravity 2.0 專案初始化與清單註冊完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "專案路徑: $ProjectDir" -ForegroundColor Green
Write-Host "現在您可以在 AntiGravity 2.0 專案清單中直接看到「$ProjectName」！`n"
