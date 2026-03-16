# settingZsh 架構說明

這份文件說明三件事：

1. dotfiles 在解決什麼問題
2. `chezmoi` 的核心運作原理
3. 這個專案在 `chezmoi` 之上額外補了哪些能力與邊界

若你只想知道如何安裝與日常使用，請先看 `README.md`；若你要理解這個 repo 為什麼這樣切分，從這份文件開始比較合適。

## 先講結論

`settingZsh` 現在的角色不是「一套會接管整份 shell 設定的自訂安裝器」，而是：

- 用 `chezmoi` 管理跨平台 dotfiles 與部署流程
- 用 `public baseline + custom private repo` 處理公開設定與 SSH secrets 的責任切分
- 用 `SOPS + age` 管理 private SSH repo 的檔案加密與 recipient
- 用少量專案邏輯補齊原生 dotfiles 工具通常不直接處理的部分
  - 平台工具安裝
  - 字型安裝
  - editor feature gating
  - adoption gate、舊版 `settingZsh` 環境遷移與診斷

## 什麼是 dotfiles

dotfiles 指的是使用者家目錄下的設定檔，例如：

- `~/.zshrc`
- `~/.gitconfig`
- `~/.ssh/config`
- `~/.config/nvim/`
- PowerShell profile

管理 dotfiles 的主要目的不是「備份幾個檔案」而已，而是：

- 在新機器快速重建熟悉的工作環境
- 在多台機器間維持一致的 baseline
- 讓設定變更可以進版控、review、回溯
- 將「共用設定」與「機器專屬差異」分開管理

dotfiles 工具通常擅長的是「檔案狀態管理」，不一定擅長處理：

- 套件安裝
- 字型安裝
- 需要平台判斷的 shell 行為
- 舊環境遷移
- 與既有手工設定共存的診斷

這也是本專案仍然保留一部分額外邏輯的原因。

## `chezmoi` 的核心原理

`chezmoi` 可以把它想成「宣告式管理家目錄檔案的控制面」。它有幾個核心概念。

### 1. Source state 與 target state

- `source state`
  - 也就是 repo 內的檔案結構與模板
  - 例如 `home/modify_dot_zshrc`
- `target state`
  - 真正落在使用者家目錄裡的檔案
  - 例如 `~/.zshrc`

`chezmoi apply` 做的事，就是把 source state 渲染並同步到 target state。對這個 repo 來說，`~/.zshrc` 已不再是單純 whole-file target，而是透過 `modify_` source state 只建立或插入 bootstrap。

### 2. Template 與 data

`chezmoi` 支援模板與資料注入，所以同一份 source state 可以根據平台或機器資料產生不同結果。

例如：

- macOS / Linux / Windows 可以套不同 profile 路徑
- `feature_editor = true` 時才啟用 editor 安裝
- `install_fonts = false` 時跳過字型流程

在這個 repo 裡，這些設定主要來自：

- `.chezmoi.toml.tmpl`
- `.chezmoidata/`
- 使用者本機的 `~/.config/chezmoi/chezmoi.toml`

### 3. Target naming 規則

`chezmoi` 不是直接把 repo 內檔名原樣複製，而是透過命名規則描述目標檔案型態，例如：

- `modify_dot_zshrc` -> `~/.zshrc`（modify-based bootstrap ownership）
- `private_dot_ssh/config.tmpl` -> `~/.ssh/config`

這讓同一份 source state 可以同時表達：

- 目標路徑
- 是否為私密檔案
- 是否為模板

### 4. `run_*` scripts

純 dotfiles 無法處理的安裝動作，可以交給 `run_once_*` 或 `run_onchange_*` scripts。

這個 repo 目前用它們來做：

- base packages 安裝
- Maple Mono 字型安裝
- editor 工具安裝
- 依平台選擇安裝路徑或 fallback

### 5. 日常操作

最重要的幾個指令是：

- `chezmoi init --apply`（fresh install）
- `chezmoi init`（existing machine 先 init，不急著 apply）
- `chezmoi apply`
- `chezmoi update`
- `chezmoi diff`
- `chezmoi cd`

