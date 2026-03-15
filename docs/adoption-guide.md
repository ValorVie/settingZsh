# settingZsh 既有機器導入指南

這份指南只處理一件事：**這台機器已經有自己的 `~/.zshrc` 時，怎麼安全導入 `settingZsh`**。

如果是新機器，直接看 [README.md](/Users/arlen/Documents/syncthing/backup/server/Code/settingZsh/.worktrees/settingzsh-chezmoi/README.md) 的 `fresh install` 流程即可。

## 核心原則

- 不直接拿 `chezmoi init --apply` 套在陌生既有 shell 上
- `~/.zshrc` 只由 bootstrap 擁有
- 先跑 adoption gate，再決定要不要導入
- `legacy import` 是 opt-in 的草稿工具，不是高相容保底

## 什麼情況算 existing machine

只要你符合下面任一項，就建議先走 adoption：

- `~/.zshrc` 已存在
- 已有 plugin manager，例如 Zinit、Oh My Zsh、Prezto、Antigen
- 已有 `compinit`
- 已有 `precmd` / `precmd_functions`
- 已有 brew / `nvm` / bun / conda 初始化
- `.zshrc` 內疑似混有 secret

## 推薦流程

### 1. 先 init，但不要直接 apply

```bash
chezmoi init <public-repo>
chezmoi cd
```

### 2. 先跑 blocking preflight

```bash
uv run --directory lib python -m settingzsh.cli preflight
```

可能結果：

- `safe`
  - 代表沒有發現需要先中止的重型 shell 狀態
  - 可以往 `chezmoi apply` 或 `settingzsh.cli reconcile` 前進
- `needs_adopt`
  - 代表這台機器有既有 shell 生態，需要先看 adopt report
- `broken_existing_shell`
  - 代表現況 shell 自己就有問題，要先處理現況

### 3. 如果是 `needs_adopt`，先產生報告與備份

```bash
uv run --directory lib python -m settingzsh.cli adopt
```

這一步只會做兩件事：

- 建立 `.zshrc` 備份
- 產生 adopt report

它**不會**重寫 live `.zshrc`。

預設輸出：

- `~/.zshrc.bak.<timestamp>`
- `~/.config/settingzsh/reports/adopt-report-<timestamp>.md`

## 什麼時候可以直接 apply

只有在下面情況才建議直接 `chezmoi apply`：

- `preflight` 回 `safe`
- 你知道這台機器的 `.zshrc` 沒有重型 plugin / hook / completion 生態
- 你接受 public baseline 只插入 bootstrap，不接管整份檔案

## `legacy import` 是什麼

```bash
uv run --directory lib python -m settingzsh.cli legacy-import
```

目前只會產生：

- `~/.config/settingzsh/local.d/90-legacy-import.zsh.draft`

它的用途是讓你看到「如果把既有 `.zshrc` 承接進 `local.d`，大概會長什麼樣」。

注意：

- 它不會自動啟用
- 它不會自動幫你清重複 `compinit`
- 它不會自動處理 `precmd` / `precmd_functions`
- 它不會自動拆 secrets

所以它是草稿工具，不是零風險遷移器。

## 建議判斷方式

### 可以直接導入

- `.zshrc` 很短
- 只有 PATH / alias / 少量環境變數
- 沒有 plugin manager
- 沒有 hooks
- 沒有 secrets

### 先維持現況，只插 bootstrap 或延後導入

- 有 `compinit`
- 有 `precmd`
- 有 prompt instant init
- 有 OpenSpec / bun / brew / `nvm` 混合初始化
- 有你暫時不想移動的 secrets

## 相關指令

```bash
uv run --directory lib python -m settingzsh.cli preflight
uv run --directory lib python -m settingzsh.cli adopt
uv run --directory lib python -m settingzsh.cli doctor
uv run --directory lib python -m settingzsh.cli migrate
uv run --directory lib python -m settingzsh.cli reconcile
uv run --directory lib python -m settingzsh.cli legacy-import
```
