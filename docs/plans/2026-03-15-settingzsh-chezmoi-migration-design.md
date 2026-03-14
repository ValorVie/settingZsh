# settingZsh 遷移到 chezmoi 的設計

**日期：** 2026-03-15  
**狀態：** 已確認  
**作者：** Codex

## 背景

`settingZsh` 目前已能在 macOS、Linux、Windows 提供跨平台 shell / profile、字型、開發工具與 editor 選配安裝，但主要控制面仍是自訂 shell / Python CLI 與平台腳本。

使用者希望改以 `chezmoi` 作為主要配置與部署系統，同時滿足以下條件：

- 保留現有專案已能交付的結果，不接受功能退化
- 支援 macOS / Linux / Windows 三平台
- 支援 `.ssh/config`
- 將 SSH keys 與私有 SSH host 設定分離到 private repo
- 接受第一次 private overlay 由使用者手動完成 Git 驗證後再部署

## 目標

- 以 `chezmoi` 取代目前自訂 dotfiles / setup orchestration 的主要角色
- 保留現有產品能力的結果等價，而非保留原實作
- 建立 `public baseline + private SSH overlay` 的清楚責任邊界
- 讓 public baseline 在沒有 private overlay 的情況下仍可獨立工作
- 讓 Linux server 的 private overlay 第二階段部署不依賴 GUI

## 非目標

- 不把 private repo 擴張成第二套完整 dotfiles 系統
- 不同步 `known_hosts`
- 不要求第一次新機部署無條件一鍵完成 private key 佈署
- 不保留既有 Python CLI / merge engine 作為必須存在的組件

## 設計原則

1. **結果等價，不是實作等價**
   - 可以淘汰 Python CLI
   - 不可以失去現有使用者可見能力

2. **單一主入口**
   - `public repo` 是唯一主入口與主要 source of truth
   - `private repo` 只是 SSH overlay feed，不是第二個主系統

3. **兩階段部署**
   - Phase A：public baseline
   - Phase B：manual auth 後的 private SSH overlay

4. **明確 capability parity**
   - 所有遷移工作都以 capability parity matrix 為驗收基準

## 考慮過的方向

### 方案 A：chezmoi 為主，private SSH overlay 分離（推薦）

做法：

- `chezmoi` 成為主要 dotfiles / scripts / templates 控制面
- public repo 管 baseline
- private repo 只處理 `~/.ssh/**`

優點：

- 最符合使用者的 public + private 分離需求
- 符合 chezmoi 單一主入口模型
- 避免 private repo 長成第二套系統

缺點：

- 需要把「不退化」具體寫成 matrix
- private overlay 不是無條件一鍵部署

### 方案 B：完整 private repo 包住 public baseline

做法：

- public repo 保留共用內容
- private repo 變成個人/工作主入口

優點：

- 個人機器可高度還原
- private 設定空間大

缺點：

- 容易形成雙 source of truth
- 對目前只有 SSH 私密需求而言是過度設計

### 方案 C：維持現有架構，只補 `chezmoi` 作為外層包裝

做法：

- 保留 Python CLI / shell merge 流程
- 額外再加 `chezmoi`

優點：

- 短期改動較少

缺點：

- 兩套控制面並存
- 無法真正降低維護負擔

## 最終決策

採用 **方案 A：chezmoi 為主，private SSH overlay 分離**。

## 核心架構

### 1. Repo 邊界

#### Public 主 repo

角色：

- 唯一主入口
- 唯一 baseline source of truth

責任：

- shell / profile / git / nvim / 通用 dotfiles
- 平台安裝 scripts
- `.ssh/config` 主檔與共用 `config.d`
- feature flags 與 machine data

限制：

- 不放 secrets
- 不放 private SSH keys
- 不放公司或個人私有 host 細節

#### Private SSH overlay repo

角色：

- 受控 SSH overlay feed

責任：

- `~/.ssh/id_*`
- `~/.ssh/config.d/90-private.conf`
- SSH certificates 或其他僅限 SSH 的敏感內容

限制：

- 只允許對應 `~/.ssh/**`
- 不允許放 shell / git / nvim / 一般 dotfiles
- 不接管 `~/.ssh/config` 主檔

### 2. 目錄模型

建議的 public repo 結構：

```text
.
├── .chezmoi.toml.tmpl
├── .chezmoidata/
│   ├── common.yaml
│   ├── macos.yaml
│   ├── linux.yaml
│   └── windows.yaml
├── home/
│   ├── dot_zshrc.tmpl
│   ├── private_dot_ssh/
│   │   ├── config.tmpl
│   │   └── config.d/
│   │       └── 10-common.conf.tmpl
│   ├── dot_config/
│   │   ├── powershell/
│   │   ├── git/
│   │   └── nvim/
│   └── ...
└── run_*.tmpl
```

