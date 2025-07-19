-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- jk to escape (removed since i mapped capslock to escape)
-- vim.keymap.set("i", "jk", "<ESC>", { silent = true })

-- simple string search
vim.keymap.set("n", "<leader>sf", function()
  Snacks.picker.grep({ root = false, args = { "-F" } })
end, { silent = true, desc = "String match" })

-- quick delete buffer
vim.keymap.set("n", "<leader><BS>", function()
  Snacks.bufdelete()
end, { silent = true, desc = "Close Buffer" })

-- delete all buffers
vim.keymap.set("n", "<leader>ba", function()
  Snacks.bufdelete.all()
end, { desc = "Delete All Buffers" })

-- yank and paste to system clipboard
vim.keymap.set({ "n", "v", "x" }, "<leader>y", '"+y', { silent = true, desc = "Copy to system clipboard" })
vim.keymap.set({ "n", "x" }, "<leader>p", '"+p', { desc = "Paste from system clipboard after the cursor position" })
vim.keymap.set({ "n", "x" }, "<leader>P", '"+P', { desc = "Paste from system clipboard before the cursor position" })

-- cmd+c not working in ghostty : (
-- vim.keymap.set("v", "<D-c>", '"+y', { desc = "Copy to system clipboard (Cmd+C)" })

-- cmd+s to save
vim.keymap.set("n", "<D-s>", "<cmd>w<cr>", { silent = true, desc = "Save" })
vim.keymap.set("i", "<D-s>", "<Esc><cmd>w<cr>", { silent = true, desc = "Save" })

-- open all git modified files
vim.keymap.set("n", "<leader>gF", function()
  local cwd = vim.fn.getcwd()
  -- Get git root
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if not git_root or git_root == "" then
    return
  end

  -- Get all modified files restricted to current directory
  -- Use relative path from git root for consistency
  local relative_cwd = vim.fn.fnamemodify(cwd, ":s?" .. git_root .. "/??")
  local cmd = string.format("cd %s && git diff --name-only HEAD -- %s; git ls-files --others --exclude-standard -- %s", 
    vim.fn.shellescape(git_root), vim.fn.shellescape(relative_cwd), vim.fn.shellescape(relative_cwd))
  local files = vim.fn.systemlist(cmd)

  -- Use a set to handle duplicates and open files
  local seen = {}
  for _, file in ipairs(files) do
    -- Git returns paths relative to git root, so we need the full path
    local full_path = git_root .. "/" .. file
    if not seen[file] and vim.fn.filereadable(full_path) == 1 then
      seen[file] = true
      vim.cmd("edit " .. vim.fn.fnameescape(full_path))
    end
  end
end, { desc = "Open git modified files (cwd)" })

-- open in finder
vim.keymap.set("n", "<leader>jf", function()
  local path = vim.api.nvim_buf_get_name(0)
  os.execute("open -R " .. path)
end, { silent = true, desc = "Reveal in Finder" })

-- copy relative path
vim.keymap.set("n", "<leader>jp", function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  print("Copied: " .. path)
end, { desc = "Copy file path" })
