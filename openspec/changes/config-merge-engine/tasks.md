## 1. 模板檔案提取

- [x] 1.1 建立 `templates/` 目錄
- [x] 1.2 從 `setup_mac.sh` heredoc（行 101-207）提取 `templates/zshrc_base_mac.zsh`
- [x] 1.3 從 `setup_linux.sh` heredoc（行 92-202）提取 `templates/zshrc_base_linux.zsh`
- [x] 1.4 從 `setup_mac.sh` editor heredoc（行 255-279）提取 `templates/zshrc_editor.zsh`（跨平台共用）
- [x] 1.5 驗證提取的模板內容與原 heredoc 一致

## 2. Python 合併引擎

- [x] 2.1 建立 `lib/` 目錄與 `lib/pyproject.toml`（`requires-python >= 3.10`，零外部依賴）
- [x] 2.2 實作 `lib/config_merge.py` CLI 骨架（argparse：`--target`、`--template`、`--section`、`--type`、`--dry-run`、`--no-color`）
- [x] 2.3 實作 section markers 解析（begin/end 配對偵測、zsh `#` / vim `"` 註解字元）
- [x] 2.4 實作全新安裝路徑（檔案不存在 → 寫入 markers + template + 空 user section，回傳碼 `2`）
- [x] 2.5 實作已有 markers 更新路徑（替換 managed 段內容，保留 user 段與其他 sections）
- [x] 2.6 實作首次升級合併路徑（備份 `.bak.<timestamp>`、正規化去重、輸出合併結果）
- [x] 2.7 實作正規化去重邏輯（去除空白、壓縮多空白、排除註解行和空行）
- [x] 2.8 實作 vim `set` 命令語義比對（提取 key、值衝突保留使用者版）
- [x] 2.9 實作差異摘要輸出（管理區段狀態、移除重複行內容、保留自訂行數、值衝突清單、備份路徑）
- [x] 2.10 實作 `--dry-run` 模式（僅輸出摘要，不寫入檔案）
- [x] 2.11 實作 `--no-color` 模式
- [x] 2.12 實作 end marker 缺失的容錯處理（視為無 markers，走首次升級流程）

## 3. uv 安裝整合

- [x] 3.1 在 `setup_mac.sh` 新增 `install_uv()` 函式：檢查 `uv` 是否存在，不存在則執行 `curl -LsSf https://astral.sh/uv/install.sh | sh`
- [x] 3.2 在 `setup_linux.sh` 新增同樣的 `install_uv()` 函式
- [x] 3.3 在 `install_zsh_env()` 開頭呼叫 `install_uv`，確保 uv 可用

## 4. Setup 腳本修改（macOS）

- [x] 4.1 在 `setup_mac.sh` 新增 `merge_config()` 共用函式（封裝 `uv run` 呼叫，含 fallback）
- [x] 4.2 將 `install_zsh_env()` 中的 zshrc heredoc 替換為 `merge_config ~/.zshrc "$SCRIPT_DIR/templates/zshrc_base_mac.zsh" "zsh-base" "zsh"`
- [x] 4.3 將 `install_editor_env()` 中的 .vimrc 複製替換為 `merge_config ~/.vimrc "$SCRIPT_DIR/vim/.vimrc" "vimrc" "vim"`
- [x] 4.4 將 `install_editor_env()` 中的 editor heredoc 替換為 `merge_config ~/.zshrc "$SCRIPT_DIR/templates/zshrc_editor.zsh" "editor" "zsh"`

## 5. Setup 腳本修改（Linux）

- [x] 5.1 在 `setup_linux.sh` 新增 `merge_config()` 共用函式
- [x] 5.2 將 `install_zsh_env()` 中的 zshrc heredoc 替換為 `merge_config ~/.zshrc "$SCRIPT_DIR/templates/zshrc_base_linux.zsh" "zsh-base" "zsh"`
- [x] 5.3 將 `install_editor_env()` 中的 .vimrc 複製替換為 `merge_config ~/.vimrc "$SCRIPT_DIR/vim/.vimrc" "vimrc" "vim"`
- [x] 5.4 將 `install_editor_env()` 中的 editor heredoc 替換為 `merge_config ~/.zshrc "$SCRIPT_DIR/templates/zshrc_editor.zsh" "editor" "zsh"`

## 6. 測試

- [x] 6.1 為 `lib/config_merge.py` 撰寫 Python 單元測試：全新安裝、已有 markers 更新、首次升級去重、值衝突、dry-run、end marker 缺失
- [x] 6.2 在 `tests/test_mac.sh` 新增測試項目：uv 可用性、`lib/config_merge.py` 存在、`templates/` 檔案存在、merge_config 函式可呼叫
- [x] 6.3 在 `tests/test_linux.sh` 新增同樣的測試項目
- [x] 6.4 手動執行 `uv run lib/config_merge.py --dry-run --target ~/.zshrc --template templates/zshrc_base_mac.zsh --section zsh-base --type zsh` 驗證差異摘要正確
