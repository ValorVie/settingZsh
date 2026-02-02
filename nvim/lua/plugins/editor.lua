-- 編輯器插件覆寫：對齊 VSCode 的 search.exclude 和 files.exclude

return {
  -- Telescope: 搜尋排除
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        file_ignore_patterns = {
          "node_modules",
          "target",
          "logs",
          "venv",
          "%.venv",
          "%.git/",
          "dist",
          "build",
          "vendor",
        },
      },
    },
  },

  -- Neo-tree: 檔案總管排除
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      filesystem = {
        filtered_items = {
          visible = false,
          hide_dotfiles = false,
          hide_gitignored = true,
          hide_by_name = {
            ".git",
            ".DS_Store",
            "node_modules",
            "target",
            "Thumbs.db",
            "desktop.ini",
            "$RECYCLE.BIN",
            "System Volume Information",
            "bower_components",
          },
        },
      },
    },
  },
}
