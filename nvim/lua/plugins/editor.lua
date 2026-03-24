-- ide type plugins that should not load in the vscode extension

require("noice").setup({
  lsp = {
    override = {
      ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
      ["vim.lsp.util.stylize_markdown"] = true,
    },
    hover = {
      silent = true,
    },
  },
  cmdline = { enabled = false },
  messages = { enabled = false },
  notify = {
    view = "mini",
  },
  views = {
    mini = {
      position = { row = -2 },
    },
  },
  presets = {
    bottom_search = true,
    long_message_to_split = true,
  },
})

require("which-key").setup({
  preset = "helix",
  icons = {
    mappings = false,
  },
  spec = {
    {
      mode = { "n", "x" },
      { "<leader>c", group = "code" },
      { "<leader>r", group = "lsp pickers" },
      { "<leader>f", group = "file" },
      { "<leader>g", group = "git" },
      { "<leader>gh", group = "hunks" },
      { "<leader>j", group = "util" },
      { "<leader>l", group = "vim.pack" },
      { "<leader>q", group = "quit/session" },
      { "<leader>s", group = "search" },
      { "<leader>x", group = "diagnostics/quickfix" },
      { "[", group = "prev" },
      { "]", group = "next" },
      { "g", group = "goto" },
      { "gr", group = "lsp" },
      { "gs", group = "surround" },
      { "z", group = "fold" },
      {
        "<leader>b",
        group = "buffer",
        expand = function()
          return require("which-key.extras").expand.buf()
        end,
      },
      {
        "<leader>w",
        group = "windows",
        proxy = "<c-w>",
        expand = function()
          return require("which-key.extras").expand.win()
        end,
      },

      -- rm jank
      { "<leader>y", hidden = true },
      { "<leader>p", hidden = true },
      { "<leader>P", hidden = true },
      { "<leader>K", hidden = true },
    },
  },
})

require("blink.cmp").setup({
  keymap = {
    ["<C-y>"] = { "select_and_accept" },
  },
  completion = {
    menu = {
      draw = { treesitter = { "lsp" } },
    },
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 200,
    },
  },
  sources = {
    default = { "lsp", "path", "snippets", "buffer", "lazydev" },
    providers = {
      lazydev = {
        name = "LazyDev",
        module = "lazydev.integrations.blink",
        score_offset = 100,
      },
    },
  },
  cmdline = {
    keymap = { preset = "cmdline" },
    completion = {
      list = { selection = { preselect = false } },
      menu = {
        auto_show = function()
          return vim.fn.getcmdtype() == ":"
        end,
      },
      ghost_text = { enabled = true },
    },
  },
})

require("trouble").setup({
  modes = {
    lsp = {
      win = { position = "right" },
    },
  },
})

require("todo-comments").setup()

require("gitsigns").setup({
  signs = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
    untracked = { text = "▎" },
  },
  signs_staged = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "" },
    topdelete = { text = "" },
    changedelete = { text = "▎" },
  },
  current_line_blame = true,
  on_attach = function(buffer)
    local gs = package.loaded.gitsigns

    local function map(mode, l, r, desc)
      vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc, silent = true })
    end

    map("n", "]h", function()
      if vim.wo.diff then
        return vim.cmd.normal({ "]c", bang = true })
      end
      gs.nav_hunk("next")
    end, "Next Hunk")
    map("n", "[h", function()
      if vim.wo.diff then
        return vim.cmd.normal({ "[c", bang = true })
      end
      gs.nav_hunk("prev")
    end, "Prev Hunk")
    map("n", "]H", function()
      gs.nav_hunk("last")
    end, "Last Hunk")
    map("n", "[H", function()
      gs.nav_hunk("first")
    end, "First Hunk")
    map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
    map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
    map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
    map("n", "<leader>ghP", gs.preview_hunk, "Preview Hunk Floating")
    map("n", "<leader>ghb", function()
      gs.blame_line({ full = true })
    end, "Blame Line")
    map("n", "<leader>ghB", function()
      gs.blame()
    end, "Blame Buffer")
    map("n", "<leader>ghd", gs.diffthis, "Diff This")
    map("n", "<leader>ghD", function()
      gs.diffthis("~")
    end, "Diff This ~")
    map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
  end,
})

require("stay-centered").setup({
  skip_filetypes = { "snacks_dashboard" },
})

require("persistence").setup()

local hi = require("mini.hipatterns")
hi.setup({
  highlighters = {
    hex_color = hi.gen_highlighter.hex_color(),
  },
})
