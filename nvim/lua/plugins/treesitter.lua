-- filetype detection
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

vim.treesitter.language.register("bash", "kitty")

TS.setup({
  indent = { enable = true },
  highlight = { enable = true },
  folds = { enable = true },
  ensure_installed = ensure_installed,
})

-- install missing parsers
if TS.get_installed then
  local installed = TS.get_installed()
  local installed_set = {}
  for _, lang in ipairs(installed) do
    installed_set[lang] = true
  end

  local missing = vim.tbl_filter(function(lang)
    return not installed_set[lang]
  end, ensure_installed)

  if #missing > 0 then
    TS.install(missing, { summary = true })
  end
end

-- enable treesitter highlighting and indentation per filetype
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("pack_treesitter", { clear = true }),
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match)
    if not lang then
      return
    end

    local ok = pcall(vim.treesitter.start, ev.buf)
    if not ok then
      return
    end

    vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- nvim-treesitter-textobjects
local TSTextObjects = require("nvim-treesitter-textobjects")
if TSTextObjects.setup then
  TSTextObjects.setup({
    move = {
      enable = true,
      set_jumps = true,
    },
  })

  local move_opts = {
    goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer", ["]a"] = "@parameter.inner" },
    goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer", ["]A"] = "@parameter.inner" },
    goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer", ["[a"] = "@parameter.inner" },
    goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer", ["[A"] = "@parameter.inner" },
  }

  local function attach_textobjects(buf)
    for method, keymaps in pairs(move_opts) do
      for key, query in pairs(keymaps) do
        local desc = (key:sub(1, 1) == "[" and "Prev " or "Next ") .. query:gsub("@", ""):gsub("%..*", "")
        vim.keymap.set({ "n", "x", "o" }, key, function()
          if vim.wo.diff and key:find("[cC]") then
            return vim.cmd("normal! " .. key)
          end
          require("nvim-treesitter-textobjects.move")[method](query, "textobjects")
        end, { buffer = buf, desc = desc, silent = true })
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
end

-- nvim-treesitter-context
require("treesitter-context").setup({
  max_lines = 3,
})
