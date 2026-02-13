return {
  {
    "nexxeln/vesper.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("vesper")

      vim.api.nvim_set_hl(0, "LspInlayHint", { bg = "#000000", fg = "#5c5c5c" })
      vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#262626" })
      vim.api.nvim_set_hl(0, "SnacksIndent", { fg = "#323232" })
      vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = "#888888" })
      vim.api.nvim_set_hl(0, "CursorLine", { bg = "#1c1c1c" })

      -- matches my custom ghostty theme palette based on vesper
      vim.g.terminal_color_0 = "#101010"
      vim.g.terminal_color_1 = "#ff8080"
      vim.g.terminal_color_2 = "#99ffe4"
      vim.g.terminal_color_3 = "#ffc799"
      vim.g.terminal_color_4 = "#a0a0a0"
      vim.g.terminal_color_5 = "#ffc799"
      vim.g.terminal_color_6 = "#99ffe4"
      vim.g.terminal_color_7 = "#ffffff"
      vim.g.terminal_color_8 = "#505050"
      vim.g.terminal_color_9 = "#ff9999"
      vim.g.terminal_color_10 = "#b3ffe4"
      vim.g.terminal_color_11 = "#ffd1a8"
      vim.g.terminal_color_12 = "#b0b0b0"
      vim.g.terminal_color_13 = "#ffc799"
      vim.g.terminal_color_14 = "#66ddcc"
      vim.g.terminal_color_15 = "#ffffff"
    end,
  },
}
