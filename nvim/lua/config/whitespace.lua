local M = {}

function M.should_trim(buf)
    if not vim.api.nvim_buf_is_valid(buf) then
        return false
    end
    if vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable or vim.bo[buf].readonly or vim.bo[buf].binary then
        return false
    end
    if vim.bo[buf].filetype == "markdown" then
        return false
    end
    local editorconfig = vim.b[buf].editorconfig
    if type(editorconfig) == "table" and editorconfig.trim_trailing_whitespace ~= nil then
        return false
    end
    return true
end

function M.trim(buf)
    if not M.should_trim(buf) then
        return false
    end

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local changed = false
    for index, line in ipairs(lines) do
        local trimmed = line:gsub("%s+$", "")
        if trimmed ~= line then
            lines[index] = trimmed
            changed = true
        end
    end
    if not changed then
        return false
    end

    local current_window = vim.api.nvim_get_current_win()
    local restore_view = vim.api.nvim_win_get_buf(current_window) == buf
    local view = restore_view and vim.fn.winsaveview() or nil
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    if view then
        vim.fn.winrestview(view)
    end
    return true
end

return M
