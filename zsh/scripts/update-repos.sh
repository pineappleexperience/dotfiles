#!/bin/sh
# Updates all Git repositories in the current directory

count=0

for dir in */; do
  # Skip if not a directory
  [ -d "$dir" ] || continue

  if [ -d "$dir/.git" ]; then
    echo "----------------------------------------"
    echo "Updating repository in: $dir"
    echo "----------------------------------------"
    (cd "$dir" && git pull)
    echo
    count=$((count + 1))
  else
    echo "Skipping $dir (not a Git repository)"
  fi
done

# Final summary
echo "✅ Pulled $count Git repositories."
