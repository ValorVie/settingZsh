## Context

Linux 安裝腳本 `setup_linux.sh` 的 `install_editor_env()` 將 neovim 解壓至 `/usr/local/`、lazygit 安裝至 `/usr/local/bin/`，需要 sudo。`update_linux.sh` 有相同問題。macOS 和 Windows 腳本不受影響（Homebrew 和 winget 本身就是使用者層級）。

`~/.local/bin` 已在 `templates/zshrc_base_linux.zsh` 的 PATH 中（append 方式）。

## Goals / Non-Goals

**Goals:**
- neovim 和 lazygit 統一安裝至 `~/.local/bin`，不再需要 sudo
- ripgrep 和 fd 在無 sudo 時提供 GitHub Release binary fallback
- build-essential 和 vim 在無 sudo 時輸出警告而非中斷
- 有 sudo 的使用者體驗不退化

**Non-Goals:**
- 不改變 macOS / Windows 的安裝流程
- 不將 `~/.local/bin` 改為 PATH prepend（超出本次範圍）
- 不移除 apt 安裝路徑（有 sudo 時仍用 apt 安裝 ripgrep/fd/build-essential/vim）
- 不處理 build-essential 的使用者層級替代方案

## Decisions

### Decision 1: neovim/lazygit 統一使用 `~/.local/bin`（Linux）

不論有無 sudo，一律安裝到 `~/.local/bin`。不做分流。

**理由：** 統一路徑降低維護複雜度。neovim tar.gz 解壓結構為 `bin/`、`lib/`、`share/`，`--strip-components=1` 到 `~/.local/` 時結構正確對應。lazygit 為單一 binary。

**替代方案：** 有 sudo 走 `/usr/local`、無 sudo 走 `~/.local/` → 增加分支複雜度，無實際收益。

### Decision 2: ripgrep/fd 偵測 sudo 後分流（Linux）

使用 `sudo -n true 2>/dev/null` 偵測是否有免密碼 sudo 權限：
- **有 sudo** → `sudo apt install -y ripgrep fd-find`（維持現行）
- **無 sudo** → 從 GitHub Release 下載靜態 binary 至 `~/.local/bin/`

**理由：** apt 版本由系統套件管理追蹤，對有 sudo 的使用者是更好的選擇。但 ripgrep 和 fd 都提供 musl 靜態編譯 binary，fallback 可靠。

**注意：** fd 在 Debian/Ubuntu apt 安裝後指令名為 `fdfind`，但 GitHub Release binary 指令名為 `fd`。fallback 安裝後指令名會不同，需確認 LazyVim telescope 設定是否相容（telescope 預設找 `fd`，所以 GitHub binary 反而更相容）。

### Decision 3: build-essential/vim 改為偵測 + 警告（Linux）

- 有 sudo → 照舊 `sudo apt install -y build-essential vim`
- 無 sudo → 檢測 `gcc` 和 `vim` 是否存在
  - 存在：靜默通過
  - 不存在：輸出警告訊息，不中斷流程

**理由：** build-essential 包含 gcc/g++/make 等系統級編譯工具，不適合使用者層級安裝。多數伺服器和開發環境已預裝。缺少時 treesitter 會退化但 nvim 仍可用。

### Decision 4: 版本管理策略

ripgrep 和 fd 的 fallback 下載版本以腳本頂部變數管理（如同現有的 `LAZYGIT_VERSION`）：
```bash
RIPGREP_VERSION="14.1.1"
FD_VERSION="10.2.0"
```

**理由：** 與現有 lazygit 版本管理方式一致。

## Risks / Trade-offs

- **[風險] 舊版 nvim/lazygit 殘留在 `/usr/local/bin/`** → PATH 中 `/usr/local/bin` 通常在 `~/.local/bin` 前面。若使用者先前用 sudo 安裝過，舊版會優先被找到，導致新安裝的版本被遮蔽。**緩解：** 安裝完成後檢測 `/usr/local/bin/nvim` 和 `/usr/local/bin/lazygit` 是否存在，若存在則輸出路徑、版本、以及建議移除指令（`sudo rm /usr/local/bin/nvim` 等）。
- **[風險] fd 指令名不一致** → apt 裝的叫 `fdfind`，GitHub binary 叫 `fd`。**緩解：** telescope 預設找 `fd`，GitHub binary 版本反而更相容。
- **[風險] GitHub Release 下載失敗** → 網路問題或 URL 變更。**緩解：** 下載失敗時輸出警告，不中斷整體流程。
- **[取捨] 無 sudo 環境缺少 build-essential** → treesitter 無法編譯語法解析器，語法高亮退化。可接受，因 nvim 基本功能仍正常。
