# settingZsh 卸載 / 重置指南

這份文件只講 **手動卸載 / 重置**，不是重新安裝。

如果你只是想把目前這台機器的 `settingZsh` 移除、保留其他原有設定，請照這份文件做。

## 什麼情況需要卸載 / 重置

你可能需要這個流程的情況包括：

- 這台機器要交接、退役，或你不再要這份 public baseline
- 你想移除 `settingZsh`，但保留自己原本的 shell / SSH / PowerShell 設定
- 你懷疑 `~/.local/share/chezmoi` 還留著舊 source state
- 你先前曾經手動調整過 `~/.zshrc`、profile 或 SSH 設定，想先回到可控狀態再決定要不要重裝

這不是 reinstall，也就是不自動重新 init；流程本身不會自動重新 init。

## 正式入口

正式入口是：

```bash
scripts/uninstall-settingzsh.sh
```

標準參數：

```bash
scripts/uninstall-settingzsh.sh --dry-run
scripts/uninstall-settingzsh.sh --execute
scripts/uninstall-settingzsh.sh --restore <backup-id>
```

可選參數：

- `--home <path>`：指定要處理的 home
- `--backup-root <path>`：指定備份根目錄

預設備份位置會是：

```text
~/.local/share/settingzsh-uninstall-backups/<backup-id>/
```

## 標準流程

### 1. 先跑 `--dry-run`

`--dry-run` 只列出會發生什麼事，不改動任何檔案。

你應該先確認三件事：

- 哪些路徑會被完整移除
- 哪些檔案只會被局部改寫
- 哪些共享路徑只會被列出、等待人工確認

### 2. 再跑 `--execute`

`--execute` 會先建立 backup，再做移除或改寫。

這一步結束後，你會拿到 backup id，之後若要還原，就用同一個 id 執行 `--restore <backup-id>`。

### 3. 需要回復時再跑 `--restore <backup-id>`

restore 只會從前一次卸載產生的 backup 還原內容。

如果 restore 當下目標位置已經有新內容，腳本會先把現況做一份二次 backup，再覆蓋回原始內容。

restore 不會：

- 重新安裝 `settingZsh`
- 自動重新 init
- 幫你把系統套件回到原狀

## 三類路徑

### 專案專屬

這類路徑可以視為 `settingZsh` 專屬，通常會先備份再移除：

- `~/.local/share/chezmoi`
- `~/.config/chezmoi`
- `~/.cache/chezmoi`
- `~/.config/settingzsh`
- `~/.local/share/settingzsh`

這些位置多半是 source state、chezmoi config/state，或 public baseline 的工作目錄。

### 局部改寫

這類路徑不能直接整份刪掉，必須看內容後決定要移除哪一段：

- `~/.zshrc`
- `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`
- `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1`
- `~/.ssh/config`
- `~/.ssh/config.d/10-common.conf`

原則是：

- 如果內容是純 `settingZsh` 產物，就可備份後移除
- 如果還混有你自己的內容，就只 strip `settingZsh` 那一段
- 如果內容不可辨識，就不要貿然動手

補充：SSH 目前只在 `~/.ssh/config` / `~/.ssh/config.d/10-common.conf` 可明確辨識為 pure baseline 時才會備份後移除；若含使用者自訂內容，預設不改。

### 共享路徑

這類路徑只人工確認，不預設自動刪除：

- `~/.local/bin`
- `~/.fzf`
- `~/.local/share/zinit/zinit.git`
- `~/.local/share/fonts/MapleMono`
- `~/Documents/PowerShell`
- `~/Documents/WindowsPowerShell`

原因很單純：這些路徑很可能也被其他工具、其他專案或手動流程共用。

## 你不需要做的事

卸載結束後，不要立刻把它當成重新安裝流程。

你不需要，也不應該在卸載腳本裡自動做這些事：

- 自動重新 init
- 自動重新 apply
- 自動重建你自己的 login shell 設定

如果你原本就想重裝，請先把卸載流程走完，再回到 [README.md](../README.md) 的 `fresh install` 流程。

## `exec zsh` 與 `chsh` 的差別

如果你只是想把目前這個 terminal session 切到 zsh，用：

```bash
exec zsh
```

`exec zsh` 只影響目前 session，不會改帳號的 login shell。

如果你要把 login shell 也切成 zsh，請手動執行：

```bash
chsh -s /bin/zsh "$(whoami)"
```

這在 LXC / container / server 環境特別重要。

如果你先前手動把 login shell 改成 `/bin/zsh`，卸載不會替你改回去。

## 常見風險

- 直接刪 `~/.local/share/chezmoi` 但沒看 `~/.zshrc`、profile、SSH 內容，容易留下半套狀態
- 看到共享路徑就一併刪，容易誤傷其他工具
- 把卸載流程當成重新安裝流程，會讓你更難判斷哪些內容是舊 source state，哪些是你自己的設定

如果你不確定，先跑 `--dry-run`，不要直接 `--execute`。
