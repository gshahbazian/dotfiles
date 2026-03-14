-- flash.nvim
require("flash").setup({})

-- trouble.nvim
require("trouble").setup({
  modes = {
    lsp = {
      win = { position = "right" },
    },
  },
})

-- todo-comments.nvim
require("todo-comments").setup({})

-- gitsigns.nvim
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

-- stay-centered.nvim
require("stay-centered").setup({ enabled = true })

-- persistence.nvim
require("persistence").setup({})
