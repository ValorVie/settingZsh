# settingZsh 卸載與安全重置設計

**日期：** 2026-04-06  
**狀態：** draft  
**範圍：** `codex/settingzsh-chezmoi` branch 的 public baseline 卸載、手動重置文件、LXC/login shell 安裝說明

## 1. 背景

目前專案已經明確定義 fresh install 與 baseline update 流程，但沒有正式的「移除這個專案」流程。

實際使用中已出現兩個風險點：

1. 使用者可能只刪 `~/.config/chezmoi`，卻留下 `~/.local/share/chezmoi` 的舊 source state，導致重新 `chezmoi init --apply` 時仍使用舊版 schema。
2. 在 LXC 這類環境中，安裝後雖然可手動 `exec zsh`，但帳號的 login shell 不會自動切成 `/bin/zsh`；若使用者希望預設 shell 真的改成 zsh，仍需手動執行 `chsh -s /bin/zsh "$(whoami)"`。

本設計要補上的不是「一鍵重新安裝」，而是「安全卸載與乾淨重置」。

## 2. 目標

- 提供正式的 manual uninstall / reset 文件，讓使用者能安全移除 `settingZsh`
- 提供對應腳本，支援 `dry-run`、`execute`、`restore`
- 預設行為必須保守，不能誤刪使用者原本就有的 shell / SSH / PowerShell / 共用工具設定
- 卸載流程不自動重新執行 `chezmoi init --apply`
- 文件要明確說明 LXC / container 情境下的 login shell 行為與手動 `chsh` 步驟

## 3. 非目標

- 不實作「一鍵 reinstall」
- 不嘗試還原未知的第三方工具狀態，例如系統套件管理器已安裝的 `zsh`、`git`、`fzf`
- 不保證回到「機器出廠狀態」
- 不自動推斷並覆蓋使用者想要的最終 login shell

## 4. 使用者需求重述

使用者要的是：

- 把 `settingZsh` 視為一個可移除的專案
- 卸載必須乾淨
- 但不能影響其他原有設定
- 不需要在卸載完成後自動重新 init

這代表卸載邏輯不能用「安裝過就刪」這種路徑清單策略，而要用 ownership-based uninstall。

## 5. 方案比較

### 方案 A：激進路徑刪除

做法：
- 直接刪掉所有安裝清單中曾經提到的路徑

優點：
- 實作最簡單

缺點：
- 風險最高
- 很容易誤刪共享路徑，例如 `~/.local/bin`、`~/.fzf`、`~/.local/share/zinit/zinit.git`

### 方案 B：純保守 ownership 刪除

做法：
- 只刪能百分之百確認由 `settingZsh` 寫入且格式可辨識的檔案

優點：
- 最安全

缺點：
- 會留下不少工作目錄與安裝物
- 使用者仍需要額外手動清理

### 方案 C：分級卸載，推薦

做法：
- 把路徑分成 `專案專屬`、`設定可辨識可局部還原`、`共享路徑需保守處理`
- 專案專屬的目錄直接納入備份後移除
- 共享路徑預設只在 `dry-run` 報告列出，不自動刪除
- 針對 `.zshrc`、PowerShell profile、SSH config 採內容層級的 restore / strip 策略

優點：
- 安全性與可用性平衡最好
- 能處理「卸載這個專案」而非「清空使用者家目錄」

缺點：
- 實作與測試成本較高

**決策：採用方案 C。**

## 6. ownership 模型

### 6.1 專案專屬路徑

這些路徑可視為 `settingZsh` 專屬，預設納入備份後移除：

- `~/.local/share/chezmoi`
- `~/.config/chezmoi`
- `~/.cache/chezmoi`
- `~/.config/settingzsh`
- `~/.local/share/settingzsh`

理由：
- 它們在目前專案語境中屬於 source state、chezmoi config/state、public baseline 工作目錄
- 使用者若要保留其中內容，應由 restore 流程取回，而不是在 live 位置常駐

### 6.2 可辨識設定檔

這些路徑不能直接整份刪除，必須先看內容：

- `~/.zshrc`
- `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`
- `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1`
- `~/.ssh/config`
- `~/.ssh/config.d/10-common.conf`

策略：

- `.zshrc`
  - 若整份內容等於 pure bootstrap file，備份後直接移除
  - 若包含 inline bootstrap block，移除 `settingZsh bootstrap` 區塊，保留其餘內容
  - 若移除後為空，備份後刪檔
- PowerShell profile
  - 若檔案內容是純橋接到 `public-baseline.ps1`，備份後移除
  - 若有混合使用者內容，僅移除 `settingZsh` 橋接段
- SSH
  - `~/.ssh/config.d/10-common.conf` 若與 public baseline 模板一致，備份後移除
  - `~/.ssh/config` 僅在內容可辨識為 public baseline 單一輸出時才移除；若含使用者自訂內容，預設不改

### 6.3 共享路徑

這些路徑預設只報告，不自動刪除：

- `~/.local/bin`
- `~/.fzf`
- `~/.local/share/zinit/zinit.git`
- `~/.local/share/fonts/MapleMono`
- `~/Documents/PowerShell`
- `~/Documents/WindowsPowerShell`

理由：
- 它們很可能被其他專案或手動流程共用
- 即使最初由 `settingZsh` 觸發建立，也不能安全假定只有本專案在使用

若使用者真的要刪這些共享路徑，文件可以提供「人工確認後手動刪除」段落，但主腳本不提供預設自動清理。

## 7. 備份與還原模型

### 7.1 備份目錄

卸載不做直接永久刪除，而是先搬到備份目錄：