對這個專案來說，`chezmoi` 已經是新的主要控制面。

## 本專案的架構

### 一張圖看分層

```text
repo source state
├── public baseline
│   ├── shell / profile templates
│   ├── .ssh/config 主檔與共用 config.d
│   ├── run_* 安裝腳本
│   ├── nvim / vim baseline
│   └── machine data / feature flags
└── adoption guardrails
    ├── preflight / adopt / doctor
    └── migrate / reconcile / legacy import draft

apply 後的 target state
├── ~/.zshrc
├── ~/.config/settingzsh/managed.d/*.zsh
├── PowerShell profiles
├── ~/.ssh/config
└── 其他工具與字型

外部 overlay
└── custom private repo
    └── 只負責 ~/.ssh/**
```

### 1. Public baseline

public baseline 是這個專案的唯一主入口與主要 source of truth，負責：

- macOS / Linux 的 Zsh bootstrap ownership 與 managed fragments
- Windows PowerShell 5.1 / 7+ profile baseline
- `.ssh/config` 主檔與 `config.d/10-common.conf`
- `nvim/`、`.vimrc` 與 editor 相關部署來源
- 平台安裝腳本
- feature flags 與 machine data

它刻意不負責：

- SSH 私鑰
- 私有 bastion / host 規則
- `known_hosts`
- 其他 secret

### 2. Custom private repo

SSH secrets 不放在 public repo，而是放在你自己的 `custom private repo`。

這個 repo 的邊界很刻意，只應該管理：

- `~/.ssh/id_*`
- `~/.ssh/*.pub`
- `~/.ssh/config.d/*.conf`
- 其他明確屬於 SSH 的私有內容

它不應該管理：

- `~/.ssh/config` 主檔
- shell / nvim / 其他一般 dotfiles
- `known_hosts`

原因很單純：一旦 private repo 開始承載一般 dotfiles，它就會長成第二套主系統，後續很容易 drift。

repo 內提供了參考範本：

- `examples/valor-ssh-key/`

範本目錄採顯式分層：

- `shared/config.d/`
- `shared-keys/keys/`
- `<machine>/config.d/`
- `<machine>/keys/`
- `<machine>/custom-paths/`

README 裡統一稱呼這個概念為 `custom private repo`，不綁死 repo 名稱。

### 3. Shell / profile runtime 結構

#### macOS / Linux

`~/.zshrc` 不再由 public baseline 直接整份擁有，而是只擁有 bootstrap：

```zsh
if [ -f "$HOME/.config/settingzsh/init.zsh" ]; then
  source "$HOME/.config/settingzsh/init.zsh"
fi
```

實際 source state 不是 `dot_zshrc.tmpl`，而是 `home/modify_dot_zshrc`。它會做兩件事：

- 檔案不存在時建立極小 bootstrap
- 檔案已存在時只插入 `settingZsh bootstrap` 區塊

這就是 adoption guardrails 的第一層：public baseline 不再直接接管既有整份 `.zshrc`。

真正的 managed 內容放在：

- `~/.config/settingzsh/init.zsh`
- `~/.config/settingzsh/managed.d/10-base.zsh`
- `~/.config/settingzsh/managed.d/40-editor.zsh`

必要時使用者還可以自行加：

- `~/.config/settingzsh/local.d/*.zsh`

這個模型的重點是：

- 不再讓工具接管整份 `~/.zshrc`
- 把 baseline 與 local customization 分層
- 降低其他工具插手 `~/.zshrc` 時的破壞面

#### Windows

PowerShell 採雙 profile target：

- `~/Documents/PowerShell/Microsoft.PowerShell_profile.ps1`
- `~/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1`

這兩個 target 只負責 source：

- `~/.config/settingzsh/powershell/public-baseline.ps1`

這樣可以讓 PowerShell 5.1 與 7+ 共用同一份 baseline 邏輯，同時保留 target parity。

## 這個專案比原生 `chezmoi` 多做了什麼

