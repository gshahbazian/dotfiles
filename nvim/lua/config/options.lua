-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- default lazyvim hides markdown characters
vim.opt.conceallevel = 0

-- disable prettier if prittierrc not found
vim.g.lazyvim_prettier_needs_config = true

-- disable using the system clipboard (remapped to leader+y)
vim.opt.clipboard = ""
