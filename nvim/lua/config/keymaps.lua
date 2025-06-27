-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "jk", "<ESC>", { silent = true })

vim.keymap.set("n", "<leader>sf", function()
  Snacks.picker.grep({ root = false, args = { "-F" } })
end, { silent = true, desc = "String match" })

vim.keymap.set("n", "<leader><BS>", function()
  Snacks.bufdelete()
end, { silent = true, desc = "Close Buffer" })

vim.keymap.set({ "n", "v", "x" }, "<leader>y", '"+y', { silent = true, desc = "Copy to system clipboard" })

-- cmd+c not working in ghostty : (
-- vim.keymap.set("v", "<D-c>", '"+y', { desc = "Copy to system clipboard (Cmd+C)" })

vim.keymap.set("n", "<D-s>", "<cmd>w<cr>", { silent = true, desc = "Save" })
vim.keymap.set("i", "<D-s>", "<Esc><cmd>w<cr>", { silent = true, desc = "Save" })

vim.keymap.set("n", "<leader>gF", function()
  local cwd = vim.fn.getcwd()

  local function get_git_root()
    local handle = io.popen("git -C " .. cwd .. " rev-parse --show-toplevel", "r")
    if not handle then
      return nil
    end
    local root = handle:read("*l")
    handle:close()
    return root
  end

  local git_root = get_git_root()
  if not git_root then
    return
  end

  local function run_git_cmd(cmd)
    local handle = io.popen(cmd, "r")
    if not handle then
      return {}
    end
    local out = {}
    for line in handle:lines() do
      table.insert(out, line)
    end
    handle:close()
    return out
  end

  -- Run git from root, but restrict to subdir using `cwd` as pathspec
  local staged_files = run_git_cmd("git -C " .. git_root .. " diff --name-only --cached " .. cwd)
  local changed_files = run_git_cmd("git -C " .. git_root .. " ls-files --modified --others --exclude-standard " .. cwd)

  local file_set = {}
  for _, f in ipairs(staged_files) do
    file_set[f] = true
  end
  for _, f in ipairs(changed_files) do
    file_set[f] = true
  end

  for file, _ in pairs(file_set) do
    local full_path = git_root .. "/" .. file
    if vim.fn.filereadable(full_path) == 1 then
      vim.cmd("edit " .. vim.fn.fnameescape(full_path))
    end
  end
end, { desc = "Open git modified files (current dir)" })
