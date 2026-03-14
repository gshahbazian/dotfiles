-- Diagnostics
vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
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

-- Mason
require("mason").setup({})

-- ensure mason tools are installed
local mr = require("mason-registry")
mr.refresh(function()
  for _, tool in ipairs({ "stylua", "shfmt", "prettier", "biome", "shellcheck" }) do
    local p = mr.get_package(tool)
    if not p:is_installed() then
      p:install()
    end
  end
end)

-- mason-lspconfig
require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "vtsls", "eslint", "jsonls", "tailwindcss", "bashls" },
  automatic_enable = {
    exclude = { "rust_analyzer" },
  },
})

-- Server configs
vim.lsp.config("*", {
  capabilities = {
    workspace = {
      fileOperations = {
        didRename = true,
        willRename = true,
      },
    },
  },
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      workspace = { checkThirdParty = false },
      codeLens = { enable = true },
      completion = { callSnippet = "Replace" },
      doc = { privateName = { "^_" } },
      hint = {
        enable = true,
        setType = false,
        paramType = true,
        paramName = "Disable",
        semicolon = "Disable",
        arrayIndex = "Disable",
      },
    },
  },
})

local vtsls_settings = {
  complete_function_calls = true,
  vtsls = {
    enableMoveToFileCodeAction = true,
    autoUseWorkspaceTsdk = true,
    experimental = {
      maxInlayHintLength = 30,
      completion = { enableServerSideFuzzyMatch = true },
    },
  },
  typescript = {
    updateImportsOnFileMove = { enabled = "always" },
    suggest = { completeFunctionCalls = true },
    preferences = {
      importModuleSpecifier = "non-relative",
      preferTypeOnlyAutoImports = true,
    },
    inlayHints = {
      enumMemberValues = { enabled = true },
      functionLikeReturnTypes = { enabled = true },
      parameterNames = { enabled = "literals" },
      parameterTypes = { enabled = true },
      propertyDeclarationTypes = { enabled = true },
      variableTypes = { enabled = true, suppressWhenTypeMatchesName = false },
    },
  },
}

vtsls_settings.javascript = vim.tbl_deep_extend("force", {}, vtsls_settings.typescript, vtsls_settings.javascript or {})

vim.lsp.config("vtsls", {
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  settings = vtsls_settings,
})

vim.lsp.config("eslint", {
  settings = {
    workingDirectories = { mode = "auto" },
    format = false,
  },
})

vim.lsp.config("jsonls", {
  before_init = function(_, new_config)
    new_config.settings.json.schemas = new_config.settings.json.schemas or {}
    vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
  end,
  settings = {
    json = {
      format = { enable = true },
      validate = { enable = true },
    },
  },
})

vim.lsp.config("tailwindcss", {
  settings = {
    tailwindCSS = {
      includeLanguages = {
        elixir = "html-eex",
        eelixir = "html-eex",
        heex = "html-eex",
      },
    },
  },
})

vim.lsp.config("bashls", {})

-- rust_analyzer is disabled — rustaceanvim handles it
vim.lsp.config("rust_analyzer", { enabled = false })

-- Enable servers not handled by mason-lspconfig
-- (mason-lspconfig's automatic_enable handles the rest)

-- Inlay hints & LSP keymaps via LspAttach
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("pack_lsp_attach", { clear = true }),
  callback = function(ev)
    local buf = ev.buf
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end

    -- Enable inlay hints
    if client:supports_method("textDocument/inlayHint") then
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" then
        vim.lsp.inlay_hint.enable(true, { bufnr = buf })
      end
    end

    -- LSP keymaps
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
    map("n", "K", vim.lsp.buf.hover, "Hover")
    map("n", "gK", vim.lsp.buf.signature_help, "Signature Help")
    map("i", "<c-k>", vim.lsp.buf.signature_help, "Signature Help")
    map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
    map({ "n", "x" }, "<leader>cc", vim.lsp.codelens.run, "Run Codelens")
    map("n", "<leader>cC", vim.lsp.codelens.refresh, "Refresh & Display Codelens")
    map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
    map("n", "<leader>cR", function()
      Snacks.rename.rename_file()
    end, "Rename File")
    map("n", "<leader>cl", function()
      Snacks.picker.lsp_config()
    end, "Lsp Info")

    -- TypeScript-specific keymaps
    if client.name == "vtsls" then
      local function code_action(action)
        return function()
          vim.lsp.buf.code_action({
            apply = true,
            context = { only = { action }, diagnostics = {} },
          })
        end
      end

      map("n", "<leader>co", code_action("source.organizeImports"), "Organize Imports")
      map("n", "<leader>cM", code_action("source.addMissingImports.ts"), "Add missing imports")
      map("n", "<leader>cu", code_action("source.removeUnused.ts"), "Remove unused imports")
      map("n", "<leader>cD", code_action("source.fixAll.ts"), "Fix all diagnostics")
      map("n", "gD", function()
        local win = vim.api.nvim_get_current_win()
        local params = vim.lsp.util.make_position_params(win, "utf-16")
        client:request("workspace/executeCommand", {
          command = "typescript.goToSourceDefinition",
          arguments = { params.textDocument.uri, params.position },
        }, function(_, result)
          if result and #result > 0 then
            vim.lsp.util.show_document(result[1], "utf-16")
          end
        end)
      end, "Goto Source Definition")
      map("n", "gR", function()
        client:request("workspace/executeCommand", {
          command = "typescript.findAllFileReferences",
          arguments = { vim.uri_from_bufnr(0) },
        }, function(_, result)
          if result then
            vim.fn.setqflist({}, " ", { title = "File References", items = vim.lsp.util.locations_to_items(result, "utf-16") })
            vim.cmd("copen")
          end
        end)
      end, "File References")
    end
  end,
})
