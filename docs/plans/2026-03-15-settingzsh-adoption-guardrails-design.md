# settingZsh 既有系統導入與 Guardrails 設計

**日期：** 2026-03-15  
**狀態：** 已確認  
**作者：** Codex

## 背景

`settingZsh` 目前已完成 `chezmoi` 化的 public baseline、平台安裝 scripts、PowerShell parity、SSH public/private 分層與對應文件。但現況仍有一個核心風險：

- 新機器安裝路徑已可用
- 既有機器，尤其是已有完整 `~/.zshrc` 生態的系統，仍缺少正式 adopt 流程與 blocking guardrails

實際驗證顯示，像現存 server 這類已有 OpenSpec completion、Powerlevel10k、Zinit、`compinit`、`precmd`、Linuxbrew、`nvm`、bun 與 secrets 的 `.zshrc`，若直接套用目前的 whole-file `dot_zshrc.tmpl`，風險很高。即使不直接覆蓋，若在既有 `.zshrc` 後再載入 `managed.d/*.zsh`，也可能造成初始化順序改變與雙重載入。

使用者要求這一輪先聚焦：

- `P0`：把 `.zshrc` ownership 改成 `create_ / modify_ bootstrap`
- `P0`：新增 `adopt existing shell` 與 blocking preflight
- `P1`：加 interactive shell doctor，不只看 `zsh -n`
- `P2`：再考慮把現有 `.zshrc` 自動拆到 `local.d/90-legacy-import.zsh`
- `P2`：撰寫 `keepassxc-cli`、`gopass` 安裝與使用指南

本輪明確排除 runtime secret 注入架構，避免把 shell adopt 與 secret runtime abstraction 混成同一題。

## 目標

- 將 `~/.zshrc` ownership 從 whole-file target 收斂為 bootstrap ownership
- 讓既有機器在真正修改檔案前先經過 blocking preflight
- 提供正式的 adopt 報告與備份流程，而不是直接套用 baseline
- 讓 doctor 能反映 interactive shell 行為，而不只檢查語法
- 將 legacy import 明確定義為 opt-in 的 P2 能力，而非預設導入路徑
- 補齊 desktop/server secret manager 指南，但不在本輪落地 runtime secret 機制

## 非目標

- 不在本輪自動重排陌生 `.zshrc` 的區塊順序
- 不在本輪自動拆分陌生 `.zshrc` 中的 PATH / prompt / completion / secret
- 不在本輪設計統一 secret provider abstraction
- 不在本輪擴張成通用 `.zshrc` 維護工具
- 不在本輪更動 Windows PowerShell adopt 行為

## 問題定義

### 現況問題 1：`.zshrc` ownership 過大

目前 `home/dot_zshrc.tmpl` 直接對應 `~/.zshrc` target。對 fresh install 這沒有問題，但對既有機器代表：

- `chezmoi apply` 的語義接近「讓 `.zshrc` 變成 bootstrap 檔」
- 缺少「只插入 bootstrap、不覆蓋整份」的正式策略

### 現況問題 2：缺少導入前阻擋機制

目前 repo 有：

- `doctor`
- `migrate`
- `reconcile`

但還沒有一層明確的 adoption gate 去回答：

- 這台機器能不能安全導入？
- 它是 fresh install 還是既有重型 shell？
- 若現況 shell 本身已有錯誤，是否應立刻停止？

### 現況問題 3：doctor 太偏語法檢查

目前 `doctor` 主要看：

- legacy markers
- `zsh -n`

但實際 shell 問題常出現在 interactive 啟動期，例如：

- plugin init 錯誤
- `precmd` / `precmd_functions` 衝突
- `compinit` 重複
- `setopt` / ZLE 僅互動模式才會觸發的錯誤

### 現況問題 4：legacy import 應延後且 opt-in

把整份舊 `.zshrc` 搬到 `local.d/90-legacy-import.zsh` 看似保留了內容，但會改變執行順序：

1. bootstrap
2. `managed.d/*.zsh`
3. `local.d/*.zsh`

這不等於保留原行為，尤其對已有 `compinit`、prompt init、hook、PATH 順序的 shell 來說風險高。因此這個能力應明確排在 P2，且第一版只能 draft，不應直接改 live shell。

## 考慮過的方向

### 方案 A：保守導入，guardrails 優先（推薦）

做法：

- `.zshrc` 改成 bootstrap ownership
- 先做 blocking preflight
- 先產出 adopt report 與備份
- doctor 升級成 interactive-aware
- legacy import 延到 P2，且預設只產生 draft

