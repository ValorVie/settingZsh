" =============================================================================
" Vim 精簡配置（伺服器 fallback 用，無外部插件依賴）
" =============================================================================

" --- 基礎體驗 ---
syntax on               " 開啟語法高亮
set number              " 顯示行號
set relativenumber      " 顯示相對行號
set wrap                " 自動折行
set encoding=utf-8      " 設定編碼
set mouse=              " 關閉攔截滑鼠
set clipboard=unnamed,unnamedplus " 共用系統剪貼簿（跨平台相容）
set backspace=indent,eol,start    " 讓 Backspace 正常運作

" --- 縮排與 Tab ---
set tabstop=4           " Tab 寬度為 4
set shiftwidth=4        " 自動縮排寬度為 4
set softtabstop=4       " 插入模式 Tab 寬度為 4
set expandtab           " 將 Tab 轉換為空白字元
set autoindent          " 換行時自動縮排

" --- 搜尋設定 ---
set ignorecase          " 搜尋時忽略大小寫
set smartcase           " 如果搜尋包含大寫，則強制區分大小寫
set hlsearch            " 高亮搜尋結果
set incsearch           " 邊打字邊搜尋

" --- 外觀 ---
set cursorline          " 高亮目前所在的行
set termguicolors       " 啟用真彩色支援
set scrolloff=8         " 游標距離螢幕上下邊緣至少 8 行
set sidescrolloff=8     " 水平方向同理
set signcolumn=yes      " 永遠顯示 sign 欄
set updatetime=250      " 降低更新延遲

" --- 實用設定 ---
set undofile            " 持久化 undo 歷史
set splitright          " 新分割視窗開在右邊
set splitbelow          " 新分割視窗開在下面
set list                " 顯示不可見字元
set listchars=tab:»\ ,trail:·,nbsp:␣
set fileformat=unix     " 預設使用 Unix 換行
set fixendofline        " 確保檔案結尾有換行
