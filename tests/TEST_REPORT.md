# 測試報告：跨平台安裝腳本

**測試日期：** 2026-02-01
**測試人員：** Claude Code (Opus 4.5)

---

## 測試環境

| 平台 | 環境 | 版本 |
|---|---|---|
| Linux | WSL2 Debian | Linux 6.6.87.2-microsoft-standard-WSL2 |
| Windows | Native | Windows NT 10.0.26200.0, PowerShell 7.5.4 |
| macOS | 未測試 | 待日後在 macOS 環境中執行 |

---

## 測試結果摘要

| 平台 | PASS | FAIL | WARN | 結果 |
|---|---|---|---|---|
| Linux/WSL | 12 | 0 | 0 | **PASSED** |
| Windows | 12 | 0 | 0 | **PASSED** |
| macOS | - | - | - | 待測 |

---

## Linux/WSL 測試項目

| # | 測試項目 | 結果 | 說明 |
|---|---|---|---|
| 1 | setup.sh OS 偵測 | PASS | `uname -s` = Linux，正確呼叫 setup_linux.sh |
| 2 | .zshrc 備份邏輯 | PASS | 偵測到既有 .zshrc，備份邏輯可執行 |
| 3 | Python 3.13 | PASS | Python 3.13.5 已安裝 |
| 4 | 字型下載 URL | PASS | `MapleMonoNL-NF-CN.zip` HTTP 200 |
| 5a | 字型下載 | PASS | 下載成功 (152MB) |
| 5b | 字型解壓 | PASS | 解壓出 16 個 ttf 檔案 |
| 6 | 字型安裝狀態 | PASS | fc-list 找到 16 個 Maple Mono NL NF CN 字型 |
| 7a | fzf 存在性檢查 | PASS | `~/.fzf` 存在時會 git pull（不重複 clone） |
| 7b | fzf install 腳本 | PASS | `~/.fzf/install` 存在 |
| 8 | zoxide | PASS | zoxide 0.9.9 已安裝 |
| 9 | zinit | PASS | `zinit.zsh` 存在 |
| 10 | update.sh OS 偵測 | PASS | 正確對應 update_linux.sh |

## Windows 測試項目

| # | 測試項目 | 結果 | 說明 |
|---|---|---|---|
| 1 | PS 版本與 Profile 路徑 | PASS | PS 7 -> Documents\PowerShell |
| 2 | Source Profile | PASS | Windows-Powershell\Microsoft.PowerShell_profile.ps1 存在 |
| 3 | Profile 動態路徑 | PASS | 使用 `$env:USERPROFILE`，無寫死路徑 |
| 4 | winget | PASS | 可用 |
| 5a | Terminal-Icons | PASS | 已安裝 |
| 5b | ZLocation | PASS | 已安裝 |
| 5c | PSFzf | PASS | 已安裝 |
| 6 | 字型下載 URL | PASS | `MapleMonoNL-NF-CN.zip` HTTP 200 |
| 7 | 字型安裝路徑 | PASS | `%LOCALAPPDATA%\Microsoft\Windows\Fonts` 存在 |
| 8 | 字型登錄檔 | PASS | `HKCU:\...\Fonts` 存在 |
| 9 | setup_win.ps1 字型檔名 | PASS | 使用正確檔名 `MapleMonoNL-NF-CN.zip` |
| 10 | update_win.ps1 字型檔名 | PASS | 使用正確檔名 `MapleMonoNL-NF-CN.zip` |

---

## macOS 待測項目

以下項目需在 macOS 環境中執行 `tests/test_linux.sh`（OS 偵測會自動調整），或手動驗證：

- [ ] `setup.sh` 偵測為 Darwin 並呼叫 `setup_mac.sh`
- [ ] Homebrew 檢測（已安裝 / 未安裝提示）
- [ ] `brew install zsh git unzip xz`
- [ ] `brew install python@3.13`
- [ ] 字型下載 `MapleMonoNL-NF-CN.zip` 並安裝至 `~/Library/Fonts/`
- [ ] fzf `git clone --depth 1`（新安裝）/ `git pull`（已存在）
- [ ] zoxide curl 安裝
- [ ] .zshrc 備份與 heredoc 寫入
- [ ] zinit 首次啟動自動安裝
- [ ] `update_mac.sh` 的 `brew update && brew upgrade`
- [ ] `update_mac.sh` 的 fzf git pull
- [ ] `update_mac.sh` 的 zinit self-update + plugin update
- [ ] `update_mac.sh` 的字型更新

---

## 修正記錄

本次測試發現並修正了以下 BUG：

### BUG 1: 字型檔名錯誤 (HTTP 404)

**問題：** 所有腳本使用的字型檔名與 GitHub Release 實際檔名不符。

| 腳本 | 修正前 | 修正後 |
|---|---|---|
| setup_linux.sh | `MapleMono-NL-NF-CN.zip` | `MapleMonoNL-NF-CN.zip` |
| update_linux.sh | `MapleMono-NL-NF-CN.zip` | `MapleMonoNL-NF-CN.zip` |
| setup_mac.sh | `MapleMono-NL-NF-CN.zip` | `MapleMonoNL-NF-CN.zip` |
| update_mac.sh | `MapleMono-NL-NF-CN.zip` | `MapleMonoNL-NF-CN.zip` |
| setup_win.ps1 | `MapleMono-NL-NF-CN-autohint.zip` | `MapleMonoNL-NF-CN.zip` |
| update_win.ps1 | `MapleMono-NL-NF-CN-autohint.zip` | `MapleMonoNL-NF-CN.zip` |

**根因：** Maple Font v7.9 的命名規則為 `MapleMonoNL-NF-CN`（無額外連字號），且 NF-CN 版本不提供獨立的 autohint 包。

### BUG 2: setup_linux.sh fzf 重複安裝會失敗

**問題：** `setup_linux.sh` 第 40 行直接執行 `git clone --depth 1 ... ~/.fzf`，若 `~/.fzf` 已存在會因目錄非空而失敗。

**修正：** 加入存在性檢查，已存在時改用 `git -C ~/.fzf pull`（與 `setup_mac.sh` 一致）。

---

## 測試腳本

- `tests/test_linux.sh` — Linux/WSL/macOS 測試腳本
- `tests/test_win.ps1` — Windows 測試腳本
