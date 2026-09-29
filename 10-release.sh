#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "============================================================"
echo " Local release: build everything, package release/, publish"
echo " with the GitHub CLI (works on a private repo + GitHub Free -"
echo " see docs/guide/releases-en.md)"
echo "============================================================"

DRYRUN=0
VERSION=""
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRYRUN=1 ;;
        *) [ -z "$VERSION" ] && VERSION="$arg" ;;
    esac
done

if [ -z "$VERSION" ] && [ -f "VERSION" ]; then
    VERSION="$(tr -d '[:space:]' < VERSION)"
fi
if [ -z "$VERSION" ]; then
    echo "[ERROR] No version given and no VERSION file found." >&2
    echo "Usage: 10-release.sh vX.Y.Z [--dry-run]" >&2
    echo "   or: put \"vX.Y.Z\" in a VERSION file and run: 10-release.sh [--dry-run]" >&2
    exit 1
fi
echo "Release version: $VERSION"

echo "-----------------------------------------------------------"
echo "1. Refuse a dirty working tree (release must come from a"
echo "   committed, reviewable state)"
echo "-----------------------------------------------------------"
command -v git >/dev/null 2>&1 || { echo "[ERROR] git not found on PATH." >&2; exit 1; }
if [ -n "$(git status --porcelain)" ]; then
    echo "[ERROR] Working tree is not clean. Commit or stash your changes first:" >&2
    git status --short >&2
    exit 1
fi

echo "-----------------------------------------------------------"
echo "2. Check the GitHub CLI is installed and logged in"
echo "-----------------------------------------------------------"
command -v gh >/dev/null 2>&1 || { echo "[ERROR] GitHub CLI 'gh' not found - see docs/guide/releases-en.md." >&2; exit 1; }
if ! gh auth status >/dev/null 2>&1; then
    echo "[ERROR] gh is not logged in to GitHub." >&2
    echo "Fix: gh auth login" >&2
    echo "(see docs/guide/releases-en.md for a step-by-step walkthrough," >&2
    echo " including the GitHub Student Developer Pack)" >&2
    exit 1
fi

echo "-----------------------------------------------------------"
echo "3. Build everything locally: jar, both coverage-report"
echo "   families, both doc-coverage families, API docs, site"
echo "-----------------------------------------------------------"
./7-build-app.sh || { echo "[ERROR] Build failed - fix it before releasing." >&2; exit 1; }

echo "-----------------------------------------------------------"
echo "4. Zip the whole site as release/site.zip (download -> unzip"
echo "   -> open index.html; this is how graders see the site on a"
echo "   private repo without GitHub Pages - see docs/guide/releases-en.md)"
echo "-----------------------------------------------------------"
command -v zip >/dev/null 2>&1 || { echo "[ERROR] 'zip' not found. Install it: sudo apt-get install -y zip" >&2; exit 1; }
rm -f release/site.zip
( cd calculator-app/target/site && zip -rq "../../../release/site.zip" . )
[ -f "release/site.zip" ] || { echo "[ERROR] release/site.zip was not created." >&2; exit 1; }

echo "-----------------------------------------------------------"
echo "Release assets in release/:"
echo "-----------------------------------------------------------"
ls -1 release

NOTES_FILE="$(mktemp --suffix=.md)"
cat > "$NOTES_FILE" <<EOF
# $VERSION

Built locally with 7-build-app.bat / 7-build-app.sh. This Java template's runnable jar is portable bytecode -
application-binary.tar.gz runs unmodified on Windows, Linux and macOS with any JDK 17+.

- application-binary.tar.gz - the runnable jar (cross-platform)
- source-code.tar.gz - the source tree at this commit (git archive)
- test-results-surefire.tar.gz - raw JUnit XML plus the rendered Surefire report
- test-jacoco-report.tar.gz / test-coverage-report.tar.gz - unit-test coverage, native (JaCoCo) and ReportGenerator families
- doc-coverage-report.tar.gz / doc-coverage-reportgenerator-report.tar.gz - documentation coverage, native (genhtml) and ReportGenerator families
- application-documentation.tar.gz - Doxygen API docs
- api-docs-javadoc.tar.gz - Javadoc API docs
- application-site.tar.gz / site.zip - the full Maven site (unzip site.zip and open index.html)
EOF

if [ "$DRYRUN" = "1" ]; then
    echo "-----------------------------------------------------------"
    echo "[DRY RUN] Would run:"
    echo "  gh release create $VERSION release/* --title \"$VERSION\" --notes-file \"$NOTES_FILE\""
    echo "[DRY RUN] No release was created and nothing was published."
    exit 0
fi

echo "-----------------------------------------------------------"
echo "5. Publish with the GitHub CLI (no Actions minutes used)"
echo "-----------------------------------------------------------"
gh release create "$VERSION" release/* --title "$VERSION" --notes-file "$NOTES_FILE" \
    || { echo "[ERROR] 'gh release create' failed - see the output above. Common causes: the tag $VERSION already exists, you lack push access, or an asset exceeds GitHub's 2 GiB-per-file limit." >&2; exit 1; }

echo "...................."
echo "Release $VERSION published."
echo "...................."
