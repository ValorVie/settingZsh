# Editor 使用指南

本專案安裝兩個獨立的編輯器：**Vim** 和 **Neovim (LazyVim)**。兩者各自運作，互不影響。

## 定位與使用場景

| 編輯器 | 用途 | 配置檔 | 插件依賴 |
|--------|------|--------|----------|
| Vim | 伺服器 / SSH 臨時編輯 | `~/.vimrc` | 無（零依賴） |
| Neovim | 本機開發主力 IDE | `~/.config/nvim/` | LazyVim + 語言插件 |

```
vim file.txt     # 啟動 Vim
nvim file.txt    # 啟動 Neovim
```

---

## Vim

### 概述

精簡配置，無外部插件依賴，專為伺服器環境或 SSH 遠端編輯設計。配置來源：`vim/.vimrc`。

### 操作設定

| 設定 | 值 | 說明 |
|------|-----|------|
| 行號 | `number` + `relativenumber` | 顯示絕對行號與相對行號 |
| 縮排 | 4 空格 | Tab 自動轉為空格 |
| 搜尋 | 忽略大小寫 / 增量搜尋 | 包含大寫時自動切換為區分大小寫 |
| 滑鼠 | 關閉 | 不攔截終端機滑鼠事件 |
| 剪貼簿 | `unnamed,unnamedplus` | 共用系統剪貼簿 |
| 分割視窗 | 右 / 下 | 新視窗預設開在右邊和下面 |
| 換行 | Unix (`\n`) | 自動修正檔尾換行 |

### 常用操作

#### 基本移動

| 按鍵 | 功能 | 記法 |
|------|------|------|
| `h` `j` `k` `l` | 左 / 下 / 上 / 右 | 鍵盤中排，`j` 像箭頭朝下 |
| `w` / `b` | 下一個 / 上一個詞 | **w**ord / **b**ack |
| `0` / `$` | 行首 / 行尾 | 0 是起點，$ 是正規表達式行尾 |
| `gg` / `G` | 檔案開頭 / 結尾 | **g**o 到頂，大 G 到底 |
| `Ctrl+d` / `Ctrl+u` | 向下 / 向上半頁 | **d**own / **u**p |
| `{number}G` | 跳到第 N 行 | 如 `42G` 跳到第 42 行 |

#### 編輯

| 按鍵 | 功能 | 記法 |
|------|------|------|
| `i` / `a` | 在游標前 / 後插入 | **i**nsert / **a**ppend |
| `o` / `O` | 在下方 / 上方新增一行 | **o**pen line（大 O 往上開） |
| `dd` | 刪除整行 | **d**elete 按兩下 = 整行 |
| `yy` | 複製整行 | **y**ank（拉）按兩下 = 整行 |
| `p` / `P` | 貼上（下方 / 上方） | **p**aste |
| `u` / `Ctrl+r` | 復原 / 重做 | **u**ndo / **r**edo |
| `.` | 重複上一個操作 | 「再來一次」 |

#### 搜尋與取代

| 按鍵 | 功能 | 記法 |
|------|------|------|
| `/pattern` | 向下搜尋 | 斜線開啟搜尋列 |
| `?pattern` | 向上搜尋 | 問號 = 反方向搜尋 |
| `n` / `N` | 下一個 / 上一個匹配 | **n**ext（大 N 反向） |
| `:%s/old/new/g` | 全檔取代 | **s**ubstitute，`%` = 全檔，`g` = 每行全部 |
| `:noh` | 清除搜尋高亮 | **no** **h**ighlight |

#### 分割視窗

| 按鍵 | 功能 | 記法 |
|------|------|------|
| `:vs file` | 垂直分割開啟檔案 | **v**ertical **s**plit |
| `:sp file` | 水平分割開啟檔案 | **sp**lit |
| `Ctrl+w h/j/k/l` | 在視窗間移動 | **w**indow + 方向 |
| `Ctrl+w =` | 平均分配視窗大小 | = 等號 = 均等 |

#### 存檔與離開

| 按鍵 | 功能 | 記法 |
|------|------|------|
| `:w` | 存檔 | **w**rite |
| `:q` | 離開 | **q**uit |
| `:wq` / `ZZ` | 存檔並離開 | write + quit / ZZ 快速離開 |
| `:q!` | 放棄修改並離開 | ! = 強制 |

---

## Neovim (LazyVim)

### 概述

