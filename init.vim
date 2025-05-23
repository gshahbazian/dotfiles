" ========== General ==========
set clipboard=unnamedplus     " Use system clipboard
set number                    " Show line numbers
set cursorline                " Highlight current line
set mouse=a                   " Enable mouse support

" ========== Indentation ==========
set expandtab                 " Use spaces instead of tabs
set shiftwidth=2              " Indent size for auto-indents
set tabstop=2                 " Number of spaces for a tab
set smartindent               " Smart auto-indenting
set autoindent                " Copy indent from current line

" ========== Searching ==========
set ignorecase                " Case-insensitive search...
set smartcase                 " ...unless uppercase letters are used
set incsearch                 " Show match while typing
set hlsearch                  " Highlight all search matches
nnoremap <leader><space> :nohlsearch<CR>  " <leader><space> to clear highlights

" ========== UI Enhancements ==========
set scrolloff=10              " Minimum lines above/below cursor
set confirm                   " Confirm before overwriting files
