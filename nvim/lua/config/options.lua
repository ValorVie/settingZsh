-- 覆寫 LazyVim 預設選項，對齊 VSCode 使用習慣

-- 縮排（LazyVim 預設為 2）
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

-- 換行（LazyVim 預設為 false）
vim.opt.wrap = true

-- 預設使用絕對行號；<Leader>uL 可切換相對行號
vim.opt.number = true
vim.opt.relativenumber = false

-- 關閉滑鼠（LazyVim 預設為 "a"）
vim.opt.mouse = ""

-- SSH 終端自動偵測失敗時，明確使用內建 OSC 52 provider
if vim.env.SSH_CONNECTION or vim.env.SSH_TTY then
    vim.g.clipboard = "osc52"
end

-- 檔案格式
vim.opt.fileformat = "unix"
vim.opt.fixendofline = true