以 [LazyVim](https://www.lazyvim.org/) 為基礎的完整 IDE 配置，支援 LSP、自動補全、模糊搜尋、Git 整合等功能。配置來源：`nvim/`。

### 本專案的客製化

以下為覆寫 LazyVim 預設值的設定（`nvim/lua/config/options.lua`）：

| 選項 | 本專案 | LazyVim 預設 | 說明 |
|------|--------|-------------|------|
| `tabstop` | 4 | 2 | Tab 寬度對齊 VSCode |
| `shiftwidth` | 4 | 2 | 自動縮排寬度 |
| `wrap` | true | false | 啟用自動換行 |
| `mouse` | `""` | `"a"` | 關閉滑鼠攔截 |
| `fileformat` | unix | - | 統一使用 Unix 換行 |

### 自訂快鍵

| 按鍵 | 模式 | 功能 |
|------|------|------|
| `jk` | Insert | 退出插入模式（等同 `Esc`） |

### LazyVim 核心快鍵

Leader 鍵為**空格鍵** (`<Space>`)。以下列出最常用的操作：

#### 檔案與導航

| 按鍵 | 功能 | 記法 |
|------|------|------|
| `<Leader>ff` | 搜尋檔案（Telescope） | **f**ind **f**ile |
| `<Leader>fg` | 全域文字搜尋（Grep） | **f**ind by **g**rep |
| `<Leader>fb` | 搜尋已開啟的 Buffer | **f**ind **b**uffer |
| `<Leader>fr` | 搜尋最近開啟的檔案 | **f**ind **r**ecent |
| `<Leader>e` | 開啟/關閉檔案總管（Neo-tree） | **e**xplorer |

#### Buffer 管理

| 按鍵 | 功能 | 記法 |
|------|------|------|
| `Shift+h` / `Shift+l` | 上一個 / 下一個 Buffer | H 左 / L 右 |
| `<Leader>bd` | 關閉當前 Buffer | **b**uffer **d**elete |
| `<Leader>bo` | 關閉其他所有 Buffer | **b**uffer **o**nly（只留這個） |

#### 視窗操作

| 按鍵 | 功能 | 記法 |
|------|------|------|
| `<Leader>-` | 水平分割 | 橫槓 = 橫切 |
| `<Leader>\|` | 垂直分割 | 豎線 = 直切 |
| `Ctrl+h/j/k/l` | 在視窗間移動 | 同 Vim 方向鍵 |

#### LSP（程式碼智慧功能）

| 按鍵 | 功能 | 記法 |
|------|------|------|
| `gd` | 跳到定義 | **g**o to **d**efinition |
| `gr` | 查看引用 | **g**o to **r**eferences |
| `K` | 顯示文件（Hover） | 大 K = 查手冊（同 man page 慣例） |
| `<Leader>ca` | 程式碼動作（Code Action） | **c**ode **a**ction |
| `<Leader>cr` | 重新命名符號 | **c**ode **r**ename |
| `<Leader>cd` | 顯示行診斷訊息 | **c**ode **d**iagnostic |
| `]d` / `[d` | 下一個 / 上一個診斷 | ] 往後 / [ 往前，**d**iagnostic |

#### 搜尋與取代

| 按鍵 | 功能 | 記法 |
|------|------|------|
| `<Leader>sr` | 搜尋並取代（Spectre） | **s**earch **r**eplace |
| `<Leader>ss` | 搜尋文件符號 | **s**earch **s**ymbol |
| `<Leader>sS` | 搜尋工作區符號 | 大 S = 全工作區 |

#### Git 操作

| 按鍵 | 功能 | 記法 |
|------|------|------|
| `<Leader>gg` | 開啟 lazygit | **g**it **g**o |
| `]h` / `[h` | 下一個 / 上一個 Git hunk | ] 往後 / [ 往前，**h**unk |
| `<Leader>ghs` | Stage hunk | **g**it **h**unk **s**tage |
| `<Leader>ghr` | Reset hunk | **g**it **h**unk **r**eset |

#### 其他實用功能

| 按鍵 | 功能 | 記法 |
|------|------|------|
| `<Leader>l` | Lazy 插件管理器 | **l**azy |
| `<Leader>cm` | Mason（LSP/工具安裝器） | **c**ode **m**ason |
| `<Leader>uf` | 切換自動格式化 | **u**I toggle **f**ormat |
| `<Leader>us` | 切換拼字檢查 | **u**I toggle **s**pell |
| `<Leader>uw` | 切換自動換行 | **u**I toggle **w**rap |

### 啟用的語言支援

透過 LazyVim Extras 啟用（`nvim/lazyvim.json`）：

| Extra | 提供功能 |
|-------|---------|
| `lang.python` | Pyright LSP + Ruff 格式化 + debugpy |
| `lang.typescript` | ts_ls LSP + 型別檢查 |
| `lang.rust` | rust-analyzer LSP + Cargo 整合 |
| `lang.php` | Intelephense LSP |
| `lang.json` | JSON Schema 驗證 |
| `lang.markdown` | Markdown 預覽 + 格式化 |
| `formatting.prettier` | Prettier 程式碼格式化 |
| `linting.eslint` | ESLint 整合 |

### 搜尋排除目錄

Telescope 和 Neo-tree 預設排除以下目錄，避免搜尋結果包含不相關的檔案：

```
node_modules/  target/  logs/  venv/  .venv/
.git/  dist/  build/  vendor/
```

### Markdown 特殊處理

Markdown 檔案預設**不自動格式化**，且保留行尾空白（Markdown 使用兩個空白表示 `<br>`）。

---

## 常見問題

### Neovim 首次啟動很慢？

首次啟動時 LazyVim 會自動下載所有插件和 LSP 伺服器。等待安裝完成後重啟即可。

### 如何安裝新的語言支援？

1. 啟動 Neovim
2. 輸入 `:LazyExtras` 瀏覽可用的 Extras
3. 選擇要啟用的語言，按 `x` 啟用
4. 重啟 Neovim

### 如何查看所有可用快鍵？

在 Normal 模式按下 `<Space>`（Leader 鍵），等待一秒，which-key 會顯示所有可用的快鍵選單。

### Vim 和 Neovim 的配置會互相影響嗎？

不會。Vim 讀取 `~/.vimrc`，Neovim 讀取 `~/.config/nvim/`，兩者完全獨立。
