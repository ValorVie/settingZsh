## Context

目前 `setup_mac.sh` 和 `setup_linux.sh` 透過 heredoc 直接覆寫 `~/.zshrc`，並以檔案複製覆寫 `~/.vimrc`。使用者在覆寫前若已有自訂內容，僅產生一份 `.bak` 備份，需手動合併回來。重複執行腳本會反覆覆寫，無法分辨哪些行是模板管理、哪些是使用者新增。

此設計引入 section markers 機制，將配置檔切分為 managed（模板控制）與 user（使用者自訂）兩種區段，由 Python 合併引擎處理比對與寫入。

**影響平台：** Linux / macOS

## Goals / Non-Goals

**Goals:**

- 重複執行 setup 腳本時，只更新 managed 段，不破壞 user 段
- 首次升級（無 markers 的既有檔案）自動去重，保留使用者獨有行
- 合併後輸出差異摘要，讓使用者知道哪些行被移除、保留、有衝突
- uv 作為唯一 Python 管理工具，由 setup 腳本安裝

**Non-Goals:**

- 互動式衝突解決
- nvim/ 目錄合併
- Windows PowerShell Profile 合併
- python3 fallback 路徑

## Decisions

### D1: Section Markers 格式（影響平台：Linux / macOS）

**決定：** 使用 `# === settingZsh:managed:<section-id>:begin ===` / `end` 標記 managed 段，`# === settingZsh:user:begin ===` / `end` 標記 user 段。

**替代方案：**
- (A) 用隱藏字元標記 → 不可見、不利除錯
- (B) 用檔頭 magic comment → 無法支援同一檔案多個 section

**理由：** 明確可讀、grep 友善、支援同一檔案多 section（`.zshrc` 需要 `zsh-base` + `editor` 兩段）。`.vimrc` 以 `"` 替代 `#` 作為註解字元。

### D2: 合併引擎語言選擇（影響平台：Linux / macOS）

**決定：** Python 3 標準庫，零外部依賴，由 uv 管理環境。

**替代方案：**
- (A) 純 Shell 實作 → 字串處理能力弱，正規化比對難以維護
- (B) awk/sed 組合 → 邊界情況處理複雜，可讀性差

**理由：** Python 的字串處理、正規表達式、集合操作適合此任務。uv 提供一致的 Python 環境管理，避免系統 Python 版本差異。

### D3: uv 安裝方式（影響平台：Linux / macOS）

**決定：** 在 setup 腳本中檢查 `uv` 是否存在，不存在則透過官方安裝腳本安裝。

| 平台 | 安裝方式 |
|------|----------|
| macOS | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| Linux | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |

**理由：** 官方安裝腳本跨平台通用，不依賴 Homebrew/apt，安裝至 `~/.local/bin`（已在 PATH 中）。

### D4: 模板檔案提取策略（影響平台：Linux / macOS）

**決定：** 從 heredoc 提取為獨立模板檔案，存放於 `templates/` 目錄。

```
templates/
├── zshrc_base_mac.zsh      # macOS 專用（含 Homebrew shellenv）
├── zshrc_base_linux.zsh    # Linux 專用（含動態 PATH）
└── zshrc_editor.zsh        # 跨平台共用（nvm lazy loading + alias）
```

**差異處理：**
- `zshrc_base_mac.zsh` 與 `zshrc_base_linux.zsh` 的差異僅在 PATH 設定和 Homebrew 初始化
- `zshrc_editor.zsh` 兩平台完全相同，不需分離

### D5: 重複偵測的正規化規則（影響平台：Linux / macOS）

**決定：**
1. 去除前後空白
2. 多空白壓縮為單一空白
3. 純註解行和空行不參與比較
4. `.vimrc` 的 `set` 命令提取 key 做語義比對（例如 `set tabstop=2` 和 `set tabstop=4` 視為同一 key）

**分類處理：**
| 類型 | 處理 |
|------|------|
| 完全重複 | 移除使用者版，摘要列出 |
| 值衝突（同 key 不同 value） | 保留使用者版，摘要列出衝突內容 |
| 使用者獨有 | 保留在 user section |

### D6: CLI 介面設計（影響平台：Linux / macOS）

**決定：** `lib/config_merge.py` 作為 CLI 工具，由 `uv run` 執行。

```
uv run lib/config_merge.py \
  --target <目標檔案> \
  --template <模板檔案> \
  --section <section-id> \
  --type <zsh|vim> \
  [--dry-run] [--no-color]
```

**回傳碼：** `0` 成功、`1` 錯誤、`2` 全新安裝

### D7: Setup 腳本整合方式（影響平台：Linux / macOS）

**決定：** 新增 `merge_config()` Shell 函式，封裝 `uv run` 呼叫。uv 不可用時 fallback 到備份+覆寫。

```bash
merge_config() {
    local target="$1" template="$2" section="$3" filetype="$4"
    if command -v uv >/dev/null 2>&1; then
        uv run "$SCRIPT_DIR/lib/config_merge.py" \
            --target "$target" --template "$template" \
            --section "$section" --type "$filetype"
    else
        echo "[警告] uv 不可用，使用備份+覆寫模式"
        [ -f "$target" ] && cp "$target" "${target}.bak"
        cp "$template" "$target"
    fi
}
```

原有 heredoc 區塊替換為：
- `merge_config ~/.zshrc "$SCRIPT_DIR/templates/zshrc_base_<platform>.zsh" "zsh-base" "zsh"`
- `merge_config ~/.zshrc "$SCRIPT_DIR/templates/zshrc_editor.zsh" "editor" "zsh"`
- `merge_config ~/.vimrc "$SCRIPT_DIR/vim/.vimrc" "vimrc" "vim"`

## Risks / Trade-offs

| 風險 | 緩解措施 |
|------|----------|
| [風險] uv 安裝失敗（網路問題） | → fallback 到備份+覆寫模式，不中斷 setup 流程 |
| [風險] 使用者手動編輯 managed 段 | → 下次合併會覆蓋，但差異摘要會提示被覆蓋的內容 |
| [風險] end marker 被意外刪除 | → 找不到配對 marker 時視為無 markers，走首次升級流程 |
| [取捨] 值衝突只保留使用者版 | → 不做互動式選擇，以差異摘要通知，使用者可手動調整 |
| [取捨] Python 新增為依賴 | → uv 自帶 Python 管理，不需系統預裝 Python |

## Open Questions

（目前無未決問題）
