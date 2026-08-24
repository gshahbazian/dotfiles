# dotfiles

Source the zshrc:

```bash
cd ~
echo "source ~/development/gshahbazian/dotfiles/.zshrc" > .zshrc
```

Install other files by symlinking to correct directory:

```bash
ln -sv ~/development/gshahbazian/dotfiles/git ~/.config
```

Update the Brewfile:

```
brew bundle dump --file="./Brewfile" --force --no-npm --no-cargo --no-go --no-uv
```
