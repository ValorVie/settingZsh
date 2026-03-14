# settingZsh Bootstrap 化重構設計

**日期：** 2026-03-14
**狀態：** 已確認
**作者：** Codex

## 背景

目前 `settingZsh` 會直接管理 `~/.zshrc` 的大段內容，並透過 [lib/config_merge.py](/Users/arlen/Documents/syncthing/backup/server/Code/settingZsh/lib/config_merge.py) 與 shell 腳本整合。這個模型在下列情境容易失效：

- 系統原本已經有複雜的 `~/.zshrc`
- 其他工具會在 `~/.zshrc` 前後插入內容
- managed 區塊被外部工具或人工調整後，系統缺少明確的漂移檢查與修復流程

本次重構的核心前提是：`settingZsh` 不是通用的 `.zshrc` 維護工具，只需要保證「本工具不要造成 shell 異常」，不接管其他工具的設定。

## 目標

- 將 `settingZsh` 對 `~/.zshrc` 的責任收斂為最小 bootstrap
- 將本工具自己的 managed 設定移到 `~/.config/settingzsh/`
- 讓 `setup` / `update` 預設不重排、不主動遷移既有 `.zshrc`
- 將遷移與修復行為集中到 `migrate` / `doctor --fix`
- 寫入前必須驗證，失敗時必須可回滾

## 非目標

- 不代管第三方工具插入的 `.zshrc` 內容
- 不幫使用者自動整理 bun / gcloud / Spectra / OpenSpec 等外部區塊
- 不重寫 Windows PowerShell 設定模型
- 不將 `settingZsh` 變成通用 shell framework manager

## 已確認的決策

### 1. 核心架構：Python + uv，Shell 只做薄包裝

- 保留 `setup.sh`、`setup_mac.sh`、`setup_linux.sh`、`update.sh` 作為入口
- shell 腳本只負責平台偵測、安裝前置工具、呼叫 Python CLI
- shell 不再直接 merge 或覆寫 `~/.zshrc`

### 2. `.zshrc` 只保留最小 bootstrap

目標穩態如下：

```zsh
# >>> settingZsh bootstrap >>>
[ -f "$HOME/.config/settingzsh/init.zsh" ] && source "$HOME/.config/settingzsh/init.zsh"
# <<< settingZsh bootstrap <<<
```

- 本工具只保證這段 bootstrap 與其所載入的 managed 檔案健康
- 第三方內容原則上留在原本的 `~/.zshrc`

### 3. managed 設定改放到 `~/.config/settingzsh/`

建議目錄結構：

```text
~/.config/settingzsh/
├── init.zsh
├── managed.d/
│   ├── 10-base.zsh
│   └── 40-editor.zsh
├── backups/
│   └── <timestamp>/
└── state.json
```

- `init.zsh`：以固定順序載入 `managed.d/*.zsh`
- `managed.d/`：本工具實際管理的 shell 片段
- `backups/`：遷移或修復前的備份
- `state.json`：版本、遷移狀態、最近一次 doctor 結果、備份路徑

### 4. `setup/update` 預設不主動遷移

- `setup` / `update` 只維護本工具自己的檔案
- 偵測到舊版 `settingZsh:managed:*` markers、bootstrap 缺失或驗證失敗時，不直接改寫 `~/.zshrc`
- 預設只輸出明確提醒，要求使用者執行 `migrate` 或 `doctor --fix`

### 5. 遷移只處理 `settingZsh` 自己的內容

針對像目前機器這種混合態 `.zshrc`：

- 擷取舊 `managed:zsh-base`
- 擷取舊 `managed:editor`
- 將這兩段寫入新的 `managed.d/*.zsh`
- 將舊 `settingZsh:user` 區塊內容移到新結構中的保留檔案
- 將 `.zshrc` 裡舊版 `settingZsh` markers 收斂為單一 bootstrap
- 非 `settingZsh` 內容保持原順序與原位置

### 6. 失敗策略採安全模式

所有會改動 shell 檔案的流程都遵循：

1. 建立備份
2. 生成候選檔案
3. 執行 `zsh -n`
4. 執行最小 interactive smoke test
5. 全部通過才原子替換
6. 任一步失敗就回滾，保留原檔並輸出修復資訊

## Python CLI 設計

建議命令：

- `setup`
- `update`
- `doctor`
- `migrate`
- `reconcile`

### `setup`

- 建立 `~/.config/settingzsh/` 與 managed fragments
- 檢查 `~/.zshrc` 是否已有 bootstrap
- 發現舊 markers 時只警告，不自動遷移

### `update`

- 更新本工具自己的 managed fragments 與狀態
- 先跑輕量 doctor
- 偵測風險時停止 shell 寫入，只提示後續動作

### `doctor`

檢查：

- bootstrap 是否存在且不重複
- 是否仍存在舊版 markers
- `init.zsh` / `managed.d/*.zsh` 是否完整
- `zsh -n`
- `ZDOTDIR=<temp>` interactive smoke test
- 本工具已知高風險寫法，例如重複 `compinit` 或全域 `precmd()` 覆蓋

預設唯讀；只有 `doctor --fix` 才可改動檔案。

### `migrate`

- 只搬移 `settingZsh` 自己的舊結構
- 不嘗試理解第三方工具的 `.zshrc` 區塊
- 驗證失敗時完整回滾

### `reconcile`

- 比對 `managed.d/` 與產生的 `init.zsh`
- 可用於 `setup/update` 前的內部健康檢查
- 不改動第三方內容

## 檔案責任建議

建議新增 Python 模組：

```text
lib/
├── config_merge.py
├── pyproject.toml
└── settingzsh/
    ├── __init__.py
    ├── cli.py
    ├── bootstrap.py
    ├── doctor.py
    ├── migrate.py
    ├── reconcile.py
    ├── state.py
    └── shellgen.py
```

- `config_merge.py` 可先保留，後續收斂為 `.vimrc` 或其他純文字合併用途
- 新 CLI 不再依賴 full-file `.zshrc` merge

## 測試策略

### 單元測試

- bootstrap 偵測與插入
- 舊版 markers 擷取與移除
- `state.json` 讀寫
- rollback 邏輯

### Fixture 整合測試

建立多種 `.zshrc` 樣本：

- 空檔
- 純第三方內容
- 舊版 `settingZsh` markers
- 混合態 `.zshrc`

對每個 fixture 驗證：

- `doctor`
- `migrate`
- `doctor --fix`
- `update`

### Shell 驗證

- `zsh -n`
- `ZDOTDIR=<fixture-home> zsh -i -c exit`

## 驗收標準

1. `setup/update` 不再因本工具的 shell 寫入而破壞既有 `.zshrc`
2. `migrate` 只搬移 `settingZsh` 自己的內容，不重排第三方區塊
3. 遷移後 `.zshrc` 可收斂為 bootstrap + 既有第三方內容
4. 本工具輸出的 shell 內容通過語法與 interactive smoke test
5. 任一步失敗都可自動回滾
6. README 與測試流程能反映新命令模型

## 取捨

- 這個設計刻意放棄「自動整理整份 `.zshrc`」的野心
- 換來的是明確責任邊界、較低風險、較高可測性
- 若未來需要通用 `.zshrc` 維護能力，應視為另一個獨立工具，而不是繼續擴張 `settingZsh`
