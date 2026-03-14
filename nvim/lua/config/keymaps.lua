local map = vim.keymap.set

-- better up/down
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
map({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- Move Lines
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", [[:<C-u>execute "'<,'>move '>+" . v:count1<cr>gv=gv]], { desc = "Move Down" })
map("v", "<A-k>", [[:<C-u>execute "'<,'>move '<-" . (v:count1 + 1)<cr>gv=gv]], { desc = "Move Up" })

-- Buffers
map("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev Buffer" })
map("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Buffer" })
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })
map("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, { desc = "Delete Other Buffers" })
map("n", "<leader>bD", "<cmd>bd<cr>", { desc = "Delete Buffer and Window" })
map("n", "<leader>br", "<Cmd>BufferLineCloseRight<CR>", { desc = "Delete Buffers to the Right" })
map("n", "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", { desc = "Delete Buffers to the Left" })
map("n", "<leader>bj", "<cmd>BufferLinePick<cr>", { desc = "Pick Buffer" })

-- Clear search and stop snippet on escape
map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- Add undo break-points
map("i", ",", ",<c-g>u")
map("i", ".", ".<c-g>u")
map("i", ";", ";<c-g>u")

-- Keywordprg
map("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keywordprg" })

-- Better indenting
map("x", "<", "<gv")
map("x", ">", ">gv")

-- Commenting
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

-- New file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

