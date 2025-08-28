export DOTFILES_DIR="$HOME/development/gshahbazian/dotfiles"

export EDITOR="nvim"
export CLICOLOR=1

# -----------------------
# history
# -----------------------
HISTSIZE=10000
SAVEHIST=20000
HISTFILE="$HOME/.zsh_history"

# setopt share_history           # share across sessions
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

setopt correct            # command spelling correction
setopt extended_glob      # like extglob
unsetopt nomatch          # don't error on unmatched globs

fpath+=("$HOME/.zfunc")

# -----------------------
# aliases
# -----------------------
alias l='eza -la --git --no-user --icons=always'
alias ll='l'
alias tree='eza -a --git-ignore --tree --level=2 --git --no-user --icons=always'
alias cdd='cd ~/development'
alias nv='nvim'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias h='history'
alias path='printf "%s\n" $path'

# -----------------------
# path
# -----------------------
export GOPATH="$HOME/development/go"
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$HOME/.local/bin:$HOME/.npm-global/bin:$DOTFILES_DIR/bin:$GOPATH/bin"

eval "$(/opt/homebrew/bin/brew shellenv)"
autoload -Uz compinit && compinit

eval "$(fnm env --log-level=error --use-on-cd --version-file-strategy=recursive --corepack-enabled --shell zsh)"
eval "$(uv generate-shell-completion zsh)"

# -----------------------
# fzf
# -----------------------
show_file_or_dir_preview='if [ -d {} ]; then eza --tree --level=2 --git --no-user --icons=always {}; else bat --style=numbers --color=always --line-range=:501 {}; fi'
export FZF_DEFAULT_OPTS="--style=full --bind='ctrl-/:toggle-preview' --preview-window=hidden --preview='$show_file_or_dir_preview'"
export FZF_CTRL_T_OPTS="--preview-window=nohidden --layout=reverse"
export FZF_ALT_C_OPTS="--preview-window=nohidden --layout=reverse"
export FZF_COMPLETION_OPTS="--preview-window=nohidden --layout=reverse --walker-skip=.git,node_modules"
export FZF_COMPLETION_PATH_OPTS="--walker=file,dir,follow,hidden"
export FZF_COMPLETION_DIR_OPTS="--walker=dir,follow,hidden"
source <(fzf --zsh)

export BAT_THEME="rose-pine"

# -----------------------
# starship
# -----------------------
eval "$(starship init zsh)"

function set_win_title() {
  local path="$PWD"
  [[ "$path" == "$HOME"* ]] && path="~${path#$HOME}"
  print -n "\033]0;$path\007"
}
starship_precmd_user_func="set_win_title"

# -----------------------
# zoxide
# -----------------------
eval "$(zoxide init zsh)"

# -----------------------
# keybinds
# -----------------------
bindkey -e                                   # emacs mode (default, explicit)
bindkey '^[[A' history-beginning-search-backward
bindkey '^[[B' history-beginning-search-forward

# -----------------------
# plugins
# -----------------------
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
