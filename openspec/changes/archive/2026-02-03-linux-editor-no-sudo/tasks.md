## 1. 版本變數與輔助函式

- [x] 1.1 在 `setup_linux.sh` 頂部新增 `RIPGREP_VERSION` 和 `FD_VERSION` 版本變數
- [x] 1.2 在 `setup_linux.sh` 新增 `has_sudo()` 輔助函式（使用 `sudo -n true 2>/dev/null`）
- [x] 1.3 在 `update_linux.sh` 頂部新增相同版本變數與 `has_sudo()` 函式

## 2. setup_linux.sh — install_editor_env() 改造

- [x] 2.1 將 apt 安裝行（build-essential, vim, ripgrep, fd-find）改為 sudo 分流：有 sudo 走 apt，無 sudo 走偵測+警告+fallback
- [x] 2.2 將 neovim 安裝目標從 `/usr/local/` 改為 `~/.local/`，移除 sudo，新增 `mkdir -p ~/.local`
- [x] 2.3 將 lazygit 安裝目標從 `/usr/local/bin/` 改為 `~/.local/bin/`，移除 sudo，新增 `mkdir -p ~/.local/bin`
- [x] 2.4 新增無 sudo 時 ripgrep 的 GitHub Release 下載安裝邏輯（下載至 `~/.local/bin/rg`）
- [x] 2.5 新增無 sudo 時 fd 的 GitHub Release 下載安裝邏輯（下載至 `~/.local/bin/fd`）
- [x] 2.6 更新 echo 提示訊息中的安裝路徑
- [x] 2.7 新增舊版偵測：安裝完成後檢查 `/usr/local/bin/nvim` 和 `/usr/local/bin/lazygit` 是否存在，輸出路徑與建議移除指令

## 3. update_linux.sh 同步改造

- [x] 3.1 將 neovim 更新目標從 `/usr/local/` 改為 `~/.local/`，移除 sudo
- [x] 3.2 將 lazygit 更新目標從 `/usr/local/bin/` 改為 `~/.local/bin/`，移除 sudo
- [x] 3.3 將 ripgrep/fd 更新改為 sudo 分流：有 sudo 走 apt upgrade，無 sudo 走重新下載 binary

## 4. 測試驗證

- [x] 4.1 更新 `tests/test_linux.sh` 中 neovim/lazygit 的路徑檢查（若有寫死 `/usr/local/bin`）
