local backdrop = require("utils.backdrop")

-- check if we need to reload the file when it changed
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank()
  end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
  callback = function()
    local current_tab = vim.fn.tabpagenr()
    vim.cmd("tabdo wincmd =")
    vim.cmd("tabnext " .. current_tab)
    backdrop.resize()
  end,
})

-- go to last loc when opening a buffer
vim.api.nvim_create_autocmd("BufReadPost", {
  callback = function(event)
    local exclude = { "gitcommit" }
    local buf = event.buf
    if vim.tbl_contains(exclude, vim.bo[buf].filetype) or vim.b[buf].pack_last_loc then
      return
    end
    vim.b[buf].pack_last_loc = true
    local mark = vim.api.nvim_buf_get_mark(buf, '"')
    local lcount = vim.api.nvim_buf_line_count(buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  pattern = {
    "checkhealth",
    "gitsigns-blame",
    "help",
    "qf",
    "nvim-pack",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.opt_local.relativenumber = false
    vim.schedule(function()
      vim.keymap.set("n", "q", function()
        vim.cmd("close")
        pcall(vim.api.nvim_buf_delete, event.buf, { force = true })
      end, { buffer = event.buf, silent = true, desc = "Quit buffer" })
    end)
  end,
})

-- make it easier to close man-files when opened inline
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "man" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
  end,
})

-- wrap in text filetypes
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
  callback = function()
    vim.opt_local.wrap = true
  end,
})

-- auto create dir when saving a file
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  callback = function(event)
    if event.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- esc to quit mini.files
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesBufferCreate",
  callback = function(event)
    vim.keymap.set("n", "<Esc>", MiniFiles.close, {
      buffer = event.data.buf_id,
      silent = true,
      desc = "Close mini.files",
    })
  end,
})

-- backdrop behind mini.files
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesExplorerOpen",
  callback = function()
    backdrop.open()
  end,
})
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesExplorerClose",
  callback = function()
    backdrop.close()
  end,
})

-- clean mini.files titlebar
vim.api.nvim_create_autocmd("User", {
  pattern = "MiniFilesWindowUpdate",
  callback = function(args)
    local win_id = args.data.win_id
    if not vim.api.nvim_win_is_valid(win_id) then
      return
    end

    local state = MiniFiles.get_explorer_state()
    if not state then
      return
    end

    local path
    for _, window in ipairs(state.windows) do
      if window.win_id == win_id then
        path = window.path
        break
      end
    end

    if type(path) ~= "string" then
      return
    end

    path = tostring(path):gsub("%z", "")
    local cwd = vim.uv.fs_realpath(vim.fn.getcwd()) or vim.fn.getcwd()
    local normalized_path = vim.uv.fs_realpath(path) or path
    local title

    if normalized_path == cwd then
      title = vim.fs.basename(cwd)
    else
      title = vim.fs.relpath(cwd, path) or path
    end

    local config = vim.api.nvim_win_get_config(win_id)
    config.title = string.format(" %s ", title)
    vim.api.nvim_win_set_config(win_id, config)
  end,
})
