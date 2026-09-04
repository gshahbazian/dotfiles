export DOTFILES_DIR="$HOME/development/gshahbazian/dotfiles"

# -----------------------
# path
# -----------------------
eval "$(/opt/homebrew/bin/brew shellenv)"

export GOPATH="$HOME/development/go"
export PNPM_HOME="$HOME/Library/pnpm"
typeset -U path PATH
path=(
  $DOTFILES_DIR/bin
  $PNPM_HOME/bin
  $HOME/.local/npm/bin
  $GOPATH/bin
  $HOME/.local/bin
  $path
)
