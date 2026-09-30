#!/bin/bash
# 10 - LOCAL release: build everything (script 7), then publish release/ with the GitHub CLI.
# Works on a private repository on GitHub Free and uses no Actions minutes.
#   ./10-release-linux.sh --dry-run   build + show the exact gh command and the asset list; publish nothing
#   ./10-release-linux.sh             really publish tag v<VERSION from project.env> with every file in release/
# The version comes from project.env (VERSION=1.1.0 -> tag v1.1.0); edit it there, commit, then release.
# NOTE: a local build only holds THIS platform's assets. CI (the "v*" tag workflow) builds Windows +
# Linux + macOS; use this script when you want to release without CI (see docs/guide/releases-en.md).
set -e
cd "$(dirname "$0")"

DRYRUN=0
for a in "$@"; do [ "$a" = "--dry-run" ] && DRYRUN=1; done

. scripts/load-env-linux.sh
. scripts/detect-python-linux.sh
TAG="v$VERSION"
fail() { echo "[ERROR] $1" >&2; exit 1; }

echo "============================================================"
echo " Local release $TAG of $PROJECT_NAME  (platform $PLATFORM-$ARCH)"
echo "============================================================"

echo "[1/5] Refuse a dirty working tree (a release must come from a committed state)"
command -v git >/dev/null 2>&1 || fail "git not found on PATH."
if [ -n "$(git status --porcelain)" ]; then
    git status --short >&2
    fail "The working tree is not clean. Commit or stash your changes first."
fi

echo "[2/5] Check the GitHub CLI is installed and logged in"
if ! command -v gh >/dev/null 2>&1; then
    echo "[WARN] GitHub CLI 'gh' not found - see docs/guide/releases-en.md."
    [ "$DRYRUN" = "1" ] && echo "[DRY RUN] Continuing without gh - a real release needs it." || exit 1
elif ! gh auth status >/dev/null 2>&1; then
    echo "[WARN] gh is not logged in. Fix: gh auth login   (see docs/guide/releases-en.md)"
    [ "$DRYRUN" = "1" ] && echo "[DRY RUN] Continuing without a login - a real release needs it." || exit 1
fi

echo "[3/5] Build everything (7-build-all-linux.sh: reports, API docs, both sites, release/)"
./7-build-all-linux.sh || fail "The build failed - fix it before releasing."

echo "[4/5] Release notes"
"$PY" scripts/assemble.py notes
echo "Files in release/ (these become the release assets):"
ls -1 release

if [ "$DRYRUN" = "1" ]; then
    echo "[DRY RUN] Would run:"
    echo "  gh release create $TAG release/* --title \"$PROJECT_NAME $VERSION\" --notes-file build/release-notes.md"
    echo "[DRY RUN] No release was created and nothing was published."
    exit 0
fi

echo "[5/5] Publish with the GitHub CLI"
gh release create "$TAG" release/* --title "$PROJECT_NAME $VERSION" --notes-file build/release-notes.md \
    || fail "'gh release create' failed. Common causes: the tag $TAG already exists (raise VERSION in project.env), no write access, or an asset larger than 2 GiB."
echo "...................."
echo "Release $TAG published."
echo "...................."
