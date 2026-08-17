-- P0 語言工具補強；語言 Extra 仍是主要設定來源

return {
    {
        "neovim/nvim-lspconfig",
        init = function()
            vim.filetype.add({
                filename = {
                    ["compose.yaml"] = "yaml.docker-compose",
                    ["compose.yml"] = "yaml.docker-compose",
                    ["docker-compose.yaml"] = "yaml.docker-compose",
                    ["docker-compose.yml"] = "yaml.docker-compose",
                },
            })
        end,
        opts = {
            servers = {
                html = {},
                cssls = {},
                intelephense = { mason = false },
            },
        },
    },
}
