# settingZsh 架構大收斂設計

**日期：** 2026-04-05  
**狀態：** Proposed  
**範圍：** `codex/settingzsh-chezmoi` branch 的整體架構重整  
**優先路徑：** `fresh install` 優先，`existing machine` 採較嚴格但可預期的導入策略

## 1. 目的

本設計要一次解決目前 branch 的四個核心問題：

1. 控制面分裂：`chezmoi` 與 `legacy CLI` 都能直接寫 baseline
2. shell baseline 沒有單一真相來源：`home/` 與 `templates/` 各自維護
3. 設定模型分裂：`.chezmoi.toml.tmpl` 與 `.chezmoidata/` 命名不一致、接線不完整
4. 平台抽象不足：腳本只做到 OS，未完整涵蓋 architecture，且 Linux fallback 直接硬編碼 `x86_64`

本次規劃採「大收斂」策略，不做保守維持現狀的相容層堆疊，而是直接把專案收斂到單一、可持續演進的形狀。

## 2. 已觀察到的結構問題

### 2.1 控制面分裂

- 文件已將 `chezmoi` 定義為新的主要控制面，`public baseline` 是唯一主入口
- 但 `lib/settingzsh/cli.py` 目前仍可透過 `setup`、`update`、`reconcile`、`migrate` 直接寫入 `~/.zshrc`、`init.zsh`、`managed.d/*`

影響：

- 正式寫檔路徑不只一條
- 文件敘事與實作不一致
- 任何 baseline 調整都需要雙倍驗證

### 2.2 Shell baseline 沒有單一真相來源

- `chezmoi` 路徑使用 `home/dot_config/settingzsh/managed.d/*.tmpl`
- Python CLI 路徑使用 `lib/settingzsh/shellgen.py` 指向的 `templates/*.zsh`
- 兩邊內容已經漂移，並非單純註解差異

影響：

- `fresh install` 與 `legacy reconcile` 可能生成不同 shell
- 後續每次改 shell 行為都可能再次分叉

### 2.3 設定模型分裂

- `home/.chezmoi.toml.tmpl` 定義 top-level flags：`feature_editor`、`install_fonts`、`private_ssh_overlay`
- `home/.chezmoidata/` 又定義另一套 nested schema，例如 `features.editor`、`paths.font_dir`
- 腳本多半直接讀 top-level flag 或硬編碼路徑，未真正以 `.chezmoidata/` 作為執行時真相來源

影響：

- 命名與概念重複
- schema 難以信任
- 後續加 feature 時容易在多處改名或漏改

### 2.4 平台抽象不足

- 專案目標是跨平台，但 Linux editor fallback 仍直接硬編碼 `x86_64` artifact
- 測試也偏向檢查 URL 字串，而不是驗證「給定 `os + arch` 是否選到正確 artifact」

影響：

- `arm64`、未來其他 architecture 的維護成本偏高
- 平台支援是散落在腳本中的 if/else，而非可驗證的資料模型

## 3. 設計目標

### 3.1 核心目標

1. 讓 `chezmoi` 成為唯一 baseline 寫入引擎
2. 讓 `home/` 成為唯一 baseline source of truth
3. 讓 `lib/settingzsh` 只保留 guardrails 與遷移協助責任
4. 讓 `.chezmoidata/` 成為唯一結構化設定 schema
5. 讓平台抽象至少涵蓋 `os + arch + package_manager`
6. 讓 `fresh install` 成為最乾淨、最可靠、最完整支援的主流程

### 3.2 次要目標

1. 讓文件敘事與實作一致
2. 讓測試依職責分層，而不是以散落字串檢查拼接
3. 降低後續新增功能時的結構性風險

## 4. 非目標

本次收斂不包含：

1. 新增新的 shell 功能集合
2. 擴張 private overlay 邊界到 `~/.ssh/**` 之外
3. 重新設計 editor 功能本身的內容
4. 引入第二套新的部署框架取代 `chezmoi`

## 5. 最終目標架構

### 5.1 單核心模型

收斂後只保留一條正式寫檔路徑：

- `chezmoi`：唯一將 baseline 寫入目標家目錄的引擎
- `home/`：唯一 baseline 來源目錄
- `lib/settingzsh`：只做分析、診斷、報告、備份與遷移協助

### 5.2 目標目錄模型

