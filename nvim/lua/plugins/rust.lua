vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, {
  server = {
    on_attach = function(_, bufnr)
      vim.keymap.set("n", "<leader>ca", function()
        vim.cmd.RustLsp("codeAction")
      end, { desc = "Rust Code Action", buffer = bufnr })
    end,

    default_settings = {
      ["rust-analyzer"] = {
        cargo = {
          allFeatures = true,
          loadOutDirsFromCheck = true,
        },
        files = {
          exclude = {
            ".direnv",
            ".git",
            ".jj",
            ".github",
            ".gitlab",
            "bin",
            "node_modules",
            "target",
            "venv",
            ".venv",
          },
          watcher = "client",
        },
      },
    },
  },
})
