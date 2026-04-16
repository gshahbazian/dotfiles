-- better up/down
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "<Down>", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "<Up>", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

-- move to window using the <ctrl> hjkl keys
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })

-- resize window using <ctrl> arrow keys
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

-- move lines
vim.keymap.set("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
vim.keymap.set("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
vim.keymap.set("v", "<A-j>", [[:<C-u>execute "'<,'>move '>+" . v:count1<cr>gv=gv]], { desc = "Move Down" })
vim.keymap.set("v", "<A-k>", [[:<C-u>execute "'<,'>move '<-" . (v:count1 + 1)<cr>gv=gv]], { desc = "Move Up" })

-- buffers
vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Prev Buffer" })
vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next Buffer" })
vim.keymap.set("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
vim.keymap.set("n", "<leader>bd", function()
  Snacks.bufdelete()
end, { desc = "Delete Buffer" })
vim.keymap.set("n", "<leader>bo", function()
  Snacks.bufdelete.other()
end, { desc = "Delete Other Buffers" })
vim.keymap.set("n", "<leader>bD", "<cmd>bd<cr>", { desc = "Delete Buffer and Window" })
vim.keymap.set("n", "<leader>br", "<Cmd>BufferLineCloseRight<CR>", { desc = "Delete Buffers to the Right" })
vim.keymap.set("n", "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", { desc = "Delete Buffers to the Left" })
vim.keymap.set("n", "<leader>bj", "<cmd>BufferLinePick<cr>", { desc = "Pick Buffer" })
vim.keymap.set("n", "<leader>ba", function()
  Snacks.bufdelete.all()
end, { desc = "Delete All Buffers" })
vim.keymap.set("n", "<leader><BS>", function()
  Snacks.bufdelete()
end, { desc = "Close Buffer" })

vim.keymap.set({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
vim.keymap.set("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
vim.keymap.set("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
vim.keymap.set("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
vim.keymap.set("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
vim.keymap.set("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
vim.keymap.set("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })

-- add undo break-points
vim.keymap.set("i", ",", ",<c-g>u")
vim.keymap.set("i", ".", ".<c-g>u")
vim.keymap.set("i", ";", ";<c-g>u")

vim.keymap.set("n", "<leader>K", "<cmd>norm! K<cr>", { desc = "Keywordprg" })

-- better indenting
vim.keymap.set("x", "<", "<gv")
vim.keymap.set("x", ">", ">gv")

vim.keymap.set("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
vim.keymap.set("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

vim.keymap.set("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })

vim.keymap.set("n", "<leader>xl", function()
  local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Location List" })

-- quickfix list
vim.keymap.set("n", "<leader>xq", function()
  local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Quickfix List" })
vim.keymap.set("n", "<leader>xc", function()
  vim.fn.setqflist({})
  vim.cmd("cclose")
end, { desc = "Clear Quickfix" })
vim.keymap.set("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
vim.keymap.set("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

vim.keymap.set({ "n", "x" }, "<leader>cf", function()
  require("conform").format({ bufnr = 0 })
end, { desc = "Format" })

-- diagnostic
local function diagnostic_goto(next, severity)
  return function()
    vim.diagnostic.jump({
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
vim.keymap.set("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
vim.keymap.set("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
vim.keymap.set("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
vim.keymap.set("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
vim.keymap.set("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
vim.keymap.set("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })

-- vim.pack
vim.keymap.set("n", "<leader>lu", function()
  vim.pack.update()
end, { desc = "Update plugins" })
vim.keymap.set("n", "<leader>lh", "<cmd>checkhealth vim.pack<cr>", { desc = "Plugin health" })
vim.keymap.set("n", "<leader>lm", "<cmd>Mason<cr>", { desc = "Mason" })

-- git
vim.keymap.set("n", "<leader>gg", function()
  Snacks.lazygit()
end, { desc = "Lazygit" })
vim.keymap.set({ "n", "x" }, "<leader>gB", function()
  Snacks.gitbrowse()
end, { desc = "Git Browse (open)" })
vim.keymap.set({ "n", "x" }, "<leader>gY", function()
  Snacks.gitbrowse({
    open = function(url)
      vim.fn.setreg("+", url)
    end,
    notify = false,
  })
end, { desc = "Git Browse (copy)" })

vim.keymap.set("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })

-- windows
vim.keymap.set("n", "<leader>-", "<C-W>s", { desc = "Split Window Below", remap = true })
vim.keymap.set("n", "<leader>|", "<C-W>v", { desc = "Split Window Right", remap = true })
vim.keymap.set("n", "<leader>wd", "<C-W>c", { desc = "Delete Window", remap = true })
vim.keymap.set("n", "<leader>w<tab>", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })

-- flash
vim.keymap.set({ "n", "x", "o" }, "s", function()
  require("flash").jump()
end, { desc = "Flash" })
vim.keymap.set({ "n", "o", "x" }, "S", function()
  require("flash").treesitter()
end, { desc = "Flash Treesitter" })
vim.keymap.set("o", "r", function()
  require("flash").remote()
end, { desc = "Remote Flash" })
vim.keymap.set({ "o", "x" }, "R", function()
  require("flash").treesitter_search()
end, { desc = "Treesitter Search" })
vim.keymap.set({ "n", "o", "x" }, "<c-space>", function()
  require("flash").treesitter({
    actions = {
      ["<c-space>"] = "next",
      ["<BS>"] = "prev",
    },
  })
end, { desc = "Treesitter Incremental Selection" })

-- trouble
vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics (Trouble)" })
vim.keymap.set("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics (Trouble)" })
vim.keymap.set("n", "<leader>cs", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols (Trouble)" })
vim.keymap.set("n", "<leader>cS", "<cmd>Trouble lsp toggle<cr>", { desc = "LSP references/definitions/... (Trouble)" })
vim.keymap.set("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List (Trouble)" })
vim.keymap.set("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List (Trouble)" })

-- noice
vim.keymap.set("n", "<leader>n", "<cmd>Noice history<cr>", { desc = "Notification History" })

-- pickers
vim.keymap.set("n", "<leader><space>", function()
  Snacks.picker.smart({
    filter = { cwd = true },
  })
end, { desc = "Find Files" })
vim.keymap.set("n", "<leader>/", function()
  Snacks.picker.grep()
end, { desc = "Grep" })
vim.keymap.set("n", '<leader>s"', function()
  Snacks.picker.registers()
end, { desc = "Registers" })
vim.keymap.set("n", "<leader>sj", function()
  Snacks.picker.jumps()
end, { desc = "Jumps" })
vim.keymap.set("n", "<leader>sk", function()
  Snacks.picker.keymaps()
end, { desc = "Keymaps" })
vim.keymap.set("n", "<leader>sr", function()
  Snacks.picker.resume({
    on_show = function()
      vim.cmd.stopinsert()
    end,
  })
end, { desc = "Resume" })
vim.keymap.set({ "n", "x" }, "<leader>sw", function()
  Snacks.picker.grep_word({
    on_show = function()
      vim.cmd.stopinsert()
    end,
  })
end, { desc = "Visual selection or word" })
vim.keymap.set("n", "<leader>sm", function()
  Snacks.picker.marks()
end, { desc = "Marks" })
vim.keymap.set("n", "<leader>sf", function()
  Snacks.picker.grep({ regex = false })
end, { desc = "Search string" })
vim.keymap.set("n", "<leader>fg", function()
  Snacks.picker.git_status({
    ignored = false,
    on_show = function()
      vim.cmd.stopinsert()
    end,
  })
end, { desc = "Git status" })
vim.keymap.set("n", "<leader>e", function()
  local mini_files = require("mini.files")
  if not mini_files.close() then
    local path = vim.api.nvim_buf_get_name(0)
    mini_files.open(path ~= "" and path or nil, false)
  end
end, { desc = "mini.files" })
vim.keymap.set("n", "<leader>,", function()
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
vim.keymap.set("n", "<leader>fr", function()
  Snacks.picker.recent({
    filter = { cwd = true },
    on_show = function()
      vim.cmd.stopinsert()
    end,
  })
end, { desc = "Recent files" })

-- yank and paste to system clipboard
vim.keymap.set({ "n", "x" }, "<leader>y", '"+y', { silent = true, desc = "Copy to system clipboard" })
vim.keymap.set({ "n", "x" }, "<leader>p", '"+p', { desc = "Paste from system clipboard after the cursor position" })
vim.keymap.set({ "n", "x" }, "<leader>P", '"+P', { desc = "Paste from system clipboard before the cursor position" })

-- cmd+s to save
vim.keymap.set("n", "<D-s>", "<cmd>w<cr>", { silent = true, desc = "Save" })
vim.keymap.set("i", "<D-s>", "<Esc><cmd>w<cr>", { silent = true, desc = "Save" })

-- change macro keys
vim.keymap.set("n", "q", "<nop>", { silent = true })
vim.keymap.set("n", "<C-M-q>", "q", { desc = "Record macro" })

-- alt+h/l to go to start/end of line
vim.keymap.set({ "n", "v" }, "<A-h>", "^", { desc = "Go to start of line" })
vim.keymap.set({ "n", "v" }, "<A-l>", "$", { desc = "Go to end of line" })

-- stop ctrl-z from suspending
vim.keymap.set("n", "<c-z>", "<nop>", { silent = true })

vim.keymap.set("n", "<leader>jf", function()
  local path = vim.api.nvim_buf_get_name(0)
  vim.fn.jobstart({ "open", "-R", path }, { detach = true })
end, { silent = true, desc = "Reveal in Finder" })

vim.keymap.set("n", "<leader>jp", function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  print(path)
end, { desc = "Copy file path" })

vim.keymap.set("n", "<leader>jc", function()
  local file_path = vim.fn.expand("%:p")
  local line = vim.fn.line(".")
  local col = vim.fn.col(".")
  local goto_arg = file_path .. ":" .. line .. ":" .. col

  local cwd = vim.fn.getcwd()
  vim.fn.jobstart({ "zed", cwd, goto_arg }, { detach = true })
end, { silent = true, desc = "Open in Zed" })

vim.keymap.set("v", "<leader>jy", function()
  local yank = require("utils.yank")
  yank.yank_visual_with_path(yank.get_buffer_cwd_relative(), "relative")
end, { desc = "[Y]ank selection with [R]elative path" })

vim.keymap.set("n", "<leader>jW", "<cmd>noautocmd write<CR>", { desc = "Save without formatting" })

vim.keymap.set("n", "<leader>cu", function()
  require("undotree").open()
end, { desc = "Undotree" })
