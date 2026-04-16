Snacks.setup({
  bigfile = {},
  quickfile = {},
  indent = {},
  input = {},
  scope = {},
  words = {},
  statuscolumn = {},
  lazygit = {
    theme = {
      [241] = { fg = "Special" },
      activeBorderColor = { fg = "MatchParen", bold = true },
      cherryPickedCommitBgColor = { fg = "Identifier" },
      cherryPickedCommitFgColor = { fg = "Function" },
      defaultFgColor = { fg = "Normal" },
      inactiveBorderColor = { fg = "FoldColumn" },
      optionsTextColor = { fg = "Function" },
      searchingActiveBorderColor = { fg = "MatchParen", bold = true },
      selectedLineBgColor = { bg = "Visual" },
      unstagedChangesColor = { fg = "DiagnosticError" },
    },
    win = {
      backdrop = 60,
      border = true,
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
    },
    previewers = {
      diff = {
        style = "syntax",
      },
    },
  },
  dashboard = {
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
