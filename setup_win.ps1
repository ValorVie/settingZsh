# =============================================================================
# Windows 環境安裝腳本
# 部署 PowerShell Profile、安裝模組、fzf、Starship、Maple Mono 字型
# 選裝：neovim (LazyVim) + nvm-windows + node + ripgrep + fd + lazygit
# =============================================================================

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# =============================================================================
# 共用函式
# =============================================================================

function Ask-YesNo {
    param(
        [string]$Prompt,
        [string]$Default = "N"
    )
    if ($Default -eq "Y") {
        $reply = Read-Host "$Prompt (Y/n)"
        if ([string]::IsNullOrWhiteSpace($reply)) { $reply = "Y" }
    } else {
        $reply = Read-Host "$Prompt (y/N)"
        if ([string]::IsNullOrWhiteSpace($reply)) { $reply = "N" }
    }
    return $reply -match '^[Yy]'
}

function Save-Features {
    param([string[]]$Features)
    $FeaturesDir = Join-Path $env:USERPROFILE ".settingzsh"
    if (-not (Test-Path $FeaturesDir)) {
        New-Item -ItemType Directory -Path $FeaturesDir -Force | Out-Null
    }
    $FeaturesPath = Join-Path $FeaturesDir "features"
    $Features | Out-File -FilePath $FeaturesPath -Encoding utf8
    Write-Host " [完成] 已記錄安裝模組至 $FeaturesPath" -ForegroundColor Green
}

# =============================================================================
# 基本環境安裝
# =============================================================================

function Install-BaseEnv {
    # -------------------------------------------------------------------------
    # 1. 偵測 PowerShell 版本與 Profile 路徑
    # -------------------------------------------------------------------------
    $PSMajor = $PSVersionTable.PSVersion.Major
    if ($PSMajor -ge 7) {
        $ProfileDir = Join-Path $env:USERPROFILE "Documents\PowerShell"
        Write-Host " [偵測] PowerShell $PSMajor (7+)，Profile 路徑：$ProfileDir" -ForegroundColor Green
    } else {
        $ProfileDir = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell"
        Write-Host " [偵測] PowerShell $PSMajor (5.1)，Profile 路徑：$ProfileDir" -ForegroundColor Green
    }
    $ProfilePath = Join-Path $ProfileDir "Microsoft.PowerShell_profile.ps1"

    # -------------------------------------------------------------------------
    # 2. 備份既有 Profile
    # -------------------------------------------------------------------------
    if (Test-Path $ProfilePath) {
        $BackupPath = "$ProfilePath.bak"
        Copy-Item $ProfilePath $BackupPath -Force
        Write-Host " [備份] 既有 Profile 已備份至 $BackupPath" -ForegroundColor Yellow
    }

    # -------------------------------------------------------------------------
    # 3. 複製新 Profile
    # -------------------------------------------------------------------------
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

    # -------------------------------------------------------------------------
    # 4. 安裝 PowerShell 模組
    # -------------------------------------------------------------------------
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

    # -------------------------------------------------------------------------
    # 5. 安裝 fzf 和 Starship（透過 winget）
    # -------------------------------------------------------------------------
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

    # -------------------------------------------------------------------------
    # 6. 下載並安裝 Maple Mono NL NF CN 字型
    # -------------------------------------------------------------------------
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
}

# =============================================================================
# Editor 環境安裝
# =============================================================================

