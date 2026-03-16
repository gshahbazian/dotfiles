vim.filetype.add({
  filename = {
    ["Tiltfile"] = "python",
    ["vifmrc"] = "vim",
  },
  pattern = {
    ["%.env%.[%w_.-]+"] = "sh",
    [".*/%.vscode/.*%.json"] = "jsonc",
    [".*/zed/.*%.json"] = "jsonc",
  },
})

local TS = require("nvim-treesitter")

local ensure_installed = {
  "bash",
  "c",
  "diff",
  "fish",
  "git_config",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "json5",
  "lua",
  "luadoc",
  "luap",
  "markdown",
  "markdown_inline",
  "printf",
  "python",
  "query",
  "regex",
  "ron",
  "rust",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
}

local isnt_installed = function(lang)
  return #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0
end
local to_install = vim.tbl_filter(isnt_installed, ensure_installed)
if #to_install > 0 then
  TS.install(to_install)
end

local filetypes = {}
for _, lang in ipairs(ensure_installed) do
  for _, ft in ipairs(vim.treesitter.language.get_filetypes(lang)) do
    table.insert(filetypes, ft)
  end
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = filetypes,
  group = vim.api.nvim_create_augroup("pack_treesitter", { clear = true }),
  callback = function(ev)
    vim.treesitter.start(ev.buf)
    vim.api.nvim_set_option_value("indentexpr", "v:lua.require'nvim-treesitter'.indentexpr()", { scope = "local" })
    vim.api.nvim_set_option_value("foldmethod", "expr", { scope = "local" })
    vim.api.nvim_set_option_value("foldexpr", "v:lua.vim.treesitter.foldexpr()", { scope = "local" })
  end,
})

-- nvim-treesitter-textobjects
local TSTextObjects = require("nvim-treesitter-textobjects")
TSTextObjects.setup({
  move = { set_jumps = true },
})

local textobjects = {
  { key = "f", query = "@function.outer", name = "Function" },
  { key = "c", query = "@class.outer", name = "Class" },
  { key = "a", query = "@parameter.inner", name = "Parameter" },
}

local function attach_textobjects(buf)
  local move = require("nvim-treesitter-textobjects.move")

  for _, obj in ipairs(textobjects) do
    for _, dir in ipairs({ { "]", "next" }, { "[", "previous" } }) do
      for _, edge in ipairs({ { obj.key, "start" }, { obj.key:upper(), "end" } }) do
        local key = dir[1] .. edge[1]
        local method = "goto_" .. dir[2] .. "_" .. edge[2]
        local desc = (dir[2] == "next" and "Next " or "Prev ") .. obj.name .. " " .. edge[2]:gsub("^%l", string.upper)

        vim.keymap.set({ "n", "x", "o" }, key, function()
          if vim.wo.diff and key:find("[cC]") then
            return vim.cmd("normal! " .. key)
          end
          move[method](obj.query, "textobjects")
        end, { buffer = buf, desc = desc, silent = true })
      end
    end
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("pack_treesitter_textobjects", { clear = true }),
  callback = function(ev)
    attach_textobjects(ev.buf)
  end,
})
vim.tbl_map(attach_textobjects, vim.api.nvim_list_bufs())

-- nvim-treesitter-context
require("treesitter-context").setup({
  max_lines = 3,
})
