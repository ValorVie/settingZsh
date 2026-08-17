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
if empty($SSH_CONNECTION) && empty($SSH_TTY)
    set clipboard=unnamed,unnamedplus " 本機 Vim 使用原生系統剪貼簿
else
    set clipboard=                    " SSH 明確使用下方 OSC 52 mapping
endif
set backspace=indent,eol,start    " 讓 Backspace 正常運作

" --- SSH OSC 52 剪貼簿 ---
if !empty($SSH_CONNECTION) || !empty($SSH_TTY)
    function! s:OSC52Send(text) abort
        if !executable('base64')
            echohl ErrorMsg
            echom 'OSC 52 複製失敗：找不到 base64'
            echohl None
            return
        endif

        let l:b64 = substitute(system('base64', a:text), '\_s', '', 'g')
        if v:shell_error != 0
            echohl ErrorMsg
            echom 'OSC 52 複製失敗：base64 執行錯誤'
            echohl None
            return
        endif

        let l:tty = get(g:, 'settingzsh_osc52_tty', '/dev/tty')
        call writefile(["\033]52;c;" . l:b64 . "\007"], l:tty, 'b')
    endfunction

    function! s:OSC52Operator(type) abort
        if a:type ==# 'line'
            silent normal! `[V`]y
        elseif a:type ==# 'block'
            silent execute "normal! `[\<C-V>`]y"
        else
            silent normal! `[v`]y
        endif
        call s:OSC52Send(getreg('"'))
    endfunction

    function! s:OSC52Start() abort
        let &operatorfunc = '<SID>OSC52Operator'
        return 'g@'
    endfunction

    function! s:OSC52Line() abort
        silent normal! yy
        call s:OSC52Send(getreg('"'))
    endfunction

    " Normal mode：\"+y{motion}
    nnoremap <expr> "+y <SID>OSC52Start()

    " Normal mode 整行：\"+yy
    nnoremap <silent> "+yy :<C-U>call <SID>OSC52Line()<CR>

    " Visual 選取後：\"+y
    xnoremap <silent> "+y y:<C-U>call <SID>OSC52Send(getreg('"'))<CR>
endif

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
