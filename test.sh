#!/usr/bin/env bash
# This script executes test commands in a directory whenever
# files are deleted/changed/modified within it, or any subdirectories.

# Run when files are changed
TEST_CMD="zig build test"

USE_GITIGNORE=true
IGNORED_PATHS=("readme.md" ".png" ".git")

DIR_TO_WATCH="."

# Run on test success
SUCC_CMD='echo -e "$GREEN$(date +%H:%M:%S)  All tests passed.$NC"'
# Run on test failure
FAIL_CMD='echo -e "$RED$(date +%H:%M:%S)  Some tests failed.$NC"'

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "$BLUE Waiting for file modifications to run tests..."

# Use inotifywait to watch the directory recursively for
# create, delete, and modify events
inotifywait -q -m -r -e create -e delete -e modify --format '%w%f' "$DIR_TO_WATCH" | while read FILE
do
  SKIP=false

  # Check for explicit ignores
  for DIR in "${IGNORED_PATHS[@]}"; do
    if [[ "$FILE" == *"$DIR"* ]]; then
      SKIP=true
      break
    fi
  done

  if $USE_GITIGNORE; then
    # Respect git ignored files
    git check-ignore -q $FILE
    if [ $? -eq 0 ]; then
      SKIP=true
    fi
  fi

  if [ "$SKIP" = true ]; then
    continue
  fi

  clear
  echo "File $FILE changed. Re-running tests:"
  if $TEST_CMD; then
    eval "$SUCC_CMD"
  else
    eval "$FAIL_CMD"
  fi
done

