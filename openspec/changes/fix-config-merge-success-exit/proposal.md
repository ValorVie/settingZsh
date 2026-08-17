## Why

`config_merge.py` 會在全新安裝成功後回傳狀態碼 `2`，但 Linux 與 macOS 的 setup 腳本使用 `set -e`，因此把成功結果當成錯誤並提早結束。實際安裝已重現此行為：`.vimrc` 寫入成功後，LazyVim 設定與 features 標記沒有部署。

## What Changes

- Linux 與 macOS 的 `merge_config()` 將狀態碼 `2` 視為成功，讓 setup 繼續執行後續步驟。
- `config_merge.py` 的既有狀態碼契約保持不變：`0` 是一般成功、`1` 是錯誤、`2` 是全新安裝成功。
- 新增可重跑的回歸測試，驗證狀態碼 `0` 與 `2` 不會中止 setup，真正錯誤仍會往上傳遞。

## Capabilities

### New Capabilities

- `setup-config-merge-exit-handling`: 定義 Unix setup 腳本如何解讀配置合併工具的成功與失敗狀態。

### Modified Capabilities

- 無。

## Impact

- 影響平台：Linux、macOS。
- 影響檔案：`setup_linux.sh`、`setup_mac.sh` 與對應測試。
- 不新增依賴，不改變 Windows 安裝流程，也不改寫使用者既有配置。

## 非目標 (Non-goals)

- 不變更 `config_merge.py` 的狀態碼定義。
- 不處理 `fd`／`fdfind` 命令名稱差異或其他 editor 套件問題。
- 不由原始專案直接修復 `/home/sympasof/.config/nvim`；現場設定待修正版驗證後另行部署。