```text
repo root
├── .chezmoiroot -> home
├── home/                         # 唯一 baseline source
│   ├── .chezmoi.toml.tmpl        # 使用者可覆寫預設值入口
│   ├── .chezmoidata/             # 唯一結構化 schema
│   ├── modify_dot_zshrc
│   ├── dot_config/settingzsh/
│   ├── private_dot_ssh/
│   ├── Documents/
│   ├── run_once_before_*
│   └── run_onchange_after_*
├── lib/settingzsh/               # guardrails only
│   ├── preflight
│   ├── adopt
│   ├── doctor
│   └── legacy_import
└── docs/
```

### 5.3 `legacy CLI` 新角色

保留：

- `preflight`
- `adopt`
- `doctor`
- `legacy-import`

退出主產品或降為 shim：

- `setup`
- `update`
- `reconcile`
- `migrate`

原則：

- `legacy CLI` 不再擁有 baseline 文本模板
- `legacy CLI` 不再直接寫 `~/.zshrc`、`init.zsh`、`managed.d/*`
- 若仍保留相容命令，其作用只能是引導到 `chezmoi` 或輸出明確提示，不再自行生成內容

## 6. 元件責任切分

### 6.1 `home/`

責任：

- 所有要部署到家目錄的 shell/profile/SSH baseline 內容
- 所有 `run_*` 安裝與同步腳本
- 所有 baseline 相關模板與來源檔

禁止：

- 只存在於 legacy CLI 的平行模板

### 6.2 `.chezmoidata/`

責任：

- 定義唯一結構化 schema
- 定義平台預設、功能開關預設、路徑模型、artifact map、overlay 參數

禁止：

- 僅作文件展示、沒有實際消費點的欄位

### 6.3 `.chezmoi.toml.tmpl`

責任：

- 提供使用者可覆寫欄位的預設值
- 作為 `chezmoi` data 的 entry point

禁止：

- 與 `.chezmoidata/` 平行維護第二套命名系統

### 6.4 `lib/settingzsh/`

責任：

- 分析現況 shell
- 產生 adopt report
- 診斷 baseline 落地後的異常
- 協助盤點 legacy 結構

禁止：

- 生成 baseline 文本
- 寫入 baseline managed fragments

### 6.5 `templates/`

處置：

- 退出正式來源鏈
- 優先刪除
- 若短期仍保留，僅能作為過渡期 fixture 或由 canonical source 自動產出，不允許手動維護

## 7. 收斂後的設定模型

### 7.1 Canonical schema

```yaml
features:
  editor: false
  fonts: true
  private_ssh_overlay: false

platform:
  os: linux|macos|windows
  arch: x86_64|arm64
  package_manager: apt|brew|winget|none

paths:
  zinit_home: string
  font_dir: string
  nvim_dir: string
  powershell_profile_v5: string
  powershell_profile_v7: string

artifacts:
  ripgrep:
    linux:
      x86_64: url
      arm64: url
  fd:
    linux:
      x86_64: url
      arm64: url
  neovim:
    linux:
      x86_64: url
      arm64: url
  lazygit:
    linux:
      x86_64: url
      arm64: url

overlay:
  repo: string
  profile: auto|string
```

### 7.2 命名規則

- 不再使用 `feature_editor` / `install_fonts` / `private_ssh_overlay` 這種 top-level 與 nested 並存的命名
- 對外概念統一收斂為：
  - `features.editor`
  - `features.fonts`
  - `features.private_ssh_overlay`
  - `overlay.repo`
  - `overlay.profile`

### 7.3 覆寫規則

- `.chezmoidata/` 定義 canonical schema 與平台預設
- `chezmoi.toml` 只可覆寫 schema 內已存在欄位
- 所有模板與腳本只讀這套 schema

## 8. 平台抽象與 artifact 選擇

### 8.1 抽象層級

平台判斷必須至少產出：

- `os`
- `arch`
- `package_manager`

### 8.2 Artifact map

所有 fallback binary 都必須改由資料表選擇，不可在腳本內直接硬編碼：

- ripgrep
- fd
- neovim
- lazygit

### 8.3 測試原則

- 驗證 `os + arch` 對應結果
- 不再以「URL 是否包含某個字串」當成需求本身

## 9. 使用者流程

### 9.1 Fresh install

正式主流程：

1. `chezmoi init --apply`
2. `run_once_before_*`
3. `run_onchange_after_*`
4. 重新開啟 shell

這條路徑應成為：

- 文件首要敘事
- 測試首要驗證路徑
- 架構設計的第一優先

### 9.2 Existing machine onboarding

正式導入路徑：

1. `chezmoi init`
2. `preflight`
3. 若非 `safe`，產出 `adopt report`
4. 使用者決定是否繼續 `chezmoi apply`

原則：

