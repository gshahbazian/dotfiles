local lint = require("lint")

lint.linters_by_ft = {
  fish = { "fish" },
}

local function debounce(ms, fn)
  local timer = vim.uv.new_timer()
  return function(...)
    local argv = { ... }
    timer:start(ms, 0, function()
      timer:stop()
      vim.schedule_wrap(fn)(unpack(argv))
    end)
  end
end

local function do_lint()
  local names = lint._resolve_linter_by_ft(vim.bo.filetype)
  names = vim.list_extend({}, names)

  -- Add fallback linters
  if #names == 0 then
    vim.list_extend(names, lint.linters_by_ft["_"] or {})
  end

  -- Add global linters
  vim.list_extend(names, lint.linters_by_ft["*"] or {})

  -- Filter out linters that don't exist
  local ctx = { filename = vim.api.nvim_buf_get_name(0) }
  ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
  names = vim.tbl_filter(function(name)
    local linter = lint.linters[name]
    if not linter then
      vim.notify("Linter not found: " .. name, vim.log.levels.WARN)
    end
    return linter and not (type(linter) == "table" and linter.condition and not linter.condition(ctx))
  end, names)

  if #names > 0 then
    lint.try_lint(names)
  end
end

vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
  group = vim.api.nvim_create_augroup("pack_lint", { clear = true }),
  callback = debounce(100, do_lint),
})
