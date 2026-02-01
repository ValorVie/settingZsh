## 1. 檔案重命名與入口腳本

- [x] 1.1 將 `setup_env.sh` 重命名為 `setup_linux.sh`
- [x] 1.2 將 `update.sh` 重命名為 `update_linux.sh`
- [x] 1.3 建立 `setup.sh`（Unix 入口，uname -s 偵測後呼叫 setup_linux.sh 或 setup_mac.sh）
- [x] 1.4 建立 `update.sh`（Unix 入口，uname -s 偵測後呼叫 update_linux.sh 或 update_mac.sh）

## 2. macOS 安裝與更新腳本

- [x] 2.1 建立 `setup_mac.sh`：Homebrew 檢測、前置套件安裝（zsh git unzip xz）、Python 3.13 安裝
- [x] 2.2 `setup_mac.sh`：Maple Mono NL NF CN 字型下載並安裝至 ~/Library/Fonts/
- [x] 2.3 `setup_mac.sh`：fzf（git clone ~/.fzf）和 zoxide（curl install）安裝
- [x] 2.4 `setup_mac.sh`：備份 .zshrc 並寫入共用 Zsh 配置（與 Linux 相同內容）
- [x] 2.5 建立 `update_mac.sh`：brew update/upgrade、fzf pull、zoxide 更新、Zinit 更新、字型更新

## 3. Windows 安裝與更新腳本

- [x] 3.1 建立 `setup.bat`：以 Bypass 執行策略呼叫 setup_win.ps1
- [x] 3.2 建立 `setup_win.ps1`：偵測 PS 版本與 Profile 路徑、備份既有 Profile、複製新 Profile
- [x] 3.3 `setup_win.ps1`：安裝 PowerShell 模組（Terminal-Icons、ZLocation、PSFzf）
- [x] 3.4 `setup_win.ps1`：透過 winget 安裝 fzf 和 Starship（含 winget 不可用時的提示）
- [x] 3.5 `setup_win.ps1`：下載並安裝 Maple Mono NL NF CN 字型（含自動安裝失敗時的 fallback 提示）
- [x] 3.6 建立 `update.bat`：以 Bypass 執行策略呼叫 update_win.ps1
- [x] 3.7 建立 `update_win.ps1`：Update-Module、winget upgrade、字型更新

## 4. PowerShell Profile 修正

- [x] 4.1 將 `Microsoft.PowerShell_profile.ps1` 中 `C:\Users\jack3\miniconda3\...` 改為 `$env:USERPROFILE\miniconda3\...`
- [x] 4.2 將 `Microsoft.PowerShell_profile.ps1` 中 `C:\Users\jack3\Documents\PowerShell\...` 改為 `$env:USERPROFILE\Documents\PowerShell\...`

## 5. 文件更新

- [x] 5.1 更新 `README.md`：安裝步驟改為 `./setup.sh`（Unix）/ `setup.bat`（Windows），移除直接執行 setup_env.sh 的說明
- [x] 5.2 更新 `README.md`：腳本內容摘要反映新的檔案結構
