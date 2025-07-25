return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        explorer = {
          hidden = true,
          ignored = true,
          layout = {
            layout = {
              position = "right",
            },
          },
          exclude = {
            ".git",
            "node_modules",
            "vendor",
            "dist",
            "build",
            "out",
            ".DS_Store",
          },
        },
      },
    },
    dashboard = {
      width = 18,
      preset = {
        keys = {
          { icon = "", key = "s", desc = " ̲last session", section = "session" },
          { icon = "", key = "l", desc = " ̲lazy", action = ":Lazy" },
          { icon = "", key = "q", desc = " ̲quit", action = ":qa" },
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
