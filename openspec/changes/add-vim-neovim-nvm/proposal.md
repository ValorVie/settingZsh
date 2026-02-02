## Why

專案目前僅涵蓋 Shell 環境（Zsh/PowerShell），缺乏編輯器配置。開發者在設定完 Shell 後，仍需手動安裝 Vim/Neovim 及 Node.js 版本管理器（nvm）。將這些整合進安裝腳本，可達成「一鍵部署完整開發環境」的目標。

此外，多數 LSP server（pyright、typescript-language-server、intelephense 等）依賴 Node.js，nvm 是管理 Node.js 版本的標準工具，屬於必要的前置依賴。

## What Changes

- 新增 Vim 精簡配置檔（`vim/.vimrc`），作為伺服器環境 fallback
- 新增 Neovim LazyVim 配置（`nvim/`），支援 Python、PHP、JS/TS、Rust 語言
- 三平台安裝腳本新增**互動式詢問**：是否安裝編輯器環境（預設否，僅安裝 Zsh）
- 三平台安裝腳本新增 nvm（Unix）/ nvm-windows（Windows）安裝
- 三平台安裝腳本新增 Neovim、ripgrep、fd、lazygit 安裝
- 安裝腳本寫入功能標記檔（`~/.settingzsh/features`），記錄已安裝模組
- 更新腳本依據標記檔條件更新（僅更新已安裝的模組）
- `.zshrc` 新增 nvm lazy loading 與 `alias vim='nvim'`（僅選裝 editor 時）

## Non-goals（非目標）

- 不提供 Neovim 插件的細部自訂 UI（使用 LazyVim 預設主題 tokyonight）
- 不安裝語言本身（Python、PHP、Rust 等由使用者自行管理）
- 不處理 LSP server 安裝（由 mason.nvim 在首次啟動時自動安裝）
- 不重構現有 Zsh 安裝邏輯，僅新增 editor 模組

## Capabilities

### New Capabilities

- `editor-config`: Vim/Neovim 配置檔管理（.vimrc + LazyVim nvim/ 目錄結構）
- `nvm-setup`: Node.js 版本管理器安裝（nvm for Unix, nvm-windows for Windows）
- `interactive-install`: 安裝腳本互動式模組選擇與功能標記檔機制
- `editor-tools`: 編輯器輔助工具安裝（ripgrep, fd, lazygit）

### Modified Capabilities

- `macos-setup`: 新增 editor 模組安裝步驟、互動詢問、標記檔寫入
- `windows-setup`: 新增 editor 模組安裝步驟、互動詢問、標記檔寫入
- `unified-entry`: setup.sh/update.sh 行為不變，但下游腳本行為變更

## Impact

- **影響平台:** Linux、macOS、Windows 全部
- **影響檔案:** setup_mac.sh, setup_linux.sh, setup_win.ps1, update_mac.sh, update_linux.sh, update_win.ps1, Windows-Powershell/Microsoft.PowerShell_profile.ps1
- **新增檔案:** vim/.vimrc, nvim/ 目錄（約 8 個檔案）
- **新增依賴:** neovim ≥0.10, nvm/nvm-windows, node LTS, ripgrep, fd, lazygit
- **使用者影響:** 安裝時多一個互動提示；選擇安裝 editor 後，首次啟動 nvim 會自動下載插件（需網路）
