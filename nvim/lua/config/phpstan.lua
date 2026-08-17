local M = {}

local config_files = {
    "phpstan.neon",
    "phpstan.neon.dist",
    "phpstan.dist.neon",
}

function M.available(root)
    if not root or root == "" then
        return false
    end
    local binary = vim.fs.joinpath(root, "vendor", "bin", "phpstan")
    if vim.fn.executable(binary) ~= 1 then
        return false
    end
    for _, name in ipairs(config_files) do
        if vim.uv.fs_stat(vim.fs.joinpath(root, name)) then
            return true
        end
    end
    return false
end

function M.try_lint(buf)
    local root = LazyVim.root({ buf = buf, normalize = true })
    if M.available(root) then
        require("lint").try_lint("phpstan", { cwd = root })
    end
end

return M
