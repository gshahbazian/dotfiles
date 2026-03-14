require("config.options")

-- PackChanged hook (MUST be before vim.pack.add)
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind

    if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
      if not ev.data.active then
        vim.cmd.packadd("nvim-treesitter")
      end
      vim.cmd("TSUpdate")
    end
  end,
})

-- Install and load all plugins
vim.pack.add({
  -- Colorschemes
  "https://github.com/gshahbazian/vesper.nvim",

  -- Core UI
  "https://github.com/folke/snacks.nvim",
  "https://github.com/akinsho/bufferline.nvim",
  "https://github.com/nvim-lualine/lualine.nvim",
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/folke/noice.nvim",
  "https://github.com/folke/which-key.nvim",
  "https://github.com/nvim-mini/mini.icons",

  -- Editor
  "https://github.com/folke/flash.nvim",
  "https://github.com/folke/trouble.nvim",
  "https://github.com/folke/todo-comments.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/arnamak/stay-centered.nvim",

  -- Coding
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.9") },
  "https://github.com/rafamadriz/friendly-snippets",
  "https://github.com/nvim-mini/mini.ai",
  "https://github.com/nvim-mini/mini.surround",
  "https://github.com/folke/ts-comments.nvim",
  "https://github.com/folke/lazydev.nvim",

  -- Treesitter
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
  "https://github.com/nvim-treesitter/nvim-treesitter-context",

  -- LSP
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/mason-org/mason-lspconfig.nvim",

  -- Formatting & Linting
  "https://github.com/stevearc/conform.nvim",
  "https://github.com/mfussenegger/nvim-lint",

  -- Lang
  "https://github.com/mrcjkb/rustaceanvim",
  "https://github.com/Saecki/crates.nvim",
  "https://github.com/b0o/SchemaStore.nvim",

  -- Util
  "https://github.com/folke/persistence.nvim",
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-mini/mini.hipatterns",
}, {
  load = true,
})

-- Configure plugins
require("plugins.colorscheme")
require("plugins.ui")
require("plugins.editor")
require("plugins.coding")
require("plugins.treesitter")
require("plugins.lsp")
require("plugins.formatting")
require("plugins.linting")
require("plugins.lang")

-- Keymaps & autocmds last (depend on plugins being configured)
require("config.keymaps")
require("config.autocmds")
