## Context

專案目前是一支平鋪直敘的安裝腳本，每個平台一支檔案、由上至下執行。新增 editor 模組需要引入互動機制（詢問使用者）與狀態記錄機制（記住裝了什麼），以便 update 腳本知道該更新什麼。

現有腳本無函式化結構，所有邏輯寫在 top-level。為了加入可選模組，需要將邏輯拆分為函式。

## Goals / Non-Goals

**Goals:**
- 安裝腳本支援互動式選擇 editor 模組（預設否）
- 更新腳本根據已安裝模組條件更新
- 提供完整的 Vim fallback 配置 + Neovim LazyVim 配置
- 三平台安裝 nvm + Node.js LTS
- 三平台安裝 editor 輔助工具（ripgrep, fd, lazygit）

**Non-Goals:**
- 不重構現有 Zsh 安裝邏輯的核心流程
- 不處理 Neovim 插件 / LSP server 安裝（由 lazy.nvim / mason.nvim 自動管理）

## Decisions

### D1: 安裝腳本結構 — 函式化拆分

**決策:** 將 setup 腳本拆為函式（`install_zsh_env`、`install_editor_env`），主流程呼叫函式。

**理由:** 現有的 top-level 流程無法支援條件執行。函式化後，互動結果直接決定呼叫哪些函式。

**替代方案:**
- 拆成獨立腳本（`setup_editor_mac.sh`）：增加檔案數量，使用者需跑多支腳本
- 用 flag 參數（`setup_mac.sh --with-editor`）：不夠直覺，新手不友好

**影響平台:** 全部（macOS、Linux、Windows）

### D2: 功能標記檔機制

**決策:** 安裝完成後寫入 `~/.settingzsh/features` 文字檔，每行一個模組名（`zsh`、`editor`）。update 腳本優先讀此檔；若檔案不存在（舊版安裝），fallback 偵測 `command -v nvim`。

**理由:** 簡單、可靠、可讀、可擴展。未來新增其他可選模組只需加一行。

**替代方案:**
- 環境變數：重啟後消失
- 偵測已安裝工具：不夠精確（使用者可能自己裝了 nvim 但不是透過此腳本）

**影響平台:** 全部
- Unix: `~/.settingzsh/features`
- Windows: `$env:USERPROFILE\.settingzsh\features`

### D3: Neovim 安裝方式

**決策:** 依平台使用不同安裝方式。

| 平台 | 安裝方式 | 理由 |
|------|----------|------|
| macOS | `brew install neovim` | Homebrew 已是專案前提，版本通常足夠新 |
| Linux | GitHub Release tar.gz 解壓至 `/usr/local/` | apt 的 neovim 版本過舊（通常 <0.10），不用 snap/PPA |
| Windows | `winget install Neovim.Neovim` | 與現有 winget 安裝模式一致 |

**替代方案:**
- Linux 用 snap：使用者明確排除
- Linux 用 PPA：unstable PPA 不穩定，stable PPA 版本落後
- Linux 用 bob-nvim：需要 cargo，增加額外依賴

### D4: nvm 安裝方式

**決策:**

| 平台 | 工具 | 安裝方式 |
|------|------|----------|
| macOS / Linux | nvm (nvm-sh/nvm) | 官方 curl 安裝腳本 |
| Windows | nvm-windows (coreybutler) | `winget install CoreyButler.NVMforWindows` |

安裝完成後自動執行 `nvm install --lts` 並設為預設。

**影響平台:** 全部

### D5: nvm 在 .zshrc 中使用 lazy loading

**決策:** .zshrc 中使用延遲載入 nvm（定義 `nvm`/`node`/`npm`/`npx` 為 shell function，首次呼叫時才初始化）。

**理由:** nvm 標準初始化拖慢 shell 啟動約 200-500ms。lazy loading 將開銷推遲到第一次使用 node 相關指令時。

**影響平台:** macOS、Linux（Windows 的 nvm-windows 不影響 shell 啟動）

### D6: Neovim 配置框架 — LazyVim

**決策:** 使用 LazyVim（lazyvim.github.io）預設配置框架，搭配最小覆寫。

配置結構：
```
nvim/
├── init.lua              # require("config.lazy")
├── lazyvim.json          # 啟用的 extras 清單
├── lua/config/
│   ├── lazy.lua          # lazy.nvim bootstrap + LazyVim spec
│   ├── options.lua       # 覆寫：tabstop=4, wrap=true, mouse=""
│   ├── keymaps.lua       # 自訂快鍵
│   └── autocmds.lua      # trim whitespace 等自動命令
├── lua/plugins/
│   └── editor.lua        # neo-tree 排除 + telescope ignore patterns
└── ftplugin/
    └── markdown.lua      # Markdown 例外設定
```

啟用的 LazyVim Extras：
- `lang.python`, `lang.typescript`, `lang.rust`, `lang.php`, `lang.json`, `lang.markdown`
- `formatting.prettier`, `linting.eslint`

**影響平台:** 全部（配置檔跨平台通用）
- Unix: `~/.config/nvim/`
- Windows: `~/AppData/Local/nvim/`

### D7: Vim 精簡配置

**決策:** 提供 `vim/.vimrc` 精簡配置（約 30 行），涵蓋基礎體驗、縮排、搜尋、外觀。不安裝 Vim 插件。

**理由:** .vimrc 定位為伺服器 fallback，保持無依賴、開箱即用。

**影響平台:** macOS、Linux（Windows 不安裝 Vim，僅安裝 Neovim）

### D8: editor 輔助工具安裝

**決策:** 隨 editor 模組安裝以下工具：

| 工具 | 用途 | macOS | Linux | Windows |
|------|------|-------|-------|---------|
| ripgrep | telescope 搜尋後端 | brew | apt | winget |
| fd | telescope 檔案搜尋 | brew | apt (fd-find) | winget |
| lazygit | Git TUI（LazyVim 整合） | brew | GitHub Release binary | winget |

**影響平台:** 全部

### D9: .zshrc 寫入分段策略

**決策:** .zshrc 的 heredoc 分為兩段：
1. **zsh 基本段**（永遠寫入）：PATH、Zinit、插件、fzf、zoxide、快鍵、歷史記錄
2. **editor 段**（選裝 editor 時追加）：nvm lazy loading、`alias vim='nvim'`

**理由:** 避免未安裝 editor 時 .zshrc 出現無用的 nvm 初始化和 alias。

**影響平台:** macOS、Linux

## Risks / Trade-offs

- **[風險] Linux Neovim 版本綁定** → 使用 `latest` release URL，自動取得最新穩定版。update 腳本可重新下載覆蓋。
- **[風險] nvm 官方安裝腳本變更** → curl 安裝腳本是 nvm 官方長期維護的安裝方式，風險低。
- **[風險] LazyVim extras 接口變更** → LazyVim 遵循語義版本，extras 接口穩定。lazyvim.json 由 LazyVim 自動管理。
- **[取捨] 函式化拆分增加腳本複雜度** → 接受。這是支援可選模組的最小必要改動。
- **[取捨] Linux lazygit 需從 GitHub Release 下載** → apt 沒有 lazygit 套件，GitHub Release 是官方建議方式。

## Open Questions

（無——前置探索階段已確認所有決策）