優點：

- 最符合「不要造成麻煩」與既有機器安全導入
- P0 就能顯著降低誤傷風險
- 讓 P1 / P2 的責任邊界清楚

缺點：

- 使用者在 P0 後仍需人工判斷 adopt 報告
- 不提供快速半自動遷移

### 方案 B：平衡導入，提早提供 legacy import draft

做法：

- P0 同方案 A
- P1 同時加入 legacy import draft

優點：

- 既有機器較快有承接工具

缺點：

- 在 doctor 尚未成熟前就開始移動舊內容，風險偏高
- P1 複雜度會明顯膨脹

### 方案 C：積極導入，自動拆分 `.zshrc`

做法：

- 自動辨識區塊、消重複、重排順序、嘗試抽到 `local.d`

優點：

- 長期最完整

缺點：

- 幾乎重新走回自訂 `.zshrc` 維護工具路線
- 與本專案「不做通用 shell 管理器」的邊界衝突

## 最終決策

採用 **方案 A：保守導入，guardrails 優先**。

核心理由：

- 先把 ownership 與 adoption gate 做對，比提早做半自動遷移更重要
- `P1` 必須先讓 doctor 真正可信，之後的 legacy import 才有意義
- `P2` 的 legacy import 與 secret manager 指南屬於擴充能力，不應影響 P0 的導入安全性

## 核心設計

### 1. `~/.zshrc` ownership 改為 bootstrap ownership

新的原則：

- `settingZsh` 只擁有 bootstrap block
- 不直接擁有整份 `.zshrc`

#### Fresh install

若 `~/.zshrc` 不存在：

- 建立最小 `.zshrc`
- 內容僅包含 bootstrap

#### Existing shell, low-risk

若 `~/.zshrc` 已存在，且 preflight 判定為低風險：

- 不覆蓋整份 `.zshrc`
- 只插入 `settingZsh bootstrap` 區塊
- 保留既有非 settingZsh 內容

#### Existing shell, high-risk

若 `~/.zshrc` 已存在，且 preflight 判定為高風險：

- 停止
- 不修改 `.zshrc`
- 轉入 adopt 報告與備份路徑

#### 建議的 `chezmoi` 技術手段

- `create_`：新機器建立 bootstrap 檔
- `modify_`：低風險既有 `.zshrc` 僅插入 bootstrap block

也就是說，public baseline 不再透過 whole-file target 直接宣告 `~/.zshrc` 的完整內容。

### 2. Blocking preflight

新增一個正式 adoption gate。其責任是：在任何會修改 `.zshrc` 的操作前，先判定導入安全性。

#### 檢查項目

- `~/.zshrc` 是否存在
- 是否已有 heavy shell ecosystem
  - Zinit
  - Oh My Zsh
  - Prezto / Antigen / Zplug / plugin manager 類模式
- 是否已有：
  - `compinit`
  - `precmd`
  - `precmd_functions`
  - `brew shellenv`
  - `nvm`
  - bun
  - conda
- 是否疑似含 secret
  - `TOKEN`
  - `SECRET`
  - `PASSWORD`
  - `KEY`
- `zsh -n` 語法檢查
- interactive shell 檢查

#### 結果分類

- `safe`
  - 可執行 bootstrap create / modify
- `needs_adopt`
  - 發現既有重型 shell，停止
- `broken_existing_shell`
  - 現況 shell 本身不健康，停止

#### 行為

- 任何非 `safe` 結果都不得寫檔
- `needs_adopt` 會進入 adopt 報告流程
- `broken_existing_shell` 只提供診斷，不嘗試自動修復

### 3. Adopt existing shell 報告與備份

這不是自動遷移器，而是導入前分析流程。

#### 實際行為

- 讀取既有 `.zshrc`
- 建立 timestamped 備份
- 產出一份 adopt report

#### 報告內容

- shell 結構摘要
  - plugin manager
  - prompt init
  - completion
  - hook
  - env/path
- 疑似 secrets
- 疑似 machine-local integrations
- 建議分流
  - future baseline candidates
  - future `local.d` candidates
  - future secret candidates

#### 第一版不做的事

- 不自動搬到 `local.d`
- 不自動消重複
- 不自動重排
- 不自動 source draft

### 4. Interactive shell doctor（P1）

P1 的責任是把 doctor 從「語法檢查器」升級成「互動 shell 健康檢查器」。

#### 檢查內容

