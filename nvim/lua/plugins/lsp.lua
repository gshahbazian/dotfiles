vim.filetype.add({
  filename = {
    ["Tiltfile"] = "python",
  },
  pattern = {
    [".*/%.vscode/.*%.json"] = "jsonc",
    [".*/%.?zed/.*%.json"] = "jsonc",
  },
})

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

    -- lsp pickers
    vim.keymap.set("n", "gd", function()
      Snacks.picker.lsp_definitions()
    end, { buffer = buf, desc = "Goto Definition", silent = true })
    vim.keymap.set("n", "<leader>rd", function()
      Snacks.picker.lsp_definitions()
    end, { buffer = buf, desc = "Goto Definition", silent = true })
    vim.keymap.set("n", "<leader>rr", function()
      Snacks.picker.lsp_references()
    end, { buffer = buf, desc = "References", silent = true })
    vim.keymap.set("n", "<leader>rI", function()
      Snacks.picker.lsp_implementations()
    end, { buffer = buf, desc = "Goto Implementation", silent = true })
    vim.keymap.set("n", "<leader>ry", function()
      Snacks.picker.lsp_type_definitions()
    end, { buffer = buf, desc = "Goto T[y]pe Definition", silent = true })

    -- default lsp keymaps listed here
    -- https://neovim.io/doc/user/lsp/#_global-defaults

    vim.keymap.set("n", "<leader>cR", function()
      Snacks.rename.rename_file()
    end, { buffer = buf, desc = "Rename File", silent = true })
    vim.keymap.set("n", "<leader>cl", function()
      Snacks.picker.lsp_config()
    end, { buffer = buf, desc = "Lsp Info", silent = true })

    local function code_action(action)
      return function()
        vim.lsp.buf.code_action({
          apply = true,
          context = { only = { action }, diagnostics = {} },
        })
      end
    end

    vim.keymap.set("n", "<leader>co", code_action("source.organizeImports"), {
      buffer = buf,
      desc = "Organize Imports",
      silent = true,
    })

    if client.name == "vtsls" then
      vim.keymap.set("n", "<leader>cM", code_action("source.addMissingImports.ts"), {
        buffer = buf,
        desc = "Add missing imports",
        silent = true,
      })
      vim.keymap.set("n", "<leader>cD", code_action("source.fixAll.ts"), {
        buffer = buf,
        desc = "Fix all diagnostics",
        silent = true,
      })
    end
  end,
})
