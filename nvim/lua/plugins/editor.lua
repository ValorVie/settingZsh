-- 編輯器插件覆寫：統一 VS Code 的 search.exclude 和 files.exclude 意圖

local excludes = {
    ".git",
    ".cache",
    ".pytest_cache",
    ".terraform",
    ".venv",
    ".worktrees",
    "__pycache__",
    "build",
    "coverage",
    "dist",
    "logs",
    "node_modules",
    "target",
    "vendor",
    "venv",
}

local paths = require("config.path")

local function explorer_path(picker)
    local items = picker:selected({ fallback = true })
    return items[1] and Snacks.picker.util.path(items[1]) or nil
end

local function copy_explorer_path(relative)
    return function(picker)
        local file = explorer_path(picker)
        local root = relative and LazyVim.root({ normalize = true }) or nil
        paths.copy(file, { root = root })
    end
end

return {
    {
        "folke/snacks.nvim",
        opts = {
            picker = {
                actions = {
                    copy_absolute_path = copy_explorer_path(false),
                    copy_relative_path = copy_explorer_path(true),
                },
                sources = {
                    files = { exclude = excludes, follow = false },
                    grep = { exclude = excludes, follow = false },
                    explorer = {
                        exclude = excludes,
                        follow = false,
                        win = {
                            list = {
                                keys = {
                                    ["Y"] = "copy_absolute_path",
                                    ["gY"] = "copy_relative_path",
                                },
                            },
                        },
                    },
                },
            },
        },
    },
}
