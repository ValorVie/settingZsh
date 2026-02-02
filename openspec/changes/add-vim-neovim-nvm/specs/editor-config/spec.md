## ADDED Requirements

### Requirement: 提供 Vim 精簡配置檔

專案 SHALL 包含 `vim/.vimrc` 精簡配置檔，涵蓋基礎體驗、縮排、搜尋、外觀設定。此配置無任何外部插件依賴。

#### Scenario: .vimrc 基礎體驗設定
- **WHEN** 使用者載入 `vim/.vimrc`
- **THEN** 配置 SHALL 啟用語法高亮、行號、相對行號、自動折行、UTF-8 編碼、關閉滑鼠攔截、共用系統剪貼簿

#### Scenario: .vimrc 縮排設定
- **WHEN** 使用者載入 `vim/.vimrc`
- **THEN** 配置 SHALL 設定 tabstop=4、shiftwidth=4、expandtab、autoindent

#### Scenario: .vimrc 搜尋設定
- **WHEN** 使用者載入 `vim/.vimrc`
- **THEN** 配置 SHALL 啟用 ignorecase、smartcase、hlsearch、incsearch

#### Scenario: .vimrc 外觀與實用設定
- **WHEN** 使用者載入 `vim/.vimrc`
- **THEN** 配置 SHALL 啟用 cursorline、termguicolors、scrolloff=8、signcolumn=yes、undofile、splitright、splitbelow、list + listchars 顯示不可見字元

### Requirement: 提供 Neovim LazyVim 配置

專案 SHALL 包含 `nvim/` 目錄，使用 LazyVim 框架，可直接複製至 `~/.config/nvim/`（Unix）或 `~/AppData/Local/nvim/`（Windows）。

#### Scenario: LazyVim 入口結構
- **WHEN** 使用者複製 `nvim/` 至 Neovim 配置路徑
- **THEN** `init.lua` SHALL 載入 `config.lazy`，`lua/config/lazy.lua` SHALL 引導 lazy.nvim 並載入 LazyVim spec

#### Scenario: LazyVim extras 啟用
- **WHEN** Neovim 首次啟動
- **THEN** `lazyvim.json` SHALL 啟用以下 extras：lang.python、lang.typescript、lang.rust、lang.php、lang.json、lang.markdown、formatting.prettier、linting.eslint

### Requirement: Neovim 選項覆寫對齊 VSCode 習慣

`lua/config/options.lua` SHALL 覆寫 LazyVim 預設值以對齊使用者的 VSCode 設定。

#### Scenario: 縮排覆寫
- **WHEN** 載入 options.lua
- **THEN** tabstop、shiftwidth、softtabstop SHALL 設為 4（LazyVim 預設為 2）

#### Scenario: 換行覆寫
- **WHEN** 載入 options.lua
- **THEN** wrap SHALL 設為 true（LazyVim 預設為 false）

#### Scenario: 滑鼠覆寫
- **WHEN** 載入 options.lua
- **THEN** mouse SHALL 設為空字串（關閉滑鼠）

#### Scenario: 檔案格式設定
- **WHEN** 載入 options.lua
- **THEN** fileformat SHALL 設為 "unix"，fixendofline SHALL 設為 true

### Requirement: Neovim 搜尋排除對齊 VSCode

`lua/plugins/editor.lua` SHALL 設定 telescope 和 neo-tree 的排除規則，對齊 VSCode 的 search.exclude 和 files.exclude。

#### Scenario: Telescope 搜尋排除
- **WHEN** 使用 telescope 搜尋檔案或文字
- **THEN** SHALL 排除 node_modules、target、logs、venv、.venv、.git 目錄

#### Scenario: Neo-tree 檔案排除
- **WHEN** 開啟 neo-tree 檔案總管
- **THEN** SHALL 隱藏 .git、.DS_Store、node_modules、target、Thumbs.db、desktop.ini

### Requirement: Markdown 檔案例外設定

`ftplugin/markdown.lua` SHALL 為 Markdown 檔案關閉行尾空白自動刪除，因 Markdown 以兩個空白表示換行。

#### Scenario: Markdown 保留行尾空白
- **WHEN** 編輯 Markdown 檔案
- **THEN** 存檔時 SHALL 不刪除行尾空白

### Requirement: 安裝腳本部署 Vim 配置

安裝腳本 SHALL 將 `vim/.vimrc` 複製至 `~/.vimrc`，複製前 SHALL 備份既有檔案。

| 平台 | 行為 |
|------|------|
| macOS | 複製至 `~/.vimrc` |
| Linux | 複製至 `~/.vimrc` |
| Windows | 不安裝 Vim 配置（僅安裝 Neovim） |

#### Scenario: 備份既有 .vimrc
- **WHEN** `~/.vimrc` 已存在
- **THEN** 腳本 SHALL 將其重命名為 `~/.vimrc.bak` 後再複製新檔案

#### Scenario: 直接複製 .vimrc
- **WHEN** `~/.vimrc` 不存在
- **THEN** 腳本 SHALL 直接複製

### Requirement: 安裝腳本部署 Neovim 配置

安裝腳本 SHALL 將 `nvim/` 目錄複製至 Neovim 配置路徑，複製前 SHALL 備份既有配置。

| 平台 | 配置路徑 |
|------|----------|
| macOS / Linux | `~/.config/nvim/` |
| Windows | `$env:LOCALAPPDATA\nvim\` |

#### Scenario: 備份既有 Neovim 配置
- **WHEN** Neovim 配置目錄已存在
- **THEN** 腳本 SHALL 將其重命名為 `nvim.bak` 後再複製

#### Scenario: 直接複製 Neovim 配置
- **WHEN** Neovim 配置目錄不存在
- **THEN** 腳本 SHALL 直接複製整個 `nvim/` 目錄

### Requirement: .zshrc 啟用 vim 至 nvim alias

選裝 editor 時，安裝腳本 SHALL 在 .zshrc 中加入 `alias vim='nvim'`。

#### Scenario: 選裝 editor 時啟用 alias
- **WHEN** 使用者選擇安裝 editor 環境
- **THEN** .zshrc SHALL 包含 `alias vim='nvim'`

#### Scenario: 未選裝 editor 時不加入 alias
- **WHEN** 使用者未選擇安裝 editor 環境
- **THEN** .zshrc SHALL 不包含 vim alias
