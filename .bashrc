# If not running interactively, don't do anything
[ -z "$PS1" ] && return

export DOTFILES_DIR=$HOME/development/gshahbazian/dotfiles

#
# ALIAS
#

alias l="eza -la --git --no-user --icons=always"
alias ll="l"
alias tree="eza -a --git-ignore --tree --level=2 --git --no-user --icons=always"
alias cdd="cd ~/development"
alias nv="nvim"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias h="history"
alias path='echo -e "${PATH//:/\\n}"'

#
# ENV
#

export GOPATH=$HOME/development/go
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$DOTFILES_DIR/bin:$GOROOT/bin:$GOPATH/bin"

# https://mac.install.guide/ruby/13.html
if [ -d "/opt/homebrew/opt/ruby/bin" ]; then
  export PATH=/opt/homebrew/opt/ruby/bin:$PATH
  export PATH=$(gem environment gemdir)/bin:$PATH
fi

# Add Homebrew env vars.
eval "$(/opt/homebrew/bin/brew shellenv)"

# fnm
eval "$(fnm env --log-level=error --use-on-cd --version-file-strategy=recursive --corepack-enabled --shell bash)"

export EDITOR=nvim
export CLICOLOR=1

# Better history management
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="cd:pwd:exit:clear:history:ls:ll:eza:eza *:z *:zi:zi *:..:...:...."
export HISTTIMEFORMAT="%F %T "

# Append to history file, don't overwrite it
shopt -s histappend

# Check window size after each command and update LINES and COLUMNS
shopt -s checkwinsize

# Enable extended pattern matching
shopt -s extglob

# Enable ** for recursive matching
shopt -s globstar

# Save multi-line commands as one command
shopt -s cmdhist

# Correct minor errors in directory names during completion
shopt -s dirspell

# bash-completion
[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"
complete -r bun # remove bun completion cause its breaking file completion

# fzf
show_file_or_dir_preview="if [ -d {} ]; then eza --tree --level=2 --git --no-user --icons=always {}; else bat --style=numbers --color=always --line-range=:501 {}; fi"
export FZF_DEFAULT_OPTS="--style=full --bind='ctrl-/:toggle-preview' --preview-window=hidden --preview='$show_file_or_dir_preview'"
export FZF_CTRL_T_OPTS="--preview-window=nohidden --layout=reverse"
export FZF_ALT_C_OPTS="--preview-window=nohidden --layout=reverse"
export FZF_COMPLETION_OPTS="--preview-window=nohidden --layout=reverse --walker-skip=.git,node_modules"
export FZF_COMPLETION_PATH_OPTS="--walker=file,dir,follow,hidden"
export FZF_COMPLETION_DIR_OPTS="--walker=dir,follow,hidden"
eval "$(fzf --bash)"

export BAT_THEME="rose-pine"

#
# PROMPT
#

eval "$(starship init bash)"

function set_win_title() {
  local path="$PWD"
  [[ "$path" == "$HOME"* ]] && path="~${path#$HOME}"
  echo -ne "\033]0;$path\007"
}
starship_precmd_user_func="set_win_title"

# nvim was causing problems not existing cleanly
trap '[[ -n "$NVIM" ]] && tput rmcup' EXIT

# zoxide
eval "$(zoxide init bash)"
