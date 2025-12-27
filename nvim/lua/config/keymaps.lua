-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- yank and paste to system clipboard
vim.keymap.set({ "n", "v", "x" }, "<leader>y", '"+y', { silent = true, desc = "Copy to system clipboard" })
vim.keymap.set({ "n", "x" }, "<leader>p", '"+p', { desc = "Paste from system clipboard after the cursor position" })
vim.keymap.set({ "n", "x" }, "<leader>P", '"+P', { desc = "Paste from system clipboard before the cursor position" })

-- cmd+s to save
vim.keymap.set("n", "<D-s>", "<cmd>w<cr>", { silent = true, desc = "Save" })
vim.keymap.set("i", "<D-s>", "<Esc><cmd>w<cr>", { silent = true, desc = "Save" })

-- center on some jumps
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzz")
vim.keymap.set("n", "N", "Nzz")
vim.keymap.set("n", "*", "*zzzv")
vim.keymap.set("n", "#", "#zzzv")
vim.keymap.set("n", "G", "Gzz")
vim.keymap.set("n", "%", "%zz")

-- change macro keys
vim.keymap.set("n", "q", "<nop>", { silent = true })
vim.keymap.set("n", "<C-M-q>", "q", { desc = "Record macro" })

-- stop ctrl-z from suspending
vim.keymap.set("n", "<c-z>", "<nop>", { noremap = true, silent = true })

-- open all git modified files
vim.keymap.set("n", "<leader>gF", function()
  local cwd = vim.fn.getcwd()
  local root_res = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
  if root_res.code ~= 0 then
    return
  end
  local git_root = vim.trim(root_res.stdout or "")
  if git_root == "" then
    return
  end

  local relative_cwd = "."
  if cwd ~= git_root and vim.startswith(cwd, git_root .. "/") then
    relative_cwd = cwd:sub(#git_root + 2)
  end

  local status_res = vim.system({ "git", "-C", git_root, "status", "--porcelain=v1", "-z", "--", relative_cwd }, { text = true }):wait()
  if status_res.code ~= 0 then
    return
  end

  local output = status_res.stdout or ""
  if output == "" then
    return
  end

  local items = vim.split(output, "\0", { plain = true })

  -- Use a set to handle duplicates and open files
  local seen = {}

  local i = 1
  while i <= #items do
    local entry = items[i]
    if entry == "" then
      break
    end

    -- porcelain v1: "XY <path>" (and for renames/copies: "XY <from>\0<to>")
    local status = entry:sub(1, 2)
    local path = vim.trim(entry:sub(4))
    if status:find("R", 1, true) or status:find("C", 1, true) then
      i = i + 1
      path = items[i] or path
    end

    if path ~= "" and not seen[path] then
      seen[path] = true
      local full_path = git_root .. "/" .. path
      if vim.fn.filereadable(full_path) == 1 then
        vim.cmd.edit(vim.fn.fnameescape(full_path))
      end
    end

    i = i + 1
  end
end, { desc = "Open git modified files (cwd)" })

-- open in finder
vim.keymap.set("n", "<leader>jf", function()
  local path = vim.api.nvim_buf_get_name(0)
  vim.fn.jobstart({ "open", "-R", path }, { detach = true })
end, { silent = true, desc = "Reveal in Finder" })

-- copy relative path
vim.keymap.set("n", "<leader>jp", function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  print(path)
end, { desc = "Copy file path" })

-- open in cursor
vim.keymap.set("n", "<leader>jc", function()
  local file_path = vim.fn.expand("%:p")
  local cwd = vim.fn.getcwd()
  local line = vim.fn.line(".")
  local col = vim.fn.col(".")
  local goto_arg = '"' .. file_path .. ":" .. line .. ":" .. col .. '"'
  vim.fn.jobstart({ "cursor", cwd, "--goto", goto_arg }, { detach = true })
end, { silent = true, desc = "Open in Cursor" })

-- yank with path
vim.keymap.set("v", "<leader>jy", function()
  local yank = require("custom.yank")
  yank.yank_visual_with_path(yank.get_buffer_cwd_relative(), "relative")
end, { desc = "[Y]ank selection with [R]elative path" })

-- vscode specific keymaps
if vim.g.vscode then
  local vscode = require("vscode")

  vim.keymap.set("n", "]h", function()
    vscode.action("workbench.action.editor.nextChange")
  end, { desc = "Next git hunk" })

  vim.keymap.set("n", "[h", function()
    vscode.action("workbench.action.editor.previousChange")
  end, { desc = "Previous git hunk" })

  vim.keymap.set("n", "]e", function()
    vscode.action("editor.action.marker.next")
  end, { desc = "Next error" })

  vim.keymap.set("n", "[e", function()
    vscode.action("editor.action.marker.prev")
  end, { desc = "Previous error" })

  vim.keymap.set("n", "]d", function()
    vscode.action("editor.action.marker.next")
  end, { desc = "Next diagnostic" })

  vim.keymap.set("n", "[d", function()
    vscode.action("editor.action.marker.prev")
  end, { desc = "Previous diagnostic" })

  vim.keymap.set("n", "gr", function()
    vscode.action("editor.action.goToReferences")
  end, { desc = "Go to references" })

  vim.keymap.set("n", "<leader>ca", function()
    vscode.action("editor.action.quickFix")
  end, { desc = "Code actions" })

  -- quick close tab
  vim.keymap.set("n", "<leader><BS>", function()
    vscode.action("workbench.action.closeActiveEditor")
  end, { desc = "Close tab" })

  -- close all tabs except current
  vim.keymap.set("n", "<leader>bo", function()
    vscode.action("workbench.action.closeOtherEditors")
  end, { desc = "Close other tabs" })

  -- toggle file explorer
  vim.keymap.set("n", "<leader>e", function()
    vscode.action("workbench.action.toggleSidebarVisibility")
  end, { desc = "Toggle file explorer" })

  -- use vscode native undo/redo
  vim.keymap.set("n", "u", function()
    vscode.action("undo")
  end, { desc = "Undo" })

  vim.keymap.set("n", "<C-r>", function()
    vscode.action("redo")
  end, { desc = "Redo" })
end

-- disable some lazyvim keymaps
vim.keymap.del("n", "<leader>fT")
vim.keymap.del("n", "<leader>ft")
