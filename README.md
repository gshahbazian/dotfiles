# dotfiles

Source the bash_profile:

```bash
cd ~
echo "source ~/development/dotfiles/.bash_profile" > .bash_profile
```

Install other files by symlinking to home directory:

```bash
ln -sv ~/development/dotfiles/.inputrc ~
```
