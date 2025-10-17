#!/bin/bash

# This script finds and deletes all old golden files and snapshots.
# This is useful for cleaning the environment before regenerating all screenshots.

echo "(1/2) Clearing all old golden directories under test/**/..."

# Use the find command to safely find and delete golden directories
# -type d: finds directories only
# -name "goldens": finds all directories named "goldens"
# -print: prints the directory path before deleting
# -exec rm -rf {} +: performs the delete operation
find ./test -type d -name "goldens" -print -exec rm -rf {} +
echo "Old golden directories have been cleared."

echo "---------------------------------"

echo "(2/2) Clearing all content under the snapshots/ directory..."

# Check if the snapshots directory exists
if [ -d "snapshots" ]; then
  # Delete all files and subdirectories within the snapshots directory
  rm -rf snapshots/*
  echo "Contents of snapshots/ directory have been cleared."
else
  echo "snapshots/ directory not found, skipping."
fi

echo "
All old golden files and snapshots have been successfully cleared."