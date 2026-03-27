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

for _, ft in ipairs(biome_fts) do
  formatters_by_ft[ft] = formatters_by_ft[ft] or {}
  table.insert(formatters_by_ft[ft], "biome-check")
end

for _, ft in ipairs(prettier_fts) do
  formatters_by_ft[ft] = formatters_by_ft[ft] or {}
  table.insert(formatters_by_ft[ft], "prettier")
end

local prettier_config_cache = {}
local function has_prettier_config(ctx)
  if prettier_config_cache[ctx.filename] == nil then
    vim.fn.system({ "prettier", "--find-config-path", ctx.filename })
    prettier_config_cache[ctx.filename] = vim.v.shell_error == 0
  end
  return prettier_config_cache[ctx.filename]
end

require("conform").setup({
  formatters_by_ft = formatters_by_ft,
  default_format_opts = {
    timeout_ms = 3000,
    lsp_format = "fallback",
  },
  formatters = {
    injected = { options = { ignore_errors = true } },
    ["biome-check"] = { require_cwd = true },
    prettier = {
      condition = function(_, ctx)
        return has_prettier_config(ctx)
      end,
    },
  },
})

-- format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  callback = function(event)
    require("conform").format({ bufnr = event.buf })
  end,
})
