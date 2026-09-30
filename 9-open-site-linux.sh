#!/bin/bash
# 9 - open the built site in your browser, served over http://localhost (the report pages use
# <iframe>, and most browsers block iframes on a file:// page).
#   ./9-open-site-linux.sh              serve site/            (the MkDocs site, all reports)
#   ./9-open-site-linux.sh 9000         same, on port 9000
#   ./9-open-site-linux.sh --maven      serve site-native/     (the Maven site on its own)
#   ./9-open-site-linux.sh --edit       live-reloading MkDocs dev server (while writing docs)
# In WSL the URL also opens in your Windows browser (localhost is forwarded).
set -e
cd "$(dirname "$0")"
. scripts/load-env-linux.sh
. scripts/detect-python-linux.sh

export NO_MKDOCS_2_WARNING=true
DIR=site; PORT=8000; MODE=serve
for a in "$@"; do
    case "$a" in
        --maven) DIR=site-native ;;
        --edit) MODE=edit ;;
        ''|*[!0-9]*) ;;
        *) PORT="$a" ;;
    esac
done

open_url() {
    if [ -n "$CI" ]; then return 0; fi
    if command -v wslview >/dev/null 2>&1; then wslview "$1" >/dev/null 2>&1 &
    elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$1" >/dev/null 2>&1 &
    elif command -v explorer.exe >/dev/null 2>&1; then explorer.exe "$1" >/dev/null 2>&1 &
    else echo "Open this in your browser: $1"; fi
}

if [ "$MODE" = "edit" ]; then
    echo "Live MkDocs server - the report pages need a full ./7-build-all-linux.sh run first."
    "$PY" scripts/assemble.py site
    echo "Open http://localhost:$PORT/ - CTRL+C stops it."
    open_url "http://localhost:$PORT/"
    "$PY" -m mkdocs serve -a "localhost:$PORT"
    exit 0
fi

if [ ! -f "$DIR/index.html" ]; then
    echo "[ERROR] $DIR/index.html not found. Build it first: ./7-build-all-linux.sh" >&2
    exit 1
fi
echo "Serving $DIR/ at http://localhost:$PORT/   (CTRL+C stops the server)"
open_url "http://localhost:$PORT/"
"$PY" -m http.server "$PORT" --directory "$DIR"
