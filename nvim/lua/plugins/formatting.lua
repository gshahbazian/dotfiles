local biome_fts = {
  "astro",
  "css",
  "graphql",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "svelte",
  "typescript",
  "typescriptreact",
  "vue",
}

local prettier_fts = {
  "css",
  "graphql",
  "handlebars",
  "html",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "less",
  "markdown",
  "markdown.mdx",
  "scss",
  "typescript",
  "typescriptreact",
  "vue",
  "yaml",
}

local formatters_by_ft = {
  lua = { "stylua" },
  sh = { "shfmt" },
}

-- ts get biome-organize-imports first
for _, ft in ipairs({ "typescript", "typescriptreact" }) do
  formatters_by_ft[ft] = { "biome-organize-imports" }
end

for _, ft in ipairs(biome_fts) do
  formatters_by_ft[ft] = formatters_by_ft[ft] or {}
  table.insert(formatters_by_ft[ft], "biome")
end

for _, ft in ipairs(prettier_fts) do
  formatters_by_ft[ft] = formatters_by_ft[ft] or {}
  table.insert(formatters_by_ft[ft], "prettier")
end

-- prettier requires config file
local function has_prettier_config(ctx)
  vim.fn.system({ "prettier", "--find-config-path", ctx.filename })
  return vim.v.shell_error == 0
end

require("conform").setup({
  formatters_by_ft = formatters_by_ft,
  default_format_opts = {
    timeout_ms = 3000,
    lsp_format = "fallback",
  },
  formatters = {
    injected = { options = { ignore_errors = true } },
    biome = { require_cwd = true },
    ["biome-organize-imports"] = { require_cwd = true },
    prettier = {
      condition = function(_, ctx)
        return has_prettier_config(ctx)
      end,
    },
  },
})

-- format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("pack_format_on_save", { clear = true }),
  callback = function(event)
    require("conform").format({ bufnr = event.buf })
  end,
})
