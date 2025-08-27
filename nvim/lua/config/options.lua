-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- switch ghost text and tab selection to copilot
vim.g.ai_cmp = false

-- default lazyvim hides markdown characters
vim.opt.conceallevel = 0

-- disable prettier if prittierrc not found
vim.g.lazyvim_prettier_needs_config = true

-- dont format with eslint
vim.g.lazyvim_eslint_auto_format = false

-- disable using the system clipboard (remapped to leader+y)
vim.opt.clipboard = ""

-- enable mode in vscode status line
if vim.g.vscode then
  vim.opt.showmode = true
end

-- disable undofile
-- vim.opt.undofile = false
