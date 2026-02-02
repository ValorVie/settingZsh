## Why

目前 setup 腳本部署 `.zshrc` 和 `.vimrc` 時，採用「備份 + 覆寫」模式——使用者的自訂設定會被完整替換，需要手動從 `.bak` 檔案中找回。重複執行腳本也會產生多餘的備份檔，且無法區分哪些是使用者獨有的自訂。

引入配置檔合併機制，讓 managed（模板管理）內容與 user（使用者自訂）內容共存，重複執行時只更新 managed 段、保留 user 段，並在合併時自動列出差異摘要。

## What Changes

- 新增 `uv` 安裝步驟至 setup 腳本，作為 Python 環境管理工具
- 新增 `lib/config_merge.py`：Python 合併引擎，處理正規化比對、去重、section markers 管理
- 新增 `templates/` 目錄：從 heredoc 提取模板檔案（`zshrc_base_mac.zsh`、`zshrc_base_linux.zsh`、`zshrc_editor.zsh`）
- 修改 `setup_mac.sh` / `setup_linux.sh`：將 heredoc 覆寫替換為 `merge_config()` 呼叫
- 合併時自動輸出差異摘要（移除的重複行、保留的自訂行、值衝突）
- `.vimrc` 同樣透過合併引擎處理，支援 `set` 命令的語義比對

## Non-goals（非目標）

- 不支援互動式衝突解決——衝突以差異摘要呈現，不中斷流程
- 不處理 `nvim/` 配置合併（LazyVim 框架結構，維持備份+覆寫）
- 不處理 Windows PowerShell Profile 合併
- 不擴展到 `.tmux.conf` 或其他 dotfile
- 不保留 `python3` fallback 路徑——uv 作為唯一 Python 管理工具

## Capabilities

### New Capabilities

- `config-merge`: 配置檔合併引擎，涵蓋 section markers、正規化去重、差異摘要輸出、CLI 介面

### Modified Capabilities

- `macos-setup`: 新增 uv 安裝、heredoc 替換為 merge_config 呼叫
- `unified-entry`: setup.sh 入口需確保 uv 可用後再呼叫平台腳本

## Impact

- **影響平台：** Linux / macOS
- **修改檔案：** `setup_mac.sh`、`setup_linux.sh`、`setup.sh`，新增 `lib/`、`templates/`
- **新增依賴：** uv（由腳本自動安裝）
- **測試：** `tests/test_mac.sh`、`tests/test_linux.sh` 需新增合併機制驗證
