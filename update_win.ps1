# =============================================================================
# Windows 環境更新腳本
# 更新 PowerShell 模組、fzf、Starship、Maple Mono 字型
# =============================================================================

$ErrorActionPreference = "Continue"

Write-Host "=== Windows 環境更新開始 ===" -ForegroundColor Cyan

# -----------------------------------------------------------------------------
# 1. 更新 PowerShell 模組
# -----------------------------------------------------------------------------
$Modules = @("Terminal-Icons", "ZLocation", "PSFzf")
foreach ($mod in $Modules) {
    if (Get-Module -ListAvailable $mod -ErrorAction SilentlyContinue) {
        Write-Host " [更新] $mod..." -ForegroundColor Cyan
        Update-Module -Name $mod -Force -ErrorAction SilentlyContinue
        Write-Host " [完成] $mod 已更新" -ForegroundColor Green
    } else {
        Write-Host " [略過] $mod 未安裝" -ForegroundColor DarkGray
    }
}

# -----------------------------------------------------------------------------
# 2. 更新 fzf 和 Starship（透過 winget）
# -----------------------------------------------------------------------------
if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host " [更新] 透過 winget 更新 fzf..." -ForegroundColor Cyan
    winget upgrade junegunn.fzf --accept-source-agreements --accept-package-agreements 2>$null
    Write-Host " [更新] 透過 winget 更新 Starship..." -ForegroundColor Cyan
    winget upgrade Starship.Starship --accept-source-agreements --accept-package-agreements 2>$null
} else {
    Write-Host " [提示] winget 不可用，請手動更新 fzf 和 Starship" -ForegroundColor Yellow
}

# -----------------------------------------------------------------------------
# 3. 更新 Maple Mono NL NF CN 字型
# -----------------------------------------------------------------------------
Write-Host " [字型] 下載最新 Maple Mono NL NF CN..." -ForegroundColor Cyan
$MapleVersion = "v7.9"
$MapleArchive = "MapleMonoNL-NF-CN.zip"
$MapleUrl = "https://github.com/subframe7536/maple-font/releases/download/$MapleVersion/$MapleArchive"
$TempDir = Join-Path $env:TEMP "MapleMono"
$ZipPath = Join-Path $env:TEMP $MapleArchive

try {
    Invoke-WebRequest -Uri $MapleUrl -OutFile $ZipPath -UseBasicParsing
    if (Test-Path $TempDir) { Remove-Item $TempDir -Recurse -Force }
    Expand-Archive -Path $ZipPath -DestinationPath $TempDir -Force

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
            $RegPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
            $RegName = "$($font.BaseName) (TrueType)"
            Set-ItemProperty -Path $RegPath -Name $RegName -Value $DestPath -ErrorAction Stop
            $Installed++
        } catch {
            # 單一字型安裝失敗，繼續處理其他
        }
    }

    if ($Installed -gt 0) {
        Write-Host " [完成] 已更新 $Installed 個字型檔案" -ForegroundColor Green
    } else {
        Write-Host " [提示] 自動更新失敗，請手動安裝字型" -ForegroundColor Yellow
        Write-Host "   字型檔案位於：$TempDir" -ForegroundColor Yellow
    }

    Remove-Item $ZipPath -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host " [提示] 字型下載失敗，請手動下載：" -ForegroundColor Yellow
    Write-Host "   $MapleUrl" -ForegroundColor Yellow
}

# -----------------------------------------------------------------------------
# 完成
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Windows 環境更新完成 ===" -ForegroundColor Cyan
