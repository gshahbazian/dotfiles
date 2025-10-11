return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections.lualine_c[4] = { LazyVim.lualine.pretty_path({
      length = 6,
    }) }

    if opts.sections.lualine_x then
      opts.sections.lualine_x = vim.tbl_filter(function(component)
        if type(component) == "table" and type(component[1]) == "function" then
          local func_str = string.dump(component[1])
          if func_str:find("sidekick") then
            return false
          end
        end

        return true
      end, opts.sections.lualine_x)
    end
  end,
}
