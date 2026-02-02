-- 覆寫 LazyVim 預設選項，對齊 VSCode 使用習慣

-- 縮排（LazyVim 預設為 2）
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

-- 換行（LazyVim 預設為 false）
vim.opt.wrap = true

-- 關閉滑鼠（LazyVim 預設為 "a"）
vim.opt.mouse = ""

-- 檔案格式
vim.opt.fileformat = "unix"
vim.opt.fixendofline = true
