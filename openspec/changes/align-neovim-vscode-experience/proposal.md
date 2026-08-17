## Why

目前的 LazyVim 配置已具備 IDE 框架，但實際 picker 與排除設定錯接、語言 Extra 與可執行工具不一致，Markdown 儲存語意也偏離既有 VS Code 習慣。需要把研究結論轉成可驗收的 P0 設計，避免繼續以「外掛已安裝」代替真正的開發能力驗收。

## What Changes

- **BREAKING**：固定使用 Snacks picker 與 Snacks Explorer，取代目前因安裝世代而變動的 fzf-lua／Telescope／Neo-tree 組合；搜尋與 explorer 介面會改變，但保留既有功能意圖。
- 統一檔案、全文搜尋、explorer 與最近專案的排除規則，並保留顯示 ignored 項目的操作入口。
- 明確固定 PHP 使用 Intelephense、Python 使用 Pyright + Ruff analysis + Black formatting，補上 YAML、Docker、HTML/CSS、Marksman 與專案型 PHPStan 整合。
- 修正 Markdown 儲存行為：保留有語意的行尾空白與 formatter，並預設停用 markdownlint 格式診斷；一般文字檔維持 final newline 與可預期的行尾空白處理。
- 保留絕對路徑複製，新增專案相對路徑與 `path:line` 快捷鍵，不引入新外掛。
- 新增無網路的配置測試與安裝後 runtime 驗收，區分「已宣告」、「已安裝」、「已 attach」三種狀態。
- 同步更新 editor guide 與 README，移除 Telescope、DAP 與語言工具的過期敘述。
- 讓 Linux／macOS 的 Neovim 配置部署可安全重跑；相同內容直接 no-op，內容變更時不產生巢狀 backup。

## Capabilities

### New Capabilities

- `neovim-workspace-navigation`: 定義單一 picker/explorer、搜尋排除、最近專案與路徑複製行為。
- `neovim-language-tooling`: 定義 P0 語言伺服器、formatter、linter 與專案工具邊界。
- `neovim-save-behavior`: 定義格式化、行尾空白、final newline 與 EditorConfig 優先序。
- `neovim-readiness-verification`: 定義無網路測試、安裝後健康檢查與實際 LSP attach 驗收。

### Modified Capabilities

- 無。既有 `editor-tools` 仍負責安裝 Neovim、ripgrep、fd 與 lazygit；本 change 定義其上層的 Neovim 開發體驗。

## Impact

- 影響平台：Linux、macOS、Windows 的共用 Neovim 配置；OSC 52 仍只在 SSH 環境啟用。
- 主要影響：`nvim/lazyvim.json`、`nvim/lua/config/`、`nvim/lua/plugins/`、`nvim/ftplugin/`、`tests/`、`README.md`、`docs/editor-guide.md`。
- `5ff7b9a` 已完成的 SSH clipboard 與絕對行號設定視為前置項，不在本 change 重做。
- 不新增系統層常駐服務，不修改專案依賴，不掃描整個 home 尋找專案。

## 非目標 (Non-goals)

- 本 change 不啟用 DAP、Neotest 或 AI Extra；這些能力保留為 P1 後續 change。
- 不加入 CSV、貼圖、彩色括號、試算表／二進位 viewer、Git graph 或 Git worktree 專用外掛。
- 不複製 VS Code Project Manager 的 tags、grouping 或 base-folder 遞迴掃描。
- 不把 Remote SSH、SSHFS、私鑰、主機清單、字型與終端 profile 寫入 Neovim 配置。
- 不用全域 PHPStan、Black、ESLint 或其他工具取代專案鎖定的版本與設定。
