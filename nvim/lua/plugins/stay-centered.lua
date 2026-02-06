return {
  "arnamak/stay-centered.nvim",
  lazy = false,
  name = "stay-centered",
  vscode = false,
  priority = 1000,
  opts = {
    enabled = true,
  },
  config = function(_, opts)
    require("stay-centered").setup(opts)
  end,
}
