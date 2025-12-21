return {
  "folke/snacks.nvim",
  opts = {
    scroll = { enabled = false },
    image = { enabled = false },
    terminal = { enabled = false },
    scratch = { enabled = false },
    notifier = { enabled = false },
    picker = {
      hidden = true,
      ignored = true,
      exclude = {
        ".git",
        "node_modules",
        "vendor",
        "dist",
        "build",
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
    dashboard = {
      width = 20,
      preset = {
        keys = {
          { icon = "", key = "s", desc = "[s]ession resume", section = "session" },
          { icon = "", key = "e", desc = "[e]xplorer", action = "<leader>e" },
          { icon = "", key = "l", desc = "[l]azy", action = ":Lazy" },
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
  },
  keys = {
    { "<leader><space>", LazyVim.pick("files", { root = false }), desc = "Find Files (cwd)" },
    {
      "<leader>sf",
      function()
        Snacks.picker.grep({ root = false, args = { "-F" } })
      end,
      desc = "Search string (cwd)",
    },
    {
      "<leader>e",
      function()
        Snacks.explorer()
      end,
      desc = "Explorer Snacks (cwd)",
      remap = true,
    },
    {
      "<leader>,",
      function()
        Snacks.picker.buffers({
          on_show = function()
            vim.cmd.stopinsert()
          end,
          win = {
            input = {
              keys = {
                ["d"] = "bufdelete",
              },
            },
            list = { keys = { ["d"] = "bufdelete" } },
          },
        })
      end,
      desc = "Buffers",
    },
    {
      "<leader>ba",
      function()
        Snacks.bufdelete.all()
      end,
      desc = "Delete All Buffers",
    },
    {
      "<leader><BS>",
      function()
        Snacks.bufdelete()
      end,
      desc = "Close Buffer",
    },

    -- disable all this jank
    { "<leader>n", false },
    { "<leader>E", false },
    { "<leader>.", false },
    { "<leader>S", false },
    { "<leader>dps", false },
    { "<leader>sa", false },
    { "<leader>sC", false },
    { "<leader>sh", false },
    { "<leader>si", false },
    { "<leader>sM", false },
    { "<leader>sp", false },
    { "<leader>sH", false },
    { "<leader>fc", false },
    { "<leader>fe", false },
    { "<leader>fE", false },
    { "<leader>fp", false },
    { "<leader>fr", false },
  },
  init = function()
    vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#262626" })
    vim.api.nvim_set_hl(0, "SnacksIndent", { fg = "#323232" })
    vim.api.nvim_set_hl(0, "SnacksIndentScope", { fg = "#888888" })
  end,
}
