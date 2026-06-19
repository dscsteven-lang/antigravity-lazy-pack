# Create-AntiGravityProject.ps1
# AntiGravity 2.0 新專案自動初始化腳本

param (
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,

    [Parameter(Mandatory=$true)]
    [string]$FolderName,

    [string]$Personality = "",

    [switch]$EnableNotebookLM,

    [switch]$EnableGitHubCLI,

    [switch]$CreateGithubRepo,

    [string]$GithubRepoUrl,

    [string]$GitBranchName,

    [switch]$EnableDrawGuideline,

    [string]$TargetParentDir = ""
)

# 在 param 區塊外部設定含有中文的預設值，避免 Windows PowerShell 5.1 解析 param block 時發生編碼逃逸錯誤
if ([string]::IsNullOrEmpty($Personality)) {
    $Personality = "未設定特別個性化，請由 AI 自由發揮並依據開發歷程學習調整。"
}
if ([string]::IsNullOrEmpty($TargetParentDir)) {
    $TargetParentDir = "G:/我的雲端硬碟/AntiGravity2/"
}

# 設定 PowerShell 輸出為 UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 0. 本機環境與元件診斷
$GitInstalled = $false
$GitVersion = "未安裝"
if (Get-Command git -ErrorAction SilentlyContinue) {
    $GitInstalled = $true
    $GitVersion = (git --version).Trim()
}

$GhInstalled = $false
$GhLoggedIn = $false
$GhUser = ""
if (Get-Command gh -ErrorAction SilentlyContinue) {
    $GhInstalled = $true
    $ghAuth = gh auth status 2>&1 | Out-String
    if ($ghAuth -match "Logged in to") {
        $GhLoggedIn = $true
        if ($ghAuth -match "as ([^\s]+)") {
            $GhUser = $Matches[1]
        }
    }
}

$NlmInstalled = $false
$NlmStatus = "未安裝"
if (Get-Command nlm -ErrorAction SilentlyContinue) {
    $NlmInstalled = $true
    $nlmDoc = nlm doctor 2>&1 | Out-String
    if ($nlmDoc -match "successful" -or $nlmDoc -match "OK") {
        $NlmStatus = "正常運作"
    } else {
        $NlmStatus = "未登入或狀態異常"
    }
}

