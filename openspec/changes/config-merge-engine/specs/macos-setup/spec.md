## MODIFIED Requirements

### Requirement: macOS 寫入 .zshrc 配置

`setup_mac.sh` SHALL 透過 `merge_config()` 函式呼叫合併引擎來部署 `.zshrc`，取代原有的 heredoc 覆寫方式。合併引擎 SHALL 保留使用者既有自訂、去除重複行、輸出差異摘要。

#### Scenario: 全新安裝 .zshrc
- **WHEN** `~/.zshrc` 不存在
- **THEN** 腳本 SHALL 呼叫 `merge_config ~/.zshrc "$SCRIPT_DIR/templates/zshrc_base_mac.zsh" "zsh-base" "zsh"` 寫入完整配置

#### Scenario: 既有 .zshrc 升級
- **WHEN** `~/.zshrc` 已存在且無 settingZsh markers
- **THEN** 合併引擎 SHALL 備份原檔、去重比對、保留使用者獨有行

#### Scenario: 重複執行
- **WHEN** `~/.zshrc` 已存在且包含 settingZsh markers
- **THEN** 合併引擎 SHALL 僅更新 managed 段，保留 user 段

## ADDED Requirements

### Requirement: macOS 安裝 uv

`setup_mac.sh` SHALL 檢查 `uv` 是否可用，若不可用則透過官方安裝腳本安裝。

#### Scenario: uv 未安裝
- **WHEN** 系統中不存在 `uv` 指令
- **THEN** 腳本 SHALL 執行 `curl -LsSf https://astral.sh/uv/install.sh | sh` 安裝 uv

#### Scenario: uv 已安裝
- **WHEN** 系統中已存在 `uv` 指令
- **THEN** 腳本 SHALL 跳過安裝步驟
