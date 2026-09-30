#!/bin/bash

echo ":::: DELETE GOOGLE DRIVE desktop.ini FILES ::::"

# Save the current directory
currentDir=$(pwd)

echo "Get the current directory: $currentDir"

echo "Change the current working directory to the script directory"
cd "$(dirname "$0")/.."

# Find and delete desktop.ini files, and remove them from Git index
find . -name 'desktop.ini' -print0 | while IFS= read -r -d '' file; do
    if [ -f "$file" ]; then
        git rm --cached --force "$file"
        rm "$file"
        echo "Removed $file"
    fi
done

echo ":::: DELETE OPERATION COMPLETED ::::"

# Wait for user input before exiting, but never in CI/non-interactive runs
# (CI=true is set by GitHub Actions and by this repo's own test runs).
if [ -z "$CI" ] && [ -t 0 ]; then
    read -p "Press any key to continue..." -n1 -s
    echo
fi
