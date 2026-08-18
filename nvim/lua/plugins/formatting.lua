local oxfmt_fts = {
  "css",
  "html",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "typescript",
  "typescriptreact",
}

local formatters_by_ft = {
  lua = { "stylua" },
  sh = { "shfmt" },
  ["_"] = { "trim_whitespace", "trim_newlines" },
}

for _, ft in ipairs(oxfmt_fts) do
  formatters_by_ft[ft] = { "oxfmt" }
end

require("conform").setup({
  formatters_by_ft = formatters_by_ft,
  default_format_opts = {
    timeout_ms = 3000,
    lsp_format = "fallback",
  },
  formatters = {
    injected = { options = { ignore_errors = true } },
    oxfmt = {
      require_cwd = true,
    },
  },
})

-- format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(event)
    require("conform").format({ bufnr = event.buf })
  end,
})
