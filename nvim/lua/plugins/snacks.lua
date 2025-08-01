return {
  "folke/snacks.nvim",
  opts = {
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
          { icon = "", key = "e", desc = "[e]xplorer", action = ":lua Snacks.explorer({ cwd = LazyVim.root() })" },
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
}
