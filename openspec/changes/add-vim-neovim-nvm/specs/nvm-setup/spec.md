## ADDED Requirements

### Requirement: Unix 安裝 nvm

安裝腳本 SHALL 使用 nvm-sh/nvm 官方 curl 安裝腳本安裝 nvm。

| 平台 | 安裝方式 |
|------|----------|
| macOS | `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/<version>/install.sh \| bash` |
| Linux | 同上 |

#### Scenario: nvm 尚未安裝
- **WHEN** `$NVM_DIR/nvm.sh` 不存在
- **THEN** 腳本 SHALL 下載並執行 nvm 官方安裝腳本

#### Scenario: nvm 已安裝
- **WHEN** `$NVM_DIR/nvm.sh` 已存在
- **THEN** 腳本 SHALL 跳過安裝並輸出提示

### Requirement: Windows 安裝 nvm-windows

`setup_win.ps1` SHALL 透過 winget 安裝 nvm-windows。

#### Scenario: winget 可用且 nvm-windows 未安裝
- **WHEN** 系統有 winget 且無 nvm 指令
- **THEN** 腳本 SHALL 執行 `winget install CoreyButler.NVMforWindows`

#### Scenario: winget 不可用
- **WHEN** 系統無 winget
- **THEN** 腳本 SHALL 輸出 nvm-windows 手動安裝連結並繼續

#### Scenario: nvm-windows 已安裝
- **WHEN** 系統已有 nvm 指令
- **THEN** 腳本 SHALL 跳過並輸出提示

### Requirement: 安裝 Node.js LTS

安裝 nvm 後，腳本 SHALL 自動安裝 Node.js LTS 版本並設為預設。

#### Scenario: 安裝 Node.js LTS (Unix)
- **WHEN** nvm 安裝完成
- **THEN** 腳本 SHALL 執行 `nvm install --lts` 並 `nvm alias default lts/*`

#### Scenario: 安裝 Node.js LTS (Windows)
- **WHEN** nvm-windows 安裝完成
- **THEN** 腳本 SHALL 執行 `nvm install lts` 並 `nvm use lts`

### Requirement: .zshrc 加入 nvm lazy loading

選裝 editor 時，安裝腳本 SHALL 在 .zshrc 加入 nvm 延遲載入配置。nvm/node/npm/npx 指令在首次呼叫時才初始化 nvm。

#### Scenario: nvm lazy loading 函式
- **WHEN** 使用者開啟新的 zsh session
- **THEN** nvm、node、npm、npx SHALL 定義為 shell function，呼叫時才執行 `$NVM_DIR/nvm.sh`

#### Scenario: lazy loading 後正常運作
- **WHEN** 使用者首次執行 `node --version`
- **THEN** SHALL 觸發 nvm 初始化並正確回傳 node 版本

### Requirement: 更新腳本更新 nvm 與 Node.js

更新腳本 SHALL 在偵測到 editor 模組已安裝時，更新 nvm 本身及 Node.js LTS。

#### Scenario: Unix 更新 nvm
- **WHEN** 執行更新腳本且 features 包含 editor
- **THEN** SHALL 重新執行 nvm 官方安裝腳本以更新至最新版

#### Scenario: Windows 更新 nvm
- **WHEN** 執行更新腳本且 features 包含 editor
- **THEN** SHALL 執行 `winget upgrade CoreyButler.NVMforWindows`（若可用）
