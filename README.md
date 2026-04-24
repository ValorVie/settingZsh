# settingZsh

跨平台 shell / profile 基線設定，現在以 `chezmoi` 作為唯一主控制面與主寫檔流程，支援 macOS、Linux、Windows，並保留「公開基線設定（public baseline）+ 自訂私有 repo（custom private repo）」的 SSH 分層模型。

英文術語總表請先看 `docs/terminology.md`。新增英文術語時，也應同步更新這份總表。

延伸文件：

- `docs/terminology.md`：英文術語總表與建議中文寫法
- `docs/architecture.md`：架構、dotfiles / `chezmoi` 原理與專案責任邊界
- `docs/architecture-diagram.md`：目前設計的 Mermaid 架構圖與 fresh-install 流程圖
- `docs/fresh-install-inventory.md`：新系統首次部署時的行為、落地檔案/目錄與各自作用
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
- 管理 Windows PowerShell 5.1 / 7+ profile 目標檔案與共用基線設定
- 透過 `chezmoi run_*` scripts 安裝 base tools、字型與選配 editor 工具
- 提供 `.ssh/config` 主檔與 `config.d` 分層骨架
- `settingzsh.cli` 只保留 Linux / macOS 的 guardrails：`preflight`、`adopt`、`doctor`、`legacy-import`
- `settingzsh.cli` 的 `setup`、`update`、`migrate`、`reconcile` 已退役 / deprecated，不再是正常寫檔流程

## 設計原則

- `public repo` 只管基線設定與非機密設定
- SSH keys 與私有 host 規則放在你自己的 `custom private repo`
- `custom private repo` 建議以 `SOPS + age` 管理密文與 recipients
- `~/.ssh/config` 主檔永遠由公開基線設定管理
- `custom private repo` 只應該提供 `~/.ssh/**`
- `known_hosts` 預設不進版控
- fresh install 與 existing machine adoption 是兩條不同流程
- `~/.zshrc` 只由 bootstrap 擁有，不再讓公開基線設定接管整份檔案
- 新安裝與 baseline 更新都只走 `chezmoi`；舊的 `setup*.sh` / `update*.sh` 已退役，只保留歷史參考與回歸驗證

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
# 預設安裝到 ~/.local/bin
sh -c "$(curl -fsLS get.chezmoi.io)"

# 若你要放到 /usr/bin，改用 -b 指定目錄（需 root 權限）
sudo sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/bin
```

**Windows**

```powershell
winget install twpayne.chezmoi
```

### 2. fresh install：套用 public baseline

這份 README 內的 `public repo` 範例都用本專案：

```bash
PUBLIC_REPO="https://github.com/ValorVie/settingZsh.git"
```

直接套用預設 branch：

```bash
chezmoi init --apply "$PUBLIC_REPO"
```

若你要指定 branch，例如測試 `codex/settingzsh-chezmoi`：

```bash
chezmoi init --apply --branch codex/settingzsh-chezmoi "$PUBLIC_REPO"
```

若你在 server / LXC 上不需要字型，也可以在 fresh install 當下先跳過：

```bash
SETTINGZSH_INSTALL_FONTS=false chezmoi init --apply "$PUBLIC_REPO"
# 或
SETTINGZSH_INSTALL_FONTS=false chezmoi init --apply --branch codex/settingzsh-chezmoi "$PUBLIC_REPO"
```

如果已經 init 過，之後更新直接用：

```bash
chezmoi update
```

### 3. existing machine：先跑 adoption gate

如果這台機器已經有自己的 `~/.zshrc`，建議先：

```bash
chezmoi init "$PUBLIC_REPO"
# 或：chezmoi init --branch codex/settingzsh-chezmoi "$PUBLIC_REPO"
chezmoi cd
uv run --directory lib python -m settingzsh.cli preflight
```

若結果是 `needs_adopt`，先建立 adopt report：

```bash
uv run --directory lib python -m settingzsh.cli adopt
```

再依 [docs/adoption-guide.md](./docs/adoption-guide.md) 判斷要不要導入、保留現況，或產生 `legacy import draft`。不要把 `migrate` / `reconcile` 當成這裡的下一步。

### 4. 重新開啟終端機

**macOS / Linux**

```bash
exec zsh
```

`exec zsh` 只會切換目前這個 session。

如果你要把 login shell 也切成 zsh，請手動執行：

```bash
chsh -s /bin/zsh "$(whoami)"
```

這點在 LXC / container / server 環境特別重要，因為安裝完成不代表帳號的 login shell 會自動改掉。

**Windows**

重新開啟 PowerShell / Windows Terminal。

## 常見操作場景

### 我是新機器，想直接裝好

1. 安裝 `chezmoi`
2. `chezmoi init --apply https://github.com/ValorVie/settingZsh.git`
3. 重新開啟 shell
4. 視需要再開 editor feature（`[data.features]` 下的 `editor = true`）
5. 最後再接你的 `custom private repo`

