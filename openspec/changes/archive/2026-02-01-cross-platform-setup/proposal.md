## Why

目前的安裝腳本（setup_env.sh、update.sh）僅支援 Linux（apt），macOS 使用者無法執行。Windows 雖有 PowerShell Profile，但缺乏自動化部署機制且路徑寫死。需要將安裝流程拆分為平台各自腳本 + 共用入口，實現三平台（Linux/macOS/Windows）統一的安裝與更新體驗。

## What Changes

- **重構入口**：將 `setup_env.sh` 重命名為 `setup_linux.sh`，將 `update.sh` 重命名為 `update_linux.sh`，新增 `setup.sh` 和 `update.sh` 作為 Unix 統一入口（透過 `uname -s` 偵測 OS）
- **新增 macOS 支援**：新增 `setup_mac.sh` 和 `update_mac.sh`，使用 Homebrew 安裝套件，字型安裝至 `~/Library/Fonts/`，fzf 統一用 git clone 方式
- **新增 Windows 自動部署**：新增 `setup.bat`、`setup_win.ps1`、`update.bat`、`update_win.ps1`，自動偵測 PS 版本與 Profile 路徑、安裝模組、部署字型（失敗時提示手動安裝）
- **修正 PowerShell Profile**：將寫死的 `C:\Users\jack3\...` 改為 `$env:USERPROFILE\...` 動態路徑
- **更新 README.md**：統一安裝說明為 `./setup.sh`（Unix）或 `setup.bat`（Windows）

## Capabilities

### New Capabilities
- `macos-setup`: macOS 環境安裝與更新腳本（Homebrew 安裝套件、字型、fzf、zoxide、Zsh 配置）
- `windows-setup`: Windows 環境自動部署腳本（PowerShell Profile 部署、模組安裝、字型安裝、fzf/starship）
- `unified-entry`: 統一入口腳本，透過 OS 偵測分發至對應平台腳本

### Modified Capabilities

（無既有 specs 需修改）

## Impact

- **檔案重命名**：`setup_env.sh` → `setup_linux.sh`、`update.sh` → `update_linux.sh`
- **新增 8 個腳本檔案**：setup.sh、setup_mac.sh、setup.bat、setup_win.ps1、update.sh、update_mac.sh、update.bat、update_win.ps1
- **修改 2 個既有檔案**：`Windows-Powershell/Microsoft.PowerShell_profile.ps1`（動態路徑）、`README.md`（安裝說明）
- **依賴**：macOS 需預裝 Homebrew、Windows 需 winget 或 Chocolatey
