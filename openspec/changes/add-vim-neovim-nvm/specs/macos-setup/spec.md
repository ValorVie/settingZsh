## MODIFIED Requirements

### Requirement: macOS 安裝前置套件

`setup_mac.sh` SHALL 透過 `brew install` 安裝 zsh、git、unzip、xz 等前置套件。

#### Scenario: 安裝前置套件
- **WHEN** 執行 `setup_mac.sh`
- **THEN** 腳本 SHALL 執行 `brew install zsh git unzip xz`

#### Scenario: 選裝 editor 時安裝額外套件
- **WHEN** 執行 `setup_mac.sh` 且使用者選擇安裝 editor
- **THEN** 腳本 SHALL 額外執行 `brew install vim neovim ripgrep fd lazygit`

### Requirement: macOS 寫入 .zshrc 配置

`setup_mac.sh` SHALL 備份既有 `.zshrc`（若存在），並寫入 Zsh 配置內容。選裝 editor 時 SHALL 追加 nvm lazy loading 與 vim alias。

#### Scenario: 既有 .zshrc 備份
- **WHEN** `~/.zshrc` 已存在
- **THEN** 腳本 SHALL 將其重命名為 `~/.zshrc.bak` 後再寫入新配置

#### Scenario: 寫入共用 zsh 配置
- **WHEN** 執行 `setup_mac.sh`
- **THEN** 寫入的 `.zshrc` SHALL 包含 Zinit 初始化、插件、fzf、zoxide 等基本配置

#### Scenario: 選裝 editor 時追加配置
- **WHEN** 使用者選擇安裝 editor
- **THEN** .zshrc SHALL 額外包含 nvm lazy loading 函式與 `alias vim='nvim'`

### Requirement: macOS 更新腳本

`update_mac.sh` SHALL 根據 features 標記檔決定更新範圍。

#### Scenario: 僅更新 zsh 環境
- **WHEN** features 不含 editor
- **THEN** 腳本 SHALL 更新 Homebrew 套件、fzf、zoxide、Zinit 插件、字型

#### Scenario: 更新 zsh + editor 環境
- **WHEN** features 包含 editor
- **THEN** 腳本 SHALL 額外更新 neovim、ripgrep、fd、lazygit、nvm、Node.js LTS、lazy.nvim 插件
