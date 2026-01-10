export DOTFILES_DIR="$HOME/development/gshahbazian/dotfiles"

export EDITOR="nvim"
export CLICOLOR=1

# -----------------------
# history
# -----------------------
HISTSIZE=10000
SAVEHIST=20000
HISTFILE="$HOME/.zsh_history"

setopt append_history          # append, don't clobber
setopt inc_append_history      # write immediately
setopt extended_history        # timestamps etc.
setopt hist_ignore_all_dups    # drop older dups on add
setopt hist_find_no_dups       # don't show dup matches during search
setopt hist_reduce_blanks      # trim superfluous blanks
setopt hist_ignore_space       # ignore commands starting with a space

# -----------------------
# completions
# -----------------------
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors ''

setopt correct
setopt extended_glob
unsetopt nomatch

fpath+=("$HOME/.zfunc")

# -----------------------
# aliases
# -----------------------
alias ll='eza -la --git --no-user --icons=always'
alias cdd='cd ~/development'
alias nv='nvim'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias path='printf "%s\n" $path'
alias viewpr='gh pr view --web'
alias p='pnpm'

# -----------------------
# path
# -----------------------
export GOPATH="$HOME/development/go"
typeset -U path PATH
path=(
  $DOTFILES_DIR/bin
  $HOME/.npm-global/bin
  $GOPATH/bin
  $HOME/.local/bin
  $path
)

eval "$(/opt/homebrew/bin/brew shellenv)"
autoload -Uz compinit && compinit

eval "$(fnm env --log-level=error --use-on-cd --version-file-strategy=recursive --corepack-enabled --shell zsh)"
eval "$(uv generate-shell-completion zsh)"

# -----------------------
# fzf
# -----------------------
show_file_or_dir_preview='if [ -d {} ]; then eza --tree --level=2 --icons=always {}; else bat --style=numbers --color=always --line-range=:501 {}; fi'

export FZF_DEFAULT_OPTS="
  --style=full
  --bind='ctrl-/:toggle-preview'
  --preview-window=hidden
  --preview='$show_file_or_dir_preview'"
export FZF_CTRL_T_OPTS="--preview-window=nohidden --layout=reverse"
export FZF_ALT_C_OPTS="--preview-window=nohidden --layout=reverse"
export FZF_COMPLETION_OPTS="--preview-window=nohidden --layout=reverse --walker-skip=.git,node_modules"
export FZF_COMPLETION_PATH_OPTS="--walker=file,dir,follow,hidden"
export FZF_COMPLETION_DIR_OPTS="--walker=dir,follow,hidden"
source <(fzf --zsh)

export BAT_THEME="base16"

# -----------------------
# starship
# -----------------------
eval "$(starship init zsh)"

# -----------------------
# zoxide
# -----------------------
eval "$(zoxide init zsh)"

# -----------------------
# keybinds
# -----------------------
bindkey -e
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line

# -----------------------
# plugins
# -----------------------
BREW_PREFIX="$(/opt/homebrew/bin/brew --prefix)"
source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
ZSH_HIGHLIGHT_STYLES[command]='fg=white,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=white,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=white,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=white,bold'
