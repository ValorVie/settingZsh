# settingZsh

跨平台 shell / profile baseline，現在以 `chezmoi` 作為主要控制面，支援 macOS、Linux、Windows，並保留 `public baseline + custom private repo` 的 SSH 分層模型。

延伸文件：

- `docs/architecture.md`：架構、dotfiles / `chezmoi` 原理與專案責任邊界
- `docs/editor-guide.md`：Vim / Neovim 配置與使用方式

## 這個 repo 會做什麼

- 管理 macOS / Linux 的 `~/.zshrc` bootstrap 與 `~/.config/settingzsh/managed.d/*.zsh`
- 管理 Windows PowerShell 5.1 / 7+ profile target 與共用 baseline
- 透過 `chezmoi run_*` scripts 安裝 base tools、字型與選配 editor 工具
- 提供 `.ssh/config` 主檔與 `config.d` 分層骨架
- 保留 Linux / macOS 的 `doctor`、`migrate`、`reconcile` CLI，供舊環境遷移與診斷

## 設計原則

- `public repo` 只管 baseline 與非機密設定
- SSH keys 與私有 host 規則放在你自己的 `custom private repo`
- `~/.ssh/config` 主檔永遠由 public baseline 管理
- `custom private repo` 只應該提供 `~/.ssh/**`
- `known_hosts` 預設不進版控
- 新安裝以 `chezmoi` 為主；舊的 `setup*.sh` / `update*.sh` 保留作遷移期參考與回歸驗證

## 需求

### 共通

- Git
- 網路連線
- 你的 public repo URL

### macOS

- Homebrew
- `chezmoi`

### Linux

- `curl`
- `tar`
- `unzip`
- `chezmoi`

### Windows

- PowerShell
- `winget`
- `chezmoi`

## 快速開始

### 1. 安裝 chezmoi

