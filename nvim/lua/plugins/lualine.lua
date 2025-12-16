return {
  "nvim-lualine/lualine.nvim",
  opts = {
    sections = {
      lualine_b = {},
      lualine_c = {
        { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
        { LazyVim.lualine.pretty_path() },
      },
      lualine_y = { "diagnostics" },
      lualine_z = { "branch" },
    },
  },
}
