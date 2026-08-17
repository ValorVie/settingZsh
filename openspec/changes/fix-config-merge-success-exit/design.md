## Context

`config_merge.py` 使用 `0` 表示一般成功、`1` 表示錯誤、`2` 表示全新安裝成功。Linux 與 macOS 的 `merge_config()` 直接執行此 CLI，而平台腳本啟用了 `set -e`。因此狀態碼 `2` 會中止整個 setup。

現場執行已留下連續證據：Node 與 `.vimrc` 在同一輪安裝完成，但緊接在 `.vimrc` 合併後的 Neovim 配置、editor zsh 區段與 features 標記都不存在。獨立 CLI 重現也確認目標檔建立成功時程序回傳 `2`。

## Goals / Non-Goals

**Goals:**

- Linux 與 macOS setup 在合併工具回傳 `2` 時繼續執行。
- 合併工具的真正錯誤仍維持非零並交由 `set -e` 停止流程。
- 用不接觸真實 HOME、網路或套件管理器的測試固定狀態碼契約。

**Non-Goals:**

- 不調整 `config_merge.py` 既有的 `0`／`1`／`2` 定義。
- 不重構 setup 主流程，也不處理其他套件安裝問題。
- 不修改 Windows 腳本；Windows 不呼叫這個 Bash 合併包裝函式。

## Decisions

### D1: 在 Shell 包裝函式正規化成功狀態

影響平台：Linux、macOS。

`merge_config()` 先保存 `uv run` 的狀態碼，再把 `0` 與 `2` 正規化成 Shell 成功狀態 `0`；其他值原樣回傳。`uv run` 放在可擷取失敗碼的條件式中，避免 `set -e` 在包裝函式判斷前退出。

保留 CLI 狀態碼 `2`，因為既有 OpenSpec 已把它定義為「全新安裝」結果。另一個方案是把 CLI 的全新安裝改成回傳 `0`，但這會改變已發布的工具契約，範圍較大。

### D2: Linux 與 macOS 維持對稱實作

影響平台：Linux、macOS。

兩份 setup 腳本保留各自的 `merge_config()`，套用相同的狀態碼處理。抽出新的共用 Shell library 只會為一個很短的判斷增加載入路徑與部署風險，這次不做。

### D3: 從實際函式文字建立隔離測試

影響平台：Linux 測試環境，覆蓋 Linux 與 macOS setup 函式。

測試從兩份 setup 腳本擷取 `merge_config()`，以 Bash 函式模擬 `uv` 回傳 `0`、`1`、`2`，再檢查包裝函式的最終狀態。這個測試不 source setup 主流程，因此不會下載檔案、執行套件管理器或修改 HOME。

## Risks / Trade-offs

- [風險] 未來合併工具新增其他成功狀態碼時仍會被視為失敗。→ 新狀態必須先更新規格與測試，避免靜默放寬。
- [風險] Linux 與 macOS 的短小判斷可能日後漂移。→ 同一個測試同時跑兩份實際函式，任一份不同步都會失敗。

## Migration Plan

1. 先加入回歸測試並確認目前實作在狀態碼 `2` 下失敗。
2. 更新兩份 `merge_config()`，讓 `0` 與 `2` 回傳 Shell 成功。
3. 執行回歸測試、完整 Python 測試、Bash 語法檢查與本輪腳本的 ShellCheck。
4. 修正版同步到安裝工作副本後重新執行 setup；既有 `.vimrc` 可安全重跑，接續部署 Neovim 設定與 features 標記。

回復時只需還原兩份 setup 函式與回歸測試。此變更不修改既有使用者配置內容。
