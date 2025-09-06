return {
  "folke/snacks.nvim",
  opts = {
    scroll = {
      enabled = false,
    },
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
          { icon = "", key = "e", desc = "[e]xplorer", action = "<leader>fE" },
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
    { "<leader>e", "<leader>fE", desc = "Explorer Snacks (cwd)", remap = true },
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
  },
  init = function()
    vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = "#ea9d34" })
  end,
}
