# settingZsh -> chezmoi Capability Parity Matrix

**日期：** 2026-03-15  
**目的：** 確保遷移到 `chezmoi` 後，使用者可見結果不退化。

## 使用方式

- 每一列代表一個必須被追蹤的能力。
- 實作前先確認 `新 chezmoi 機制` 欄位已具體化。
- 驗收時逐列執行 `驗證方式`。

## Matrix

| 現有能力 | 目前來源 | 新 chezmoi 機制 | 是否必保留 | 驗證方式 |
| :--- | :--- | :--- | :--- | :--- |
| macOS/Linux Zsh baseline | `templates/zshrc_base_mac.zsh` `templates/zshrc_base_linux.zsh` | `home/modify_dot_zshrc` + `home/dot_config/settingzsh/managed.d/*.zsh.tmpl` | MUST | `zsh -n ~/.zshrc` 與啟動 smoke |
| Zinit 與預設插件集合 | `README.md`、模板檔 | `managed.d/10-base.zsh.tmpl` | MUST | 檢查模板含 `zinit` 與插件宣告 |
| `fzf` 安裝與初始化 | `setup_mac.sh` `setup_linux.sh` `setup_win.ps1` | `run_once_*` scripts + 對應 shell/profile 模板 | MUST | `command -v fzf` |
| `zoxide` 安裝與初始化 | `setup_mac.sh` `setup_linux.sh` | `run_once_*` scripts + shell 模板 | MUST | `command -v zoxide` |
| Maple Mono 字型安裝 | 三平台 setup 腳本 | 平台專屬 `run_once_*fonts*` scripts | MUST | 目標字型路徑存在 + 人工視覺確認 |
| Linux 無 sudo fallback | `setup_linux.sh` | Linux 專屬 fallback script 分支 | MUST | 無 sudo 環境 smoke test |
| Windows PowerShell profile 路徑分流（5.1/7+） | `setup_win.ps1` | `home/dot_config/powershell/...` + Windows script | MUST | 5.1/7+ 各自檔案落地檢查 |
| Windows PowerShell modules（Terminal-Icons/ZLocation/PSFzf） | `setup_win.ps1` | Windows `run_once_*` script | MUST | `Get-Module -ListAvailable` |
| Windows `Starship` 安裝 | `setup_win.ps1` | Windows `run_once_*` script | SHOULD | `command -v starship` |
| Editor 預設不安裝 | 互動流程 + `~/.settingzsh/features` | `feature_editor` data flag | MUST | 預設 apply 後 editor tools 未安裝 |
| Editor 啟用後安裝工具 | 三平台 setup scripts | `run_onchange_*editor*` scripts + feature flag | MUST | 啟用 flag 後工具存在檢查 |
| 既有 nvim 設定備份策略 | 三平台 setup scripts | editor script 內備份邏輯 | MUST | 既有 `~/.config/nvim` 時建立 `.bak` |
| `.ssh/config` 主檔由 baseline 管理 | README 與現況規劃 | `home/private_dot_ssh/config.tmpl` | MUST | `ssh -G example` 可解析 |
| `config + config.d` 分層 | 既有設計文件 | `config.tmpl` + `config.d/10-common.conf.tmpl` | MUST | `Include` 生效檢查 |
| private SSH overlay 第二階段 | 遷移設計文件 | `.chezmoiexternal.toml.tmpl` + overlay script | MUST | private overlay 缺席/存在雙路徑驗證 |
| private overlay 缺席時 baseline 可獨立工作 | 使用者需求 | 兩階段流程 + 容錯 script | MUST | 只跑 Phase A 功能驗證 |
| shell 狀態檢查能力（doctor 類） | `settingzsh.cli doctor` | 遷移期保留 CLI 或新增 smoke checks | SHOULD | `zsh -n` + config parse smoke |
| update 可重跑且不破壞設定（idempotency） | 既有 update scripts | `chezmoi apply` + run script 設計 | MUST | 連跑兩次 diff 為空或預期 |

## 不可接受退化（MUST NOT REGRESS）

- Linux 無 sudo fallback 消失
- Windows PowerShell modules 消失
- Windows profile 路徑分流消失
- 字型安裝退化成只放字型檔
- editor 預設不安裝與 feature gating 消失
- Zinit 與預設插件集合消失
- `.ssh/config` 主檔被 private overlay 接管
- private overlay 缺席時 baseline 無法單獨工作
