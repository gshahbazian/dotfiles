-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

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
  local cmd = string.format(
    "cd %s && git diff --name-only HEAD -- %s; git ls-files --others --exclude-standard -- %s",
    vim.fn.shellescape(git_root),
    vim.fn.shellescape(relative_cwd),
    vim.fn.shellescape(relative_cwd)
  )
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

-- open in vscode
vim.keymap.set("n", "<leader>jv", function()
  vim.fn.jobstart({ "code", "." }, { detach = true })
end, { silent = true, desc = "Open in VSCode" })

-- jank function to center some plugin keymaps jump
local function add_centering_to_keymap(mode, key, desc_suffix)
  local original = vim.fn.maparg(key, mode, false, true)
  if vim.tbl_isempty(original) then
    return
  end

  vim.keymap.set(mode, key, function()
    if original.callback then
      original.callback()
    elseif original.rhs then
      if original.noremap == 1 then
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(original.rhs, true, false, true), "n", false)
      else
        vim.cmd("normal! " .. original.rhs)
      end
    end

    vim.cmd("normal! zz")
  end, {
    desc = original.desc and (original.desc .. desc_suffix) or ("Original " .. key .. desc_suffix),
    silent = original.silent == 1,
    buffer = original.buffer ~= 0 and original.buffer or nil,
  })
end

-- Function to batch add centering to multiple keymaps
local function add_centering_to_keymaps(keymaps, desc_suffix)
  desc_suffix = desc_suffix or " (centered)"

  for _, keymap in ipairs(keymaps) do
    local mode = keymap.mode or "n"
    local key = keymap.key
    add_centering_to_keymap(mode, key, desc_suffix)
  end
end

-- Usage: Add centering to diagnostic and navigation keymaps
add_centering_to_keymaps({
  { key = "]e" },
  { key = "[e" },
  { key = "]d" },
  { key = "[d" },
  { key = "]h" },
  { key = "[h" },
})
