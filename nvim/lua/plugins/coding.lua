-- coding plugins that are safe to load in the vscode extension

require("flash").setup()

require("mini.extra").setup({})

local ai = require("mini.ai")
local extra_ai_spec = require("mini.extra").gen_ai_spec
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
    d = extra_ai_spec.number(),
    -- word part: CamelCase / snake_case segment
    e = {
      { "%u[%l%d]+%f[^%l%d]", "%f[%S][%l%d]+%f[^%l%d]", "%f[%P][%l%d]+%f[^%l%d]", "^[%l%d]+%f[^%l%d]" },
      "^().*()$",
    },
    -- function call: `foo.bar()` (dotted name allowed)
    u = ai.gen_spec.function_call(),
    -- function call: `foo_bar()` only (no dots)
    U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }),
    -- diagnostic
    D = extra_ai_spec.diagnostic(),
    -- entire buffer
    g = extra_ai_spec.buffer(),
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
