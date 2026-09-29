#!/bin/bash
set -e

# Change the current working directory to the script directory
cd "$(dirname "$0")"

HOOKS_DIR=".git/hooks"

if [ ! -d "$HOOKS_DIR" ]; then
    echo "[!] $HOOKS_DIR directory not found. Run this from a git clone." >&2
    exit 1
fi

if [ -f "$HOOKS_DIR/pre-commit" ]; then
    echo "Backing up current pre-commit script..."
    mv "$HOOKS_DIR/pre-commit" "$HOOKS_DIR/pre-commit.backup"
fi
cp "pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"

if [ -f "$HOOKS_DIR/pre-push" ]; then
    echo "Backing up current pre-push script..."
    mv "$HOOKS_DIR/pre-push" "$HOOKS_DIR/pre-push.backup"
fi
cp "pre-push" "$HOOKS_DIR/pre-push"
chmod +x "$HOOKS_DIR/pre-push"

echo "Scripts has been copied successfully."
