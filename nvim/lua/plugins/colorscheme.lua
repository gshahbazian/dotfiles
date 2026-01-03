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
    end,
  },
}
