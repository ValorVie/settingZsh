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