### 這台機器已經有自己的 `.zshrc`

1. `chezmoi init https://github.com/ValorVie/settingZsh.git`
   若要測試分支，可改成 `chezmoi init --branch codex/settingzsh-chezmoi https://github.com/ValorVie/settingZsh.git`
2. `chezmoi cd`
3. 跑 `preflight`
4. 若不是 `safe`，先跑 `adopt`
5. 確認報告後再決定要不要 `chezmoi apply`

### 我只想更新既有 baseline

1. 先看本次更新會改哪些目標檔：

   ```bash
   chezmoi diff
   ```

2. 更新已初始化過的 source state 並重新套用 baseline：

   ```bash
   chezmoi update
   ```

3. 若只是調整本機 `~/.config/chezmoi/chezmoi.toml`，例如 feature flag 或 private SSH overlay，直接重新套用即可：

   ```bash
   chezmoi apply
   ```

4. 若更新內容包含 shell loader / tmux 相關修正，既有 tmux server 可能還保留舊環境。更新後可清掉舊 guard，再開新的 tmux pane / window：

   ```bash
   unset SETTINGZSH_LOADED
   tmux set-environment -u SETTINGZSH_LOADED 2>/dev/null
   tmux set-environment -gu SETTINGZSH_LOADED 2>/dev/null
   ```

   不需要直接 `tmux kill-server`，除非你確定可以關閉所有 tmux session。

5. 若有 shell 異常，再跑 `doctor`。若是既有機器要看導入風險，回到 `preflight` / `adopt`。

### 我想卸載 / 重置這台機器

1. 先看 [docs/uninstall-guide.md](./docs/uninstall-guide.md)
2. 正式入口是 [`scripts/uninstall-settingzsh.sh`](./scripts/uninstall-settingzsh.sh)
3. 標準流程是 `--dry-run` -> `--execute` -> `--restore <backup-id>`
4. 卸載不是重新安裝，不會自動重新 init
5. 如果你先前手動把 login shell 改成 `/bin/zsh`，卸載不會替你改回去

### 我想把 SSH 私有設定接上去

1. 先確認 public baseline 已建立 `~/.ssh/config`
2. 準備好 `custom private repo`（結構參考 [`examples/valor-ssh-key/`](examples/valor-ssh-key/README.md)）
3. 在 `~/.config/chezmoi/chezmoi.toml` 開啟 `[data.features].private_ssh_overlay`，並填入 `[data.overlay].repo`
4. 若 repo 內是 `SOPS + age` 密文，先準備 `sops` 與 `SOPS_AGE_KEY_FILE`
5. 跑 `chezmoi apply` 或 `chezmoi update`
6. 跑 `ssh -G <host>` 檢查結果

## preflight 結果怎麼看

`preflight` 只有三種主要結果：

- `safe`
  - 可以繼續 `chezmoi apply` 或 `chezmoi update`