# 自動決定程式碼子目錄名稱
$RepoSubDirName = ""
if (-not [string]::IsNullOrEmpty($GithubRepoUrl)) {
    $RepoSubDirName = ($GithubRepoUrl.Split('/')[-1]).Replace(".git", "")
} elseif ($CreateGithubRepo) {
    $RepoSubDirName = $FolderName
} else {
    $RepoSubDirName = "code"
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  AntiGravity 2.0 專案初始化腳本開始執行" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "專案名稱: $ProjectName"
Write-Host "專案工作區目錄: $FolderName"
Write-Host "共享程式碼子目錄: $RepoSubDirName"
Write-Host "預設父路徑: $TargetParentDir"
Write-Host "專案個性化: $Personality"
Write-Host "NotebookLM MCP 連接: $(if ($EnableNotebookLM) { '是' } else { '否' })"
Write-Host "GitHub CLI 連接: $(if ($EnableGitHubCLI) { '是' } else { '否' })"
Write-Host "GitHub 遠端儲存庫建立: $(if ($CreateGithubRepo) { '是' } else { '否' })"
Write-Host "GitHub 遠端儲存庫 URL: $(if ($GithubRepoUrl) { $GithubRepoUrl } else { '無' })"
Write-Host "指定或自動生成的分支: $(if ($GitBranchName) { $GitBranchName } else { '自動生成' })"
Write-Host "生圖指引與 UI 規範: $(if ($EnableDrawGuideline) { '是' } else { '否' })"
Write-Host "------------------------------------------"

# 1. 建立完整專案工作區路徑與程式碼子目錄路徑
$ProjectDir = Join-Path $TargetParentDir $FolderName
$ProjectDir = [System.IO.Path]::GetFullPath($ProjectDir)
$RepoDir = Join-Path $ProjectDir $RepoSubDirName

# 偵測 Git 是否可用
$HasGit = $GitInstalled

# 2. 建立外層本地專案目錄 (不進版控，僅作為本地工作區)
Write-Host "正在建立外層專案工作區..." -ForegroundColor Yellow
if (-not (Test-Path $ProjectDir)) {
    New-Item -ItemType Directory -Path $ProjectDir -Force | Out-Null
    Write-Host "成功建立工作區資料夾: $ProjectDir" -ForegroundColor Green
} else {
    Write-Host "工作區資料夾已存在: $ProjectDir" -ForegroundColor Yellow
}

# 3. 建立記憶與自訂設定子目錄 (在外層工作區，本地專屬，不上傳版控)
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

# 4. 在內層子目錄初始化 Git / Clone 程式碼倉庫
if ($HasGit) {
    if (-not [string]::IsNullOrEmpty($GithubRepoUrl)) {
        if (-not (Test-Path $RepoDir) -or -not (Test-Path (Join-Path $RepoDir ".git"))) {
            # 偵測是否已安裝並登入 GitHub CLI (gh)
            $HasGhLoggedIn = $false
            if (Get-Command gh -ErrorAction SilentlyContinue) {
                $ghStatus = gh auth status 2>&1 | Out-String
                if ($ghStatus -match "Logged in to") {
                    $HasGhLoggedIn = $true
                }
            }

            if ($HasGhLoggedIn) {
                Write-Host "偵測到 GitHub CLI 已登入，將使用 gh repo clone 進行複製（可自動處理私有庫憑證）..." -ForegroundColor Gray
                gh repo clone $GithubRepoUrl $RepoDir
            } else {
                Write-Host "使用標準 git clone 複製儲存庫..." -ForegroundColor Gray
                git clone $GithubRepoUrl $RepoDir
            }

            if ($LASTEXITCODE -eq 0) {
                Write-Host "儲存庫複製成功！" -ForegroundColor Green
            } else {
                Write-Host ""
                Write-Host "======================================================================" -ForegroundColor Red
                Write-Host "❌ 儲存庫複製失敗！" -ForegroundColor Red
                Write-Host "======================================================================" -ForegroundColor Red
                Write-Host "如果您所連接的是私有儲存庫（Private Repository）："
                Write-Host "由於 AI Agent 的執行環境為「非互動式」，Git 預設無法為您彈出驗證/登入視窗。"
                Write-Host ""
                Write-Host "💡 請透過以下任一方法解決後，再重新執行一次："
                Write-Host "  👉 方法一：在此電腦的終端機（PowerShell）中手動執行一次登入："
                Write-Host "             gh auth login"
                Write-Host "             （登入完成後，腳本將能自動讀取憑證並順利執行）"
                Write-Host ""
                Write-Host "  👉 方法二：在此電腦的終端機中，手動複製該儲存庫（藉此彈出登入視窗並儲存憑證）："
                Write-Host "             git clone $GithubRepoUrl `"$RepoDir`""
                Write-Host "             （手動 clone 成功後，再重新執行本初始化腳本，腳本會自動跳過 clone 步驟）"
                Write-Host "======================================================================" -ForegroundColor Red
                exit 1
            }
        } else {
            Write-Host "子目錄已存在且已為 Git 儲存庫，跳過複製步驟。" -ForegroundColor Yellow
        }
    } else {
        if (-not (Test-Path $RepoDir)) {
            New-Item -ItemType Directory -Path $RepoDir -Force | Out-Null
        }
        if (-not (Test-Path (Join-Path $RepoDir ".git"))) {
            Write-Host "正在子目錄初始化本地 Git 儲存庫..." -ForegroundColor Yellow
            Push-Location $RepoDir
            git init | Out-Null
            Pop-Location
            Write-Host "子目錄 Git 儲存庫初始化成功！" -ForegroundColor Green
        } else {
            Write-Host "子目錄 Git 儲存庫先前已初始化。" -ForegroundColor Yellow
        }
    }
} else {
    if (-not (Test-Path $RepoDir)) {
        New-Item -ItemType Directory -Path $RepoDir -Force | Out-Null
    }
    Write-Warning "未在本機找到 git 指令，跳過 Git 初始化。"
}

# 5. 複製與處理模板檔案
$ScriptDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($ScriptDir)) {
    $ScriptDir = Get-Location
}

$GitignoreTemplate = Join-Path $ScriptDir "templates/gitignore.template"
$AgentsTemplate = Join-Path $ScriptDir "templates/AGENTS.md"

# 5.1 處理子目錄內部的 .gitignore (若已有舊檔，則安全附加排除規則，防止覆蓋原有設定)
$TargetGitignore = Join-Path $RepoDir ".gitignore"
if (Test-Path $GitignoreTemplate) {
    if (-not (Test-Path $RepoDir)) {
        New-Item -ItemType Directory -Path $RepoDir -Force | Out-Null
    }
    
    if (Test-Path $TargetGitignore) {
        $ExistingContent = Get-Content -Path $TargetGitignore -Raw -Encoding utf8
        if ($ExistingContent -notmatch "AntiGravity temporary files") {
            Write-Host "正在將 AntiGravity 快取排除規則附加至子目錄的 .gitignore 中..." -ForegroundColor Yellow
            $TemplateContent = Get-Content -Path $GitignoreTemplate -Raw -Encoding utf8
            $MergedContent = $ExistingContent + "`n`n# ==========================================`n# AntiGravity 2.0 自動附加快取排除規則`n# ==========================================`n" + $TemplateContent
            [System.IO.File]::WriteAllText($TargetGitignore, $MergedContent, [System.Text.Encoding]::UTF8)
            Write-Host "已成功合併子目錄的 .gitignore 規則。" -ForegroundColor Green
        } else {
            Write-Host "子目錄 .gitignore 中已包含 AntiGravity 規則，跳過合併。" -ForegroundColor Gray
        }
    } else {
        Copy-Item -Path $GitignoreTemplate -Destination $TargetGitignore -Force
        Write-Host "建立子目錄 .gitignore 成功。" -ForegroundColor Green
    }
} else {
    Write-Warning "未找到 gitignore 模板: $GitignoreTemplate，跳過複製。"
}

# 5.2 處理並建立外層的 .agents/AGENTS.md (讓 AI 運作在工作區根目錄，但 Git 指向子目錄)
$TargetAgents = Join-Path $AgentConfigDir "AGENTS.md"
if (Test-Path $AgentsTemplate) {
    $AgentsContent = Get-Content -Path $AgentsTemplate -Raw -Encoding utf8
    
    # 進行參數取代
    $AgentsContent = $AgentsContent.Replace("{{PROJECT_NAME}}", $ProjectName)
    $AgentsContent = $AgentsContent.Replace("{{PROJECT_PERSONALITY}}", $Personality)
    
    # 決定寫入規則檔中的子目錄名稱
    $AgentsContent = $AgentsContent.Replace("{{REPO_SUBDIR}}", $RepoSubDirName)
    
    $NotebookLMVal = if ($NlmInstalled -and ($NlmStatus -eq "正常運作")) { "已連線且本機可用 (nlm 狀態: $NlmStatus)" } else { "未連線，請確認本機是否安裝且登入 notebooklm-mcp-cli" }
    $GithubVal = if ($GhInstalled -and $GhLoggedIn) { "已連線且本機可用 (帳號: $GhUser)" } else { "未連線，請確認本機是否安裝且登入 GitHub CLI" }
    
    $DrawGuidelineText = ""
    if ($EnableDrawGuideline) {
        $DrawGuidelineText = @"
## 🎨 生圖指引與 UI 設計規範
- **工具使用**：當需要設計網頁、介面或產生圖示素材時，使用 generate_image 工具。
- **生圖規範**：
  - 生成介面設計圖時，僅產生介面本身，不包含外圍的設備外框（例如電腦、手機等形狀），除非使用者明確要求。
  - 設計應使用高質感現代配色，避免純紅、純綠、純藍等單調配色，優先採用漸層、玻璃擬態與和諧的調色盤。
  - 將專案引用的正式圖片與素材保存在專案的 assets 目錄中，並以小寫及底線命名。
  - **Git 安全**：暫時生成或測試用的臨時圖片，請放置於排除的目錄（例如 temp 或 scratch），切勿直接提交到 Git。
"@
    }
    
    $AgentsContent = $AgentsContent.Replace("{{NOTEBOOKLM_STATUS}}", $NotebookLMVal)
    $AgentsContent = $AgentsContent.Replace("{{GITHUB_CLI_STATUS}}", $GithubVal)
    $AgentsContent = $AgentsContent.Replace("{{DRAW_GUIDELINE}}", $DrawGuidelineText)
    
    # 寫入目標檔案 (UTF-8)
    [System.IO.File]::WriteAllText($TargetAgents, $AgentsContent, [System.Text.Encoding]::UTF8)
    Write-Host "建立外層 .agents/AGENTS.md 成功。" -ForegroundColor Green
} else {
    Write-Warning "未找到 AGENTS.md 模板: $AgentsTemplate，跳過複製。"
}

# 6. 連接 GitHub CLI 授權登入（若使用者啟用且未登入，主動開啟瀏覽器登入）
if ($EnableGitHubCLI -and -not $GhLoggedIn) {
    if ($GhInstalled) {
        Write-Host "GitHub CLI 未登入，正開啟瀏覽器授權登入..." -ForegroundColor Yellow
        gh auth login --web --git-protocol https
        # 重新整理登入狀態
        $ghAuth = gh auth status 2>&1 | Out-String
        if ($ghAuth -match "Logged in to") {
            $GhLoggedIn = $true
            if ($ghAuth -match "as ([^\s]+)") { $GhUser = $Matches[1] }
        }
    }
}

# 7. 自動化在子目錄中進行 Git 分支建立、提交與推送
if ($HasGit -and (Test-Path $RepoDir)) {
    Push-Location $RepoDir
    
    if (-not [string]::IsNullOrEmpty($GithubRepoUrl)) {
        # 情況 A: 關聯既有倉庫，強制建立獨立分支
        
        # 7.1 自動計算分支名稱
        $TargetBranch = $GitBranchName
        if ([string]::IsNullOrEmpty($TargetBranch)) {
            # 獲取 Git 使用者名稱並過濾空格
            $GitUser = (git config user.name)
            if ($null -eq $GitUser) { $GitUser = "" }
            $GitUser = $GitUser.Trim() -replace '\s+', '-'
            
            if ([string]::IsNullOrEmpty($GitUser)) {
                $GitUser = $env:USERNAME
            }
            if ([string]::IsNullOrEmpty($GitUser)) {
                $GitUser = "developer"
            }
            $TargetBranch = "$GitUser/setup-agents"
        }
        
        Write-Host "為了團隊協作安全，強制切換至專屬分支: $TargetBranch ..." -ForegroundColor Yellow
        git checkout -B $TargetBranch | Out-Null
        
        # 7.2 提交變更
        $gitStatus = git status --porcelain 2>&1
        if (-not [string]::IsNullOrEmpty($gitStatus)) {
            Write-Host "正在提交分支初始化設定..." -ForegroundColor Yellow
            git add . | Out-Null
            git commit -m "Configure AntiGravity rules and memory settings on branch $TargetBranch" | Out-Null
        }
        
        # 7.3 推送至專屬分支 (安全推送，不會污染 main 分支)
        Write-Host "正在將專屬分支推送至 GitHub..." -ForegroundColor Yellow
        $pushResult = git push -u origin $TargetBranch 2>&1
        if ($LASTEXITCODE -eq 0 -or $pushResult -match "branch '.*' set up to track") {
            Write-Host "成功推送分支 '$TargetBranch' 至 GitHub！請至 GitHub 建立 Pull Request 合併至 main。" -ForegroundColor Green
        } else {
            Write-Warning "推送分支失敗，詳細輸出："
            Write-Host $pushResult -ForegroundColor Red
        }
    }
    else {
        # 情況 B: 全新倉庫 (直接提交至 main 作為預設分支)
        $gitStatus = git status --porcelain 2>&1
        if (-not [string]::IsNullOrEmpty($gitStatus)) {
            Write-Host "正在提交本地新增的設定檔..." -ForegroundColor Yellow
            git add . | Out-Null
            git commit -m "Configure AntiGravity rules and memory settings" | Out-Null
        }

        if ($CreateGithubRepo) {
            Write-Host "正在嘗試在 GitHub 上建立新的同名儲存庫..." -ForegroundColor Yellow
            if (Get-Command gh -ErrorAction SilentlyContinue) {
                git branch -M main | Out-Null
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
            }
        }
    }
    
    Pop-Location
}

# 8. 自動向 AntiGravity 2.0 註冊此專案 (將「外層工作區根目錄」加入專案清單)
Write-Host "正在將專案註冊至 AntiGravity 2.0 專案清單..." -ForegroundColor Yellow
$ConfigProjectsDir = Join-Path $env:USERPROFILE ".gemini/config/projects"
if (-not (Test-Path $ConfigProjectsDir)) {
    New-Item -ItemType Directory -Path $ConfigProjectsDir -Force | Out-Null
}

# 產生 UUID
$ProjectId = [guid]::NewGuid().ToString()

# 計算外層工作區路徑的 URL 百分比編碼 folderUri (強制磁碟代號為小寫)
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
[System.IO.File]::WriteAllText($JsonFilePath, $ProjectJson)
Write-Host "成功將專案註冊至 AntiGravity 清單！設定檔: $JsonFilePath" -ForegroundColor Green

# 8.5 輸出開發環境與相容性診斷報告
Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "             🛠️  本機開發環境與相容性診斷報告" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# Git 檢查
if ($GitInstalled) {
    Write-Host " [v] Git 版本控制   : 已安裝 ($GitVersion)" -ForegroundColor Green
} else {
    Write-Host " [x] Git 版本控制   : 未安裝！此機台將無法使用任何版本控制與自動分支機制。" -ForegroundColor Red
    Write-Host "     👉 建議安裝指令：winget install --id Git.Git" -ForegroundColor Gray
}

# GitHub CLI 檢查
if ($GhInstalled) {
    if ($GhLoggedIn) {
        Write-Host " [v] GitHub CLI     : 已安裝，且已完成授權登入 (帳號: $GhUser)" -ForegroundColor Green
    } else {
        Write-Host " [!] GitHub CLI     : 已安裝，但「尚未登入」！" -ForegroundColor Yellow
        Write-Host "     👉 建議登入指令：gh auth login" -ForegroundColor Gray
    }
} else {
    Write-Host " [x] GitHub CLI     : 未安裝！(若需要自動建立 GitHub 儲存庫或安全存取私有庫則為必備)" -ForegroundColor Red
    Write-Host "     👉 建議安裝指令：winget install --id GitHub.cli" -ForegroundColor Gray
}

# NotebookLM 檢查
if ($NlmInstalled) {
    if ($NlmStatus -eq "正常運作") {
        Write-Host " [v] NotebookLM MCP : 已安裝，且連線正常 (nlm doctor: OK)" -ForegroundColor Green
    } else {
        Write-Host " [!] NotebookLM MCP : 已安裝，但「連線狀態異常」($NlmStatus)！" -ForegroundColor Yellow
        Write-Host "     👉 建議登入指令：nlm login" -ForegroundColor Gray
    }
} else {
    Write-Host " [x] NotebookLM MCP : 未安裝！此專案將無法自動同步資料至 NotebookLM 記憶庫。" -ForegroundColor Red
    Write-Host "     👉 建議安裝指令：" -ForegroundColor Gray
    Write-Host "         1. npm install -g notebooklm-mcp-cli" -ForegroundColor Gray
    Write-Host "         2. nlm login" -ForegroundColor Gray
}
Write-Host "======================================================================" -ForegroundColor Cyan

# 9. 成功輸出
Write-Host "==========================================" -ForegroundColor Green
Write-Host "  AntiGravity 2.0 專案初始化與清單註冊完成！" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "專案路徑: $ProjectDir" -ForegroundColor Green
Write-Host "現在您可以在 AntiGravity 2.0 專案清單中直接看到「$ProjectName」！`n"
