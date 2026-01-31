# =============================================================================
# PowerShell Profile - Path Fixer & Enhanced UI
# =============================================================================

# 除錯訊息：讓你知道 Profile 真的有跑
Write-Host ">>> Profile Loading... (Term: $env:TERM_PROGRAM)" -ForegroundColor DarkGray

if ($env:TERM_PROGRAM -eq "vscode") {
    # -------------------------------------------------------------------------
    # 情境 A: VS Code 整合終端機
    # -------------------------------------------------------------------------
    $machine = [Environment]::GetEnvironmentVariable("Path","Machine")
    $user    = [Environment]::GetEnvironmentVariable("Path","User")
    $base    = "$machine;$user"

    $baseList = $base -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
    $origList = $env:Path -split ';' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }

    $merged = New-Object System.Collections.Generic.List[string]
    foreach ($p in $baseList) { if (-not $merged.Contains($p)) { $null = $merged.Add($p) } }
    foreach ($p in $origList) { if (-not $merged.Contains($p)) { $null = $merged.Add($p) } }

    $env:Path = ($merged -join ';')
    Write-Host " [VS Code] PATH merged successfully." -ForegroundColor Cyan

} else {
    # -------------------------------------------------------------------------
    # 情境 B: Tabby / 獨立 PowerShell 視窗
    # -------------------------------------------------------------------------
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    Write-Host " [System] PATH forced reset from Registry." -ForegroundColor Green
}

# =============================================================================
# 其他工具初始化 (Conda, Chocolatey, etc.)
# =============================================================================

#region conda initialize
If (Test-Path "C:\Users\jack3\miniconda3\Scripts\conda.exe") {
    (& "C:\Users\jack3\miniconda3\Scripts\conda.exe" "shell.powershell" "hook") | Out-String | ?{$_} | Invoke-Expression
}
#endregion

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

# OpenSpec completion
if (Test-Path "C:\Users\jack3\Documents\PowerShell\OpenSpecCompletion.ps1") {
    . "C:\Users\jack3\Documents\PowerShell\OpenSpecCompletion.ps1"
}

# =============================================================================
# 互動功能增強 (PSReadLine - 類似 Zsh 的記憶功能)
# =============================================================================
if (Get-Module -ListAvailable PSReadLine) {
    # 設定預測來源為「歷史紀錄」
    Set-PSReadLineOption -PredictionSource History

    # 設定預測顯示風格為「清單模式」 (若喜歡 Zsh 灰字感，可將 ListView 改為 InlineView)
    Set-PSReadLineOption -PredictionViewStyle ListView

    # 額外建議：設定 F2 鍵可以切換 ViewStyle (在清單與行內預測間切換)
    Set-PSReadLineKeyHandler -Key F2 -Function SwitchPredictionView

    Write-Host " [UI] PSReadLine History Prediction Enabled." -ForegroundColor Magenta
}

# =============================================================================
# 3. 外觀與導航增強 (讓 PowerShell 像 Zsh 的關鍵)
# =============================================================================

# [Starship] 現代化提示字元 (需先安裝 Starship)
# 它會接管原本單調的 "PS C:\Users...>"
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# [Terminal-Icons] 讓 ls 顯示檔案圖示 (需先 Install-Module Terminal-Icons)
if (Get-Module -ListAvailable Terminal-Icons) {
    Import-Module Terminal-Icons
}

# [Z-Location] 智慧跳轉 (需先 Install-Module ZLocation)
# 用法: 輸入 "z github" 即可跳到 C:\Users\xxx\Documents\GitHub
if (Get-Module -ListAvailable ZLocation) {
    Import-Module ZLocation
    # 將別名設為 z (預設也是 z，這裡確保習慣一致)
    Set-Alias z Invoke-ZLocation -ErrorAction SilentlyContinue
}

# =============================================================================
# 4. 實用別名與函式 (Muscle Memory)
# =============================================================================

# 讓習慣 Linux/Mac 的手指不打結
Set-Alias ll Get-ChildItem -ErrorAction SilentlyContinue
Set-Alias grep Select-String -ErrorAction SilentlyContinue
Set-Alias which Get-Command -ErrorAction SilentlyContinue

# [mkcd] 建立資料夾並直接進入
function mkcd {
    param ( [string]$Path )
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location $Path
}

# [profile] 快速編輯設定檔 (不用每次都打 notepad $PROFILE)
function pro { code $PROFILE }
function reload { . $PROFILE } # 快速重載設定

# =============================================================================
# 5. 互動功能增強 (PSReadLine + FZF)
# =============================================================================
if (Get-Module -ListAvailable PSReadLine) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView

    # [顏色微調] 讓預測的文字在深色背景更明顯 (淡灰色)
    Set-PSReadLineOption -Colors @{
        "InlinePrediction" = "#808080"
    }

    # [鍵盤操作]
    # F2: 切換顯示模式 (ListView <-> Inline)
    Set-PSReadLineKeyHandler -Key F2 -Function SwitchPredictionView
    # Tab: 自動完成 (選單式)
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

# [PSFzf] 終極歷史搜尋 (需安裝 fzf 和 PSFzf)
# 這會覆蓋預設的 Ctrl+R，提供更強的搜尋體驗
# 下載 fzf: https://github.com/junegunn/fzf/releases
if (Get-Module -ListAvailable PSFzf) {
    # 只有在 fzf 存在於 PATH 時才載入
    if (Get-Command fzf -ErrorAction SilentlyContinue) {
        Import-Module PSFzf
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
        Write-Host " [UI] PSFzf loaded with Ctrl+T (file) / Ctrl+R (history)." -ForegroundColor DarkCyan
    } else {
        Write-Host " [Warning] fzf binary not found. Install from: https://github.com/junegunn/fzf/releases" -ForegroundColor Yellow
    }
}

Write-Host " [System] Valor's Environment Loaded Successfully." -ForegroundColor Cyan