- `~/.local/share/settingzsh-uninstall-backups/<timestamp>/`

備份內容包含：

- `manifest.json`
- `report.md`
- `owned/`：被完整搬走的專案專屬路徑
- `rewritten/`：被局部改寫前的原始檔案副本

### 7.2 manifest

`manifest.json` 至少記錄：

- 建立時間
- 執行模式
- 目標 home
- 完整搬移的路徑
- 局部改寫的路徑
- 未處理但需人工確認的共享路徑

### 7.3 restore

restore 只從先前 uninstall 產生的 backup 還原：

- 完整搬移的路徑：搬回原位
- 局部改寫的路徑：用備份原文覆蓋回去

restore 不負責：

- 還原系統套件
- 還原 `apt` 安裝的 `zsh` / `git`
- 還原共享路徑中未被卸載的其他工具狀態

## 8. 腳本設計

### 8.1 位置

新增一支可直接在 repo 內執行的腳本：

- `scripts/uninstall-settingzsh.sh`

### 8.2 CLI 介面

```bash
scripts/uninstall-settingzsh.sh --dry-run
scripts/uninstall-settingzsh.sh --execute
scripts/uninstall-settingzsh.sh --restore <backup-id>
```

可選參數：

- `--home <path>`：指定目標家目錄
- `--backup-root <path>`：指定備份根目錄

### 8.3 行為

`--dry-run`
- 不改動檔案
- 輸出：
  - 專案專屬路徑將被移除清單
  - 可辨識設定檔將被 strip / remove 的動作
  - 共享路徑人工確認清單

`--execute`
- 先建立 backup
- 產生 manifest 與 report
- 執行 move / rewrite
- 結尾印出 restore 指令與 backup id

`--restore <backup-id>`
- 根據 manifest 還原先前移除與改寫的內容

### 8.4 安全要求

- 沒有 `--execute` 時不得修改任何檔案
- 所有刪除動作都轉換成 `mv` 到 backup root，不直接 `rm -rf`
- 若目標路徑超出指定 `--home`，立即失敗
- 若偵測到非預期 symlink 跳脫 `home`，立即失敗

## 9. 文件設計

### 9.1 新增文件

新增：

- `docs/uninstall-guide.md`

內容包含：

- 什麼情況需要卸載 / 重置
- `dry-run` → `execute` → `restore` 標準流程
- 專案專屬、局部改寫、共享路徑三種類別
- 常見風險說明
- LXC / container 注意事項

### 9.2 README 補充

README 新增一節：

- 卸載與重置

至少提供：

- `docs/uninstall-guide.md` 連結
- 若 source state 疑似卡在舊版，先移除 `~/.local/share/chezmoi`
- 不自動重新 init

## 10. LXC / login shell 行為

目前 repo 只在 README 提示 `exec zsh`，沒有任何 `chsh` 邏輯。

這代表目前行為是：

- 安裝流程會確保 `zsh` 可用
- 使用者可以在當前 session 手動 `exec zsh`
- 但系統帳號的 login shell 不會自動被改成 `/bin/zsh`

這在 LXC / server 環境中是可預期的，因為：

- `chsh` 是使用者帳號層級變更
- 行為具環境依賴，可能受 PAM、容器映像、非互動 shell 限制影響
- 自動執行 `chsh` 屬於侵入性較高的帳號設定修改，不應在 public baseline install script 中默默執行

**設計決策：**

- 不在 install script 中自動執行 `chsh`
- 在安裝文件加入明確說明：
  - 若只想在當前 session 進入 zsh，用 `exec zsh`
  - 若想把帳號預設 shell 改成 zsh，手動執行：

```bash
chsh -s /bin/zsh "$(whoami)"
```

- 在卸載文件中也補充反向說明：
  - 若使用者先前手動把 login shell 改成 zsh，卸載 `settingZsh` 不會自動替他改回其他 shell

## 11. 測試策略

### 11.1 文件測試

- 更新 `tests/test_settingzsh_docs.py`
- 驗證 README 與 uninstall guide 都有：
  - uninstall / reset 流程
  - `~/.local/share/chezmoi` 清理說明
  - `exec zsh`
  - `chsh -s /bin/zsh "$(whoami)"`

### 11.2 腳本測試

新增 shell 測試，覆蓋：

- `dry-run` 不修改檔案
- `execute` 會建立 backup root 與 manifest
- pure bootstrap `.zshrc` 會移除
- 混合內容 `.zshrc` 只 strip bootstrap block
- pure bridge PowerShell profile 會移除
- 共享路徑不會被自動刪除
- `restore` 會還原被移除與改寫的檔案

## 12. 風險與對策

### 風險 1：誤刪共享路徑

對策：
- 共享路徑只報告，不預設移除

### 風險 2：局部 rewrite 規則誤判

對策：
- 僅對有明確 marker / 純橋接格式的檔案做 rewrite
- 不可辨識時採 no-op + warning

### 風險 3：restore 覆蓋使用者後續變更

對策：
- restore 前提示目前檔案若已存在會被覆蓋
- 仍先做二次 backup

## 13. 驗收標準

- 使用者可以在不重新 init 的前提下，安全移除 `settingZsh` 的 source state 與 baseline 痕跡
- `.zshrc` 若原本含使用者內容，卸載後仍保留原有內容，只移除 `settingZsh` bootstrap
- 共享路徑預設不被腳本自動刪除
- README 與 uninstall guide 都清楚說明：
  - source state 在 `~/.local/share/chezmoi`
  - uninstall 不等於重裝
  - `exec zsh` 與 `chsh` 的差別

