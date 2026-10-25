#!/usr/bin/env bash
# Adds all git repositories and worktrees under ~/projects to zoxide, so the project switcher lists them.

fd --hidden --no-ignore --max-depth 5 --exclude node_modules '^\.git$' "$HOME/projects" --format '{//}' |
	while read -r repo; do
		zoxide add "$repo"
	done
