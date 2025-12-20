return {
  "folke/noice.nvim",
  opts = {
    lsp = {
      hover = {
        silent = true,
      },
    },
    cmdline = {
      enabled = false,
    },
    messages = {
      enabled = false,
    },
    notify = {
      enabled = true,
      view = "mini",
    },
    views = {
      mini = {
        position = {
          row = -2, -- move up 1 from bottom
        },
      },
    },
  },
  keys = {
    { "<leader>n", "<cmd>Noice history<cr>", desc = "Notification History" },
  },
}
