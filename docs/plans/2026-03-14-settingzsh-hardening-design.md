# settingZsh 部署、設定與邊界防護設計

**日期：** 2026-03-14
**狀態：** 已確認
**作者：** Codex

## 背景

`settingZsh` 已完成 bootstrap 化重構：Linux / macOS 的主要 shell 流程已改為最小 `~/.zshrc` bootstrap、`~/.config/settingzsh/init.zsh`、`managed.d/*.zsh`、以及 `doctor` / `migrate` / `reconcile` 指令。

這個方向已經把工具責任從「維護整份 `.zshrc`」收斂為「維護本工具自己的 shell 資產」，但目前仍缺少三塊能力：

- 多台機器重複部署所需的 non-interactive 與 state / cache 管理
- repo 預設與本機覆蓋之間的正式設定層
- 對多工具共存與邊界情況的更完整偵測與顯式修復模式

使用者要求是混合場景，但以「多台機器可重複部署」優先，同時保留單機安全性與最小干預。

## 目標

- 讓 `setup` / `update` 可在互動式與 non-interactive 場景穩定重跑
- 引入 `repo default + machine local override` 的設定模型
- 明確區分 `managed.d` 與 `local.d` 的責任邊界
- 將 `doctor` 提升為有效的 preflight / drift 偵測工具
- 維持 `reconcile` 的保守特性，只補齊本工具資產
- 引入顯式 `repair` 模式處理較侵入的修復

## 非目標

- 不把 `settingZsh` 變成通用 `.zshrc` 管理工具
- 不自動重寫或整理 bun / gcloud / OpenSpec / Spectra / Obsidian 等第三方區塊
- 不把 Windows PowerShell 流程併入這次設計
- 不建立龐大的外部工具 adapter 生態系

## 考慮過的方向

### 方案 A：分層控制面（推薦）

以 repo baseline、machine override、runtime bootstrap、control commands 四層組成。

優點：

- 延續現有 bootstrap / `managed.d` / CLI 架構
- 最符合「多機可重複部署 + 單機安全」的雙重需求
- 可逐步導入，不需要推翻現有實作

缺點：

- 仍需要 `doctor` 判斷更多 drift 類型
- 需要清楚定義 local override 的邊界

### 方案 B：完全宣告式部署

所有 shell 資產都由一份完整 machine profile 宣告生成。

優點：

- 多機一致性最高
- 部署結果最可重現

缺點：

- 對真實世界中已被多工具修改的 `.zshrc` 過於剛性
- 容易超出 `settingZsh` 的責任邊界

### 方案 C：外部工具 adapter 模型

針對 bun / gcloud / OpenSpec 等建立 detector 與 repair adapter。

優點：

- 對複雜多工具共存最強

缺點：

- 成本過高
- 容易把本工具擴張成 shell ecosystem manager

## 最終決策

採用 **方案 A：分層控制面**。

核心理由：

- 現有程式已具備 bootstrap、`managed.d`、`doctor`、`migrate`、`reconcile`，向這個方向延伸成本最低
- 可以將多機部署能力、設定模型、邊界防護整合為單一架構
- 不需要重新接管整份 `.zshrc`

## 核心設計

### 1. 分層結構

#### Repo Baseline

受 repo 管理的穩定預設：

```text
config/
└── settings.default.toml

templates/
├── zshrc_base_mac.zsh
├── zshrc_base_linux.zsh
└── zshrc_editor.zsh
```

責任：

- 提供團隊共用 baseline
- 只放跨機器穩定設定
- 不放個人 PATH、SDK 路徑、第三方工具注入內容

#### Machine Override

每台機器自己的設定：

```text
~/.config/settingzsh/
├── settings.local.toml
└── local.d/
    ├── 50-bun.zsh
    ├── 60-gcloud.zsh
    └── 70-custom.zsh
```

責任：

- `settings.local.toml`：覆蓋值與 feature flags
- `local.d/*.zsh`：必須是 shell code 的機器專屬內容

約束：

- 可新增與覆蓋變數值
- 不可直接覆寫 repo managed fragment 的檔名與內容

#### Runtime Bootstrap

```text
~/.zshrc
└── settingZsh bootstrap

~/.config/settingzsh/
├── init.zsh
├── managed.d/
└── local.d/
```

