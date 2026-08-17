## Context

參見 `proposal.md` 的 Why。現有配置同時安裝 fzf-lua、Telescope 與 Neo-tree，但 runtime picker 是 fzf-lua，排除設定卻只寫給 Telescope。語言 Extra 已宣告，Mason 與 PATH 的 executable 並未完整對齊；Markdown ftplugin 也以關閉 autoformat 取代保留行尾空白。

本 change 只把研究報告的 P0 建議轉成可執行設計。`5ff7b9a` 已完成的 SSH OSC 52 與絕對行號設定是前置項，不重做。

## Goals / Non-Goals

**Goals:**

- 固定單一 navigation backend，讓新舊安裝得到相同行為。
- 為主要語言建立一條 LSP、formatter、linter 的責任鏈。
- 修正 Markdown 與一般檔案的儲存語意，尊重 EditorConfig。
- 讓配置測試不需網路，runtime 驗收則清楚列出外部安裝與人工停止點。

**Non-Goals:**

- 不在本 change 啟用 DAP、Neotest、AI Extra 或 P2 小工具。
- 不建立全域專案 tags 資料庫，也不掃描整個 home。
- 不自動修改任何 workspace 的 Composer、npm、Cargo 或 Python lockfile。
- 不把 runtime health check 的 optional warning 全部消成零。

## Decisions

### D1: 固定 Snacks picker 與 Snacks Explorer

影響平台：Linux、macOS、Windows。

在 `nvim/lazyvim.json` 明確啟用 `editor.snacks_picker` 與 `editor.snacks_explorer`，並移除 `editor.lua` 對 Telescope、Neo-tree 的強制 spec。Snacks 已是 LazyVim 與本配置的既有依賴，可同時提供 files、grep、projects、Git 與 explorer，不新增另一套核心 UI。

替代方案是保留 fzf-lua + Neo-tree。它的變更較小，但搜尋與 explorer 仍需維護兩份排除，Project picker 也要再加一層整合；長期成本較高，因此不採用。

### D2: 排除規則分成共用與專案兩層

影響平台：全部。

`nvim/lua/plugins/editor.lua` 只保留跨專案都合理的依賴、建置與快取目錄；專案特定資料由 `.gitignore`、`.ignore` 或工具自己的 project config 管理。Picker 與 explorer 共用同一份 Lua 清單，但不把該清單誤當成 LSP watcher exclude。

不啟用 symlink follow。`fd`、`fdfind` 與 `rg` 由 Snacks／底層工具自行選擇，不為 Debian 額外建立 symlink。

### D3: Project picker 使用最近 roots，不做 base-folder 掃描

影響平台：全部。

使用 Snacks projects 與既有 persistence session。它覆蓋「快速回到最近專案」的主要需求，但不複製 VS Code Project Manager 的 tags、grouping 與遞迴掃描。若未來確認需要固定分類，另建不含私人主機資料的手動專案清單。

### D4: 路徑複製共用一個小型 Helper

影響平台：全部。

新增單一 Lua helper，負責：

1. 正規化 buffer 或 explorer item 的絕對路徑。
2. 以 `LazyVim.root({ buf=0, normalize=true })` 決定和 LSP／picker 一致的 root。
3. 以 `vim.fs.relpath(root, file)` 產生相對路徑，失敗時回退絕對路徑。
4. 輸出一律使用 `/`，並由 caller 決定是否附行號。
5. 寫入 `+` register 前檢查未命名 buffer，失敗時通知且不覆寫 register。

Snacks Explorer 新增 `Y` 複製絕對路徑與 `gY` 複製相對路徑；一般 buffer 使用 `<Leader>yp` 與 `<Leader>yL`。不覆蓋原生 `Y`，因為 explorer mapping 是 buffer-local。

### D5: P0 語言工具選擇固定，但專案依賴不全域化

影響平台：全部；executable 由各平台的 Mason package 或系統 PATH 提供。

- PHP：設定 `vim.g.lazyvim_php_lsp="intelephense"`。PHPStan 只呼叫 workspace `vendor/bin/phpstan`；找不到時不啟用。
- Python：保留 LazyVim 預設 Pyright，Ruff 只做 analysis，啟用 Black Extra 做格式化。這最接近既有 Pylance + Black 習慣；basedpyright 留作 per-project 或未來比較。
- TypeScript／JavaScript：使用 LazyVim 預設 vtsls，搭配既有 ESLint 與 Prettier。
- Rust：保留 rustaceanvim／rust-analyzer，不再配置第二個 LSP client。
- JSON、Markdown：保留既有 Extra，將 Marksman executable 納入驗收。
- YAML、Docker：新增官方 Extra。
- HTML／CSS：在 `nvim-lspconfig` 的 server opts 明確啟用 `html`、`cssls`；格式化仍由 Prettier。

