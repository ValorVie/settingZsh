-- 保留 Markdown 工具鏈，但不預設顯示 markdownlint 格式診斷

return {
    {
        "mfussenegger/nvim-lint",
        optional = true,
        opts = function(_, opts)
            opts.linters_by_ft = opts.linters_by_ft or {}
            opts.linters_by_ft.markdown = nil
            opts.linters_by_ft["markdown.mdx"] = nil
        end,
    },
}
