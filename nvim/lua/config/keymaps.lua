-- 自訂快鍵
-- LazyVim 已內建豐富的快鍵，此處僅加入額外的自訂映射

-- jk 快速退出 insert mode
vim.keymap.set("i", "jk", "<Esc>", { desc = "Exit insert mode" })

local paths = require("config.path")

vim.keymap.set("n", "<Leader>yp", function()
    paths.copy_buffer()
end, { desc = "Copy Project-Relative Path" })

vim.keymap.set("n", "<Leader>yL", function()
    paths.copy_buffer({ with_line = true })
end, { desc = "Copy Project-Relative Path with Line" })
