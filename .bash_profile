# If not running interactively, don't do anything
[ -z "$PS1" ] && return

export DOTFILES_DIR=$HOME/development/mac-cofig

#
# ALIAS
#

alias ll="ls -lahL"

#
# ENV
#

export GOPATH=$HOME/development/go
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$DOTFILES_DIR/bin:$GOROOT/bin:$GOPATH/bin"
export CLICOLOR=1
export LSCOLORS=gxfxcxdxbxegedabagacad

# Tell grep to highlight matches
export GREP_OPTIONS='—color=auto'

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion

ulimit -n 10000

#
# PROMPT
#

_bash_prompt_config() {
  local USER_SYMBOL="\u"
  local ESC_OPEN="\["
  local ESC_CLOSE="\]"

  if tput setaf >/dev/null 2>&1 ; then
    _setaf () { tput setaf "$1" ; }
    local RESET="${ESC_OPEN}$( { tput sgr0 || tput me ; } 2>/dev/null )${ESC_CLOSE}"
    local BOLD="$( { tput bold || tput md ; } 2>/dev/null )"
  else
    # Fallback
    _setaf () { echo "\033[0;$(($1+30))m" ; }
    local RESET="\033[m"
    local BOLD=""
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

  MAXLENGTH=$(( ( MAXLENGTH < ${#DIR} ) ? ${#DIR} : MAXLENGTH ))

  local OFFSET=$(( ${#P_PWD} - MAXLENGTH ))

  if [ ${OFFSET} -gt "0" ]; then
    P_PWD=${P_PWD:$OFFSET:$MAXLENGTH}
    P_PWD=${TRUNC_SYMBOL}/${P_PWD#*/}
  fi

  # Git branch name
  P_GIT=$(parse_git_branch)

  PS1="${P_USER} ${P_YELLOW}${P_PWD}${P_GREEN}${P_GIT}${P_YELLOW} $ ${P_RESET}"
}

parse_git_branch() {
  local OUT=$(git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/')
  if [ "$OUT" != "" ]; then echo " $OUT"; fi
}

_bash_prompt_config
unset _bash_prompt_config

PROMPT_COMMAND=bash_prompt_command

# Clean up
unset READLINK CURRENT_SCRIPT SCRIPT_PATH