- `needs_adopt`
  - 代表這台機器已有重型 shell 生態
  - 先跑 `adopt`，不要直接套用
- `broken_existing_shell`
  - 代表現況 shell 本身就不健康
  - 先修現況，再談導入

最小流程：

```bash
chezmoi init "$PUBLIC_REPO"
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

補充：`chezmoi init --apply` 會先安裝 Zinit 本體；預設 zsh plugins 會在下一次 interactive `zsh` 啟動時，由 `managed.d/10-base.zsh` 透過 Zinit 自動拉下。

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
- 不自動佈署 SSH 私鑰，除非你明確開啟 `private_ssh_overlay`
- 不接管整份 `~/.zshrc`
- 不同步 `known_hosts`
- 不為 existing machine 自動清理舊 `.zshrc`

### 卸載與重置

這個 repo 現在的正式卸載入口是 [`scripts/uninstall-settingzsh.sh`](./scripts/uninstall-settingzsh.sh)；完整說明請看 [docs/uninstall-guide.md](./docs/uninstall-guide.md)。

如果你懷疑 source state 還卡在舊版，先不要直接重跑 `chezmoi init --apply`。請先照卸載指南把舊的 `~/.local/share/chezmoi` 與相關目標狀態處理乾淨，再決定要不要重新安裝。

卸載流程本身不會自動重新 init，也不會替你把手動 `chsh -s /bin/zsh "$(whoami)"` 改回去。

## 完整安裝指南

### Machine data 與 feature flags

這個 repo 用 repo root 的 `.chezmoiroot` 把 chezmoi source root 指到 `home/`，所以主要 data key 在 `home/.chezmoi.toml.tmpl`：

```toml
[data.features]
editor = false
fonts = true
private_ssh_overlay = false

[data.overlay]
repo = ""
profile = "auto"
```

private overlay external 定義放在 `home/.chezmoiexternal.toml.tmpl`。

目前真正會影響安裝行為的主要是：

- `[data.features].editor`
- `[data.features].fonts`
- `[data.features].private_ssh_overlay`
- `[data.overlay].repo`
- `[data.overlay].profile`

另外可用的環境變數覆蓋有：

- `SETTINGZSH_FEATURE_EDITOR`
- `SETTINGZSH_INSTALL_FONTS`
- `SETTINGZSH_PRIVATE_SSH_OVERLAY`
- `SETTINGZSH_PLATFORM_PROFILE`
- `SETTINGZSH_PRIVATE_SSH_OVERLAY_PROFILE`

若你要在本機覆蓋預設值，編輯 `~/.config/chezmoi/chezmoi.toml`：

```toml
[data.features]
editor = true
fonts = true
```

改完後重新套用：

```bash
chezmoi apply
```

### 啟用 private SSH overlay

如果你要讓 public baseline 在第二階段自動拉取並落地 SSH private repo，先在本機 `~/.config/chezmoi/chezmoi.toml` 設定：

```toml
[data.features]
private_ssh_overlay = true

[data.overlay]
repo = "git@github.com:<you>/<your-private-repo>.git"
profile = "auto"
```

再執行：

```bash
chezmoi apply
```

行為如下：

- external checkout 會落在 `~/.local/share/settingzsh/private-ssh-overlay`
- `shared/config.d/` 會寫入到 `~/.ssh/config.d/`
- `shared-keys/keys/` 與 `<profile>/keys/` 會寫入到 `~/.ssh/`
- `<profile>/custom-paths/` 會寫入到 `~/.ssh/custom-paths/`
- `[data.overlay].profile = "auto"` 會用目前機器的 short hostname；若要覆蓋，可用 `SETTINGZSH_PLATFORM_PROFILE` 或 `SETTINGZSH_PRIVATE_SSH_OVERLAY_PROFILE`

若 private repo 內是 `SOPS + age` 密文，目標機器上要先有 `sops`，並提供可用的 age private key，例如：

```bash
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/owner.txt"
chezmoi apply
```

若你不想走自動 overlay，仍可維持手動 clone / decrypt / copy 流程；public baseline 不會強制要求這個功能。

### 啟用 editor 環境

這會依平台安裝或部署：

- macOS / Linux：Vim、Neovim、`nvm`、Node.js LTS、`ripgrep`、`fd`、`lazygit`、repo 內的 `nvim/` 設定，以及 `.vimrc` merge
- Windows：Neovim、`nvm-windows`、Node.js LTS、`ripgrep`、`fd`、`lazygit`，以及 repo 內的 `nvim/` 設定

啟用方式有兩種。

**持久化做法**

```toml
[data.features]
editor = true
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
[data.features]
editor = true
```

關閉：

```toml
[data.features]
editor = false
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

