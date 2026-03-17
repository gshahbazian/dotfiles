local M = {}

function M.setup()
  local map = vim.keymap.set

  vim.pack.add({
    "https://github.com/folke/flash.nvim",
    "https://github.com/nvim-mini/mini.ai",
  }, {
    load = true,
  })

  require("flash").setup()

  local ai = require("mini.ai")
  ai.setup({
    n_lines = 500,
    custom_textobjects = {
      t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
      d = { "%f[%d]%d+" },
      e = {
        { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
        "^().*()$",
      },
      u = ai.gen_spec.function_call(),
      U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
    },
  })

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
  map("n", "gr", function()
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
