# settingZsh

跨平台 shell / profile baseline，現在以 `chezmoi` 作為主要控制面，支援 macOS、Linux、Windows，並保留 `public baseline + custom private repo` 的 SSH 分層模型。

延伸文件：

- `docs/architecture.md`：架構、dotfiles / `chezmoi` 原理與專案責任邊界
- `docs/adoption-guide.md`：既有機器導入流程、preflight、adopt report 與 legacy import draft
- `docs/editor-guide.md`：Vim / Neovim 配置與使用方式
- `docs/secrets/keepassxc-cli.md`：desktop file secret 操作指南
- `docs/secrets/gopass.md`：server file secret 操作指南
- `docs/secrets/sops-age.md`：`SOPS + age` 加密與輪替指南

## README 怎麼讀

如果你只想直接照著做，建議用這個順序讀：

1. `快速開始`
2. `常見操作場景`
3. `完整安裝指南`
4. `SSH 與 custom private repo`
5. `日常使用`
6. `故障排查`

## 這個 repo 會做什麼

- 管理 macOS / Linux 的 `~/.zshrc` bootstrap 與 `~/.config/settingzsh/managed.d/*.zsh`
- 管理 Windows PowerShell 5.1 / 7+ profile target 與共用 baseline
- 透過 `chezmoi run_*` scripts 安裝 base tools、字型與選配 editor 工具
- 提供 `.ssh/config` 主檔與 `config.d` 分層骨架
- 保留 Linux / macOS 的 `preflight`、`adopt`、`doctor`、`migrate`、`reconcile`、`legacy-import` CLI，供舊環境遷移與診斷

## 設計原則

- `public repo` 只管 baseline 與非機密設定
- SSH keys 與私有 host 規則放在你自己的 `custom private repo`
- `custom private repo` 建議以 `SOPS + age` 管理密文與 recipients
- `~/.ssh/config` 主檔永遠由 public baseline 管理
- `custom private repo` 只應該提供 `~/.ssh/**`
- `known_hosts` 預設不進版控
- fresh install 與 existing machine adoption 是兩條不同流程
- `~/.zshrc` 只由 bootstrap 擁有，不再讓 public baseline 接管整份檔案
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

### 你應該走哪條路

- `fresh install`
  - 新機器、沒有既有重型 `~/.zshrc`
  - 可以直接 `chezmoi init --apply`
- `existing machine`
  - 已經有自己的 shell 生態、plugin manager、`compinit`、`precmd`、brew / `nvm` / bun 等初始化
  - 先走 adoption gate，不要直接 `init --apply`

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

### 2. fresh install：套用 public baseline

把 `<public-repo>` 換成你自己的 repo URL：

```bash
chezmoi init --apply <public-repo>
```

如果已經 init 過，之後更新直接用：

```bash
chezmoi update
```

### 3. existing machine：先跑 adoption gate

如果這台機器已經有自己的 `~/.zshrc`，建議先：

```bash
chezmoi init <public-repo>
chezmoi cd
uv run --directory lib python -m settingzsh.cli preflight
```

若結果是 `needs_adopt`，先建立 adopt report：

```bash
uv run --directory lib python -m settingzsh.cli adopt
```

再依 [docs/adoption-guide.md](/Users/arlen/Documents/syncthing/backup/server/Code/settingZsh/.worktrees/settingzsh-chezmoi/docs/adoption-guide.md) 判斷要不要導入、保留現況，或產生 `legacy import draft`。

### 4. 重新開啟終端機

**macOS / Linux**

```bash
exec zsh
```

**Windows**

重新開啟 PowerShell / Windows Terminal。

## 常見操作場景

### 我是新機器，想直接裝好

1. 安裝 `chezmoi`
2. `chezmoi init --apply <public-repo>`
3. 重新開啟 shell
4. 視需要再開 `feature_editor`
5. 最後再接你的 `custom private repo`

### 這台機器已經有自己的 `.zshrc`

1. `chezmoi init <public-repo>`
2. `chezmoi cd`
3. 跑 `preflight`
4. 若不是 `safe`，先跑 `adopt`
5. 確認報告後再決定要不要 `chezmoi apply`

### 我只想更新既有 baseline

1. `chezmoi update`
2. 若有 shell 異常，再跑 `doctor`
3. 若懷疑 managed fragments 缺檔，再跑 `reconcile`

### 我想把 SSH 私有設定接上去

1. 先確認 public baseline 已建立 `~/.ssh/config`
2. 準備好 `custom private repo`
3. 依你的安全流程 materialize `config.d/*.conf` 與 key files
4. 跑 `ssh -G <host>` 檢查結果

## preflight 結果怎麼看

`preflight` 只有三種主要結果：

- `safe`
  - 可以繼續 `chezmoi apply` 或 `reconcile`
- `needs_adopt`
  - 代表這台機器已有重型 shell 生態
  - 先跑 `adopt`，不要直接套用
- `broken_existing_shell`
  - 代表現況 shell 本身就不健康
  - 先修現況，再談導入

最小流程：

```bash
chezmoi init <public-repo>
chezmoi cd
uv run --directory lib python -m settingzsh.cli preflight
```

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
- 不為 existing machine 自動清理舊 `.zshrc`

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

### 開啟或關閉 editor feature

開啟：

```toml
[data]
feature_editor = true
```

關閉：

```toml
[data]
feature_editor = false
```

改完後都用同一個指令重新套用：

