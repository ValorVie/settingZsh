## ADDED Requirements

### Requirement: Windows 安裝腳本偵測 PowerShell 版本與 Profile 路徑

`setup_win.ps1` SHALL 偵測 PowerShell 版本（5.1 或 7+），並根據版本決定 Profile 檔案路徑。

#### Scenario: PowerShell 5.1
- **WHEN** PowerShell 主版本為 5
- **THEN** Profile 路徑 SHALL 為 `$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1`

#### Scenario: PowerShell 7+
- **WHEN** PowerShell 主版本大於等於 7
- **THEN** Profile 路徑 SHALL 為 `$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`

### Requirement: Windows 備份既有 Profile

`setup_win.ps1` SHALL 在複製新 Profile 前備份既有檔案。

#### Scenario: 既有 Profile 存在
- **WHEN** 目標 Profile 路徑已有檔案
- **THEN** 腳本 SHALL 將其重命名為 `.ps1.bak` 後再複製新檔案

#### Scenario: 既有 Profile 不存在
- **WHEN** 目標 Profile 路徑無檔案
- **THEN** 腳本 SHALL 建立目標目錄（若不存在）並直接複製

### Requirement: Windows 複製 PowerShell Profile

`setup_win.ps1` SHALL 將 `Windows-Powershell/Microsoft.PowerShell_profile.ps1` 複製至偵測到的 Profile 路徑。

#### Scenario: 成功複製
- **WHEN** 執行 `setup_win.ps1`
- **THEN** 目標 Profile 檔案 SHALL 與來源檔案內容一致

### Requirement: Windows 安裝 PowerShell 模組

`setup_win.ps1` SHALL 安裝 Terminal-Icons、ZLocation、PSFzf 模組。

#### Scenario: 模組未安裝
- **WHEN** 系統中不存在指定模組
- **THEN** 腳本 SHALL 執行 `Install-Module -Name <模組名> -Force -Scope CurrentUser`

#### Scenario: 模組已安裝
- **WHEN** 系統中已存在指定模組
- **THEN** 腳本 SHALL 跳過該模組並輸出提示訊息

### Requirement: Windows 安裝 fzf 和 Starship

`setup_win.ps1` SHALL 透過 winget 安裝 fzf 和 starship。若 winget 不可用，SHALL 輸出手動安裝提示。

#### Scenario: winget 可用
- **WHEN** 系統中存在 `winget` 指令
- **THEN** 腳本 SHALL 執行 `winget install junegunn.fzf` 和 `winget install Starship.Starship`

#### Scenario: winget 不可用
- **WHEN** 系統中不存在 `winget` 指令
- **THEN** 腳本 SHALL 輸出手動安裝連結並繼續執行後續步驟

### Requirement: Windows 安裝 Maple Mono 字型（含 fallback）

`setup_win.ps1` SHALL 下載 `MapleMono-NL-NF-CN-autohint.zip` 並嘗試自動安裝字型。安裝失敗時 SHALL 提示使用者手動安裝並提供檔案路徑。

#### Scenario: 字型自動安裝成功
- **WHEN** 腳本成功將 `.ttf` 檔案複製至 `$env:LOCALAPPDATA\Microsoft\Windows\Fonts\` 並寫入登錄檔
- **THEN** 腳本 SHALL 輸出安裝成功訊息

#### Scenario: 字型自動安裝失敗
- **WHEN** 字型安裝過程發生錯誤
- **THEN** 腳本 SHALL 輸出「請手動安裝字型，檔案已下載至 <路徑>」並繼續執行

### Requirement: PowerShell Profile 使用動態路徑

`Microsoft.PowerShell_profile.ps1` 中 SHALL 使用 `$env:USERPROFILE` 取代寫死的使用者路徑。

#### Scenario: Conda 路徑動態化
- **WHEN** 腳本檢測 Conda 安裝
- **THEN** SHALL 使用 `"$env:USERPROFILE\miniconda3\Scripts\conda.exe"` 而非寫死路徑

#### Scenario: OpenSpec completion 路徑動態化
- **WHEN** 腳本載入 OpenSpec completion
- **THEN** SHALL 使用 `"$env:USERPROFILE\Documents\PowerShell\OpenSpecCompletion.ps1"` 而非寫死路徑

### Requirement: Windows 更新腳本

`update_win.ps1` SHALL 更新 PowerShell 模組、fzf、starship 及 Maple Mono 字型。

#### Scenario: 執行 Windows 更新
- **WHEN** 執行 `update_win.ps1`
- **THEN** 腳本 SHALL 依序執行 `Update-Module`、`winget upgrade`（若可用）、字型更新（含 fallback）
