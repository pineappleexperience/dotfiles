# dotfiles

Configuration files.

## install

Create a symlink using [GNU stow](https://www.gnu.org/software/stow/) for a `<package>` in the `<target directory>`.

```shell
stow -t <target directory> <package>
```

### Example

To link the NeoVim configuration to the home folder:

```shell
stow -t ~ nvim
```

## applications

Basic information about supported apllications.

### NeoVim

Using [LazyVim](http://www.lazyvim.org/) as a plugin manager.

### zsh

See [README of zshrc](./zshrc/README.md).
