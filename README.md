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

### Linux / macOS 安裝內容

- **備份原有 Zsh 配置檔：** 若已有 `.zshrc`，會自動備份為 `.zshrc.bak`
- **安裝必要工具：**
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
   - 編輯 `~/.zshrc` 文件，自訂自己的配置。
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

