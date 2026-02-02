## MODIFIED Requirements

### Requirement: Unix 入口腳本透過 OS 偵測分發

`setup.sh` 和 `update.sh` SHALL 透過 `uname -s` 偵測作業系統，將執行流程分發至對應平台腳本。在呼叫平台腳本前，SHALL 確保 `uv` 已安裝。

#### Scenario: Linux 環境執行 setup.sh
- **WHEN** 在 Linux 環境執行 `./setup.sh`
- **THEN** 腳本 SHALL 確認 `uv` 可用（若不可用則安裝）
- **THEN** 腳本 SHALL 呼叫 `./setup_linux.sh`

#### Scenario: macOS 環境執行 setup.sh
- **WHEN** 在 macOS 環境執行 `./setup.sh`
- **THEN** 腳本 SHALL 確認 `uv` 可用（若不可用則安裝）
- **THEN** 腳本 SHALL 呼叫 `./setup_mac.sh`

#### Scenario: 不支援的平台
- **WHEN** 在非 Linux/macOS 環境執行 `./setup.sh`
- **THEN** 腳本 SHALL 輸出錯誤訊息並以非零狀態碼退出
