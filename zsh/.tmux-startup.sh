#!/usr/bin/env bash

# Start a session "projects" in ~/projects if it doesn't exist
tmux has-session -t projects 2>/dev/null
if [ $? != 0 ]; then
  tmux new-session -ds projects -c "$HOME/projects"
fi

# Start a session "notes" in ~/Documents/notes if it doesn't exist
tmux has-session -t notes 2>/dev/null
if [ $? != 0 ]; then
  tmux new-session -ds notes -c "$HOME/Documents/notes"
fi

# Start a session "dotfiles" in ~/Documents/dotfiles if it doesn't exist
tmux has-session -t dotfiles 2>/dev/null
if [ $? != 0 ]; then
  tmux new-session -ds dotfiles -c "$HOME/projects/personal/dotfiles"
fi