-- Location list
map("n", "<leader>xl", function()
  local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Location List" })

-- Quickfix list
map("n", "<leader>xq", function()
  local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Quickfix List" })

map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

-- Formatting
map({ "n", "x" }, "<leader>cf", function()
  require("conform").format({ bufnr = 0 })
end, { desc = "Format" })

-- Diagnostic
local function diagnostic_goto(next, severity)
  return function()
    vim.diagnostic.jump({
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- vim.pack
map("n", "<leader>lp", function()
  vim.pack.update(nil, { offline = true })
end, { desc = "Plugin status" })
map("n", "<leader>lu", function()
  vim.pack.update()
end, { desc = "Update plugins" })
map("n", "<leader>lU", function()
  vim.pack.update(nil, { force = true })
end, { desc = "Update plugins (force)" })
map("n", "<leader>lh", "<cmd>checkhealth vim.pack<cr>", { desc = "Plugin health" })

-- Lazygit
map("n", "<leader>gg", function()
  Snacks.lazygit()
end, { desc = "Lazygit" })

map({ "n", "x" }, "<leader>gB", function()
  Snacks.gitbrowse()
end, { desc = "Git Browse (open)" })
map({ "n", "x" }, "<leader>gY", function()
  Snacks.gitbrowse({
    open = function(url)
      vim.fn.setreg("+", url)
    end,
    notify = false,
  })
end, { desc = "Git Browse (copy)" })

-- Quit
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

-- Windows
map("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
map("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })

-- Tabs
map("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })

-- Flash keymaps
map({ "n", "x", "o" }, "s", function()
  require("flash").jump()
end, { desc = "Flash" })
map({ "n", "o", "x" }, "S", function()
  require("flash").treesitter()
end, { desc = "Flash Treesitter" })
map("o", "r", function()
  require("flash").remote()
end, { desc = "Remote Flash" })
map({ "o", "x" }, "R", function()
  require("flash").treesitter_search()
end, { desc = "Treesitter Search" })
map({ "n", "o", "x" }, "<c-space>", function()
  require("flash").treesitter({
    actions = {
      ["<c-space>"] = "next",
      ["<BS>"] = "prev",
    },
  })
end, { desc = "Treesitter Incremental Selection" })

-- Trouble keymaps
map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })
map("n", "<leader>cs", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols (Trouble)" })
map("n", "<leader>cS", "<cmd>Trouble lsp toggle<cr>", { desc = "LSP references/definitions/... (Trouble)" })
map("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
map("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })

-- Todo-comments keymaps
map("n", "<leader>xt", "<cmd>Trouble todo toggle<cr>", { desc = "Todo (Trouble)" })
map("n", "<leader>xT", "<cmd>Trouble todo toggle filter = {tag = {TODO,FIX,FIXME}}<cr>", { desc = "Todo/Fix/Fixme (Trouble)" })

-- Word reference navigation
map("n", "]]", function()
  Snacks.words.jump(vim.v.count1)
end, { desc = "Next Reference" })
map("n", "[[", function()
  Snacks.words.jump(-vim.v.count1)
end, { desc = "Prev Reference" })

-- Noice keymaps
map("n", "<leader>n", "<cmd>Noice history<cr>", { desc = "Notification History" })

-- Mason
map("n", "<leader>cm", "<cmd>Mason<cr>", { desc = "Mason" })

-- Snacks picker keymaps
map("n", "<leader><space>", function()
  Snacks.picker.files()
end, { desc = "Find Files" })
map("n", "<leader>/", function()
  Snacks.picker.grep()
end, { desc = "Grep" })
map("n", '<leader>s"', function()
  Snacks.picker.registers()
end, { desc = "Registers" })
map("n", "<leader>sj", function()
  Snacks.picker.jumps()
end, { desc = "Jumps" })
map("n", "<leader>sk", function()
  Snacks.picker.keymaps()
end, { desc = "Keymaps" })
map("n", "<leader>sr", function()
  Snacks.picker.resume()
end, { desc = "Resume" })
map({ "n", "x" }, "<leader>sw", function()
  Snacks.picker.grep_word()
end, { desc = "Visual selection or word" })
map("n", "<leader>sm", function()
  Snacks.picker.marks()
end, { desc = "Marks" })
map("n", "<leader>sf", function()
  Snacks.picker.grep({ args = { "-F" } })
end, { desc = "Search string" })
map("n", "<leader>fg", function()
  Snacks.picker.git_files()
end, { desc = "Git files" })
map("n", "<leader>e", function()
  Snacks.explorer()
end, { desc = "Explorer Snacks" })
map("n", "<leader>,", function()
  Snacks.picker.buffers({
    on_show = function()
      vim.cmd.stopinsert()
    end,
    win = {
      input = { keys = { ["d"] = "bufdelete" } },
      list = { keys = { ["d"] = "bufdelete" } },
    },
  })
end, { desc = "Buffers" })
map("n", "<leader>ba", function()
  Snacks.bufdelete.all()
end, { desc = "Delete All Buffers" })
map("n", "<leader><BS>", function()
  Snacks.bufdelete()
end, { desc = "Close Buffer" })
map("n", "<leader>fr", function()
  Snacks.picker.recent({
    filter = { cwd = true },
    on_show = function()
      vim.cmd.stopinsert()
    end,
  })
end, { desc = "Recent files" })

-- ============================================================================

-- Yank and paste to system clipboard
map({ "n", "v" }, "<leader>y", '"+y', { silent = true, desc = "Copy to system clipboard" })
map({ "n", "x" }, "<leader>p", '"+p', { desc = "Paste from system clipboard after the cursor position" })
map({ "n", "x" }, "<leader>P", '"+P', { desc = "Paste from system clipboard before the cursor position" })

-- Cmd+s to save
map("n", "<D-s>", "<cmd>w<cr>", { silent = true, desc = "Save" })
map("i", "<D-s>", "<Esc><cmd>w<cr>", { silent = true, desc = "Save" })

-- Change macro keys
map("n", "q", "<nop>", { silent = true })
map("n", "<C-M-q>", "q", { desc = "Record macro" })

-- Alt+h/l to go to start/end of line
map({ "n", "v" }, "<A-h>", "^", { desc = "Go to start of line" })
map({ "n", "v" }, "<A-l>", "$", { desc = "Go to end of line" })

-- Stop ctrl-z from suspending
map("n", "<c-z>", "<nop>", { silent = true })

-- Open all git modified files
map("n", "<leader>gF", function()
  local cwd = vim.fn.getcwd()
  local root_res = vim.system({ "git", "rev-parse", "--show-toplevel" }, { text = true }):wait()
  if root_res.code ~= 0 then
    return
  end
  local git_root = vim.trim(root_res.stdout or "")
  if git_root == "" then
    return
  end

  local relative_cwd = "."
  if cwd ~= git_root and vim.startswith(cwd, git_root .. "/") then
    relative_cwd = cwd:sub(#git_root + 2)
  end

  local status_res = vim.system({ "git", "-C", git_root, "status", "--porcelain=v1", "-z", "--", relative_cwd }, { text = true }):wait()
  if status_res.code ~= 0 then
    return
  end

  local output = status_res.stdout or ""
  if output == "" then
    return
  end

  local items = vim.split(output, "\0", { plain = true })
  local seen = {}
  local i = 1
  while i <= #items do
    local entry = items[i]
    if entry == "" then
      break
    end

    local status = entry:sub(1, 2)
    local path = vim.trim(entry:sub(4))
    if status:find("R", 1, true) or status:find("C", 1, true) then
      i = i + 1
      path = items[i] or path
    end

    if path ~= "" and not seen[path] then
      seen[path] = true
      local full_path = git_root .. "/" .. path
      if vim.fn.filereadable(full_path) == 1 then
        vim.cmd.edit(vim.fn.fnameescape(full_path))
      end
    end

    i = i + 1
  end
end, { desc = "Open git modified files" })

-- Open in finder
map("n", "<leader>jf", function()
  local path = vim.api.nvim_buf_get_name(0)
  vim.fn.jobstart({ "open", "-R", path }, { detach = true })
end, { silent = true, desc = "Reveal in Finder" })

-- Copy relative path
map("n", "<leader>jp", function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  print(path)
end, { desc = "Copy file path" })

-- Open in zed
map("n", "<leader>jc", function()
  local file_path = vim.fn.expand("%:p")
  local cwd = vim.fn.getcwd()
  local line = vim.fn.line(".")
  local col = vim.fn.col(".")
  local goto_arg = file_path .. ":" .. line .. ":" .. col
  vim.fn.jobstart({ "zed", cwd, goto_arg }, { detach = true })
end, { silent = true, desc = "Open in Zed" })

-- Yank with path
map("v", "<leader>jy", function()
  local yank = require("utils.yank")
  yank.yank_visual_with_path(yank.get_buffer_cwd_relative(), "relative")
end, { desc = "[Y]ank selection with [R]elative path" })

-- Save without triggering format
map("n", "<leader>jW", "<cmd>noautocmd write<CR>", { desc = "Save without formatting" })
