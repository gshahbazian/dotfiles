vim.loader.enable(true)

require("config.options")

if vim.g.vscode then
  require("utils.vscode").setup()
  return
end

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

vim.pack.add({
  "https://github.com/gshahbazian/vesper.nvim",

  -- ui
  "https://github.com/folke/snacks.nvim",
  "https://github.com/akinsho/bufferline.nvim",
  "https://github.com/nvim-lualine/lualine.nvim",
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/folke/noice.nvim",
  "https://github.com/folke/which-key.nvim",
  "https://github.com/nvim-mini/mini.icons",
  "https://github.com/folke/persistence.nvim",

  -- editor
  "https://github.com/folke/flash.nvim",
  "https://github.com/folke/trouble.nvim",
  "https://github.com/folke/todo-comments.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/arnamak/stay-centered.nvim",

  -- coding
  { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
  "https://github.com/rafamadriz/friendly-snippets",
  "https://github.com/nvim-mini/mini.ai",
  "https://github.com/nvim-mini/mini.surround",
  "https://github.com/folke/ts-comments.nvim",
  "https://github.com/folke/lazydev.nvim",

  -- treesitter
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
  "https://github.com/nvim-treesitter/nvim-treesitter-context",

  -- lsp
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/mason-org/mason.nvim",
  "https://github.com/mason-org/mason-lspconfig.nvim",
  "https://github.com/stevearc/conform.nvim",

  -- lang
  "https://github.com/mrcjkb/rustaceanvim",
  "https://github.com/Saecki/crates.nvim",
  "https://github.com/b0o/SchemaStore.nvim",
  "https://github.com/nvim-mini/mini.hipatterns",
}, {
  load = true,
})

require("plugins.colorscheme")
require("plugins.ui")
require("plugins.editor")
require("plugins.coding")
require("plugins.treesitter")
require("plugins.lsp")
require("plugins.formatting")
require("plugins.lang")
require("config.keymaps")
require("config.autocmds")
