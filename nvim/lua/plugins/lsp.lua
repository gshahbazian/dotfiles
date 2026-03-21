vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = { current_line = true },
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.HINT] = " ",
      [vim.diagnostic.severity.INFO] = " ",
    },
  },
})

require("mason").setup()

local mr = require("mason-registry")
mr.refresh(function()
  for _, tool in ipairs({ "stylua", "shfmt", "prettier", "biome", "shellcheck" }) do
    local p = mr.get_package(tool)
    if not p:is_installed() then
      p:install()
    end
  end
end)

require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "vtsls", "eslint", "jsonls", "tailwindcss", "bashls" },
  automatic_enable = {
    exclude = { "rust_analyzer" },
  },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("pack_lsp_attach", { clear = true }),
  callback = function(ev)
    local buf = ev.buf
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end

    -- inlay hints
    if client:supports_method("textDocument/inlayHint") then
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" then
        vim.lsp.inlay_hint.enable(true, { bufnr = buf })
      end
    end

    -- keymaps
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, silent = true })
    end

    map("n", "gd", function()
      Snacks.picker.lsp_definitions()
    end, "Goto Definition")
    map("n", "gr", function()
      Snacks.picker.lsp_references()
    end, "References")
    map("n", "gI", function()
      Snacks.picker.lsp_implementations()
    end, "Goto Implementation")
    map("n", "gy", function()
      Snacks.picker.lsp_type_definitions()
    end, "Goto T[y]pe Definition")
    map("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
    map("n", "gK", vim.lsp.buf.signature_help, "Signature Help")
    map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
    map({ "n", "x" }, "<leader>cc", vim.lsp.codelens.run, "Run Codelens")
    map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
    map("n", "<leader>cR", function()
      Snacks.rename.rename_file()
    end, "Rename File")
    map("n", "<leader>cl", function()
      Snacks.picker.lsp_config()
    end, "Lsp Info")

    local function code_action(action)
      return function()
        vim.lsp.buf.code_action({
          apply = true,
          context = { only = { action }, diagnostics = {} },
        })
      end
    end

    map("n", "<leader>co", code_action("source.organizeImports"), "Organize Imports")

    if client.name == "vtsls" then
      map("n", "<leader>cM", code_action("source.addMissingImports.ts"), "Add missing imports")
      map("n", "<leader>cD", code_action("source.fixAll.ts"), "Fix all diagnostics")
    end
  end,
})
