#!/bin/bash

# This script finds and deletes all old golden files and snapshots.
# This is useful for cleaning the environment before regenerating all screenshots.

echo "(1/2) Clearing all old golden files under test/**/goldens/..."

# Use the find command to safely find and delete golden files
# -path: matches the path pattern
# -type f: finds files only
# -name "*.png": finds all files ending with .png
# -print: prints the file path before deleting
# -delete: performs the delete operation
find ./test -path '*/goldens/*.png' -type f -name "*.png" -print -delete
echo "Old golden files have been cleared."

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

echo "\nAll old golden files and snapshots have been successfully cleared."
