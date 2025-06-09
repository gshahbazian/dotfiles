set clipboard=unnamedplus
set number
set relativenumber
set cursorline
set mouse=a

set expandtab
set shiftwidth=2
set tabstop=2
set smartindent
set autoindent

set ignorecase
set smartcase
set incsearch
set hlsearch
nnoremap <Esc> :nohlsearch<CR>

set scrolloff=10
set confirm

augroup highlight_yank
    autocmd!
    au TextYankPost * silent! lua vim.highlight.on_yank({higroup="IncSearch", timeout=700})
augroup END
