vim.pack.add({
  "https://github.com/gshahbazian/vesper.nvim",
  "https://github.com/rebelot/kanagawa.nvim",
}, { load = true })

local theme = "vesper"
local local_config = vim.fn.stdpath("config") .. ".local.lua"
local ok, local_settings = pcall(dofile, local_config)

if ok and type(local_settings) == "table" and type(local_settings.theme) == "string" then
  theme = local_settings.theme
end

vim.cmd.colorscheme(theme)
