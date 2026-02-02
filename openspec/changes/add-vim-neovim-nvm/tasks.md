## 1. 編輯器配置檔

- [x] 1.1 建立 `vim/.vimrc`：基礎體驗、縮排（tabstop=4）、搜尋、外觀、scrolloff=8、undofile、listchars 等設定
- [x] 1.2 建立 `nvim/init.lua`：LazyVim 入口（`require("config.lazy")`）
- [x] 1.3 建立 `nvim/lua/config/lazy.lua`：lazy.nvim bootstrap + LazyVim spec 載入
- [x] 1.4 建立 `nvim/lazyvim.json`：啟用 extras（lang.python, lang.typescript, lang.rust, lang.php, lang.json, lang.markdown, formatting.prettier, linting.eslint）
- [x] 1.5 建立 `nvim/lua/config/options.lua`：覆寫 tabstop=4, shiftwidth=4, wrap=true, mouse="", fileformat="unix", fixendofline=true
- [x] 1.6 建立 `nvim/lua/config/keymaps.lua`：自訂快鍵（預留檔案，可為空或加入 jk→Esc 等）
- [x] 1.7 建立 `nvim/lua/config/autocmds.lua`：自訂自動命令（預留檔案）
- [x] 1.8 建立 `nvim/lua/plugins/editor.lua`：telescope file_ignore_patterns（node_modules, target, logs, venv, .venv, .git）+ neo-tree filtered_items（.git, .DS_Store, node_modules, target, Thumbs.db, desktop.ini）
- [x] 1.9 建立 `nvim/ftplugin/markdown.lua`：關閉 Markdown 行尾空白自動刪除

## 2. 安裝腳本重構 — macOS

- [x] 2.1 重構 `setup_mac.sh`：將現有安裝邏輯包入 `install_zsh_env()` 函式
- [x] 2.2 新增 `ask_yes_no()` 函式：互動詢問，預設 N
- [x] 2.3 新增 `install_editor_env()` 函式：安裝 vim, neovim（`brew install vim neovim`）, nvm（curl 官方腳本 https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh）, node LTS, ripgrep, fd, lazygit（`brew install ripgrep fd lazygit`）
- [x] 2.4 新增 `save_features()` 函式：寫入 `~/.settingzsh/features`
- [x] 2.5 新增 .vimrc 和 nvim/ 配置部署邏輯（備份 + 複製）
- [x] 2.6 修改 .zshrc heredoc：zsh 基本段維持不變；選裝 editor 時追加 nvm lazy loading + `alias vim='nvim'`
- [x] 2.7 主流程串接：install_zsh_env → 詢問 → install_editor_env（條件）→ save_features

## 3. 安裝腳本重構 — Linux

- [x] 3.1 重構 `setup_linux.sh`：將現有安裝邏輯包入 `install_zsh_env()` 函式
- [x] 3.2 新增 `ask_yes_no()` 函式（與 macOS 相同邏輯）
- [x] 3.3 新增 `install_editor_env()` 函式：安裝 vim（`sudo apt install -y vim`）, neovim（從 https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz 下載解壓至 `/usr/local/`）, nvm（curl 官方腳本）, node LTS, ripgrep（`sudo apt install -y ripgrep`）, fd（`sudo apt install -y fd-find`）, lazygit（從 https://github.com/jesseduffield/lazygit/releases/latest 下載 binary 至 `/usr/local/bin/`）, build-essential（`sudo apt install -y build-essential`）
- [x] 3.4 新增 `save_features()` 函式
- [x] 3.5 新增 .vimrc 和 nvim/ 配置部署邏輯
- [x] 3.6 修改 .zshrc heredoc：同 macOS 分段策略
- [x] 3.7 主流程串接

## 4. 安裝腳本重構 — Windows

- [x] 4.1 重構 `setup_win.ps1`：將現有安裝邏輯包入 `Install-ZshEnv` 函式
- [x] 4.2 新增 `Install-EditorEnv` 函式：透過 winget 安裝 Neovim（`Neovim.Neovim`）, nvm-windows（`CoreyButler.NVMforWindows`）, ripgrep（`BurntSushi.ripgrep.MSVC`）, fd（`sharkdp.fd`）, lazygit（`JesseDuffield.lazygit`）; 執行 `nvm install lts` + `nvm use lts`
- [x] 4.3 新增互動詢問邏輯（`Read-Host` 預設 N）
- [x] 4.4 新增 nvim/ 配置部署至 `$env:LOCALAPPDATA\nvim\`（含備份）
- [x] 4.5 新增 `Save-Features` 函式：寫入 `$env:USERPROFILE\.settingzsh\features`
- [x] 4.6 主流程串接

## 5. 更新腳本修改

- [x] 5.1 修改 `update_mac.sh`：讀取 features 標記檔；zsh 段維持不變；editor 段新增 `brew upgrade neovim ripgrep fd lazygit` + nvm 更新 + `nvim --headless "+Lazy! sync" +qa`
- [x] 5.2 修改 `update_linux.sh`：讀取 features 標記檔；editor 段重新下載 neovim tar.gz + `sudo apt upgrade ripgrep fd-find` + 重新下載 lazygit binary + nvm 更新
- [x] 5.3 修改 `update_win.ps1`：讀取 features 標記檔；editor 段 `winget upgrade` 各工具 + nvm-windows 更新

## 6. 測試與文件

- [x] 6.1 更新 `tests/test_linux.sh`：新增 vim/nvim/nvm/node/rg/fd/lazygit 存在性測試
- [x] 6.2 更新 `tests/test_win.ps1`：新增 nvim/nvm/node/rg/fd/lazygit 存在性測試
- [x] 6.3 建立 `tests/test_mac.sh`：新增 macOS 環境測試（brew/fzf/zoxide/zinit/字型/editor 工具）
- [x] 6.4 更新 `README.md`：新增「編輯器環境」章節，說明互動安裝流程、LazyVim 使用方式、nvm 用法、常用 Neovim 快鍵對照表
