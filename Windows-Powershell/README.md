# Windows-Powershell（歷史資產）

這個目錄保留的是 **舊版手工維護的 PowerShell profile 參考檔**，不是目前 `chezmoi` 版本的 source state。

## 目前版本真正使用的檔案

Windows 的現行實作請看：

- `home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl`
- `home/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1.tmpl`
- `home/dot_config/settingzsh/powershell/public-baseline.ps1.tmpl`
- `run_once_before_10-install-base-packages.ps1.tmpl`
- `run_once_before_20-install-fonts.ps1.tmpl`
- `run_onchange_after_30-install-editor.ps1.tmpl`

也就是說，現在的主要入口是 `chezmoi init --apply` / `chezmoi apply`，不是手動照這個資料夾裡的舊說明逐步安裝。

## 這個資料夾現在還有什麼用途

- 對照舊版 PowerShell profile 的歷史內容
- 協助理解某些舊設定為什麼存在
- 做 legacy Windows 行為比對時的參考

## 如果你要看目前 PowerShell profile 會落到哪裡

常用 target 路徑如下：

| 目標 | 路徑 |
|------|------|
| Windows PowerShell 5.1 | `$HOME\\Documents\\WindowsPowerShell\\Microsoft.PowerShell_profile.ps1` |
| PowerShell 7+ | `$HOME\\Documents\\PowerShell\\Microsoft.PowerShell_profile.ps1` |

兩者都只會 source 同一份 baseline：

```powershell
$HOME/.config/settingzsh/powershell/public-baseline.ps1
```

若你要安裝目前版本，請回到 `README.md` 的 `chezmoi` 安裝流程，不要直接照這個目錄的舊手工說明操作。
