# dotfiles

Configuration files.

# install

Create a symlink using [GNU stow](https://www.gnu.org/software/stow/) for a `<package>` in the `<target directory>`.

```shell
stow -t <target directory> <package>
```

## Example

To link the nvim configuration to the home folder:

```shell
stow -t ~ nvim
```

# applications

Basic information about supported apllications.

## Neovim

Using [LazyVim](http://www.lazyvim.org/) as a plugin manager.
