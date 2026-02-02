## MODIFIED Requirements

### Requirement: Windows 安裝 fzf 和 Starship

`setup_win.ps1` SHALL 透過 winget 安裝 fzf 和 starship。選裝 editor 時 SHALL 額外安裝 neovim、nvm-windows、ripgrep、fd、lazygit。

#### Scenario: winget 可用（僅 zsh）
- **WHEN** 系統中存在 `winget` 且未選裝 editor
- **THEN** 腳本 SHALL 執行 `winget install junegunn.fzf` 和 `winget install Starship.Starship`

#### Scenario: winget 可用（含 editor）
- **WHEN** 系統中存在 `winget` 且選裝 editor
- **THEN** 腳本 SHALL 額外執行 `winget install Neovim.Neovim`、`winget install CoreyButler.NVMforWindows`、`winget install BurntSushi.ripgrep.MSVC`、`winget install sharkdp.fd`、`winget install JesseDuffield.lazygit`

#### Scenario: winget 不可用
- **WHEN** 系統中不存在 `winget` 指令
- **THEN** 腳本 SHALL 輸出所有工具的手動安裝連結並繼續

### Requirement: Windows 更新腳本

`update_win.ps1` SHALL 根據 features 標記檔決定更新範圍。

#### Scenario: 僅更新基本環境
- **WHEN** features 不含 editor
- **THEN** 腳本 SHALL 更新 PowerShell 模組、fzf、starship、字型

#### Scenario: 更新含 editor 環境
- **WHEN** features 包含 editor
- **THEN** 腳本 SHALL 額外透過 `winget upgrade` 更新 Neovim、nvm-windows、ripgrep、fd、lazygit

### Requirement: Windows 部署 Neovim 配置

選裝 editor 時，`setup_win.ps1` SHALL 將 `nvim/` 目錄複製至 `$env:LOCALAPPDATA\nvim\`。

#### Scenario: 備份既有 Neovim 配置
- **WHEN** `$env:LOCALAPPDATA\nvim\` 已存在
- **THEN** 腳本 SHALL 將其重命名為 `nvim.bak` 後再複製

#### Scenario: 直接複製 Neovim 配置
- **WHEN** `$env:LOCALAPPDATA\nvim\` 不存在
- **THEN** 腳本 SHALL 直接複製整個 `nvim/` 目錄
