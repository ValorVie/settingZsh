# =============================================================================
# Windows 環境安裝腳本
# 部署 PowerShell Profile、安裝模組、fzf、Starship、Maple Mono 字型
# =============================================================================

$ErrorActionPreference = "Stop"

Write-Host "=== Windows 環境安裝開始 ===" -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# 1. 偵測 PowerShell 版本與 Profile 路徑
# -----------------------------------------------------------------------------
$PSMajor = $PSVersionTable.PSVersion.Major
if ($PSMajor -ge 7) {
    $ProfileDir = Join-Path $env:USERPROFILE "Documents\PowerShell"
    Write-Host " [偵測] PowerShell $PSMajor (7+)，Profile 路徑：$ProfileDir" -ForegroundColor Green
} else {
    $ProfileDir = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell"
    Write-Host " [偵測] PowerShell $PSMajor (5.1)，Profile 路徑：$ProfileDir" -ForegroundColor Green
}
$ProfilePath = Join-Path $ProfileDir "Microsoft.PowerShell_profile.ps1"

# -----------------------------------------------------------------------------
# 2. 備份既有 Profile
# -----------------------------------------------------------------------------
if (Test-Path $ProfilePath) {
    $BackupPath = "$ProfilePath.bak"
    Copy-Item $ProfilePath $BackupPath -Force
    Write-Host " [備份] 既有 Profile 已備份至 $BackupPath" -ForegroundColor Yellow
}

# -----------------------------------------------------------------------------
# 3. 複製新 Profile
# -----------------------------------------------------------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SourceProfile = Join-Path $ScriptDir "Windows-Powershell\Microsoft.PowerShell_profile.ps1"

if (-not (Test-Path $SourceProfile)) {
    Write-Host " [錯誤] 找不到來源 Profile：$SourceProfile" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}
Copy-Item $SourceProfile $ProfilePath -Force
Write-Host " [完成] Profile 已複製至 $ProfilePath" -ForegroundColor Green

# -----------------------------------------------------------------------------
# 4. 安裝 PowerShell 模組
# -----------------------------------------------------------------------------
$Modules = @("Terminal-Icons", "ZLocation", "PSFzf")
foreach ($mod in $Modules) {
    if (Get-Module -ListAvailable $mod -ErrorAction SilentlyContinue) {
        Write-Host " [略過] $mod 已安裝" -ForegroundColor DarkGray
    } else {
        Write-Host " [安裝] $mod..." -ForegroundColor Cyan
        Install-Module -Name $mod -Force -Scope CurrentUser -AllowClobber
        Write-Host " [完成] $mod 安裝成功" -ForegroundColor Green
    }
}

# -----------------------------------------------------------------------------
# 5. 安裝 fzf 和 Starship（透過 winget）
# -----------------------------------------------------------------------------
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host " [安裝] 透過 winget 安裝 fzf..." -ForegroundColor Cyan
    winget install junegunn.fzf --accept-source-agreements --accept-package-agreements 2>$null
    Write-Host " [安裝] 透過 winget 安裝 Starship..." -ForegroundColor Cyan
    winget install Starship.Starship --accept-source-agreements --accept-package-agreements 2>$null
} else {
    Write-Host " [提示] winget 不可用，請手動安裝以下工具：" -ForegroundColor Yellow
    Write-Host "   fzf:      https://github.com/junegunn/fzf/releases" -ForegroundColor Yellow
    Write-Host "   Starship: https://starship.rs/#quick-install" -ForegroundColor Yellow
}

# -----------------------------------------------------------------------------
# 6. 下載並安裝 Maple Mono NL NF CN 字型
# -----------------------------------------------------------------------------
Write-Host " [字型] 下載 Maple Mono NL NF CN..." -ForegroundColor Cyan
$MapleVersion = "v7.9"
$MapleArchive = "MapleMonoNL-NF-CN.zip"
$MapleUrl = "https://github.com/subframe7536/maple-font/releases/download/$MapleVersion/$MapleArchive"
$TempDir = Join-Path $env:TEMP "MapleMono"
$ZipPath = Join-Path $env:TEMP $MapleArchive

try {
    Invoke-WebRequest -Uri $MapleUrl -OutFile $ZipPath -UseBasicParsing
    if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
    Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force

    # 嘗試自動安裝至使用者字型目錄
    $UserFontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    if (-not (Test-Path $UserFontDir)) {
        New-Item -ItemType Directory -Path $UserFontDir -Force | Out-Null
    }

    $FontFiles = Get-ChildItem -Path $TempDir -Filter "*.ttf" -Recurse
    if ($FontFiles.Count -eq 0) {
        $FontFiles = Get-ChildItem -Path $TempDir -Filter "*.otf" -Recurse
    }

    $Installed = 0
    foreach ($font in $FontFiles) {
        try {
            $DestPath = Join-Path $UserFontDir $font.Name
            Copy-Item $font.FullName $DestPath -Force
            # 寫入使用者字型登錄檔（指向安裝後路徑）
            $RegPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
            $RegName = "$($font.BaseName) (TrueType)"
            Set-ItemProperty -Path $RegPath -Name $RegName -Value $DestPath -ErrorAction Stop
            $Installed++
        } catch {
            # 單一字型安裝失敗，繼續處理其他
        }
    }

    if ($Installed -gt 0) {
        Write-Host " [完成] 已安裝 $Installed 個字型檔案至 $UserFontDir" -ForegroundColor Green
        Write-Host " [提示] 請重新啟動終端機以套用新字型" -ForegroundColor Yellow
    } else {
        Write-Host " [提示] 自動安裝失敗，請手動安裝字型" -ForegroundColor Yellow
        Write-Host "   字型檔案位於：$TempDir" -ForegroundColor Yellow
        Write-Host "   請選取所有 .ttf 檔案，右鍵 > 安裝" -ForegroundColor Yellow
    }
} catch {
    Write-Host " [提示] 字型下載失敗，請手動下載並安裝：" -ForegroundColor Yellow
    Write-Host "   $MapleUrl" -ForegroundColor Yellow
}

# -----------------------------------------------------------------------------
# 完成
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Windows 環境安裝完成 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "後續步驟：" -ForegroundColor White
Write-Host "  1. 重新啟動終端機" -ForegroundColor White
Write-Host "  2. 在 Windows Terminal 設定中將字型改為 'Maple Mono NL NF CN'" -ForegroundColor White
Write-Host "  3. 在 VS Code settings.json 中設定：" -ForegroundColor White
Write-Host '     "editor.fontFamily": "''Maple Mono NL NF CN'', ''Consolas'', monospace"' -ForegroundColor White
Write-Host '     "terminal.integrated.fontFamily": "''Maple Mono NL NF CN''"' -ForegroundColor White