若你要暫時跳過字型安裝，可用任一種方式：

```toml
[data.features]
fonts = false
```

或：

```bash
SETTINGZSH_INSTALL_FONTS=false chezmoi apply
```

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
- `custom managed path`：例如 `~/.ssh/custom-paths/sympasoft-macmini-ssh/<key>`

### 建議流程

1. 先套用 public baseline
2. 確認 `~/.ssh/config` 與 `~/.ssh/config.d/` 已存在
3. 建議用 `[data.features].private_ssh_overlay = true` 搭配 `[data.overlay].repo`，讓 `chezmoi apply` 自動拉取並寫入到正確路徑
4. 若你不想自動拉取，再走手動 clone / decrypt / copy 流程
5. 確認 `~/.ssh/config.d/90-private.conf` 與 key file 權限正確（私鑰 600）

> 若要用自動 overlay，目標機器必須能 `git clone` 你的 private repo。若檔案是 `SOPS + age` 密文，還必須先準備 `sops` 與 age private key。若不符合這兩個前提，就維持手動流程。

### custom private repo 最小接線流程

這是最小可用流程，先列自動模式，再列手動 fallback：

1. public baseline 先完成

```bash
chezmoi init --apply https://github.com/ValorVie/settingZsh.git
# 或：chezmoi init --apply --branch codex/settingzsh-chezmoi https://github.com/ValorVie/settingZsh.git
```

2. 準備 private repo 結構

- 參考 `examples/valor-ssh-key/`
- 至少要有 machine-specific `config.d/90-private.conf`
- key 依 `standard path` / `custom-paths` 分類

3. 自動模式：把 overlay data 接到 chezmoi

```toml
[data.features]
private_ssh_overlay = true

[data.overlay]
repo = "git@github.com:<you>/<your-private-repo>.git"
profile = "auto"
```

若 private repo 內是密文，再先準備：

```bash
export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/owner.txt"
```

然後：

```bash
chezmoi apply
```

4. 手動 fallback：若不走自動 overlay，再手動 clone / decrypt / copy

在目標機器上 clone private repo、解密、複製到 `~/.ssh/`。完整的逐步指令請見 [`examples/valor-ssh-key/README.md`](examples/valor-ssh-key/README.md) 的「部署到目標機器」段落，最終結果應該是：

- `~/.ssh/config.d/*.conf` — private host 設定
- `~/.ssh/<key>` — 解密後的私鑰（權限 600）
- 或 custom managed path（如 `~/.ssh/custom-paths/sympasoft-macmini-ssh/`）

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

補充：

- `chezmoi cd` 會進到 source root，也就是 `~/.local/share/chezmoi/home`
- 如果你要改 repo root 內的 `lib/`、`docs/`、`tests/`，先回到 `chezmoi` clone root：

```bash
cd "$(dirname "$(chezmoi source-path)")"
```

### 常用指令速查

```bash
chezmoi init --apply https://github.com/ValorVie/settingZsh.git
chezmoi init --apply --branch codex/settingzsh-chezmoi https://github.com/ValorVie/settingZsh.git
chezmoi update
chezmoi diff
chezmoi apply
chezmoi cd
uv run --directory lib python -m settingzsh.cli preflight
uv run --directory lib python -m settingzsh.cli adopt
uv run --directory lib python -m settingzsh.cli doctor
uv run --directory lib python -m settingzsh.cli legacy-import
```

