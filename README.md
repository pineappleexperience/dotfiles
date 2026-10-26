# dotfiles

Configuration of my development environment on macOS: [Ghostty](https://ghostty.org) as terminal,
[tmux](https://github.com/tmux/tmux/wiki) with one session per project, zsh, [NeoVim](https://neovim.io) as Java
IDE, [AeroSpace](https://github.com/nikitabobko/AeroSpace) as tiling window manager and
[Sketchybar](https://github.com/FelixKratz/SketchyBar) as menu bar. Inspired by @typecraft-dev.

Everything uses the same look: the [Rosé Pine](https://rosepinetheme.com) palette, **Moon** when macOS is dark,
**Dawn** when it is light, and **JetBrains Mono** as font. Each tool follows the macOS appearance on its own, see
[Look](#look).

## Install

```shell
./install.sh
```

The script installs [Homebrew](https://brew.sh) if needed, all tools, fonts and apps from the `Brewfile`
(`brew bundle`), links the configuration into the home directory with [GNU stow](https://www.gnu.org/software/stow/)
and builds bat's theme cache. It can be run again at any time.

A single package can be linked by hand:

```shell
stow -t ~ nvim
```

Manual steps after the first installation:

1. Homebrew refuses formulae from taps it does not trust. Sketchybar comes from one:
   `brew trust felixkratz/formulae`, then run `./install.sh` again.
2. macOS: System Settings → Control Center → "Automatically hide and show the menu bar": **Always** (Sketchybar
   replaces it).
3. tmux: `<prefix> I` installs the tmux plugins (prefix is `Ctrl+b`).
4. NeoVim: start it once so lazy.nvim and Mason install the plugins and language servers, then
   `:NeotestJava setup`.
5. Node: `fnm install --lts`, then `corepack enable` for yarn.
6. GitLab: `glab auth login --hostname <host>` for merge request reviews in NeoVim and the Sketchybar item.
7. IntelliJ: theme and font, see [IdeaVim](#ideavim).
8. `~/scripts/zoxide-add-projects.sh` makes all git repositories under `~/projects` known to the project
   switcher.

## Daily use

| What | How |
|------|-----|
| Switch to a project (opens a tmux session for it) | `<prefix> s`, type part of the name, Enter |
| Session for any directory | `sesh connect <dir>` in the shell, e.g. `sesh connect .` |
| Jump to a directory | `z <part of the path>`, `zi` to pick one |
| Find a file / text / class in NeoVim | `<leader>sf` / `<leader>sg` / `<leader>sc` |
| Build, run configurations, servers | `<leader>r…` and `<leader>w…` in NeoVim, see the [NeoVim README](nvim/.config/nvim/README.md) |
| Git | `<leader>gl` lazygit, `<leader>gd` diff, `<leader>gr` review the branch |
| Workspaces | `Alt+<letter>`, Ghostty is on `U`, IntelliJ on `I` |

## Look

| Tool | How it follows dark and light |
|------|-------------------------------|
| Ghostty | `theme = light:Rose Pine Dawn,dark:Rose Pine Moon` |
| tmux, Starship, fzf, eza, lazygit, zsh syntax highlighting | use the terminal's 16 colours, which Ghostty sets |
| NeoVim | detects the terminal background and reloads the colorscheme |
| bat, delta in lazygit | detect the terminal background |
| delta on the command line | `~/scripts/delta-pager.sh` asks macOS |
| Sketchybar | reloads its colours when macOS switches |
| IntelliJ | "Sync with OS" with the Rose Pine Theme plugin |

## Applications

### Ghostty

The terminal (`ghostty/.config/ghostty/config`): Rosé Pine, JetBrainsMono Nerd Font Mono 13, no title bar
(AeroSpace manages the windows, tmux provides the tabs). Option keeps typing special characters on the German
keyboard, so it does not work as Alt in terminal programs.

### tmux

Prefix `Ctrl+b`. The status line at the top shows the windows and the session, plus a marker while the prefix is
pressed or a pane is zoomed.

| Keys | Action |
|------|--------|
| `<prefix> s` | Project switcher ([sesh](https://github.com/joshmedeski/sesh)): running sessions, the sessions from `sesh/.config/sesh/sesh.toml` and all directories zoxide knows. `ctrl+x` closes a session, `ctrl+o` toggles the preview, `#` numbers the rows |
| `<prefix> S` | Session tree, numbered from 1 |
| `<prefix> L` | Last session |
| `<prefix> w` / `"` / `%` | New window / split below / split right, in the current directory |
| `Ctrl+h/j/k/l` | Move between tmux panes and NeoVim windows ([vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)) |
| `<prefix> r` | Reload the configuration |

A new shell outside tmux attaches to the running tmux or starts it. tmux-resurrect and tmux-continuum save the
sessions every 15 minutes and restore them when tmux starts. Colours: `tmux/.config/tmux/theme.conf`.

### zsh

Plain zsh without a framework (`zsh/.zshrc`), starts in about 0.1s.

- **Prompt**: [Starship](https://starship.rs) (`starship/.config/starship.toml`), two lines: directory, git,
  Java/Node version inside projects, exit code of failed and duration of slow commands, then the input.
- **Node**: [fnm](https://github.com/Schniz/fnm) switches the Node version per project (`.nvmrc`, `.node-version`),
  yarn comes from corepack.
- **Java**: `javas` lists the installed JDKs, `juse <version>` switches the current shell.
- **Navigation**: [zoxide](https://github.com/ajeetdsouza/zoxide): `z <part of a path>`, `zi`.
- **fzf**: `^T` inserts a file (with preview). Own widgets in `zsh/.zsh/keybindings.zsh`: `^F` inserts a file,
  `^V` opens a file in NeoVim, `^R` changes into a directory, `^G` git status.
- **Listing**: `ls`, `l`, `ll`, `la`, `lt` use [eza](https://eza.rocks).
- **Aliases**: `zsh/.aliases` (Maven, git, Docker, Java). Typed aliases expand on space
  (`zsh/.zsh/alias-expansion.zsh`).
- Vi mode, `v` in normal mode edits the command line in NeoVim.

### NeoVim

[lazy.nvim](https://github.com/folke/lazy.nvim) manages the plugins, [Mason](https://github.com/mason-org/mason.nvim)
the language servers. Colorscheme [Rosé Pine](https://github.com/rose-pine/neovim).

[NeoVim for Java development](nvim/.config/nvim/README.md) explains the setup in detail: navigation, Java
(jdtls, Lombok, Spotless), builds and run configurations, Tomcat, debugging, tests, Git reviews, databases,
tabs and splits.

### IdeaVim

[IdeaVim](https://plugins.jetbrains.com/plugin/164-ideavim) configuration (`ideavim/.ideavimrc`). The key
bindings mirror the NeoVim configuration.

Same look as the terminal:

1. Install the plugin [Rose Pine Theme](https://plugins.jetbrains.com/plugin/28154-rose-pine-theme)
   (Settings → Plugins → Marketplace).
2. Settings → Appearance & Behavior → Appearance: enable **Sync with OS**, choose **Rose Pine Moon** as the dark
   and **Rose Pine Dawn** as the light theme (the `Islands` variants with the new UI). The editor colour scheme
   comes with the theme.
3. Settings → Editor → Font: **JetBrains Mono**, size 13.
4. Settings → Tools → Terminal: font **JetBrainsMono Nerd Font Mono**, so the prompt icons render.

### Git

- `git/.config/git/config` is read in addition to `~/.gitconfig`: [delta](https://github.com/dandavison/delta)
  shows diffs with syntax highlighting and line numbers (`n`/`N` jump between files), moved lines are marked,
  merge conflicts show the common ancestor. The global ignore file is `git/.config/git/ignore`.
- [lazygit](https://github.com/jesseduffield/lazygit) (`lazygit/.config/lazygit/config.yml`, `<leader>gl` in
  NeoVim): delta side by side in wide views, files open in the surrounding NeoVim.
- [bat](https://github.com/sharkdp/bat) has the Rosé Pine themes (`bat/.config/bat/themes`), delta uses them too.
  After changing them run `bat cache --build`.

### AeroSpace

Tiling window manager (`aerospace/.config/aerospace/aerospace.toml`). `Alt+<letter or digit>` switches to a
workspace, `Alt+Shift+<letter or digit>` moves the window there, `Alt+Tab` goes back to the previous workspace.
Apps open on fixed workspaces (Ghostty on `U`, IntelliJ on `I`, Outlook on `M`, …). AeroSpace starts Sketchybar and
leaves room for it at the top.

### Sketchybar

Replaces the macOS menu bar (`sketchybar/.config/sketchybar`). The bar is transparent, both sides sit on rounded
backgrounds.

- Left: the AeroSpace workspaces with windows (app icons, the current one highlighted, clickable) on the display
  of their monitor, the active app.
- Right, only when relevant: GitLab (merge requests to review, failed and running pipelines of my merge
  requests, only while the VPN is connected), local servers listening on the configured ports, RAM, VPN or
  offline, headphones or another audio output, volume (click mutes), battery, date and time.
- `settings.sh` holds the server ports, the VPN name and the GitLab host.
