## ADDED Requirements

### Requirement: macOS 安裝腳本檢測 Homebrew

`setup_mac.sh` SHALL 在執行前檢測 Homebrew 是否已安裝。若未安裝，SHALL 輸出安裝指引並退出。

#### Scenario: Homebrew 已安裝
- **WHEN** 系統中存在 `brew` 指令
- **THEN** 腳本 SHALL 繼續執行後續安裝步驟

#### Scenario: Homebrew 未安裝
- **WHEN** 系統中不存在 `brew` 指令
- **THEN** 腳本 SHALL 輸出 Homebrew 安裝指令提示並以非零狀態碼退出

### Requirement: macOS 安裝前置套件

`setup_mac.sh` SHALL 透過 `brew install` 安裝 zsh、git、unzip、xz 等前置套件。

#### Scenario: 安裝前置套件
- **WHEN** 執行 `setup_mac.sh`
- **THEN** 腳本 SHALL 執行 `brew install zsh git unzip xz`

### Requirement: macOS 安裝 Python 3.13

`setup_mac.sh` SHALL 透過 Homebrew 安裝 Python 3.13。

#### Scenario: 安裝 Python
- **WHEN** 執行 `setup_mac.sh`
- **THEN** 腳本 SHALL 執行 `brew install python@3.13`

### Requirement: macOS 安裝 Maple Mono 字型

`setup_mac.sh` SHALL 下載 `MapleMono-NL-NF-CN.zip` 並將字型檔安裝至 `~/Library/Fonts/`。

#### Scenario: 字型安裝成功
- **WHEN** 下載並解壓字型檔案後
- **THEN** 腳本 SHALL 將 `.ttf` 檔案複製至 `~/Library/Fonts/`

### Requirement: macOS 安裝 fzf 使用 git clone

`setup_mac.sh` SHALL 透過 `git clone --depth 1` 將 fzf 安裝至 `~/.fzf`，並執行自動安裝腳本。

#### Scenario: fzf 安裝
- **WHEN** 執行 `setup_mac.sh`
- **THEN** 腳本 SHALL 執行 `git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf` 並執行 `~/.fzf/install --all --key-bindings --completion --no-bash --no-fish`

### Requirement: macOS 安裝 zoxide

`setup_mac.sh` SHALL 透過 curl 安裝 zoxide。

#### Scenario: zoxide 安裝
- **WHEN** 執行 `setup_mac.sh`
- **THEN** 腳本 SHALL 執行 zoxide 的遠端安裝腳本

### Requirement: macOS 寫入 .zshrc 配置

`setup_mac.sh` SHALL 備份既有 `.zshrc`（若存在），並寫入與 Linux 完全相同的 Zsh 配置內容。

#### Scenario: 既有 .zshrc 備份
- **WHEN** `~/.zshrc` 已存在
- **THEN** 腳本 SHALL 將其重命名為 `~/.zshrc.bak` 後再寫入新配置

#### Scenario: 寫入共用配置
- **WHEN** 執行 `setup_mac.sh`
- **THEN** 寫入的 `.zshrc` 內容 SHALL 與 `setup_linux.sh` 寫入的內容完全一致

### Requirement: macOS 更新腳本

`update_mac.sh` SHALL 更新 Homebrew 套件、fzf、zoxide、Zinit 插件及 Maple Mono 字型。

#### Scenario: 執行 macOS 更新
- **WHEN** 執行 `update_mac.sh`
- **THEN** 腳本 SHALL 依序執行 `brew update && brew upgrade`、fzf git pull、zoxide 重新安裝、Zinit 更新、字型更新
