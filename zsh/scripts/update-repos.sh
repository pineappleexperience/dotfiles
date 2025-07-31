#!/bin/sh
# Updates all repos in the current directory
find . -maxdepth 1 -type d -exec sh -c '(cd {} && git pull)' ';'
