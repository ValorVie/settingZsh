# 配置檔合併機制

## 目標

在 setup 腳本覆寫 `.zshrc` 和 `.vimrc` 前，自動整合使用者現有內容，偵測重複設定，保留使用者獨有自訂，並列出差異摘要。

## 架構：Python 合併引擎 + Shell 薄封裝

使用 uv 管理 Python 環境，Python 3 標準庫（零外部依賴）實作核心合併邏輯，Shell/PowerShell 腳本透過 `uv run` 呼叫。Python/uv 不可用時 fallback 到現有備份+覆寫行為。

## 涵蓋範圍

- `.zshrc`（macOS / Linux）— 兩個 section：`zsh-base`、`editor`
- `.vimrc`（macOS / Linux）— 一個 section：`vimrc`
- `nvim/` 不做合併（LazyVim 框架結構，直接備份+覆寫）
- Windows PowerShell Profile 不做合併（本次範圍外）

## 修改的檔案

| 檔案 | 變更 |
|------|------|
| `lib/config_merge.py` | 新建 — 核心合併引擎 |
| `templates/zshrc_base_mac.zsh` | 新建 — 從 setup_mac.sh heredoc 提取 |
| `templates/zshrc_base_linux.zsh` | 新建 — 從 setup_linux.sh heredoc 提取 |
| `templates/zshrc_editor.zsh` | 新建 — 從 editor heredoc 提取（跨平台共用） |
| `setup_mac.sh` | 修改 — heredoc 替換為 merge_config 呼叫 |
| `setup_linux.sh` | 修改 — 同上 |
| `tests/test_mac.sh` | 修改 — 新增合併機制測試 |
| `tests/test_linux.sh` | 修改 — 新增合併機制測試 |

## Section Markers 設計

`.zshrc` 使用 `#` 註解字元：

```zsh
# === settingZsh:managed:zsh-base:begin ===
...（managed content）...
# === settingZsh:managed:zsh-base:end ===

# === settingZsh:user:begin ===
...（使用者自訂，去重後保留）...
# === settingZsh:user:end ===
```

`.vimrc` 使用 `"` 註解字元：

```vim
" === settingZsh:managed:vimrc:begin ===
...
" === settingZsh:managed:vimrc:end ===
```

## 合併演算法

### 主流程

**輸入：** `existing_file`, `template_file`, `section_id`, `file_type`

1. existing 不存在 → 直接寫入 markers + template + 空 user section
2. existing 有新版 markers → 替換該 section 的 managed 內容，user section 不動
3. existing 無 markers（首次升級或全新使用者檔案）→
   1. 備份為 `.bak.{timestamp}`
   2. 將 existing 全部內容視為使用者內容
   3. 逐行正規化比較，找出與 template 重複的行
   4. 輸出：markers + template + 去重後的使用者獨有行（放入 user section）
   5. 列印差異摘要

### 重複偵測

**正規化規則：**

- 去除前後空白
- 多空白壓縮為單一空白
- 純註解行和空行不參與比較
- `.vimrc` 的 `set` 命令提取 key 做語義比對

**分類處理：**

| 類型 | 範例 | 處理 |
|------|------|------|
| 完全重複 | 使用者和模板都有 `alias ls='ls --color'` | 移除使用者版，摘要列出 |
| 值衝突 | 使用者 `set tabstop=2`，模板 `set tabstop=4` | 保留使用者版（尊重使用者偏好） |
| 使用者獨有 | `alias gst='git status'` | 保留在 user section |

### 差異摘要輸出

```
=== 配置檔合併摘要：.zshrc ===
  管理區段：已寫入 (zsh-base)
  移除重複：3 行
    - alias ls='ls --color'
    - setopt appendhistory
    - bindkey '^f' autosuggest-accept
  保留自訂：5 行
  備份檔案：~/.zshrc.bak.20260202-153000
================================
```

## Python 環境管理：uv

