-- Markdown 例外設定：保留行尾空白（Markdown 以兩個空白表示換行）
vim.b.autoformat = false

-- 禁止 LazyVim 的 trim whitespace 對 markdown 生效
vim.api.nvim_create_autocmd("BufWritePre", {
  buffer = 0,
  callback = function()
    -- 覆蓋 trim trailing whitespace，不做任何事
  end,
})
