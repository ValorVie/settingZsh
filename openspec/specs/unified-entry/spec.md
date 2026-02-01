## ADDED Requirements

### Requirement: Unix 入口腳本透過 OS 偵測分發

`setup.sh` 和 `update.sh` SHALL 透過 `uname -s` 偵測作業系統，將執行流程分發至對應平台腳本。

#### Scenario: Linux 環境執行 setup.sh
- **WHEN** 在 Linux 環境執行 `./setup.sh`
- **THEN** 腳本 SHALL 呼叫 `./setup_linux.sh`

#### Scenario: macOS 環境執行 setup.sh
- **WHEN** 在 macOS 環境執行 `./setup.sh`
- **THEN** 腳本 SHALL 呼叫 `./setup_mac.sh`

#### Scenario: 不支援的平台
- **WHEN** 在非 Linux/macOS 環境執行 `./setup.sh`
- **THEN** 腳本 SHALL 輸出錯誤訊息並以非零狀態碼退出

### Requirement: Windows 入口透過 batch 啟動 PowerShell

`setup.bat` 和 `update.bat` SHALL 以 `powershell -ExecutionPolicy Bypass -File` 方式呼叫對應的 `.ps1` 腳本。

#### Scenario: 執行 setup.bat
- **WHEN** 使用者在 Windows 執行 `setup.bat`
- **THEN** 系統 SHALL 以 Bypass 執行策略啟動 `setup_win.ps1`

#### Scenario: 執行 update.bat
- **WHEN** 使用者在 Windows 執行 `update.bat`
- **THEN** 系統 SHALL 以 Bypass 執行策略啟動 `update_win.ps1`

### Requirement: 既有腳本重命名

`setup_env.sh` SHALL 重命名為 `setup_linux.sh`，`update.sh` SHALL 重命名為 `update_linux.sh`，內容不做修改。

#### Scenario: 重命名後功能不變
- **WHEN** 執行重命名後的 `setup_linux.sh`
- **THEN** 行為 SHALL 與原始 `setup_env.sh` 完全一致
