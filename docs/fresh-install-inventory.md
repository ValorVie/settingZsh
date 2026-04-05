# settingZsh 新機器首次安裝行為與落地清單

這份文件專門回答一個問題：

> 一台新系統執行這個 branch 的 `chezmoi init --apply --branch codex/settingzsh-chezmoi https://github.com/ValorVie/settingZsh.git` 時，到底會做什麼、會落哪些檔案/目錄、各自有什麼作用？

若你要看高層架構，先看 [architecture.md](./architecture.md) 與 [architecture-diagram.md](./architecture-diagram.md)。
若你不熟這份文件裡的英文術語，先看 [terminology.md](./terminology.md)。

## 適用範圍

- public repo：`https://github.com/ValorVie/settingZsh.git`
- branch：`codex/settingzsh-chezmoi`
- 主流程：`chezmoi init --apply`
- 本文件以「新機器首次部署」為主，只描述 `chezmoi` 的首次寫入與後續 baseline 更新；既有機器導入不在這裡談
- baseline 更新同樣只走 `chezmoi update`

## 預設行為開關

來源是 [home/.chezmoi.toml.tmpl](/home/valor/settingZsh/home/.chezmoi.toml.tmpl#L1)。

| 設定 | 預設值 | 影響 |
| --- | --- | --- |
| `[data.features].editor` | `false` | 不執行 editor 安裝腳本 |
| `[data.features].private_ssh_overlay` | `false` | 不 clone / 不套用 private SSH overlay |
| `[data.overlay].repo` | `""` | overlay repo 預設未設定 |
| `[data.features].fonts` | `true` | 預設會安裝 Maple Mono Nerd Font |
| `[data.overlay].profile` | `"auto"` | private overlay profile 預設依主機名稱自動判斷 |

## 新機器首次安裝流程

1. `chezmoi` 先把 public repo clone 到 `~/.local/share/chezmoi`。
2. `.chezmoiroot` 指定來源根目錄是 `home/`，所以 `chezmoi` 真正讀取的是 repo 內的 `home/`，不是 repo root。
3. `chezmoi` 先把公開基線設定寫入目標路徑，例如 `~/.zshrc`、`~/.config/settingzsh/*`、`~/.ssh/config`、PowerShell profile。
4. `run_once_before_*` 腳本在套用前執行：
   - `10-install-base-packages`
   - `15-install-zinit`
   - `20-install-fonts`
5. `run_onchange_after_*` 腳本在內容變更後執行：
   - `30-install-editor`
   - `40-install-private-ssh`
6. 非 Windows 主機第一次 interactive `zsh` 啟動時，`~/.config/settingzsh/managed.d/10-base.zsh` 會透過 Zinit 載入預設 plugins。

## 會留在系統上的工作目錄與來源目錄

上一節列的是「實際寫進家目錄、要被 shell / ssh / PowerShell 直接讀取的檔案」。

但新機器首次安裝完成後，系統上還會留下另一類目錄：它們不是最終 dotfile 目標，本身也不一定會被 shell 直接 `source`，但屬於 `chezmoi` 或安裝腳本的工作目錄，會長期存在。

| 路徑 | 類型 | 何時出現 | 作用 |
| --- | --- | --- | --- |
| `~/.local/share/chezmoi/` | `chezmoi` 來源 repo 的本地 clone | `chezmoi init --apply` | 這是 public repo 的本地副本。之後 `chezmoi update`、`chezmoi diff`、`chezmoi source-path` 都會用到它。 |
| `~/.local/share/chezmoi/home/` | 實際來源根目錄 | 同上 | 因為 repo 用 `.chezmoiroot = home`，所以這個目錄才是真正被 `chezmoi` 當成來源根目錄。`chezmoi source-path` 會指到這裡。 |
| `~/.local/share/chezmoi/home/modify_dot_zshrc` | 來源模板檔 | 同上 | `~/.zshrc` 的 modify-template。它會留在來源目錄內，不會被部署成 `~/modify_dot_zshrc`。 |
| `~/.local/bin/` | 使用者級工具安裝目錄 | `10-install-base-packages`、editor fallback | 存放 `uv`、`uvx`，以及某些 fallback 安裝的 CLI，例如 `rg`、`fd`、`lazygit`、Neovim unpack 產物。 |
| `~/.local/share/zinit/zinit.git/` | Zinit 本體安裝目錄 | `15-install-zinit` | Zinit git checkout，本體由這裡被 `managed.d/10-base.zsh` 載入。 |
| `~/.cache/zinit/completions/` | Zinit cache/completion 目錄 | `10-install-base-packages` | 提前建立的 completion cache 目錄。 |
| `~/.fzf/` | `fzf` fallback checkout | Linux fallback 情境 | 當系統套件安裝不到 `fzf` 時，會 clone upstream repo 到這裡並執行安裝器。 |
| `~/.nvm/` | Node version manager 家目錄 | `30-install-editor` 且 editor feature 啟用 | NVM 與 Node LTS 安裝位置。 |
| `~/.local/share/fonts/MapleMono/` | Linux 字型安裝目錄 | `20-install-fonts` 且 `[data.features].fonts = true` | Maple Mono Nerd Font 的實際落地位置。 |
| `~/Library/Fonts/` | macOS 字型安裝目錄 | `20-install-fonts` | macOS 字型落地位置。 |
| `~/.local/share/settingzsh/private-ssh-overlay/` | private SSH 覆蓋層的本地 clone | `40-install-private-ssh` 且覆蓋層啟用 | private SSH repo 的本地副本；腳本再把其中內容同步到 `~/.ssh/`、`~/.ssh/config.d/`、`~/.ssh/custom-paths/`。 |

補充：

- 我用隔離 `HOME` 真實跑 `chezmoi init --apply` 驗證過，`chezmoi source-path` 會指到 `~/.local/share/chezmoi/home`。
- 也就是說，`~/.local/share/chezmoi` 是 repo 本地副本；`~/.local/share/chezmoi/home` 才是這個 repo 在 `chezmoi` 觀點下的來源根目錄。

## 一定會寫入家目錄的檔案與目錄

下表是我用隔離 `HOME` 實際跑 `chezmoi apply --exclude=scripts` 後確認的常駐目標檔案。

| 目標路徑 | 來源 | 作用 |
| --- | --- | --- |
| `~/.zshrc` | `home/modify_dot_zshrc` | shell 主入口。新機器首次部署會寫成最小啟動橋接區塊。較複雜的 modify 行為與導入邊界請看 adoption guide。 |
| `~/.config/settingzsh/init.zsh` | `home/dot_config/settingzsh/init.zsh.tmpl` | `settingZsh` 載入器，先載入 `managed.d/*.zsh`，再載入 `local.d/*.zsh`。 |
| `~/.config/settingzsh/managed.d/10-base.zsh` | `home/dot_config/settingzsh/managed.d/10-base.zsh.tmpl` | Zsh 基線設定：PATH、Powerlevel10k instant prompt、Zinit、預設 plugins、history、completion、`fzf`/`zoxide` 初始化。 |
| `~/.config/settingzsh/managed.d/40-editor.zsh` | `home/dot_config/settingzsh/managed.d/40-editor.zsh.tmpl` | editor shell integration，目前主要是 `nvm` lazy loading。這個檔案會存在，但 editor 安裝本身預設不會跑。 |
| `~/.config/settingzsh/powershell/public-baseline.ps1` | `home/dot_config/settingzsh/powershell/public-baseline.ps1.tmpl` | PowerShell 公共基線設定，載入 `Terminal-Icons`、`ZLocation`、`PSFzf`，若有 `starship` 則初始化。 |
| `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1` | `home/Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl` | PowerShell 7+ profile 橋接檔，唯一職責是轉接到 `public-baseline.ps1`。 |
| `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1` | `home/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1.tmpl` | Windows PowerShell 5.1 profile 橋接檔，唯一職責是轉接到 `public-baseline.ps1`。 |
| `~/.ssh/config` | `home/private_dot_ssh/config.tmpl` | 公開安全的 SSH 基線設定，定義 `Host *` 通用設定並 `Include ~/.ssh/config.d/*.conf`。 |
| `~/.ssh/config.d/10-common.conf` | `home/private_dot_ssh/config.d/10-common.conf.tmpl` | 保留給可公開分享的 SSH 通用設定，目前是安全骨架。 |
| `~/.config/settingzsh/` | 父目錄 | 管理 shell / PowerShell baseline 的主目錄。 |
| `~/.ssh/config.d/` | 父目錄 | SSH include 目錄，private overlay 也會往這裡落檔。 |
| `~/Documents/PowerShell/` | 父目錄 | PowerShell 7+ profile 目錄。 |
| `~/Documents/WindowsPowerShell/` | 父目錄 | Windows PowerShell 5.1 profile 目錄。 |

## run scripts 會做的事

這些腳本不是常駐目標檔案。`chezmoi` 會在執行時把它們渲染成暫存檔，跑完就結束，不會在 `~` 留下 `10-install-base-packages.sh` 這類檔案。

### `run_once_before_10-install-base-packages`

| 平台 | 腳本 | 行為 | 可能落地 |
| --- | --- | --- | --- |
| Linux / macOS | `run_once_before_10-install-base-packages.sh.tmpl` | 建立共用目錄，安裝基線套件 | `~/.local/bin/`、`~/.cache/zinit/completions/`、`~/.config/settingzsh/managed.d/`、`~/.config/settingzsh/local.d/` |
| Linux | 同上 | 透過 `apt` 安裝 `zsh git unzip xz-utils fontconfig curl ca-certificates fzf`；若 `fzf`/`zoxide` 缺失則用 fallback 安裝 | 可能建立 `~/.fzf/`、`~/.local/bin/` |
| macOS | 同上 | 透過 `brew install zsh git unzip xz fzf zoxide` | 依 Homebrew 路徑 |
| Linux / macOS | 同上 | 若 `uv` 不存在則安裝 `uv` | `~/.local/bin/uv`、`~/.local/bin/uvx` |
| Windows | `run_once_before_10-install-base-packages.ps1.tmpl` | 建立 PowerShell profile / config 目錄、安裝 PowerShell modules、嘗試用 `winget` 裝 `fzf` / `Starship` | `~/Documents/PowerShell/`、`~/Documents/WindowsPowerShell/`、`~/.config/settingzsh/`、PowerShell CurrentUser module path |

### `run_once_before_15-install-zinit`

| 平台 | 腳本 | 行為 | 落地 |
| --- | --- | --- | --- |
| Linux / macOS | `run_once_before_15-install-zinit.sh.tmpl` | clone 或更新 Zinit 本體 | `~/.local/share/zinit/zinit.git` |

補充：這一步只安裝 Zinit 本體。`powerlevel10k`、`fzf-tab`、`zsh-autosuggestions` 等 plugins 會在下一次 interactive `zsh` 啟動時由 `10-base.zsh` 拉下。

### `run_once_before_20-install-fonts`

| 平台 | 腳本 | 條件 | 行為 | 落地 |
| --- | --- | --- | --- | --- |
| Linux / macOS | `run_once_before_20-install-fonts.sh.tmpl` | `[data.features].fonts = true` 或 `SETTINGZSH_INSTALL_FONTS=true` | 下載 Maple Mono Nerd Font 並安裝 | Linux：`~/.local/share/fonts/MapleMono/`；macOS：`~/Library/Fonts/` |
| Windows | `run_once_before_20-install-fonts.ps1.tmpl` | 同上 | 下載字型、拷貝到使用者字型目錄、寫入 registry | `~/AppData/Local/Microsoft/Windows/Fonts/` |

### `run_onchange_after_30-install-editor`

| 平台 | 腳本 | 條件 | 行為 | 可能落地 |
| --- | --- | --- | --- | --- |
| Linux / macOS | `run_onchange_after_30-install-editor.sh.tmpl` | `[data.features].editor = true` 或 `SETTINGZSH_FEATURE_EDITOR=true` | 安裝 editor 依賴、安裝 `nvm` + Node LTS、merge `.vimrc`、deploy `nvim` config | `~/.nvm/`、`~/.config/nvim/`、`~/.vimrc`、`~/.local/bin/rg`、`~/.local/bin/fd`、`~/.local/bin/lazygit`、`~/.local/`（fallback Neovim） |
| Windows | `run_onchange_after_30-install-editor.ps1.tmpl` | 同上 | 用 `winget` 安裝 Neovim / NVM / ripgrep / fd / lazygit，複製 `nvim` 設定 | `~/AppData/Local/nvim` |

補充：

- 這個 branch 預設 `[data.features].editor = false`，所以新機器首次安裝預設只會寫入 `40-editor.zsh`，不會真的安裝 editor toolchain。
- 若目標位置已有 `~/.config/nvim` 或 Windows 的 `~/AppData/Local/nvim`，腳本會先備份成 `.bak` 再覆蓋。

### `run_onchange_after_40-install-private-ssh`

| 平台 | 腳本 | 條件 | 行為 | 落地 |
| --- | --- | --- | --- | --- |
| Linux / macOS | `run_onchange_after_40-install-private-ssh.sh.tmpl` | `[data.features].private_ssh_overlay = true` 且 `[data.overlay].repo` 已設定 | 套用 private SSH overlay；必要時用 `sops decrypt` 解密檔案 | `~/.local/share/settingzsh/private-ssh-overlay/`、`~/.ssh/config.d/`、`~/.ssh/`、`~/.ssh/custom-paths/` |
| Windows | `run_onchange_after_40-install-private-ssh.ps1.tmpl` | 同上 | 同樣邏輯，並調整 ACL 權限 | 同上（Windows 路徑語法） |

private SSH 覆蓋層的來源目錄模型如下：

- `shared/config.d/` -> `~/.ssh/config.d/`
- `shared-keys/keys/` -> `~/.ssh/`
- `<profile>/config.d/` -> `~/.ssh/config.d/`
- `<profile>/keys/` -> `~/.ssh/`
- `<profile>/custom-paths/` -> `~/.ssh/custom-paths/`

## 預設新機器首次安裝的落地結果

以下是 Linux 上用隔離 `HOME` 實際跑 `chezmoi apply --exclude=scripts` 得到的常駐目錄樹。這代表「公開基線設定一定會寫進去的檔案」，不包含腳本額外安裝物。

```text
~
~/.config
~/.config/settingzsh
~/.config/settingzsh/init.zsh
~/.config/settingzsh/managed.d
~/.config/settingzsh/managed.d/10-base.zsh
~/.config/settingzsh/managed.d/40-editor.zsh
~/.config/settingzsh/powershell
~/.config/settingzsh/powershell/public-baseline.ps1
~/.ssh
~/.ssh/config
~/.ssh/config.d
~/.ssh/config.d/10-common.conf
~/.zshrc
~/Documents
~/Documents/PowerShell
~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1
~/Documents/WindowsPowerShell
~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1
```

如果用預設開關直接跑完整 `chezmoi init --apply`，通常還會額外看到：

- `~/.local/share/chezmoi/`
- `~/.local/share/chezmoi/home/`
- `~/.local/bin/`
- `~/.cache/zinit/completions/`
- `~/.config/settingzsh/local.d/`
- `~/.local/share/zinit/zinit.git/`
- `~/.local/share/fonts/MapleMono/`（Linux）

## 不直觀但重要的行為

- `.zshrc` 的 bootstrap 只允許一份。`modify_dot_zshrc` 會先移除舊的 `settingZsh bootstrap` 區塊，再補回一個標準單一區塊。
- PowerShell profile 目標目前是跨平台寫入的，所以在 Linux / macOS 也會看到 `~/Documents/PowerShell/*`。它們本身很輕，只是橋接到 `public-baseline.ps1`。
- `private_ssh_overlay` 預設關閉，所以新機器首次安裝不會自動出現 `~/.ssh/custom-paths/` 或 private host/key。
- `run_once_before_15-install-zinit` 只保證 Zinit 本體存在，不代表 plugins 在 `apply` 當下就全下載完成。

## 相關檔案

- [architecture.md](./architecture.md)
- [architecture-diagram.md](./architecture-diagram.md)
- [adoption-guide.md](./adoption-guide.md)
- [editor-guide.md](./editor-guide.md)