建議的 private repo 結構：

```text
.
└── home/
    └── private_dot_ssh/
        ├── id_ed25519
        ├── id_ed25519.pub
        └── config.d/
            └── 90-private.conf.tmpl
```

## 部署流程

### Phase A：Public baseline

入口：

```bash
chezmoi init --apply <public-repo>
```

Phase A 負責：

- 落地 shell / profile / git / nvim / `.ssh/config`
- 建立 `~/.ssh/config.d/`
- 依平台與 feature flags 執行 `run_once_` / `run_onchange_` scripts
- 安裝通用工具與字型

### Phase B：Private SSH overlay

前提：

- 使用者已手動完成 Git 驗證

Phase B 負責：

- 將 private SSH overlay 帶入本機
- 落地 SSH keys
- 落地 `~/.ssh/config.d/90-private.conf`

### Phase B 的 guardrails

- 不假裝 Phase A 就能無條件完成 private key 佈署
- 不讓 private overlay 接管 `.ssh/config` 主檔
- 若 private overlay 缺席，public baseline 仍然正常

## `.ssh` 模型

### `~/.ssh/config`

永遠由 public baseline 管理，內容只負責：

- `Host *` defaults
- `Include ~/.ssh/config.d/*.conf`
- 三平台相容骨架

### `~/.ssh/config.d/10-common.conf`

由 public baseline 提供，放安全的共用設定。

### `~/.ssh/config.d/90-private.conf`

由 private overlay 提供，放私有 host / bastion / `IdentityFile`。

### `known_hosts`

預設不同步；若後續需要，再另行設計。

## Capability Parity Matrix

所有遷移工作必須先建立正式 matrix。每列至少包含：

- `現有能力`
- `目前來源檔案`
- `新 chezmoi 機制`
- `是否必保留`
- `驗證方式`

### 必保留能力

#### Shell / Profile

- macOS / Linux Zsh baseline
- Zinit 與現有預設插件集合
- `fzf`
- `zoxide`
- Windows PowerShell profile
- Windows PowerShell 5.1 / 7+ 路徑分流
- `.ssh/config` 主檔

#### 平台安裝

- macOS 字型安裝到 `~/Library/Fonts`
- Linux 字型安裝與 `fc-cache`
- Linux 無 sudo fallback
- Windows 字型安裝到 user fonts + registry
- Windows PowerShell modules：`Terminal-Icons`、`ZLocation`、`PSFzf`
- Windows `fzf` / `Starship`

#### Editor Feature

- 預設不安裝 editor
- 可明確啟用 editor feature
- 保留 feature state
- update / apply 不應默默擴大安裝範圍
- 部署 nvim 前備份既有設定

#### SSH / Overlay

- public baseline 單獨可用
- private overlay 缺席不影響 baseline
- Linux server 第二階段部署不依賴 GUI
- 三平台可解析 `config + config.d` 模型

## 不可接受退化清單

以下列為 `MUST NOT REGRESS`：

- Linux 無 sudo fallback
- Windows PowerShell modules
- Windows PowerShell 5.1 / 7+ profile 路徑分流
- Maple Mono 自動安裝能力
- editor 預設不安裝與 feature gating
- Zinit 與現有預設插件集合
- `.ssh/config` 的 public/private 分層
- private overlay 缺席時 public baseline 可獨立工作

## 驗證策略

### 1. Static

- repo 內模板、scripts、平台資料存在
- platform-specific branches 與 feature branches 齊全

### 2. Smoke

- `chezmoi apply --dry-run`
- shell / profile 語法驗證
- `ssh -G <host>` 可解析 config

### 3. Outcome

- 新機部署後結果與 README 承諾一致
- 第二次執行維持 idempotency
- private overlay 存在 / 缺席兩種情境都成立

## 遷移路徑

1. 先建立 `capability parity matrix`
2. 再建立 public baseline 的 chezmoi source state
3. 再建立 private SSH overlay feed
4. 最後才淘汰舊的 shell / Python CLI 主流程

## 開放問題

- private overlay 最終是以 `external` + install step，或其他更嚴格的輸入方式落地
- feature state 最終放在 `.chezmoidata`、機器本地 config，或獨立 state 檔
- 舊版 `settingZsh` 使用者的遷移提示與 rollback 文案
