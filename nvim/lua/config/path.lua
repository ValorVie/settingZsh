local M = {}

local function normalize(path)
    if not path or path == "" then
        return nil
    end
    return vim.fs.normalize(vim.fn.fnamemodify(path, ":p")):gsub("\\", "/")
end

function M.relative(path, root)
    path = normalize(path)
    root = normalize(root)
    if not path then
        return nil
    end
    local relative = root and vim.fs.relpath(root, path) or nil
    return (relative or path):gsub("\\", "/")
end

function M.format(path, opts)
    opts = opts or {}
    local value = M.relative(path, opts.root)
    if not value then
        return nil
    end
    if opts.line then
        value = ("%s:%d"):format(value, opts.line)
    end
    return value
end

function M.copy(path, opts)
    opts = opts or {}
    local value = M.format(path, opts)
    if not value then
        vim.notify("目前 buffer 沒有可複製的檔案路徑", vim.log.levels.WARN)
        return false
    end
    vim.fn.setreg(opts.register or "+", value, "c")
    return true, value
end

function M.copy_buffer(opts)
    opts = opts or {}
    local buf = opts.buf or vim.api.nvim_get_current_buf()
    local path = vim.api.nvim_buf_get_name(buf)
    local root = opts.root or LazyVim.root({ buf = buf, normalize = true })
    local line = opts.with_line and vim.api.nvim_win_get_cursor(0)[1] or nil
    return M.copy(path, { root = root, line = line, register = opts.register })
end

return M
