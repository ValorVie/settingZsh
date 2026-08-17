## 1. 測試與 Baseline

- [ ] 1.1 確認前置 commit `5ff7b9a` 的 SSH clipboard、絕對行號與 `tests/test_nvim_options.py` 在開發副本通過
- [ ] 1.2 先為單一 Snacks picker/explorer、共用排除與最近專案宣告加入會失敗的無網路配置測試
- [ ] 1.3 先為絕對路徑、project-relative path、`path:line` 與未命名 buffer stop 加入會失敗的 Neovim headless 測試
- [ ] 1.4 先為 P0 Extra、PHP／Python LSP 選擇、HTML／CSS server 與 formatter/linter manifest 加入會失敗的配置測試
- [ ] 1.5 先為一般文字 trim、Markdown hard break、EditorConfig 優先序與非一般 buffer skip 建立暫存 fixture 測試

## 2. Workspace Navigation

- [ ] 2.1 將 `nvim/lazyvim.json` 遷移至目前 schema，明確啟用 `lazyvim.plugins.extras.editor.snacks_picker` 與 `snacks_explorer`
- [ ] 2.2 修改 `nvim/lua/plugins/editor.lua`，移除 Telescope／Neo-tree 強制 spec，改為 Snacks 共用排除、ignored toggle 與不追蹤 symlink 設定
- [ ] 2.3 新增單一 path helper，實作 root-relative、absolute fallback、`/` 正規化與未命名 buffer 安全停止
- [ ] 2.4 在 Snacks Explorer 加入 buffer-local `Y` 絕對路徑與 `gY` 相對路徑，在一般 buffer 加入 `<Leader>yp` 與 `<Leader>yL`
- [ ] 2.5 執行 navigation 與 path 測試，確認舊 Telescope／Neo-tree 設定不再強制安裝或接管核心 mapping

## 3. P0 語言工具

- [ ] 3.1 在 `nvim/lazyvim.json` 啟用 YAML、Docker 與 Black 官方 Extra，保留既有 Python、TypeScript、Rust、PHP、JSON、Markdown、Prettier、ESLint Extra
- [ ] 3.2 明確設定 PHP 使用 Intelephense、Python 使用 Pyright + Ruff analysis，並在 LSP opts 啟用 html 與 cssls
- [ ] 3.3 擴充 `nvim-lint` 的 PHP 設定，只在 workspace 有 `vendor/bin/phpstan` 與有效設定時執行 PHPStan
- [ ] 3.4 定義 P0 executable manifest，避免在 `mason.nvim` 與 `mason-lspconfig` 重複宣告同一 LSP package
- [ ] 3.5 執行語言 manifest 測試，確認 Python 只有 Black 負責格式化、Rust 不產生第二個 rust-analyzer client

## 4. 儲存行為

- [ ] 4.1 移除 `nvim/ftplugin/markdown.lua` 的 `vim.b.autoformat=false` 與空 `BufWritePre` callback，保留 Markdown formatter／preview
- [ ] 4.2 先驗證 Neovim EditorConfig 的有效屬性介面，再實作只在專案未明確設定時啟用的 trailing-whitespace fallback
- [ ] 4.3 讓 fallback 僅處理可寫一般文字 buffer，排除 Markdown、terminal、help、prompt、nofile、唯讀與 binary buffer
- [ ] 4.4 執行儲存 fixture 測試，驗證一般 trim、Markdown 兩個空白、final newline、EditorConfig EOL 與游標／搜尋狀態

## 5. 安裝與 Runtime 驗收

- [ ] 5.1 更新 Linux 平台測試，在 editor feature 已安裝時把缺少 `~/.config/nvim/init.lua` 視為失敗
- [ ] 5.2 更新 macOS 與 Windows 平台測試，把既有 Neovim config warning 改為 failure，並維持各平台實際配置路徑
- [ ] 5.3 新增不連網的 Neovim gate，只使用 repo fixture、隔離 XDG/data path 與既有 executable，不讀寫真實使用者配置
- [ ] 5.4 新增明確 opt-in 的安裝後 acceptance：外掛來源使用 `https://github.com/LazyVim/LazyVim` 與 `lazy-lock.json` 鎖定 commit；Mason package 來源使用 `https://github.com/mason-org/mason-registry`，執行時記錄 registry revision 與實際 package version
- [ ] 5.5 在受控配置執行 LazyHealth、主要 picker/explorer、P0 executable 與代表性 LSP attach 驗收；任何 blocking error 出現時停止，不進入完成狀態
- [ ] 5.6 將 OSC 52 copy、OSC 52 paste、browser preview 與真實 workspace 行為保留為分開的人工停止點，不把未執行寫成通過

## 6. 文件、完整驗證與交付

- [ ] 6.1 更新 `README.md` 與 `docs/editor-guide.md`，同步 Snacks、P0 語言工具、DAP optional 狀態、Markdown 行為與新快捷鍵
- [ ] 6.2 執行完整 pytest、Stylua、Bash／PowerShell 可用的語法檢查、直接相關 ShellCheck、diff check 與 `openspec validate align-neovim-vscode-experience --strict`
- [ ] 6.3 先在使用者層級開發副本完成全部 P0 gate，再把相同範圍逐檔套到原始 repo 並確認內容一致
- [ ] 6.4 只提交本 change 的實作、測試、文件與 OpenSpec artifacts；保留其他 dirty files，不 push
- [ ] 6.5 在交付摘要列出 P1／P2 非目標、Mason 版本漂移與尚未完成的人工驗收，不建立平行任務系統
