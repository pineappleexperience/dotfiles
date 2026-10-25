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

Using [lazy.nvim](https://github.com/folke/lazy.nvim) as a plugin manager. Colorscheme
[Rosé Pine](https://github.com/rose-pine/neovim): Moon when the terminal is dark, Dawn when it is light. NeoVim
detects the terminal background and follows when it changes.

See [NeoVim for Java development](nvim/.config/nvim/README.md) for using NeoVim as a Java and Jakarta EE IDE.

### IdeaVim

Configuration for the [IdeaVim IntelliJ plugin](https://plugins.jetbrains.com/plugin/164-ideavim). The key
bindings mirror the NeoVim configuration.

Same look as the terminal:

1. Install the plugin [Rose Pine Theme](https://plugins.jetbrains.com/plugin/28154-rose-pine-theme)
   (Settings → Plugins → Marketplace).
2. Settings → Appearance & Behavior → Appearance: enable **Sync with OS**, choose **Rose Pine Moon** as the dark
   and **Rose Pine Dawn** as the light theme (the `Islands` variants with the new UI). The editor colour scheme
   comes with the theme.
3. Settings → Editor → Font: **JetBrains Mono**, size 13.
4. Settings → Tools → Terminal: font **JetBrainsMono Nerd Font Mono**, so the prompt icons render.

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

### Git

- `git/.config/git/config` is read in addition to `~/.gitconfig`: [delta](https://github.com/dandavison/delta)
  shows diffs with syntax highlighting and line numbers (`n`/`N` jump between files), moved lines are marked,
  merge conflicts show the common ancestor. `~/scripts/delta-pager.sh` picks Rosé Pine Moon or Dawn from the
  macOS appearance.
- [lazygit](https://github.com/jesseduffield/lazygit) (`lazygit/.config/lazygit/config.yml`, `<leader>gl` in
  NeoVim): terminal colours, delta side by side in wide views, files open in the surrounding NeoVim.
- [bat](https://github.com/sharkdp/bat) has the Rosé Pine themes (`bat/.config/bat/themes`), delta uses them too.
  After changing them run `bat cache --build`.

### Aerospace

Using [Aerospace](https://github.com/nikitabobko/AeroSpace) as a window tiling manager.

### Sketchybar

[Sketchybar](https://github.com/FelixKratz/SketchyBar) replaces the macOS menu bar (System Settings → Control
Center → "Automatically hide and show the menu bar": Always). AeroSpace starts it. Rosé Pine Moon or Dawn,
following the macOS appearance.

- Left: AeroSpace workspaces with windows (with app icons, the current one highlighted, clickable) on the
  display of their monitor, the active app.
- Right, only when relevant: GitLab (merge requests to review, failed and running pipelines of my merge
  requests, only while the VPN is connected), local servers listening on the ports in `settings.sh`, RAM,
  VPN or offline, headphones or another audio output, volume (click mutes), battery, date and time.
- `sketchybar/.config/sketchybar/settings.sh` holds the server ports, the VPN name and the GitLab host. The
  GitLab item needs `glab auth login --hostname <host>`.
