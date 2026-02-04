## ADDED Requirements

### Requirement: sudo 權限偵測

Linux 安裝腳本 SHALL 在安裝 editor 環境前偵測使用者是否具有免密碼 sudo 權限，並據此決定安裝策略。

#### Scenario: 使用者有 sudo 權限
- **WHEN** `sudo -n true 2>/dev/null` 成功
- **THEN** 腳本 SHALL 使用 apt 安裝 build-essential、vim、ripgrep、fd-find

#### Scenario: 使用者無 sudo 權限
- **WHEN** `sudo -n true 2>/dev/null` 失敗
- **THEN** 腳本 SHALL 跳過 apt 安裝，改用使用者層級替代方案

### Requirement: neovim 安裝至使用者目錄

Linux 安裝腳本 SHALL 將 neovim 安裝至 `~/.local/`（不論有無 sudo 權限）。

#### Scenario: 安裝 neovim
- **WHEN** 執行 setup_linux.sh 且選擇安裝 editor 且 `nvim` 指令不存在
- **THEN** 腳本 SHALL 下載 `nvim-linux-x86_64.tar.gz` 並以 `--strip-components=1` 解壓至 `~/.local/`

#### Scenario: neovim 已安裝
- **WHEN** `nvim` 指令已存在
- **THEN** 腳本 SHALL 跳過安裝並輸出版本提示

### Requirement: lazygit 安裝至使用者目錄

Linux 安裝腳本 SHALL 將 lazygit 安裝至 `~/.local/bin/`（不論有無 sudo 權限）。

#### Scenario: 安裝 lazygit
- **WHEN** 執行 setup_linux.sh 且選擇安裝 editor 且 `lazygit` 指令不存在
- **THEN** 腳本 SHALL 下載 lazygit binary 並安裝至 `~/.local/bin/`

#### Scenario: lazygit 已安裝
- **WHEN** `lazygit` 指令已存在
- **THEN** 腳本 SHALL 跳過安裝並輸出版本提示

### Requirement: ripgrep 使用者層級 fallback

Linux 安裝腳本 SHALL 在無 sudo 時從 GitHub Release 下載 ripgrep binary 至 `~/.local/bin/`。

#### Scenario: 無 sudo 且 ripgrep 未安裝
- **WHEN** 無 sudo 權限且 `rg` 指令不存在
- **THEN** 腳本 SHALL 從 GitHub Release 下載 ripgrep 靜態 binary 並安裝至 `~/.local/bin/rg`

#### Scenario: 無 sudo 且 ripgrep 已存在
- **WHEN** 無 sudo 權限且 `rg` 指令已存在
- **THEN** 腳本 SHALL 跳過安裝

### Requirement: fd 使用者層級 fallback

Linux 安裝腳本 SHALL 在無 sudo 時從 GitHub Release 下載 fd binary 至 `~/.local/bin/`。

#### Scenario: 無 sudo 且 fd 未安裝
- **WHEN** 無 sudo 權限且 `fd` 和 `fdfind` 指令都不存在
- **THEN** 腳本 SHALL 從 GitHub Release 下載 fd 靜態 binary 並安裝至 `~/.local/bin/fd`

#### Scenario: 無 sudo 且 fd 已存在
- **WHEN** 無 sudo 權限且 `fd` 或 `fdfind` 指令已存在
- **THEN** 腳本 SHALL 跳過安裝

### Requirement: 舊版系統安裝偵測

Linux 安裝腳本 SHALL 在安裝完成後偵測 `/usr/local/bin/` 下是否存在舊版 neovim 或 lazygit，若存在 SHALL 輸出路徑與建議移除指令。

#### Scenario: 系統路徑存在舊版 neovim
- **WHEN** 安裝完成後 `/usr/local/bin/nvim` 存在
- **THEN** 腳本 SHALL 輸出警告，包含：舊版路徑 `/usr/local/bin/nvim`、該檔案的版本資訊、說明舊版可能因 PATH 順序優先於新版、建議移除指令 `sudo rm /usr/local/bin/nvim`

#### Scenario: 系統路徑存在舊版 lazygit
- **WHEN** 安裝完成後 `/usr/local/bin/lazygit` 存在
- **THEN** 腳本 SHALL 輸出警告，包含：舊版路徑 `/usr/local/bin/lazygit`、說明舊版可能因 PATH 順序優先於新版、建議移除指令 `sudo rm /usr/local/bin/lazygit`

#### Scenario: 系統路徑無舊版
- **WHEN** 安裝完成後 `/usr/local/bin/nvim` 和 `/usr/local/bin/lazygit` 都不存在
- **THEN** 腳本 SHALL 不輸出任何警告

### Requirement: build-essential 缺失警告

Linux 安裝腳本 SHALL 在無 sudo 且 `gcc` 不存在時輸出警告，不中斷安裝。

#### Scenario: 無 sudo 且 gcc 不存在
- **WHEN** 無 sudo 權限且 `gcc` 指令不存在
- **THEN** 腳本 SHALL 輸出警告「缺少 gcc (build-essential)，treesitter 語法解析器可能無法編譯」

#### Scenario: 無 sudo 且 gcc 已存在
- **WHEN** 無 sudo 權限且 `gcc` 指令已存在
- **THEN** 腳本 SHALL 靜默通過，不輸出警告

### Requirement: 更新腳本同步策略

`update_linux.sh` SHALL 套用與安裝腳本相同的使用者層級安裝策略。

#### Scenario: 更新 neovim
- **WHEN** 執行 update_linux.sh 且 features 包含 editor
- **THEN** SHALL 下載最新 neovim tar.gz 解壓至 `~/.local/`

#### Scenario: 更新 lazygit
- **WHEN** 執行 update_linux.sh 且 features 包含 editor
- **THEN** SHALL 下載最新 lazygit binary 安裝至 `~/.local/bin/`

#### Scenario: 有 sudo 更新 ripgrep/fd
- **WHEN** 執行 update_linux.sh 且有 sudo 權限
- **THEN** SHALL 透過 `sudo apt install -y --only-upgrade ripgrep fd-find` 更新

#### Scenario: 無 sudo 更新 ripgrep/fd
- **WHEN** 執行 update_linux.sh 且無 sudo 權限
- **THEN** SHALL 從 GitHub Release 重新下載最新 binary 至 `~/.local/bin/`