官方文件：
- [Quick Start](https://www.chezmoi.io/quick-start/)
- [Install chezmoi](https://www.chezmoi.io/install/)

範例：

**macOS**

```bash
brew install chezmoi
```

**Linux**

```bash
sh -c "$(curl -fsLS get.chezmoi.io)"
```

**Windows**

```powershell
winget install twpayne.chezmoi
```

### 2. 套用 public baseline

把 `<public-repo>` 換成你自己的 repo URL：

```bash
chezmoi init --apply <public-repo>
```

如果已經 init 過，之後更新直接用：

```bash
chezmoi update
```

### 3. 重新開啟終端機

**macOS / Linux**

```bash
exec zsh
```

**Windows**

重新開啟 PowerShell / Windows Terminal。

## 安裝後會得到什麼

### macOS / Linux

- `~/.zshrc` 極小 bootstrap
- `~/.config/settingzsh/init.zsh`
- `~/.config/settingzsh/managed.d/10-base.zsh`
- `~/.config/settingzsh/managed.d/40-editor.zsh`
- Zinit + 預設插件集合
- `fzf`
- `zoxide`
- Maple Mono 字型

### Windows

- `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`
- `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1`
- `~/.config/settingzsh/powershell/public-baseline.ps1`
- PowerShell modules：`Terminal-Icons`、`ZLocation`、`PSFzf`
- `fzf`
- `Starship`
- Maple Mono 字型

### 預設不會做的事

- 不自動安裝 editor 工具
- 不自動佈署 SSH 私鑰
- 不接管整份 `~/.zshrc`
- 不同步 `known_hosts`

## 完整安裝指南

### Machine data 與 feature flags

這個 repo 目前用到的主要 data key 在 `.chezmoi.toml.tmpl`：

```toml
[data]
feature_editor = false
private_ssh_overlay = false
private_ssh_overlay_repo = ""
install_fonts = true
platform_profile = "auto"
```

目前真正會影響安裝行為的主要是：

- `feature_editor`
- `install_fonts`

`private_ssh_overlay`、`private_ssh_overlay_repo` 與 `platform_profile` 目前先保留給後續 private overlay / profile 選擇流程，不代表 public repo 已自動接好 secret repo。

若你要在本機覆蓋預設值，編輯 `~/.config/chezmoi/chezmoi.toml`：

```toml
[data]
feature_editor = true
install_fonts = true
```

改完後重新套用：

```bash
chezmoi apply
```

### 啟用 editor 環境

這會依平台安裝或部署：

- macOS / Linux：Vim、Neovim、`nvm`、Node.js LTS、`ripgrep`、`fd`、`lazygit`、repo 內的 `nvim/` 設定，以及 `.vimrc` merge
- Windows：Neovim、`nvm-windows`、Node.js LTS、`ripgrep`、`fd`、`lazygit`，以及 repo 內的 `nvim/` 設定

啟用方式有兩種。

**持久化做法**

```toml
[data]
feature_editor = true
```

然後：

```bash
chezmoi apply
```

**一次性做法**

```bash
SETTINGZSH_FEATURE_EDITOR=true chezmoi apply
```

### Linux 無 sudo 的行為

Linux 目前採用 non-interactive sudo 檢查，不會因為 `chezmoi apply` 卡在 sudo prompt。

若沒有可用的 `sudo -n`：

- base packages 會略過 apt 安裝
- editor 安裝會改走 binary fallback
- `ripgrep`、`fd`、`neovim`、`lazygit` 會從 release tarball 安裝到 `~/.local/bin` 或 `~/.local`
- `gcc` / `vim` 沒有 userspace fallback，會保留 warning

### 字型安裝

預設會安裝 Maple Mono。

- macOS：安裝到 `~/Library/Fonts`
- Linux：安裝到 `~/.local/share/fonts/MapleMono`
- Windows：安裝到 `%LOCALAPPDATA%\\Microsoft\\Windows\\Fonts`

安裝後若終端機字型沒切換，請手動把終端機字型改成 `Maple Mono NL NF CN`。

## Shell / Profile 模型

### macOS / Linux

`~/.zshrc` 只保留 bootstrap：

```zsh
if [ -f "$HOME/.config/settingzsh/init.zsh" ]; then
  source "$HOME/.config/settingzsh/init.zsh"
fi
```

真正的內容放在：

- `~/.config/settingzsh/managed.d/10-base.zsh`
- `~/.config/settingzsh/managed.d/40-editor.zsh`
- `~/.config/settingzsh/local.d/*.zsh`

載入順序是：

1. `managed.d/*.zsh`
2. `local.d/*.zsh`

### Windows

Profile 採雙 target：

- `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`
- `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1`

兩者都只負責 source：

```powershell
$HOME/.config/settingzsh/powershell/public-baseline.ps1
```

真正的 module import 與 `starship init` 都放在 `public-baseline.ps1`。

## SSH 與 custom private repo

### public baseline 的責任

public baseline 只提供：

- `~/.ssh/config`
- `~/.ssh/config.d/10-common.conf`

主檔會包含：

```sshconfig
Include ~/.ssh/config.d/*.conf
```

### custom private repo 的責任

你的 `custom private repo` 只應該管理：

- 私鑰
- 公鑰
- `~/.ssh/config.d/90-private.conf`
- 其他只屬於 SSH 的私有設定

不應該管理：

- `~/.ssh/config` 主檔
- `known_hosts`
- shell / git / nvim / 其他一般 dotfiles

### 範本 repo

repo 內已提供一個參考範本：

- `examples/valor-ssh-key/README.md`

這個範本故意只示範結構，不內建實際私鑰，而且它是 plain repo layout，不是 public repo 這一側的 chezmoi source state。指南裡一律稱它為 `custom private repo`，你可以換成自己的 repo 名稱與交付流程。

### 建議結構

```text
custom-private-repo/
├── README.md
└── .ssh/
    ├── config.d/
    │   └── 90-private.conf
    ├── id_ed25519
    └── id_ed25519.pub
```

### 建議流程

1. 先套用 public baseline
2. 確認 `~/.ssh/config` 與 `~/.ssh/config.d/` 已存在
3. 依你的安全流程部署 `custom private repo`
4. 只把 private repo 的 `.ssh/**` 帶進目標機器
5. 確認 `~/.ssh/config.d/90-private.conf` 與 key file 權限正確

> 目前這個 public repo 沒有自動拉取 secret repo；這是刻意的。SSH secrets 的運送方式交給你的 `custom private repo` 與安全流程決定。

## 日常使用

### 更新

```bash
chezmoi update
```

### 檢查差異

```bash
chezmoi diff
```

### 重新套用

```bash
chezmoi apply
```

### 進到 source state

```bash
chezmoi cd
```

## 舊環境遷移與診斷

Linux / macOS 還保留 `settingzsh.cli`，用來處理舊版 bootstrap / marker 狀態。

在 repo source state 內執行：

```bash
chezmoi cd
uv run --directory lib python -m settingzsh.cli doctor
uv run --directory lib python -m settingzsh.cli migrate
uv run --directory lib python -m settingzsh.cli reconcile
```

用途：

- `doctor`：檢查 bootstrap / legacy marker / shell 驗證狀態
- `migrate`：把舊版 `settingZsh:*` 區塊搬到 `managed.d`
- `reconcile`：補齊 bootstrap、`init.zsh`、managed fragments

## 專案結構

```text
.
├── .chezmoi.toml.tmpl
├── .chezmoidata/
├── home/
│   ├── dot_zshrc.tmpl
│   ├── dot_config/settingzsh/init.zsh.tmpl
│   ├── dot_config/settingzsh/managed.d/
│   ├── dot_config/settingzsh/powershell/
│   ├── Documents/PowerShell/
│   ├── Documents/WindowsPowerShell/
│   └── private_dot_ssh/
├── run_once_before_*.tmpl
├── run_onchange_after_*.tmpl
├── lib/settingzsh/
├── nvim/
├── vim/
└── examples/valor-ssh-key/
```

## 驗證

主要靜態與單元測試：

```bash
bash tests/chezmoi/test_task1_scaffold.sh
bash tests/chezmoi/test_source_state.sh
bash tests/chezmoi/test_zsh_baseline.sh
bash tests/chezmoi/test_scripts_presence.sh
bash tests/chezmoi/test_linux_fallback.sh
uv run pytest -q tests/test_config_merge.py tests/test_settingzsh_*.py
```

Windows profile parity 另外有：

```powershell
pwsh -File tests/chezmoi/test_windows_profile.ps1
```

## 已知限制

- Windows runtime 驗證需要 `pwsh`
- Linux 無 sudo fallback 仍依賴外網下載 release binary
- `custom private repo` 目前不由 public repo 自動拉取
- 遷移期內 legacy `setup*.sh` / `update*.sh` 仍存在，但新安裝應以 `chezmoi` 為主