- `zsh -n ~/.zshrc`
- `zsh -i -c exit`
- 互動期 stderr/stdout 模式檢查
- plugin manager / prompt init 失敗
- `compinit` 重複
- `precmd` / `precmd_functions` 衝突
- PATH / brew / bun / `nvm` 順序風險
- secret smell

#### 結果分級

- `blocking`
- `warning`
- `info`

#### 關鍵原則

- 不只看 process exit code
- 必須能辨識 exit 0 但 shell 已經有錯誤輸出的情況

### 5. Legacy import（P2）

`legacy import` 被明確定義為 opt-in 的遷移輔助工具，不是預設導入路徑。

#### 第一版行為

- 掃描既有 `.zshrc`
- 產生 draft：
  - `~/.config/settingzsh/local.d/90-legacy-import.zsh.draft`
- 輸出 diff
- 跑一次 doctor 預測啟用風險

#### 第一版限制

- 預設不改 live `.zshrc`
- 預設不 rename 成正式 `.zsh`
- 不自動在 `init.zsh` 中變更 source 行為
- 不自動清理重複或重排順序

#### 為何放在 P2

因為把舊 `.zshrc` 搬到 `local.d` 代表執行時機從「`.zshrc` 原始位置」變成「`managed.d` 之後」，對行為相容性影響大，不能當作 P0 安全保底。

### 6. Secret manager 指南（P2）

這一輪只補**文件與樣板**，不補 runtime secret 實作。

#### Desktop

- `keepassxc-cli`
- 適用：
  - desktop 機器
  - file secret
  - 人工操作與既有個人同步流程

#### Server

- `gopass`
- 適用：
  - Linux server / headless
  - local-first
  - CLI-first workflow

#### 本輪不處理

- runtime secret 注入架構
- 統一 secret provider abstraction
- 將 secret 寫入 `.zshrc`

## CLI / 指令設計建議

建議新增或調整指令語義如下：

- `settingzsh preflight`
  - 純檢查
  - 不改檔
- `settingzsh adopt`
  - 純報告 + 備份
  - 不改 live shell
- `settingzsh doctor`
  - 升級成 interactive-aware
- `settingzsh install-bootstrap`
  - 僅在 `safe` 時執行 create / modify bootstrap
- `settingzsh legacy-import --draft`
  - 產生 draft，不啟用

是否保留既有 `setup/update/reconcile` 名稱，可在實作時再做兼容包裝；但責任上應分離成「preflight/adopt/install-bootstrap/doctor/import」幾個階段。

## 測試策略

### P0

- `.zshrc` 不存在 -> create bootstrap
- `.zshrc` 輕量 -> modify bootstrap
- `.zshrc` 重型 -> block，不改檔
- adopt 會建立備份與報告

### P1

- `zsh -n` fail
- interactive shell 有錯誤輸出但 exit 0
- duplicate `compinit`
- `precmd` 衝突
- secret smell

### P2

- 產生 `90-legacy-import.zsh.draft`
- 預設不自動啟用
- draft 失敗時不碰 live 檔
- keepassxc-cli / gopass 指南存在且與 README 互連

## 文件影響

應更新：

- `README.md`
  - 分開 `fresh install` 與 `existing machine adoption`
- `docs/architecture.md`
  - 新增 adoption gate 與 bootstrap ownership
- 新增 `docs/adoption-guide.md`
- 新增 `docs/secrets/keepassxc-cli.md`
- 新增 `docs/secrets/gopass.md`

## 風險與緩解

### 風險 1：`modify_` 對複雜 `.zshrc` 仍可能誤插

緩解：

- 先做 blocking preflight
- `modify_` 只在明確低風險條件下允許

### 風險 2：interactive doctor 噪音過高

緩解：

- 分離 `blocking` / `warning` / `info`
- 不以單一 stderr 輸出直接 fail，需有已知模式與規則

### 風險 3：legacy import 被誤解成高相容保底

緩解：

- 文件中明確說明它改變執行時機
- 第一版只產 draft，不自動啟用

## 最終建議

這一輪的最佳實踐不是做更強的 `.zshrc` 自動合併，而是：

1. 先把 `.zshrc` ownership 收斂成 bootstrap ownership
2. 先讓既有機器一定會被 preflight 擋住或分流
3. 先讓 doctor 能真實反映 interactive shell 狀態
4. 最後才提供 opt-in 的 legacy import 與 secrets 指南

這樣可以同時滿足：

- 新機器可持續走 `chezmoi`
- 舊機器不會被誤傷
- 專案邊界仍維持在「管理自己的 baseline」而不是「管理所有 shell」
