return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
          layout = {
            layout = {
              position = "right",
            },
          },
          exclude = {
            ".git",
            "node_modules",
            "vendor",
            "dist",
            "build",
            "out",
            ".DS_Store",
          },
        },
      },
    },
  },
}
