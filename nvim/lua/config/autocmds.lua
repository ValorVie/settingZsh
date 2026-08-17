-- 專案有鎖定版本與設定時，才執行 PHPStan
vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.php",
    callback = function(event)
        require("config.phpstan").try_lint(event.buf)
    end,
})

-- 專案沒有 EditorConfig 規則時，清除一般文字檔的行尾空白
vim.api.nvim_create_autocmd("BufWritePre", {
    callback = function(event)
        require("config.whitespace").trim(event.buf)
    end,
})
