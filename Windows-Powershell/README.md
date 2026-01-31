打開一個**管理員權限**的 PowerShell 視窗，執行一次安裝指令（只需執行一次）：

```powershell
# 允許執行腳本
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# 允許 PSGallery
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

# 安裝推薦模組
Install-Module -Name Terminal-Icons -Scope CurrentUser -Force
Install-Module -Name ZLocation -Scope CurrentUser -Force
Install-Module -Name PSFzf -Scope CurrentUser -Force

# PSFzf 需要底層的 fzf 二進位檔案
scoop install fzf
# 或用 winget: winget install fzf

# 如果你有安裝 winget (Win10/11 內建)，安裝 Starship
winget install starship
```

---

## PowerShell 設定檔位置

在 PowerShell 中可以使用 `$PROFILE` 自動變數來查看設定檔位置：

```powershell
# 查看目前設定檔路徑
$PROFILE

# 查看所有設定檔路徑
$PROFILE | Select-Object *
```

常用的設定檔位置：

| 作用域 | Windows PowerShell 5.1 | PowerShell 7+ |
|--------|------------------------|---------------|
| 目前使用者，目前主機 | `$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1` | `$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` |
| 所有使用者，目前主機 | `$PSHOME\Microsoft.PowerShell_profile.ps1` | 同左 |
| 目前使用者，所有主機 | `$HOME\Documents\WindowsPowerShell\profile.ps1` | `$HOME\Documents\PowerShell\profile.ps1` |

常用指令：

```powershell
# 測試設定檔是否存在
Test-Path $PROFILE

# 用記事本開啟設定檔
notepad $PROFILE

# 如果設定檔不存在，建立它
if (!(Test-Path $PROFILE)) { New-Item -Type File -Path $PROFILE -Force }
```

`$PROFILE` 預設指向「目前使用者，目前主機」的設定檔，這是最常用的一個。

