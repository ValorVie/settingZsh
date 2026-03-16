# settingZsh 終態架構與 SSH Secret Repo 設計

**日期：** 2026-03-16  
**狀態：** 已確認  
**作者：** Codex

## 背景

`settingZsh` 已經完成 `chezmoi` 化的 public baseline，並具備：

- `~/.zshrc` bootstrap ownership
- `preflight` / `adopt` / `doctor` / `legacy-import` guardrails
- macOS / Linux / Windows 的 profile baseline
- `.ssh/config` 主檔與 `config.d` 公開骨架

但整體架構仍缺最後一塊：把「既有系統導入」、「SSH private overlay」、「private repo 額外加密」收斂成一個完整且長期可維護的終態。

目前的 `valor-ssh` 實際範例也暴露了幾個結構性問題：

- 單一 `90-private.conf` 同時混入 Macmini 與 ValorPC 規則
- 同時混入 macOS 專屬 `UseKeychain yes` 與 Windows 路徑寫法
- 標準 `~/.ssh` 路徑與自訂路徑沒有清楚分層
- `IdentityFile` 與 `ForwardAgent` 使用策略不一致

因此本設計直接規劃到最終目標，不再拆 P0-P2。

## 目標

- 讓 `settingZsh` 成為跨平台 public baseline 與 adoption control plane
- 讓既有系統導入具備正式的 blocking guardrails
- 讓 SSH private material 有獨立且清楚的 private repo 邊界
- 讓 private repo 使用 `SOPS + age` 做檔案級加密與 recipient 管理
- 讓標準 key 路徑與自訂 key 路徑都有正式模型
- 讓 `valor-ssh` 從單一大檔演進為可維護、可輪替、可跨平台分流的結構

## 非目標

- 不把 `settingZsh` 擴張成通用 `.zshrc` 維護工具
- 不在本輪處理 runtime secret 注入
- 不讓 public repo 接管 SSH 私鑰
- 不讓 private repo 開始承載一般 shell / editor / git dotfiles
- 不同步 `known_hosts`

## 最終責任切分

### 1. Public repo：唯一主入口

`settingZsh` public repo 是唯一的主要控制面與 source of truth，負責：

- `~/.zshrc` bootstrap ownership
- `~/.config/settingzsh/managed.d/*.zsh`
- Windows PowerShell baseline
- `.ssh/config` 主檔
- `.ssh/config.d/10-common.conf`
- `chezmoi run_*` 安裝腳本
- adoption guardrails

它不負責：

- SSH 私鑰
- 私有 bastion / host 規則
- `known_hosts`
- 任何 runtime secret

### 2. Custom private repo：只負責 `~/.ssh/**`

private repo 只應該管理：

- `~/.ssh/config.d/*.conf`
- private keys
- `.pem`、certificates
- 其他明確屬於 SSH 的私有檔案

它不應該管理：

- `~/.ssh/config` 主檔
- shell 設定
- git 設定
- editor 設定
- 非 SSH 類 secrets

### 3. SOPS + age：只負責 private repo 檔案加密

`SOPS + age` 的責任是：

- 保護 private repo 內的檔案內容
- 管理 recipients
- 支援 rotation 與 recovery

它不負責：

- shell runtime secret 注入
- 取代 `chezmoi`
- 管理 public baseline

## 既有系統導入模型

### 核心原則

- new machine 與 existing machine 是兩條不同流程
- 既有機器不能直接套 `chezmoi init --apply`
- 任何 live shell 變更前都要先經過 adoption gate

### 最終流程

#### Fresh install

- 若 `~/.zshrc` 不存在，建立最小 bootstrap
- 直接套用 public baseline

#### Existing machine

1. `chezmoi init <public-repo>`
2. `preflight`
3. 若結果是 `safe`，才允許 bootstrap create / modify
4. 若結果是 `needs_adopt`，產生 adopt report 與 backup
5. 若結果是 `broken_existing_shell`，停止並要求先處理現況

### Guardrails

- `preflight`：判定能否安全導入
- `adopt`：只做報告與備份，不重寫 live shell
- `doctor`：檢查 interactive shell 狀態
- `legacy-import`：只作為 opt-in 草稿工具

## SSH Private Repo 結構

private repo 的正式結構定義如下：

```text
valor-ssh/
├── .sops.yaml
├── README.md
├── shared/
│   └── config.d/
│       └── 10-common-private.conf
├── shared-keys/
│   └── keys/
│       └── README.md
├── macmini/
│   ├── config.d/
│   │   └── 90-private.conf
│   ├── keys/
│   │   ├── id_ed25519
│   │   ├── google_compute_engine
│   │   └── vm-1-test
│   └── custom-paths/
│       └── sympasoft-macmini-ssh/
│           ├── google_compute_engine
│           └── vm-1-test
└── valorpc/
    ├── config.d/
    │   └── 90-private.conf
    ├── keys/
    │   ├── ssh-key-2021-10-20.key
    │   ├── pi4_valorpc
    │   ├── LightsailDefaultKey-us-west-2.pem
    │   └── id_rsa
    └── custom-paths/
        └── windows-imported/
            └── google_compute_engine
```

