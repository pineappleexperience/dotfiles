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
- **Look**: colours from the terminal palette (`tmux/.config/tmux/theme.conf`), so tmux follows the terminal
  theme. The status line shows the windows and the session, plus a marker while the prefix is pressed or a pane
  is zoomed.

### Ghostty

[Ghostty](https://ghostty.org) is the terminal. Rosé Pine Moon in dark mode, Rosé Pine Dawn in light mode,
JetBrains Mono Nerd Font.

### zsh

Plain zsh without a framework, starts in about 0.1s.

- **Prompt**: [Starship](https://starship.rs) (`starship/.config/starship.toml`): directory, git, Java/Node version
  inside projects, exit code of failed and duration of slow commands.
- **Node**: [fnm](https://github.com/Schniz/fnm) switches the Node version per project (`.nvmrc`, `.node-version`),
  yarn comes from corepack (`corepack enable` after installing a Node version).
- **Navigation**: [zoxide](https://github.com/ajeetdsouza/zoxide), `z <part of a path>` jumps to a known
  directory, `zi` picks one with fzf.
- **fzf**: `^T` inserts a file (with preview), `^F`, `^V` and `^R` are own widgets (see `.zsh/keybindings.zsh`).
- **Listing**: `ls`, `l`, `ll`, `la`, `lt` use [eza](https://eza.rocks).
- Vi mode, `v` in normal mode edits the command line in NeoVim.
- Colours come from the terminal palette, so prompt, fzf, eza and the syntax highlighting follow the terminal
  theme.

### Aerospace

Using [Aerospace](https://github.com/nikitabobko/AeroSpace) as a window tiling manager.

### Sketchybar

Using [Sketchybar](https://github.com/FelixKratz/SketchyBar) for displaying workspaces.
