local M = {}

function M.setup()
  vim.pack.add({
    { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
    "https://github.com/nvim-treesitter/nvim-treesitter-context",

    "https://github.com/folke/flash.nvim",
    "https://github.com/nvim-mini/mini.nvim",
    "https://github.com/folke/ts-comments.nvim",
  }, {
    load = true,
  })

  require("plugins.coding")
  require("plugins.treesitter")
  require("config.keymaps")
  require("config.autocmds")

  local vscode = require("vscode")

  vim.keymap.set("n", "<leader><space>", "<cmd>Find<cr>")
  vim.keymap.set("n", "<leader>/", function()
    vscode.call("workbench.action.findInFiles")
  end)
  vim.keymap.set("n", "<S-h>", function()
    vscode.call("workbench.action.previousEditor")
  end)
  vim.keymap.set("n", "<S-l>", function()
    vscode.call("workbench.action.nextEditor")
  end)
  vim.keymap.set("n", "]h", function()
    vscode.action("workbench.action.editor.nextChange")
  end)
  vim.keymap.set("n", "[h", function()
    vscode.action("workbench.action.editor.previousChange")
  end)
  vim.keymap.set("n", "]e", function()
    vscode.action("editor.action.marker.next")
  end)
  vim.keymap.set("n", "[e", function()
    vscode.action("editor.action.marker.prev")
  end)
  vim.keymap.set("n", "]d", function()
    vscode.action("editor.action.marker.next")
  end)
  vim.keymap.set("n", "[d", function()
    vscode.action("editor.action.marker.prev")
  end)
  vim.keymap.set("n", "<leader>rd", function()
    vscode.action("editor.action.revealDefinition")
  end)
  vim.keymap.set("n", "<leader>rr", function()
    vscode.action("editor.action.goToReferences")
  end)
  vim.keymap.set("n", "<leader>ca", function()
    vscode.action("editor.action.quickFix")
  end)
  vim.keymap.set("n", "<leader><BS>", function()
    vscode.action("workbench.action.closeActiveEditor")
  end)
  vim.keymap.set("n", "<leader>bo", function()
    vscode.action("workbench.action.closeOtherEditors")
  end)
  vim.keymap.set("n", "<leader>e", function()
    vscode.action("workbench.action.toggleSidebarVisibility")
  end)
  vim.keymap.set("n", "u", function()
    vscode.action("undo")
  end)
  vim.keymap.set("n", "<C-r>", function()
    vscode.action("redo")
  end)
  vim.keymap.set("n", "za", function()
    vscode.action("editor.toggleFold")
  end)
  vim.keymap.set("n", "zc", function()
    vscode.action("editor.fold")
  end)
  vim.keymap.set("n", "zo", function()
    vscode.action("editor.unfold")
  end)
  vim.keymap.set("n", "zM", function()
    vscode.action("editor.foldAll")
  end)
  vim.keymap.set("n", "zR", function()
    vscode.action("editor.unfoldAll")
  end)
end

return M
