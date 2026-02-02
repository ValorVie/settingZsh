-- 自訂快鍵
-- LazyVim 已內建豐富的快鍵，此處僅加入額外的自訂映射

-- jk 快速退出 insert mode
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })
