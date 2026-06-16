export DOTFILES_DIR="$HOME/development/gshahbazian/dotfiles"

# -----------------------
# path
# -----------------------
eval "$(/opt/homebrew/bin/brew shellenv)"

export GOPATH="$HOME/development/go"
typeset -U path PATH
path=(
  $DOTFILES_DIR/bin
  $HOME/.npm-global/bin
  $GOPATH/bin
  $HOME/.local/bin
  $path
)