```bash
chezmoi apply
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

`~/.zshrc` 的 ownership 已收斂成 bootstrap ownership：

- fresh install：建立極小 bootstrap
- existing machine：透過 `modify_` source state 只補 bootstrap，不覆蓋整份檔案

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
- `~/.ssh/config.d/*.conf`
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
├── .sops.yaml
├── README.md
├── shared/
│   └── config.d/
│       └── 10-common-private.conf
├── shared-keys/
│   └── keys/
│       └── README.md
├── macmini/
│   ├── config.d/90-private.conf
│   ├── keys/
│   └── custom-paths/
└── valorpc/
    ├── config.d/90-private.conf
    ├── keys/
    └── custom-paths/
```

路徑模型：

- `standard path`：`~/.ssh/<key>`
- `custom managed path`：例如 `~/.ssh/config/sympasoft-macmini-ssh/<key>`

### 建議流程

1. 先套用 public baseline
2. 確認 `~/.ssh/config` 與 `~/.ssh/config.d/` 已存在
3. 依你的安全流程部署 `custom private repo`
4. 只把 private repo 的 `.ssh/**` 帶進目標機器
5. 確認 `~/.ssh/config.d/90-private.conf` 與 key file 權限正確

> 目前這個 public repo 沒有自動拉取 secret repo；這是刻意的。SSH secrets 的運送方式交給你的 `custom private repo` 與安全流程決定。若要把 private repo push 到遠端，建議先完成 `SOPS + age` 加密（見 `docs/secrets/sops-age.md`）。

### custom private repo 最小接線流程

這是最小可用流程，不含自動化抓取：

1. public baseline 先完成

```bash
chezmoi init --apply <public-repo>
```

2. 準備 private repo 結構

- 參考 `examples/valor-ssh-key/`
- 至少要有 machine-specific `config.d/90-private.conf`
- key 依 `standard path` / `custom-paths` 分類

3. 若 private repo 會進版控，先做 `SOPS + age`

- 設定 `.sops.yaml`
- 建立 `owner` + `recovery` recipients
- 確認 repo 內只存密文

4. materialize 到目標機器

- `~/.ssh/config.d/*.conf`
- `~/.ssh/<key>`
- 或 custom managed path

5. 驗證

```bash
ssh -G <host>
```

若你是用本 repo 的實際範例結構，還可以額外跑：

```bash
./scripts/check-ssh-config.sh
```

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

### 常用指令速查

```bash
chezmoi init --apply <public-repo>
chezmoi update
chezmoi diff
chezmoi apply
chezmoi cd
uv run --directory lib python -m settingzsh.cli preflight
uv run --directory lib python -m settingzsh.cli adopt
uv run --directory lib python -m settingzsh.cli doctor
uv run --directory lib python -m settingzsh.cli reconcile
```

## 既有系統導入與診斷

Linux / macOS 還保留 `settingzsh.cli`，專門處理既有機器 adoption 與舊版 `settingZsh` 狀態。

在 repo source state 內執行：

```bash
chezmoi cd
uv run --directory lib python -m settingzsh.cli preflight
uv run --directory lib python -m settingzsh.cli adopt
uv run --directory lib python -m settingzsh.cli doctor
uv run --directory lib python -m settingzsh.cli migrate
uv run --directory lib python -m settingzsh.cli reconcile
uv run --directory lib python -m settingzsh.cli legacy-import
```

用途：

- `preflight`：blocking adoption gate，判斷這台機器能不能安全導入
- `adopt`：建立 `.zshrc` 備份與 adopt report，不重寫 live shell
- `doctor`：檢查 bootstrap / legacy marker / interactive shell 驗證狀態
- `migrate`：把舊版 `settingZsh:*` 區塊搬到 `managed.d`
- `reconcile`：補齊 bootstrap、`init.zsh`、managed fragments
- `legacy-import`：產生 `local.d/90-legacy-import.zsh.draft`，但不自動啟用

`preflight` / `adopt` 的完整說明請看 [docs/adoption-guide.md](/Users/arlen/Documents/syncthing/backup/server/Code/settingZsh/.worktrees/settingzsh-chezmoi/docs/adoption-guide.md)。

## 專案結構

```text
.
├── .chezmoi.toml.tmpl
├── .chezmoidata/
├── home/
│   ├── modify_dot_zshrc
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

## 故障排查

### `chezmoi apply` 前就知道這台機器風險高

先不要硬套，先跑：

```bash
chezmoi init <public-repo>
chezmoi cd
uv run --directory lib python -m settingzsh.cli preflight
uv run --directory lib python -m settingzsh.cli adopt
```

### shell 語法看起來正常，但互動模式怪怪的

先跑：

```bash
uv run --directory lib python -m settingzsh.cli doctor
```

它會幫你看：

- bootstrap / marker 狀態
- interactive shell warning
- 既有 shell 的高風險訊號

### SSH host 能看到，但連線行為不對

先確認：

```bash
ssh -G <host>
```

如果你有自己的 private repo，再確認：

- key 是否真的 materialize 到目標路徑
- `IdentityFile` 與 `IdentitiesOnly yes` 是否一致
- custom path 是否和實際檔案位置一致

### editor 沒有出現或工具不完整

先確認：

- `feature_editor = true`
- `chezmoi apply` 已重跑
- Linux 若無 sudo，是否已走 fallback 安裝路徑

更細節的 editor 行為請看 [docs/editor-guide.md](/Users/arlen/Documents/syncthing/backup/server/Code/settingZsh/.worktrees/settingzsh-chezmoi/docs/editor-guide.md)。

## 已知限制

- Windows runtime 驗證需要 `pwsh`
- Linux 無 sudo fallback 仍依賴外網下載 release binary
- `custom private repo` 目前不由 public repo 自動拉取
- 遷移期內 legacy `setup*.sh` / `update*.sh` 仍存在，但新安裝應以 `chezmoi` 為主
