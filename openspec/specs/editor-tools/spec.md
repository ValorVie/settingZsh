### Requirement: 安裝 Neovim

安裝腳本 SHALL 安裝 Neovim ≥ 0.10（LazyVim 最低需求）。

| 平台 | 安裝方式 |
|------|----------|
| macOS | `brew install neovim` |
| Linux | GitHub Release tar.gz 解壓至 `~/.local/` |
| Windows | `winget install Neovim.Neovim` |

#### Scenario: macOS 安裝 Neovim
- **WHEN** 執行 setup_mac.sh 且選擇安裝 editor
- **THEN** 腳本 SHALL 執行 `brew install neovim`

#### Scenario: Linux 安裝 Neovim
- **WHEN** 執行 setup_linux.sh 且選擇安裝 editor
- **THEN** 腳本 SHALL 從 GitHub Release 下載 `nvim-linux-x86_64.tar.gz`，解壓至 `~/.local/`

#### Scenario: Windows 安裝 Neovim
- **WHEN** 執行 setup_win.ps1 且選擇安裝 editor
- **THEN** 腳本 SHALL 執行 `winget install Neovim.Neovim`

#### Scenario: Neovim 已安裝
- **WHEN** `nvim` 指令已存在
- **THEN** 腳本 SHALL 跳過安裝並輸出提示

### Requirement: 安裝 Vim（僅 Unix）

安裝腳本 SHALL 在 macOS 和 Linux 安裝 Vim。

#### Scenario: macOS 安裝 Vim
- **WHEN** 執行 setup_mac.sh 且選擇安裝 editor
- **THEN** 腳本 SHALL 執行 `brew install vim`

#### Scenario: Linux 安裝 Vim
- **WHEN** 執行 setup_linux.sh 且選擇安裝 editor
- **THEN** 腳本 SHALL 執行 `sudo apt install -y vim`

### Requirement: 安裝 lazygit

安裝腳本 SHALL 安裝 lazygit（LazyVim Git TUI 整合）。

| 平台 | 安裝方式 |
|------|----------|
| macOS | `brew install lazygit` |
| Linux | 從 GitHub Release 下載 binary 至 `~/.local/bin/` |
| Windows | `winget install JesseDuffield.lazygit` |

#### Scenario: macOS 安裝 lazygit
- **WHEN** 執行 setup_mac.sh 且選擇安裝 editor
- **THEN** 腳本 SHALL 執行 `brew install lazygit`

#### Scenario: Linux 安裝 lazygit
- **WHEN** 執行 setup_linux.sh 且選擇安裝 editor
- **THEN** 腳本 SHALL 從 GitHub Release 下載 lazygit binary 並安裝至 `~/.local/bin/`

#### Scenario: Windows 安裝 lazygit
- **WHEN** 執行 setup_win.ps1 且選擇安裝 editor
- **THEN** 腳本 SHALL 執行 `winget install JesseDuffield.lazygit`

### Requirement: 安裝 ripgrep

安裝腳本 SHALL 安裝 ripgrep（telescope.nvim 搜尋後端）。

| 平台 | 安裝方式 |
|------|----------|
| macOS | `brew install ripgrep` |
| Linux（有 sudo） | `sudo apt install -y ripgrep` |
| Linux（無 sudo） | GitHub Release binary 至 `~/.local/bin/` |
| Windows | `winget install BurntSushi.ripgrep.MSVC` |

#### Scenario: 安裝 ripgrep（有 sudo）
- **WHEN** 選擇安裝 editor 且有 sudo 權限
- **THEN** 腳本 SHALL 透過 `sudo apt install -y ripgrep` 安裝

#### Scenario: 安裝 ripgrep（無 sudo）
- **WHEN** 選擇安裝 editor 且無 sudo 權限且 `rg` 指令不存在
- **THEN** 腳本 SHALL 從 GitHub Release 下載 ripgrep binary 至 `~/.local/bin/`

### Requirement: 安裝 fd

安裝腳本 SHALL 安裝 fd（telescope.nvim 檔案搜尋）。

| 平台 | 安裝方式 | 指令名稱 |
|------|----------|----------|
| macOS | `brew install fd` | `fd` |
| Linux（有 sudo） | `sudo apt install -y fd-find` | `fdfind` |
| Linux（無 sudo） | GitHub Release binary 至 `~/.local/bin/` | `fd` |
| Windows | `winget install sharkdp.fd` | `fd` |

#### Scenario: 安裝 fd（有 sudo）
- **WHEN** 選擇安裝 editor 且有 sudo 權限
- **THEN** 腳本 SHALL 透過 `sudo apt install -y fd-find` 安裝

#### Scenario: 安裝 fd（無 sudo）
- **WHEN** 選擇安裝 editor 且無 sudo 權限且 `fd`/`fdfind` 指令都不存在
- **THEN** 腳本 SHALL 從 GitHub Release 下載 fd binary 至 `~/.local/bin/`

### Requirement: 安裝 build-essential（僅 Linux）

Linux 安裝腳本在有 sudo 時 SHALL 安裝 build-essential（treesitter 編譯需要 gcc）。無 sudo 時 SHALL 檢測 gcc 是否存在並在缺失時輸出警告。

#### Scenario: 有 sudo 安裝 build-essential
- **WHEN** 執行 setup_linux.sh 且選擇安裝 editor 且有 sudo 權限
- **THEN** 腳本 SHALL 執行 `sudo apt install -y build-essential`

#### Scenario: 無 sudo 且 gcc 缺失
- **WHEN** 執行 setup_linux.sh 且選擇安裝 editor 且無 sudo 權限且 `gcc` 不存在
- **THEN** 腳本 SHALL 輸出警告訊息，不中斷安裝

### Requirement: 更新腳本更新 editor 工具

更新腳本 SHALL 在偵測到 editor 模組已安裝時，更新 neovim、ripgrep、fd、lazygit。

#### Scenario: macOS 更新 editor 工具
- **WHEN** 執行 update_mac.sh 且 features 包含 editor
- **THEN** SHALL 透過 `brew upgrade neovim ripgrep fd lazygit` 更新

#### Scenario: Linux 更新 editor 工具（neovim/lazygit）
- **WHEN** 執行 update_linux.sh 且 features 包含 editor
- **THEN** SHALL 下載最新 neovim tar.gz 至 `~/.local/`，下載最新 lazygit binary 至 `~/.local/bin/`

#### Scenario: Linux 更新 editor 工具（ripgrep/fd，有 sudo）
- **WHEN** 執行 update_linux.sh 且 features 包含 editor 且有 sudo 權限
- **THEN** SHALL 透過 `sudo apt install -y --only-upgrade ripgrep fd-find` 更新

#### Scenario: Linux 更新 editor 工具（ripgrep/fd，無 sudo）
- **WHEN** 執行 update_linux.sh 且 features 包含 editor 且無 sudo 權限
- **THEN** SHALL 從 GitHub Release 重新下載 binary 至 `~/.local/bin/`

#### Scenario: Windows 更新 editor 工具
- **WHEN** 執行 update_win.ps1 且 features 包含 editor
- **THEN** SHALL 透過 `winget upgrade` 更新 Neovim、ripgrep、fd、lazygit
