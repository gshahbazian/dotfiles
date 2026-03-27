local M = {}

local state = {
  buf = nil,
  win = nil,
}

function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end

  state.win = nil
  state.buf = nil
end

function M.open()
  M.close()

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = 0,
    col = 0,
    width = vim.o.columns,
    height = vim.o.lines - vim.o.cmdheight,
    style = "minimal",
    border = "none",
    focusable = false,
    zindex = 98,
    noautocmd = true,
  })

  vim.bo[buf].bufhidden = "wipe"
  vim.wo[win].winhighlight = "Normal:Backdrop"
  vim.wo[win].winblend = 60

  state.buf = buf
  state.win = win
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
    zindex = 98,
    noautocmd = true,
  })
end

return M
