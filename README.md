# dotfiles

This repository contains configuration files. Inspired by @typecraft-dev.

## install

For easy installation use the install script:

```shell
./install.sh
```

The install script uses [GNU stow](https://www.gnu.org/software/stow/) for creating symlinks in the home directory.

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

### iTerm

[iTerm 2](https://iterm2.com) may be used as the default terminal on macOS.

Themes for iTerm can be found on [https://iterm2colorschemes.com](https://iterm2colorschemes.com). Currently using `Catppuccin`.

Nerd fonts may be downloaded from [Nerd fonts](https://www.nerdfonts.com/). Currently using `Hack Nerd Font`. Set the font in the iTerm settings.

### NeoVim

Using [lazy.nvim](https://github.com/folke/lazy.nvim) as a plugin manager.

See [NeoVim for Java development](nvim/.config/nvim/README.md) for using NeoVim as a Java and Jakarta EE IDE.

### IdeaVim

Configuration for the [IdeaVim IntelliJ plugin](https://plugins.jetbrains.com/plugin/164-ideavim).

### tmux

Using [tmux](https://github.com/tmux/tmux/wiki) as a terminal multiplexer / for window tiling.

To Install all required plugins via TPM. Press `<leader> I` in any tmux session.

- **Projects**: one session per project. `<prefix> s` opens the project switcher ([sesh](https://github.com/joshmedeski/sesh)):
  running sessions, the sessions from `sesh/.config/sesh/sesh.toml` and all directories zoxide knows. Picking
  one opens or switches to its session, `ctrl+x` closes a session, `ctrl+o` toggles the preview.
  `~/scripts/zoxide-add-projects.sh` adds all git repositories under `~/projects` to zoxide.
  `<prefix> S` shows the tmux session tree.
- **Sessions survive a restart**: tmux-resurrect and tmux-continuum save them every 15 minutes and restore
  them when tmux starts.
- **Look**: Rosé Pine Moon (`tmux/.config/tmux/themes/`). The status line shows the windows and the session,
  plus a marker while the prefix is pressed or a pane is zoomed.

### Ghostty

[Ghostty](https://ghostty.org) is the terminal. Rosé Pine Moon in dark mode, Rosé Pine Dawn in light mode,
JetBrains Mono Nerd Font.

### zsh

The zsh configuration uses the [Ruby](https://www.ruby-lang.org/de/) gem [colorls](https://github.com/athityakumar/colorls). In this configuration Ruby is assumed to be installed via [Homebrew](https://brew.sh/).

### Aerospace

Using [Aerospace](https://github.com/nikitabobko/AeroSpace) as a window tiling manager.

### Sketchybar

Using [Sketchybar](https://github.com/FelixKratz/SketchyBar) for displaying workspaces.
