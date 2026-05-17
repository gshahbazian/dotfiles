local M = {}

local state = {
  buf = nil,
  win = nil,
  zindex = nil,
}

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end

  state.win = nil
  state.buf = nil
  state.zindex = nil
end

function M.open(opts)
  opts = opts or {}
  M.close()

  local buf = vim.api.nvim_create_buf(false, true)
  local zindex = opts.zindex or 98
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = 0,
    col = 0,
    width = vim.o.columns,
    height = vim.o.lines - vim.o.cmdheight,
    style = "minimal",
    border = "none",
    focusable = false,
    zindex = zindex,
    noautocmd = true,
  })

  vim.bo[buf].bufhidden = "wipe"
  vim.wo[win].winhighlight = "Normal:Backdrop"
  vim.wo[win].winblend = 60

  state.buf = buf
  state.win = win
  state.zindex = zindex
end

function M.resize()
  if not (state.win and vim.api.nvim_win_is_valid(state.win)) then
    return
  end

  vim.api.nvim_win_set_config(state.win, {
    relative = "editor",
    row = 0,
    col = 0,
    width = vim.o.columns,
    height = vim.o.lines - vim.o.cmdheight,
    style = "minimal",
    border = "none",
    focusable = false,
    zindex = state.zindex or 98,
    noautocmd = true,
  })
end

return M
