-- coding plugins that are safe to load in the vscode extension

require("flash").setup()

local ai = require("mini.ai")
ai.setup({
  n_lines = 500,
  custom_textobjects = {
    -- block / conditional / loop (treesitter)
    o = ai.gen_spec.treesitter({
      a = { "@block.outer", "@conditional.outer", "@loop.outer" },
      i = { "@block.inner", "@conditional.inner", "@loop.inner" },
    }),
    -- function (treesitter)
    f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
    -- class (treesitter)
    c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
    -- html/xml tag
    t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
    -- a run of digits
    d = { "%f[%d]%d+" },
    -- word part: CamelCase / snake_case segment
    e = {
      { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
      "^().*()$",
    },
    -- function call: `foo.bar()` (dotted name allowed)
    u = ai.gen_spec.function_call(),
    -- function call: `foo_bar()` only (no dots)
    U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
    -- diagnostic block: contiguous run of lsp/linter diagnostics
    D = function(ai_type)
      local diagnostics = vim.diagnostic.get(0)
      if #diagnostics == 0 then
        return {}
      end

      table.sort(diagnostics, function(a, b)
        return a.lnum < b.lnum or (a.lnum == b.lnum and a.col < b.col)
      end)

      -- group adjacent/overlapping diagnostics into contiguous blocks
      local blocks = {}
      for _, d in ipairs(diagnostics) do
        local last = blocks[#blocks]
        if last and d.lnum <= last.end_lnum + 1 then
          if d.end_lnum > last.end_lnum then
            last.end_lnum = d.end_lnum
            last.end_col = d.end_col
          elseif d.end_lnum == last.end_lnum then
            last.end_col = math.max(last.end_col, d.end_col)
          end
        else
          table.insert(blocks, {
            lnum = d.lnum,
            col = d.col,
            end_lnum = d.end_lnum,
            end_col = d.end_col,
          })
        end
      end

      local regions = {}
      for _, b in ipairs(blocks) do
        local from, to
        if ai_type == "a" then
          from = { line = b.lnum + 1, col = 1 }
          local end_line = vim.fn.getline(b.end_lnum + 1)
          to = { line = b.end_lnum + 1, col = math.max(#end_line, 1) }
        else
          from = { line = b.lnum + 1, col = b.col + 1 }
          to = { line = b.end_lnum + 1, col = math.max(b.end_col, 1) }
        end
        table.insert(regions, { from = from, to = to })
      end
      return regions
    end,
    -- entire buffer
    g = function()
      local from = { line = 1, col = 1 }
      local to = {
        line = vim.fn.line("$"),
        col = math.max(vim.fn.getline("$"):len(), 1),
      }
      return { from = from, to = to }
    end,
  },

  -- use the default lsp an/in
  mappings = {
    around_next = "",
    inside_next = "",
  },
})

require("mini.surround").setup({
  mappings = {
    add = "gsa",
    delete = "gsd",
    find = "gsf",
    find_left = "gsF",
    highlight = "gsh",
    replace = "gsr",
    update_n_lines = "gsn",
  },
})

require("ts-comments").setup()