- `existing machine` 不再追求完全自動修復
- 目標是提供可理解、可預測的 guardrail
- 若現況 shell 很重或已破損，允許流程更保守、更手動

### 9.3 Baseline update

正式更新路徑：

1. `chezmoi update`
2. 必要時 `doctor`

不再使用：

- `legacy CLI setup`
- `legacy CLI update`

## 10. 腳本與執行邊界

### 10.1 `run_once_before_*`

只做：

- 安裝前置資產與工具
- 建立必要目錄
- 安裝 baseline runtime 前置條件

### 10.2 `run_onchange_after_*`

只做：

- 在內容變更後同步外部資產
- 依 feature flag 進行受控的第二階段操作

### 10.3 Private SSH overlay

保留目前邊界：

- `custom private repo` 只負責 `~/.ssh/**`
- 不接管 `~/.ssh/config` 主檔
- 仍作為受控第二階段 overlay feed，不升格為第二套主系統

## 11. 測試策略

收斂後測試改為四層。

### 11.1 Schema tests

驗證：

- `.chezmoidata/` 欄位完整性
- 所有必要 artifact 對應完整
- 所有 schema 欄位都有明確消費點

### 11.2 Render tests

驗證：

- 在不同 `os + arch + feature flags` 下，`chezmoi` 產物正確
- shell/profile/SSH baseline 渲染符合預期

### 11.3 Behavior tests

驗證：

- `fresh install` smoke
- `update` smoke
- private overlay smoke
- editor feature opt-in 行為

### 11.4 Guardrail tests

驗證：

- `preflight`
- `adopt`
- `doctor`
- `legacy-import`

### 11.5 測試淘汰原則

淘汰：

- 驗證 legacy CLI 直接寫 baseline 的測試
- 將硬編碼 artifact 字串視為需求的測試

## 12. 遷移策略

本次採大收斂，不走長期雙軌。

### Phase 1: 定義 canonical source 與 schema

1. 定義 `home/` 為唯一 baseline source
2. 定義 `.chezmoidata/` 為唯一 schema
3. 建立使用者覆寫到 canonical schema 的映射

### Phase 2: 移除 Python baseline rendering

1. 拆除 `shellgen.py` 對 `templates/` 的依賴
2. 移除 `lib/settingzsh` 內所有 baseline 生成責任
3. 刪除或封存 `templates/`

### Phase 3: 收縮 legacy CLI

1. `setup/update/reconcile/migrate` 退出主產品
2. `preflight/adopt/doctor/legacy-import` 保留
3. 更新文件，讓文件敘事與實作一致

### Phase 4: 平台抽象與 artifact map

1. 將所有 fallback URL 資料化
2. 補齊 `arm64` 路徑
3. 重寫相關測試

### Phase 5: 完成文件與驗收

1. 更新 README、architecture、inventory、adoption guide
2. 重新整理測試分層
3. 完成最終 smoke 與 guardrail 驗證

## 13. 風險與處理

### 13.1 風險：既有使用者仍依賴 legacy CLI

處理：

- 透過文件與 shim 提前提示
- 將 `fresh install` 與 `update` 全面收斂到 `chezmoi`

### 13.2 風險：資料 schema 收斂時出現命名轉換成本

處理：

- 明確列出舊欄位到新 schema 的映射
- 在過渡期提供單向兼容，不保留永久雙命名

### 13.3 風險：existing machine 相容性下降

處理：

- 明確接受這是大收斂的代價
- 用 `preflight` + `adopt report` 替代過度自動化修復

## 14. 驗收標準

完成此設計後，系統必須滿足：

1. baseline 寫入只有 `chezmoi` 一條正式路徑
2. shell/profile baseline 只有一份 canonical source
3. `.chezmoidata/` 的每個欄位都有明確消費點
4. Linux fallback 可依 `x86_64` / `arm64` 正確選 artifact
5. README 與 architecture 文件不再宣稱不存在的相容模型
6. `fresh install` smoke 與 `baseline update` smoke 可穩定驗證
7. `legacy CLI` 測試只剩 guardrail 類型，不再驗 baseline 寫檔

## 15. 最終決策摘要

本次規劃採以下最終決策：

1. `chezmoi` 是唯一 baseline 寫入引擎
2. `home/` 是唯一 baseline source of truth
3. `lib/settingzsh` 只做 guardrails，不再直接寫 baseline
4. `.chezmoidata/` 是唯一 schema
5. 平台抽象提升到 `os + arch + package_manager`
6. `fresh install` 是第一優先路徑
7. `existing machine` 採較嚴格但更誠實的導入策略