LazyVim Extra 與 mason-lspconfig 負責 LSP 安裝意圖；`mason.nvim.ensure_installed` 只列 formatter／linter 等非 LSP 工具，避免同一 package 在兩處重複宣告。外掛版本由 `lazy-lock.json` 鎖定；Mason runtime 版本記錄在驗收輸出，不提交其安裝目錄。

### D6: EditorConfig 優先，個人規則只做 Fallback

影響平台：全部。

移除 `ftplugin/markdown.lua` 的 `vim.b.autoformat=false` 與空 callback。Markdown formatter 保持可用；是否 trim 由有效 EditorConfig 與 filetype fallback 決定。

一般文字的 trailing-whitespace fallback 放在單一 autocmd：只處理可寫、一般 `buftype`、非 binary buffer；Markdown 跳過。實作前測試 Neovim 內建 EditorConfig 暴露的有效屬性，只有在專案沒有明確設定時才套用個人預設。若無法可靠判定，停止此 fallback，改為只提供專案 `.editorconfig` 建議，不得冒險改寫內容。

不以全域 `fileformat=unix` 覆蓋已偵測到的 CRLF；新檔預設與既有 `fixendofline` 保留。特殊 code page／BOM 由專案或 filetype 明確設定。

### D7: 測試分成無網路 Gate 與安裝後 Acceptance

影響平台：測試可在 Linux 執行完整 headless gate；macOS／Windows 仍執行平台配置存在性檢查與可用的 Neovim 測試。

無網路 gate 使用 `nvim --headless -u NONE`、暫存 fixture 與 Python subprocess，驗證：

- options、Extra manifest、主要 LSP 選擇與單一 navigation backend。
- 路徑 helper 的 root-relative、absolute fallback、line number 與 unnamed-buffer stop。
- Markdown 與一般文字儲存行為，不讀寫真實使用者配置。

安裝後 acceptance 是獨立命令，不在一般單元測試自動下載 package。它開啟代表性 fixture，保存 `:LazyHealth`、executable 清單、active picker/explorer、`:LspInfo`／client 名稱與 log 路徑。OSC 52 copy/paste、browser preview 與真實 workspace 行為保留人工停止點。

### D8: 平台測試把配置缺失視為失敗

影響平台：Linux、macOS、Windows。

既有平台測試在 editor feature 已安裝時必須確認 `init.lua`。Linux 補上缺少的檢查；macOS／Windows 將目前的 warning 改為 failure。這能捕捉「binary 已安裝但配置未部署」的原始故障型態。

### D9: 文件只描述已套用能力

影響平台：全部。

更新 `README.md` 與 `docs/editor-guide.md`：picker/explorer、語言 server、DAP optional 狀態、Markdown 行為與新快捷鍵必須和 runtime 一致。P1／P2 只列後續選項，不得寫成已安裝。

## Risks / Trade-offs

- [風險] 切換 Snacks 會改變 picker/explorer UI 與部分按鍵習慣。→ 保留核心功能鍵，提供切換前後對照並用 fixture 驗收。
- [風險] Mason registry 與語言 server 版本會漂移。→ 外掛鎖定於 `lazy-lock.json`，runtime acceptance 記錄實際 package 版本；不宣稱跨時間完全重現。
- [風險] Pyright、Ruff、Black 可能對同一檔案提出不同修改。→ Ruff 不負責格式化，Black 是唯一 Python formatter。
- [風險] 全域 trim fallback 可能破壞有語意空白。→ EditorConfig 優先、Markdown 與非一般 buffer 排除；無可靠判定時停止 fallback。
- [風險] OSC 52 paste 可能被終端阻擋或等待。→ 自動 gate 只驗證 provider 選擇；copy/paste 分開人工驗收。
- [風險] Project root 判定不同可能產生意外相對路徑。→ 共用 LazyVim root policy，root 不是祖先時回退絕對路徑。

## Migration Plan

1. 在使用者層級開發副本先寫失敗測試並保存 baseline：active picker、已安裝工具、LSP errors、Markdown 行為。
2. 套用 navigation 與 path helper，執行無網路 gate；失敗時不繼續語言工具階段。
3. 套用 P0 語言 Extra／server／formatter／linter 宣告，執行 manifest 測試。
4. 修正 save behavior 與平台配置測試，執行 fixture 儲存測試。
5. 更新文件，執行完整 pytest、Stylua、Bash／PowerShell 可用的語法檢查、ShellCheck 與 OpenSpec strict validation。
6. 把相同檔案套到原始 repo，逐檔比對後 commit，不 push。
7. 使用安裝後 acceptance 在受控使用者配置執行。只有本次啟用功能無 blocking error、代表性 LSP attach 且人工停止點有明確結果時，才宣稱 P0 完成。

Rollback：還原實作 commit，恢復 setup 產生的上一份 Neovim 配置備份，重啟 Neovim 並重跑 baseline。不得刪除 Mason 或 Lazy data directory 來掩蓋設定問題。