### 結構規則

- `shared/config.d/`
  - 放共用 private host 規則
  - 不放 private key
- `shared-keys/keys/`
  - 顯式保留給例外的 shared private keys
  - 預設應維持空白或只有 README
- `<machine>/config.d/`
  - 只放該機器自己的 private host 規則
- `<machine>/keys/`
  - 預設部署到 `~/.ssh/`
- `<machine>/custom-paths/`
  - 部署到自訂路徑

## 路徑模型

### 1. Standard path

預設 key 路徑：

- `~/.ssh/id_ed25519`
- `~/.ssh/google_compute_engine`
- `~/.ssh/LightsailDefaultKey-us-west-2.pem`

這是三平台共同的正式模型。

### 2. Custom managed path

對於確實需要放在其他位置的 key，使用明確的 custom-paths 模型，例如：

- `~/.ssh/config/sympasoft-macmini-ssh/google_compute_engine`
- `~/.config/valor-ssh/keys/google_compute_engine`

這類 key 仍由 private repo 管理，但不應與 standard path 混為一談。

### 3. External unmanaged path

若 key 由其他工具產生或交付，private repo 可以只引用，不負責部署。這是文件化例外，不列入主流程。

## `90-private.conf` 的終態規則

### 1. 不再混機器

目前單一檔案同時混了 Macmini 與 ValorPC 規則。終態必須拆成：

- `macmini/config.d/90-private.conf`
- `valorpc/config.d/90-private.conf`

### 2. 不再混平台專屬語義

- `UseKeychain yes` 只留在 macOS 專屬檔案
- 若某份檔案可能被非 macOS client 讀到，先加 `IgnoreUnknown UseKeychain`
- Windows / 跨平台路徑寫法要統一，不混用 `~/.ssh/...` 與 `~\\.ssh\\...`

### 3. `IdentityFile` 的使用規則

只要 host 明確綁定特定 key，預設一起加：

- `IdentityFile ...`
- `IdentitiesOnly yes`

### 4. `ForwardAgent` 的使用規則

`ForwardAgent yes` 只留在真的要做 hop / jump 的 host。不可當廣泛預設。

## SOPS + age 設計

### 核心原理

- 每個 secret 檔案用自己的資料金鑰加密
- `SOPS` 負責管理檔案、規則與 metadata
- `age` 負責保護那把資料金鑰該分給哪些 recipients

### Recipient 模型

第一版固定兩組 recipient：

- `owner`
- `recovery`

不預設做 per-machine recipient matrix。需要 machine self-decrypt 時再擴充。

### `.sops.yaml`

```yaml
creation_rules:
  - path_regex: ^shared/.*$
    age:
      - age1-owner-public-key
      - age1-recovery-public-key

  - path_regex: ^shared-keys/.*$
    age:
      - age1-owner-public-key
      - age1-recovery-public-key

  - path_regex: ^macmini/.*$
    age:
      - age1-owner-public-key
      - age1-recovery-public-key

  - path_regex: ^valorpc/.*$
    age:
      - age1-owner-public-key
      - age1-recovery-public-key
```

### Key 管理原則

- 使用 dedicated age identity，不重用 SSH key
- repo 只放 recipient 公鑰，不放 age private key
- 額外保留一把離線 recovery key
- private repo 只存密文，不存明文私鑰

## 實際操作模型

### Authoring

- 在可信任工作機上用 `sops` 編輯 SSH private files
- 編輯完成後提交密文到 private repo

### Materialization

- 只解密目標機器需要的 subtree
- 落地到 `~/.ssh/` 或 custom path

### Hardening

- 落地後立即設定權限
- 使用 `ssh -G <host>` 檢查最終 config
- 再進行實際連線 smoke test

### Rotation 與 Recovery

- recipient 新增或變更：`sops updatekeys`
- 懷疑資料金鑰或 recipient 洩漏：`sops rotate`
- 主工作機遺失時，使用 recovery key 解密並重建 recipients

## 需要重構的現有 `valor-ssh` 問題

以目前實際 `90-private.conf` 來看，至少需要修正：

- 拆分 Macmini 與 ValorPC 規則
- 將 `UseKeychain yes` 限縮到 macOS 檔案
- 將 Windows 式 `~\\.ssh\\...` 路徑收斂成統一模型
- 對有 `IdentityFile` 的 host 補齊 `IdentitiesOnly yes`
- 收斂 `ForwardAgent yes` 的使用範圍
- 將 custom path host 改由 `custom-paths/` 類型管理

## 最終建議

`settingZsh` 的終態不是更大的 shell 維護器，而是以下四個元件的穩定組合：

1. `chezmoi public baseline`
2. `adoption guardrails`
3. `custom private SSH repo`
4. `SOPS + age`

只要這四層邊界清楚：

- 新機器可直接部署
- 舊機器不會被誤傷
- SSH secrets 可安全版控
- 路徑與平台差異可長期維護
