-- mini.icons
require("mini.icons").setup({
  file = {
    [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
    ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
    [".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
    [".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
    [".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
    [".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
    ["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
    ["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
    ["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
    ["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
    ["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
  },
  filetype = {
    dotenv = { glyph = "", hl = "MiniIconsYellow" },
  },
})
package.preload["nvim-web-devicons"] = function()
  require("mini.icons").mock_nvim_web_devicons()
  return package.loaded["nvim-web-devicons"]
end

-- snacks.nvim
Snacks.setup({
  bigfile = { enabled = true },
  quickfile = { enabled = true },
  indent = { enabled = true },
  input = { enabled = true },
  scope = { enabled = true },
  words = { enabled = true },
  statuscolumn = { enabled = true },
  lazygit = {
    theme = {
      inactiveBorderColor = { fg = "FoldColumn" },
    },
  },
  picker = {
    hidden = true,
    ignored = true,
    exclude = {
      ".git",
      "node_modules",
      "vendor",
      "dist",
      "out",
      ".DS_Store",
      ".next",
    },
    sources = {
      files = {
        hidden = true,
        ignored = true,
      },
      explorer = {
        layout = {
          layout = {
            position = "right",
          },
        },
      },
    },
  },
  explorer = { enabled = true },
  dashboard = {
    enabled = true,
    width = 20,
    preset = {
      keys = {
        { icon = "", key = "s", desc = "[s]ession resume", action = [[<cmd>lua require("persistence").load()<cr>]] },
        { icon = "", key = "e", desc = "[e]xplorer", action = "<leader>e" },
        { icon = "", key = "r", desc = "[r]ecent", action = "<leader>fr" },
        { icon = "", key = "q", desc = "[q]uit", action = ":qa" },
      },
      header = [[
                                                                   
      ████ ██████           █████      ██                    
     ███████████             █████                            
     █████████ ███████████████████ ███   ███████████  
    █████████  ███    █████████████ █████ ██████████████  
   █████████ ██████████ █████████ █████ █████ ████ █████  
 ███████████ ███    ███ █████████ █████ █████ ████ █████ 
██████  █████████████████████ ████ █████ █████ ████ ██████
]],
    },
    formats = {
      key = { "" },
    },
    sections = {
      { section = "header" },
      { section = "keys" },
    },
  },
})

-- bufferline
require("bufferline").setup({
  options = {
    close_command = function(n)
      Snacks.bufdelete(n)
    end,
    right_mouse_command = function(n)
      Snacks.bufdelete(n)
    end,
    show_buffer_close_icons = false,
    show_close_icon = false,
    diagnostics = "nvim_lsp",
    always_show_bufferline = false,
    diagnostics_indicator = function(_, _, diag)
      local ret = (diag.error and " " .. diag.error .. " " or "") .. (diag.warning and " " .. diag.warning or "")
      return vim.trim(ret)
    end,
    offsets = {
      { filetype = "snacks_layout_box" },
    },
  },
})
-- fix bufferline when restoring a session
vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
  callback = function()
    vim.schedule(function()
      pcall(require("bufferline").refresh)
    end)
  end,
})

-- lualine
vim.g.lualine_laststatus = vim.o.laststatus
if vim.fn.argc(-1) > 0 then
  vim.o.statusline = " "
else
  vim.o.laststatus = 0
end

local lualine_require = require("lualine_require")
lualine_require.require = require
vim.o.laststatus = vim.g.lualine_laststatus

require("lualine").setup({
  options = {
    theme = "auto",
    globalstatus = vim.o.laststatus == 3,
    disabled_filetypes = { statusline = { "dashboard", "snacks_dashboard" } },
    section_separators = { left = "", right = "" },
    component_separators = { left = "", right = "" },
  },
  sections = {
    lualine_a = { "mode" },
    lualine_b = {},
    lualine_c = {
      { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
      { "filename", path = 1 },
    },
    lualine_x = {
      Snacks.profiler.status(),
      -- stylua: ignore
      {
        function() return require("noice").api.status.command.get() end,
        cond = function() return package.loaded["noice"] and require("noice").api.status.command.has() end,
        color = function() return { fg = Snacks.util.color("Statement") } end,
      },
      -- stylua: ignore
      {
        function() return require("noice").api.status.mode.get() end,
        cond = function() return package.loaded["noice"] and require("noice").api.status.mode.has() end,
        color = function() return { fg = Snacks.util.color("Constant") } end,
      },
      {
        "diff",
        symbols = {
          added = " ",
          modified = " ",
          removed = " ",
        },
        source = function()
          local gitsigns = vim.b.gitsigns_status_dict
          if gitsigns then
            return {
              added = gitsigns.added,
              modified = gitsigns.changed,
              removed = gitsigns.removed,
            }
          end
        end,
      },
    },
    lualine_y = { "diagnostics" },
    lualine_z = { "branch" },
  },
  extensions = {},
})

-- noice
require("noice").setup({
  lsp = {
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
    },
    hover = {
      silent = true,
    },
  },
  routes = {
    {
      filter = {
        event = "msg_show",
        any = {
          { find = "%d+L, %d+B" },
          { find = "; after #%d+" },
          { find = "; before #%d+" },
        },
      },
      view = "mini",
    },
  },
  cmdline = { enabled = false },
  messages = { enabled = false },
  notify = {
    enabled = true,
    view = "mini",
  },
  views = {
    mini = {
      position = { row = -2 },
    },
  },
  presets = {
    bottom_search = true,
    long_message_to_split = true,
  },
})

-- which-key
require("which-key").setup({
  preset = "helix",
  icons = {
    mappings = false,
  },
  spec = {
    {
      mode = { "n", "x" },
      { "<leader><tab>", group = "tabs" },
      { "<leader>c", group = "code" },
      { "<leader>f", group = "file" },
      { "<leader>g", group = "git" },
      { "<leader>gh", group = "hunks" },
      { "<leader>j", group = "util" },
      { "<leader>l", group = "vim.pack" },
      { "<leader>q", group = "quit/session" },
      { "<leader>s", group = "search" },
      { "<leader>x", group = "diagnostics/quickfix" },
      { "[", group = "prev" },
      { "]", group = "next" },
      { "g", group = "goto" },
      { "gs", group = "surround" },
      { "z", group = "fold" },
      {
        "<leader>b",
        group = "buffer",
        expand = function()
          return require("which-key.extras").expand.buf()
        end,
      },
      {
        "<leader>w",
        group = "windows",
        proxy = "<c-w>",
        expand = function()
          return require("which-key.extras").expand.win()
        end,
      },
      -- rm jank
      { "<leader>y", hidden = true },
      { "<leader>p", hidden = true },
      { "<leader>P", hidden = true },
      { "<leader>K", hidden = true },
    },
  },
})
