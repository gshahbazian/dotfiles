-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("i", "jk", "<ESC>", { silent = true })

vim.keymap.set("n", "<leader>sf", function()
  Snacks.picker.grep({ root = false, args = { "-F" } })
end, { desc = "String match" })

vim.keymap.set("n", "<leader><BS>", function()
  Snacks.bufdelete()
end, { desc = "Close Buffer" })

-- vim.keymap.set("n", "<D-s>", "<cmd>w<cr>", { desc = "Save" })
-- vim.keymap.set("i", "<D-s>", "<Esc><cmd>w<cr>a", { desc = "Save" })
