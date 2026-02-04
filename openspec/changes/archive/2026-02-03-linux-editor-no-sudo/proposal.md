## Why

Linux 安裝腳本的 `install_editor_env()` 目前將 neovim 和 lazygit 安裝至 `/usr/local/bin`，需要 sudo 權限。在無 sudo 權限的環境（共用伺服器、容器、受限帳號）中，整個 editor 安裝流程會失敗。將安裝目標改為 `~/.local/bin`（使用者層級），並為 ripgrep/fd 提供無 sudo fallback，可讓更多環境順利執行。

## What Changes

- **neovim**: Linux 安裝/更新目標從 `/usr/local/` 改為 `~/.local/`（bin + share + lib）
- **lazygit**: Linux 安裝/更新目標從 `/usr/local/bin/` 改為 `~/.local/bin/`
- **ripgrep/fd**: 偵測 sudo 權限，有則走 apt，無則從 GitHub Release 下載 binary 至 `~/.local/bin/`
- **build-essential/vim**: 有 sudo 時走 apt 安裝；無 sudo 時檢測 `gcc`/`vim` 是否已存在，缺失則輸出警告（不中斷安裝）
- **update_linux.sh**: 同步套用相同策略

## Capabilities

### New Capabilities
- `linux-userspace-install`: Linux 使用者層級安裝策略——偵測 sudo 權限並決定安裝路徑與方式

### Modified Capabilities
- `editor-tools`: Linux 安裝路徑從 `/usr/local/` 改為 `~/.local/`；新增無 sudo 時的 fallback 安裝方式

## Impact

- **受影響檔案**: `setup_linux.sh`、`update_linux.sh`
- **不受影響**: `setup_mac.sh`、`update_mac.sh`、`setup_win.ps1`、`update_win.ps1`、`lib/config_merge.py`
- **PATH 依賴**: `~/.local/bin` 已在 `templates/zshrc_base_linux.zsh` 中設定，無需額外變更
- **測試**: `tests/test_linux.sh` 需更新路徑檢查
