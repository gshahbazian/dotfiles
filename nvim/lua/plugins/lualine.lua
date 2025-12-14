return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections = opts.sections or {}
    opts.sections.lualine_c = opts.sections.lualine_c or {}

    local component = { LazyVim.lualine.pretty_path({ length = 6 }) }
    local pos = math.min(4, #opts.sections.lualine_c + 1)
    table.insert(opts.sections.lualine_c, pos, component)
  end,
}
