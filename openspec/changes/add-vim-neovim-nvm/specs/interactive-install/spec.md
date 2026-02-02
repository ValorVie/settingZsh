## ADDED Requirements

### Requirement: 安裝腳本互動式詢問 editor 模組

安裝腳本 SHALL 在完成 Zsh 基本安裝後，詢問使用者是否安裝 editor 環境。預設為「否」。

#### Scenario: 使用者按 Enter（預設不安裝）
- **WHEN** 安裝腳本顯示「是否安裝編輯器環境？(y/N)」且使用者按 Enter
- **THEN** 腳本 SHALL 跳過 editor 安裝，僅記錄 zsh 至 features

#### Scenario: 使用者輸入 y
- **WHEN** 使用者輸入 y 或 Y
- **THEN** 腳本 SHALL 繼續安裝 editor 環境（vim, neovim, nvm, node, ripgrep, fd, lazygit）

#### Scenario: 使用者輸入 n
- **WHEN** 使用者輸入 n 或 N
- **THEN** 腳本 SHALL 跳過 editor 安裝

### Requirement: 功能標記檔寫入

安裝腳本 SHALL 在安裝完成後寫入功能標記檔，記錄已安裝的模組。

| 平台 | 標記檔路徑 |
|------|-----------|
| macOS / Linux | `~/.settingzsh/features` |
| Windows | `$env:USERPROFILE\.settingzsh\features` |

#### Scenario: 僅安裝 zsh
- **WHEN** 使用者未選擇 editor
- **THEN** features 檔案 SHALL 包含一行 `zsh`

#### Scenario: 安裝 zsh + editor
- **WHEN** 使用者選擇安裝 editor
- **THEN** features 檔案 SHALL 包含 `zsh` 和 `editor` 兩行

#### Scenario: 標記檔目錄建立
- **WHEN** `~/.settingzsh/` 目錄不存在
- **THEN** 腳本 SHALL 建立該目錄後再寫入

### Requirement: 更新腳本讀取功能標記檔

更新腳本 SHALL 讀取功能標記檔以決定更新範圍。

#### Scenario: 標記檔存在且包含 editor
- **WHEN** features 檔案包含 `editor`
- **THEN** 更新腳本 SHALL 更新 zsh 環境和 editor 環境

#### Scenario: 標記檔存在但不含 editor
- **WHEN** features 檔案僅包含 `zsh`
- **THEN** 更新腳本 SHALL 僅更新 zsh 環境

#### Scenario: 標記檔不存在（fallback）
- **WHEN** features 檔案不存在
- **THEN** 更新腳本 SHALL 檢查 `command -v nvim`；若存在則更新 editor 環境，否則僅更新 zsh

### Requirement: 安裝腳本函式化結構

安裝腳本 SHALL 將安裝邏輯拆為函式：
- `install_zsh_env`：現有 Zsh 安裝邏輯
- `install_editor_env`：新增 editor 安裝邏輯
- `ask_yes_no`：互動詢問函式
- `save_features`：標記檔寫入函式

#### Scenario: 函式化後行為不變
- **WHEN** 使用者執行安裝腳本且不安裝 editor
- **THEN** Zsh 環境的安裝結果 SHALL 與重構前完全一致
