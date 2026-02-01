## Context

settingZsh 專案目前僅透過 `setup_env.sh` 和 `update.sh` 支援 Linux（apt）環境。macOS 使用者無法使用這些腳本，Windows 使用者雖有 PowerShell Profile 但缺乏自動部署機制。

目前檔案結構：
- `setup_env.sh` — Linux 專用，使用 apt 安裝
- `update.sh` — Linux 專用，使用 apt 更新
- `Windows-Powershell/Microsoft.PowerShell_profile.ps1` — Windows 手動部署，路徑寫死

## Goals / Non-Goals

**Goals:**
- 三平台（Linux/macOS/Windows）都能透過單一入口完成環境安裝與更新
- 平台腳本各自獨立，職責清晰，易於維護
- `.zshrc` 配置在 Linux 和 macOS 之間完全共用
- PowerShell Profile 路徑動態化，不綁定特定使用者

**Non-Goals:**
- 不支援 WSL 內的自動安裝（WSL 視為 Linux 環境，直接使用 Linux 腳本）
- 不處理 Linux 非 Debian 系發行版（如 RHEL/Arch）
- 不自動安裝 Homebrew（僅檢測並提示）
- Windows 字型安裝失敗時不強制重試（提示使用者手動安裝）

## Decisions

### D1: 平台各自腳本 + 共用入口（選項 B）

**選擇**：每個平台一個獨立腳本，Unix 入口透過 `uname -s` 分發。

**替代方案**：單一腳本內做 OS 判斷（選項 A）。

**理由**：職責分離清楚，單一腳本不會因平台邏輯交織而變得過長。雖然檔案數量較多，但每個檔案的邏輯單純，維護成本較低。

### D2: macOS fzf 使用 git clone 安裝

**選擇**：macOS 的 fzf 安裝統一使用 `git clone ~/.fzf`，與 Linux 一致。

**替代方案**：`brew install fzf`。

**理由**：`.zshrc` 中已寫死 `[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh`，若用 brew 安裝，此行不會生效。統一安裝方式可保持 `.zshrc` 完全共用。

### D3: Windows 字型安裝採 fallback 策略

**選擇**：嘗試透過 PowerShell 自動安裝字型至 `$env:LOCALAPPDATA\Microsoft\Windows\Fonts\`，失敗時輸出提示訊息與下載檔案路徑，由使用者手動安裝。

**替代方案**：強制要求管理員權限安裝至系統字型目錄。

**理由**：使用者層級字型目錄不需要管理員權限，相容性更好。自動安裝可能因權限或防毒軟體而失敗，fallback 機制確保流程不會中斷。

### D4: Windows 套件管理器優先使用 winget

**選擇**：Windows 腳本優先使用 `winget` 安裝 fzf 和 starship，若 winget 不可用則提示使用者手動安裝。

**替代方案**：同時支援 winget/choco/scoop。

**理由**：winget 是 Windows 11 內建的套件管理器，覆蓋率最高。支援多種套件管理器會增加腳本複雜度，效益不大。

### D5: 檔案重命名策略

**選擇**：直接重命名 `setup_env.sh` → `setup_linux.sh`、`update.sh` → `update_linux.sh`。

**替代方案**：保留原檔名作為相容層。

**理由**：此為個人工具庫，不需考慮外部使用者的向後相容性。乾淨重命名更易理解。

## Risks / Trade-offs

- **[風險] Homebrew 未安裝** → macOS 腳本開頭檢查 `command -v brew`，未安裝時輸出安裝指引並退出
- **[風險] Windows 字型自動安裝失敗** → fallback 至手動安裝提示，輸出檔案下載路徑
- **[風險] winget 不可用（舊版 Windows 10）** → 提示使用者安裝 winget 或手動安裝相關工具
- **[風險] Maple Font 版本寫死（v7.9）** → 未來需手動更新版本號，可在後續改為動態取得 latest release
- **[取捨] .zshrc 完全共用** → macOS 和 Linux 使用相同配置，無法針對單一平台做差異化設定。目前已有 Homebrew 偵測邏輯，足以應付差異。
