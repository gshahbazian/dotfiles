# dotfiles

Source the bashrc:

```bash
cd ~
echo "source ~/development/dotfiles/.bashrc" > .bashrc
```

Install other files by symlinking to home directory:

```bash
ln -sv ~/development/dotfiles/.inputrc ~
```
