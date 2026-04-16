vim.loader.enable(true)

_G.Config = {}

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
  "https://github.com/folke/snacks.nvim",
  "https://github.com/nvim-mini/mini.nvim",
  "https://github.com/gshahbazian/vesper.nvim",
}, { load = true })

vim.cmd.colorscheme("vesper")

require("config.keymaps")
require("config.autocmds")

-- lazy load helpers
local misc = require("mini.misc")
Config.now = function(f)
  misc.safely("now", f)
end
Config.later = function(f)
  misc.safely("later", f)
end
Config.now_if_args = vim.fn.argc(-1) > 0 and Config.now or Config.later
Config.on_event = function(ev, f)
  misc.safely("event:" .. ev, f)
end
Config.on_filetype = function(ft, f)
  misc.safely("filetype:" .. ft, f)
end

-- lazy load plugins

Config.now(function()
  require("plugins.snacks")
end)

Config.now_if_args(function()
  vim.pack.add({
    -- lines
    "https://github.com/akinsho/bufferline.nvim",
    "https://github.com/nvim-lualine/lualine.nvim",

    -- treesitter
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
    "https://github.com/nvim-treesitter/nvim-treesitter-context",

    -- lsp
    "https://github.com/neovim/nvim-lspconfig",
    "https://github.com/mason-org/mason.nvim",
    "https://github.com/mason-org/mason-lspconfig.nvim",

    -- ft specific
    "https://github.com/folke/lazydev.nvim",
    { src = "https://github.com/mrcjkb/rustaceanvim", version = vim.version.range("*") },
    "https://github.com/b0o/SchemaStore.nvim",
  })

  require("plugins.lines")
  require("plugins.treesitter")
  require("plugins.lsp")
  require("plugins.rust")
end)

Config.later(function()
  vim.pack.add({
    -- coding
    "https://github.com/folke/flash.nvim",
    "https://github.com/folke/ts-comments.nvim",

    -- editor
    "https://github.com/MunifTanjim/nui.nvim",
    "https://github.com/folke/noice.nvim",
    "https://github.com/folke/which-key.nvim",
    { src = "https://github.com/saghen/blink.cmp", version = vim.version.range("1.*") },
    "https://github.com/rafamadriz/friendly-snippets",
    "https://github.com/folke/trouble.nvim",
    { src = "https://github.com/lewis6991/gitsigns.nvim", version = vim.version.range("*") },
    "https://github.com/arnamak/stay-centered.nvim",
    "https://github.com/folke/persistence.nvim",

    -- formatting
    "https://github.com/stevearc/conform.nvim",
  })

  require("plugins.coding")
  require("plugins.editor")
  require("plugins.formatting")
end)
