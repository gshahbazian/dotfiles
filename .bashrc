# If not running interactively, don't do anything
[ -z "$PS1" ] && return

export DOTFILES_DIR=$HOME/development/gshahbazian/dotfiles

#
# ALIAS
#

alias ll="ls -lahL"
alias la="ls -A"
alias l="ls -CF"
alias cdd="cd ~/development"
alias nv="nvim"
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias mkdir="mkdir -pv"
alias h="history"
alias path='echo -e "${PATH//:/\\n}"'
alias yolo="claude --dangerously-skip-permissions"

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

export CLICOLOR=1

# Better history management
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="ls:ll:cd:pwd:exit:clear:history"
export HISTTIMEFORMAT="%F %T "

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

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

[[ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]] && . "/opt/homebrew/etc/profile.d/bash_completion.sh"

export FZF_DEFAULT_OPTS="--style full --preview 'bat --style=numbers --color=always --line-range=:500 {}' --preview-window=right:60%"
eval "$(fzf --bash)"

#
# PROMPT
#

_bash_prompt_config() {
  local USER_SYMBOL="\u"
  local ESC_OPEN="\["
  local ESC_CLOSE="\]"

  if tput setaf >/dev/null 2>&1; then
    _setaf() { tput setaf "$1"; }
    local RESET="${ESC_OPEN}$({ tput sgr0 || tput me; } 2>/dev/null)${ESC_CLOSE}"
  else
    # Fallback
    _setaf() { echo "\033[0;$(($1 + 30))m"; }
    local RESET="\033[m"
    ESC_OPEN=""
    ESC_CLOSE=""
  fi

  # Colors
  local YELLOW="${ESC_OPEN}$(_setaf 3)${ESC_CLOSE}"
  local GREEN="${ESC_OPEN}$(_setaf 10)${ESC_CLOSE}"
  local VIOLET="${ESC_OPEN}$(_setaf 13)${ESC_CLOSE}"

  # Expose the variables we need in prompt command
  P_USER=${VIOLET}${USER_SYMBOL}
  P_GREEN=${GREEN}
  P_YELLOW=${YELLOW}
  P_RESET=${RESET}
}

bash_prompt_command() {
  local MAXLENGTH=35
  local TRUNC_SYMBOL=".."
  local DIR=${PWD##*/}
  local P_PWD=${PWD/#$HOME/\~}

  MAXLENGTH=$(((MAXLENGTH < ${#DIR}) ? ${#DIR} : MAXLENGTH))

  local OFFSET=$((${#P_PWD} - MAXLENGTH))

  if [ ${OFFSET} -gt "0" ]; then
    P_PWD=${P_PWD:$OFFSET:$MAXLENGTH}
    P_PWD=${TRUNC_SYMBOL}/${P_PWD#*/}
  fi

  # Git branch name
  P_GIT=$(parse_git_branch)

  PS1="\[\033]0;\w\007\]\[\033[1m\]${P_USER} ${P_YELLOW}${P_PWD}${P_GREEN}${P_GIT}${P_YELLOW} $ ${P_RESET}"
}

parse_git_branch() {
  local OUT=$(git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
  if [ "$OUT" != "" ]; then echo " $OUT"; fi
}

_bash_prompt_config
unset _bash_prompt_config

PROMPT_COMMAND=bash_prompt_command