function Install-EditorEnv {
    # -------------------------------------------------------------------------
    # 1. 透過 winget 安裝 editor 工具
    # -------------------------------------------------------------------------
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $EditorPackages = @(
            @{ Id = "Neovim.Neovim"; Name = "Neovim" },
            @{ Id = "CoreyButler.NVMforWindows"; Name = "nvm-windows" },
            @{ Id = "BurntSushi.ripgrep.MSVC"; Name = "ripgrep" },
            @{ Id = "sharkdp.fd"; Name = "fd" },
            @{ Id = "JesseDuffield.lazygit"; Name = "lazygit" }
        )
        foreach ($pkg in $EditorPackages) {
            Write-Host " [安裝] 透過 winget 安裝 $($pkg.Name)..." -ForegroundColor Cyan
            winget install $pkg.Id --accept-source-agreements --accept-package-agreements 2>$null
        }
    } else {
        Write-Host " [提示] winget 不可用，請手動安裝以下工具：" -ForegroundColor Yellow
        Write-Host "   Neovim:      https://github.com/neovim/neovim/releases" -ForegroundColor Yellow
        Write-Host "   nvm-windows: https://github.com/coreybutler/nvm-windows/releases" -ForegroundColor Yellow
        Write-Host "   ripgrep:     https://github.com/BurntSushi/ripgrep/releases" -ForegroundColor Yellow
        Write-Host "   fd:          https://github.com/sharkdp/fd/releases" -ForegroundColor Yellow
        Write-Host "   lazygit:     https://github.com/jesseduffield/lazygit/releases" -ForegroundColor Yellow
    }

    # -------------------------------------------------------------------------
    # 2. 安裝 Node.js LTS（透過 nvm-windows）
    # -------------------------------------------------------------------------
    Write-Host " [安裝] 安裝 Node.js LTS..." -ForegroundColor Cyan
    if (Get-Command nvm -ErrorAction SilentlyContinue) {
        nvm install lts 2>$null
        nvm use lts 2>$null
        Write-Host " [完成] Node.js LTS 已安裝" -ForegroundColor Green
    } else {
        Write-Host " [提示] nvm 尚未就緒，請重新開啟終端機後執行：" -ForegroundColor Yellow
        Write-Host "   nvm install lts" -ForegroundColor Yellow
        Write-Host "   nvm use lts" -ForegroundColor Yellow
    }

    # -------------------------------------------------------------------------
    # 3. 部署 Neovim 配置
    # -------------------------------------------------------------------------
    Write-Host " [部署] Neovim 配置..." -ForegroundColor Cyan
    $NvimConfigDir = Join-Path $env:LOCALAPPDATA "nvim"
    $SourceNvim = Join-Path $ScriptDir "nvim"

    if (Test-Path $NvimConfigDir) {
        $BackupDir = "$NvimConfigDir.bak"
        if (Test-Path $BackupDir) { Remove-Item $BackupDir -Recurse -Force }
        Rename-Item $NvimConfigDir $BackupDir
        Write-Host " [備份] 既有 nvim 配置已備份至 $BackupDir" -ForegroundColor Yellow
    }

    Copy-Item -Path $SourceNvim -Destination $NvimConfigDir -Recurse -Force
    Write-Host " [完成] Neovim 配置已部署至 $NvimConfigDir" -ForegroundColor Green
}

# =============================================================================
# 主流程
# =============================================================================

Write-Host "══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  settingZsh 環境安裝程式 (Windows)" -ForegroundColor Cyan
Write-Host "══════════════════════════════════════" -ForegroundColor Cyan

# 永遠安裝基本環境
Install-BaseEnv
$Features = @("zsh")

# 詢問是否安裝 Editor 環境
Write-Host ""
if (Ask-YesNo "是否安裝編輯器環境？(neovim + nvm + node + ripgrep + fd + lazygit)" "N") {
    Install-EditorEnv
    $Features += "editor"
}

# 記錄已安裝模組
Save-Features -Features $Features

# -------------------------------------------------------------------------
# 完成
# -------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Windows 環境安裝完成 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "後續步驟：" -ForegroundColor White
Write-Host "  1. 重新啟動終端機" -ForegroundColor White
Write-Host "  2. 在 Windows Terminal 設定中將字型改為 'Maple Mono NL NF CN'" -ForegroundColor White
Write-Host "  3. 在 VS Code settings.json 中設定：" -ForegroundColor White
Write-Host '     "editor.fontFamily": "''Maple Mono NL NF CN'', ''Consolas'', monospace"' -ForegroundColor White
Write-Host '     "terminal.integrated.fontFamily": "''Maple Mono NL NF CN''"' -ForegroundColor White
if ($Features -contains "editor") {
    Write-Host "  4. 首次啟動 nvim 會自動安裝 LazyVim 插件（需要網路連線）" -ForegroundColor White
}
