# README: Zsh + Zinit + FZF + Python 3.13

## 功能

- 安裝並設定 **Zsh** 為預設 Shell
- 安裝 **Python 3.13** 與 **pip**
- 安裝 **fzf**（模糊搜尋工具）
- 安裝 **zoxide**（快速目錄切換工具）
- 配置 **Zinit** 來管理 Zsh 插件
- 安裝並設定 **Maple Mono NL NF CN**
- 預設 Zsh 插件包含：
  - **Powerlevel10k**（高效能 Zsh 提示行）
  - **fzf-tab**（fzf 選單自動補全）
  - **zsh-syntax-highlighting**（語法高亮）
  - **zsh-autosuggestions**（命令建議）
  - 其他實用工具和命令片段
- **（選裝）編輯器環境**：Vim、Neovim（LazyVim）、nvm、ripgrep、fd、lazygit

---

## 安裝步驟

### Linux / macOS（統一入口）

1. **Linux** — 確保系統具備基礎工具：
   ```bash
   sudo apt update -y && sudo apt install -y zsh git xz-utils fontconfig unzip
   ```
   **macOS** — 確保已安裝 [Homebrew](https://brew.sh/)（腳本會自動透過 brew 安裝所需套件）。

2. 切換預設 Shell 為 Zsh（Linux）：
   ```bash
   chsh -s /bin/zsh "$(whoami)"
   ```
   - 如果無法切換預設 Shell，手動修改登入時的 shell，在 ~/.bashrc 或 ~/.profile 末尾加上：
      ```bash
      exec zsh
      ```

3. 執行安裝腳本（自動偵測 Linux/macOS）：
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

4. 更新套件（可選）：
   ```bash
   chmod +x update.sh
   ./update.sh
   ```

### Windows

1. 執行安裝腳本（自動部署 PowerShell Profile、安裝模組與字型）：
   ```
   setup.bat
   ```

2. 更新套件（可選）：
   ```
   update.bat
   ```


---

## 腳本內容摘要

### 檔案結構

| 檔案 | 說明 |
| :--- | :--- |
| `setup.sh` | Unix 統一入口（自動偵測 Linux/macOS） |
| `setup_linux.sh` | Linux（apt）安裝腳本 |
| `setup_mac.sh` | macOS（Homebrew）安裝腳本 |
| `setup.bat` / `setup_win.ps1` | Windows 安裝腳本 |
| `update.sh` | Unix 統一更新入口 |
| `update_linux.sh` | Linux 更新腳本 |
| `update_mac.sh` | macOS 更新腳本 |
| `update.bat` / `update_win.ps1` | Windows 更新腳本 |
| `vim/.vimrc` | Vim 基礎配置（伺服器 fallback 用） |
| `nvim/` | Neovim（LazyVim）完整配置 |
| `lib/config_merge.py` | 配置檔合併引擎（Python 3.10+） |
| `lib/pyproject.toml` | 合併引擎專案定義 |
| `templates/` | Zsh 配置模板（從 setup 腳本提取） |
| `tests/test_mac.sh` | macOS 環境驗證腳本 |
| `tests/test_linux.sh` | Linux/WSL 環境驗證腳本 |
| `tests/test_win.ps1` | Windows 環境驗證腳本 |
| `tests/test_config_merge.py` | 合併引擎單元測試（pytest） |

### Linux / macOS 安裝內容

- **智慧合併配置檔：** 使用 section markers 機制管理 `.zshrc` 和 `.vimrc`
  - **首次安裝：** 寫入管理區段 + 空的使用者自訂區段
  - **既有配置升級：** 自動去除重複設定，保留使用者獨有自訂
  - **重複執行：** 僅更新管理區段，使用者自訂不受影響
  - 每次合併後輸出差異摘要（移除的重複行、值衝突、保留的自訂行）
- **安裝必要工具：**
  - 安裝 **uv**（Python 環境管理）
  - 安裝 **Python 3.13** 與 **pip**
  - 安裝 **fzf** 與 **zoxide**
  - 自動下載並安裝 **Maple Mono NL NF CN** 字型
- **自動配置 Zsh 插件：**
  - 使用 **Zinit** 安裝和管理插件
  - 預設啟用高效能提示行（Powerlevel10k）
  - 提供多種實用的 Zsh 設定和快捷鍵

### Windows 安裝內容

- **自動部署 PowerShell Profile** 至正確路徑（支援 PS 5.1 和 7+）
- **安裝 PowerShell 模組：** Terminal-Icons、ZLocation、PSFzf
- **透過 winget 安裝：** fzf、Starship
- **下載並安裝 Maple Mono NL NF CN 字型**（自動安裝失敗時提示手動安裝）

---

## 編輯器環境（選裝）

安裝腳本執行時會詢問是否安裝編輯器環境，預設**不安裝**（僅處理 Zsh）。選擇安裝後，會一併安裝以下工具：

| 工具 | 說明 |
| :--- | :--- |
| **Vim** | 基礎文字編輯器（伺服器 SSH 環境 fallback） |
| **Neovim** | 現代化編輯器，搭配 LazyVim 框架 |
| **nvm** / **nvm-windows** | Node.js 版本管理器（LazyVim LSP 相依） |
| **Node.js LTS** | 透過 nvm 安裝 |
| **ripgrep** | 快速全文搜尋（Telescope 相依） |
| **fd** | 快速檔案搜尋（Telescope 相依） |
| **lazygit** | 終端 Git GUI（LazyVim 內建整合） |

### 互動安裝流程

```
$ ./setup.sh
=== Zsh 環境安裝 ===
...（Zsh 基礎環境安裝）...

是否安裝編輯器環境？(Vim + Neovim + nvm + 開發工具) [y/N]:
```

- 輸入 `y`：安裝完整編輯器環境
- 直接 Enter 或輸入 `n`：僅保留 Zsh 環境

安裝選擇會記錄在 `~/.settingzsh/features`（Windows：`%USERPROFILE%\.settingzsh\features`），`update.sh` 會據此決定更新範圍。

### 各平台安裝差異

| 工具 | macOS | Linux (Debian/Ubuntu) | Windows |
| :--- | :--- | :--- | :--- |
| Vim | `brew install vim` | `sudo apt install vim` | —（不安裝） |
| Neovim | `brew install neovim` | GitHub Release tar.gz | `winget install Neovim.Neovim` |
| nvm | curl 官方安裝腳本 | curl 官方安裝腳本 | `winget install CoreyButler.NVMforWindows` |
| ripgrep | `brew install ripgrep` | `sudo apt install ripgrep` | `winget install BurntSushi.ripgrep.MSVC` |
| fd | `brew install fd` | `sudo apt install fd-find` | `winget install sharkdp.fd` |
| lazygit | `brew install lazygit` | GitHub Release binary | `winget install JesseDuffield.lazygit` |

### LazyVim 使用方式

本專案使用 [LazyVim](https://www.lazyvim.org/) 作為 Neovim 預設框架，已啟用以下 Extras：

- `lang.python`、`lang.typescript`、`lang.rust`、`lang.php`
- `lang.json`、`lang.markdown`
- `formatting.prettier`、`linting.eslint`

首次啟動 Neovim 時，LazyVim 會自動下載所有插件與 LSP 伺服器，請確保網路連線正常。

```bash
nvim   # 首次啟動會自動安裝插件
```

### 常用 Neovim 快鍵（VSCode 對照）

| 功能 | VSCode | Neovim (LazyVim) |
| :--- | :--- | :--- |
| 檔案搜尋 | `Ctrl+P` | `<Space>ff` |
| 全域搜尋 | `Ctrl+Shift+F` | `<Space>sg` |
| 檔案總管 | `Ctrl+Shift+E` | `<Space>e` |
| 快速修正 | `Ctrl+.` | `<Space>ca` |
| 跳至定義 | `F12` | `gd` |
| 查看參照 | `Shift+F12` | `gr` |
| 重新命名 | `F2` | `<Space>cr` |
| 格式化 | `Shift+Alt+F` | `<Space>cf` |
| 終端機 | `` Ctrl+` `` | `<Space>ft` |
| Git GUI | Source Control 面板 | `<Space>gg`（lazygit） |
| 關閉檔案 | `Ctrl+W` | `<Space>bd` |
| 分割視窗 | `Ctrl+\` | `<Space>-` / `<Space>\|` |
| 切換緩衝區 | `Ctrl+Tab` | `<Space>,` |
| 命令面板 | `Ctrl+Shift+P` | `<Space>:` |

> **提示：** `<Space>` 即 Leader 鍵（空白鍵）。按下後稍等會顯示 which-key 選單，列出所有可用指令。

### nvm 用法

nvm 採用 lazy loading 機制，首次使用 `node`、`npm`、`npx` 或 `nvm` 時才會載入，不影響 shell 啟動速度。

```bash
# 查看已安裝版本
nvm ls

# 安裝特定版本
nvm install 20

# 切換版本
nvm use 20

# 設定預設版本
nvm alias default 20
```

Windows 使用 nvm-windows，指令略有不同：
```powershell
nvm list
nvm install lts
nvm use lts
```

---

## 字型設定（解決破圖問題）

在 Windows 環境下使用 Claude Code 等現代 CLI 工具時，常見 CJK 字元導致的渲染錯位（Rendering Artifacts）。安裝支援 Nerd Font 圖示且正確處理中文寬度的字型可有效解決此問題。

### 推薦字型

| 字型 | 特色 | 適合場景 |
| :--- | :--- | :--- |
| [Maple Mono NL NF CN](https://github.com/subframe7536/maple-font) | 無連字 + Nerd Font + 中文，終端機最穩 | 跨平台通用首選 |
| [Sarasa Term TC](https://github.com/be5invis/Sarasa-Gothic) | 嚴格 2:1 對齊，台灣標準字形 | 追求精確對齊 |

### 安裝 Maple Mono（各平台）

- **Windows：** 下載 `MapleMono-NL-NF-CN-autohint.zip`，解壓後全選安裝
- **macOS：** 下載 `MapleMono-NL-NF-CN.zip`，雙擊 `.ttf` 安裝
- **Linux：**
  ```bash
  mkdir -p ~/.local/share/fonts/MapleMono
  unzip MapleMono-NL-NF-CN.zip -d ~/.local/share/fonts/MapleMono
  fc-cache -fv
  ```

### 終端機字型設定

**Windows Terminal（settings.json）：**
```json
{
    "profiles": {
        "defaults": {
            "font": {
                "face": "Maple Mono NL NF CN",
                "size": 12
            }
        }
    }
}
```

**VS Code（settings.json）：**
```json
{
    "editor.fontFamily": "'Maple Mono NL NF CN', 'Menlo', 'Monaco', 'Courier New', monospace",
    "editor.fontSize": 14,
    "editor.fontLigatures": false,
    "terminal.integrated.fontFamily": "'Maple Mono NL NF CN'"
}
```

> **字型安裝原則：** 字型安裝在「顯示端」。透過 SSH 連線遠端時，字型安裝在本機；遠端主機只需確保 `$LANG` 為 UTF-8。

詳細說明請參閱 [Claude Code Windows 破圖解決方案](message/Claude%20Code%20Windows%20破圖解決方案%20.md)。

---

## 配置檔合併引擎

Setup 腳本內部使用合併引擎管理 `.zshrc` 和 `.vimrc`，你也可以直接呼叫它來預覽或手動合併。

### 預覽合併結果（不寫入）

```bash
uv run lib/config_merge.py \
  --target ~/.zshrc \
  --template templates/zshrc_base_mac.zsh \
  --section zsh-base \
  --type zsh \
  --dry-run
```

輸出範例：

```
=== 配置檔合併摘要：.zshrc ===
  管理區段：已寫入 (zsh-base)
  移除重複：3 行
    - alias ls='ls --color'
    - setopt appendhistory
    - bindkey '^f' autosuggest-accept
  值衝突：0 行
  保留自訂：5 行
  備份檔案：~/.zshrc.bak.20260202-153000
================================
```

### 選項說明

| 選項 | 必填 | 說明 |
| :--- | :--- | :--- |
| `--target` | 是 | 目標檔案（如 `~/.zshrc`） |
| `--template` | 是 | 模板檔案（如 `templates/zshrc_base_mac.zsh`） |
| `--section` | 是 | 區段 ID（`zsh-base`、`editor`、`vimrc`） |
| `--type` | 是 | 檔案類型：`zsh` 或 `vim` |
| `--dry-run` | 否 | 僅輸出摘要，不寫入檔案 |
| `--no-color` | 否 | 停用彩色輸出 |

### 合併行為

| 情境 | 行為 |
| :--- | :--- |
| 目標檔案不存在 | 全新寫入（管理區段 + 空的使用者區段） |
| 目標已有 settingZsh 標記 | 僅更新對應的管理區段，使用者區段不動 |
| 目標有內容但無標記（首次升級） | 備份原檔、自動去除與模板重複的行、保留使用者獨有設定 |

---

## 常見問題

1. **如何立即套用新設定？**
   執行以下指令：
   ```bash
   exec zsh
   ```

2. **如何確認 Zsh 是否為預設 Shell？**
   執行以下指令確認：
   ```bash
   echo $SHELL
   ```
   若回傳結果為 `/bin/zsh`，則表示已成功設為預設。

3. **字體安裝後沒有生效？**
   - 確認已重啟終端機。
   - 使用終端機的設定選項更改字體為 **Maple Mono NL NF CN**。

4. **如何進一步自訂 Zsh？**
   - 在 `~/.zshrc` 的 `settingZsh:user:begin` 和 `settingZsh:user:end` 標記之間加入自訂設定，重複執行 setup 腳本時不會被覆蓋。
   - 配置 **Powerlevel10k**，執行以下指令：
     ```bash
     p10k configure
     ```

5. **Claude Code 在 Windows 上破圖怎麼辦？**
   - 安裝 [Maple Mono NL NF CN](https://github.com/subframe7536/maple-font) 字型
   - 在 Windows Terminal 和 VS Code 中設定該字型
   - 確保 Claude Code 更新至 v2.1.19 以上版本
   - 詳細解決方案見 [破圖解決方案文件](message/Claude%20Code%20Windows%20破圖解決方案%20.md)

---

## 注意事項

- **Root 使用者：** 若以 root 身份執行腳本，請手動修改 `~/.zshrc` 中的環境變數路徑。
- **重新登入：** 若切換 Shell 後未生效，請登出並重新登入。
- **配置合併：** `~/.zshrc` 中 `settingZsh:managed:*` 標記之間的內容由腳本管理，手動修改會在下次執行時被覆蓋。自訂設定請放在 `settingZsh:user` 區段內。

---

## 更新套件

**Linux / macOS：**
```bash
./update.sh
```

**Windows：**
```
update.bat
```

