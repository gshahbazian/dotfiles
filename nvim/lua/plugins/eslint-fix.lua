return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      eslint = {
        -- needed this cause plaza/bakery has eslint without a config file
        root_dir = require("lspconfig.util").root_pattern("package.json", ".git"),
      },
    },
  },
}