載入順序固定為：

1. `managed.d/*.zsh`
2. `local.d/*.zsh`

bootstrap 只負責載入，不負責做配置決策。

#### Control Commands

- `doctor`
- `migrate`
- `reconcile`
- `repair`（新增）

## 設定模型

### `settings.default.toml`

建議先支援以下群組：

```toml
[install]
fonts = true

[shell]
enable_currentdir_hook = false
brew_shellenv_mode = "zprofile"
enable_compinit = true

[editor]
enable_nvm_lazy = true

[integrations]
gcloud = false
bun = false
```

### `settings.local.toml`

機器專屬覆蓋，例如：

```toml
[machine]
role = "personal-macbook"

[shell]
extra_path = ["$HOME/.bun/bin", "$HOME/google-cloud-sdk/bin"]

[integrations]
gcloud = true
bun = true
```

### 設定合併規則

- 純量：local 覆蓋 default
- 陣列：採追加與去重
- `managed.d` 檔名：不得由 local 覆寫
- shell code：只能進 `local.d`

## 部署方式優化

### 1. shell wrapper 保留薄包裝

shell 腳本繼續負責：

- OS 偵測
- 套件管理器安裝
- 呼叫 Python CLI

Python CLI 負責：

- preflight
- settings / state 讀取
- bootstrap / fragment 管理
- 驗證與 rollback

### 2. non-interactive 入口

建議加入：

- `--yes`
- `--with-editor`
- `--skip-fonts`
- `--doctor-first`
- `--reconcile-only`

### 3. state file

新增：

```text
~/.config/settingzsh/state.json
```

至少記錄：

- `installed_features`
- `platform`
- `last_setup_at`
- `last_reconcile_at`
- `installer_version`
- `managed_fragment_hashes`

### 4. artifact cache

新增下載物件快取與 metadata：

```text
~/.cache/settingzsh/
├── downloads/
└── artifacts.json
```

每個 artifact 記：

- `url`
- `version`
- `sha256`
- `cache_path`

目標是減少每次部署都直接依賴網路。

## 邊界情況防護

### 1. `doctor v2`

除了既有的 `legacy_markers`、`shell_validation_failed`，再補：

- `duplicate_compinit`
- `duplicate_brew_shellenv`
- `precmd_override`
- `path_order_conflict`
- `missing_managed_fragment`
- `legacy_markers_partial`
- `local_fragment_source_error`

### 2. `reconcile` 與 `repair` 分離

#### `reconcile`

- 只補齊 bootstrap、`init.zsh`、缺失的 managed fragments
- 保留既有 `managed.d` 內容
- 不改 local fragments
- 不碰未知 `.zshrc` 內容

#### `repair`

顯式啟用才可執行：

- 重新生成 managed fragments
- 清理或隔離 legacy markers
- 將破損或不相容片段移到 quarantine

### 3. `migrate` 補強殘缺舊標記

對不完整 `settingZsh:*` markers，不自動猜測修復；改為：

- 偵測
- 匯出到 quarantine / backup
- 回報需要人工確認

## 驗證策略

### 單元測試

- settings 合併
- `local.d` 載入順序
- `doctor v2` findings
- `repair` guardrails
- state file 讀寫
- artifact metadata

### Fixture 測試

建立 fixture 組合：

- 空 `.zshrc`
- 只有 bootstrap
- 舊版 markers
- 殘缺 markers
- 第三方 completions + PATH 修改
- `precmd` / `precmd_functions` 衝突

### Shell 驗證

- `zsh -n`
- `ZDOTDIR=<temp-home> zsh -i -c exit`

## 驗收標準

1. 多台機器可透過 non-interactive 入口穩定重跑
2. repo 預設與 machine override 的責任邊界明確
3. `local` 不可直接覆寫 managed baseline
4. `doctor` 能在常見 drift 狀態下給出具體警告
5. `reconcile` 預設保守，`repair` 預設不自動觸發
6. 本工具不會因自己的修復流程破壞第三方 shell 內容

## 取捨

- 這個設計刻意不追求「自動整理所有 shell 問題」
- 換來的是清楚邊界與較低誤傷風險
- 若未來真要管理第三方工具整合，應該是獨立子系統，而不是直接擴張 `reconcile`