## 既有系統導入與診斷

Linux / macOS 還保留 `settingzsh.cli` 的 guardrails，專門處理既有機器 adoption 與舊版 `settingZsh` 狀態；它不是 baseline 寫檔主流程。

在 repo root 執行，不是 `home/` source root：

```bash
cd "$(dirname "$(chezmoi source-path)")"
uv run --directory lib python -m settingzsh.cli preflight
uv run --directory lib python -m settingzsh.cli adopt
uv run --directory lib python -m settingzsh.cli doctor
uv run --directory lib python -m settingzsh.cli legacy-import
```

用途：

- `preflight`：blocking adoption gate，判斷這台機器能不能安全導入
- `adopt`：建立 `.zshrc` 備份與 adopt report，不重寫 live shell
- `doctor`：檢查 bootstrap / legacy marker / interactive shell 驗證狀態
- `legacy-import`：產生 `local.d/90-legacy-import.zsh.draft`，但不自動啟用

退役 / deprecated write paths：

- `setup`
- `update`
- `migrate`
- `reconcile`

這些名稱只保留歷史文件與舊輸出對照，不應再當成新安裝、baseline 更新或 adoption 的下一步。

`preflight` / `adopt` / `doctor` / `legacy-import` 的完整說明請看 [docs/adoption-guide.md](./docs/adoption-guide.md)。

## 專案結構

```text
.
├── .chezmoiroot
├── home/
│   ├── .chezmoi.toml.tmpl
│   ├── .chezmoiexternal.toml.tmpl
│   ├── .chezmoiignore.tmpl
│   ├── .chezmoidata/
│   ├── modify_dot_zshrc
│   ├── dot_config/settingzsh/init.zsh.tmpl
│   ├── dot_config/settingzsh/managed.d/
│   ├── dot_config/settingzsh/powershell/
│   ├── Documents/PowerShell/
│   ├── Documents/WindowsPowerShell/
│   ├── private_dot_ssh/
│   ├── run_once_before_*.tmpl
│   └── run_onchange_after_*.tmpl
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
bash tests/chezmoi/test_fonts_feature_gating.sh
bash tests/chezmoi/test_ssh_overlay.sh
bash tests/chezmoi/test_apply_smoke.sh
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
chezmoi init https://github.com/ValorVie/settingZsh.git
# 若你正在測試分支：
# chezmoi init --branch codex/settingzsh-chezmoi https://github.com/ValorVie/settingZsh.git
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

- key 是否真的寫入到目標路徑
- `IdentityFile` 與 `IdentitiesOnly yes` 是否一致
- custom path 是否和實際檔案位置一致

### 我懷疑 source state 還留在舊版

如果你發現 `~/.local/share/chezmoi` 還留著舊 source state，不要直接重跑 `chezmoi init --apply`。

先看 [docs/uninstall-guide.md](./docs/uninstall-guide.md)，用正式卸載入口把舊狀態清乾淨，再決定要不要重新安裝。

### editor 沒有出現或工具不完整

先確認：

- `[data.features].editor = true`
- `chezmoi apply` 已重跑
- Linux 若無 sudo，是否已走 fallback 安裝路徑
- 若是字型沒裝，檢查是否把 `[data.features].fonts` 關掉了

更細節的 editor 行為請看 [docs/editor-guide.md](./docs/editor-guide.md)。

## 已知限制

- Windows runtime 驗證需要 `pwsh`
- Linux 無 sudo fallback 仍依賴外網下載 release binary
- 自動 private overlay 依賴 private repo 可被 git clone；若內容是密文，還需要 `sops` 與 age key
- 遷移期內 legacy `setup*.sh` / `update*.sh` 仍存在，但它們已退役，不再是新安裝或 baseline 更新的正常入口
