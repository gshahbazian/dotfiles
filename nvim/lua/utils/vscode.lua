local M = {}

function M.setup()
  local map = vim.keymap.set

  vim.pack.add({
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
    "https://github.com/nvim-treesitter/nvim-treesitter-context",

    "https://github.com/folke/flash.nvim",
    "https://github.com/nvim-mini/mini.ai",
    "https://github.com/nvim-mini/mini.surround",
    "https://github.com/folke/ts-comments.nvim",
  }, {
    load = true,
  })

  require("plugins.coding")
  require("plugins.treesitter")
  require("config.keymaps")

  local vscode = require("vscode")

  map("n", "<leader><space>", "<cmd>Find<cr>")
  map("n", "<leader>/", function()
    vscode.call("workbench.action.findInFiles")
  end)
  map("n", "<S-h>", function()
    vscode.call("workbench.action.previousEditor")
  end)
  map("n", "<S-l>", function()
    vscode.call("workbench.action.nextEditor")
  end)
  map("n", "]h", function()
    vscode.action("workbench.action.editor.nextChange")
  end)
  map("n", "[h", function()
    vscode.action("workbench.action.editor.previousChange")
  end)
  map("n", "]e", function()
    vscode.action("editor.action.marker.next")
  end)
  map("n", "[e", function()
    vscode.action("editor.action.marker.prev")
  end)
  map("n", "]d", function()
    vscode.action("editor.action.marker.next")
  end)
  map("n", "[d", function()
    vscode.action("editor.action.marker.prev")
  end)
  map("n", "<leader>rd", function()
    vscode.action("editor.action.revealDefinition")
  end)
  map("n", "<leader>rr", function()
    vscode.action("editor.action.goToReferences")
  end)
  map("n", "<leader>ca", function()
    vscode.action("editor.action.quickFix")
  end)
  map("n", "<leader><BS>", function()
    vscode.action("workbench.action.closeActiveEditor")
  end)
  map("n", "<leader>bo", function()
    vscode.action("workbench.action.closeOtherEditors")
  end)
  map("n", "<leader>e", function()
    vscode.action("workbench.action.toggleSidebarVisibility")
  end)
  map("n", "u", function()
    vscode.action("undo")
  end)
  map("n", "<C-r>", function()
    vscode.action("redo")
  end)
  map("n", "za", function()
    vscode.action("editor.toggleFold")
  end)
  map("n", "zc", function()
    vscode.action("editor.fold")
  end)
  map("n", "zo", function()
    vscode.action("editor.unfold")
  end)
  map("n", "zM", function()
    vscode.action("editor.foldAll")
  end)
  map("n", "zR", function()
    vscode.action("editor.unfoldAll")
  end)

  require("config.autocmds")
end

return M