在 `lib/` 目錄下建立獨立的 Python 專案，使用 uv 管理：

```
lib/
├── pyproject.toml          # uv 專案定義（requires-python >= 3.10, 零依賴）
└── config_merge.py         # 合併引擎（inline script 或 package）
```

`pyproject.toml` 僅聲明 Python 版本需求，不引入外部套件。

## CLI 介面

```bash
uv run lib/config_merge.py \
  --target ~/.zshrc \
  --template templates/zshrc_base_mac.zsh \
  --section zsh-base \
  --type zsh

uv run lib/config_merge.py \
  --target ~/.vimrc \
  --template vim/.vimrc \
  --section vimrc \
  --type vim
```

**選項：**

| 選項 | 說明 |
|------|------|
| `--target` | 目標檔案 |
| `--template` | 模板檔案 |
| `--section` | section ID |
| `--type` | `zsh` / `vim` |
| `--dry-run` | 僅輸出摘要，不寫入 |
| `--no-color` | 無色彩輸出 |

**回傳碼：** `0` 成功、`1` 錯誤、`2` 全新安裝（無既有檔案）

## Setup 腳本修改

### 新增共用函式 `merge_config()`

```bash
merge_config() {
    local target="$1" template="$2" section="$3" filetype="$4"
    if command -v uv >/dev/null 2>&1; then
        uv run "$SCRIPT_DIR/lib/config_merge.py" \
            --target "$target" --template "$template" \
            --section "$section" --type "$filetype"
    elif command -v python3 >/dev/null 2>&1; then
        python3 "$SCRIPT_DIR/lib/config_merge.py" \
            --target "$target" --template "$template" \
            --section "$section" --type "$filetype"
    else
        echo "[警告] uv/Python3 不可用，使用備份+覆寫模式"
        [ -f "$target" ] && cp "$target" "${target}.bak"
        cp "$template" "$target"
    fi
}
```

### `install_zsh_env()` 修改

刪除 heredoc 區塊，替換為：

```bash
merge_config ~/.zshrc "$SCRIPT_DIR/templates/zshrc_base_mac.zsh" "zsh-base" "zsh"
```

### `install_editor_env()` 修改

`.vimrc` 部署替換為：

```bash
merge_config ~/.vimrc "$SCRIPT_DIR/vim/.vimrc" "vimrc" "vim"
```

Editor 段追加替換為：

```bash
merge_config ~/.zshrc "$SCRIPT_DIR/templates/zshrc_editor.zsh" "editor" "zsh"
```

## 邊界情況

| 情境 | 處理 |
|------|------|
| 全新安裝 | markers + template + 空 user section |
| 重複執行（已有 markers） | 僅更新 managed 段 |
| 首次升級（無 markers） | 全檔視為使用者內容，去重後保留 |
| end marker 被刪除 | 找不到配對時視為無 markers |
| Python 不可用 | fallback 備份+覆寫 |
| 空檔案 | 等同全新安裝 |
| 同一檔案多個 section（zsh-base + editor） | 各自獨立處理，互不干擾 |
| managed section 內被使用者修改 | 會被新模板覆蓋，但差異摘要提示 |

## 實作順序

1. 建立 `templates/` — 從 heredoc 提取模板檔案
2. 建立 `lib/config_merge.py` — 合併引擎（正規化、去重、markers、摘要）
3. 修改 `setup_mac.sh` — 替換 heredoc 為 merge_config 呼叫
4. 修改 `setup_linux.sh` — 同上
5. 更新測試腳本 — 驗證 merge tool 存在、template 檔案存在

## 驗證方式

1. **單元測試：** 準備假的 existing 檔案，驗證合併輸出正確
2. **整合測試：** 在 macOS 上實際執行 `python3 lib/config_merge.py --dry-run` 對比本機 `~/.zshrc`
3. **手動驗證：** 跑 `tests/test_mac.sh` 確認無 FAIL