如果只用原生 `chezmoi`，可以管檔案，但還不夠覆蓋本專案原本承諾的能力。這個 repo 額外補了幾件事。

### 1. 平台安裝能力

透過 `run_*` scripts 補齊：

- macOS：Homebrew 生態、字型安裝、shell 工具
- Linux：`sudo -n` 檢查、無 sudo fallback、使用者空間 binary 安裝
- Windows：PowerShell modules、`winget` / 使用者目錄下的工具與字型配置

這些不只是「把檔案放進家目錄」，而是讓新機器真的能得到可用的環境。

### 2. Feature gating

目前至少有兩個重要 feature flag：

- `feature_editor`
- `install_fonts`

這代表安裝不是單一路徑，而是可以在「維持 baseline」的前提下，針對較重的功能選擇性啟用。

### 3. Adoption guardrails 與舊版 `settingZsh` 遷移

這個 repo 不是從零開始，所以目前仍保留 Linux / macOS 的 Python CLI，並把既有系統導入分成兩層：

- `adoption gate`
  - `preflight`
  - `adopt`
  - `doctor`
- `legacy compatibility`
  - `migrate`
  - `reconcile`
  - `legacy-import`

它們的角色不是新系統的主入口，而是處理：

- existing machine adoption
- blocking preflight
- bootstrap 補齊
- 舊版 `settingZsh:*` markers
- managed fragments 修復
- interactive shell 診斷
- legacy import draft

也就是說，`chezmoi` 現在負責 new baseline，而 adoption gate 負責把既有機器安全帶過來。

### 4. Capability parity 與測試

本專案不是單純把安裝器換皮，而是以「不退化」為硬限制遷移。

因此 repo 內額外維持：

- capability parity 設計文件
- shell baseline 靜態檢查
- scripts presence 測試
- Linux fallback 測試
- Windows profile parity 測試
- docs 靜態測試

這些測試的目的，是避免在重構到 `chezmoi` 後，只剩下表面上的 dotfiles 同步，卻丟失原本已經能交付的結果。

## 為什麼不直接把所有事情都交給 `chezmoi`

因為問題不只是一份 dotfiles repo。

這個專案還需要處理：

- 字型與工具安裝
- 平台差異
- editor 是否安裝的控制
- 與既有環境共存
- 從舊版 `settingZsh` 遷移

`chezmoi` 很適合當主控制面，但若完全不補專案邏輯，現有能力會退化。現在的設計是在「盡量用標準工具」與「不犧牲現有結果」之間取平衡。

## 目前的邊界與非目標

這個 repo 刻意不做以下事情：

- 不自動拉取 secret repo
- 不同步 `known_hosts`
- 不讓 private repo 變成第二套完整 dotfiles 系統
- 不再回到整份 `.zshrc` merge 模型
- 不把 runtime secret 注入納入這一輪 adoption guardrails

## SSH 路徑模型與 `SOPS + age`

private SSH repo 的正式路徑模型分成兩種：

- `standard path`
  - `~/.ssh/<key>`
- `custom managed path`
  - 例如 `~/.ssh/config/sympasoft-macmini-ssh/<key>`

`SOPS + age` 的責任是管理 private repo 的密文與 recipients，不處理 runtime secret 注入。建議至少保留兩組 recipients：

- `owner`
- `recovery`

詳細操作（`.sops.yaml`、`updatekeys`、`rotate`）請看 [sops-age.md](/Users/arlen/Documents/syncthing/backup/server/Code/settingZsh/.worktrees/settingzsh-chezmoi/docs/secrets/sops-age.md)。

這些限制不是缺點，而是用來降低維護面與避免責任失控的 guardrails。

## 建議怎麼讀這個 repo

如果你是第一次接手，建議順序是：

1. `README.md`
2. `docs/architecture.md`
3. `docs/editor-guide.md`
4. `docs/plans/2026-03-15-settingzsh-capability-parity.md`
5. `docs/plans/2026-03-15-settingzsh-chezmoi-migration-design.md`

這樣會先理解使用方式，再理解架構，再理解遷移時的能力約束。
