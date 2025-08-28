return {
  "neovim/nvim-lspconfig",
  opts = {
    diagnostics = {
      virtual_text = false,
      virtual_lines = true,
    },
    servers = {
      vtsls = {
        settings = {
          typescript = {
            preferences = {
              importModuleSpecifier = "non-relative",
            },
            inlayHints = {
              parameterNames = "all",
            },
          },
        },
      },
    },
  },
}
